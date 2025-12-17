# 📚 Akademik Not ve Devam Takip Sistemi

> Marmara Üniversitesi - Veritabanı Yönetim Sistemleri Dersi Projesi

![SQL Server](https://img.shields.io/badge/SQL%20Server-2022-CC2927?style=flat&logo=microsoft-sql-server)
![Node.js](https://img.shields.io/badge/Node.js-18+-339933?style=flat&logo=node.js)
![React](https://img.shields.io/badge/React-18-61DAFB?style=flat&logo=react)
![License](https://img.shields.io/badge/License-MIT-blue.svg)

## 📋 Proje Hakkında

Bu proje, üniversitelerde öğrenci not yönetimi ve devam takibini dijitalleştiren kapsamlı bir veritabanı uygulamasıdır. Tüm iş mantığı SQL Server'da Stored Procedure ve Trigger'lar ile gerçekleştirilmiştir.

### ✨ Özellikler

- 📊 **Not Yönetimi:** Vize, Final, Ödev gibi bileşen bazlı not girişi
- 📈 **Otomatik Hesaplama:** Ağırlıklı ortalama ve harf notu (Trigger ile)
- ✅ **Yoklama Takibi:** Haftalık yoklama ve devam yüzdesi hesaplama
- ⚠️ **Uyarı Sistemi:** Devamsızlık sınırı aşıldığında otomatik bildirim
- 📑 **Raporlama:** Transkript, ders istatistikleri, devam özetleri
- 🔐 **Rol Tabanlı Erişim:** Admin, Akademisyen, Öğrenci

## 🏗️ Mimari

```
┌─────────────────────────────────────────────────────────┐
│              FRONTEND (React + Vite + Tailwind)         │
└────────────────────────┬────────────────────────────────┘
                         │ HTTP/REST
                         ▼
┌─────────────────────────────────────────────────────────┐
│              BACKEND (Node.js + Express)                │
│              Sadece API Köprüsü - İş Mantığı YOK        │
└────────────────────────┬────────────────────────────────┘
                         │ mssql (SP calls)
                         ▼
┌─────────────────────────────────────────────────────────┐
│              DATABASE (MS SQL Server 2022)              │
│  ┌─────────┐ ┌─────────┐ ┌─────────┐ ┌─────────┐       │
│  │ Tables  │ │   SPs   │ │Triggers │ │  Views  │       │
│  │  (13+)  │ │  (30+)  │ │   (5)   │ │   (4)   │       │
│  └─────────┘ └─────────┘ └─────────┘ └─────────┘       │
│              TÜM İŞ MANTIĞI BURADA                      │
└─────────────────────────────────────────────────────────┘
```

## 📁 Proje Yapısı

```
akademik-not-sistemi/
├── 📂 db/
│   ├── 📂 schema/
│   │   └── tables.sql              # Tablo tanımları
│   ├── 📂 stored_procedures/
│   │   ├── auth.sql                # Kimlik doğrulama
│   │   ├── student.sql             # Öğrenci işlemleri
│   │   ├── course.sql              # Ders işlemleri
│   │   ├── grading.sql             # Not işlemleri
│   │   ├── attendance.sql          # Yoklama işlemleri
│   │   ├── academic.sql            # Akademisyen işlemleri
│   │   ├── reporting.sql           # Raporlama
│   │   └── bulk_operations.sql     # Toplu işlemler (CURSOR)
│   ├── 📂 triggers/
│   │   └── triggers.sql            # 5 adet trigger
│   ├── 📂 views/
│   │   └── views.sql               # 4 adet view
│   ├── 📂 functions/
│   │   └── functions.sql           # 6 adet UDF
│   ├── 📂 migrations/
│   │   └── *.sql                   # Migration dosyaları
│   └── 📂 seeds/
│       └── sample_data.sql         # Test verileri
├── 📂 backend/
│   ├── 📂 routes/                  # API endpoint'leri
│   ├── 📂 db/                      # DB bağlantısı
│   ├── server.js                   # Express sunucu
│   └── .env                        # Ortam değişkenleri
├── 📂 frontend/
│   ├── 📂 src/
│   │   ├── 📂 pages/               # React sayfaları
│   │   ├── 📂 components/          # Bileşenler
│   │   ├── 📂 services/            # API servisleri
│   │   └── 📂 context/             # Auth context
│   └── vite.config.js
├── start.sh                        # Tek tıkla başlat
├── ER_Diagram.dbml                 # ER diyagramı kodu
└── README.md
```

## 🚀 Kurulum

### Gereksinimler

- [Docker Desktop](https://www.docker.com/products/docker-desktop/) (SQL Server için)
- [Node.js](https://nodejs.org/) v18+
- [Git](https://git-scm.com/)

### 1. Projeyi Klonla

```bash
git clone https://github.com/[KULLANICI_ADINIZ]/akademik-not-sistemi.git
cd akademik-not-sistemi
```

### 2. SQL Server Docker Container

```bash
docker run -e 'ACCEPT_EULA=Y' \
  -e 'SA_PASSWORD=MyStrongPassw0rd!' \
  -p 1433:1433 \
  --name akademik-sql \
  -d mcr.microsoft.com/mssql/server:2022-latest
```

### 3. Veritabanını Oluştur

Azure Data Studio veya SSMS ile bağlan ve sırasıyla çalıştır:
1. `db/schema/tables.sql`
2. `db/stored_procedures/*.sql`
3. `db/triggers/triggers.sql`
4. `db/views/views.sql`
5. `db/functions/functions.sql`
6. `db/seeds/sample_data.sql`

### 4. Backend Kurulum

```bash
cd backend
npm install
cp .env.example .env  # Gerekirse düzenle
npm start
```

### 5. Frontend Kurulum

```bash
cd frontend
npm install
npm run dev
```

### 6. Tarayıcıda Aç

```
http://localhost:5173
```

## 🔐 Test Kullanıcıları

| Rol | Kullanıcı Adı | Şifre |
|-----|---------------|-------|
| Admin | `admin` | `Admin@123` |
| Akademisyen | `ayse.akademik` | `Akademik@123` |
| Öğrenci | `mehmet.ogrenci` | `Ogrenci@123` |

## 📊 Veritabanı Nesneleri

### Tablolar (13+)
- Roles, Users, Departments, Programs
- Students, Academics, Courses, CourseOfferings
- ClassSessions, Enrollments, GradeComponents, Grades
- Attendance, AttendancePolicies, AttendanceAlerts
- Notifications, AuditLog

### Stored Procedures (30+)
- `sp_LoginUser`, `sp_CreateUser`
- `sp_RegisterStudent`, `sp_GetStudentSchedule`
- `sp_RecordGrade`, `sp_GetStudentTranscript`
- `sp_RecordAttendance`, `sp_GetAttendanceSummary`
- `sp_SendBulkNotification` (CURSOR örneği)
- ve daha fazlası...

### Triggers (5)
- `tr_Grades_AIU_Recalculate` - Not ortalaması hesaplama
- `tr_GradeComponents_CheckWeights` - Ağırlık kontrolü
- `tr_Attendance_AI_ThresholdCheck` - Devamsızlık uyarısı
- `tr_Attendance_AIU_UpdatePercent` - Devam yüzdesi güncelleme
- `tr_Enrollments_StatusAudit` - Durum değişikliği kaydı

### Views (4)
- `vw_StudentTranscript` - Öğrenci transkripti
- `vw_CourseStatistics` - Ders istatistikleri
- `vw_AttendanceSummary` - Devam özeti
- `vw_AcademicWorkload` - Akademisyen iş yükü

### Functions (6)
- `fn_CalculateLetterGrade` - Harf notu hesaplama
- `fn_GetGradePoint` - Not puanı (4.0 skala)
- `fn_CalculateStudentGPA` - GPA hesaplama
- `fn_GetStudentGrades` - Not tablosu (TVF)
- `fn_CalculateAttendancePercent` - Devam yüzdesi
- `fn_IsPassingGrade` - Geçer not kontrolü

## 📸 Ekran Görüntüleri

| Giriş Ekranı | Dashboard |
|--------------|-----------|
| ![Login](screenshots/login.png) | ![Dashboard](screenshots/dashboard.png) |

| Not Girişi | Yoklama |
|------------|---------|
| ![Grades](screenshots/gradebook.png) | ![Attendance](screenshots/attendance.png) |

*(Ekran görüntüleri `screenshots/` klasörüne eklenmelidir)*

## 🛠️ Teknolojiler

| Katman | Teknoloji |
|--------|-----------|
| Veritabanı | MS SQL Server 2022 |
| Backend | Node.js 18+, Express.js |
| Frontend | React 18, Vite, Tailwind CSS |
| DB Bağlantısı | mssql (npm) |
| Containerization | Docker |

## 📝 Lisans

Bu proje MIT lisansı altında lisanslanmıştır.

## 👨‍💻 Geliştirici

- **Ad Soyad:** [Adınızı Yazın]
- **Öğrenci No:** [Numaranızı Yazın]
- **Üniversite:** Marmara Üniversitesi
- **Bölüm:** Bilgisayar Mühendisliği
- **Ders:** Veritabanı Yönetim Sistemleri

---

⭐ Bu projeyi beğendiyseniz yıldız vermeyi unutmayın!

