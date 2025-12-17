/*
    db/views/views.sql
    Purpose: Create database views for reporting and data access
    Views provide abstraction layer and simplify complex queries
*/

USE AkademikDB;
GO

SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

/* =========================================================
   View 1: vw_StudentTranscript
   Purpose: Öğrenci transkript bilgilerini tek sorguda getirir
   Usage: SELECT * FROM vw_StudentTranscript WHERE StudentID = @ID
   ========================================================= */
IF OBJECT_ID('dbo.vw_StudentTranscript', 'V') IS NOT NULL
    DROP VIEW dbo.vw_StudentTranscript;
GO

CREATE VIEW dbo.vw_StudentTranscript
AS
SELECT 
    S.StudentID,
    S.StudentNumber,
    S.FirstName,
    S.LastName,
    FullName = CONCAT(S.FirstName, ' ', S.LastName),
    D.DepartmentName,
    P.ProgramName,
    C.CourseCode,
    C.CourseName,
    C.Credit,
    C.ECTS,
    CO.Term,
    CO.Section,
    E.EnrollmentID,
    E.CurrentAverage,
    E.LetterGrade,
    E.EnrollStatus,
    E.AttendancePercent,
    E.EnrolledAt,
    -- GPA için harf notunun sayısal karşılığı
    GradePoint = CASE E.LetterGrade
        WHEN 'AA' THEN 4.0
        WHEN 'BA' THEN 3.5
        WHEN 'BB' THEN 3.0
        WHEN 'CB' THEN 2.5
        WHEN 'CC' THEN 2.0
        WHEN 'DC' THEN 1.5
        WHEN 'DD' THEN 1.0
        WHEN 'FD' THEN 0.5
        WHEN 'FF' THEN 0.0
        ELSE NULL
    END,
    -- Ders başarı durumu
    IsPass = CASE 
        WHEN E.LetterGrade IN ('AA', 'BA', 'BB', 'CB', 'CC', 'DC', 'DD') THEN 1
        ELSE 0
    END,
    -- Akademisyen bilgisi
    AcademicID = A.AcademicID,
    AcademicName = CONCAT(AU.Username, ' (', ISNULL(A.Title, 'Öğr. Gör.'), ')')
FROM dbo.Students S
INNER JOIN dbo.Enrollments E ON S.StudentID = E.StudentID
INNER JOIN dbo.CourseOfferings CO ON E.OfferingID = CO.OfferingID
INNER JOIN dbo.Courses C ON CO.CourseID = C.CourseID
INNER JOIN dbo.Programs P ON C.ProgramID = P.ProgramID
INNER JOIN dbo.Departments D ON P.DepartmentID = D.DepartmentID
LEFT JOIN dbo.Academics A ON CO.AcademicID = A.AcademicID
LEFT JOIN dbo.Users AU ON A.AcademicID = AU.UserID;
GO

/* =========================================================
   View 2: vw_CourseStatistics
   Purpose: Ders bazlı istatistikler (ortalama, geçme oranı vb.)
   Usage: SELECT * FROM vw_CourseStatistics WHERE Term = '2025-FALL'
   ========================================================= */
IF OBJECT_ID('dbo.vw_CourseStatistics', 'V') IS NOT NULL
    DROP VIEW dbo.vw_CourseStatistics;
GO

CREATE VIEW dbo.vw_CourseStatistics
AS
SELECT 
    CO.OfferingID,
    C.CourseCode,
    C.CourseName,
    C.Credit,
    CO.Term,
    CO.Section,
    CO.Capacity,
    -- Öğrenci sayıları
    TotalEnrolled = COUNT(E.EnrollmentID),
    ActiveStudents = SUM(CASE WHEN E.EnrollStatus = 'Active' THEN 1 ELSE 0 END),
    DroppedStudents = SUM(CASE WHEN E.EnrollStatus = 'Dropped' THEN 1 ELSE 0 END),
    FailedByAttendance = SUM(CASE WHEN E.EnrollStatus = 'AutoFailDueToAttendance' THEN 1 ELSE 0 END),
    -- Not istatistikleri
    ClassAverage = AVG(E.CurrentAverage),
    MinGrade = MIN(E.CurrentAverage),
    MaxGrade = MAX(E.CurrentAverage),
    -- Harf notu dağılımı
    CountAA = SUM(CASE WHEN E.LetterGrade = 'AA' THEN 1 ELSE 0 END),
    CountBA = SUM(CASE WHEN E.LetterGrade = 'BA' THEN 1 ELSE 0 END),
    CountBB = SUM(CASE WHEN E.LetterGrade = 'BB' THEN 1 ELSE 0 END),
    CountCB = SUM(CASE WHEN E.LetterGrade = 'CB' THEN 1 ELSE 0 END),
    CountCC = SUM(CASE WHEN E.LetterGrade = 'CC' THEN 1 ELSE 0 END),
    CountDC = SUM(CASE WHEN E.LetterGrade = 'DC' THEN 1 ELSE 0 END),
    CountDD = SUM(CASE WHEN E.LetterGrade = 'DD' THEN 1 ELSE 0 END),
    CountFD = SUM(CASE WHEN E.LetterGrade = 'FD' THEN 1 ELSE 0 END),
    CountFF = SUM(CASE WHEN E.LetterGrade = 'FF' THEN 1 ELSE 0 END),
    -- Geçme oranı (CC ve üstü)
    PassRate = CAST(
        CASE WHEN COUNT(E.EnrollmentID) = 0 THEN 0
        ELSE SUM(CASE WHEN E.LetterGrade IN ('AA','BA','BB','CB','CC') THEN 1 ELSE 0 END) * 100.0 / COUNT(E.EnrollmentID)
        END AS DECIMAL(5,2)
    ),
    -- Devam ortalaması
    AvgAttendance = AVG(E.AttendancePercent),
    -- Akademisyen
    AcademicID = CO.AcademicID
FROM dbo.CourseOfferings CO
INNER JOIN dbo.Courses C ON CO.CourseID = C.CourseID
LEFT JOIN dbo.Enrollments E ON CO.OfferingID = E.OfferingID
GROUP BY 
    CO.OfferingID, C.CourseCode, C.CourseName, C.Credit,
    CO.Term, CO.Section, CO.Capacity, CO.AcademicID;
GO

/* =========================================================
   View 3: vw_AttendanceSummary
   Purpose: Öğrenci devam özet bilgileri
   Usage: SELECT * FROM vw_AttendanceSummary WHERE OfferingID = @ID
   ========================================================= */
IF OBJECT_ID('dbo.vw_AttendanceSummary', 'V') IS NOT NULL
    DROP VIEW dbo.vw_AttendanceSummary;
GO

CREATE VIEW dbo.vw_AttendanceSummary
AS
SELECT 
    E.EnrollmentID,
    E.OfferingID,
    E.StudentID,
    S.StudentNumber,
    S.FirstName,
    S.LastName,
    FullName = CONCAT(S.FirstName, ' ', S.LastName),
    C.CourseCode,
    C.CourseName,
    CO.Term,
    -- Oturum sayıları
    TotalSessions = (
        SELECT COUNT(*) 
        FROM dbo.ClassSessions CS 
        WHERE CS.OfferingID = E.OfferingID
    ),
    -- Durum bazlı sayımlar
    PresentCount = (
        SELECT COUNT(*) 
        FROM dbo.Attendance A 
        INNER JOIN dbo.ClassSessions CS ON A.SessionID = CS.SessionID
        WHERE CS.OfferingID = E.OfferingID AND A.StudentID = E.StudentID AND A.Status = 'Present'
    ),
    AbsentCount = (
        SELECT COUNT(*) 
        FROM dbo.Attendance A 
        INNER JOIN dbo.ClassSessions CS ON A.SessionID = CS.SessionID
        WHERE CS.OfferingID = E.OfferingID AND A.StudentID = E.StudentID AND A.Status = 'Absent'
    ),
    LateCount = (
        SELECT COUNT(*) 
        FROM dbo.Attendance A 
        INNER JOIN dbo.ClassSessions CS ON A.SessionID = CS.SessionID
        WHERE CS.OfferingID = E.OfferingID AND A.StudentID = E.StudentID AND A.Status = 'Late'
    ),
    ExcusedCount = (
        SELECT COUNT(*) 
        FROM dbo.Attendance A 
        INNER JOIN dbo.ClassSessions CS ON A.SessionID = CS.SessionID
        WHERE CS.OfferingID = E.OfferingID AND A.StudentID = E.StudentID AND A.Status = 'Excused'
    ),
    -- Hesaplanmış devam yüzdesi
    E.AttendancePercent,
    -- Devamsızlık durumu
    AttendanceStatus = CASE 
        WHEN E.EnrollStatus = 'AutoFailDueToAttendance' THEN 'KALDI (Devamsızlık)'
        WHEN E.AttendancePercent IS NULL THEN 'Kayıt Yok'
        WHEN E.AttendancePercent >= 80 THEN 'İyi'
        WHEN E.AttendancePercent >= 60 THEN 'Uyarı'
        ELSE 'Kritik'
    END,
    -- Politika bilgisi
    PolicyWarning = AP.WarningThresholdPercent,
    PolicyAutoFail = AP.AutoFailPercent
FROM dbo.Enrollments E
INNER JOIN dbo.Students S ON E.StudentID = S.StudentID
INNER JOIN dbo.CourseOfferings CO ON E.OfferingID = CO.OfferingID
INNER JOIN dbo.Courses C ON CO.CourseID = C.CourseID
LEFT JOIN dbo.AttendancePolicies AP ON CO.OfferingID = AP.OfferingID;
GO

/* =========================================================
   View 4: vw_AcademicWorkload (Bonus)
   Purpose: Akademisyen iş yükü özeti
   ========================================================= */
IF OBJECT_ID('dbo.vw_AcademicWorkload', 'V') IS NOT NULL
    DROP VIEW dbo.vw_AcademicWorkload;
GO

CREATE VIEW dbo.vw_AcademicWorkload
AS
SELECT 
    A.AcademicID,
    U.Username,
    A.Title,
    D.DepartmentName,
    -- Ders sayıları
    TotalOfferings = COUNT(DISTINCT CO.OfferingID),
    TotalStudents = COUNT(DISTINCT E.StudentID),
    -- Aktif dönem
    CurrentTermOfferings = SUM(CASE WHEN CO.Term LIKE CONCAT(YEAR(GETDATE()), '%') THEN 1 ELSE 0 END),
    -- Not bekleyen öğrenci sayısı
    PendingGrades = SUM(CASE WHEN E.LetterGrade IS NULL AND E.EnrollStatus = 'Active' THEN 1 ELSE 0 END)
FROM dbo.Academics A
INNER JOIN dbo.Users U ON A.AcademicID = U.UserID
INNER JOIN dbo.Departments D ON A.DepartmentID = D.DepartmentID
LEFT JOIN dbo.CourseOfferings CO ON A.AcademicID = CO.AcademicID
LEFT JOIN dbo.Enrollments E ON CO.OfferingID = E.OfferingID
GROUP BY A.AcademicID, U.Username, A.Title, D.DepartmentName;
GO

PRINT '=== Views Created Successfully ===';
PRINT 'vw_StudentTranscript - Öğrenci transkript görünümü';
PRINT 'vw_CourseStatistics - Ders istatistikleri görünümü';
PRINT 'vw_AttendanceSummary - Devam özet görünümü';
PRINT 'vw_AcademicWorkload - Akademisyen iş yükü görünümü';
GO

