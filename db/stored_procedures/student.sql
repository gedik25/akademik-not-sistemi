/*
    db/stored_procedures/student.sql
    Student & academic management stored procedures.
    Run after tables.sql and auth.sql.
*/

SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

/* =========================================================
   sp_RegisterStudent
   Creates a user with Student role and inserts Students row.
   ========================================================= */
IF OBJECT_ID('dbo.sp_RegisterStudent', 'P') IS NOT NULL DROP PROCEDURE dbo.sp_RegisterStudent;
GO
CREATE PROCEDURE dbo.sp_RegisterStudent
    @Username        NVARCHAR(50),
    @PasswordPlain   NVARCHAR(255),
    @Email           NVARCHAR(255),
    @Phone           NVARCHAR(20) = NULL,
    @StudentNumber   NVARCHAR(20),
    @NationalID      NVARCHAR(20),
    @FirstName       NVARCHAR(50),
    @LastName        NVARCHAR(50),
    @BirthDate       DATE,
    @Gender          CHAR(1) = NULL,
    @DepartmentID    INT,
    @ProgramID       INT = NULL,
    @AdvisorID       INT = NULL,
    @EnrollmentYear  SMALLINT = NULL,
    @NewStudentID    INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE
        @RoleID INT,
        @Salt VARBINARY(128),
        @Hash VARBINARY(256);

    SELECT @RoleID = RoleID FROM dbo.Roles WHERE RoleName = 'Student';
    IF @RoleID IS NULL
        THROW 53000, 'Student rolü tanımlı değil.', 1;

    IF @AdvisorID IS NOT NULL AND NOT EXISTS (SELECT 1 FROM dbo.Academics WHERE AcademicID = @AdvisorID)
        THROW 53001, 'Danışman bulunamadı.', 1;

    SET @Salt = CRYPT_GEN_RANDOM(32);
    SET @Hash = HASHBYTES('SHA2_512', @Salt + CONVERT(VARBINARY(512), @PasswordPlain));

    BEGIN TRY
        BEGIN TRAN;

        INSERT INTO dbo.Users (RoleID, Username, PasswordHash, PasswordSalt, Email, Phone)
        VALUES (@RoleID, @Username, @Hash, @Salt, @Email, @Phone);

        SET @NewStudentID = SCOPE_IDENTITY();

        INSERT INTO dbo.Students
        (
            StudentID, StudentNumber, NationalID, FirstName, LastName,
            BirthDate, Gender, DepartmentID, ProgramID, AdvisorID, EnrollmentYear
        )
        VALUES
        (
            @NewStudentID, @StudentNumber, @NationalID, @FirstName, @LastName,
            @BirthDate, @Gender, @DepartmentID, @ProgramID, @AdvisorID, @EnrollmentYear
        );

        COMMIT TRAN;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRAN;
        THROW;
    END CATCH;
END;
GO

/* =========================================================
   sp_AssignAdvisor
   ========================================================= */
IF OBJECT_ID('dbo.sp_AssignAdvisor', 'P') IS NOT NULL DROP PROCEDURE dbo.sp_AssignAdvisor;
GO
CREATE PROCEDURE dbo.sp_AssignAdvisor
    @StudentID INT,
    @AdvisorID INT
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1 FROM dbo.Students WHERE StudentID = @StudentID)
        THROW 53002, 'Öğrenci bulunamadı.', 1;

    IF NOT EXISTS (SELECT 1 FROM dbo.Academics WHERE AcademicID = @AdvisorID)
        THROW 53003, 'Akademik danışman bulunamadı.', 1;

    UPDATE dbo.Students
    SET AdvisorID = @AdvisorID
    WHERE StudentID = @StudentID;
END;
GO

/* =========================================================
   sp_ListStudentsByDepartment
   ========================================================= */
IF OBJECT_ID('dbo.sp_ListStudentsByDepartment', 'P') IS NOT NULL DROP PROCEDURE dbo.sp_ListStudentsByDepartment;
GO
CREATE PROCEDURE dbo.sp_ListStudentsByDepartment
    @DepartmentID INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        S.StudentID,
        S.StudentNumber,
        S.FirstName,
        S.LastName,
        S.EnrollmentYear,
        P.ProgramName,
        AdvisorName = (SELECT CONCAT(U2.Username, ' (', A2.Title, ')')
                       FROM dbo.Academics A2
                       INNER JOIN dbo.Users U2 ON A2.AcademicID = U2.UserID
                       WHERE A2.AcademicID = S.AdvisorID)
    FROM dbo.Students S
    LEFT JOIN dbo.Programs P ON S.ProgramID = P.ProgramID
    WHERE S.DepartmentID = @DepartmentID;
END;
GO

/* =========================================================
   sp_RegisterAcademic
   ========================================================= */
IF OBJECT_ID('dbo.sp_RegisterAcademic', 'P') IS NOT NULL DROP PROCEDURE dbo.sp_RegisterAcademic;
GO
CREATE PROCEDURE dbo.sp_RegisterAcademic
    @Username        NVARCHAR(50),
    @PasswordPlain   NVARCHAR(255),
    @Email           NVARCHAR(255),
    @Phone           NVARCHAR(20) = NULL,
    @Title           NVARCHAR(50) = NULL,
    @DepartmentID    INT,
    @Office          NVARCHAR(50) = NULL,
    @PhoneExtension  NVARCHAR(10) = NULL,
    @NewAcademicID   INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE
        @RoleID INT,
        @Salt VARBINARY(128),
        @Hash VARBINARY(256);

    SELECT @RoleID = RoleID FROM dbo.Roles WHERE RoleName = 'Academic';
    IF @RoleID IS NULL
        THROW 53004, 'Academic rolü tanımlı değil.', 1;

    SET @Salt = CRYPT_GEN_RANDOM(32);
    SET @Hash = HASHBYTES('SHA2_512', @Salt + CONVERT(VARBINARY(512), @PasswordPlain));

    BEGIN TRY
        BEGIN TRAN;

        INSERT INTO dbo.Users (RoleID, Username, PasswordHash, PasswordSalt, Email, Phone)
        VALUES (@RoleID, @Username, @Hash, @Salt, @Email, @Phone);

        SET @NewAcademicID = SCOPE_IDENTITY();

        INSERT INTO dbo.Academics (AcademicID, Title, DepartmentID, Office, PhoneExtension)
        VALUES (@NewAcademicID, @Title, @DepartmentID, @Office, @PhoneExtension);

        COMMIT TRAN;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRAN;
        THROW;
    END CATCH;
END;
GO

