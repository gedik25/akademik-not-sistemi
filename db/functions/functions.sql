/*
    db/functions/functions.sql
    Purpose: User-Defined Functions for business logic calculations
    Functions encapsulate reusable calculation logic
*/

USE AkademikDB;
GO

SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

/* =========================================================
   Function 1: fn_CalculateLetterGrade (Scalar Function)
   Purpose: Puan girildiğinde harf notunu döner
   Usage: SELECT dbo.fn_CalculateLetterGrade(85.5) -- Returns 'BA'
   ========================================================= */
IF OBJECT_ID('dbo.fn_CalculateLetterGrade', 'FN') IS NOT NULL
    DROP FUNCTION dbo.fn_CalculateLetterGrade;
GO

CREATE FUNCTION dbo.fn_CalculateLetterGrade
(
    @Score DECIMAL(5,2)
)
RETURNS NVARCHAR(2)
AS
BEGIN
    DECLARE @LetterGrade NVARCHAR(2);
    
    SET @LetterGrade = CASE 
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
    
    RETURN @LetterGrade;
END;
GO

/* =========================================================
   Function 2: fn_GetGradePoint (Scalar Function)
   Purpose: Harf notunun sayısal karşılığını döner (4.0 skala)
   Usage: SELECT dbo.fn_GetGradePoint('BA') -- Returns 3.5
   ========================================================= */
IF OBJECT_ID('dbo.fn_GetGradePoint', 'FN') IS NOT NULL
    DROP FUNCTION dbo.fn_GetGradePoint;
GO

CREATE FUNCTION dbo.fn_GetGradePoint
(
    @LetterGrade NVARCHAR(2)
)
RETURNS DECIMAL(3,2)
AS
BEGIN
    DECLARE @GradePoint DECIMAL(3,2);
    
    SET @GradePoint = CASE @LetterGrade
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
    
    RETURN @GradePoint;
END;
GO

/* =========================================================
   Function 3: fn_CalculateStudentGPA (Scalar Function)
   Purpose: Öğrencinin genel not ortalamasını (GPA) hesaplar
   Usage: SELECT dbo.fn_CalculateStudentGPA(@StudentID)
   Formula: GPA = Σ(Kredi × Not Puanı) / Σ(Kredi)
   ========================================================= */
IF OBJECT_ID('dbo.fn_CalculateStudentGPA', 'FN') IS NOT NULL
    DROP FUNCTION dbo.fn_CalculateStudentGPA;
GO

CREATE FUNCTION dbo.fn_CalculateStudentGPA
(
    @StudentID INT
)
RETURNS DECIMAL(4,2)
AS
BEGIN
    DECLARE @GPA DECIMAL(4,2);
    
    SELECT @GPA = 
        CASE 
            WHEN SUM(C.Credit) = 0 OR SUM(C.Credit) IS NULL THEN NULL
            ELSE CAST(
                SUM(C.Credit * dbo.fn_GetGradePoint(E.LetterGrade)) / SUM(C.Credit) 
                AS DECIMAL(4,2)
            )
        END
    FROM dbo.Enrollments E
    INNER JOIN dbo.CourseOfferings CO ON E.OfferingID = CO.OfferingID
    INNER JOIN dbo.Courses C ON CO.CourseID = C.CourseID
    WHERE E.StudentID = @StudentID
      AND E.LetterGrade IS NOT NULL
      AND E.EnrollStatus NOT IN ('Dropped', 'AutoFailDueToAttendance');
    
    RETURN @GPA;
END;
GO

/* =========================================================
   Function 4: fn_GetStudentGrades (Table-Valued Function)
   Purpose: Öğrencinin tüm notlarını tablo olarak döner
   Usage: SELECT * FROM dbo.fn_GetStudentGrades(@StudentID)
   ========================================================= */
IF OBJECT_ID('dbo.fn_GetStudentGrades', 'IF') IS NOT NULL
    DROP FUNCTION dbo.fn_GetStudentGrades;
GO

CREATE FUNCTION dbo.fn_GetStudentGrades
(
    @StudentID INT
)
RETURNS TABLE
AS
RETURN
(
    SELECT 
        E.EnrollmentID,
        C.CourseCode,
        C.CourseName,
        C.Credit,
        CO.Term,
        E.CurrentAverage,
        E.LetterGrade,
        GradePoint = dbo.fn_GetGradePoint(E.LetterGrade),
        WeightedPoints = C.Credit * dbo.fn_GetGradePoint(E.LetterGrade),
        E.AttendancePercent,
        E.EnrollStatus
    FROM dbo.Enrollments E
    INNER JOIN dbo.CourseOfferings CO ON E.OfferingID = CO.OfferingID
    INNER JOIN dbo.Courses C ON CO.CourseID = C.CourseID
    WHERE E.StudentID = @StudentID
);
GO

/* =========================================================
   Function 5: fn_CalculateAttendancePercent (Scalar Function)
   Purpose: Devam yüzdesini hesaplar
   Usage: SELECT dbo.fn_CalculateAttendancePercent(@EnrollmentID)
   ========================================================= */
IF OBJECT_ID('dbo.fn_CalculateAttendancePercent', 'FN') IS NOT NULL
    DROP FUNCTION dbo.fn_CalculateAttendancePercent;
GO

CREATE FUNCTION dbo.fn_CalculateAttendancePercent
(
    @EnrollmentID INT
)
RETURNS DECIMAL(5,2)
AS
BEGIN
    DECLARE @Percent DECIMAL(5,2);
    DECLARE @StudentID INT;
    DECLARE @OfferingID INT;
    DECLARE @TotalSessions INT;
    DECLARE @PresentCount INT;
    DECLARE @LateCount INT;
    DECLARE @ExcusedCount INT;
    
    -- Get enrollment details
    SELECT @StudentID = StudentID, @OfferingID = OfferingID
    FROM dbo.Enrollments WHERE EnrollmentID = @EnrollmentID;
    
    -- Count total sessions
    SELECT @TotalSessions = COUNT(*)
    FROM dbo.ClassSessions
    WHERE OfferingID = @OfferingID;
    
    IF @TotalSessions = 0
        RETURN NULL;
    
    -- Count attendance by status
    SELECT 
        @PresentCount = SUM(CASE WHEN A.Status = 'Present' THEN 1 ELSE 0 END),
        @LateCount = SUM(CASE WHEN A.Status = 'Late' THEN 1 ELSE 0 END),
        @ExcusedCount = SUM(CASE WHEN A.Status = 'Excused' THEN 1 ELSE 0 END)
    FROM dbo.Attendance A
    INNER JOIN dbo.ClassSessions CS ON A.SessionID = CS.SessionID
    WHERE CS.OfferingID = @OfferingID AND A.StudentID = @StudentID;
    
    -- Calculate: Present = 100%, Late = 50%, Excused = 100%
    SET @Percent = CAST(
        (ISNULL(@PresentCount, 0) + ISNULL(@LateCount, 0) * 0.5 + ISNULL(@ExcusedCount, 0)) * 100.0 / @TotalSessions
        AS DECIMAL(5,2)
    );
    
    RETURN @Percent;
END;
GO

/* =========================================================
   Function 6: fn_IsPassingGrade (Scalar Function)
   Purpose: Notun geçer not olup olmadığını kontrol eder
   Usage: SELECT dbo.fn_IsPassingGrade('CC') -- Returns 1
   ========================================================= */
IF OBJECT_ID('dbo.fn_IsPassingGrade', 'FN') IS NOT NULL
    DROP FUNCTION dbo.fn_IsPassingGrade;
GO

CREATE FUNCTION dbo.fn_IsPassingGrade
(
    @LetterGrade NVARCHAR(2)
)
RETURNS BIT
AS
BEGIN
    RETURN CASE 
        WHEN @LetterGrade IN ('AA', 'BA', 'BB', 'CB', 'CC', 'DC', 'DD') THEN 1
        ELSE 0
    END;
END;
GO

PRINT '=== Functions Created Successfully ===';
PRINT 'fn_CalculateLetterGrade - Puan -> Harf notu dönüşümü';
PRINT 'fn_GetGradePoint - Harf notu -> 4.0 skala dönüşümü';
PRINT 'fn_CalculateStudentGPA - Öğrenci GPA hesaplama';
PRINT 'fn_GetStudentGrades - Öğrenci not tablosu (TVF)';
PRINT 'fn_CalculateAttendancePercent - Devam yüzdesi hesaplama';
PRINT 'fn_IsPassingGrade - Geçer not kontrolü';
GO

