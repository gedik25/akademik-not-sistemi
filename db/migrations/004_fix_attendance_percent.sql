/*
    db/migrations/004_fix_attendance_percent.sql
    Purpose: Fix incorrect AttendancePercent values (100x too large)
*/

USE AkademikDB;
GO

PRINT '=== Fixing AttendancePercent Values ===';
GO

-- Mevcut hatalı değerleri göster
PRINT 'Before fix:';
SELECT EnrollmentID, StudentID, AttendancePercent 
FROM dbo.Enrollments 
WHERE AttendancePercent > 100;
GO

-- Düzelt: 100'e böl
UPDATE dbo.Enrollments
SET AttendancePercent = AttendancePercent / 100.0
WHERE AttendancePercent > 100;
GO

-- Sonucu göster
PRINT 'After fix:';
SELECT EnrollmentID, StudentID, AttendancePercent 
FROM dbo.Enrollments 
WHERE AttendancePercent IS NOT NULL;
GO

-- View'dan kontrol
PRINT 'View check:';
SELECT TOP 10 
    StudentNumber, 
    FullName, 
    CourseCode, 
    PresentCount, 
    AbsentCount, 
    LateCount, 
    TotalSessions,
    AttendancePercent,
    AttendanceStatus
FROM dbo.vw_AttendanceSummary
ORDER BY StudentNumber;
GO

PRINT '=== Fix Completed ===';
GO

