# Akademik Not ve Devam Takip Sistemi – Veritabanı Mimari Raporu

## 1. Mimari İlkeler
- Tüm iş mantığı, bütünlük kuralları ve hesaplamalar MS SQL Server içinde tanımlanan stored procedure ve trigger’larda uygulanacak; Node.js katmanı sadece köprü görevi görecek.
- Tablolar 3NF prensiplerine göre bölünmüş, her alan tek bir gerçeği temsil eder ve türetilmiş alanlar yalnızca raporlama gerektirdiğinde tutulur.
- Kimlik sütunları `INT IDENTITY` veya üniversite politikalarına göre `UNIQUEIDENTIFIER` ile yönetilir; tarih/zaman alanları için `DATETIME2`, parasal değerler için `DECIMAL(10,2)` tercih edilecektir.
- Güvenlik amaçlı olarak kullanıcı parolaları hash + salt kombinasyonu ile saklanacak; doğrulama yalnızca stored procedure içinde yapılacaktır.

## 2. Varlık Tanımları
| Tablo | Temel Alanlar | Açıklama / Normalizasyon Notu |
| --- | --- | --- |
| `Roles` | `RoleID (PK)`, `RoleName (UK)`, `Description` | Yetki seviyelerini merkezi olarak tutar (Admin, Student, Academic, Advisor vb.). |
| `Users` | `UserID (PK)`, `RoleID (FK)`, `Username (UK)`, `PasswordHash`, `PasswordSalt`, `Email`, `Phone`, `IsActive`, `CreatedAt` | Tüm kişilere ait kimlik bilgilerinin tek tablosu; parolalar hashlenmiş formda saklanır. |
| `Students` | `StudentID (PK/FK Users)`, `StudentNumber (UK)`, `NationalID (UK)`, `FirstName`, `LastName`, `BirthDate`, `Gender`, `DepartmentID (FK)`, `AdvisorID (FK Academics)` | Öğrenciye özel alanlar Users tablosundan ayrılarak 3NF sağlanır. |
| `Academics` | `AcademicID (PK/FK Users)`, `Title`, `DepartmentID (FK)`, `Office`, `PhoneExtension` | Akademik personel için genişletilmiş bilgiler. |
| `Departments` | `DepartmentID (PK)`, `FacultyName`, `DepartmentName`, `ChairID (FK Academics)` | Bölüm tanımları, hem öğrenci hem akademik ilişkileri için referans. |
| `Programs` | `ProgramID (PK)`, `DepartmentID (FK)`, `ProgramName`, `DegreeLevel`, `CreditRequirement` | Bölüm içindeki programlara ait bilgileri saklar. |
| `Courses` | `CourseID (PK)`, `CourseCode (UK)`, `CourseName`, `ProgramID (FK)`, `Credit`, `ECTS`, `SemesterOffered` | Ders sabit bilgilerinin tutulduğu tablo. |
| `CourseOfferings` | `OfferingID (PK)`, `CourseID (FK)`, `AcademicID (FK)`, `Term`, `Section`, `Capacity`, `ScheduleJSON` | Dönem bazlı ders açılışları; JSON alanı ders programını (gün/saat/salon) saklar. |
| `ClassSessions` | `SessionID (PK)`, `OfferingID (FK)`, `SessionDate`, `StartTime`, `EndTime`, `SessionType (Lecture/Lab)` | Devam takibi için oluşturulan her oturuma ait detaylar. |
| `Enrollments` | `EnrollmentID (PK)`, `OfferingID (FK)`, `StudentID (FK)`, `EnrollStatus`, `EnrolledAt`, `DroppedAt` | Öğrencinin dönemlik ders kayıtlarını tutar; durum alanı (Active, Dropped, Completed) içerir. |
| `GradeComponents` | `ComponentID (PK)`, `OfferingID (FK)`, `ComponentName`, `WeightPercent`, `IsMandatory` | Ders içi değerlendirme bileşenlerini (Vize, Final, Proje) tanımlar; ağırlık toplamı trigger ile %100 tutulur. |
| `Grades` | `GradeID (PK)`, `EnrollmentID (FK)`, `ComponentID (FK)`, `Score`, `ScoreDate`, `GradedBy (FK Academics)` | Öğrenci not girişleri; Score 0-100 arasında tutulur. |
| `AttendancePolicies` | `PolicyID (PK)`, `OfferingID (FK)`, `MaxAbsencePercent`, `WarningThresholdPercent`, `AutoFailPercent` | Ders bazlı devamsızlık kurallarını içerir. |
| `Attendance` | `AttendanceID (PK)`, `SessionID (FK)`, `StudentID (FK)`, `Status (Present/Absent/Late)`, `RecordedAt`, `RecordedBy (FK Academics)` | Her oturum için öğrencinin devam durumu; tetikleyicilerle politikalara göre değerlendirilir. |
| `Notifications` | `NotificationID (PK)`, `UserID (FK)`, `Type`, `Title`, `Message`, `IsRead`, `CreatedAt` | Sistem içinde oluşturulan bildirimleri saklar. |
| `AuditLog` | `AuditID (PK)`, `TableName`, `RecordID`, `ActionType`, `ChangedBy (FK Users)`, `ChangeTimestamp`, `ChangeDetails` | Kritik SP’lerin izlenebilirliğini sağlar. |

### Normalizasyon Örnekleri
- Öğrenci ve akademik bilgiler `Users` tablosundan ayrıştırılarak çok değerli bağımlılıklar kaldırıldı.
- Ders içerikleri (`Courses`) ile dönemsel açılışlar (`CourseOfferings`) ayrıldı; bu sayede ders bilgilerinin tekrar edilmesi önlendi.
- Not bileşenleri (`GradeComponents`) ile not değerleri (`Grades`) ayrı kurgulanarak bileşen ağırlıkları merkezi yönetildi.

## 3. İlişkiler
- `Users.RoleID → Roles.RoleID` (N:1) – Her kullanıcı tek rol, bir rol birden fazla kullanıcı.
- `Students.StudentID → Users.UserID` ve `Academics.AcademicID → Users.UserID` (1:1) – Alt tip tablolar.
- `Departments.DepartmentID → Programs.DepartmentID` ve `Departments.DepartmentID → Students.DepartmentID` (1:N).
- `Academics` tabloları hem `Departments` (bölüm bağlılığı) hem de `CourseOfferings` (ders açma) ile ilişkilidir.
- `Courses.CourseID → CourseOfferings.CourseID` (1:N); `CourseOfferings.OfferingID → Enrollments.OfferingID` (1:N).
- `Enrollments.EnrollmentID → Grades.EnrollmentID` ve `GradeComponents.ComponentID → Grades.ComponentID` (her not kaydı hem öğrenci-ders hem de bileşene bağlı).
- `CourseOfferings.OfferingID → GradeComponents.OfferingID`, `CourseOfferings.OfferingID → AttendancePolicies.OfferingID`, `CourseOfferings.OfferingID → ClassSessions.OfferingID`.
- `ClassSessions.SessionID → Attendance.SessionID`; `Attendance.StudentID` `Enrollments.StudentID` ile kontrol edilecek (FK veya trigger).
- `Notifications.UserID → Users.UserID`; `AuditLog.ChangedBy → Users.UserID`.

Bu yapı karmaşık çoktan-çoğa ilişkileri (ör. öğrenciler ↔ ders açılışları) `Enrollments` gibi bağlantı tablolarıyla çözer ve 3NF’i korur.

## 4. Stored Procedure Envanteri
### Kimlik & Yetkilendirme
- `sp_LoginUser (@Username, @Password)` – Hash/salt kontrolü, son giriş zamanını günceller, rol bilgisi döner.
- `sp_CreateUser (@RoleID, @Username, @Password, @Email, …)` – Kullanıcı ve rol ilişkilendirmesini yapar; gerekli alt tablo insert işlemlerini transaction içinde gerçekleştirir.
- `sp_UpdateUserContact (@UserID, @Email, @Phone)` – İletişim bilgilerini günceller.
- `sp_DeactivateUser (@UserID, @Reason)` – Pasifleştirir, ilgili notification oluşturur.

### Öğrenci & Akademisyen Yönetimi
- `sp_RegisterStudent (@UserFields…, @StudentFields…)` – Kullanıcı + öğrenci kayıtlarını tek seferde yaratır.
- `sp_AssignAdvisor (@StudentID, @AdvisorID)` – Öğrenci danışman ataması.
- `sp_RegisterAcademic (@UserFields…, @AcademicFields…)`.
- `sp_ListStudentsByDepartment (@DepartmentID)` – Filtreli listeleme.

### Ders & Kayıt İşlemleri
- `sp_CreateCourse (@CourseCode, @CourseName, …)`; `sp_UpdateCourse`, `sp_DeleteCourse`.
- `sp_OpenCourseOffering (@CourseID, @AcademicID, @Term, …)` – Ders açılışı + default policy şablonu.
- `sp_GetCourseCatalog (@ProgramID, @Term)` – React tarafı için liste.
- `sp_EnrollStudent (@OfferingID, @StudentID)` – Kapasite kontrolü, çakışma kontrolü.
- `sp_DropEnrollment (@EnrollmentID, @Reason)`.
- `sp_GetStudentSchedule (@StudentID, @Term)` – Ders programını JSON olarak döner.

### Not Yönetimi
- `sp_DefineGradeComponent (@OfferingID, @ComponentName, @WeightPercent, @IsMandatory)` – Toplam ağırlığı trigger veya SP içinde doğrular.
- `sp_RecordGrade (@EnrollmentID, @ComponentID, @Score, @GradedBy)` – Not kaydı; tetikleyiciler ortalamayı günceller.
- `sp_GetGradeBook (@OfferingID)` – Akademisyen için sınıf not listesi.
- `sp_GetStudentTranscript (@StudentID)` – Tüm dönem notları, ortalama ve ECTS hesapları ile döner.
- `sp_ApproveFinalGrades (@OfferingID, @AcademicID)` – Not kilitleme ve audit log.

### Devam Takibi
- `sp_DefineAttendancePolicy (@OfferingID, @MaxAbsencePercent, …)`.
- `sp_RecordAttendance (@SessionID, @StudentID, @Status, @RecordedBy)` – Yoklama girişi; tetikleyici eşik kontrollerini yapar.
- `sp_GetAttendanceSummary (@OfferingID)` – Ders bazlı özet.
- `sp_GetStudentAttendanceDetail (@StudentID, @OfferingID)`.

### Raporlama & Bildirim
- `sp_GetDashboardStats (@RoleID, @UserID)` – Kullanıcının rolüne göre özet.
- `sp_ListNotifications (@UserID)` / `sp_MarkNotificationRead (@NotificationID)`.
- `sp_SearchAuditLog (@DateFrom, @DateTo, @ActionType, @TableName)`.

Tüm CRUD istekleri bu SP’ler aracılığıyla yapılacak ve backend/React sadece parametreleri aktaracaktır.

## 5. Trigger Senaryoları
1. **Not Girişi Sonrası Dinamik Ortalama Hesabı (`tr_Grades_AIU_Recalculate`)**  
   - **Olay:** `Grades` tablosunda INSERT/UPDATE/DELETE.  
   - **Mantık:** İlgili `EnrollmentID` için tüm notlar çekilir, ağırlıklı ortalama hesaplanır ve `Enrollments` tablosundaki `CurrentAverage`, `LetterGrade`, `Status` alanları güncellenir. Ortalama değişimi varsa `AuditLog` kaydı ve öğrenci + danışmana `Notifications` eklenir. Ayrıca ders bazlı not bileşeni ağırlık toplamı %100 değilse işlem rollback edilir.  
   - **Fayda:** Node.js katmanına hiç matematiksel yük bırakmadan, anlık GPA güncellemesi sağlar.

2. **Devamsızlık Eşiği Tetikleyicisi (`tr_Attendance_AI_ThresholdCheck`)**  
   - **Olay:** `Attendance` tablosu INSERT.  
   - **Mantık:** İlgili `OfferingID` için tanımlı `AttendancePolicies` alınır. Öğrencinin toplam yoklama sayısı üzerinden devamsızlık yüzdesi hesaplanır. `WarningThresholdPercent` aşılırsa `Notifications` tablosuna öğrenci ve danışman için kayıt eklenir. `AutoFailPercent` aşılırsa `Enrollments` kaydında `EnrollStatus = 'AutoFailDueToAttendance'` yapılır ve `AuditLog`a detay eklenir. Aynı eşik için tekrar bildirim gönderilmemesi adına yardımcı bir `AttendanceAlerts` tablosu veya trigger içinde kontrol kullanılır.  
   - **Fayda:** Devamsızlık işlemleri tam otomatik hale gelir, yönetmelik uyumu garanti edilir.

Bu iki tetikleyici, hocanın beklediği “iş mantığı veritabanında yaşar” ilkesini sahada görünür kılar.

## 6. Sonraki Adımlar
- Bu rapor doğrultusunda MS SQL DDL şeması oluşturulacak (tablolar, PK/FK, indeksler).
- Stored procedure ve trigger’lar bu dokümandaki isimlendirme/akışa göre yazılacak.
- Backend (Node.js) sadece ilgili SP adını ve parametrelerini çağıracak; React tarafı da bu uçlara bağlanacak.

