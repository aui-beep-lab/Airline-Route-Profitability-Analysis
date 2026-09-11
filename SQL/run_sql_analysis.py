"""
Runs every query in queries.sql against airline.db and saves each result set
as a CSV in outputs/sql_results. Prints a short preview of each query as it runs.

Usage:
    python run_sql_analysis.py
"""

import sqlite3
import re
from pathlib import Path
import pandas as pd

BASE_DIR = Path(r"C:\Users\Administrator\Desktop\GitHub Repository\Airline Route Profitability")
DB_PATH = BASE_DIR / "airline.db"
SQL_PATH = BASE_DIR / "sql" / "queries.sql"
OUT_DIR = BASE_DIR / "outputs" / "sql_results"
OUT_DIR.mkdir(parents=True, exist_ok=True)

if not DB_PATH.exists():
    raise FileNotFoundError(
        f"Database not found at {DB_PATH}. Run create_database.py first."
    )
if not SQL_PATH.exists():
    raise FileNotFoundError(f"queries.sql not found at {SQL_PATH}")

conn = sqlite3.connect(DB_PATH)
sql_text = SQL_PATH.read_text(encoding="utf-8")

# Split into individual statements on semicolons that end a line, skipping
# comment only lines used as section headers.
raw_statements = [s.strip() for s in sql_text.split(";") if s.strip()]

result_index = 0
for stmt in raw_statements:
    # Skip pure comment blocks with no actual SQL keyword
    body = re.sub(r"--.*", "", stmt).strip()
    if not body:
        continue

    label_match = re.search(r"--\s*(\d+\.\d+.*)", stmt)
    label = label_match.group(1).strip() if label_match else body.split("\n")[0][:60]

    try:
        if body.upper().startswith(("CREATE VIEW", "DROP VIEW", "CREATE INDEX", "DROP INDEX")):
            conn.execute(stmt)
            conn.commit()
            print(f"Executed: {label}")
            continue

        df = pd.read_sql_query(stmt, conn)
        result_index += 1
        safe_name = re.sub(r"[^a-zA-Z0-9]+", "_", label).strip("_").lower()[:60]
        out_path = OUT_DIR / f"{result_index:02d}_{safe_name}.csv"
        df.to_csv(out_path, index=False)
        print(f"[{result_index:02d}] {label}  ->  {len(df)} rows saved to {out_path.name}")
    except Exception as e:
        print(f"Skipped a statement due to error: {e}")

conn.close()
print("\nAll queries executed. Results saved in outputs/sql_results/")
