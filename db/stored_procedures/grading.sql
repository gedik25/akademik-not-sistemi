/*
    db/stored_procedures/grading.sql
    Grade component management and transcript related procedures.
*/

SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

/* =========================================================
   sp_DefineGradeComponent
   ========================================================= */
IF OBJECT_ID('dbo.sp_DefineGradeComponent', 'P') IS NOT NULL DROP PROCEDURE dbo.sp_DefineGradeComponent;
GO
CREATE PROCEDURE dbo.sp_DefineGradeComponent
    @OfferingID    INT,
    @ComponentName NVARCHAR(50),
    @WeightPercent DECIMAL(5,2),
    @IsMandatory   BIT = 1,
    @ComponentID   INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @WeightSum DECIMAL(6,2);

    SELECT @WeightSum = ISNULL(SUM(WeightPercent), 0)
    FROM dbo.GradeComponents
    WHERE OfferingID = @OfferingID;

    IF (@WeightSum + @WeightPercent) > 100
        THROW 55000, 'Toplam ağırlık %100''ü aşamaz.', 1;

    INSERT INTO dbo.GradeComponents (OfferingID, ComponentName, WeightPercent, IsMandatory)
    VALUES (@OfferingID, @ComponentName, @WeightPercent, @IsMandatory);

    SET @ComponentID = SCOPE_IDENTITY();
END;
GO

/* =========================================================
   sp_RecordGrade
   ========================================================= */
IF OBJECT_ID('dbo.sp_RecordGrade', 'P') IS NOT NULL DROP PROCEDURE dbo.sp_RecordGrade;
GO
CREATE PROCEDURE dbo.sp_RecordGrade
    @EnrollmentID INT,
    @ComponentID  INT,
    @Score        DECIMAL(5,2),
    @GradedBy     INT,
    @Notes        NVARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @OldScore DECIMAL(5,2) = NULL;
    DECLARE @ActionType NVARCHAR(30);
    DECLARE @ComponentName NVARCHAR(50);

    -- Bileşen adını al
    SELECT @ComponentName = ComponentName FROM dbo.GradeComponents WHERE ComponentID = @ComponentID;

    IF EXISTS (SELECT 1 FROM dbo.Grades WHERE EnrollmentID = @EnrollmentID AND ComponentID = @ComponentID)
    BEGIN
        -- Eski notu sakla
        SELECT @OldScore = Score FROM dbo.Grades WHERE EnrollmentID = @EnrollmentID AND ComponentID = @ComponentID;
        SET @ActionType = 'UpdateGrade';

        UPDATE dbo.Grades
        SET Score = @Score,
            ScoreDate = SYSUTCDATETIME(),
            GradedBy = @GradedBy,
            Notes = @Notes
        WHERE EnrollmentID = @EnrollmentID AND ComponentID = @ComponentID;
    END
    ELSE
    BEGIN
        SET @ActionType = 'InsertGrade';

        INSERT INTO dbo.Grades (EnrollmentID, ComponentID, Score, GradedBy, Notes)
        VALUES (@EnrollmentID, @ComponentID, @Score, @GradedBy, @Notes);
    END

    -- AuditLog kaydı
    INSERT INTO dbo.AuditLog (TableName, RecordID, ActionType, ChangedBy, ChangeDetails)
    VALUES (
        'Grades',
        CONCAT(@EnrollmentID, '-', @ComponentID),
        @ActionType,
        @GradedBy,
        CONCAT(@ComponentName, ': ', 
               CASE WHEN @OldScore IS NOT NULL THEN CONCAT(CAST(@OldScore AS NVARCHAR(10)), ' -> ') ELSE '' END,
               CAST(@Score AS NVARCHAR(10)))
    );
END;
GO

/* =========================================================
   sp_GetGradeBook
   ========================================================= */
IF OBJECT_ID('dbo.sp_GetGradeBook', 'P') IS NOT NULL DROP PROCEDURE dbo.sp_GetGradeBook;
GO
CREATE PROCEDURE dbo.sp_GetGradeBook
    @OfferingID INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        S.StudentNumber,
        S.FirstName,
        S.LastName,
        GC.ComponentName,
        G.Score,
        G.ScoreDate
    FROM dbo.GradeComponents GC
    LEFT JOIN dbo.Grades G
        ON GC.ComponentID = G.ComponentID
    LEFT JOIN dbo.Enrollments E
        ON G.EnrollmentID = E.EnrollmentID
    LEFT JOIN dbo.Students S
        ON E.StudentID = S.StudentID
    WHERE GC.OfferingID = @OfferingID
    ORDER BY S.StudentNumber, GC.ComponentName;
END;
GO

/* =========================================================
   sp_GetStudentTranscript
   ========================================================= */
IF OBJECT_ID('dbo.sp_GetStudentTranscript', 'P') IS NOT NULL DROP PROCEDURE dbo.sp_GetStudentTranscript;
GO
CREATE PROCEDURE dbo.sp_GetStudentTranscript
    @StudentID INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        CO.Term,
        C.CourseCode,
        C.CourseName,
        C.Credit,
        E.CurrentAverage,
        E.LetterGrade
    FROM dbo.Enrollments E
    INNER JOIN dbo.CourseOfferings CO ON E.OfferingID = CO.OfferingID
    INNER JOIN dbo.Courses C ON CO.CourseID = C.CourseID
    WHERE E.StudentID = @StudentID
    ORDER BY CO.Term;
END;
GO

/* =========================================================
   sp_ApproveFinalGrades
   ========================================================= */
IF OBJECT_ID('dbo.sp_ApproveFinalGrades', 'P') IS NOT NULL DROP PROCEDURE dbo.sp_ApproveFinalGrades;
GO
CREATE PROCEDURE dbo.sp_ApproveFinalGrades
    @OfferingID INT,
    @AcademicID INT
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1 FROM dbo.CourseOfferings WHERE OfferingID = @OfferingID AND AcademicID = @AcademicID)
        THROW 55001, 'Sadece dersi veren akademisyen notları onaylayabilir.', 1;

    DECLARE @WeightSum DECIMAL(6,2);
    SELECT @WeightSum = SUM(WeightPercent) FROM dbo.GradeComponents WHERE OfferingID = @OfferingID;

    IF @WeightSum <> 100
        THROW 55002, 'Bileşen ağırlıkları %100 olmalıdır.', 1;

    UPDATE dbo.Enrollments
    SET EnrollStatus = CASE WHEN CurrentAverage IS NULL THEN EnrollStatus ELSE 'Completed' END,
        StatusUpdatedAt = SYSUTCDATETIME()
    WHERE OfferingID = @OfferingID AND EnrollStatus <> 'Dropped';

    INSERT INTO dbo.AuditLog (TableName, RecordID, ActionType, ChangedBy, ChangeDetails)
    SELECT 'Enrollments', CAST(EnrollmentID AS NVARCHAR(100)), 'ApproveGrades', @AcademicID,
           CONCAT('Final grades approved for offering ', @OfferingID)
    FROM dbo.Enrollments
    WHERE OfferingID = @OfferingID;
END;
GO

