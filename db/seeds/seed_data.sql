/*
    db/seeds/seed_data.sql
    Minimal reference data and demo records.
    Execute after schema, stored procedures, and triggers are deployed.
*/

SET NOCOUNT ON;
GO

/* =========================================================
   Roles
   ========================================================= */
IF NOT EXISTS (SELECT 1 FROM dbo.Roles WHERE RoleName = 'Admin')
    INSERT INTO dbo.Roles (RoleName, Description) VALUES ('Admin', 'Sistem yöneticisi');

IF NOT EXISTS (SELECT 1 FROM dbo.Roles WHERE RoleName = 'Academic')
    INSERT INTO dbo.Roles (RoleName, Description) VALUES ('Academic', 'Öğretim görevlisi');

IF NOT EXISTS (SELECT 1 FROM dbo.Roles WHERE RoleName = 'Student')
    INSERT INTO dbo.Roles (RoleName, Description) VALUES ('Student', 'Öğrenci');

IF NOT EXISTS (SELECT 1 FROM dbo.Roles WHERE RoleName = 'Advisor')
    INSERT INTO dbo.Roles (RoleName, Description) VALUES ('Advisor', 'Danışman rolü');
GO

/* =========================================================
   Departments & Programs
   ========================================================= */
IF NOT EXISTS (SELECT 1 FROM dbo.Departments WHERE DepartmentName = 'Bilgisayar Mühendisliği')
BEGIN
    INSERT INTO dbo.Departments (FacultyName, DepartmentName)
    VALUES ('Mühendislik Fakültesi', 'Bilgisayar Mühendisliği');
END
GO

DECLARE @DepartmentID INT;
SELECT @DepartmentID = DepartmentID FROM dbo.Departments WHERE DepartmentName = 'Bilgisayar Mühendisliği';

IF NOT EXISTS (SELECT 1 FROM dbo.Programs WHERE ProgramName = 'Bilgisayar Mühendisliği Lisans')
BEGIN
    INSERT INTO dbo.Programs (DepartmentID, ProgramName, DegreeLevel, CreditRequirement)
    VALUES (@DepartmentID, 'Bilgisayar Mühendisliği Lisans', 'Bachelor', 240);
END
GO

/* =========================================================
   All remaining inserts in a single batch so variables persist
   ========================================================= */
DECLARE @DepartmentID INT;
DECLARE @ProgramID INT;
DECLARE @AdminID INT;
DECLARE @AcademicID INT;
DECLARE @StudentID INT;
DECLARE @CourseID INT;
DECLARE @OfferingID INT;

-- Lookup IDs
SELECT @DepartmentID = DepartmentID FROM dbo.Departments WHERE DepartmentName = 'Bilgisayar Mühendisliği';
SELECT @ProgramID = ProgramID FROM dbo.Programs WHERE ProgramName = 'Bilgisayar Mühendisliği Lisans';

/* =========================================================
   Admin user
   ========================================================= */
IF NOT EXISTS (SELECT 1 FROM dbo.Users WHERE Username = 'admin')
BEGIN
    EXEC dbo.sp_CreateUser
        @RoleName = 'Admin',
        @Username = 'admin',
        @PasswordPlain = 'Admin@123',
        @Email = 'admin@example.edu',
        @Phone = '+900000000000',
        @NewUserID = @AdminID OUTPUT;
END
ELSE
BEGIN
    SELECT @AdminID = UserID FROM dbo.Users WHERE Username = 'admin';
END

/* =========================================================
   Sample academic
   ========================================================= */
IF NOT EXISTS (SELECT 1 FROM dbo.Users WHERE Username = 'ayse.akademik')
BEGIN
    EXEC dbo.sp_RegisterAcademic
        @Username = 'ayse.akademik',
        @PasswordPlain = 'Akademik@123',
        @Email = 'ayse.akademik@example.edu',
        @Phone = '+900000000001',
        @Title = 'Dr. Öğr. Üyesi',
        @DepartmentID = @DepartmentID,
        @Office = 'B-204',
        @PhoneExtension = '204',
        @NewAcademicID = @AcademicID OUTPUT;
END
ELSE
BEGIN
    SELECT @AcademicID = UserID FROM dbo.Users WHERE Username = 'ayse.akademik';
END

UPDATE dbo.Departments
SET ChairID = @AcademicID
WHERE DepartmentName = 'Bilgisayar Mühendisliği'
  AND (ChairID IS NULL OR ChairID <> @AcademicID);

/* =========================================================
   Sample student
   ========================================================= */
IF NOT EXISTS (SELECT 1 FROM dbo.Users WHERE Username = 'mehmet.ogrenci')
BEGIN
    EXEC dbo.sp_RegisterStudent
        @Username = 'mehmet.ogrenci',
        @PasswordPlain = 'Ogrenci@123',
        @Email = 'mehmet.ogrenci@example.edu',
        @Phone = '+900000000002',
        @StudentNumber = '20250001',
        @NationalID = '12345678901',
        @FirstName = 'Mehmet',
        @LastName = 'Yıldız',
        @BirthDate = '2003-04-15',
        @Gender = 'M',
        @DepartmentID = @DepartmentID,
        @ProgramID = @ProgramID,
        @AdvisorID = @AcademicID,
        @EnrollmentYear = 2025,
        @NewStudentID = @StudentID OUTPUT;
END
ELSE
BEGIN
    SELECT @StudentID = UserID FROM dbo.Users WHERE Username = 'mehmet.ogrenci';
END

/* =========================================================
   Sample course & offering
   ========================================================= */
IF NOT EXISTS (SELECT 1 FROM dbo.Courses WHERE CourseCode = 'CENG101')
BEGIN
    EXEC dbo.sp_CreateCourse
        @CourseCode = 'CENG101',
        @CourseName = 'Programlamaya Giriş',
        @ProgramID = @ProgramID,
        @Credit = 4,
        @ECTS = 6,
        @SemesterOffered = 1,
        @NewCourseID = @CourseID OUTPUT;
END
ELSE
BEGIN
    SELECT @CourseID = CourseID FROM dbo.Courses WHERE CourseCode = 'CENG101';
END

IF NOT EXISTS (SELECT 1 FROM dbo.CourseOfferings WHERE CourseID = @CourseID AND Term = '2025-FALL' AND Section = 'A')
BEGIN
    EXEC dbo.sp_OpenCourseOffering
        @CourseID = @CourseID,
        @AcademicID = @AcademicID,
        @Term = '2025-FALL',
        @Section = 'A',
        @Capacity = 60,
        @ScheduleJSON = N'[{ "day": "Mon", "start": "09:00", "end": "11:00", "room": "B-101" }]',
        @NewOfferingID = @OfferingID OUTPUT;
END
ELSE
BEGIN
    SELECT @OfferingID = OfferingID FROM dbo.CourseOfferings WHERE CourseID = @CourseID AND Term = '2025-FALL' AND Section = 'A';
END

/* =========================================================
   Sample enrollment
   ========================================================= */
IF NOT EXISTS (SELECT 1 FROM dbo.Enrollments WHERE OfferingID = @OfferingID AND StudentID = @StudentID)
BEGIN
    EXEC dbo.sp_EnrollStudent
        @OfferingID = @OfferingID,
        @StudentID = @StudentID;
END
GO
