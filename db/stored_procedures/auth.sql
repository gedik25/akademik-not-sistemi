/*
    db/stored_procedures/auth.sql
    Contains authentication and generic user management procedures.
*/

SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

IF OBJECT_ID('dbo.sp_LoginUser', 'P') IS NOT NULL DROP PROCEDURE dbo.sp_LoginUser;
GO
CREATE PROCEDURE dbo.sp_LoginUser
    @Username       NVARCHAR(50),
    @PasswordPlain  NVARCHAR(255)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE
        @UserID INT,
        @RoleID INT,
        @RoleName NVARCHAR(50),
        @Salt VARBINARY(128),
        @StoredHash VARBINARY(256),
        @ComputedHash VARBINARY(256);

    SELECT
        @UserID = U.UserID,
        @RoleID = U.RoleID,
        @Salt = U.PasswordSalt,
        @StoredHash = U.PasswordHash,
        @RoleName = R.RoleName
    FROM dbo.Users U
    INNER JOIN dbo.Roles R ON U.RoleID = R.RoleID
    WHERE U.Username = @Username
      AND U.IsActive = 1;

    IF @UserID IS NULL
    BEGIN
        THROW 52000, 'Kullanıcı bulunamadı veya pasif.', 1;
    END;

    SET @ComputedHash = HASHBYTES('SHA2_512', @Salt + CONVERT(VARBINARY(512), @PasswordPlain));

    IF @ComputedHash <> @StoredHash
    BEGIN
        THROW 52001, 'Şifre hatalı.', 1;
    END;

    UPDATE dbo.Users
    SET LastLoginAt = SYSUTCDATETIME()
    WHERE UserID = @UserID;

    SELECT
        U.UserID,
        U.Username,
        U.Email,
        U.RoleID,
        @RoleName AS RoleName,
        U.IsActive,
        U.LastLoginAt
    FROM dbo.Users U
    WHERE U.UserID = @UserID;
END;
GO

IF OBJECT_ID('dbo.sp_CreateUser', 'P') IS NOT NULL DROP PROCEDURE dbo.sp_CreateUser;
GO
CREATE PROCEDURE dbo.sp_CreateUser
    @RoleName      NVARCHAR(50),
    @Username      NVARCHAR(50),
    @PasswordPlain NVARCHAR(255),
    @Email         NVARCHAR(255),
    @Phone         NVARCHAR(20) = NULL,
    @NewUserID     INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE
        @RoleID INT,
        @Salt VARBINARY(128),
        @Hash VARBINARY(256);

    SELECT @RoleID = RoleID FROM dbo.Roles WHERE RoleName = @RoleName;
    IF @RoleID IS NULL
        THROW 52002, 'Geçersiz rol adı.', 1;

    SET @Salt = CRYPT_GEN_RANDOM(32);
    SET @Hash = HASHBYTES('SHA2_512', @Salt + CONVERT(VARBINARY(512), @PasswordPlain));

    BEGIN TRY
        BEGIN TRAN;

        INSERT INTO dbo.Users (RoleID, Username, PasswordHash, PasswordSalt, Email, Phone)
        VALUES (@RoleID, @Username, @Hash, @Salt, @Email, @Phone);

        SET @NewUserID = SCOPE_IDENTITY();

        COMMIT TRAN;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRAN;
        THROW;
    END CATCH;
END;
GO

IF OBJECT_ID('dbo.sp_UpdateUserContact', 'P') IS NOT NULL DROP PROCEDURE dbo.sp_UpdateUserContact;
GO
CREATE PROCEDURE dbo.sp_UpdateUserContact
    @UserID INT,
    @Email  NVARCHAR(255),
    @Phone  NVARCHAR(20) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE dbo.Users
    SET Email = @Email,
        Phone = @Phone
    WHERE UserID = @UserID;

    IF @@ROWCOUNT = 0
        THROW 52003, 'Güncellenecek kullanıcı bulunamadı.', 1;
END;
GO

IF OBJECT_ID('dbo.sp_DeactivateUser', 'P') IS NOT NULL DROP PROCEDURE dbo.sp_DeactivateUser;
GO
CREATE PROCEDURE dbo.sp_DeactivateUser
    @UserID INT,
    @Reason NVARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        BEGIN TRAN;

        UPDATE dbo.Users
        SET IsActive = 0
        WHERE UserID = @UserID;

        IF @@ROWCOUNT = 0
            THROW 52004, 'Pasifleştirilecek kullanıcı bulunamadı.', 1;

        INSERT INTO dbo.Notifications (UserID, Type, Title, Message)
        VALUES (@UserID, 'Account', 'Hesap Pasifleştirildi', ISNULL(@Reason, 'Yönetici tarafından pasifleştirildiniz.'));

        INSERT INTO dbo.AuditLog (TableName, RecordID, ActionType, ChangedBy, ChangeDetails)
        VALUES ('Users', CAST(@UserID AS NVARCHAR(100)), 'Deactivate', @UserID, @Reason);

        COMMIT TRAN;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRAN;
        THROW;
    END CATCH;
END;
GO

