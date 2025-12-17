/*
    db/seeds/sample_data.sql
    Extended sample data - more students, courses, enrollments, grades, attendance.
    Run after seed_data.sql in Azure Data Studio.
*/

SET NOCOUNT ON;
GO

/* =========================================================
   Additional Departments & Programs
   ========================================================= */
IF NOT EXISTS (SELECT 1 FROM dbo.Departments WHERE DepartmentName = 'Elektrik-Elektronik Mühendisliği')
BEGIN
    INSERT INTO dbo.Departments (FacultyName, DepartmentName)
    VALUES ('Mühendislik Fakültesi', 'Elektrik-Elektronik Mühendisliği');
END

IF NOT EXISTS (SELECT 1 FROM dbo.Departments WHERE DepartmentName = 'Makine Mühendisliği')
BEGIN
    INSERT INTO dbo.Departments (FacultyName, DepartmentName)
    VALUES ('Mühendislik Fakültesi', 'Makine Mühendisliği');
END
GO

DECLARE @DeptCompEng INT, @DeptElec INT, @DeptMech INT;
DECLARE @ProgCompEng INT, @ProgElec INT, @ProgMech INT;

SELECT @DeptCompEng = DepartmentID FROM dbo.Departments WHERE DepartmentName = 'Bilgisayar Mühendisliği';
SELECT @DeptElec = DepartmentID FROM dbo.Departments WHERE DepartmentName = 'Elektrik-Elektronik Mühendisliği';
SELECT @DeptMech = DepartmentID FROM dbo.Departments WHERE DepartmentName = 'Makine Mühendisliği';

-- Programs for new departments
IF NOT EXISTS (SELECT 1 FROM dbo.Programs WHERE ProgramName = 'Elektrik-Elektronik Mühendisliği Lisans')
BEGIN
    INSERT INTO dbo.Programs (DepartmentID, ProgramName, DegreeLevel, CreditRequirement)
    VALUES (@DeptElec, 'Elektrik-Elektronik Mühendisliği Lisans', 'Bachelor', 240);
END

IF NOT EXISTS (SELECT 1 FROM dbo.Programs WHERE ProgramName = 'Makine Mühendisliği Lisans')
BEGIN
    INSERT INTO dbo.Programs (DepartmentID, ProgramName, DegreeLevel, CreditRequirement)
    VALUES (@DeptMech, 'Makine Mühendisliği Lisans', 'Bachelor', 240);
END

SELECT @ProgCompEng = ProgramID FROM dbo.Programs WHERE ProgramName = 'Bilgisayar Mühendisliği Lisans';
SELECT @ProgElec = ProgramID FROM dbo.Programs WHERE ProgramName = 'Elektrik-Elektronik Mühendisliği Lisans';
SELECT @ProgMech = ProgramID FROM dbo.Programs WHERE ProgramName = 'Makine Mühendisliği Lisans';

/* =========================================================
   Additional Academics
   ========================================================= */
DECLARE @AcademicID INT;
DECLARE @AyseID INT;

-- Get existing academic (Ayşe)
SELECT @AyseID = UserID FROM dbo.Users WHERE Username = 'ayse.akademik';

-- Academic 2: Ali Demir (Bilgisayar)
IF NOT EXISTS (SELECT 1 FROM dbo.Users WHERE Username = 'ali.demir')
BEGIN
    EXEC dbo.sp_RegisterAcademic
        @Username = 'ali.demir',
        @PasswordPlain = 'Akademik@123',
        @Email = 'ali.demir@example.edu',
        @Phone = '+900000000010',
        @Title = 'Prof. Dr.',
        @DepartmentID = @DeptCompEng,
        @Office = 'B-301',
        @PhoneExtension = '301',
        @NewAcademicID = @AcademicID OUTPUT;
END

-- Academic 3: Fatma Kaya (Elektrik-Elektronik)
IF NOT EXISTS (SELECT 1 FROM dbo.Users WHERE Username = 'fatma.kaya')
BEGIN
    EXEC dbo.sp_RegisterAcademic
        @Username = 'fatma.kaya',
        @PasswordPlain = 'Akademik@123',
        @Email = 'fatma.kaya@example.edu',
        @Phone = '+900000000011',
        @Title = 'Doç. Dr.',
        @DepartmentID = @DeptElec,
        @Office = 'C-105',
        @PhoneExtension = '105',
        @NewAcademicID = @AcademicID OUTPUT;
    
    -- Set as department chair
    UPDATE dbo.Departments SET ChairID = @AcademicID WHERE DepartmentID = @DeptElec;
END

-- Academic 4: Mustafa Yılmaz (Makine)
IF NOT EXISTS (SELECT 1 FROM dbo.Users WHERE Username = 'mustafa.yilmaz')
BEGIN
    EXEC dbo.sp_RegisterAcademic
        @Username = 'mustafa.yilmaz',
        @PasswordPlain = 'Akademik@123',
        @Email = 'mustafa.yilmaz@example.edu',
        @Phone = '+900000000012',
        @Title = 'Dr. Öğr. Üyesi',
        @DepartmentID = @DeptMech,
        @Office = 'D-202',
        @PhoneExtension = '202',
        @NewAcademicID = @AcademicID OUTPUT;
    
    UPDATE dbo.Departments SET ChairID = @AcademicID WHERE DepartmentID = @DeptMech;
END

/* =========================================================
   Additional Students (14 more = 15 total with Mehmet)
   ========================================================= */
DECLARE @StudentID INT;

-- Student 2
IF NOT EXISTS (SELECT 1 FROM dbo.Users WHERE Username = 'zeynep.arslan')
BEGIN
    EXEC dbo.sp_RegisterStudent
        @Username = 'zeynep.arslan',
        @PasswordPlain = 'Ogrenci@123',
        @Email = 'zeynep.arslan@example.edu',
        @Phone = '+900000000020',
        @StudentNumber = '20250002',
        @NationalID = '12345678902',
        @FirstName = 'Zeynep',
        @LastName = 'Arslan',
        @BirthDate = '2003-07-22',
        @Gender = 'F',
        @DepartmentID = @DeptCompEng,
        @ProgramID = @ProgCompEng,
        @AdvisorID = @AyseID,
        @EnrollmentYear = 2025,
        @NewStudentID = @StudentID OUTPUT;
END

-- Student 3
IF NOT EXISTS (SELECT 1 FROM dbo.Users WHERE Username = 'ahmet.celik')
BEGIN
    EXEC dbo.sp_RegisterStudent
        @Username = 'ahmet.celik',
        @PasswordPlain = 'Ogrenci@123',
        @Email = 'ahmet.celik@example.edu',
        @Phone = '+900000000021',
        @StudentNumber = '20250003',
        @NationalID = '12345678903',
        @FirstName = 'Ahmet',
        @LastName = 'Çelik',
        @BirthDate = '2002-11-05',
        @Gender = 'M',
        @DepartmentID = @DeptCompEng,
        @ProgramID = @ProgCompEng,
        @AdvisorID = @AyseID,
        @EnrollmentYear = 2024,
        @NewStudentID = @StudentID OUTPUT;
END

-- Student 4
IF NOT EXISTS (SELECT 1 FROM dbo.Users WHERE Username = 'elif.sahin')
BEGIN
    EXEC dbo.sp_RegisterStudent
        @Username = 'elif.sahin',
        @PasswordPlain = 'Ogrenci@123',
        @Email = 'elif.sahin@example.edu',
        @Phone = '+900000000022',
        @StudentNumber = '20250004',
        @NationalID = '12345678904',
        @FirstName = 'Elif',
        @LastName = 'Şahin',
        @BirthDate = '2003-03-18',
        @Gender = 'F',
        @DepartmentID = @DeptCompEng,
        @ProgramID = @ProgCompEng,
        @AdvisorID = @AyseID,
        @EnrollmentYear = 2025,
        @NewStudentID = @StudentID OUTPUT;
END

-- Student 5
IF NOT EXISTS (SELECT 1 FROM dbo.Users WHERE Username = 'emre.ozturk')
BEGIN
    EXEC dbo.sp_RegisterStudent
        @Username = 'emre.ozturk',
        @PasswordPlain = 'Ogrenci@123',
        @Email = 'emre.ozturk@example.edu',
        @Phone = '+900000000023',
        @StudentNumber = '20250005',
        @NationalID = '12345678905',
        @FirstName = 'Emre',
        @LastName = 'Öztürk',
        @BirthDate = '2002-08-30',
        @Gender = 'M',
        @DepartmentID = @DeptCompEng,
        @ProgramID = @ProgCompEng,
        @AdvisorID = @AyseID,
        @EnrollmentYear = 2024,
        @NewStudentID = @StudentID OUTPUT;
END

-- Student 6
IF NOT EXISTS (SELECT 1 FROM dbo.Users WHERE Username = 'busra.yildiz')
BEGIN
    EXEC dbo.sp_RegisterStudent
        @Username = 'busra.yildiz',
        @PasswordPlain = 'Ogrenci@123',
        @Email = 'busra.yildiz@example.edu',
        @Phone = '+900000000024',
        @StudentNumber = '20250006',
        @NationalID = '12345678906',
        @FirstName = 'Büşra',
        @LastName = 'Yıldız',
        @BirthDate = '2003-01-12',
        @Gender = 'F',
        @DepartmentID = @DeptCompEng,
        @ProgramID = @ProgCompEng,
        @AdvisorID = @AyseID,
        @EnrollmentYear = 2025,
        @NewStudentID = @StudentID OUTPUT;
END

-- Student 7 (Elektrik-Elektronik)
DECLARE @FatmaID INT;
SELECT @FatmaID = UserID FROM dbo.Users WHERE Username = 'fatma.kaya';

IF NOT EXISTS (SELECT 1 FROM dbo.Users WHERE Username = 'can.aksoy')
BEGIN
    EXEC dbo.sp_RegisterStudent
        @Username = 'can.aksoy',
        @PasswordPlain = 'Ogrenci@123',
        @Email = 'can.aksoy@example.edu',
        @Phone = '+900000000025',
        @StudentNumber = '20250007',
        @NationalID = '12345678907',
        @FirstName = 'Can',
        @LastName = 'Aksoy',
        @BirthDate = '2003-05-25',
        @Gender = 'M',
        @DepartmentID = @DeptElec,
        @ProgramID = @ProgElec,
        @AdvisorID = @FatmaID,
        @EnrollmentYear = 2025,
        @NewStudentID = @StudentID OUTPUT;
END

-- Student 8 (Elektrik-Elektronik)
IF NOT EXISTS (SELECT 1 FROM dbo.Users WHERE Username = 'selin.korkmaz')
BEGIN
    EXEC dbo.sp_RegisterStudent
        @Username = 'selin.korkmaz',
        @PasswordPlain = 'Ogrenci@123',
        @Email = 'selin.korkmaz@example.edu',
        @Phone = '+900000000026',
        @StudentNumber = '20250008',
        @NationalID = '12345678908',
        @FirstName = 'Selin',
        @LastName = 'Korkmaz',
        @BirthDate = '2002-12-08',
        @Gender = 'F',
        @DepartmentID = @DeptElec,
        @ProgramID = @ProgElec,
        @AdvisorID = @FatmaID,
        @EnrollmentYear = 2024,
        @NewStudentID = @StudentID OUTPUT;
END

-- Student 9 (Elektrik-Elektronik)
IF NOT EXISTS (SELECT 1 FROM dbo.Users WHERE Username = 'baris.koc')
BEGIN
    EXEC dbo.sp_RegisterStudent
        @Username = 'baris.koc',
        @PasswordPlain = 'Ogrenci@123',
        @Email = 'baris.koc@example.edu',
        @Phone = '+900000000027',
        @StudentNumber = '20250009',
        @NationalID = '12345678909',
        @FirstName = 'Barış',
        @LastName = 'Koç',
        @BirthDate = '2003-09-14',
        @Gender = 'M',
        @DepartmentID = @DeptElec,
        @ProgramID = @ProgElec,
        @AdvisorID = @FatmaID,
        @EnrollmentYear = 2025,
        @NewStudentID = @StudentID OUTPUT;
END

-- Student 10 (Elektrik-Elektronik)
IF NOT EXISTS (SELECT 1 FROM dbo.Users WHERE Username = 'deniz.acar')
BEGIN
    EXEC dbo.sp_RegisterStudent
        @Username = 'deniz.acar',
        @PasswordPlain = 'Ogrenci@123',
        @Email = 'deniz.acar@example.edu',
        @Phone = '+900000000028',
        @StudentNumber = '20250010',
        @NationalID = '12345678910',
        @FirstName = 'Deniz',
        @LastName = 'Acar',
        @BirthDate = '2002-06-20',
        @Gender = 'F',
        @DepartmentID = @DeptElec,
        @ProgramID = @ProgElec,
        @AdvisorID = @FatmaID,
        @EnrollmentYear = 2024,
        @NewStudentID = @StudentID OUTPUT;
END

-- Student 11 (Makine)
DECLARE @MustafaID INT;
SELECT @MustafaID = UserID FROM dbo.Users WHERE Username = 'mustafa.yilmaz';

IF NOT EXISTS (SELECT 1 FROM dbo.Users WHERE Username = 'omer.tas')
BEGIN
    EXEC dbo.sp_RegisterStudent
        @Username = 'omer.tas',
        @PasswordPlain = 'Ogrenci@123',
        @Email = 'omer.tas@example.edu',
        @Phone = '+900000000029',
        @StudentNumber = '20250011',
        @NationalID = '12345678911',
        @FirstName = 'Ömer',
        @LastName = 'Taş',
        @BirthDate = '2003-02-28',
        @Gender = 'M',
        @DepartmentID = @DeptMech,
        @ProgramID = @ProgMech,
        @AdvisorID = @MustafaID,
        @EnrollmentYear = 2025,
        @NewStudentID = @StudentID OUTPUT;
END

-- Student 12 (Makine)
IF NOT EXISTS (SELECT 1 FROM dbo.Users WHERE Username = 'aylin.polat')
BEGIN
    EXEC dbo.sp_RegisterStudent
        @Username = 'aylin.polat',
        @PasswordPlain = 'Ogrenci@123',
        @Email = 'aylin.polat@example.edu',
        @Phone = '+900000000030',
        @StudentNumber = '20250012',
        @NationalID = '12345678912',
        @FirstName = 'Aylin',
        @LastName = 'Polat',
        @BirthDate = '2002-10-03',
        @Gender = 'F',
        @DepartmentID = @DeptMech,
        @ProgramID = @ProgMech,
        @AdvisorID = @MustafaID,
        @EnrollmentYear = 2024,
        @NewStudentID = @StudentID OUTPUT;
END

-- Student 13 (Makine)
IF NOT EXISTS (SELECT 1 FROM dbo.Users WHERE Username = 'kerem.erdogan')
BEGIN
    EXEC dbo.sp_RegisterStudent
        @Username = 'kerem.erdogan',
        @PasswordPlain = 'Ogrenci@123',
        @Email = 'kerem.erdogan@example.edu',
        @Phone = '+900000000031',
        @StudentNumber = '20250013',
        @NationalID = '12345678913',
        @FirstName = 'Kerem',
        @LastName = 'Erdoğan',
        @BirthDate = '2003-04-07',
        @Gender = 'M',
        @DepartmentID = @DeptMech,
        @ProgramID = @ProgMech,
        @AdvisorID = @MustafaID,
        @EnrollmentYear = 2025,
        @NewStudentID = @StudentID OUTPUT;
END

-- Student 14 (Makine)
IF NOT EXISTS (SELECT 1 FROM dbo.Users WHERE Username = 'melis.kurt')
BEGIN
    EXEC dbo.sp_RegisterStudent
        @Username = 'melis.kurt',
        @PasswordPlain = 'Ogrenci@123',
        @Email = 'melis.kurt@example.edu',
        @Phone = '+900000000032',
        @StudentNumber = '20250014',
        @NationalID = '12345678914',
        @FirstName = 'Melis',
        @LastName = 'Kurt',
        @BirthDate = '2002-07-16',
        @Gender = 'F',
        @DepartmentID = @DeptMech,
        @ProgramID = @ProgMech,
        @AdvisorID = @MustafaID,
        @EnrollmentYear = 2024,
        @NewStudentID = @StudentID OUTPUT;
END

-- Student 15 (Bilgisayar)
IF NOT EXISTS (SELECT 1 FROM dbo.Users WHERE Username = 'yusuf.candan')
BEGIN
    EXEC dbo.sp_RegisterStudent
        @Username = 'yusuf.candan',
        @PasswordPlain = 'Ogrenci@123',
        @Email = 'yusuf.candan@example.edu',
        @Phone = '+900000000033',
        @StudentNumber = '20250015',
        @NationalID = '12345678915',
        @FirstName = 'Yusuf',
        @LastName = 'Candan',
        @BirthDate = '2003-11-29',
        @Gender = 'M',
        @DepartmentID = @DeptCompEng,
        @ProgramID = @ProgCompEng,
        @AdvisorID = @AyseID,
        @EnrollmentYear = 2025,
        @NewStudentID = @StudentID OUTPUT;
END
GO

/* =========================================================
   Additional Courses
   ========================================================= */
DECLARE @ProgCompEng INT, @ProgElec INT, @ProgMech INT;
DECLARE @CourseID INT;

SELECT @ProgCompEng = ProgramID FROM dbo.Programs WHERE ProgramName = 'Bilgisayar Mühendisliği Lisans';
SELECT @ProgElec = ProgramID FROM dbo.Programs WHERE ProgramName = 'Elektrik-Elektronik Mühendisliği Lisans';
SELECT @ProgMech = ProgramID FROM dbo.Programs WHERE ProgramName = 'Makine Mühendisliği Lisans';

-- CENG102: Veri Yapıları
IF NOT EXISTS (SELECT 1 FROM dbo.Courses WHERE CourseCode = 'CENG102')
BEGIN
    EXEC dbo.sp_CreateCourse
        @CourseCode = 'CENG102',
        @CourseName = 'Veri Yapıları',
        @ProgramID = @ProgCompEng,
        @Credit = 4,
        @ECTS = 6,
        @SemesterOffered = 2,
        @NewCourseID = @CourseID OUTPUT;
END

-- CENG201: Algoritma Analizi
IF NOT EXISTS (SELECT 1 FROM dbo.Courses WHERE CourseCode = 'CENG201')
BEGIN
    EXEC dbo.sp_CreateCourse
        @CourseCode = 'CENG201',
        @CourseName = 'Algoritma Analizi',
        @ProgramID = @ProgCompEng,
        @Credit = 3,
        @ECTS = 5,
        @SemesterOffered = 3,
        @NewCourseID = @CourseID OUTPUT;
END

-- CENG301: Veritabanı Yönetim Sistemleri
IF NOT EXISTS (SELECT 1 FROM dbo.Courses WHERE CourseCode = 'CENG301')
BEGIN
    EXEC dbo.sp_CreateCourse
        @CourseCode = 'CENG301',
        @CourseName = 'Veritabanı Yönetim Sistemleri',
        @ProgramID = @ProgCompEng,
        @Credit = 4,
        @ECTS = 6,
        @SemesterOffered = 5,
        @NewCourseID = @CourseID OUTPUT;
END

-- EE101: Devre Analizi
IF NOT EXISTS (SELECT 1 FROM dbo.Courses WHERE CourseCode = 'EE101')
BEGIN
    EXEC dbo.sp_CreateCourse
        @CourseCode = 'EE101',
        @CourseName = 'Devre Analizi',
        @ProgramID = @ProgElec,
        @Credit = 4,
        @ECTS = 6,
        @SemesterOffered = 1,
        @NewCourseID = @CourseID OUTPUT;
END

-- ME101: Statik
IF NOT EXISTS (SELECT 1 FROM dbo.Courses WHERE CourseCode = 'ME101')
BEGIN
    EXEC dbo.sp_CreateCourse
        @CourseCode = 'ME101',
        @CourseName = 'Statik',
        @ProgramID = @ProgMech,
        @Credit = 3,
        @ECTS = 5,
        @SemesterOffered = 1,
        @NewCourseID = @CourseID OUTPUT;
END
GO

/* =========================================================
   Course Offerings (2025-FALL term)
   ========================================================= */
DECLARE @AyseID INT, @AliID INT, @FatmaID INT, @MustafaID INT;
DECLARE @CourseID INT, @OfferingID INT;

SELECT @AyseID = UserID FROM dbo.Users WHERE Username = 'ayse.akademik';
SELECT @AliID = UserID FROM dbo.Users WHERE Username = 'ali.demir';
SELECT @FatmaID = UserID FROM dbo.Users WHERE Username = 'fatma.kaya';
SELECT @MustafaID = UserID FROM dbo.Users WHERE Username = 'mustafa.yilmaz';

-- CENG102 - Section A (Ayşe)
SELECT @CourseID = CourseID FROM dbo.Courses WHERE CourseCode = 'CENG102';
IF @CourseID IS NOT NULL AND NOT EXISTS (SELECT 1 FROM dbo.CourseOfferings WHERE CourseID = @CourseID AND Term = '2025-FALL' AND Section = 'A')
BEGIN
    EXEC dbo.sp_OpenCourseOffering
        @CourseID = @CourseID,
        @AcademicID = @AyseID,
        @Term = '2025-FALL',
        @Section = 'A',
        @Capacity = 50,
        @ScheduleJSON = N'[{ "day": "Tue", "start": "10:00", "end": "12:00", "room": "B-102" }]',
        @NewOfferingID = @OfferingID OUTPUT;
END

-- CENG201 - Section A (Ali)
SELECT @CourseID = CourseID FROM dbo.Courses WHERE CourseCode = 'CENG201';
IF @CourseID IS NOT NULL AND @AliID IS NOT NULL AND NOT EXISTS (SELECT 1 FROM dbo.CourseOfferings WHERE CourseID = @CourseID AND Term = '2025-FALL' AND Section = 'A')
BEGIN
    EXEC dbo.sp_OpenCourseOffering
        @CourseID = @CourseID,
        @AcademicID = @AliID,
        @Term = '2025-FALL',
        @Section = 'A',
        @Capacity = 40,
        @ScheduleJSON = N'[{ "day": "Wed", "start": "14:00", "end": "16:00", "room": "B-201" }]',
        @NewOfferingID = @OfferingID OUTPUT;
END

-- CENG301 - Section A (Ayşe)
SELECT @CourseID = CourseID FROM dbo.Courses WHERE CourseCode = 'CENG301';
IF @CourseID IS NOT NULL AND NOT EXISTS (SELECT 1 FROM dbo.CourseOfferings WHERE CourseID = @CourseID AND Term = '2025-FALL' AND Section = 'A')
BEGIN
    EXEC dbo.sp_OpenCourseOffering
        @CourseID = @CourseID,
        @AcademicID = @AyseID,
        @Term = '2025-FALL',
        @Section = 'A',
        @Capacity = 35,
        @ScheduleJSON = N'[{ "day": "Thu", "start": "09:00", "end": "11:00", "room": "B-103" }]',
        @NewOfferingID = @OfferingID OUTPUT;
END

-- EE101 - Section A (Fatma)
SELECT @CourseID = CourseID FROM dbo.Courses WHERE CourseCode = 'EE101';
IF @CourseID IS NOT NULL AND @FatmaID IS NOT NULL AND NOT EXISTS (SELECT 1 FROM dbo.CourseOfferings WHERE CourseID = @CourseID AND Term = '2025-FALL' AND Section = 'A')
BEGIN
    EXEC dbo.sp_OpenCourseOffering
        @CourseID = @CourseID,
        @AcademicID = @FatmaID,
        @Term = '2025-FALL',
        @Section = 'A',
        @Capacity = 45,
        @ScheduleJSON = N'[{ "day": "Mon", "start": "13:00", "end": "15:00", "room": "C-101" }]',
        @NewOfferingID = @OfferingID OUTPUT;
END

-- ME101 - Section A (Mustafa)
SELECT @CourseID = CourseID FROM dbo.Courses WHERE CourseCode = 'ME101';
IF @CourseID IS NOT NULL AND @MustafaID IS NOT NULL AND NOT EXISTS (SELECT 1 FROM dbo.CourseOfferings WHERE CourseID = @CourseID AND Term = '2025-FALL' AND Section = 'A')
BEGIN
    EXEC dbo.sp_OpenCourseOffering
        @CourseID = @CourseID,
        @AcademicID = @MustafaID,
        @Term = '2025-FALL',
        @Section = 'A',
        @Capacity = 40,
        @ScheduleJSON = N'[{ "day": "Fri", "start": "10:00", "end": "12:00", "room": "D-101" }]',
        @NewOfferingID = @OfferingID OUTPUT;
END
GO

/* =========================================================
   Student Enrollments
   ========================================================= */
DECLARE @OfferingID INT, @StudentID INT;

-- Enroll Computer Engineering students in CENG101, CENG102, CENG201, CENG301
DECLARE @CENG101_Offering INT, @CENG102_Offering INT, @CENG201_Offering INT, @CENG301_Offering INT;
DECLARE @EE101_Offering INT, @ME101_Offering INT;

SELECT @CENG101_Offering = OfferingID FROM dbo.CourseOfferings CO 
    INNER JOIN dbo.Courses C ON CO.CourseID = C.CourseID 
    WHERE C.CourseCode = 'CENG101' AND CO.Term = '2025-FALL' AND CO.Section = 'A';

SELECT @CENG102_Offering = OfferingID FROM dbo.CourseOfferings CO 
    INNER JOIN dbo.Courses C ON CO.CourseID = C.CourseID 
    WHERE C.CourseCode = 'CENG102' AND CO.Term = '2025-FALL' AND CO.Section = 'A';

SELECT @CENG201_Offering = OfferingID FROM dbo.CourseOfferings CO 
    INNER JOIN dbo.Courses C ON CO.CourseID = C.CourseID 
    WHERE C.CourseCode = 'CENG201' AND CO.Term = '2025-FALL' AND CO.Section = 'A';

SELECT @CENG301_Offering = OfferingID FROM dbo.CourseOfferings CO 
    INNER JOIN dbo.Courses C ON CO.CourseID = C.CourseID 
    WHERE C.CourseCode = 'CENG301' AND CO.Term = '2025-FALL' AND CO.Section = 'A';

SELECT @EE101_Offering = OfferingID FROM dbo.CourseOfferings CO 
    INNER JOIN dbo.Courses C ON CO.CourseID = C.CourseID 
    WHERE C.CourseCode = 'EE101' AND CO.Term = '2025-FALL' AND CO.Section = 'A';

SELECT @ME101_Offering = OfferingID FROM dbo.CourseOfferings CO 
    INNER JOIN dbo.Courses C ON CO.CourseID = C.CourseID 
    WHERE C.CourseCode = 'ME101' AND CO.Term = '2025-FALL' AND CO.Section = 'A';

-- Computer Engineering Students (mehmet, zeynep, ahmet, elif, emre, busra, yusuf) -> CENG courses
DECLARE @CompEngStudents TABLE (StudentID INT);
INSERT INTO @CompEngStudents
SELECT S.StudentID 
FROM dbo.Students S 
INNER JOIN dbo.Departments D ON S.DepartmentID = D.DepartmentID
WHERE D.DepartmentName = 'Bilgisayar Mühendisliği';

-- Enroll in CENG101
DECLARE @sid INT;
DECLARE cur_comp CURSOR FOR SELECT StudentID FROM @CompEngStudents;
OPEN cur_comp;
FETCH NEXT FROM cur_comp INTO @sid;
WHILE @@FETCH_STATUS = 0
BEGIN
    IF @CENG101_Offering IS NOT NULL AND NOT EXISTS (SELECT 1 FROM dbo.Enrollments WHERE OfferingID = @CENG101_Offering AND StudentID = @sid)
        EXEC dbo.sp_EnrollStudent @OfferingID = @CENG101_Offering, @StudentID = @sid;
    
    IF @CENG102_Offering IS NOT NULL AND NOT EXISTS (SELECT 1 FROM dbo.Enrollments WHERE OfferingID = @CENG102_Offering AND StudentID = @sid)
        EXEC dbo.sp_EnrollStudent @OfferingID = @CENG102_Offering, @StudentID = @sid;
    
    IF @CENG301_Offering IS NOT NULL AND NOT EXISTS (SELECT 1 FROM dbo.Enrollments WHERE OfferingID = @CENG301_Offering AND StudentID = @sid)
        EXEC dbo.sp_EnrollStudent @OfferingID = @CENG301_Offering, @StudentID = @sid;
    
    FETCH NEXT FROM cur_comp INTO @sid;
END
CLOSE cur_comp;
DEALLOCATE cur_comp;

-- Elektrik-Elektronik Students -> EE101
DECLARE @ElecStudents TABLE (StudentID INT);
INSERT INTO @ElecStudents
SELECT S.StudentID 
FROM dbo.Students S 
INNER JOIN dbo.Departments D ON S.DepartmentID = D.DepartmentID
WHERE D.DepartmentName = 'Elektrik-Elektronik Mühendisliği';

DECLARE cur_elec CURSOR FOR SELECT StudentID FROM @ElecStudents;
OPEN cur_elec;
FETCH NEXT FROM cur_elec INTO @sid;
WHILE @@FETCH_STATUS = 0
BEGIN
    IF @EE101_Offering IS NOT NULL AND NOT EXISTS (SELECT 1 FROM dbo.Enrollments WHERE OfferingID = @EE101_Offering AND StudentID = @sid)
        EXEC dbo.sp_EnrollStudent @OfferingID = @EE101_Offering, @StudentID = @sid;
    
    FETCH NEXT FROM cur_elec INTO @sid;
END
CLOSE cur_elec;
DEALLOCATE cur_elec;

-- Makine Students -> ME101
DECLARE @MechStudents TABLE (StudentID INT);
INSERT INTO @MechStudents
SELECT S.StudentID 
FROM dbo.Students S 
INNER JOIN dbo.Departments D ON S.DepartmentID = D.DepartmentID
WHERE D.DepartmentName = 'Makine Mühendisliği';

DECLARE cur_mech CURSOR FOR SELECT StudentID FROM @MechStudents;
OPEN cur_mech;
FETCH NEXT FROM cur_mech INTO @sid;
WHILE @@FETCH_STATUS = 0
BEGIN
    IF @ME101_Offering IS NOT NULL AND NOT EXISTS (SELECT 1 FROM dbo.Enrollments WHERE OfferingID = @ME101_Offering AND StudentID = @sid)
        EXEC dbo.sp_EnrollStudent @OfferingID = @ME101_Offering, @StudentID = @sid;
    
    FETCH NEXT FROM cur_mech INTO @sid;
END
CLOSE cur_mech;
DEALLOCATE cur_mech;
GO

/* =========================================================
   Grade Components (Vize, Final, Ödev)
   ========================================================= */
DECLARE @OfferingID INT;

-- CENG101 components
SELECT @OfferingID = OfferingID FROM dbo.CourseOfferings CO 
    INNER JOIN dbo.Courses C ON CO.CourseID = C.CourseID 
    WHERE C.CourseCode = 'CENG101' AND CO.Term = '2025-FALL';

IF @OfferingID IS NOT NULL
BEGIN
    IF NOT EXISTS (SELECT 1 FROM dbo.GradeComponents WHERE OfferingID = @OfferingID AND ComponentName = 'Vize')
        INSERT INTO dbo.GradeComponents (OfferingID, ComponentName, WeightPercent) VALUES (@OfferingID, 'Vize', 30);
    IF NOT EXISTS (SELECT 1 FROM dbo.GradeComponents WHERE OfferingID = @OfferingID AND ComponentName = 'Final')
        INSERT INTO dbo.GradeComponents (OfferingID, ComponentName, WeightPercent) VALUES (@OfferingID, 'Final', 50);
    IF NOT EXISTS (SELECT 1 FROM dbo.GradeComponents WHERE OfferingID = @OfferingID AND ComponentName = 'Ödev')
        INSERT INTO dbo.GradeComponents (OfferingID, ComponentName, WeightPercent) VALUES (@OfferingID, 'Ödev', 20);
END

-- CENG102 components
SELECT @OfferingID = OfferingID FROM dbo.CourseOfferings CO 
    INNER JOIN dbo.Courses C ON CO.CourseID = C.CourseID 
    WHERE C.CourseCode = 'CENG102' AND CO.Term = '2025-FALL';

IF @OfferingID IS NOT NULL
BEGIN
    IF NOT EXISTS (SELECT 1 FROM dbo.GradeComponents WHERE OfferingID = @OfferingID AND ComponentName = 'Vize')
        INSERT INTO dbo.GradeComponents (OfferingID, ComponentName, WeightPercent) VALUES (@OfferingID, 'Vize', 30);
    IF NOT EXISTS (SELECT 1 FROM dbo.GradeComponents WHERE OfferingID = @OfferingID AND ComponentName = 'Final')
        INSERT INTO dbo.GradeComponents (OfferingID, ComponentName, WeightPercent) VALUES (@OfferingID, 'Final', 50);
    IF NOT EXISTS (SELECT 1 FROM dbo.GradeComponents WHERE OfferingID = @OfferingID AND ComponentName = 'Proje')
        INSERT INTO dbo.GradeComponents (OfferingID, ComponentName, WeightPercent) VALUES (@OfferingID, 'Proje', 20);
END

-- CENG301 components
SELECT @OfferingID = OfferingID FROM dbo.CourseOfferings CO 
    INNER JOIN dbo.Courses C ON CO.CourseID = C.CourseID 
    WHERE C.CourseCode = 'CENG301' AND CO.Term = '2025-FALL';

IF @OfferingID IS NOT NULL
BEGIN
    IF NOT EXISTS (SELECT 1 FROM dbo.GradeComponents WHERE OfferingID = @OfferingID AND ComponentName = 'Vize')
        INSERT INTO dbo.GradeComponents (OfferingID, ComponentName, WeightPercent) VALUES (@OfferingID, 'Vize', 25);
    IF NOT EXISTS (SELECT 1 FROM dbo.GradeComponents WHERE OfferingID = @OfferingID AND ComponentName = 'Final')
        INSERT INTO dbo.GradeComponents (OfferingID, ComponentName, WeightPercent) VALUES (@OfferingID, 'Final', 45);
    IF NOT EXISTS (SELECT 1 FROM dbo.GradeComponents WHERE OfferingID = @OfferingID AND ComponentName = 'Proje')
        INSERT INTO dbo.GradeComponents (OfferingID, ComponentName, WeightPercent) VALUES (@OfferingID, 'Proje', 30);
END

-- EE101 components
SELECT @OfferingID = OfferingID FROM dbo.CourseOfferings CO 
    INNER JOIN dbo.Courses C ON CO.CourseID = C.CourseID 
    WHERE C.CourseCode = 'EE101' AND CO.Term = '2025-FALL';

IF @OfferingID IS NOT NULL
BEGIN
    IF NOT EXISTS (SELECT 1 FROM dbo.GradeComponents WHERE OfferingID = @OfferingID AND ComponentName = 'Vize')
        INSERT INTO dbo.GradeComponents (OfferingID, ComponentName, WeightPercent) VALUES (@OfferingID, 'Vize', 35);
    IF NOT EXISTS (SELECT 1 FROM dbo.GradeComponents WHERE OfferingID = @OfferingID AND ComponentName = 'Final')
        INSERT INTO dbo.GradeComponents (OfferingID, ComponentName, WeightPercent) VALUES (@OfferingID, 'Final', 50);
    IF NOT EXISTS (SELECT 1 FROM dbo.GradeComponents WHERE OfferingID = @OfferingID AND ComponentName = 'Lab')
        INSERT INTO dbo.GradeComponents (OfferingID, ComponentName, WeightPercent) VALUES (@OfferingID, 'Lab', 15);
END

-- ME101 components
SELECT @OfferingID = OfferingID FROM dbo.CourseOfferings CO 
    INNER JOIN dbo.Courses C ON CO.CourseID = C.CourseID 
    WHERE C.CourseCode = 'ME101' AND CO.Term = '2025-FALL';

IF @OfferingID IS NOT NULL
BEGIN
    IF NOT EXISTS (SELECT 1 FROM dbo.GradeComponents WHERE OfferingID = @OfferingID AND ComponentName = 'Vize')
        INSERT INTO dbo.GradeComponents (OfferingID, ComponentName, WeightPercent) VALUES (@OfferingID, 'Vize', 40);
    IF NOT EXISTS (SELECT 1 FROM dbo.GradeComponents WHERE OfferingID = @OfferingID AND ComponentName = 'Final')
        INSERT INTO dbo.GradeComponents (OfferingID, ComponentName, WeightPercent) VALUES (@OfferingID, 'Final', 60);
END
GO

/* =========================================================
   Sample Grades (for some students)
   ========================================================= */
DECLARE @ComponentID INT, @AyseID INT;

-- Get the academic who teaches CENG101 (for GradedBy)
SELECT @AyseID = UserID FROM dbo.Users WHERE Username = 'ayse.akademik';

-- Get CENG101 Vize component
SELECT @ComponentID = GC.ComponentID 
FROM dbo.GradeComponents GC
INNER JOIN dbo.CourseOfferings CO ON GC.OfferingID = CO.OfferingID
INNER JOIN dbo.Courses C ON CO.CourseID = C.CourseID
WHERE C.CourseCode = 'CENG101' AND GC.ComponentName = 'Vize';

-- Insert grades for enrolled students in CENG101
IF @ComponentID IS NOT NULL AND @AyseID IS NOT NULL
BEGIN
    DECLARE @Scores TABLE (Username NVARCHAR(50), Score DECIMAL(5,2));
    INSERT INTO @Scores VALUES 
        ('mehmet.ogrenci', 75), ('zeynep.arslan', 88), ('ahmet.celik', 62),
        ('elif.sahin', 91), ('emre.ozturk', 70), ('busra.yildiz', 85), ('yusuf.candan', 78);
    
    INSERT INTO dbo.Grades (ComponentID, EnrollmentID, Score, GradedBy)
    SELECT @ComponentID, E.EnrollmentID, S.Score, @AyseID
    FROM @Scores S
    INNER JOIN dbo.Users U ON S.Username = U.Username
    INNER JOIN dbo.Enrollments E ON E.StudentID = U.UserID
    INNER JOIN dbo.CourseOfferings CO ON E.OfferingID = CO.OfferingID
    INNER JOIN dbo.Courses C ON CO.CourseID = C.CourseID
    WHERE C.CourseCode = 'CENG101'
      AND NOT EXISTS (SELECT 1 FROM dbo.Grades G WHERE G.ComponentID = @ComponentID AND G.EnrollmentID = E.EnrollmentID);
END

-- Get CENG101 Ödev component
SELECT @ComponentID = GC.ComponentID 
FROM dbo.GradeComponents GC
INNER JOIN dbo.CourseOfferings CO ON GC.OfferingID = CO.OfferingID
INNER JOIN dbo.Courses C ON CO.CourseID = C.CourseID
WHERE C.CourseCode = 'CENG101' AND GC.ComponentName = 'Ödev';

IF @ComponentID IS NOT NULL AND @AyseID IS NOT NULL
BEGIN
    DECLARE @Scores2 TABLE (Username NVARCHAR(50), Score DECIMAL(5,2));
    INSERT INTO @Scores2 VALUES 
        ('mehmet.ogrenci', 90), ('zeynep.arslan', 95), ('ahmet.celik', 80),
        ('elif.sahin', 100), ('emre.ozturk', 85), ('busra.yildiz', 92), ('yusuf.candan', 88);
    
    INSERT INTO dbo.Grades (ComponentID, EnrollmentID, Score, GradedBy)
    SELECT @ComponentID, E.EnrollmentID, S.Score, @AyseID
    FROM @Scores2 S
    INNER JOIN dbo.Users U ON S.Username = U.Username
    INNER JOIN dbo.Enrollments E ON E.StudentID = U.UserID
    INNER JOIN dbo.CourseOfferings CO ON E.OfferingID = CO.OfferingID
    INNER JOIN dbo.Courses C ON CO.CourseID = C.CourseID
    WHERE C.CourseCode = 'CENG101'
      AND NOT EXISTS (SELECT 1 FROM dbo.Grades G WHERE G.ComponentID = @ComponentID AND G.EnrollmentID = E.EnrollmentID);
END
GO

/* =========================================================
   Summary
   ========================================================= */
DECLARE @DeptCount INT, @ProgCount INT, @AcadCount INT, @StudCount INT;
DECLARE @CourseCount INT, @OfferingCount INT, @EnrollCount INT, @CompCount INT, @GradeCount INT;

SELECT @DeptCount = COUNT(*) FROM dbo.Departments;
SELECT @ProgCount = COUNT(*) FROM dbo.Programs;
SELECT @AcadCount = COUNT(*) FROM dbo.Academics;
SELECT @StudCount = COUNT(*) FROM dbo.Students;
SELECT @CourseCount = COUNT(*) FROM dbo.Courses;
SELECT @OfferingCount = COUNT(*) FROM dbo.CourseOfferings;
SELECT @EnrollCount = COUNT(*) FROM dbo.Enrollments;
SELECT @CompCount = COUNT(*) FROM dbo.GradeComponents;
SELECT @GradeCount = COUNT(*) FROM dbo.Grades;

PRINT '=== Sample Data Summary ===';
PRINT 'Departments: ' + CAST(@DeptCount AS VARCHAR);
PRINT 'Programs: ' + CAST(@ProgCount AS VARCHAR);
PRINT 'Academics: ' + CAST(@AcadCount AS VARCHAR);
PRINT 'Students: ' + CAST(@StudCount AS VARCHAR);
PRINT 'Courses: ' + CAST(@CourseCount AS VARCHAR);
PRINT 'Course Offerings: ' + CAST(@OfferingCount AS VARCHAR);
PRINT 'Enrollments: ' + CAST(@EnrollCount AS VARCHAR);
PRINT 'Grade Components: ' + CAST(@CompCount AS VARCHAR);
PRINT 'Grades: ' + CAST(@GradeCount AS VARCHAR);
PRINT '=========================';
GO

