"""
Builds a SQLite database from the raw flight CSV so the SQL analysis in this
repo can be run with no external database server. SQLite ships with Python,
so this works out of the box on any machine.

Usage:
    python create_database.py
"""

import sqlite3
from pathlib import Path
import pandas as pd

BASE_DIR = Path(r"C:\Users\Administrator\Desktop\GitHub Repository\Airline Route Profitability")
DB_PATH = BASE_DIR / "airline.db"

csv_candidates = [
    p for p in BASE_DIR.rglob("*.csv")
    if any(k in p.name.lower() for k in ("airline", "route", "profitab"))
]
if not csv_candidates:
    raise FileNotFoundError(f"No matching CSV found under {BASE_DIR}")
DATA_PATH = csv_candidates[0]
print(f"Loading data from: {DATA_PATH}")

df = pd.read_csv(DATA_PATH)
df["Flight_Date"] = pd.to_datetime(df["Flight_Date"]).dt.strftime("%Y-%m-%d")

conn = sqlite3.connect(DB_PATH)
df.to_sql("flights", conn, if_exists="replace", index=False)

conn.execute("CREATE INDEX IF NOT EXISTS idx_route ON flights(Route)")
conn.execute("CREATE INDEX IF NOT EXISTS idx_date ON flights(Flight_Date)")
conn.execute("CREATE INDEX IF NOT EXISTS idx_aircraft ON flights(Aircraft_Type)")
conn.commit()

row_count = conn.execute("SELECT COUNT(*) FROM flights").fetchone()[0]
print(f"Database created at: {DB_PATH}")
print(f"Rows loaded into 'flights' table: {row_count}")

conn.close()
