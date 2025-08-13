CREATE INDEX IX_FactTicketSales_Game_SaleDate ON dbo.FactTicketSales(GameId, SaleDate) INCLUDE (Revenue, PricePaid, Discount);
CREATE INDEX IX_FactAttendance_Game ON dbo.FactAttendance(GameId);
CREATE INDEX IX_FactRenewals_Account ON dbo.FactRenewals(AccountId, Season);
CREATE INDEX IX_FactTicketSales_ModifiedAt ON dbo.FactTicketSales(ModifiedAt);
CREATE INDEX IX_FactAttendance_ModifiedAt ON dbo.FactAttendance(ModifiedAt);