/*
    db/stored_procedures/course.sql
    Course catalog, offering, and enrollment operations.
*/

SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

/* =========================================================
   Course CRUD
   ========================================================= */
IF OBJECT_ID('dbo.sp_CreateCourse', 'P') IS NOT NULL DROP PROCEDURE dbo.sp_CreateCourse;
GO
CREATE PROCEDURE dbo.sp_CreateCourse
    @CourseCode NVARCHAR(20),
    @CourseName NVARCHAR(150),
    @ProgramID  INT,
    @Credit     DECIMAL(4,2),
    @ECTS       DECIMAL(4,1),
    @SemesterOffered TINYINT = NULL,
    @NewCourseID INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO dbo.Courses (CourseCode, CourseName, ProgramID, Credit, ECTS, SemesterOffered)
    VALUES (@CourseCode, @CourseName, @ProgramID, @Credit, @ECTS, @SemesterOffered);

    SET @NewCourseID = SCOPE_IDENTITY();
END;
GO

IF OBJECT_ID('dbo.sp_UpdateCourse', 'P') IS NOT NULL DROP PROCEDURE dbo.sp_UpdateCourse;
GO
CREATE PROCEDURE dbo.sp_UpdateCourse
    @CourseID   INT,
    @CourseName NVARCHAR(150),
    @Credit     DECIMAL(4,2),
    @ECTS       DECIMAL(4,1),
    @SemesterOffered TINYINT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE dbo.Courses
    SET CourseName = @CourseName,
        Credit = @Credit,
        ECTS = @ECTS,
        SemesterOffered = @SemesterOffered
    WHERE CourseID = @CourseID;

    IF @@ROWCOUNT = 0
        THROW 54000, 'Güncellenecek ders bulunamadı.', 1;
END;
GO

IF OBJECT_ID('dbo.sp_DeleteCourse', 'P') IS NOT NULL DROP PROCEDURE dbo.sp_DeleteCourse;
GO
CREATE PROCEDURE dbo.sp_DeleteCourse
    @CourseID INT
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS (SELECT 1 FROM dbo.CourseOfferings WHERE CourseID = @CourseID)
        THROW 54001, 'Açılmış bölüm kayıtları olan ders silinemez.', 1;

    DELETE FROM dbo.Courses WHERE CourseID = @CourseID;

    IF @@ROWCOUNT = 0
        THROW 54002, 'Silinecek ders bulunamadı.', 1;
END;
GO

/* =========================================================
   Course offerings
   ========================================================= */
IF OBJECT_ID('dbo.sp_OpenCourseOffering', 'P') IS NOT NULL DROP PROCEDURE dbo.sp_OpenCourseOffering;
GO
CREATE PROCEDURE dbo.sp_OpenCourseOffering
    @CourseID    INT,
    @AcademicID  INT,
    @Term        NVARCHAR(20),
    @Section     NVARCHAR(5),
    @Capacity    INT,
    @ScheduleJSON NVARCHAR(MAX),
    @NewOfferingID INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1 FROM dbo.Academics WHERE AcademicID = @AcademicID)
        THROW 54003, 'Dersi açacak akademisyen bulunamadı.', 1;

    INSERT INTO dbo.CourseOfferings (CourseID, AcademicID, Term, Section, Capacity, ScheduleJSON)
    VALUES (@CourseID, @AcademicID, @Term, @Section, @Capacity, @ScheduleJSON);

    SET @NewOfferingID = SCOPE_IDENTITY();

    INSERT INTO dbo.AttendancePolicies (OfferingID, MaxAbsencePercent, WarningThresholdPercent, AutoFailPercent)
    VALUES (@NewOfferingID, 30.0, 20.0, 30.0);
END;
GO

IF OBJECT_ID('dbo.sp_GetCourseCatalog', 'P') IS NOT NULL DROP PROCEDURE dbo.sp_GetCourseCatalog;
GO
CREATE PROCEDURE dbo.sp_GetCourseCatalog
    @ProgramID INT = NULL,
    @Term      NVARCHAR(20) = NULL
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
        AcademicName = U.Username
    FROM dbo.CourseOfferings CO
    INNER JOIN dbo.Courses C ON CO.CourseID = C.CourseID
    INNER JOIN dbo.Users U ON CO.AcademicID = U.UserID
    WHERE (@ProgramID IS NULL OR C.ProgramID = @ProgramID)
      AND (@Term IS NULL OR CO.Term = @Term)
    ORDER BY CO.Term DESC, C.CourseCode;
END;
GO

/* =========================================================
   Enrollment management
   ========================================================= */
IF OBJECT_ID('dbo.sp_EnrollStudent', 'P') IS NOT NULL DROP PROCEDURE dbo.sp_EnrollStudent;
GO
CREATE PROCEDURE dbo.sp_EnrollStudent
    @OfferingID INT,
    @StudentID  INT,
    @EnrollStatus NVARCHAR(30) = 'Active'
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @CurrentCount INT, @Capacity INT;

    IF EXISTS (SELECT 1 FROM dbo.Enrollments WHERE OfferingID = @OfferingID AND StudentID = @StudentID)
        THROW 54004, 'Öğrenci zaten bu derse kayıtlı.', 1;

    SELECT
        @CurrentCount = COUNT(*),
        @Capacity = CO.Capacity
    FROM dbo.Enrollments E
    RIGHT JOIN dbo.CourseOfferings CO ON CO.OfferingID = @OfferingID
    WHERE CO.OfferingID = @OfferingID
    GROUP BY CO.Capacity;

    IF @Capacity IS NULL
        THROW 54005, 'Ders açılışı bulunamadı.', 1;

    IF @CurrentCount >= @Capacity
        THROW 54006, 'Ders kapasitesi dolu.', 1;

    INSERT INTO dbo.Enrollments (OfferingID, StudentID, EnrollStatus)
    VALUES (@OfferingID, @StudentID, @EnrollStatus);
END;
GO

IF OBJECT_ID('dbo.sp_DropEnrollment', 'P') IS NOT NULL DROP PROCEDURE dbo.sp_DropEnrollment;
GO
CREATE PROCEDURE dbo.sp_DropEnrollment
    @EnrollmentID INT,
    @Reason NVARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE dbo.Enrollments
    SET EnrollStatus = 'Dropped',
        DroppedAt = SYSUTCDATETIME()
    WHERE EnrollmentID = @EnrollmentID;

    IF @@ROWCOUNT = 0
        THROW 54007, 'Kayıt bulunamadı.', 1;

    INSERT INTO dbo.AuditLog (TableName, RecordID, ActionType, ChangedBy, ChangeDetails)
    VALUES ('Enrollments', CAST(@EnrollmentID AS NVARCHAR(100)), 'Drop', @EnrollmentID, @Reason);
END;
GO

IF OBJECT_ID('dbo.sp_GetStudentSchedule', 'P') IS NOT NULL DROP PROCEDURE dbo.sp_GetStudentSchedule;
GO
CREATE PROCEDURE dbo.sp_GetStudentSchedule
    @StudentID INT,
    @Term NVARCHAR(20)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        CO.OfferingID,
        C.CourseCode,
        C.CourseName,
        CO.Term,
        CO.Section,
        CO.ScheduleJSON
    FROM dbo.Enrollments E
    INNER JOIN dbo.CourseOfferings CO ON E.OfferingID = CO.OfferingID
    INNER JOIN dbo.Courses C ON CO.CourseID = C.CourseID
    WHERE E.StudentID = @StudentID
      AND CO.Term = @Term
      AND E.EnrollStatus IN ('Active', 'Completed');
END;
GO

