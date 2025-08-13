"""
forecast_job.py  — NBA Ticketing Forecasts (Aggregate + Per-Game)

- Reads history from Azure SQL (FactTicketSales, FactAttendance, DimGame)
- Writes 8-week forecasts to dbo.FactForecast:
    * Aggregate (GameId = 0): Attendance + Revenue (daily series)
    * Per-game (GameId = actual): Attendance + Revenue for future games (1 row per game)

Models:
- Attendance (aggregate): Prophet weekly seasonality if available (>=10 points), else MA28 fallback
- Revenue (aggregate): Moving-average (28-day) + weekend/weekday multiplier (always runs)
- Per-game: rule-based uplift using trailing means + weekend/promo multipliers

Requires:
- .env in this folder with: SQL_SERVER, SQL_DATABASE, SQL_USER, SQL_PASSWORD, SQL_ENCRYPT=yes
- ODBC Driver 17 (or 18) for SQL Server

"""

import os
import pandas as pd
import pyodbc
from datetime import date, timedelta
from dotenv import load_dotenv

# Prophet is optional; we’ll fall back if it’s not available
try:
    from prophet import Prophet
    PROPHET_AVAILABLE = True
except Exception:
    PROPHET_AVAILABLE = False

AGG_HORIZON_DAYS = 56  # 8 weeks


# -----------------------------
# Connection helpers
# -----------------------------
def connect():
    load_dotenv()
    server = os.getenv("SQL_SERVER")
    db = os.getenv("SQL_DATABASE")
    user = os.getenv("SQL_USER")
    pwd = os.getenv("SQL_PASSWORD")
    # Change to {ODBC Driver 18 for SQL Server} if that's what you installed
    conn = pyodbc.connect(
        f"DRIVER={{ODBC Driver 17 for SQL Server}};"
        f"SERVER={server};DATABASE={db};UID={user};PWD={pwd};"
        "Encrypt=yes;TrustServerCertificate=no;"
    )
    return conn


# -----------------------------
# Data fetch
# -----------------------------
def fetch_games(conn):
    sql = """
        SELECT GameId, GameDate, DayType, IsWeekend, PromoFlag
        FROM dbo.DimGame
        ORDER BY GameDate;
    """
    return pd.read_sql(sql, conn, parse_dates=["GameDate"])


def fetch_agg_series(conn):
    # Attendance: use ScannedCount
    sql_att = """
        SELECT g.GameDate, SUM(fa.ScannedCount) AS Attendance
        FROM dbo.DimGame g
        LEFT JOIN dbo.FactAttendance fa ON fa.GameId = g.GameId
        GROUP BY g.GameDate
        ORDER BY g.GameDate;
    """
    # Revenue: persisted computed column on FactTicketSales
    sql_rev = """
        SELECT g.GameDate, SUM(ts.Revenue) AS Revenue
        FROM dbo.DimGame g
        LEFT JOIN dbo.FactTicketSales ts ON ts.GameId = g.GameId
        GROUP BY g.GameDate
        ORDER BY g.GameDate;
    """
    att = pd.read_sql(sql_att, conn, parse_dates=["GameDate"])
    rev = pd.read_sql(sql_rev, conn, parse_dates=["GameDate"])
    df = pd.merge(att, rev, on="GameDate", how="outer").sort_values("GameDate")
    return df


# -----------------------------
# Write helpers
# -----------------------------
def delete_future_forecasts(conn):
    cur = conn.cursor()
    cur.execute("DELETE dbo.FactForecast WHERE ForecastDate >= CAST(SYSDATETIME() AS date);")
    conn.commit()


def upsert_forecasts(conn, rows):
    cur = conn.cursor()
    for r in rows:
        fd = r["ForecastDate"]
        fd = fd.date() if hasattr(fd, "date") else fd
        cur.execute(
            "INSERT INTO dbo.FactForecast (GameId, ForecastDate, Metric, ForecastValue, Model) "
            "VALUES (?,?,?,?,?)",
            int(r["GameId"]),
            fd,
            r["Metric"],
            float(r["ForecastValue"]),
            r.get("Model", ""),
        )
    conn.commit()


# -----------------------------
# Forecasting
# -----------------------------
def forecast_aggregate(df: pd.DataFrame):
    """
    Returns list of dict rows for aggregate (GameId=0) forecasts:
    - Attendance: Prophet weekly model (if available) else MA28 fallback
    - Revenue: MA28 + weekend/weekday multiplier (always runs)
    """
    out = []

    # ---- Attendance: Prophet (preferred) or MA28 fallback
    att = df[["GameDate", "Attendance"]].dropna().copy()
    if not att.empty:
        if PROPHET_AVAILABLE and len(att) >= 10:
            m = Prophet(weekly_seasonality=True, yearly_seasonality=False)
            m.fit(att.rename(columns={"GameDate": "ds", "Attendance": "y"}))
            future = m.make_future_dataframe(periods=AGG_HORIZON_DAYS)
            fc = m.predict(future)[["ds", "yhat"]].tail(AGG_HORIZON_DAYS)
            for _, r in fc.iterrows():
                out.append(
                    {
                        "GameId": 0,
                        "ForecastDate": r["ds"],
                        "Metric": "Attendance",
                        "ForecastValue": r["yhat"],
                        "Model": "Prophet",
                    }
                )
        else:
            # Fallback: moving average + weekend factor
            att_avg = att["Attendance"].rolling(28, min_periods=1).mean().iloc[-1]
            att_weekend = att[att["GameDate"].dt.weekday.isin([5, 6])]["Attendance"].mean()
            att_weekday = att[~att["GameDate"].dt.weekday.isin([5, 6])]["Attendance"].mean()
            weekend_mult_att = (att_weekend / att_avg) if att_avg else 1.05
            weekday_mult_att = (att_weekday / att_avg) if att_avg else 0.95
            start = df["GameDate"].max() + pd.Timedelta(days=1)
            for d in pd.date_range(start, periods=AGG_HORIZON_DAYS, freq="D"):
                mult = weekend_mult_att if d.weekday() in [5, 6] else weekday_mult_att
                out.append(
                    {
                        "GameId": 0,
                        "ForecastDate": d,
                        "Metric": "Attendance",
                        "ForecastValue": att_avg * mult,
                        "Model": "RuleBased-MA28",
                    }
                )

    # ---- Revenue: moving average + weekend/weekday factor (always)
    rev = df[["GameDate", "Revenue"]].dropna().copy()
    if not rev.empty:
        rev_avg = rev["Revenue"].rolling(28, min_periods=1).mean().iloc[-1]
        rev_weekend = rev[rev["GameDate"].dt.weekday.isin([5, 6])]["Revenue"].mean()
        rev_weekday = rev[~rev["GameDate"].dt.weekday.isin([5, 6])]["Revenue"].mean()
        weekend_mult_rev = (rev_weekend / rev_avg) if rev_avg else 1.05
        weekday_mult_rev = (rev_weekday / rev_avg) if rev_avg else 0.95
        start = df["GameDate"].max() + pd.Timedelta(days=1)
        for d in pd.date_range(start, periods=AGG_HORIZON_DAYS, freq="D"):
            mult = weekend_mult_rev if d.weekday() in [5, 6] else weekday_mult_rev
            out.append(
                {
                    "GameId": 0,
                    "ForecastDate": d,
                    "Metric": "Revenue",
                    "ForecastValue": rev_avg * mult,
                    "Model": "RuleBased-MA28",
                }
            )

    return out


def forecast_per_game(games: pd.DataFrame, hist: pd.DataFrame):
    """
    Rule-based per-game forecast using trailing averages + weekend/promo multipliers.
    Writes one row per game per metric (Attendance, Revenue) at the game date.
    """
    out = []
    h = hist.dropna().copy()
    if h.empty or games.empty:
        return out

    # Weekend labels for history
    h["IsWeekend"] = h["GameDate"].dt.weekday.isin([5, 6]).astype(int)

    # Aggregates from history
    att_avg = h["Attendance"].mean() if "Attendance" in h else None
    rev_avg = h["Revenue"].mean() if "Revenue" in h else None

    # Weekend vs weekday means
    att_weekend = h.loc[h["IsWeekend"] == 1, "Attendance"].mean() if "Attendance" in h else None
    att_weekday = h.loc[h["IsWeekend"] == 0, "Attendance"].mean() if "Attendance" in h else None
    rev_weekend = h.loc[h["IsWeekend"] == 1, "Revenue"].mean() if "Revenue" in h else None
    rev_weekday = h.loc[h["IsWeekend"] == 0, "Revenue"].mean() if "Revenue" in h else None

    # Multipliers
    weekend_mult_att = (att_weekend / att_avg) if att_avg and att_avg != 0 else 1.05
    weekday_mult_att = (att_weekday / att_avg) if att_avg and att_avg != 0 else 0.95
    weekend_mult_rev = (rev_weekend / rev_avg) if rev_avg and rev_avg != 0 else 1.05
    weekday_mult_rev = (rev_weekday / rev_avg) if rev_avg and rev_avg != 0 else 0.95

    promo_uplift_att = 1.10
    promo_uplift_rev = 1.08

    # Trailing moving averages as base
    hist_sorted = h.set_index("GameDate").sort_index()
    base_att = hist_sorted["Attendance"].rolling(28, min_periods=7).mean()
    base_rev = hist_sorted["Revenue"].rolling(28, min_periods=7).mean()
    base_att_val = float(base_att.iloc[-1]) if "Attendance" in hist_sorted and not base_att.dropna().empty else (att_avg or 10000.0)
    base_rev_val = float(base_rev.iloc[-1]) if "Revenue" in hist_sorted and not base_rev.dropna().empty else (rev_avg or 300000.0)

    for _, g in games.iterrows():
        if pd.isna(g["GameDate"]):
            continue
        is_weekend = int(g["IsWeekend"])
        att_mult = weekend_mult_att if is_weekend else weekday_mult_att
        rev_mult = weekend_mult_rev if is_weekend else weekday_mult_rev
        if int(g.get("PromoFlag", 0)) == 1:
            att_mult *= promo_uplift_att
            rev_mult *= promo_uplift_rev

        out.append(
            {
                "GameId": int(g["GameId"]),
                "ForecastDate": g["GameDate"],
                "Metric": "Attendance",
                "ForecastValue": base_att_val * att_mult,
                "Model": "RuleBased",
            }
        )
        out.append(
            {
                "GameId": int(g["GameId"]),
                "ForecastDate": g["GameDate"],
                "Metric": "Revenue",
                "ForecastValue": base_rev_val * rev_mult,
                "Model": "RuleBased",
            }
        )

    return out


# -----------------------------
# Main
# -----------------------------
def main():
    with connect() as conn:
        # Pull data
        games = fetch_games(conn)
        hist = fetch_agg_series(conn)

        # Safety: clear future rows so re-runs don't duplicate
        delete_future_forecasts(conn)

        # Aggregate daily forecasts (next 56 days)
        agg_rows = forecast_aggregate(hist)

        # Per-game forecasts for only future games
        future_games = games[games["GameDate"] >= pd.Timestamp(date.today())].copy()
        per_game_rows = forecast_per_game(future_games, hist)

        # Write
        upsert_forecasts(conn, agg_rows + per_game_rows)
        print("Forecast rows written:", len(agg_rows) + len(per_game_rows))


if __name__ == "__main__":
    main()
