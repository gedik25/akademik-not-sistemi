/*
    db/stored_procedures/academic.sql
    Academic-specific procedures: courses, students, sessions.
*/

SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

/* =========================================================
   sp_GetAcademicCourses
   Akademisyenin verdiği dersleri ve kayıtlı öğrenci sayısını döndürür.
   ========================================================= */
IF OBJECT_ID('dbo.sp_GetAcademicCourses', 'P') IS NOT NULL DROP PROCEDURE dbo.sp_GetAcademicCourses;
GO
CREATE PROCEDURE dbo.sp_GetAcademicCourses
    @AcademicID INT,
    @Term       NVARCHAR(20) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        CO.OfferingID,
        C.CourseCode,
        C.CourseName,
        C.Credit,
        C.ECTS,
        CO.Term,
        CO.Section,
        CO.Capacity,
        EnrolledCount = (SELECT COUNT(*) FROM dbo.Enrollments E WHERE E.OfferingID = CO.OfferingID AND E.EnrollStatus NOT IN ('Dropped')),
        SessionCount = (SELECT COUNT(*) FROM dbo.ClassSessions CS WHERE CS.OfferingID = CO.OfferingID)
    FROM dbo.CourseOfferings CO
    INNER JOIN dbo.Courses C ON CO.CourseID = C.CourseID
    WHERE CO.AcademicID = @AcademicID
      AND (@Term IS NULL OR CO.Term = @Term)
    ORDER BY CO.Term DESC, C.CourseCode;
END;
GO

/* =========================================================
   sp_GetEnrolledStudents
   Derse kayıtlı öğrencilerin listesini devam% ve ortalama ile döndürür.
   ========================================================= */
IF OBJECT_ID('dbo.sp_GetEnrolledStudents', 'P') IS NOT NULL DROP PROCEDURE dbo.sp_GetEnrolledStudents;
GO
CREATE PROCEDURE dbo.sp_GetEnrolledStudents
    @OfferingID INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        E.EnrollmentID,
        E.StudentID,
        S.StudentNumber,
        S.FirstName,
        S.LastName,
        FullName = CONCAT(S.FirstName, ' ', S.LastName),
        E.EnrollStatus,
        E.CurrentAverage,
        E.LetterGrade,
        E.AttendancePercent,
        E.EnrolledAt
    FROM dbo.Enrollments E
    INNER JOIN dbo.Students S ON E.StudentID = S.StudentID
    WHERE E.OfferingID = @OfferingID
    ORDER BY S.StudentNumber;
END;
GO

/* =========================================================
   sp_GenerateClassSessions
   Belirtilen OfferingID için 14 haftalık ders oturumları oluşturur.
   @StartDate: Dönemin başlangıç tarihi
   @DayOfWeek: Haftanın günü (1=Pazartesi, 7=Pazar)
   ========================================================= */
IF OBJECT_ID('dbo.sp_GenerateClassSessions', 'P') IS NOT NULL DROP PROCEDURE dbo.sp_GenerateClassSessions;
GO
CREATE PROCEDURE dbo.sp_GenerateClassSessions
    @OfferingID     INT,
    @StartDate      DATE,
    @DayOfWeek      INT = 1,           -- 1=Pazartesi varsayılan
    @StartTime      TIME(0) = '09:00',
    @EndTime        TIME(0) = '11:00',
    @SessionType    NVARCHAR(20) = 'Lecture',
    @Location       NVARCHAR(50) = NULL,
    @WeekCount      INT = 14
AS
BEGIN
    SET NOCOUNT ON;

    -- Eski oturumları sil (yoklama kaydı yoksa)
    DELETE FROM dbo.ClassSessions
    WHERE OfferingID = @OfferingID
      AND SessionID NOT IN (SELECT DISTINCT SessionID FROM dbo.Attendance);

    -- İlk dersin tarihini hesapla (StartDate'ten sonraki ilk belirtilen gün)
    DECLARE @FirstSessionDate DATE;
    DECLARE @CurrentDayOfWeek INT = (DATEPART(WEEKDAY, @StartDate) + @@DATEFIRST - 2) % 7 + 1;
    
    IF @CurrentDayOfWeek <= @DayOfWeek
        SET @FirstSessionDate = DATEADD(DAY, @DayOfWeek - @CurrentDayOfWeek, @StartDate);
    ELSE
        SET @FirstSessionDate = DATEADD(DAY, 7 - @CurrentDayOfWeek + @DayOfWeek, @StartDate);

    -- 14 haftalık oturumları oluştur
    DECLARE @WeekNum INT = 0;
    DECLARE @SessionDate DATE;

    WHILE @WeekNum < @WeekCount
    BEGIN
        SET @SessionDate = DATEADD(WEEK, @WeekNum, @FirstSessionDate);

        -- Aynı tarihte oturum yoksa ekle
        IF NOT EXISTS (
            SELECT 1 FROM dbo.ClassSessions 
            WHERE OfferingID = @OfferingID 
              AND SessionDate = @SessionDate 
              AND StartTime = @StartTime
        )
        BEGIN
            INSERT INTO dbo.ClassSessions (OfferingID, SessionDate, StartTime, EndTime, SessionType, Location)
            VALUES (@OfferingID, @SessionDate, @StartTime, @EndTime, @SessionType, @Location);
        END

        SET @WeekNum = @WeekNum + 1;
    END

    -- Oluşturulan oturum sayısını döndür
    SELECT SessionsCreated = (SELECT COUNT(*) FROM dbo.ClassSessions WHERE OfferingID = @OfferingID);
END;
GO

/* =========================================================
   sp_GetClassSessions
   Dersin tüm oturumlarını ve yoklama durumunu listeler.
   ========================================================= */
IF OBJECT_ID('dbo.sp_GetClassSessions', 'P') IS NOT NULL DROP PROCEDURE dbo.sp_GetClassSessions;
GO
CREATE PROCEDURE dbo.sp_GetClassSessions
    @OfferingID INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        CS.SessionID,
        CS.SessionDate,
        CS.StartTime,
        CS.EndTime,
        CS.SessionType,
        CS.Location,
        WeekNumber = ROW_NUMBER() OVER (ORDER BY CS.SessionDate, CS.StartTime),
        AttendanceRecorded = CASE WHEN EXISTS (
            SELECT 1 FROM dbo.Attendance A WHERE A.SessionID = CS.SessionID
        ) THEN 1 ELSE 0 END,
        PresentCount = (SELECT COUNT(*) FROM dbo.Attendance A WHERE A.SessionID = CS.SessionID AND A.Status = 'Present'),
        AbsentCount = (SELECT COUNT(*) FROM dbo.Attendance A WHERE A.SessionID = CS.SessionID AND A.Status = 'Absent'),
        LateCount = (SELECT COUNT(*) FROM dbo.Attendance A WHERE A.SessionID = CS.SessionID AND A.Status = 'Late'),
        ExcusedCount = (SELECT COUNT(*) FROM dbo.Attendance A WHERE A.SessionID = CS.SessionID AND A.Status = 'Excused')
    FROM dbo.ClassSessions CS
    WHERE CS.OfferingID = @OfferingID
    ORDER BY CS.SessionDate, CS.StartTime;
END;
GO

/* =========================================================
   sp_GetSessionAttendance
   Tek bir oturum için tüm öğrencilerin yoklama durumunu döndürür.
   ========================================================= */
IF OBJECT_ID('dbo.sp_GetSessionAttendance', 'P') IS NOT NULL DROP PROCEDURE dbo.sp_GetSessionAttendance;
GO
CREATE PROCEDURE dbo.sp_GetSessionAttendance
    @SessionID INT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @OfferingID INT;
    SELECT @OfferingID = OfferingID FROM dbo.ClassSessions WHERE SessionID = @SessionID;

    SELECT
        E.EnrollmentID,
        E.StudentID,
        S.StudentNumber,
        S.FirstName,
        S.LastName,
        FullName = CONCAT(S.FirstName, ' ', S.LastName),
        A.Status,
        A.Remarks,
        A.RecordedAt,
        A.RecordedBy
    FROM dbo.Enrollments E
    INNER JOIN dbo.Students S ON E.StudentID = S.StudentID
    LEFT JOIN dbo.Attendance A ON A.SessionID = @SessionID AND A.StudentID = E.StudentID
    WHERE E.OfferingID = @OfferingID
      AND E.EnrollStatus NOT IN ('Dropped')
    ORDER BY S.StudentNumber;
END;
GO

/* =========================================================
   sp_BulkRecordAttendance
   Tek oturum için toplu yoklama kaydı.
   @AttendanceJSON format: [{"studentId": 1, "status": "Present"}, ...]
   ========================================================= */
IF OBJECT_ID('dbo.sp_BulkRecordAttendance', 'P') IS NOT NULL DROP PROCEDURE dbo.sp_BulkRecordAttendance;
GO
CREATE PROCEDURE dbo.sp_BulkRecordAttendance
    @SessionID       INT,
    @AttendanceJSON  NVARCHAR(MAX),
    @RecordedBy      INT
AS
BEGIN
    SET NOCOUNT ON;

    -- JSON'dan yoklama verilerini parse et ve kaydet
    DECLARE @AttendanceData TABLE (
        StudentID INT,
        Status NVARCHAR(20),
        Remarks NVARCHAR(255)
    );

    INSERT INTO @AttendanceData (StudentID, Status, Remarks)
    SELECT 
        StudentID = JSON_VALUE(value, '$.studentId'),
        Status = JSON_VALUE(value, '$.status'),
        Remarks = JSON_VALUE(value, '$.remarks')
    FROM OPENJSON(@AttendanceJSON);

    -- Her öğrenci için yoklama kaydı oluştur/güncelle
    MERGE dbo.Attendance AS target
    USING @AttendanceData AS source
    ON target.SessionID = @SessionID AND target.StudentID = source.StudentID
    WHEN MATCHED THEN
        UPDATE SET 
            Status = source.Status,
            Remarks = source.Remarks,
            RecordedAt = SYSUTCDATETIME(),
            RecordedBy = @RecordedBy
    WHEN NOT MATCHED THEN
        INSERT (SessionID, StudentID, Status, RecordedBy, Remarks)
        VALUES (@SessionID, source.StudentID, source.Status, @RecordedBy, source.Remarks);

    -- Kaydedilen öğrenci sayısını döndür
    SELECT RecordedCount = @@ROWCOUNT;

    -- AuditLog kaydı
    INSERT INTO dbo.AuditLog (TableName, RecordID, ActionType, ChangedBy, ChangeDetails)
    VALUES (
        'Attendance',
        CAST(@SessionID AS NVARCHAR(100)),
        'BulkRecordAttendance',
        @RecordedBy,
        CONCAT('Toplu yoklama kaydı: ', (SELECT COUNT(*) FROM @AttendanceData), ' öğrenci')
    );
END;
GO

/* =========================================================
   sp_GetGradeComponents
   Dersin not bileşenlerini listeler.
   ========================================================= */
IF OBJECT_ID('dbo.sp_GetGradeComponents', 'P') IS NOT NULL DROP PROCEDURE dbo.sp_GetGradeComponents;
GO
CREATE PROCEDURE dbo.sp_GetGradeComponents
    @OfferingID INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        GC.ComponentID,
        GC.ComponentName,
        GC.WeightPercent,
        GC.IsMandatory,
        GradesEntered = (SELECT COUNT(*) FROM dbo.Grades G WHERE G.ComponentID = GC.ComponentID)
    FROM dbo.GradeComponents GC
    WHERE GC.OfferingID = @OfferingID
    ORDER BY GC.ComponentName;
END;
GO

/* =========================================================
   sp_GetStudentGrades
   Bir dersin tüm öğrencilerinin tüm bileşen notlarını matris formatında döndürür.
   ========================================================= */
IF OBJECT_ID('dbo.sp_GetStudentGrades', 'P') IS NOT NULL DROP PROCEDURE dbo.sp_GetStudentGrades;
GO
CREATE PROCEDURE dbo.sp_GetStudentGrades
    @OfferingID INT
AS
BEGIN
    SET NOCOUNT ON;

    -- Öğrenci bazlı notları döndür
    SELECT
        E.EnrollmentID,
        E.StudentID,
        S.StudentNumber,
        FullName = CONCAT(S.FirstName, ' ', S.LastName),
        GC.ComponentID,
        GC.ComponentName,
        GC.WeightPercent,
        G.Score,
        G.ScoreDate,
        E.CurrentAverage,
        E.LetterGrade
    FROM dbo.Enrollments E
    INNER JOIN dbo.Students S ON E.StudentID = S.StudentID
    CROSS JOIN dbo.GradeComponents GC
    LEFT JOIN dbo.Grades G ON G.EnrollmentID = E.EnrollmentID AND G.ComponentID = GC.ComponentID
    WHERE E.OfferingID = @OfferingID
      AND GC.OfferingID = @OfferingID
      AND E.EnrollStatus NOT IN ('Dropped')
    ORDER BY S.StudentNumber, GC.ComponentName;
END;
GO

