# T.C. MARMARA ÜNİVERSİTESİ TEKNOLOJİ FAKÜLTESİ
## 2024-2025 EĞİTİM ÖĞRETİM YILI GÜZ DÖNEMİ
## BİLGİSAYAR MÜHENDİSLİĞİ BÖLÜMÜ
## VERİTABANI YÖNETİM SİSTEMLERİ DERSİ
## PROJE-FİNAL DÖKÜMANI

---

**Öğrenci Adı Soyadı:** [Adınızı Yazınız]  
**Öğrenci Numarası:** [Numaranızı Yazınız]

---

## SORU 1: Grup Bilgisi ve Yazılım Bileşenleri (5 p)

### Grup Arkadaşları
- [Grup arkadaşı 1 - Ad Soyad]
- [Grup arkadaşı 2 - Ad Soyad]
- (Bireysel çalışma ise "Bireysel proje" yazınız)

### Proje: Akademik Not ve Devam Takip Sistemi

### Yazılım Bileşenleri

| Katman | Teknoloji | Açıklama |
|--------|-----------|----------|
| **Veritabanı** | MS SQL Server 2022 | Tüm iş mantığı, hesaplamalar ve veri bütünlüğü kontrolü |
| **Backend** | Node.js + Express.js | REST API köprüsü (sadece SP çağrısı yapar) |
| **Frontend** | React.js + Vite | Modern kullanıcı arayüzü |
| **Stil** | Tailwind CSS | Responsive tasarım |
| **Veritabanı Bağlantısı** | mssql (npm) | Node.js - SQL Server bağlantısı |

### Veritabanı Nesneleri
- **13+ Tablo** (3NF normalize)
- **30+ Stored Procedure** (Tüm CRUD işlemleri)
- **5 Trigger** (Otomatik hesaplama ve kontrol)
- **4 View** (Raporlama için)
- **6 User-Defined Function** (Hesaplama fonksiyonları)

---

## SORU 2: GitHub Bağlantısı (5 p)

**Proje GitHub Linki:** https://github.com/[KULLANICI_ADINIZ]/akademik-not-sistemi

*(Lütfen yukarıdaki linki kendi GitHub kullanıcı adınızla değiştirin)*

Repository İçeriği:
- `/db` - Tüm SQL dosyaları (tablolar, SP'ler, trigger'lar, view'lar)
- `/backend` - Node.js API sunucusu
- `/frontend` - React kullanıcı arayüzü
- `README.md` - Kurulum ve kullanım talimatları

---

## SORU 3: Projenin Amacı (10 p)

### Proje Tanımı
**Akademik Not ve Devam Takip Sistemi**, üniversitelerde öğrenci not yönetimi ve devam takibini dijitalleştiren kapsamlı bir veritabanı uygulamasıdır.

### Amaç
Bu projenin temel amacı, akademik süreçlerde yaşanan manuel takip problemlerini çözmek ve şu hedefleri gerçekleştirmektir:

1. **Not Yönetimi:** Vize, final, ödev gibi not bileşenlerinin tanımlanması ve öğrenci notlarının sistematik olarak girilmesi
2. **Otomatik Hesaplama:** Ağırlıklı ortalama ve harf notu hesaplamasının veritabanı tarafında otomatik yapılması
3. **Devam Takibi:** Haftalık yoklama kayıtları ve devamsızlık yüzdesi hesaplama
4. **Uyarı Sistemi:** Devamsızlık sınırı aşıldığında otomatik bildirim ve durum güncelleme
5. **Raporlama:** Öğrenci transkripti, ders istatistikleri ve devam özetleri

### Hedef Kullanıcılar
- **Öğrenciler:** Notlarını ve devam durumunu görüntüleme
- **Akademisyenler:** Not girişi ve yoklama alma
- **Yöneticiler:** Sistem genelinde raporlama ve denetim

### Teknik Özellikler
- Tüm iş mantığı SQL Server'da (Stored Procedure + Trigger)
- Node.js sadece API köprüsü görevi görür
- 3NF (Üçüncü Normal Form) uyumlu veritabanı tasarımı

---

## SORU 4: Tablo ve İlişkiler (10 p)

### Veritabanı Tabloları

| # | Tablo Adı | Açıklama | Kayıt Sayısı |
|---|-----------|----------|--------------|
| 1 | Roles | Kullanıcı rolleri (Admin, Academic, Student) | 3 |
| 2 | Users | Tüm kullanıcılar (giriş bilgileri) | 20+ |
| 3 | Departments | Fakülte ve bölümler | 3 |
| 4 | Programs | Lisans/Yüksek Lisans programları | 3 |
| 5 | Students | Öğrenci detayları | 15+ |
| 6 | Academics | Akademisyen detayları | 4 |
| 7 | Courses | Ders tanımları | 6 |
| 8 | CourseOfferings | Dönemsel ders açılışları | 6 |
| 9 | ClassSessions | Haftalık ders oturumları | 84 |
| 10 | Enrollments | Öğrenci ders kayıtları | 29 |
| 11 | GradeComponents | Not bileşenleri (Vize, Final) | 14 |
| 12 | Grades | Öğrenci notları | 14+ |
| 13 | Attendance | Yoklama kayıtları | 100+ |
| 14 | AttendancePolicies | Devamsızlık politikaları | 6 |
| 15 | AttendanceAlerts | Devamsızlık uyarıları | - |
| 16 | Notifications | Bildirimler | - |
| 17 | AuditLog | Denetim kayıtları | - |

### İlişki Yapısı (PK - FK)

```
Roles (1) ──────────< Users (N)
                         │
           ┌─────────────┼─────────────┐
           │             │             │
           ▼             ▼             ▼
      Students      Academics     Departments
           │             │             │
           │             │             ▼
           │             │         Programs
           │             │             │
           ▼             ▼             ▼
      Enrollments ◄── CourseOfferings ◄── Courses
           │             │
           ▼             ▼
        Grades      ClassSessions
                         │
                         ▼
                    Attendance
```

### Önemli İlişkiler

| İlişki | Tür | Açıklama |
|--------|-----|----------|
| Users → Students | 1:1 | Öğrenci, User'ın alt tipi |
| Users → Academics | 1:1 | Akademisyen, User'ın alt tipi |
| CourseOfferings → Enrollments | 1:N | Bir derse birçok öğrenci kayıt olabilir |
| Enrollments → Grades | 1:N | Bir kayıt için birden fazla not bileşeni |
| ClassSessions → Attendance | 1:N | Bir oturumda birçok öğrenci yoklaması |

---

## SORU 5: ER Diyagramı (10 p)

*ER Diyagramı aşağıdaki araçlardan biriyle çizilip bu bölüme eklenmelidir:*
- [dbdiagram.io](https://dbdiagram.io) ✓ (Önerilen)
- draw.io
- Lucidchart

**ER Diyagramı için dbdiagram.io kodu proje dosyalarında `ER_Diagram.dbml` olarak mevcuttur.**

[ER DİYAGRAMI BURAYA EKLENECEKTİR - PNG/PDF formatında]

---

## SORU 6: DDL (CREATE) Kodları - 2 Tablo (10 p)

### Tablo 1: Users (Kullanıcılar)

```sql
CREATE TABLE dbo.Users
(
    UserID        INT IDENTITY(1,1) PRIMARY KEY,
    RoleID        INT NOT NULL,
    Username      NVARCHAR(50) NOT NULL,
    PasswordHash  VARBINARY(256) NOT NULL,
    PasswordSalt  VARBINARY(128) NOT NULL,
    Email         NVARCHAR(255) NOT NULL,
    Phone         NVARCHAR(20) NULL,
    IsActive      BIT NOT NULL CONSTRAINT DF_Users_IsActive DEFAULT (1),
    LastLoginAt   DATETIME2 NULL,
    CreatedAt     DATETIME2 NOT NULL CONSTRAINT DF_Users_CreatedAt DEFAULT (SYSUTCDATETIME()),
    
    CONSTRAINT UQ_Users_Username UNIQUE (Username),
    CONSTRAINT UQ_Users_Email UNIQUE (Email),
    CONSTRAINT FK_Users_Roles FOREIGN KEY (RoleID) REFERENCES dbo.Roles(RoleID)
);
```

**Açıklama:** Users tablosu tüm kullanıcıların (öğrenci, akademisyen, admin) ortak bilgilerini tutar. Şifre güvenliği için PasswordHash ve PasswordSalt kullanılır.

### Tablo 2: Enrollments (Ders Kayıtları)

```sql
CREATE TABLE dbo.Enrollments
(
    EnrollmentID    INT IDENTITY(1,1) PRIMARY KEY,
    OfferingID      INT NOT NULL,
    StudentID       INT NOT NULL,
    EnrollStatus    NVARCHAR(30) NOT NULL CONSTRAINT DF_Enrollments_Status DEFAULT ('Active'),
    EnrolledAt      DATETIME2 NOT NULL CONSTRAINT DF_Enrollments_EnrolledAt DEFAULT (SYSUTCDATETIME()),
    DroppedAt       DATETIME2 NULL,
    CurrentAverage  DECIMAL(5,2) NULL,
    LetterGrade     NVARCHAR(5) NULL,
    AttendancePercent DECIMAL(5,2) NULL,
    StatusUpdatedAt DATETIME2 NULL,
    
    CONSTRAINT FK_Enrollments_Offering FOREIGN KEY (OfferingID) 
        REFERENCES dbo.CourseOfferings(OfferingID),
    CONSTRAINT FK_Enrollments_Student FOREIGN KEY (StudentID) 
        REFERENCES dbo.Users(UserID),
    CONSTRAINT UQ_Enrollments UNIQUE (OfferingID, StudentID)
);
```

**Açıklama:** Enrollments tablosu öğrenci-ders ilişkisini yönetir. CurrentAverage ve LetterGrade alanları trigger tarafından otomatik güncellenir.

---

## SORU 7: DML (INSERT, UPDATE, DELETE) Kodları - 5 Adet (10 p)

### 1. INSERT - Yeni Öğrenci Ekleme

```sql
-- Önce Users tablosuna ekle
INSERT INTO dbo.Users (RoleID, Username, PasswordHash, PasswordSalt, Email, Phone)
VALUES (3, 'yeni.ogrenci', 0x1234, 0x5678, 'yeni@example.com', '+905551234567');

-- Sonra Students tablosuna ekle
DECLARE @NewUserID INT = SCOPE_IDENTITY();
INSERT INTO dbo.Students (StudentID, StudentNumber, NationalID, FirstName, LastName, 
                          BirthDate, Gender, DepartmentID, ProgramID)
VALUES (@NewUserID, '20250099', '12345678901', 'Ahmet', 'Yılmaz', 
        '2000-05-15', 'M', 1, 1);
```

### 2. INSERT - Not Girişi

```sql
INSERT INTO dbo.Grades (EnrollmentID, ComponentID, Score, GradedBy, Notes)
VALUES (1, 1, 85.50, 2, 'Vize sınavı notu');
```

### 3. UPDATE - Öğrenci Bilgisi Güncelleme

```sql
UPDATE dbo.Students
SET ProgramID = 2,
    AdvisorID = 5
WHERE StudentID = 3;
```

### 4. UPDATE - Ders Kapasitesi Güncelleme

```sql
UPDATE dbo.CourseOfferings
SET Capacity = 50
WHERE OfferingID = 1 AND Term = '2025-FALL';
```

### 5. DELETE - Ders Kaydı Silme (Soft Delete)

```sql
-- Fiziksel silme yerine durum güncelleme (soft delete)
UPDATE dbo.Enrollments
SET EnrollStatus = 'Dropped',
    DroppedAt = SYSUTCDATETIME()
WHERE EnrollmentID = 5;

-- Veya gerçek silme (CASCADE ile)
DELETE FROM dbo.Grades WHERE EnrollmentID = 5;
DELETE FROM dbo.Enrollments WHERE EnrollmentID = 5;
```

---

## SORU 8: SQL Sorguları - 10 Adet (10 p)

### Basit Sorgular (1-5)

#### Sorgu 1: Tüm Aktif Öğrencileri Listeleme
**Amaç:** Sistemdeki aktif öğrencilerin listesini getirmek.

```sql
SELECT 
    S.StudentNumber,
    S.FirstName,
    S.LastName,
    U.Email
FROM dbo.Students S
INNER JOIN dbo.Users U ON S.StudentID = U.UserID
WHERE U.IsActive = 1
ORDER BY S.LastName, S.FirstName;
```

#### Sorgu 2: Belirli Dönemdeki Dersleri Listeleme
**Amaç:** 2025 Güz döneminde açılan dersleri listelemek.

```sql
SELECT 
    C.CourseCode,
    C.CourseName,
    CO.Section,
    CO.Capacity
FROM dbo.CourseOfferings CO
INNER JOIN dbo.Courses C ON CO.CourseID = C.CourseID
WHERE CO.Term = '2025-FALL'
ORDER BY C.CourseCode;
```

#### Sorgu 3: Öğrenci Arama (Filtreleme)
**Amaç:** Adında 'Mehmet' geçen öğrencileri bulmak.

```sql
SELECT StudentNumber, FirstName, LastName
FROM dbo.Students
WHERE FirstName LIKE '%Mehmet%' OR LastName LIKE '%Mehmet%';
```

#### Sorgu 4: Son 7 Günde Eklenen Notlar
**Amaç:** Son bir haftada girilen notları listelemek.

```sql
SELECT 
    G.GradeID,
    G.Score,
    G.ScoreDate,
    GC.ComponentName
FROM dbo.Grades G
INNER JOIN dbo.GradeComponents GC ON G.ComponentID = GC.ComponentID
WHERE G.ScoreDate >= DATEADD(DAY, -7, GETDATE())
ORDER BY G.ScoreDate DESC;
```

#### Sorgu 5: Bildirim Sayısı
**Amaç:** Okunmamış bildirim sayısını öğrenmek.

```sql
SELECT 
    UserID,
    COUNT(*) AS UnreadCount
FROM dbo.Notifications
WHERE IsRead = 0
GROUP BY UserID;
```

---

### İleri Seviye Sorgular (6-10)

#### Sorgu 6: Öğrenci Transkripti (3+ Tablo JOIN)
**Amaç:** Bir öğrencinin tüm ders notlarını ve ortalamalarını getirmek.

```sql
SELECT 
    S.StudentNumber,
    CONCAT(S.FirstName, ' ', S.LastName) AS FullName,
    C.CourseCode,
    C.CourseName,
    C.Credit,
    CO.Term,
    E.CurrentAverage,
    E.LetterGrade,
    E.AttendancePercent
FROM dbo.Students S
INNER JOIN dbo.Enrollments E ON S.StudentID = E.StudentID
INNER JOIN dbo.CourseOfferings CO ON E.OfferingID = CO.OfferingID
INNER JOIN dbo.Courses C ON CO.CourseID = C.CourseID
WHERE S.StudentID = 3
ORDER BY CO.Term DESC, C.CourseCode;
```

**Sonuç:** Öğrencinin aldığı tüm dersler, notları ve devam yüzdeleri görüntülenir.

#### Sorgu 7: Ders Bazlı İstatistikler (GROUP BY + Aggregate)
**Amaç:** Her dersin öğrenci sayısı, ortalama notu ve geçme oranını hesaplamak.

```sql
SELECT 
    C.CourseCode,
    C.CourseName,
    COUNT(E.EnrollmentID) AS StudentCount,
    AVG(E.CurrentAverage) AS ClassAverage,
    MIN(E.CurrentAverage) AS MinGrade,
    MAX(E.CurrentAverage) AS MaxGrade,
    SUM(CASE WHEN E.LetterGrade IN ('AA','BA','BB','CB','CC') THEN 1 ELSE 0 END) * 100.0 
        / COUNT(E.EnrollmentID) AS PassRate
FROM dbo.Courses C
INNER JOIN dbo.CourseOfferings CO ON C.CourseID = CO.CourseID
INNER JOIN dbo.Enrollments E ON CO.OfferingID = E.OfferingID
WHERE E.CurrentAverage IS NOT NULL
GROUP BY C.CourseCode, C.CourseName
ORDER BY ClassAverage DESC;
```

**Sonuç:** Her dersin sınıf ortalaması ve geçme oranı hesaplanır.

#### Sorgu 8: Devamsızlık Riski Olan Öğrenciler (HAVING)
**Amaç:** Devamsızlık oranı %30'un üzerinde olan öğrencileri listelemek.

```sql
SELECT 
    S.StudentNumber,
    CONCAT(S.FirstName, ' ', S.LastName) AS FullName,
    C.CourseCode,
    COUNT(CASE WHEN A.Status = 'Absent' THEN 1 END) AS AbsentCount,
    COUNT(A.AttendanceID) AS TotalRecorded,
    CAST(COUNT(CASE WHEN A.Status = 'Absent' THEN 1 END) * 100.0 / 
         NULLIF(COUNT(A.AttendanceID), 0) AS DECIMAL(5,2)) AS AbsenceRate
FROM dbo.Students S
INNER JOIN dbo.Enrollments E ON S.StudentID = E.StudentID
INNER JOIN dbo.CourseOfferings CO ON E.OfferingID = CO.OfferingID
INNER JOIN dbo.Courses C ON CO.CourseID = C.CourseID
INNER JOIN dbo.ClassSessions CS ON CO.OfferingID = CS.OfferingID
LEFT JOIN dbo.Attendance A ON CS.SessionID = A.SessionID AND S.StudentID = A.StudentID
GROUP BY S.StudentNumber, S.FirstName, S.LastName, C.CourseCode
HAVING COUNT(CASE WHEN A.Status = 'Absent' THEN 1 END) * 100.0 / 
       NULLIF(COUNT(A.AttendanceID), 0) > 30
ORDER BY AbsenceRate DESC;
```

**Sonuç:** Devamsızlık riski taşıyan öğrenciler tespit edilir.

#### Sorgu 9: Akademisyen İş Yükü (4 Tablo JOIN + GROUP BY)
**Amaç:** Her akademisyenin verdiği ders sayısı ve toplam öğrenci sayısını bulmak.

```sql
SELECT 
    A.AcademicID,
    A.Title,
    U.Username,
    D.DepartmentName,
    COUNT(DISTINCT CO.OfferingID) AS CourseCount,
    COUNT(DISTINCT E.StudentID) AS TotalStudents,
    SUM(CASE WHEN E.LetterGrade IS NULL AND E.EnrollStatus = 'Active' THEN 1 ELSE 0 END) AS PendingGrades
FROM dbo.Academics A
INNER JOIN dbo.Users U ON A.AcademicID = U.UserID
INNER JOIN dbo.Departments D ON A.DepartmentID = D.DepartmentID
LEFT JOIN dbo.CourseOfferings CO ON A.AcademicID = CO.AcademicID
LEFT JOIN dbo.Enrollments E ON CO.OfferingID = E.OfferingID
GROUP BY A.AcademicID, A.Title, U.Username, D.DepartmentName
ORDER BY TotalStudents DESC;
```

**Sonuç:** Akademisyenlerin iş yükü dağılımı görülür.

#### Sorgu 10: GPA Sıralaması (Subquery + Aggregate)
**Amaç:** Öğrencileri GPA'larına göre sıralamak ve bölüm bazlı karşılaştırma yapmak.

```sql
SELECT 
    S.StudentNumber,
    CONCAT(S.FirstName, ' ', S.LastName) AS FullName,
    D.DepartmentName,
    AVG(
        CASE E.LetterGrade
            WHEN 'AA' THEN 4.0
            WHEN 'BA' THEN 3.5
            WHEN 'BB' THEN 3.0
            WHEN 'CB' THEN 2.5
            WHEN 'CC' THEN 2.0
            WHEN 'DC' THEN 1.5
            WHEN 'DD' THEN 1.0
            ELSE 0.0
        END
    ) AS GPA,
    COUNT(E.EnrollmentID) AS CompletedCourses,
    SUM(C.Credit) AS TotalCredits
FROM dbo.Students S
INNER JOIN dbo.Departments D ON S.DepartmentID = D.DepartmentID
INNER JOIN dbo.Enrollments E ON S.StudentID = E.StudentID
INNER JOIN dbo.CourseOfferings CO ON E.OfferingID = CO.OfferingID
INNER JOIN dbo.Courses C ON CO.CourseID = C.CourseID
WHERE E.LetterGrade IS NOT NULL
GROUP BY S.StudentNumber, S.FirstName, S.LastName, D.DepartmentName
HAVING COUNT(E.EnrollmentID) >= 1
ORDER BY GPA DESC;
```

**Sonuç:** Öğrenciler GPA sırasına göre listelenir.

---

## SORU 9: Veritabanı Bağlama ve Arayüz (10 p)

### Veritabanı Bağlantısı

Node.js tarafında `mssql` kütüphanesi kullanılarak SQL Server'a bağlantı sağlanmıştır:

```javascript
// backend/db/index.js
const sql = require('mssql');

const config = {
    user: process.env.DB_USER,
    password: process.env.DB_PASSWORD,
    server: process.env.DB_SERVER,
    database: process.env.DB_NAME,
    options: {
        encrypt: false,
        trustServerCertificate: true
    }
};

const poolPromise = new sql.ConnectionPool(config)
    .connect()
    .then(pool => {
        console.log('✓ MS SQL bağlantısı başarılı');
        return pool;
    });

module.exports = { sql, poolPromise };
```

### API Endpoint Örneği

```javascript
// routes/grading.js - Not Girişi
router.post('/record', async (req, res) => {
    const { enrollmentId, componentId, score, gradedBy } = req.body;
    const pool = await poolPromise;
    
    await pool.request()
        .input('EnrollmentID', sql.Int, enrollmentId)
        .input('ComponentID', sql.Int, componentId)
        .input('Score', sql.Decimal(5, 2), score)
        .input('GradedBy', sql.Int, gradedBy)
        .execute('dbo.sp_RecordGrade');
    
    res.json({ success: true });
});
```

### Kullanıcı Arayüzü

React.js ile geliştirilen modern arayüz şu sayfaları içermektedir:

| Sayfa | Açıklama | Kullanıcı |
|-------|----------|-----------|
| Login | Giriş ekranı | Tümü |
| Dashboard | Ana sayfa, özet bilgiler | Tümü |
| Derslerim | Akademisyenin dersleri | Akademisyen |
| Öğrenci Listesi | Derse kayıtlı öğrenciler | Akademisyen |
| Not Girişi | Vize/Final not girişi | Akademisyen |
| Yoklama | Haftalık yoklama alma | Akademisyen |
| Transkript | Öğrenci not dökümü | Öğrenci |
| Ders Programı | Haftalık program | Öğrenci |

[EKRAN GÖRÜNTÜLERİ BURAYA EKLENECEKTİR]

---

## SORU 10: Transaction Nedir ve Örnek (10 p)

### Transaction Tanımı

**Transaction (İşlem)**, veritabanında bir veya birden fazla SQL komutunun tek bir mantıksal birim olarak çalıştırılmasıdır. Transaction'lar **ACID** prensiplerini sağlar:

- **Atomicity (Bölünmezlik):** Tüm işlemler ya tamamen başarılı olur ya da hiçbiri uygulanmaz
- **Consistency (Tutarlılık):** İşlem sonunda veritabanı tutarlı durumda kalır
- **Isolation (Yalıtım):** Eşzamanlı işlemler birbirini etkilemez
- **Durability (Kalıcılık):** Onaylanan değişiklikler kalıcıdır

### Projeden Transaction Örneği

Aşağıdaki Stored Procedure, not girişi sırasında transaction kullanmaktadır:

```sql
CREATE PROCEDURE dbo.sp_RecordGrade
    @EnrollmentID INT,
    @ComponentID INT,
    @Score DECIMAL(5,2),
    @GradedBy INT,
    @Notes NVARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        BEGIN TRANSACTION;  -- Transaction başlat
        
        -- Not zaten var mı kontrol et
        IF EXISTS (SELECT 1 FROM dbo.Grades 
                   WHERE EnrollmentID = @EnrollmentID AND ComponentID = @ComponentID)
        BEGIN
            -- Güncelle
            UPDATE dbo.Grades
            SET Score = @Score,
                ScoreDate = SYSUTCDATETIME(),
                GradedBy = @GradedBy,
                Notes = @Notes
            WHERE EnrollmentID = @EnrollmentID AND ComponentID = @ComponentID;
            
            -- Audit log'a kaydet
            INSERT INTO dbo.AuditLog (TableName, RecordID, ActionType, ChangedBy, ChangeDetails)
            VALUES ('Grades', CONCAT(@EnrollmentID, '-', @ComponentID), 'Update', 
                    @GradedBy, CONCAT('Score updated to ', @Score));
        END
        ELSE
        BEGIN
            -- Yeni kayıt ekle
            INSERT INTO dbo.Grades (EnrollmentID, ComponentID, Score, GradedBy, Notes)
            VALUES (@EnrollmentID, @ComponentID, @Score, @GradedBy, @Notes);
            
            -- Audit log'a kaydet
            INSERT INTO dbo.AuditLog (TableName, RecordID, ActionType, ChangedBy, ChangeDetails)
            VALUES ('Grades', CONCAT(@EnrollmentID, '-', @ComponentID), 'Insert', 
                    @GradedBy, CONCAT('Score inserted as ', @Score));
        END
        
        COMMIT TRANSACTION;  -- Başarılıysa onayla
        
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;  -- Hata varsa geri al
        THROW;  -- Hatayı yeniden fırlat
    END CATCH
END;
```

**Açıklama:** Bu procedure'de:
1. `BEGIN TRANSACTION` ile işlem başlatılır
2. Not güncelleme/ekleme ve audit log kaydı yapılır
3. Hata olmazsa `COMMIT TRANSACTION` ile onaylanır
4. Hata olursa `ROLLBACK TRANSACTION` ile tüm değişiklikler geri alınır

---

## SORU 11: View ve Stored Procedure (10 p)

### View Nedir?

**View (Görünüm)**, bir veya daha fazla tablodan oluşturulan sanal tablodur. Fiziksel veri tutmaz, sorgu çalıştırıldığında dinamik olarak sonuç üretir.

**Avantajları:**
- Karmaşık sorguları basitleştirir
- Güvenlik sağlar (sadece belirli sütunları gösterir)
- Veri soyutlama sunar

### View Örneği: vw_StudentTranscript

```sql
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
    CO.Term,
    E.CurrentAverage,
    E.LetterGrade,
    E.EnrollStatus,
    E.AttendancePercent,
    GradePoint = dbo.fn_GetGradePoint(E.LetterGrade),
    IsPass = dbo.fn_IsPassingGrade(E.LetterGrade)
FROM dbo.Students S
INNER JOIN dbo.Enrollments E ON S.StudentID = E.StudentID
INNER JOIN dbo.CourseOfferings CO ON E.OfferingID = CO.OfferingID
INNER JOIN dbo.Courses C ON CO.CourseID = C.CourseID
INNER JOIN dbo.Programs P ON C.ProgramID = P.ProgramID
INNER JOIN dbo.Departments D ON P.DepartmentID = D.DepartmentID;
GO
```

**Kullanımı:**
```sql
SELECT * FROM dbo.vw_StudentTranscript WHERE StudentID = 3;
```

**Sonuç:**
| StudentNumber | FullName | CourseCode | CourseName | CurrentAverage | LetterGrade |
|---------------|----------|------------|------------|----------------|-------------|
| 20250001 | Mehmet Yıldız | CENG101 | Programlamaya Giriş | 85.50 | BA |
| 20250001 | Mehmet Yıldız | CENG102 | Veri Yapıları | 72.00 | CC |

---

### Stored Procedure Nedir?

**Stored Procedure (Saklı Yordam)**, veritabanında saklanan ve tekrar tekrar çalıştırılabilen SQL kod bloğudur.

**Avantajları:**
- Performans (önceden derlenmiş)
- Güvenlik (doğrudan tablo erişimi engellenir)
- Bakım kolaylığı
- İş mantığını veritabanında tutma

### Stored Procedure Örneği: sp_GetStudentTranscript

```sql
CREATE PROCEDURE dbo.sp_GetStudentTranscript
    @StudentID INT
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT 
        C.CourseCode,
        C.CourseName,
        C.Credit,
        CO.Term,
        E.CurrentAverage,
        E.LetterGrade,
        E.EnrollStatus,
        E.AttendancePercent
    FROM dbo.Enrollments E
    INNER JOIN dbo.CourseOfferings CO ON E.OfferingID = CO.OfferingID
    INNER JOIN dbo.Courses C ON CO.CourseID = C.CourseID
    WHERE E.StudentID = @StudentID
    ORDER BY CO.Term DESC, C.CourseCode;
END;
GO
```

**Kullanımı:**
```sql
EXEC dbo.sp_GetStudentTranscript @StudentID = 3;
```

**Sonuç:**
| CourseCode | CourseName | Credit | Term | CurrentAverage | LetterGrade |
|------------|------------|--------|------|----------------|-------------|
| CENG101 | Programlamaya Giriş | 4.00 | 2025-FALL | 85.50 | BA |
| CENG102 | Veri Yapıları | 4.00 | 2025-FALL | 72.00 | CC |
| CENG301 | Veritabanı Yönetim Sistemleri | 3.00 | 2025-FALL | NULL | NULL |

---

## EKLER

### Ek 1: Proje Dosya Yapısı

```
akademik-not-sistemi/
├── db/
│   ├── schema/
│   │   └── tables.sql
│   ├── stored_procedures/
│   │   ├── auth.sql
│   │   ├── student.sql
│   │   ├── course.sql
│   │   ├── grading.sql
│   │   ├── attendance.sql
│   │   └── bulk_operations.sql
│   ├── triggers/
│   │   └── triggers.sql
│   ├── views/
│   │   └── views.sql
│   ├── functions/
│   │   └── functions.sql
│   └── seeds/
│       └── sample_data.sql
├── backend/
│   ├── routes/
│   ├── db/
│   └── server.js
├── frontend/
│   ├── src/
│   │   ├── pages/
│   │   ├── components/
│   │   └── services/
│   └── package.json
└── README.md
```

### Ek 2: Test Kullanıcıları

| Rol | Kullanıcı Adı | Şifre |
|-----|---------------|-------|
| Admin | admin | Admin@123 |
| Akademisyen | ayse.akademik | Akademik@123 |
| Öğrenci | mehmet.ogrenci | Ogrenci@123 |

---

*Rapor Tarihi: Aralık 2024*

