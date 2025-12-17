/*
    db/triggers/triggers.sql
    Contains business-rule triggers (grade recalculation, attendance alerts, audit helpers).
*/

SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

/* =========================================================
   tr_GradeComponents_CheckWeights
   Prevents total weights from exceeding 100%.
   ========================================================= */
IF OBJECT_ID('dbo.tr_GradeComponents_CheckWeights', 'TR') IS NOT NULL
    DROP TRIGGER dbo.tr_GradeComponents_CheckWeights;
GO
CREATE TRIGGER dbo.tr_GradeComponents_CheckWeights
ON dbo.GradeComponents
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @Totals TABLE
    (
        OfferingID INT,
        TotalWeight DECIMAL(6,2)
    );

    INSERT INTO @Totals (OfferingID, TotalWeight)
    SELECT
        CO.OfferingID,
        ISNULL(SUM(GC.WeightPercent), 0)
    FROM (
        SELECT DISTINCT OfferingID FROM inserted WHERE OfferingID IS NOT NULL
        UNION
        SELECT DISTINCT OfferingID FROM deleted WHERE OfferingID IS NOT NULL
    ) CO
    LEFT JOIN dbo.GradeComponents GC ON CO.OfferingID = GC.OfferingID
    GROUP BY CO.OfferingID;

    IF EXISTS (SELECT 1 FROM @Totals WHERE TotalWeight > 100.0001)
    BEGIN
        RAISERROR ('Bileşen ağırlıkları %100''ü aşamaz.', 16, 1);
        ROLLBACK TRANSACTION;
        RETURN;
    END
END;
GO

/* =========================================================
   tr_Grades_AIU_Recalculate
   Recomputes enrollment averages, letters, and logs changes.
   ========================================================= */
IF OBJECT_ID('dbo.tr_Grades_AIU_Recalculate', 'TR') IS NOT NULL
    DROP TRIGGER dbo.tr_Grades_AIU_Recalculate;
GO
CREATE TRIGGER dbo.tr_Grades_AIU_Recalculate
ON dbo.Grades
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @Changes TABLE
    (
        EnrollmentID INT,
        StudentID INT,
        OldAverage DECIMAL(5,2),
        NewAverage DECIMAL(5,2),
        NewLetter NVARCHAR(5)
    );

    ;WITH ChangedEnrollments AS (
        SELECT DISTINCT EnrollmentID FROM inserted
        UNION
        SELECT DISTINCT EnrollmentID FROM deleted
    ),
    Weighted AS (
        SELECT
            G.EnrollmentID,
            WeightedScore = SUM(G.Score * GC.WeightPercent),
            TotalWeight = SUM(GC.WeightPercent)
        FROM dbo.Grades G
        INNER JOIN dbo.GradeComponents GC ON G.ComponentID = GC.ComponentID
        WHERE G.EnrollmentID IN (SELECT EnrollmentID FROM ChangedEnrollments)
        GROUP BY G.EnrollmentID
    )
    UPDATE E
    SET
        CurrentAverage = CASE WHEN W.TotalWeight = 0 OR W.TotalWeight IS NULL THEN NULL ELSE CAST(W.WeightedScore / W.TotalWeight AS DECIMAL(5,2)) END,
        LetterGrade = CASE
            WHEN W.TotalWeight = 0 OR W.TotalWeight IS NULL THEN NULL
            WHEN (W.WeightedScore / W.TotalWeight) >= 90 THEN 'AA'
            WHEN (W.WeightedScore / W.TotalWeight) >= 85 THEN 'BA'
            WHEN (W.WeightedScore / W.TotalWeight) >= 80 THEN 'BB'
            WHEN (W.WeightedScore / W.TotalWeight) >= 75 THEN 'CB'
            WHEN (W.WeightedScore / W.TotalWeight) >= 70 THEN 'CC'
            WHEN (W.WeightedScore / W.TotalWeight) >= 65 THEN 'DC'
            WHEN (W.WeightedScore / W.TotalWeight) >= 60 THEN 'DD'
            WHEN (W.WeightedScore / W.TotalWeight) >= 50 THEN 'FD'
            ELSE 'FF'
        END,
        EnrollStatus = CASE
            WHEN E.EnrollStatus IN ('Dropped', 'AutoFailDueToAttendance') THEN E.EnrollStatus
            WHEN W.TotalWeight IS NULL THEN E.EnrollStatus
            WHEN (W.WeightedScore / W.TotalWeight) < 50 THEN 'AtRisk'
            ELSE 'Active'
        END,
        StatusUpdatedAt = SYSUTCDATETIME()
    OUTPUT
        inserted.EnrollmentID,
        inserted.StudentID,
        deleted.CurrentAverage,
        inserted.CurrentAverage,
        inserted.LetterGrade
    INTO @Changes
    FROM dbo.Enrollments E
    LEFT JOIN Weighted W ON E.EnrollmentID = W.EnrollmentID
    WHERE E.EnrollmentID IN (SELECT EnrollmentID FROM ChangedEnrollments);

    INSERT INTO dbo.AuditLog (TableName, RecordID, ActionType, ChangedBy, ChangeDetails)
    SELECT
        'Enrollments',
        CAST(EnrollmentID AS NVARCHAR(100)),
        'RecalculateGrade',
        StudentID,
        CONCAT('Average changed from ', ISNULL(CAST(OldAverage AS NVARCHAR(10)), 'NULL'),
               ' to ', ISNULL(CAST(NewAverage AS NVARCHAR(10)), 'NULL'))
    FROM @Changes
    WHERE ISNULL(OldAverage, -1) <> ISNULL(NewAverage, -1);

    INSERT INTO dbo.Notifications (UserID, Type, Title, Message)
    SELECT
        C.StudentID,
        'Grade',
        'Not Güncellemesi',
        CONCAT('Ders ortalaman güncellendi: ', ISNULL(CAST(C.NewAverage AS NVARCHAR(10)), 'N/A'))
    FROM @Changes C
    WHERE ISNULL(OldAverage, -1) <> ISNULL(NewAverage, -1);

    INSERT INTO dbo.Notifications (UserID, Type, Title, Message)
    SELECT
        S.AdvisorID,
        'Grade',
        'Danışman Öğrenci Not Güncellemesi',
        CONCAT('Öğrenci ', S.FirstName, ' ', S.LastName, ' için yeni ortalama: ', ISNULL(CAST(C.NewAverage AS NVARCHAR(10)), 'N/A'))
    FROM @Changes C
    INNER JOIN dbo.Students S ON C.StudentID = S.StudentID
    WHERE S.AdvisorID IS NOT NULL
      AND ISNULL(OldAverage, -1) <> ISNULL(NewAverage, -1);
END;
GO

/* =========================================================
   tr_Attendance_AI_ThresholdCheck
   Generates alerts/notifications when absence thresholds are crossed.
   ========================================================= */
IF OBJECT_ID('dbo.tr_Attendance_AI_ThresholdCheck', 'TR') IS NOT NULL
    DROP TRIGGER dbo.tr_Attendance_AI_ThresholdCheck;
GO
CREATE TRIGGER dbo.tr_Attendance_AI_ThresholdCheck
ON dbo.Attendance
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    ;WITH ChangedSessions AS (
        SELECT DISTINCT SessionID FROM inserted
    ),
    RelatedOfferings AS (
        SELECT
            CS.SessionID,
            CS.OfferingID,
            CO.CourseID
        FROM ChangedSessions S
        INNER JOIN dbo.ClassSessions CS ON CS.SessionID = S.SessionID
        INNER JOIN dbo.CourseOfferings CO ON CO.OfferingID = CS.OfferingID
    ),
    EnrollmentAbsence AS (
        SELECT
            E.EnrollmentID,
            E.StudentID,
            RO.OfferingID,
            TotalSessions = COUNT(DISTINCT CS.SessionID),
            AbsentCount = SUM(CASE WHEN A.Status = 'Absent' THEN 1 ELSE 0 END)
        FROM RelatedOfferings RO
        INNER JOIN dbo.ClassSessions CS ON CS.OfferingID = RO.OfferingID
        INNER JOIN dbo.Enrollments E ON E.OfferingID = RO.OfferingID
        LEFT JOIN dbo.Attendance A ON A.SessionID = CS.SessionID AND A.StudentID = E.StudentID
        GROUP BY E.EnrollmentID, E.StudentID, RO.OfferingID
    )
    SELECT
        EA.EnrollmentID,
        EA.StudentID,
        EA.OfferingID,
        AbsencePercent = CASE WHEN EA.TotalSessions = 0 THEN 0 ELSE (EA.AbsentCount * 100.0 / EA.TotalSessions) END,
        AP.WarningThresholdPercent,
        AP.AutoFailPercent
    INTO #Thresholds
    FROM EnrollmentAbsence EA
    INNER JOIN dbo.AttendancePolicies AP ON AP.OfferingID = EA.OfferingID;

    -- Warning alerts
    INSERT INTO dbo.AttendanceAlerts (EnrollmentID, AlertType)
    SELECT T.EnrollmentID, 'Warning'
    FROM #Thresholds T
    WHERE T.AbsencePercent >= T.WarningThresholdPercent
      AND NOT EXISTS (SELECT 1 FROM dbo.AttendanceAlerts AA WHERE AA.EnrollmentID = T.EnrollmentID AND AA.AlertType = 'Warning');

    INSERT INTO dbo.Notifications (UserID, Type, Title, Message)
    SELECT
        T.StudentID,
        'Attendance',
        'Devamsızlık Uyarısı',
        CONCAT('Devamsızlık oranın %', CAST(T.AbsencePercent AS NVARCHAR(10)), ' seviyesine ulaştı.')
    FROM #Thresholds T
    WHERE EXISTS (SELECT 1 FROM dbo.AttendanceAlerts AA WHERE AA.EnrollmentID = T.EnrollmentID AND AA.AlertType = 'Warning' AND AA.TriggeredAt >= DATEADD(SECOND, -5, SYSUTCDATETIME()));

    INSERT INTO dbo.Notifications (UserID, Type, Title, Message)
    SELECT
        S.AdvisorID,
        'Attendance',
        'Danışman Uyarısı',
        CONCAT('Öğrencinizin devamsızlığı %', CAST(T.AbsencePercent AS NVARCHAR(10)), ' oldu.')
    FROM #Thresholds T
    INNER JOIN dbo.Students S ON S.StudentID = T.StudentID
    WHERE S.AdvisorID IS NOT NULL
      AND EXISTS (SELECT 1 FROM dbo.AttendanceAlerts AA WHERE AA.EnrollmentID = T.EnrollmentID AND AA.AlertType = 'Warning' AND AA.TriggeredAt >= DATEADD(SECOND, -5, SYSUTCDATETIME()));

    -- Auto fail handling
    INSERT INTO dbo.AttendanceAlerts (EnrollmentID, AlertType)
    SELECT T.EnrollmentID, 'AutoFail'
    FROM #Thresholds T
    WHERE T.AbsencePercent >= T.AutoFailPercent
      AND NOT EXISTS (SELECT 1 FROM dbo.AttendanceAlerts AA WHERE AA.EnrollmentID = T.EnrollmentID AND AA.AlertType = 'AutoFail');

    UPDATE E
    SET EnrollStatus = 'AutoFailDueToAttendance',
        StatusUpdatedAt = SYSUTCDATETIME()
    FROM dbo.Enrollments E
    INNER JOIN #Thresholds T ON T.EnrollmentID = E.EnrollmentID
    WHERE T.AbsencePercent >= T.AutoFailPercent;

    INSERT INTO dbo.AuditLog (TableName, RecordID, ActionType, ChangedBy, ChangeDetails)
    SELECT
        'Enrollments',
        CAST(T.EnrollmentID AS NVARCHAR(100)),
        'AttendanceAutoFail',
        T.StudentID,
        CONCAT('Devamsızlık: %', CAST(T.AbsencePercent AS NVARCHAR(10)))
    FROM #Thresholds T
    WHERE T.AbsencePercent >= T.AutoFailPercent;

    DROP TABLE #Thresholds;
END;
GO

/* =========================================================
   tr_Enrollments_StatusAudit
   Logs status transitions for enrollments.
   ========================================================= */
IF OBJECT_ID('dbo.tr_Enrollments_StatusAudit', 'TR') IS NOT NULL
    DROP TRIGGER dbo.tr_Enrollments_StatusAudit;
GO
CREATE TRIGGER dbo.tr_Enrollments_StatusAudit
ON dbo.Enrollments
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO dbo.AuditLog (TableName, RecordID, ActionType, ChangedBy, ChangeDetails)
    SELECT
        'Enrollments',
        CAST(i.EnrollmentID AS NVARCHAR(100)),
        'StatusChange',
        i.StudentID,
        CONCAT('Durum ', d.EnrollStatus, ' -> ', i.EnrollStatus)
    FROM inserted i
    INNER JOIN deleted d ON i.EnrollmentID = d.EnrollmentID
    WHERE ISNULL(i.EnrollStatus, '') <> ISNULL(d.EnrollStatus, '');
END;
GO

/* =========================================================
   tr_Attendance_AIU_UpdatePercent
   Yoklama kaydedildiğinde öğrencinin devam yüzdesini günceller.
   ========================================================= */
IF OBJECT_ID('dbo.tr_Attendance_AIU_UpdatePercent', 'TR') IS NOT NULL
    DROP TRIGGER dbo.tr_Attendance_AIU_UpdatePercent;
GO
CREATE TRIGGER dbo.tr_Attendance_AIU_UpdatePercent
ON dbo.Attendance
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;

    -- Etkilenen öğrenci-ders kombinasyonlarını belirle
    DECLARE @AffectedEnrollments TABLE (
        EnrollmentID INT,
        StudentID INT,
        OfferingID INT
    );

    INSERT INTO @AffectedEnrollments (EnrollmentID, StudentID, OfferingID)
    SELECT DISTINCT E.EnrollmentID, E.StudentID, E.OfferingID
    FROM (
        SELECT SessionID, StudentID FROM inserted
        UNION
        SELECT SessionID, StudentID FROM deleted
    ) Changes
    INNER JOIN dbo.ClassSessions CS ON CS.SessionID = Changes.SessionID
    INNER JOIN dbo.Enrollments E ON E.OfferingID = CS.OfferingID AND E.StudentID = Changes.StudentID;

    -- Her etkilenen kayıt için devam yüzdesini hesapla ve güncelle
    UPDATE E
    SET AttendancePercent = Stats.AttendancePercent
    FROM dbo.Enrollments E
    INNER JOIN (
        SELECT
            AE.EnrollmentID,
            AttendancePercent = CASE 
                WHEN TotalSessions.SessionCount = 0 THEN NULL
                ELSE CAST(
                    (ISNULL(PresentCount.Cnt, 0) + (ISNULL(LateCount.Cnt, 0) * 0.5) + ISNULL(ExcusedCount.Cnt, 0)) * 100.0 
                    / TotalSessions.SessionCount 
                AS DECIMAL(5,2))
            END
        FROM @AffectedEnrollments AE
        -- Toplam oturum sayısı
        CROSS APPLY (
            SELECT SessionCount = COUNT(*)
            FROM dbo.ClassSessions CS
            WHERE CS.OfferingID = AE.OfferingID
        ) TotalSessions
        -- Geldi sayısı
        OUTER APPLY (
            SELECT Cnt = COUNT(*)
            FROM dbo.Attendance A
            INNER JOIN dbo.ClassSessions CS ON CS.SessionID = A.SessionID
            WHERE CS.OfferingID = AE.OfferingID 
              AND A.StudentID = AE.StudentID 
              AND A.Status = 'Present'
        ) PresentCount
        -- Geç kaldı sayısı (yarım devam olarak sayılır)
        OUTER APPLY (
            SELECT Cnt = COUNT(*)
            FROM dbo.Attendance A
            INNER JOIN dbo.ClassSessions CS ON CS.SessionID = A.SessionID
            WHERE CS.OfferingID = AE.OfferingID 
              AND A.StudentID = AE.StudentID 
              AND A.Status = 'Late'
        ) LateCount
        -- Mazeretli sayısı (tam devam olarak sayılır)
        OUTER APPLY (
            SELECT Cnt = COUNT(*)
            FROM dbo.Attendance A
            INNER JOIN dbo.ClassSessions CS ON CS.SessionID = A.SessionID
            WHERE CS.OfferingID = AE.OfferingID 
              AND A.StudentID = AE.StudentID 
              AND A.Status = 'Excused'
        ) ExcusedCount
    ) Stats ON Stats.EnrollmentID = E.EnrollmentID;
END;
GO

