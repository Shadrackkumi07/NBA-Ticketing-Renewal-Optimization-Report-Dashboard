# Setup Guide (End to End)

## Prereqs
- Azure Subscription with permissions to create: Azure SQL Database, Azure Storage (Blob), Azure Data Factory, (optional) Key Vault.
- Power BI Pro (PPU/Premium recommended for Incremental Refresh).
- Local tools: Azure Data Studio or SSMS, Power BI Desktop.

## 1) Azure SQL Database
1. Create Azure SQL Database (General Purpose/Serverless fine).
2. In SSMS/Azure Data Studio, run the SQL scripts in order:
   - `sql/00_create_schema.sql`
   - `sql/01_dims.sql`
   - `sql/02_facts.sql`
   - `sql/03_staging.sql`
   - `sql/04_indexes.sql`
   - `sql/10_sp_loads.sql`
3. (Optional) Create a contained user for ADF and Power BI with read/write as needed.

## 2) Load Synthetic Data (one-time)
Option A: **Bulk load via SQL** using `sql/21_bcp_examples.md` commands (adjust paths).

Option B: **Use ADF**:
1. Upload CSVs from `data/synthetic/` to an Azure Blob container (e.g., `ticketing-sample/`).
2. Import `adf/factory/factory.json` into your Data Factory.
3. Configure linked services:
   - `LS_AzureSqlDB` → point to your Azure SQL DB.
   - `LS_Blob` → your storage account/container.
4. Run pipeline `PL_Load_Synthetic_Once` to land staging data and call stored procs to build dims/facts.

## 3) Power BI
1. Open Power BI Desktop.
2. Connect to Azure SQL DB (Import mode).
3. Create `RangeStart` and `RangeEnd` DateTime parameters.
4. On the ticket and attendance fact queries, filter on `[SaleDate] >= RangeStart and [SaleDate] < RangeEnd` / `[GameDate] ...`
5. Paste measures from `powerbi/measures.dax`.
6. Configure Incremental Refresh (Store=5 years, Refresh=last 60 days; Detect changes column `ModifiedAt`).
7. Configure RLS using `SecurityUserMap` + `USERPRINCIPALNAME()` (see `docs/RLS.md`).

## 4) Forecasting Job (Python)
1. `cd python && pip install -r requirements.txt`
2. Copy `.env.example` → `.env` and set your SQL creds.
3. Run `python forecast_job.py` to write aggregate + per-game forecasts to `dbo.FactForecast`.
4. Refresh Power BI to surface forecast vs actual visuals.

## 5) ADF Daily Automation
1. In Data Factory, enable `Trigger_Daily_0300` to run `PL_Master_Daily`.

## Notes
- You can scale the dataset later by re-running a generator (ping me to add one) if you want 1M+ rows.
- All IDs/keys are consistent across CSVs to preserve referential integrity.