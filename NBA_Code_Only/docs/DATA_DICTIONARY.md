# Data Dictionary (Key Tables)

## Dimensions
- **DimDate**(DateKey, Date, Year, Month, Day, DayName, IsWeekend, IsHoliday)
- **DimGame**(GameId, Season, Opponent, GameDate, DayType, IsWeekend, PromoFlag)
- **DimCustomer**(CustomerId, AccountId, Segment, Tenure, Zip, IncomeBand)
- **DimSeat**(SeatId, Section, Row, Seat, Zone, PriceTier)
- **DimSalesTerritory**(TerritoryId, TerritoryName, RepId, Region)
- **DimChannel**(SalesChannelId, ChannelName)
- **DimPlan**(PlanId, PlanType, GameCount, PriceTier)

## Facts
- **FactTicketSales**(...)
- **FactRenewals**(...)
- **FactAttendance**(...)
- **FactForecast**(...)

## Security
- **SecurityUserMap**(UPN, TerritoryId)