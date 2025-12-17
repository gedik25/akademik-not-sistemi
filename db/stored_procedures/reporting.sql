/*
    db/stored_procedures/reporting.sql
    Dashboard, notifications, and audit reporting procedures.
*/

SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

IF OBJECT_ID('dbo.sp_GetDashboardStats', 'P') IS NOT NULL DROP PROCEDURE dbo.sp_GetDashboardStats;
GO
CREATE PROCEDURE dbo.sp_GetDashboardStats
    @UserID INT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @RoleName NVARCHAR(50);
    SELECT @RoleName = R.RoleName
    FROM dbo.Users U
    INNER JOIN dbo.Roles R ON U.RoleID = R.RoleID
    WHERE U.UserID = @UserID;

    IF @RoleName IS NULL
        THROW 56000, 'Kullanıcı rolü bulunamadı.', 1;

    IF @RoleName = 'Student'
    BEGIN
        -- Öğrenci istatistikleri
        SELECT
            CourseCount = (SELECT COUNT(*) FROM dbo.Enrollments WHERE StudentID = @UserID AND EnrollStatus = 'Active'),
            GPA = ISNULL((SELECT AVG(CurrentAverage) FROM dbo.Enrollments WHERE StudentID = @UserID AND CurrentAverage IS NOT NULL), 0),
            AttendanceRate = ISNULL((SELECT AVG(AttendancePercent) FROM dbo.Enrollments WHERE StudentID = @UserID AND AttendancePercent IS NOT NULL), 0),
            NotificationCount = (SELECT COUNT(*) FROM dbo.Notifications WHERE UserID = @UserID AND IsRead = 0);
    END
    ELSE IF @RoleName = 'Academic'
    BEGIN
        -- Akademisyen istatistikleri
        DECLARE @TodayDOW INT = DATEPART(WEEKDAY, GETDATE());
        
        SELECT
            CourseCount = (SELECT COUNT(*) FROM dbo.CourseOfferings WHERE AcademicID = @UserID),
            StudentCount = (SELECT COUNT(DISTINCT E.StudentID) 
                           FROM dbo.Enrollments E 
                           INNER JOIN dbo.CourseOfferings CO ON E.OfferingID = CO.OfferingID 
                           WHERE CO.AcademicID = @UserID AND E.EnrollStatus = 'Active'),
            PendingGrades = (SELECT COUNT(*) 
                            FROM dbo.Enrollments E 
                            INNER JOIN dbo.CourseOfferings CO ON E.OfferingID = CO.OfferingID 
                            WHERE CO.AcademicID = @UserID 
                            AND E.EnrollStatus = 'Active' 
                            AND E.LetterGrade IS NULL),
            TodayClasses = (SELECT COUNT(DISTINCT CS.SessionID) 
                           FROM dbo.ClassSessions CS 
                           INNER JOIN dbo.CourseOfferings CO ON CS.OfferingID = CO.OfferingID 
                           WHERE CO.AcademicID = @UserID 
                           AND CAST(CS.SessionDate AS DATE) = CAST(GETDATE() AS DATE));
    END
    ELSE
    BEGIN
        -- Admin istatistikleri
        SELECT
            TotalUsers = (SELECT COUNT(*) FROM dbo.Users WHERE IsActive = 1),
            ActiveCourses = (SELECT COUNT(*) FROM dbo.CourseOfferings),
            TotalStudents = (SELECT COUNT(*) FROM dbo.Students),
            TotalAcademics = (SELECT COUNT(*) FROM dbo.Academics);
    END
END;
GO

IF OBJECT_ID('dbo.sp_ListNotifications', 'P') IS NOT NULL DROP PROCEDURE dbo.sp_ListNotifications;
GO
CREATE PROCEDURE dbo.sp_ListNotifications
    @UserID INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        NotificationID,
        Type,
        Title,
        Message,
        IsRead,
        CreatedAt
    FROM dbo.Notifications
    WHERE UserID = @UserID
    ORDER BY CreatedAt DESC;
END;
GO

IF OBJECT_ID('dbo.sp_MarkNotificationRead', 'P') IS NOT NULL DROP PROCEDURE dbo.sp_MarkNotificationRead;
GO
CREATE PROCEDURE dbo.sp_MarkNotificationRead
    @NotificationID INT
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE dbo.Notifications
    SET IsRead = 1
    WHERE NotificationID = @NotificationID;
END;
GO

IF OBJECT_ID('dbo.sp_SearchAuditLog', 'P') IS NOT NULL DROP PROCEDURE dbo.sp_SearchAuditLog;
GO
CREATE PROCEDURE dbo.sp_SearchAuditLog
    @DateFrom DATETIME2 = NULL,
    @DateTo   DATETIME2 = NULL,
    @ActionType NVARCHAR(30) = NULL,
    @TableName  NVARCHAR(100) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        AuditID,
        TableName,
        RecordID,
        ActionType,
        ChangedBy,
        ChangeTimestamp,
        ChangeDetails
    FROM dbo.AuditLog
    WHERE (@DateFrom IS NULL OR ChangeTimestamp >= @DateFrom)
      AND (@DateTo IS NULL OR ChangeTimestamp <= @DateTo)
      AND (@ActionType IS NULL OR ActionType = @ActionType)
      AND (@TableName IS NULL OR TableName = @TableName)
    ORDER BY ChangeTimestamp DESC;
END;
GO

