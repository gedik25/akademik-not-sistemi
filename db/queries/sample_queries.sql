/*
    =============================================
    AKADEMİK NOT VE DEVAM TAKİP SİSTEMİ
    10 ÖRNEK SQL SORGUSU
    =============================================
    
    VTYS Projesi için hazırlanmış 10 adet SQL sorgusu:
    - 5 Basit Sorgu (SELECT, WHERE, ORDER BY)
    - 5 İleri Seviye Sorgu (JOIN, GROUP BY, HAVING, Aggregate)
    
    Her sorgu için:
    - Amaç açıklaması
    - SQL kodu
    - Beklenen sonuç açıklaması
    
    =============================================
*/

USE AkademikDB;
GO

-- =============================================
-- BASİT SORGULAR (1-5)
-- =============================================

/*
    SORGU 1: Tüm Aktif Öğrencileri Listeleme
    -----------------------------------------
    AMAÇ: Sistemde kayıtlı ve aktif durumda olan 
          tüm öğrencilerin listesini getirmek.
    
    KULLANILAN: SELECT, JOIN, WHERE, ORDER BY
*/
PRINT '=== SORGU 1: Aktif Öğrenciler ===';

SELECT 
    S.StudentNumber AS [Öğrenci No],
    S.FirstName AS [Ad],
    S.LastName AS [Soyad],
    U.Email AS [E-posta],
    D.DepartmentName AS [Bölüm]
FROM dbo.Students S
INNER JOIN dbo.Users U ON S.StudentID = U.UserID
INNER JOIN dbo.Departments D ON S.DepartmentID = D.DepartmentID
WHERE U.IsActive = 1
ORDER BY S.LastName, S.FirstName;
GO

/*
    SORGU 2: Belirli Dönemdeki Dersleri Listeleme
    ---------------------------------------------
    AMAÇ: 2025 Güz döneminde açılan dersleri ve 
          kontenjanlarını listelemek.
    
    KULLANILAN: SELECT, JOIN, WHERE, ORDER BY
*/
PRINT '=== SORGU 2: 2025 Güz Dönemi Dersleri ===';

SELECT 
    C.CourseCode AS [Ders Kodu],
    C.CourseName AS [Ders Adı],
    CO.Section AS [Şube],
    CO.Capacity AS [Kontenjan],
    C.Credit AS [Kredi]
FROM dbo.CourseOfferings CO
INNER JOIN dbo.Courses C ON CO.CourseID = C.CourseID
WHERE CO.Term = '2025-FALL'
ORDER BY C.CourseCode;
GO

/*
    SORGU 3: Öğrenci Arama (Filtreleme)
    -----------------------------------
    AMAÇ: Belirli bir bölümdeki öğrencileri bulmak.
    
    KULLANILAN: SELECT, JOIN, WHERE, LIKE
*/
PRINT '=== SORGU 3: Bilgisayar Mühendisliği Öğrencileri ===';

SELECT 
    S.StudentNumber AS [Öğrenci No],
    CONCAT(S.FirstName, ' ', S.LastName) AS [Ad Soyad],
    P.ProgramName AS [Program]
FROM dbo.Students S
INNER JOIN dbo.Departments D ON S.DepartmentID = D.DepartmentID
LEFT JOIN dbo.Programs P ON S.ProgramID = P.ProgramID
WHERE D.DepartmentName LIKE '%Bilgisayar%'
ORDER BY S.StudentNumber;
GO

/*
    SORGU 4: Son 7 Günde Girilen Notlar
    -----------------------------------
    AMAÇ: Son bir hafta içinde sisteme girilen 
          notları listelemek.
    
    KULLANILAN: SELECT, JOIN, WHERE, DATEADD, ORDER BY
*/
PRINT '=== SORGU 4: Son 7 Günde Girilen Notlar ===';

SELECT 
    G.GradeID AS [Not ID],
    S.StudentNumber AS [Öğrenci No],
    C.CourseCode AS [Ders Kodu],
    GC.ComponentName AS [Bileşen],
    G.Score AS [Not],
    G.ScoreDate AS [Tarih]
FROM dbo.Grades G
INNER JOIN dbo.GradeComponents GC ON G.ComponentID = GC.ComponentID
INNER JOIN dbo.Enrollments E ON G.EnrollmentID = E.EnrollmentID
INNER JOIN dbo.Students S ON E.StudentID = S.StudentID
INNER JOIN dbo.CourseOfferings CO ON E.OfferingID = CO.OfferingID
INNER JOIN dbo.Courses C ON CO.CourseID = C.CourseID
WHERE G.ScoreDate >= DATEADD(DAY, -7, GETDATE())
ORDER BY G.ScoreDate DESC;
GO

/*
    SORGU 5: Okunmamış Bildirimler
    ------------------------------
    AMAÇ: Her kullanıcının okunmamış bildirim 
          sayısını göstermek.
    
    KULLANILAN: SELECT, JOIN, WHERE, GROUP BY
*/
PRINT '=== SORGU 5: Okunmamış Bildirimler ===';

SELECT 
    U.Username AS [Kullanıcı],
    COUNT(*) AS [Okunmamış Bildirim]
FROM dbo.Notifications N
INNER JOIN dbo.Users U ON N.UserID = U.UserID
WHERE N.IsRead = 0
GROUP BY U.Username
ORDER BY COUNT(*) DESC;
GO


-- =============================================
-- İLERİ SEVİYE SORGULAR (6-10)
-- 3+ Tablo JOIN, GROUP BY, HAVING, Aggregate
-- =============================================

/*
    SORGU 6: Öğrenci Transkripti (3+ Tablo JOIN)
    --------------------------------------------
    AMAÇ: Belirli bir öğrencinin tüm dersleri, 
          notları ve devam durumunu getirmek.
    
    KULLANILAN: 5 Tablo JOIN, CONCAT, ORDER BY
    
    İLERİ SEVİYE KRİTERLERİ:
    ✓ 5 tablo birleştirme (JOIN)
*/
PRINT '=== SORGU 6: Öğrenci Transkripti (5 Tablo JOIN) ===';

SELECT 
    S.StudentNumber AS [Öğrenci No],
    CONCAT(S.FirstName, ' ', S.LastName) AS [Ad Soyad],
    D.DepartmentName AS [Bölüm],
    C.CourseCode AS [Ders Kodu],
    C.CourseName AS [Ders Adı],
    C.Credit AS [Kredi],
    CO.Term AS [Dönem],
    E.CurrentAverage AS [Ortalama],
    E.LetterGrade AS [Harf Notu],
    E.AttendancePercent AS [Devam %],
    E.EnrollStatus AS [Durum]
FROM dbo.Students S
INNER JOIN dbo.Departments D ON S.DepartmentID = D.DepartmentID
INNER JOIN dbo.Enrollments E ON S.StudentID = E.StudentID
INNER JOIN dbo.CourseOfferings CO ON E.OfferingID = CO.OfferingID
INNER JOIN dbo.Courses C ON CO.CourseID = C.CourseID
WHERE S.StudentID = 3
ORDER BY CO.Term DESC, C.CourseCode;
GO

/*
    SORGU 7: Ders Bazlı İstatistikler (GROUP BY + Aggregate)
    --------------------------------------------------------
    AMAÇ: Her dersin öğrenci sayısı, ortalama notu, 
          min/max not ve geçme oranını hesaplamak.
    
    KULLANILAN: 3 Tablo JOIN, COUNT, AVG, MIN, MAX, SUM, CASE
    
    İLERİ SEVİYE KRİTERLERİ:
    ✓ 3 tablo birleştirme (JOIN)
    ✓ Aggregate fonksiyonları (COUNT, AVG, MIN, MAX, SUM)
    ✓ GROUP BY
*/
PRINT '=== SORGU 7: Ders İstatistikleri (GROUP BY + Aggregate) ===';

SELECT 
    C.CourseCode AS [Ders Kodu],
    C.CourseName AS [Ders Adı],
    COUNT(E.EnrollmentID) AS [Öğrenci Sayısı],
    CAST(AVG(E.CurrentAverage) AS DECIMAL(5,2)) AS [Sınıf Ortalaması],
    MIN(E.CurrentAverage) AS [En Düşük],
    MAX(E.CurrentAverage) AS [En Yüksek],
    CAST(
        SUM(CASE WHEN E.LetterGrade IN ('AA','BA','BB','CB','CC') THEN 1 ELSE 0 END) * 100.0 
        / NULLIF(COUNT(E.EnrollmentID), 0) 
    AS DECIMAL(5,2)) AS [Geçme Oranı %]
FROM dbo.Courses C
INNER JOIN dbo.CourseOfferings CO ON C.CourseID = CO.CourseID
INNER JOIN dbo.Enrollments E ON CO.OfferingID = E.OfferingID
WHERE E.CurrentAverage IS NOT NULL
GROUP BY C.CourseCode, C.CourseName
ORDER BY [Sınıf Ortalaması] DESC;
GO

/*
    SORGU 8: Devamsızlık Riski Olan Öğrenciler (HAVING)
    ---------------------------------------------------
    AMAÇ: Devamsızlık oranı %30'un üzerinde olan 
          öğrencileri tespit etmek.
    
    KULLANILAN: 6 Tablo JOIN, COUNT, CASE, HAVING
    
    İLERİ SEVİYE KRİTERLERİ:
    ✓ 6 tablo birleştirme (JOIN)
    ✓ Aggregate fonksiyonları (COUNT)
    ✓ GROUP BY ve HAVING
*/
PRINT '=== SORGU 8: Devamsızlık Riski Olan Öğrenciler (HAVING) ===';

SELECT 
    S.StudentNumber AS [Öğrenci No],
    CONCAT(S.FirstName, ' ', S.LastName) AS [Ad Soyad],
    C.CourseCode AS [Ders Kodu],
    COUNT(CASE WHEN A.Status = 'Absent' THEN 1 END) AS [Gelmedi],
    COUNT(CASE WHEN A.Status = 'Present' THEN 1 END) AS [Geldi],
    COUNT(A.AttendanceID) AS [Toplam Kayıt],
    CAST(
        COUNT(CASE WHEN A.Status = 'Absent' THEN 1 END) * 100.0 / 
        NULLIF(COUNT(A.AttendanceID), 0) 
    AS DECIMAL(5,2)) AS [Devamsızlık %]
FROM dbo.Students S
INNER JOIN dbo.Enrollments E ON S.StudentID = E.StudentID
INNER JOIN dbo.CourseOfferings CO ON E.OfferingID = CO.OfferingID
INNER JOIN dbo.Courses C ON CO.CourseID = C.CourseID
INNER JOIN dbo.ClassSessions CS ON CO.OfferingID = CS.OfferingID
LEFT JOIN dbo.Attendance A ON CS.SessionID = A.SessionID AND S.StudentID = A.StudentID
GROUP BY S.StudentNumber, S.FirstName, S.LastName, C.CourseCode
HAVING COUNT(CASE WHEN A.Status = 'Absent' THEN 1 END) * 100.0 / 
       NULLIF(COUNT(A.AttendanceID), 0) > 30
ORDER BY [Devamsızlık %] DESC;
GO

/*
    SORGU 9: Akademisyen İş Yükü (4+ Tablo JOIN + GROUP BY)
    -------------------------------------------------------
    AMAÇ: Her akademisyenin verdiği ders sayısı, 
          toplam öğrenci sayısı ve bekleyen notları görmek.
    
    KULLANILAN: 4 Tablo JOIN, COUNT DISTINCT, SUM, CASE
    
    İLERİ SEVİYE KRİTERLERİ:
    ✓ 4 tablo birleştirme (JOIN)
    ✓ Aggregate fonksiyonları (COUNT, SUM)
    ✓ GROUP BY
*/
PRINT '=== SORGU 9: Akademisyen İş Yükü (4 Tablo JOIN) ===';

SELECT 
    A.Title AS [Unvan],
    U.Username AS [Kullanıcı Adı],
    D.DepartmentName AS [Bölüm],
    COUNT(DISTINCT CO.OfferingID) AS [Ders Sayısı],
    COUNT(DISTINCT E.StudentID) AS [Toplam Öğrenci],
    SUM(CASE WHEN E.LetterGrade IS NULL AND E.EnrollStatus = 'Active' THEN 1 ELSE 0 END) AS [Bekleyen Not]
FROM dbo.Academics A
INNER JOIN dbo.Users U ON A.AcademicID = U.UserID
INNER JOIN dbo.Departments D ON A.DepartmentID = D.DepartmentID
LEFT JOIN dbo.CourseOfferings CO ON A.AcademicID = CO.AcademicID
LEFT JOIN dbo.Enrollments E ON CO.OfferingID = E.OfferingID
GROUP BY A.Title, U.Username, D.DepartmentName
ORDER BY [Toplam Öğrenci] DESC;
GO

/*
    SORGU 10: GPA Sıralaması ve Bölüm Karşılaştırması
    -------------------------------------------------
    AMAÇ: Tüm öğrencileri GPA'larına göre sıralamak 
          ve bölüm bazlı karşılaştırma yapmak.
    
    KULLANILAN: 5 Tablo JOIN, AVG, CASE, SUM, HAVING
    
    İLERİ SEVİYE KRİTERLERİ:
    ✓ 5 tablo birleştirme (JOIN)
    ✓ Aggregate fonksiyonları (AVG, SUM, COUNT)
    ✓ GROUP BY ve HAVING
    ✓ CASE ifadesi ile harf notu -> sayısal dönüşüm
*/
PRINT '=== SORGU 10: GPA Sıralaması (5 Tablo JOIN + HAVING) ===';

SELECT 
    S.StudentNumber AS [Öğrenci No],
    CONCAT(S.FirstName, ' ', S.LastName) AS [Ad Soyad],
    D.DepartmentName AS [Bölüm],
    CAST(
        AVG(
            CASE E.LetterGrade
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
            END
        ) AS DECIMAL(4,2)
    ) AS [GPA],
    COUNT(E.EnrollmentID) AS [Tamamlanan Ders],
    SUM(C.Credit) AS [Toplam Kredi]
FROM dbo.Students S
INNER JOIN dbo.Departments D ON S.DepartmentID = D.DepartmentID
INNER JOIN dbo.Enrollments E ON S.StudentID = E.StudentID
INNER JOIN dbo.CourseOfferings CO ON E.OfferingID = CO.OfferingID
INNER JOIN dbo.Courses C ON CO.CourseID = C.CourseID
WHERE E.LetterGrade IS NOT NULL
GROUP BY S.StudentNumber, S.FirstName, S.LastName, D.DepartmentName
HAVING COUNT(E.EnrollmentID) >= 1
ORDER BY [GPA] DESC, [Toplam Kredi] DESC;
GO


-- =============================================
-- ÖZET TABLO
-- =============================================
PRINT '';
PRINT '==============================================';
PRINT '             SORGU ÖZETİ                      ';
PRINT '==============================================';
PRINT '';
PRINT 'BASİT SORGULAR:';
PRINT '  1. Aktif öğrenciler listesi';
PRINT '  2. Dönem dersleri';
PRINT '  3. Bölüm bazlı öğrenci arama';
PRINT '  4. Son 7 günde girilen notlar';
PRINT '  5. Okunmamış bildirimler';
PRINT '';
PRINT 'İLERİ SEVİYE SORGULAR:';
PRINT '  6. Öğrenci transkripti (5 tablo JOIN)';
PRINT '  7. Ders istatistikleri (GROUP BY + 5 Aggregate)';
PRINT '  8. Devamsızlık riski (6 tablo JOIN + HAVING)';
PRINT '  9. Akademisyen iş yükü (4 tablo JOIN)';
PRINT ' 10. GPA sıralaması (5 tablo JOIN + HAVING)';
PRINT '';
PRINT '==============================================';
GO

