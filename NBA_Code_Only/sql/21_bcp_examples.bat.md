# BCP Examples (Windows)

```bat
set SVR=nba-analytics-sql.database.windows.net
set DB=nba-analytics
set U=Shadrackkumi07
set P=Determinati0n@70

bcp dbo.stg_Game in C:\Users\User\Desktop\NBA\NBA_Data_Core\data\synthetic\games.csv -S %SVR% -d %DB% -U %U% -P %P% -c -t , -F 2
bcp dbo.stg_Seat in C:\Users\User\Desktop\NBA\NBA_Data_Core\data\synthetic\seats.csv -S %SVR% -d %DB% -U %U% -P %P% -c -t , -F 2
bcp dbo.stg_Customer in C:\Users\User\Desktop\NBA\NBA_Data_Core\data\synthetic\customers.csv -S %SVR% -d %DB% -U %U% -P %P% -c -t , -F 2
bcp dbo.stg_TicketSales in C:\Users\User\Desktop\NBA\NBA_Data_Core\data\synthetic\tickets.csv -S %SVR% -d %DB% -U %U% -P %P% -c -t , -F 2
bcp dbo.stg_Renewals in C:\Users\User\Desktop\NBA\NBA_Data_Core\data\synthetic\renewals.csv -S %SVR% -d %DB% -U %U% -P %P% -c -t , -F 2
bcp dbo.stg_Attendance in C:\Users\User\Desktop\NBA\NBA_Data_Core\data\synthetic\attendance.csv -S %SVR% -d %DB% -U %U% -P %P% -c -t , -F 2
bcp dbo.stg_Channel in C:\Users\User\Desktop\NBA\NBA_Data_Core\data\synthetic\channels.csv -S %SVR% -d %DB% -U %U% -P %P% -c -t , -F 2
bcp dbo.stg_Plan in C:\Users\User\Desktop\NBA\NBA_Data_Core\data\synthetic\plans.csv -S %SVR% -d %DB% -U %U% -P %P% -c -t , -F 2
bcp dbo.stg_Territory in C:\Users\User\Desktop\NBA\NBA_Data_Core\data\synthetic\territories.csv -S %SVR% -d %DB% -U %U% -P %P% -c -t , -F 2
bcp dbo.stg_SecurityUserMap in C:\Users\User\Desktop\NBA\NBA_Data_Core\data\synthetic\security_user_map.csv -S %SVR% -d %DB% -U %U% -P %P% -c -t , -F 2
```

Then run:

```sql
EXEC dbo.sp_Load_DimGame; EXEC dbo.sp_Load_DimSeat; EXEC dbo.sp_Load_DimCustomer;
EXEC dbo.sp_Load_DimChannel; EXEC dbo.sp_Load_DimPlan; EXEC dbo.sp_Load_DimTerritory;
EXEC dbo.sp_Load_SecurityUserMap; EXEC dbo.sp_Load_FactTicketSales; EXEC dbo.sp_Load_FactAttendance; EXEC dbo.sp_Load_FactRenewals;
```