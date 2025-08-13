# Power BI Model Notes
- Import mode for facts; incremental refresh on `SaleDate` and `GameDate`.
- Detect data changes on `ModifiedAt`.
- RLS: filter `DimSalesTerritory` by `SecurityUserMap` + `USERPRINCIPALNAME()`.