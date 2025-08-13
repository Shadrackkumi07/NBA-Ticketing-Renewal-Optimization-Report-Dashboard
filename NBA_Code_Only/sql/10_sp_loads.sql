IF OBJECT_ID('dbo.sp_Load_DimGame') IS NOT NULL DROP PROCEDURE dbo.sp_Load_DimGame;
GO
CREATE PROCEDURE dbo.sp_Load_DimGame AS
BEGIN
    SET NOCOUNT ON;
    MERGE dbo.DimGame AS tgt
    USING (
        SELECT DISTINCT GameId, Season, Opponent, GameDate,
               CASE WHEN DATENAME(weekday, GameDate) IN ('Saturday','Sunday') THEN 1 ELSE 0 END AS IsWeekend,
               CASE WHEN DATENAME(weekday, GameDate) IN ('Monday','Tuesday','Wednesday','Thursday') THEN 'Weeknight' ELSE 'Other' END AS DayType,
               ISNULL(PromoFlag,0) AS PromoFlag
        FROM dbo.stg_Game
    ) AS src
    ON tgt.GameId = src.GameId
    WHEN MATCHED THEN UPDATE SET Season=src.Season, Opponent=src.Opponent, GameDate=src.GameDate, DayType=src.DayType, IsWeekend=src.IsWeekend, PromoFlag=src.PromoFlag
    WHEN NOT MATCHED THEN INSERT (GameId, Season, Opponent, GameDate, DayType, IsWeekend, PromoFlag)
    VALUES (src.GameId, src.Season, src.Opponent, src.GameDate, src.DayType, src.IsWeekend, src.PromoFlag);
END
GO

IF OBJECT_ID('dbo.sp_Load_DimSeat') IS NOT NULL DROP PROCEDURE dbo.sp_Load_DimSeat;
GO
CREATE PROCEDURE dbo.sp_Load_DimSeat AS
BEGIN
    SET NOCOUNT ON;
    MERGE dbo.DimSeat AS tgt
    USING (SELECT DISTINCT SeatId, Section, [Row], Seat, Zone, PriceTier FROM dbo.stg_Seat) AS src
    ON tgt.SeatId = src.SeatId
    WHEN MATCHED THEN UPDATE SET Section=src.Section, [Row]=src.[Row], Seat=src.Seat, Zone=src.Zone, PriceTier=src.PriceTier
    WHEN NOT MATCHED THEN INSERT (SeatId, Section, [Row], Seat, Zone, PriceTier) VALUES (src.SeatId, src.Section, src.[Row], src.Seat, src.Zone, src.PriceTier);
END
GO

IF OBJECT_ID('dbo.sp_Load_DimCustomer') IS NOT NULL DROP PROCEDURE dbo.sp_Load_DimCustomer;
GO
CREATE PROCEDURE dbo.sp_Load_DimCustomer AS
BEGIN
    SET NOCOUNT ON;
    MERGE dbo.DimCustomer AS tgt
    USING (SELECT DISTINCT CustomerId, AccountId, Segment, Tenure, Zip, IncomeBand FROM dbo.stg_Customer) AS src
    ON tgt.CustomerId = src.CustomerId
    WHEN MATCHED THEN UPDATE SET AccountId=src.AccountId, Segment=src.Segment, Tenure=src.Tenure, Zip=src.Zip, IncomeBand=src.IncomeBand
    WHEN NOT MATCHED THEN INSERT (CustomerId, AccountId, Segment, Tenure, Zip, IncomeBand) VALUES (src.CustomerId, src.AccountId, src.Segment, src.Tenure, src.Zip, src.IncomeBand);
END
GO

IF OBJECT_ID('dbo.sp_Load_DimChannel') IS NOT NULL DROP PROCEDURE dbo.sp_Load_DimChannel;
GO
CREATE PROCEDURE dbo.sp_Load_DimChannel AS
BEGIN
    SET NOCOUNT ON;
    MERGE dbo.DimChannel AS tgt
    USING (SELECT DISTINCT SalesChannelId, ChannelName FROM dbo.stg_Channel) AS src
    ON tgt.SalesChannelId = src.SalesChannelId
    WHEN MATCHED THEN UPDATE SET ChannelName=src.ChannelName
    WHEN NOT MATCHED THEN INSERT (SalesChannelId, ChannelName) VALUES (src.SalesChannelId, src.ChannelName);
END
GO

IF OBJECT_ID('dbo.sp_Load_DimPlan') IS NOT NULL DROP PROCEDURE dbo.sp_Load_DimPlan;
GO
CREATE PROCEDURE dbo.sp_Load_DimPlan AS
BEGIN
    SET NOCOUNT ON;
    MERGE dbo.DimPlan AS tgt
    USING (SELECT DISTINCT PlanId, PlanType, GameCount, PriceTier FROM dbo.stg_Plan) AS src
    ON tgt.PlanId = src.PlanId
    WHEN MATCHED THEN UPDATE SET PlanType=src.PlanType, GameCount=src.GameCount, PriceTier=src.PriceTier
    WHEN NOT MATCHED THEN INSERT (PlanId, PlanType, GameCount, PriceTier) VALUES (src.PlanId, src.PlanType, src.GameCount, src.PriceTier);
END
GO

IF OBJECT_ID('dbo.sp_Load_DimTerritory') IS NOT NULL DROP PROCEDURE dbo.sp_Load_DimTerritory;
GO
CREATE PROCEDURE dbo.sp_Load_DimTerritory AS
BEGIN
    SET NOCOUNT ON;
    MERGE dbo.DimSalesTerritory AS tgt
    USING (SELECT DISTINCT TerritoryId, TerritoryName, RepId, Region FROM dbo.stg_Territory) AS src
    ON tgt.TerritoryId = src.TerritoryId
    WHEN MATCHED THEN UPDATE SET TerritoryName=src.TerritoryName, RepId=src.RepId, Region=src.Region
    WHEN NOT MATCHED THEN INSERT (TerritoryId, TerritoryName, RepId, Region) VALUES (src.TerritoryId, src.TerritoryName, src.RepId, src.Region);
END
GO

IF OBJECT_ID('dbo.sp_Load_SecurityUserMap') IS NOT NULL DROP PROCEDURE dbo.sp_Load_SecurityUserMap;
GO
CREATE PROCEDURE dbo.sp_Load_SecurityUserMap AS
BEGIN
    SET NOCOUNT ON;
    DELETE FROM dbo.SecurityUserMap;
    INSERT INTO dbo.SecurityUserMap(UPN, TerritoryId)
    SELECT UPN, TerritoryId FROM dbo.stg_SecurityUserMap;
END
GO

IF OBJECT_ID('dbo.sp_Load_FactAttendance') IS NOT NULL DROP PROCEDURE dbo.sp_Load_FactAttendance;
GO
CREATE PROCEDURE dbo.sp_Load_FactAttendance AS
BEGIN
    SET NOCOUNT ON;
    MERGE dbo.FactAttendance AS tgt
    USING (SELECT GameId, ScannedCount, NoShowCount, GateOpenTime FROM dbo.stg_Attendance) AS src
    ON tgt.GameId = src.GameId
    WHEN MATCHED THEN UPDATE SET ScannedCount=src.ScannedCount, NoShowCount=src.NoShowCount, GateOpenTime=src.GateOpenTime, ModifiedAt=SYSUTCDATETIME()
    WHEN NOT MATCHED THEN INSERT (GameId, ScannedCount, NoShowCount, GateOpenTime) VALUES (src.GameId, src.ScannedCount, src.NoShowCount, src.GateOpenTime);
END
GO

IF OBJECT_ID('dbo.sp_Load_FactTicketSales') IS NOT NULL DROP PROCEDURE dbo.sp_Load_FactTicketSales;
GO
CREATE PROCEDURE dbo.sp_Load_FactTicketSales AS
BEGIN
    SET NOCOUNT ON;
    MERGE dbo.FactTicketSales AS tgt
    USING (
        SELECT TicketId, SeatId, GameId, CustomerId, SalesChannelId, PricePaid, Discount, SaleDate, Fees, IsRenewal, OrderId
        FROM dbo.stg_TicketSales
    ) AS src
    ON tgt.TicketId = src.TicketId
    WHEN MATCHED THEN UPDATE SET SeatId=src.SeatId, GameId=src.GameId, CustomerId=src.CustomerId, SalesChannelId=src.SalesChannelId,
                                   PricePaid=src.PricePaid, Discount=src.Discount, SaleDate=src.SaleDate, Fees=src.Fees, IsRenewal=src.IsRenewal, OrderId=src.OrderId, ModifiedAt=SYSUTCDATETIME()
    WHEN NOT MATCHED THEN INSERT (TicketId, SeatId, GameId, CustomerId, SalesChannelId, PricePaid, Discount, SaleDate, Fees, IsRenewal, OrderId)
    VALUES (src.TicketId, src.SeatId, src.GameId, src.CustomerId, src.SalesChannelId, src.PricePaid, src.Discount, src.SaleDate, src.Fees, src.IsRenewal, src.OrderId);
END
GO

IF OBJECT_ID('dbo.sp_Load_FactRenewals') IS NOT NULL DROP PROCEDURE dbo.sp_Load_FactRenewals;
GO
CREATE PROCEDURE dbo.sp_Load_FactRenewals AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO dbo.FactRenewals (CustomerId, AccountId, PlanId, Season, PriorSpend, RenewedFlag, RenewalDate, RenewalAmount)
    SELECT r.CustomerId, r.AccountId, r.PlanId, r.Season, r.PriorSpend, r.RenewedFlag, r.RenewalDate, r.RenewalAmount
    FROM dbo.stg_Renewals r
    WHERE NOT EXISTS (SELECT 1 FROM dbo.FactRenewals fr WHERE fr.CustomerId=r.CustomerId AND fr.Season=r.Season AND fr.RenewalDate=r.RenewalDate);
END
GO