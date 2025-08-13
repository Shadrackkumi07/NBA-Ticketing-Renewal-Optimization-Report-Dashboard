IF OBJECT_ID('dbo.DimDate') IS NULL
CREATE TABLE dbo.DimDate (
    DateKey INT PRIMARY KEY,
    [Date] DATE NOT NULL,
    [Year] INT, Quarter INT, [Month] INT, [Day] INT,
    DayName NVARCHAR(20), IsWeekend BIT, IsHoliday BIT DEFAULT 0
);

IF OBJECT_ID('dbo.DimGame') IS NULL
CREATE TABLE dbo.DimGame (
    GameId INT PRIMARY KEY,
    Season NVARCHAR(20),
    Opponent NVARCHAR(100),
    GameDate DATE,
    DayType NVARCHAR(20),
    IsWeekend BIT,
    PromoFlag BIT DEFAULT 0
);

IF OBJECT_ID('dbo.DimCustomer') IS NULL
CREATE TABLE dbo.DimCustomer (
    CustomerId BIGINT PRIMARY KEY,
    AccountId BIGINT,
    Segment NVARCHAR(50),
    Tenure INT,
    Zip NVARCHAR(10),
    IncomeBand NVARCHAR(50)
);

IF OBJECT_ID('dbo.DimSeat') IS NULL
CREATE TABLE dbo.DimSeat (
    SeatId BIGINT PRIMARY KEY,
    Section NVARCHAR(50),
    [Row] NVARCHAR(10),
    Seat NVARCHAR(10),
    Zone NVARCHAR(50),
    PriceTier NVARCHAR(50)
);

IF OBJECT_ID('dbo.DimSalesTerritory') IS NULL
CREATE TABLE dbo.DimSalesTerritory (
    TerritoryId INT PRIMARY KEY,
    TerritoryName NVARCHAR(100),
    RepId INT,
    Region NVARCHAR(100)
);

IF OBJECT_ID('dbo.DimChannel') IS NULL
CREATE TABLE dbo.DimChannel (
    SalesChannelId INT PRIMARY KEY,
    ChannelName NVARCHAR(50)
);

IF OBJECT_ID('dbo.DimPlan') IS NULL
CREATE TABLE dbo.DimPlan (
    PlanId INT PRIMARY KEY,
    PlanType NVARCHAR(50),
    GameCount INT,
    PriceTier NVARCHAR(50)
);

IF OBJECT_ID('dbo.SecurityUserMap') IS NULL
CREATE TABLE dbo.SecurityUserMap (
    UPN NVARCHAR(255) NOT NULL,
    TerritoryId INT NOT NULL
);