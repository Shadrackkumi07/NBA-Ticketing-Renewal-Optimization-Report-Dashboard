# Row-Level Security (RLS)

**Goal**: Restrict users to see only their sales territory.

## Tables
- `DimSalesTerritory (TerritoryId, TerritoryName, RepId, Region)`
- `SecurityUserMap (UPN, TerritoryId)`

## Power BI Role Filter
```
DimSalesTerritory[TerritoryId] IN
    CALCULATETABLE(VALUES(SecurityUserMap[TerritoryId]),
                   SecurityUserMap[UPN] = USERPRINCIPALNAME())
```