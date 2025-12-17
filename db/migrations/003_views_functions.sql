/*
    db/migrations/003_views_functions.sql
    Purpose: Add Views, Functions, and Cursor-based SPs
    Run order: After all tables and basic SPs are created
    
    Bu migration şunları ekler:
    1. Views (4 adet)
    2. User-Defined Functions (6 adet)
    3. Cursor kullanan Stored Procedures (4 adet)
*/

USE AkademikDB;
GO

PRINT '==============================================';
PRINT 'Migration 003: Views, Functions, Bulk Operations';
PRINT 'Started at: ' + CONVERT(VARCHAR, GETDATE(), 120);
PRINT '==============================================';
GO

/* =========================================================
   PART 1: USER-DEFINED FUNCTIONS
   (Views bu fonksiyonları kullanabilir, önce oluşturulmalı)
   ========================================================= */

PRINT '';
PRINT '>>> Creating User-Defined Functions...';
GO

-- fn_CalculateLetterGrade
IF OBJECT_ID('dbo.fn_CalculateLetterGrade', 'FN') IS NOT NULL
    DROP FUNCTION dbo.fn_CalculateLetterGrade;
GO
CREATE FUNCTION dbo.fn_CalculateLetterGrade(@Score DECIMAL(5,2))
RETURNS NVARCHAR(2)
AS
BEGIN
    RETURN CASE 
        WHEN @Score IS NULL THEN NULL
        WHEN @Score >= 90 THEN 'AA'
        WHEN @Score >= 85 THEN 'BA'
        WHEN @Score >= 80 THEN 'BB'
        WHEN @Score >= 75 THEN 'CB'
        WHEN @Score >= 70 THEN 'CC'
        WHEN @Score >= 65 THEN 'DC'
        WHEN @Score >= 60 THEN 'DD'
        WHEN @Score >= 50 THEN 'FD'
        ELSE 'FF'
    END;
END;
GO
PRINT '   [OK] fn_CalculateLetterGrade';
GO

-- fn_GetGradePoint
IF OBJECT_ID('dbo.fn_GetGradePoint', 'FN') IS NOT NULL
    DROP FUNCTION dbo.fn_GetGradePoint;
GO
CREATE FUNCTION dbo.fn_GetGradePoint(@LetterGrade NVARCHAR(2))
RETURNS DECIMAL(3,2)
AS
BEGIN
    RETURN CASE @LetterGrade
        WHEN 'AA' THEN 4.00
        WHEN 'BA' THEN 3.50
        WHEN 'BB' THEN 3.00
        WHEN 'CB' THEN 2.50
        WHEN 'CC' THEN 2.00
        WHEN 'DC' THEN 1.50
        WHEN 'DD' THEN 1.00
        WHEN 'FD' THEN 0.50
        WHEN 'FF' THEN 0.00
        ELSE NULL
    END;
END;
GO
PRINT '   [OK] fn_GetGradePoint';
GO

-- fn_CalculateStudentGPA
IF OBJECT_ID('dbo.fn_CalculateStudentGPA', 'FN') IS NOT NULL
    DROP FUNCTION dbo.fn_CalculateStudentGPA;
GO
CREATE FUNCTION dbo.fn_CalculateStudentGPA(@StudentID INT)
RETURNS DECIMAL(4,2)
AS
BEGIN
    DECLARE @GPA DECIMAL(4,2);
    SELECT @GPA = 
        CASE 
            WHEN SUM(C.Credit) = 0 OR SUM(C.Credit) IS NULL THEN NULL
            ELSE CAST(SUM(C.Credit * dbo.fn_GetGradePoint(E.LetterGrade)) / SUM(C.Credit) AS DECIMAL(4,2))
        END
    FROM dbo.Enrollments E
    INNER JOIN dbo.CourseOfferings CO ON E.OfferingID = CO.OfferingID
    INNER JOIN dbo.Courses C ON CO.CourseID = C.CourseID
    WHERE E.StudentID = @StudentID AND E.LetterGrade IS NOT NULL
      AND E.EnrollStatus NOT IN ('Dropped', 'AutoFailDueToAttendance');
    RETURN @GPA;
END;
GO
PRINT '   [OK] fn_CalculateStudentGPA';
GO

-- fn_GetStudentGrades (Table-Valued)
IF OBJECT_ID('dbo.fn_GetStudentGrades', 'IF') IS NOT NULL
    DROP FUNCTION dbo.fn_GetStudentGrades;
GO
CREATE FUNCTION dbo.fn_GetStudentGrades(@StudentID INT)
RETURNS TABLE
AS
RETURN (
    SELECT 
        E.EnrollmentID, C.CourseCode, C.CourseName, C.Credit, CO.Term,
        E.CurrentAverage, E.LetterGrade,
        GradePoint = dbo.fn_GetGradePoint(E.LetterGrade),
        WeightedPoints = C.Credit * dbo.fn_GetGradePoint(E.LetterGrade),
        E.AttendancePercent, E.EnrollStatus
    FROM dbo.Enrollments E
    INNER JOIN dbo.CourseOfferings CO ON E.OfferingID = CO.OfferingID
    INNER JOIN dbo.Courses C ON CO.CourseID = C.CourseID
    WHERE E.StudentID = @StudentID
);
GO
PRINT '   [OK] fn_GetStudentGrades (TVF)';
GO

-- fn_IsPassingGrade
IF OBJECT_ID('dbo.fn_IsPassingGrade', 'FN') IS NOT NULL
    DROP FUNCTION dbo.fn_IsPassingGrade;
GO
CREATE FUNCTION dbo.fn_IsPassingGrade(@LetterGrade NVARCHAR(2))
RETURNS BIT
AS
BEGIN
    RETURN CASE WHEN @LetterGrade IN ('AA','BA','BB','CB','CC','DC','DD') THEN 1 ELSE 0 END;
END;
GO
PRINT '   [OK] fn_IsPassingGrade';
GO

PRINT '>>> Functions completed.';
GO

/* =========================================================
   PART 2: VIEWS
   ========================================================= */

PRINT '';
PRINT '>>> Creating Views...';
GO

-- vw_StudentTranscript
IF OBJECT_ID('dbo.vw_StudentTranscript', 'V') IS NOT NULL
    DROP VIEW dbo.vw_StudentTranscript;
GO
CREATE VIEW dbo.vw_StudentTranscript
AS
SELECT 
    S.StudentID, S.StudentNumber, S.FirstName, S.LastName,
    FullName = CONCAT(S.FirstName, ' ', S.LastName),
    D.DepartmentName, P.ProgramName,
    C.CourseCode, C.CourseName, C.Credit, C.ECTS,
    CO.Term, CO.Section,
    E.EnrollmentID, E.CurrentAverage, E.LetterGrade, E.EnrollStatus, E.AttendancePercent,
    GradePoint = dbo.fn_GetGradePoint(E.LetterGrade),
    IsPass = dbo.fn_IsPassingGrade(E.LetterGrade)
FROM dbo.Students S
INNER JOIN dbo.Enrollments E ON S.StudentID = E.StudentID
INNER JOIN dbo.CourseOfferings CO ON E.OfferingID = CO.OfferingID
INNER JOIN dbo.Courses C ON CO.CourseID = C.CourseID
INNER JOIN dbo.Programs P ON C.ProgramID = P.ProgramID
INNER JOIN dbo.Departments D ON P.DepartmentID = D.DepartmentID;
GO
PRINT '   [OK] vw_StudentTranscript';
GO

-- vw_CourseStatistics
IF OBJECT_ID('dbo.vw_CourseStatistics', 'V') IS NOT NULL
    DROP VIEW dbo.vw_CourseStatistics;
GO
CREATE VIEW dbo.vw_CourseStatistics
AS
SELECT 
    CO.OfferingID, C.CourseCode, C.CourseName, C.Credit, CO.Term, CO.Section, CO.Capacity,
    TotalEnrolled = COUNT(E.EnrollmentID),
    ActiveStudents = SUM(CASE WHEN E.EnrollStatus = 'Active' THEN 1 ELSE 0 END),
    ClassAverage = AVG(E.CurrentAverage),
    MinGrade = MIN(E.CurrentAverage),
    MaxGrade = MAX(E.CurrentAverage),
    CountAA = SUM(CASE WHEN E.LetterGrade = 'AA' THEN 1 ELSE 0 END),
    CountBA = SUM(CASE WHEN E.LetterGrade = 'BA' THEN 1 ELSE 0 END),
    CountBB = SUM(CASE WHEN E.LetterGrade = 'BB' THEN 1 ELSE 0 END),
    CountCC = SUM(CASE WHEN E.LetterGrade = 'CC' THEN 1 ELSE 0 END),
    CountFF = SUM(CASE WHEN E.LetterGrade = 'FF' THEN 1 ELSE 0 END),
    PassRate = CAST(
        CASE WHEN COUNT(E.EnrollmentID) = 0 THEN 0
        ELSE SUM(CASE WHEN dbo.fn_IsPassingGrade(E.LetterGrade) = 1 THEN 1 ELSE 0 END) * 100.0 / COUNT(E.EnrollmentID)
        END AS DECIMAL(5,2)),
    AvgAttendance = AVG(E.AttendancePercent),
    CO.AcademicID
FROM dbo.CourseOfferings CO
INNER JOIN dbo.Courses C ON CO.CourseID = C.CourseID
LEFT JOIN dbo.Enrollments E ON CO.OfferingID = E.OfferingID
GROUP BY CO.OfferingID, C.CourseCode, C.CourseName, C.Credit, CO.Term, CO.Section, CO.Capacity, CO.AcademicID;
GO
PRINT '   [OK] vw_CourseStatistics';
GO

-- vw_AttendanceSummary
IF OBJECT_ID('dbo.vw_AttendanceSummary', 'V') IS NOT NULL
    DROP VIEW dbo.vw_AttendanceSummary;
GO
CREATE VIEW dbo.vw_AttendanceSummary
AS
SELECT 
    E.EnrollmentID, E.OfferingID, E.StudentID,
    S.StudentNumber, S.FirstName, S.LastName,
    FullName = CONCAT(S.FirstName, ' ', S.LastName),
    C.CourseCode, C.CourseName, CO.Term,
    TotalSessions = (SELECT COUNT(*) FROM dbo.ClassSessions CS WHERE CS.OfferingID = E.OfferingID),
    PresentCount = (SELECT COUNT(*) FROM dbo.Attendance A INNER JOIN dbo.ClassSessions CS ON A.SessionID = CS.SessionID WHERE CS.OfferingID = E.OfferingID AND A.StudentID = E.StudentID AND A.Status = 'Present'),
    AbsentCount = (SELECT COUNT(*) FROM dbo.Attendance A INNER JOIN dbo.ClassSessions CS ON A.SessionID = CS.SessionID WHERE CS.OfferingID = E.OfferingID AND A.StudentID = E.StudentID AND A.Status = 'Absent'),
    LateCount = (SELECT COUNT(*) FROM dbo.Attendance A INNER JOIN dbo.ClassSessions CS ON A.SessionID = CS.SessionID WHERE CS.OfferingID = E.OfferingID AND A.StudentID = E.StudentID AND A.Status = 'Late'),
    E.AttendancePercent,
    AttendanceStatus = CASE 
        WHEN E.EnrollStatus = 'AutoFailDueToAttendance' THEN 'KALDI'
        WHEN E.AttendancePercent IS NULL THEN 'Kayit Yok'
        WHEN E.AttendancePercent >= 80 THEN 'Iyi'
        WHEN E.AttendancePercent >= 60 THEN 'Uyari'
        ELSE 'Kritik'
    END
FROM dbo.Enrollments E
INNER JOIN dbo.Students S ON E.StudentID = S.StudentID
INNER JOIN dbo.CourseOfferings CO ON E.OfferingID = CO.OfferingID
INNER JOIN dbo.Courses C ON CO.CourseID = C.CourseID;
GO
PRINT '   [OK] vw_AttendanceSummary';
GO

-- vw_AcademicWorkload
IF OBJECT_ID('dbo.vw_AcademicWorkload', 'V') IS NOT NULL
    DROP VIEW dbo.vw_AcademicWorkload;
GO
CREATE VIEW dbo.vw_AcademicWorkload
AS
SELECT 
    A.AcademicID, U.Username, A.Title, D.DepartmentName,
    TotalOfferings = COUNT(DISTINCT CO.OfferingID),
    TotalStudents = COUNT(DISTINCT E.StudentID),
    PendingGrades = SUM(CASE WHEN E.LetterGrade IS NULL AND E.EnrollStatus = 'Active' THEN 1 ELSE 0 END)
FROM dbo.Academics A
INNER JOIN dbo.Users U ON A.AcademicID = U.UserID
INNER JOIN dbo.Departments D ON A.DepartmentID = D.DepartmentID
LEFT JOIN dbo.CourseOfferings CO ON A.AcademicID = CO.AcademicID
LEFT JOIN dbo.Enrollments E ON CO.OfferingID = E.OfferingID
GROUP BY A.AcademicID, U.Username, A.Title, D.DepartmentName;
GO
PRINT '   [OK] vw_AcademicWorkload';
GO

PRINT '>>> Views completed.';
GO

/* =========================================================
   PART 3: CURSOR-BASED STORED PROCEDURES
   ========================================================= */

PRINT '';
PRINT '>>> Creating Cursor-based Stored Procedures...';
GO

-- sp_SendBulkNotification
IF OBJECT_ID('dbo.sp_SendBulkNotification', 'P') IS NOT NULL
    DROP PROCEDURE dbo.sp_SendBulkNotification;
GO
CREATE PROCEDURE dbo.sp_SendBulkNotification
    @Title NVARCHAR(150),
    @Message NVARCHAR(1000),
    @NotificationType NVARCHAR(30) = 'General',
    @TargetRole NVARCHAR(50) = 'Student',
    @SentCount INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @UserID INT;
    DECLARE @Counter INT = 0;
    
    DECLARE notification_cursor CURSOR FOR
        SELECT U.UserID FROM dbo.Users U
        INNER JOIN dbo.Roles R ON U.RoleID = R.RoleID
        WHERE U.IsActive = 1 AND (@TargetRole = 'All' OR R.RoleName = @TargetRole);
    
    OPEN notification_cursor;
    FETCH NEXT FROM notification_cursor INTO @UserID;
    
    WHILE @@FETCH_STATUS = 0
    BEGIN
        INSERT INTO dbo.Notifications (UserID, Type, Title, Message, IsRead)
        VALUES (@UserID, @NotificationType, @Title, @Message, 0);
        SET @Counter = @Counter + 1;
        FETCH NEXT FROM notification_cursor INTO @UserID;
    END
    
    CLOSE notification_cursor;
    DEALLOCATE notification_cursor;
    
    SET @SentCount = @Counter;
END;
GO
PRINT '   [OK] sp_SendBulkNotification (CURSOR example)';
GO

-- sp_RecalculateAllGPAs
IF OBJECT_ID('dbo.sp_RecalculateAllGPAs', 'P') IS NOT NULL
    DROP PROCEDURE dbo.sp_RecalculateAllGPAs;
GO
CREATE PROCEDURE dbo.sp_RecalculateAllGPAs
    @UpdatedCount INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @StudentID INT;
    DECLARE @Counter INT = 0;
    
    CREATE TABLE #GPAResults (StudentID INT, StudentNumber NVARCHAR(20), GPA DECIMAL(4,2));
    
    DECLARE gpa_cursor CURSOR FOR
        SELECT S.StudentID FROM dbo.Students S
        INNER JOIN dbo.Users U ON S.StudentID = U.UserID WHERE U.IsActive = 1;
    
    OPEN gpa_cursor;
    FETCH NEXT FROM gpa_cursor INTO @StudentID;
    
    WHILE @@FETCH_STATUS = 0
    BEGIN
        INSERT INTO #GPAResults 
        SELECT @StudentID, S.StudentNumber, dbo.fn_CalculateStudentGPA(@StudentID)
        FROM dbo.Students S WHERE S.StudentID = @StudentID;
        SET @Counter = @Counter + 1;
        FETCH NEXT FROM gpa_cursor INTO @StudentID;
    END
    
    CLOSE gpa_cursor;
    DEALLOCATE gpa_cursor;
    
    SET @UpdatedCount = @Counter;
    SELECT * FROM #GPAResults ORDER BY GPA DESC;
    DROP TABLE #GPAResults;
END;
GO
PRINT '   [OK] sp_RecalculateAllGPAs (CURSOR example)';
GO

PRINT '>>> Cursor-based SPs completed.';
GO

/* =========================================================
   VERIFICATION
   ========================================================= */

PRINT '';
PRINT '==============================================';
PRINT 'Migration 003 Completed Successfully!';
PRINT '==============================================';
PRINT '';
PRINT 'Summary:';
PRINT '  Functions: 5';
PRINT '  Views: 4';
PRINT '  Cursor SPs: 2';
PRINT '';
PRINT 'Test commands:';
PRINT '  SELECT dbo.fn_CalculateLetterGrade(85);';
PRINT '  SELECT dbo.fn_GetGradePoint(''BA'');';
PRINT '  SELECT * FROM dbo.vw_StudentTranscript WHERE StudentID = 3;';
PRINT '  SELECT * FROM dbo.vw_CourseStatistics;';
GO

