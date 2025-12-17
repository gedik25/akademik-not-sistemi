/*
    db/migrations/002_generate_sessions.sql
    Mevcut dersler için 14 haftalık ClassSessions oluşturma.
    Execute after 001_add_constraints.sql and academic.sql procedures.
*/

SET NOCOUNT ON;
GO

PRINT '=== Generating Class Sessions ==='
GO

/* =========================================================
   Her ders için 14 haftalık oturumlar oluştur
   Dönem başlangıcı: 2025-09-15 (Pazartesi)
   ========================================================= */

-- Tüm mevcut offering'ler için oturumları oluştur
DECLARE @OfferingID INT;
DECLARE @DayOffset INT = 0;

DECLARE offering_cursor CURSOR FOR 
SELECT OfferingID FROM dbo.CourseOfferings;

OPEN offering_cursor;
FETCH NEXT FROM offering_cursor INTO @OfferingID;

WHILE @@FETCH_STATUS = 0
BEGIN
    -- Her ders için farklı gün ve saat (çakışma olmasın)
    DECLARE @StartDate DATE = '2025-09-15';
    DECLARE @DayOfWeek INT = ((@DayOffset % 5) + 1); -- Pazartesi-Cuma arası dağıt
    DECLARE @StartHour INT = 9 + ((@DayOffset / 5) * 2); -- 09:00, 11:00, 13:00 gibi
    DECLARE @StartTime TIME(0) = CAST(CONCAT(RIGHT('0' + CAST(@StartHour AS VARCHAR(2)), 2), ':00') AS TIME(0));
    DECLARE @EndTime TIME(0) = CAST(CONCAT(RIGHT('0' + CAST(@StartHour + 2 AS VARCHAR(2)), 2), ':00') AS TIME(0));
    
    PRINT CONCAT('OfferingID: ', @OfferingID, ', Day: ', @DayOfWeek, ', Time: ', CAST(@StartTime AS VARCHAR(10)));
    
    EXEC dbo.sp_GenerateClassSessions 
        @OfferingID = @OfferingID,
        @StartDate = @StartDate,
        @DayOfWeek = @DayOfWeek,
        @StartTime = @StartTime,
        @EndTime = @EndTime,
        @SessionType = 'Lecture',
        @Location = 'B-101',
        @WeekCount = 14;
    
    SET @DayOffset = @DayOffset + 1;
    FETCH NEXT FROM offering_cursor INTO @OfferingID;
END

CLOSE offering_cursor;
DEALLOCATE offering_cursor;

GO

/* =========================================================
   Özet bilgi
   ========================================================= */
PRINT '=== Session Generation Summary ==='
SELECT 
    CO.OfferingID,
    C.CourseCode,
    SessionCount = COUNT(CS.SessionID)
FROM dbo.CourseOfferings CO
INNER JOIN dbo.Courses C ON CO.CourseID = C.CourseID
LEFT JOIN dbo.ClassSessions CS ON CS.OfferingID = CO.OfferingID
GROUP BY CO.OfferingID, C.CourseCode
ORDER BY CO.OfferingID;

PRINT '002_generate_sessions migration tamamlandı.';
GO

