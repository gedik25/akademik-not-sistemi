/*
    db/stored_procedures/bulk_operations.sql
    Purpose: Bulk operations using CURSOR for demonstration
    VTYS dersi için CURSOR kullanım örneği
*/

USE AkademikDB;
GO

SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

/* =========================================================
   SP 1: sp_SendBulkNotification
   Purpose: Tüm aktif öğrencilere toplu bildirim gönderir
   CURSOR kullanarak her öğrenciye ayrı bildirim ekler
   ========================================================= */
IF OBJECT_ID('dbo.sp_SendBulkNotification', 'P') IS NOT NULL
    DROP PROCEDURE dbo.sp_SendBulkNotification;
GO

CREATE PROCEDURE dbo.sp_SendBulkNotification
    @Title NVARCHAR(150),
    @Message NVARCHAR(1000),
    @NotificationType NVARCHAR(30) = 'General',
    @TargetRole NVARCHAR(50) = 'Student', -- 'Student', 'Academic', 'All'
    @SentCount INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @StudentID INT;
    DECLARE @Counter INT = 0;
    
    -- CURSOR tanımla: Hedef role göre kullanıcıları seç
    DECLARE notification_cursor CURSOR FOR
        SELECT U.UserID
        FROM dbo.Users U
        INNER JOIN dbo.Roles R ON U.RoleID = R.RoleID
        WHERE U.IsActive = 1
          AND (@TargetRole = 'All' OR R.RoleName = @TargetRole);
    
    -- CURSOR'ı aç
    OPEN notification_cursor;
    
    -- İlk kaydı al
    FETCH NEXT FROM notification_cursor INTO @StudentID;
    
    -- CURSOR döngüsü
    WHILE @@FETCH_STATUS = 0
    BEGIN
        -- Her kullanıcı için bildirim ekle
        INSERT INTO dbo.Notifications (UserID, Type, Title, Message, IsRead, CreatedAt)
        VALUES (@StudentID, @NotificationType, @Title, @Message, 0, SYSUTCDATETIME());
        
        SET @Counter = @Counter + 1;
        
        -- Sonraki kaydı al
        FETCH NEXT FROM notification_cursor INTO @StudentID;
    END
    
    -- CURSOR'ı kapat ve serbest bırak
    CLOSE notification_cursor;
    DEALLOCATE notification_cursor;
    
    SET @SentCount = @Counter;
    
    -- Audit log
    INSERT INTO dbo.AuditLog (TableName, RecordID, ActionType, ChangedBy, ChangeDetails)
    VALUES ('Notifications', 'BULK', 'BulkInsert', 1, 
            CONCAT('Sent ', @Counter, ' notifications with title: ', @Title));
    
    PRINT CONCAT('Toplam ', @Counter, ' kullanıcıya bildirim gönderildi.');
END;
GO

/* =========================================================
   SP 2: sp_RecalculateAllGPAs
   Purpose: Tüm öğrencilerin GPA'sını yeniden hesaplar
   CURSOR kullanarak her öğrenci için fn_CalculateStudentGPA çağırır
   ========================================================= */
IF OBJECT_ID('dbo.sp_RecalculateAllGPAs', 'P') IS NOT NULL
    DROP PROCEDURE dbo.sp_RecalculateAllGPAs;
GO

CREATE PROCEDURE dbo.sp_RecalculateAllGPAs
    @UpdatedCount INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @StudentID INT;
    DECLARE @StudentNumber NVARCHAR(20);
    DECLARE @FullName NVARCHAR(100);
    DECLARE @NewGPA DECIMAL(4,2);
    DECLARE @Counter INT = 0;
    
    -- Sonuçları tutmak için temp tablo
    CREATE TABLE #GPAResults (
        StudentID INT,
        StudentNumber NVARCHAR(20),
        FullName NVARCHAR(100),
        GPA DECIMAL(4,2)
    );
    
    -- CURSOR tanımla: Tüm aktif öğrenciler
    DECLARE gpa_cursor CURSOR FOR
        SELECT 
            S.StudentID,
            S.StudentNumber,
            CONCAT(S.FirstName, ' ', S.LastName) AS FullName
        FROM dbo.Students S
        INNER JOIN dbo.Users U ON S.StudentID = U.UserID
        WHERE U.IsActive = 1;
    
    OPEN gpa_cursor;
    FETCH NEXT FROM gpa_cursor INTO @StudentID, @StudentNumber, @FullName;
    
    WHILE @@FETCH_STATUS = 0
    BEGIN
        -- Her öğrenci için GPA hesapla
        SET @NewGPA = dbo.fn_CalculateStudentGPA(@StudentID);
        
        -- Sonucu kaydet
        INSERT INTO #GPAResults (StudentID, StudentNumber, FullName, GPA)
        VALUES (@StudentID, @StudentNumber, @FullName, @NewGPA);
        
        SET @Counter = @Counter + 1;
        
        FETCH NEXT FROM gpa_cursor INTO @StudentID, @StudentNumber, @FullName;
    END
    
    CLOSE gpa_cursor;
    DEALLOCATE gpa_cursor;
    
    SET @UpdatedCount = @Counter;
    
    -- Sonuçları döndür
    SELECT * FROM #GPAResults ORDER BY GPA DESC;
    
    DROP TABLE #GPAResults;
    
    PRINT CONCAT('Toplam ', @Counter, ' öğrenci için GPA hesaplandı.');
END;
GO

/* =========================================================
   SP 3: sp_GenerateAttendanceReport
   Purpose: Tüm aktif dersler için devam raporu oluşturur
   CURSOR kullanarak her ders için özet çıkarır
   ========================================================= */
IF OBJECT_ID('dbo.sp_GenerateAttendanceReport', 'P') IS NOT NULL
    DROP PROCEDURE dbo.sp_GenerateAttendanceReport;
GO

CREATE PROCEDURE dbo.sp_GenerateAttendanceReport
    @Term NVARCHAR(20) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @OfferingID INT;
    DECLARE @CourseCode NVARCHAR(20);
    DECLARE @CourseName NVARCHAR(150);
    DECLARE @TotalStudents INT;
    DECLARE @AvgAttendance DECIMAL(5,2);
    DECLARE @AtRiskCount INT;
    
    -- Sonuçları tutmak için temp tablo
    CREATE TABLE #AttendanceReport (
        OfferingID INT,
        CourseCode NVARCHAR(20),
        CourseName NVARCHAR(150),
        Term NVARCHAR(20),
        TotalStudents INT,
        AvgAttendance DECIMAL(5,2),
        AtRiskCount INT,
        HealthStatus NVARCHAR(20)
    );
    
    -- CURSOR tanımla: Aktif dönem dersleri
    DECLARE report_cursor CURSOR FOR
        SELECT 
            CO.OfferingID,
            C.CourseCode,
            C.CourseName
        FROM dbo.CourseOfferings CO
        INNER JOIN dbo.Courses C ON CO.CourseID = C.CourseID
        WHERE @Term IS NULL OR CO.Term = @Term;
    
    OPEN report_cursor;
    FETCH NEXT FROM report_cursor INTO @OfferingID, @CourseCode, @CourseName;
    
    WHILE @@FETCH_STATUS = 0
    BEGIN
        -- Her ders için istatistikleri hesapla
        SELECT 
            @TotalStudents = COUNT(*),
            @AvgAttendance = AVG(AttendancePercent),
            @AtRiskCount = SUM(CASE WHEN AttendancePercent < 70 THEN 1 ELSE 0 END)
        FROM dbo.Enrollments
        WHERE OfferingID = @OfferingID AND EnrollStatus = 'Active';
        
        -- Sonucu kaydet
        INSERT INTO #AttendanceReport 
        VALUES (
            @OfferingID,
            @CourseCode,
            @CourseName,
            @Term,
            @TotalStudents,
            @AvgAttendance,
            @AtRiskCount,
            CASE 
                WHEN @AvgAttendance >= 80 THEN 'İyi'
                WHEN @AvgAttendance >= 60 THEN 'Orta'
                ELSE 'Kritik'
            END
        );
        
        FETCH NEXT FROM report_cursor INTO @OfferingID, @CourseCode, @CourseName;
    END
    
    CLOSE report_cursor;
    DEALLOCATE report_cursor;
    
    -- Raporu döndür
    SELECT * FROM #AttendanceReport ORDER BY AvgAttendance;
    
    DROP TABLE #AttendanceReport;
END;
GO

/* =========================================================
   SP 4: sp_AutoEnrollStudentsToCourses
   Purpose: Belirli bir programa kayıtlı öğrencileri dönem derslerine otomatik kaydeder
   CURSOR kullanarak her öğrenci-ders kombinasyonu için işlem yapar
   ========================================================= */
IF OBJECT_ID('dbo.sp_AutoEnrollStudentsToCourses', 'P') IS NOT NULL
    DROP PROCEDURE dbo.sp_AutoEnrollStudentsToCourses;
GO

CREATE PROCEDURE dbo.sp_AutoEnrollStudentsToCourses
    @ProgramID INT,
    @Term NVARCHAR(20),
    @EnrolledCount INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @StudentID INT;
    DECLARE @OfferingID INT;
    DECLARE @Counter INT = 0;
    
    -- Öğrenci CURSOR'ı
    DECLARE student_cursor CURSOR FOR
        SELECT S.StudentID
        FROM dbo.Students S
        INNER JOIN dbo.Users U ON S.StudentID = U.UserID
        WHERE S.ProgramID = @ProgramID AND U.IsActive = 1;
    
    OPEN student_cursor;
    FETCH NEXT FROM student_cursor INTO @StudentID;
    
    WHILE @@FETCH_STATUS = 0
    BEGIN
        -- İç içe CURSOR: Her öğrenci için dönem derslerini bul
        DECLARE course_cursor CURSOR FOR
            SELECT CO.OfferingID
            FROM dbo.CourseOfferings CO
            INNER JOIN dbo.Courses C ON CO.CourseID = C.CourseID
            WHERE C.ProgramID = @ProgramID AND CO.Term = @Term;
        
        OPEN course_cursor;
        FETCH NEXT FROM course_cursor INTO @OfferingID;
        
        WHILE @@FETCH_STATUS = 0
        BEGIN
            -- Zaten kayıtlı değilse ekle
            IF NOT EXISTS (SELECT 1 FROM dbo.Enrollments WHERE StudentID = @StudentID AND OfferingID = @OfferingID)
            BEGIN
                INSERT INTO dbo.Enrollments (OfferingID, StudentID, EnrollStatus, EnrolledAt)
                VALUES (@OfferingID, @StudentID, 'Active', SYSUTCDATETIME());
                
                SET @Counter = @Counter + 1;
            END
            
            FETCH NEXT FROM course_cursor INTO @OfferingID;
        END
        
        CLOSE course_cursor;
        DEALLOCATE course_cursor;
        
        FETCH NEXT FROM student_cursor INTO @StudentID;
    END
    
    CLOSE student_cursor;
    DEALLOCATE student_cursor;
    
    SET @EnrolledCount = @Counter;
    
    PRINT CONCAT('Toplam ', @Counter, ' kayıt oluşturuldu.');
END;
GO

PRINT '=== Bulk Operations (with CURSOR) Created Successfully ===';
PRINT 'sp_SendBulkNotification - Toplu bildirim gönderme';
PRINT 'sp_RecalculateAllGPAs - Tüm GPA''ları yeniden hesapla';
PRINT 'sp_GenerateAttendanceReport - Devam raporu oluştur';
PRINT 'sp_AutoEnrollStudentsToCourses - Otomatik ders kaydı';
GO

