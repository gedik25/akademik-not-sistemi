/*
    db/stored_procedures/attendance.sql
    Attendance policy and tracking procedures.
*/

SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

/* =========================================================
   sp_DefineAttendancePolicy
   ========================================================= */
IF OBJECT_ID('dbo.sp_DefineAttendancePolicy', 'P') IS NOT NULL DROP PROCEDURE dbo.sp_DefineAttendancePolicy;
GO
CREATE PROCEDURE dbo.sp_DefineAttendancePolicy
    @OfferingID INT,
    @MaxAbsencePercent DECIMAL(5,2),
    @WarningThresholdPercent DECIMAL(5,2),
    @AutoFailPercent DECIMAL(5,2)
AS
BEGIN
    SET NOCOUNT ON;

    MERGE dbo.AttendancePolicies AS target
    USING (SELECT @OfferingID AS OfferingID) AS src
    ON target.OfferingID = src.OfferingID
    WHEN MATCHED THEN
        UPDATE SET MaxAbsencePercent = @MaxAbsencePercent,
                   WarningThresholdPercent = @WarningThresholdPercent,
                   AutoFailPercent = @AutoFailPercent
    WHEN NOT MATCHED THEN
        INSERT (OfferingID, MaxAbsencePercent, WarningThresholdPercent, AutoFailPercent)
        VALUES (@OfferingID, @MaxAbsencePercent, @WarningThresholdPercent, @AutoFailPercent);
END;
GO

/* =========================================================
   sp_RecordAttendance
   ========================================================= */
IF OBJECT_ID('dbo.sp_RecordAttendance', 'P') IS NOT NULL DROP PROCEDURE dbo.sp_RecordAttendance;
GO
CREATE PROCEDURE dbo.sp_RecordAttendance
    @SessionID  INT,
    @StudentID  INT,
    @Status     NVARCHAR(20),
    @RecordedBy INT,
    @Remarks    NVARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @OldStatus NVARCHAR(20) = NULL;
    DECLARE @ActionType NVARCHAR(30);
    DECLARE @SessionDate DATE;

    -- Oturum tarihini al
    SELECT @SessionDate = SessionDate FROM dbo.ClassSessions WHERE SessionID = @SessionID;

    IF EXISTS (SELECT 1 FROM dbo.Attendance WHERE SessionID = @SessionID AND StudentID = @StudentID)
    BEGIN
        -- Eski durumu sakla
        SELECT @OldStatus = Status FROM dbo.Attendance WHERE SessionID = @SessionID AND StudentID = @StudentID;
        SET @ActionType = 'UpdateAttendance';

        UPDATE dbo.Attendance
        SET Status = @Status,
            RecordedAt = SYSUTCDATETIME(),
            RecordedBy = @RecordedBy,
            Remarks = @Remarks
        WHERE SessionID = @SessionID AND StudentID = @StudentID;
    END
    ELSE
    BEGIN
        SET @ActionType = 'InsertAttendance';

        INSERT INTO dbo.Attendance (SessionID, StudentID, Status, RecordedBy, Remarks)
        VALUES (@SessionID, @StudentID, @Status, @RecordedBy, @Remarks);
    END

    -- AuditLog kaydı
    INSERT INTO dbo.AuditLog (TableName, RecordID, ActionType, ChangedBy, ChangeDetails)
    VALUES (
        'Attendance',
        CONCAT(@SessionID, '-', @StudentID),
        @ActionType,
        @RecordedBy,
        CONCAT('Tarih: ', CAST(@SessionDate AS NVARCHAR(10)), ', ',
               CASE WHEN @OldStatus IS NOT NULL THEN CONCAT(@OldStatus, ' -> ') ELSE '' END,
               @Status)
    );
END;
GO

/* =========================================================
   sp_GetAttendanceSummary
   ========================================================= */
IF OBJECT_ID('dbo.sp_GetAttendanceSummary', 'P') IS NOT NULL DROP PROCEDURE dbo.sp_GetAttendanceSummary;
GO
CREATE PROCEDURE dbo.sp_GetAttendanceSummary
    @OfferingID INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        S.StudentNumber,
        S.FirstName,
        S.LastName,
        TotalSessions = COUNT(DISTINCT CS.SessionID),
        Presents = SUM(CASE WHEN A.Status = 'Present' THEN 1 ELSE 0 END),
        Absents  = SUM(CASE WHEN A.Status = 'Absent' THEN 1 ELSE 0 END),
        Lates    = SUM(CASE WHEN A.Status = 'Late' THEN 1 ELSE 0 END)
    FROM dbo.Enrollments E
    INNER JOIN dbo.Students S ON E.StudentID = S.StudentID
    INNER JOIN dbo.ClassSessions CS ON CS.OfferingID = E.OfferingID
    LEFT JOIN dbo.Attendance A ON A.SessionID = CS.SessionID AND A.StudentID = S.StudentID
    WHERE E.OfferingID = @OfferingID
    GROUP BY S.StudentNumber, S.FirstName, S.LastName
    ORDER BY S.StudentNumber;
END;
GO

/* =========================================================
   sp_GetStudentAttendanceDetail
   ========================================================= */
IF OBJECT_ID('dbo.sp_GetStudentAttendanceDetail', 'P') IS NOT NULL DROP PROCEDURE dbo.sp_GetStudentAttendanceDetail;
GO
CREATE PROCEDURE dbo.sp_GetStudentAttendanceDetail
    @StudentID  INT,
    @OfferingID INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        CS.SessionDate,
        CS.SessionType,
        CS.StartTime,
        CS.EndTime,
        A.Status,
        A.Remarks
    FROM dbo.ClassSessions CS
    LEFT JOIN dbo.Attendance A
        ON CS.SessionID = A.SessionID AND A.StudentID = @StudentID
    WHERE CS.OfferingID = @OfferingID
    ORDER BY CS.SessionDate, CS.StartTime;
END;
GO

