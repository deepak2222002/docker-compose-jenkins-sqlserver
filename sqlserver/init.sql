IF DB_ID('jobportal') IS NULL
BEGIN
    CREATE DATABASE jobportal;
END
GO

USE jobportal;
GO

IF NOT EXISTS (
    SELECT 1
    FROM sys.database_principals
    WHERE name = N'$(DB_USERNAME)'
)
BEGIN
    CREATE USER [$(DB_USERNAME)] FOR LOGIN [$(DB_USERNAME)];
END
GO

IF NOT EXISTS (
    SELECT 1
    FROM sys.database_role_members drm
    JOIN sys.database_principals r
      ON drm.role_principal_id = r.principal_id
    JOIN sys.database_principals m
      ON drm.member_principal_id = m.principal_id
    WHERE r.name = 'db_owner'
      AND m.name = N'$(DB_USERNAME)'
)
BEGIN
    ALTER ROLE db_owner ADD MEMBER [$(DB_USERNAME)];
END
GO
