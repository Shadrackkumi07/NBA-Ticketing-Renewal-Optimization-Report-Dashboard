IF OBJECT_ID('dbo.FactTicketSales') IS NULL
CREATE TABLE dbo.FactTicketSales (
    TicketId BIGINT PRIMARY KEY,
    SeatId BIGINT NOT NULL,
    GameId INT NOT NULL,
    CustomerId BIGINT NOT NULL,
    SalesChannelId INT NULL,
    PricePaid DECIMAL(18,2),
    Discount DECIMAL(18,2),
    SaleDate DATETIME2,
    Revenue AS (ISNULL(PricePaid,0) - ISNULL(Discount,0)) PERSISTED,
    Fees DECIMAL(18,2) NULL,
    IsRenewal BIT DEFAULT 0,
    OrderId BIGINT NULL,
    ModifiedAt DATETIME2 DEFAULT SYSUTCDATETIME()
);

IF OBJECT_ID('dbo.FactRenewals') IS NULL
CREATE TABLE dbo.FactRenewals (
    RenewalId BIGINT IDENTITY(1,1) PRIMARY KEY,
    CustomerId BIGINT NOT NULL,
    AccountId BIGINT NOT NULL,
    PlanId INT NULL,
    Season NVARCHAR(20),
    PriorSpend DECIMAL(18,2),
    RenewedFlag BIT,
    RenewalDate DATE,
    RenewalAmount DECIMAL(18,2),
    ModifiedAt DATETIME2 DEFAULT SYSUTCDATETIME()
);

IF OBJECT_ID('dbo.FactAttendance') IS NULL
CREATE TABLE dbo.FactAttendance (
    AttendanceId BIGINT IDENTITY(1,1) PRIMARY KEY,
    GameId INT NOT NULL,
    ScannedCount INT,
    NoShowCount INT,
    GateOpenTime DATETIME2,
    ModifiedAt DATETIME2 DEFAULT SYSUTCDATETIME()
);

IF OBJECT_ID('dbo.FactForecast') IS NULL
CREATE TABLE dbo.FactForecast (
    ForecastId BIGINT IDENTITY(1,1) PRIMARY KEY,
    GameId INT NOT NULL,
    ForecastDate DATE NOT NULL,
    Metric NVARCHAR(50) NOT NULL,
    ForecastValue DECIMAL(18,2) NOT NULL,
    Model NVARCHAR(50),
    CreatedAt DATETIME2 DEFAULT SYSUTCDATETIME()
);