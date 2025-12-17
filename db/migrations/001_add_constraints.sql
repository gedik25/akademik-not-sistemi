/*
    db/migrations/001_add_constraints.sql
    CHECK constraints ve AttendancePercent alanı ekleme
    Execute after initial schema is deployed.
*/

SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

/* =========================================================
   1. CHECK Constraint: Attendance.Status
   Geçerli değerler: Present, Absent, Late, Excused
   ========================================================= */
IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = 'CK_Attendance_Status')
BEGIN
    ALTER TABLE dbo.Attendance
    ADD CONSTRAINT CK_Attendance_Status
    CHECK (Status IN ('Present', 'Absent', 'Late', 'Excused'));
    PRINT 'CK_Attendance_Status constraint eklendi.';
END
GO

/* =========================================================
   2. CHECK Constraint: Grades.Score
   Geçerli değerler: 0-100 arası
   ========================================================= */
IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = 'CK_Grades_Score')
BEGIN
    ALTER TABLE dbo.Grades
    ADD CONSTRAINT CK_Grades_Score
    CHECK (Score >= 0 AND Score <= 100);
    PRINT 'CK_Grades_Score constraint eklendi.';
END
GO

/* =========================================================
   3. Yeni Alan: Enrollments.AttendancePercent
   Devam yüzdesini trigger ile otomatik hesaplanacak
   ========================================================= */
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('dbo.Enrollments') AND name = 'AttendancePercent')
BEGIN
    ALTER TABLE dbo.Enrollments
    ADD AttendancePercent DECIMAL(5,2) NULL;
    PRINT 'AttendancePercent kolonu eklendi.';
END
GO

PRINT '001_add_constraints migration tamamlandı.';
GO

