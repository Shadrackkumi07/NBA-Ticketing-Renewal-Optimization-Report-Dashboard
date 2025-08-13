IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'dbo') EXEC('CREATE SCHEMA dbo');
GO
IF OBJECT_ID('dbo.ETL_RunLog') IS NULL
BEGIN
    CREATE TABLE dbo.ETL_RunLog (
        RunId INT IDENTITY(1,1) PRIMARY KEY,
        Pipeline NVARCHAR(200),
        Status NVARCHAR(50),
        StartedAt DATETIME2 DEFAULT SYSUTCDATETIME(),
        EndedAt DATETIME2 NULL,
        Message NVARCHAR(MAX) NULL
    );
END
GO