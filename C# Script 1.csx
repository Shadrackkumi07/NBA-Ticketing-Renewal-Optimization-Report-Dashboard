
var tableName = "MyMeasures";   


var measuresTable = Model.Tables.FirstOrDefault(t => t.Name == tableName);
if (measuresTable == null)
{
 
    measuresTable = Model.AddCalculatedTable(tableName, "DATATABLE(\"Dummy\", STRING, {{\"x\"}})");
}


Action<string, string, string> addMeasure = (name, expr, fmt) =>
{
    var m = measuresTable.Measures.FirstOrDefault(mm => mm.Name == name);
    if (m == null) m = measuresTable.AddMeasure(name, expr);
    else m.Expression = expr;

    if (!string.IsNullOrEmpty(fmt))
        m.FormatString = fmt;
};


addMeasure("Revenue", "SUM(FactTicketSales[Revenue])", "$#,0");
addMeasure("Tickets", "COUNTROWS(FactTicketSales)", "#,0");
addMeasure("Avg Ticket Price", "DIVIDE([Revenue],[Tickets])", "$#,0.00");
addMeasure("Fees", "SUM(FactTicketSales[Fees])", "$#,0");
addMeasure("Discounts", "SUM(FactTicketSales[Discount])", "$#,0");
addMeasure("Net Revenue", "[Revenue] - [Discounts] + [Fees]", "$#,0");

addMeasure("Attendance", "SUM(FactAttendance[ScannedCount])", "#,0");
addMeasure("No Shows", "SUM(FactAttendance[NoShowCount])", "#,0");
addMeasure("Attendance Rate", "DIVIDE([Attendance],[Attendance] + [No Shows])", "0.00%");

addMeasure("Renewal Accounts", "DISTINCTCOUNT(FactRenewals[AccountId])", "#,0");
addMeasure("Renewed Accounts", "CALCULATE([Renewal Accounts], FactRenewals[RenewedFlag] = TRUE())", "#,0");
addMeasure("Renewal Rate", "DIVIDE([Renewed Accounts],[Renewal Accounts])", "0.00%");
addMeasure("Renewal Amount", "SUM(FactRenewals[RenewalAmount])", "$#,0");

addMeasure("Revenue LY", "CALCULATE([Revenue], DATEADD(DimDate[Date], -1, YEAR))", "$#,0");
addMeasure("Revenue YoY %", "DIVIDE([Revenue]-[Revenue LY], [Revenue LY])", "0.00%");

addMeasure("Revenue MTD", "TOTALMTD([Revenue], DimDate[Date])", "$#,0");
addMeasure("Revenue MTD LY", "CALCULATE([Revenue MTD], DATEADD(DimDate[Date], -1, YEAR))", "$#,0");
addMeasure("Revenue MTD YoY %", "DIVIDE([Revenue MTD]-[Revenue MTD LY],[Revenue MTD LY])", "0.00%");

addMeasure("Attendance MTD", "TOTALMTD([Attendance], DimDate[Date])", "#,0");

addMeasure("Avg Weeknight Price",
    "CALCULATE([Avg Ticket Price], DimGame[DayType] = \"Weeknight\")",
    "$#,0.00");

addMeasure("Underpriced Weeknight Flag",
    "IF(SELECTEDVALUE(DimGame[DayType]) = \"Weeknight\" && [Avg Ticket Price] < [Avg Weeknight Price] * 0.9, 1, 0)",
    "0");

addMeasure("Forecast Attendance (8wk)",
    "CALCULATE(SUM(FactForecast[ForecastValue]), FactForecast[Metric] = \"Attendance\")",
    "#,0");

addMeasure("Forecast Revenue (8wk)",
    "CALCULATE(SUM(FactForecast[ForecastValue]), FactForecast[Metric] = \"Revenue\")",
    "$#,0");

addMeasure("MAPE Attendance",
    "VAR a = [Attendance] VAR f = [Forecast Attendance (8wk)] RETURN IF(NOT ISBLANK(a) && a <> 0, ABS((a - f) / a), BLANK())",
    "0.00%");

addMeasure("Revenue by Territory",
    "SUMX(VALUES(DimSalesTerritory[TerritoryId]), [Revenue])",
    "$#,0");

addMeasure("New Buyers",
    "CALCULATE(DISTINCTCOUNT(FactTicketSales[CustomerId]), DimDate[Year] = MIN(DimDate[Year]))",
    "#,0");

addMeasure("Multi-Game Buyers",
    "CALCULATE(DISTINCTCOUNT(FactTicketSales[CustomerId]), FILTER(VALUES(FactTicketSales[CustomerId]), CALCULATE([Tickets]) > 2))",
    "#,0");

addMeasure("Plan Buyers",
    "CALCULATE(DISTINCTCOUNT(FactRenewals[AccountId]), NOT ISBLANK(FactRenewals[PlanId]))",
    "#,0");


var dummy = measuresTable.Columns.FirstOrDefault(c => c.Name == "Dummy");
if (dummy != null) dummy.Delete();


measuresTable.IsHidden = false; 

