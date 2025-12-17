/*
    db/schema/tables.sql
    Purpose: Create core tables, constraints, and supporting indexes
    Execution order: run after ensuring database context is selected.
*/

SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

/* =========================================================
   1. Drop existing tables (child -> parent order)
   ========================================================= */
IF OBJECT_ID('dbo.Notifications', 'U') IS NOT NULL DROP TABLE dbo.Notifications;
IF OBJECT_ID('dbo.AttendanceAlerts', 'U') IS NOT NULL DROP TABLE dbo.AttendanceAlerts;
IF OBJECT_ID('dbo.Attendance', 'U') IS NOT NULL DROP TABLE dbo.Attendance;
IF OBJECT_ID('dbo.ClassSessions', 'U') IS NOT NULL DROP TABLE dbo.ClassSessions;
IF OBJECT_ID('dbo.AttendancePolicies', 'U') IS NOT NULL DROP TABLE dbo.AttendancePolicies;
IF OBJECT_ID('dbo.Grades', 'U') IS NOT NULL DROP TABLE dbo.Grades;
IF OBJECT_ID('dbo.GradeComponents', 'U') IS NOT NULL DROP TABLE dbo.GradeComponents;
IF OBJECT_ID('dbo.Enrollments', 'U') IS NOT NULL DROP TABLE dbo.Enrollments;
IF OBJECT_ID('dbo.CourseOfferings', 'U') IS NOT NULL DROP TABLE dbo.CourseOfferings;
IF OBJECT_ID('dbo.Courses', 'U') IS NOT NULL DROP TABLE dbo.Courses;
IF OBJECT_ID('dbo.Programs', 'U') IS NOT NULL DROP TABLE dbo.Programs;
IF OBJECT_ID('dbo.Departments', 'U') IS NOT NULL DROP TABLE dbo.Departments;
IF OBJECT_ID('dbo.Academics', 'U') IS NOT NULL DROP TABLE dbo.Academics;
IF OBJECT_ID('dbo.Students', 'U') IS NOT NULL DROP TABLE dbo.Students;
IF OBJECT_ID('dbo.AuditLog', 'U') IS NOT NULL DROP TABLE dbo.AuditLog;
IF OBJECT_ID('dbo.Users', 'U') IS NOT NULL DROP TABLE dbo.Users;
IF OBJECT_ID('dbo.Roles', 'U') IS NOT NULL DROP TABLE dbo.Roles;
GO

/* =========================================================
   2. Core lookup tables
   ========================================================= */
CREATE TABLE dbo.Roles
(
    RoleID      INT IDENTITY(1,1) PRIMARY KEY,
    RoleName    NVARCHAR(50) NOT NULL UNIQUE,
    Description NVARCHAR(255) NULL
);
GO

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
GO

CREATE TABLE dbo.Departments
(
    DepartmentID INT IDENTITY(1,1) PRIMARY KEY,
    FacultyName  NVARCHAR(100) NOT NULL,
    DepartmentName NVARCHAR(100) NOT NULL,
    ChairID      INT NULL,
    CONSTRAINT UQ_Departments UNIQUE (FacultyName, DepartmentName),
    CONSTRAINT FK_Departments_Chair FOREIGN KEY (ChairID) REFERENCES dbo.Users(UserID)
);
GO

CREATE TABLE dbo.Programs
(
    ProgramID        INT IDENTITY(1,1) PRIMARY KEY,
    DepartmentID     INT NOT NULL,
    ProgramName      NVARCHAR(150) NOT NULL,
    DegreeLevel      NVARCHAR(50) NOT NULL,
    CreditRequirement INT NOT NULL,
    CONSTRAINT UQ_Programs UNIQUE (DepartmentID, ProgramName),
    CONSTRAINT FK_Programs_Departments FOREIGN KEY (DepartmentID) REFERENCES dbo.Departments(DepartmentID)
);
GO

/* =========================================================
   3. User subtype tables
   ========================================================= */
CREATE TABLE dbo.Students
(
    StudentID     INT PRIMARY KEY,
    StudentNumber NVARCHAR(20) NOT NULL,
    NationalID    NVARCHAR(20) NOT NULL,
    FirstName     NVARCHAR(50) NOT NULL,
    LastName      NVARCHAR(50) NOT NULL,
    BirthDate     DATE NOT NULL,
    Gender        CHAR(1) NULL,
    DepartmentID  INT NOT NULL,
    ProgramID     INT NULL,
    AdvisorID     INT NULL,
    EnrollmentYear SMALLINT NULL,
    CONSTRAINT FK_Students_User FOREIGN KEY (StudentID) REFERENCES dbo.Users(UserID),
    CONSTRAINT FK_Students_Department FOREIGN KEY (DepartmentID) REFERENCES dbo.Departments(DepartmentID),
    CONSTRAINT FK_Students_Program FOREIGN KEY (ProgramID) REFERENCES dbo.Programs(ProgramID),
    CONSTRAINT FK_Students_Advisor FOREIGN KEY (AdvisorID) REFERENCES dbo.Users(UserID),
    CONSTRAINT UQ_Students_StudentNumber UNIQUE (StudentNumber),
    CONSTRAINT UQ_Students_NationalID UNIQUE (NationalID)
);
GO

CREATE TABLE dbo.Academics
(
    AcademicID     INT PRIMARY KEY,
    Title          NVARCHAR(50) NULL,
    DepartmentID   INT NOT NULL,
    Office         NVARCHAR(50) NULL,
    PhoneExtension NVARCHAR(10) NULL,
    CONSTRAINT FK_Academics_User FOREIGN KEY (AcademicID) REFERENCES dbo.Users(UserID),
    CONSTRAINT FK_Academics_Department FOREIGN KEY (DepartmentID) REFERENCES dbo.Departments(DepartmentID)
);
GO

/* =========================================================
   4. Course structures
   ========================================================= */
CREATE TABLE dbo.Courses
(
    CourseID        INT IDENTITY(1,1) PRIMARY KEY,
    CourseCode      NVARCHAR(20) NOT NULL,
    CourseName      NVARCHAR(150) NOT NULL,
    ProgramID       INT NOT NULL,
    Credit          DECIMAL(4,2) NOT NULL,
    ECTS            DECIMAL(4,1) NOT NULL,
    SemesterOffered TINYINT NULL,
    CONSTRAINT UQ_Courses_CourseCode UNIQUE (CourseCode),
    CONSTRAINT FK_Courses_Program FOREIGN KEY (ProgramID) REFERENCES dbo.Programs(ProgramID)
);
GO

CREATE TABLE dbo.CourseOfferings
(
    OfferingID   INT IDENTITY(1,1) PRIMARY KEY,
    CourseID     INT NOT NULL,
    AcademicID   INT NOT NULL,
    Term         NVARCHAR(20) NOT NULL,
    Section      NVARCHAR(5) NOT NULL,
    Capacity     INT NOT NULL,
    ScheduleJSON NVARCHAR(MAX) NULL,
    CreatedAt    DATETIME2 NOT NULL CONSTRAINT DF_CourseOfferings_CreatedAt DEFAULT (SYSUTCDATETIME()),
    CONSTRAINT FK_Offerings_Course FOREIGN KEY (CourseID) REFERENCES dbo.Courses(CourseID),
    CONSTRAINT FK_Offerings_Academic FOREIGN KEY (AcademicID) REFERENCES dbo.Users(UserID),
    CONSTRAINT UQ_Offerings UNIQUE (CourseID, Term, Section)
);
GO

CREATE TABLE dbo.ClassSessions
(
    SessionID   INT IDENTITY(1,1) PRIMARY KEY,
    OfferingID  INT NOT NULL,
    SessionDate DATE NOT NULL,
    StartTime   TIME(0) NOT NULL,
    EndTime     TIME(0) NOT NULL,
    SessionType NVARCHAR(20) NOT NULL,
    Location    NVARCHAR(50) NULL,
    CONSTRAINT FK_ClassSessions_Offering FOREIGN KEY (OfferingID) REFERENCES dbo.CourseOfferings(OfferingID),
    CONSTRAINT UQ_ClassSessions UNIQUE (OfferingID, SessionDate, StartTime)
);
GO

/* =========================================================
   5. Enrollment & grading
   ========================================================= */
CREATE TABLE dbo.Enrollments
(
    EnrollmentID   INT IDENTITY(1,1) PRIMARY KEY,
    OfferingID     INT NOT NULL,
    StudentID      INT NOT NULL,
    EnrollStatus   NVARCHAR(30) NOT NULL CONSTRAINT DF_Enrollments_Status DEFAULT ('Active'),
    EnrolledAt     DATETIME2 NOT NULL CONSTRAINT DF_Enrollments_EnrolledAt DEFAULT (SYSUTCDATETIME()),
    DroppedAt      DATETIME2 NULL,
    CurrentAverage DECIMAL(5,2) NULL,
    LetterGrade    NVARCHAR(5) NULL,
    StatusUpdatedAt DATETIME2 NULL,
    CONSTRAINT FK_Enrollments_Offering FOREIGN KEY (OfferingID) REFERENCES dbo.CourseOfferings(OfferingID),
    CONSTRAINT FK_Enrollments_Student FOREIGN KEY (StudentID) REFERENCES dbo.Users(UserID),
    CONSTRAINT UQ_Enrollments UNIQUE (OfferingID, StudentID)
);
GO

CREATE TABLE dbo.GradeComponents
(
    ComponentID   INT IDENTITY(1,1) PRIMARY KEY,
    OfferingID    INT NOT NULL,
    ComponentName NVARCHAR(50) NOT NULL,
    WeightPercent DECIMAL(5,2) NOT NULL,
    IsMandatory   BIT NOT NULL CONSTRAINT DF_GradeComponents_IsMandatory DEFAULT (1),
    CONSTRAINT FK_GradeComponents_Offering FOREIGN KEY (OfferingID) REFERENCES dbo.CourseOfferings(OfferingID),
    CONSTRAINT UQ_GradeComponents UNIQUE (OfferingID, ComponentName)
);
GO

CREATE TABLE dbo.Grades
(
    GradeID      INT IDENTITY(1,1) PRIMARY KEY,
    EnrollmentID INT NOT NULL,
    ComponentID  INT NOT NULL,
    Score        DECIMAL(5,2) NOT NULL,
    ScoreDate    DATETIME2 NOT NULL CONSTRAINT DF_Grades_ScoreDate DEFAULT (SYSUTCDATETIME()),
    GradedBy     INT NOT NULL,
    Notes        NVARCHAR(255) NULL,
    CONSTRAINT FK_Grades_Enrollment FOREIGN KEY (EnrollmentID) REFERENCES dbo.Enrollments(EnrollmentID),
    CONSTRAINT FK_Grades_Component FOREIGN KEY (ComponentID) REFERENCES dbo.GradeComponents(ComponentID),
    CONSTRAINT FK_Grades_GradedBy FOREIGN KEY (GradedBy) REFERENCES dbo.Users(UserID),
    CONSTRAINT UQ_Grades UNIQUE (EnrollmentID, ComponentID)
);
GO

/* =========================================================
   6. Attendance
   ========================================================= */
CREATE TABLE dbo.AttendancePolicies
(
    PolicyID                 INT IDENTITY(1,1) PRIMARY KEY,
    OfferingID               INT NOT NULL,
    MaxAbsencePercent        DECIMAL(5,2) NOT NULL,
    WarningThresholdPercent  DECIMAL(5,2) NOT NULL,
    AutoFailPercent          DECIMAL(5,2) NOT NULL,
    CreatedAt                DATETIME2 NOT NULL CONSTRAINT DF_AttendancePolicies_CreatedAt DEFAULT (SYSUTCDATETIME()),
    CONSTRAINT FK_AttendancePolicies_Offering FOREIGN KEY (OfferingID) REFERENCES dbo.CourseOfferings(OfferingID),
    CONSTRAINT UQ_AttendancePolicies UNIQUE (OfferingID)
);
GO

CREATE TABLE dbo.Attendance
(
    AttendanceID INT IDENTITY(1,1) PRIMARY KEY,
    SessionID    INT NOT NULL,
    StudentID    INT NOT NULL,
    Status       NVARCHAR(20) NOT NULL,
    RecordedAt   DATETIME2 NOT NULL CONSTRAINT DF_Attendance_RecordedAt DEFAULT (SYSUTCDATETIME()),
    RecordedBy   INT NOT NULL,
    Remarks      NVARCHAR(255) NULL,
    CONSTRAINT FK_Attendance_Session FOREIGN KEY (SessionID) REFERENCES dbo.ClassSessions(SessionID),
    CONSTRAINT FK_Attendance_Student FOREIGN KEY (StudentID) REFERENCES dbo.Users(UserID),
    CONSTRAINT FK_Attendance_Recorder FOREIGN KEY (RecordedBy) REFERENCES dbo.Users(UserID),
    CONSTRAINT UQ_Attendance UNIQUE (SessionID, StudentID)
);
GO

CREATE TABLE dbo.AttendanceAlerts
(
    AlertID      INT IDENTITY(1,1) PRIMARY KEY,
    EnrollmentID INT NOT NULL,
    AlertType    NVARCHAR(30) NOT NULL, -- Warning / AutoFail
    TriggeredAt  DATETIME2 NOT NULL CONSTRAINT DF_AttendanceAlerts_TriggeredAt DEFAULT (SYSUTCDATETIME()),
    CONSTRAINT FK_AttendanceAlerts_Enrollment FOREIGN KEY (EnrollmentID) REFERENCES dbo.Enrollments(EnrollmentID),
    CONSTRAINT UQ_AttendanceAlerts UNIQUE (EnrollmentID, AlertType)
);
GO

/* =========================================================
   7. Notifications & audit
   ========================================================= */
CREATE TABLE dbo.Notifications
(
    NotificationID INT IDENTITY(1,1) PRIMARY KEY,
    UserID         INT NOT NULL,
    Type           NVARCHAR(30) NOT NULL,
    Title          NVARCHAR(150) NOT NULL,
    Message        NVARCHAR(1000) NOT NULL,
    IsRead         BIT NOT NULL CONSTRAINT DF_Notifications_IsRead DEFAULT (0),
    CreatedAt      DATETIME2 NOT NULL CONSTRAINT DF_Notifications_CreatedAt DEFAULT (SYSUTCDATETIME()),
    CONSTRAINT FK_Notifications_User FOREIGN KEY (UserID) REFERENCES dbo.Users(UserID)
);
GO

CREATE TABLE dbo.AuditLog
(
    AuditID        BIGINT IDENTITY(1,1) PRIMARY KEY,
    TableName      NVARCHAR(100) NOT NULL,
    RecordID       NVARCHAR(100) NOT NULL,
    ActionType     NVARCHAR(30) NOT NULL,
    ChangedBy      INT NOT NULL,
    ChangeTimestamp DATETIME2 NOT NULL CONSTRAINT DF_AuditLog_Changed DEFAULT (SYSUTCDATETIME()),
    ChangeDetails  NVARCHAR(MAX) NULL,
    CONSTRAINT FK_AuditLog_User FOREIGN KEY (ChangedBy) REFERENCES dbo.Users(UserID)
);
GO

/* =========================================================
   8. Supporting indexes
   ========================================================= */
CREATE INDEX IX_Users_RoleID ON dbo.Users(RoleID);
CREATE INDEX IX_Students_Department ON dbo.Students(DepartmentID);
CREATE INDEX IX_Academics_Department ON dbo.Academics(DepartmentID);
CREATE INDEX IX_Courses_Program ON dbo.Courses(ProgramID);
CREATE INDEX IX_CourseOfferings_Term ON dbo.CourseOfferings(Term);
CREATE INDEX IX_Enrollments_Student ON dbo.Enrollments(StudentID);
CREATE INDEX IX_Enrollments_Status ON dbo.Enrollments(EnrollStatus);
CREATE INDEX IX_Grades_Component ON dbo.Grades(ComponentID);
CREATE INDEX IX_Attendance_Student ON dbo.Attendance(StudentID);
CREATE INDEX IX_Notifications_User ON dbo.Notifications(UserID, IsRead);
CREATE INDEX IX_AuditLog_Table ON dbo.AuditLog(TableName, ActionType);
GO

