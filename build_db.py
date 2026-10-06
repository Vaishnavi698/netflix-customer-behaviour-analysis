import sqlite3
from pathlib import Path

import pandas as pd

# Project folders
PROJECT_DIR = Path(__file__).resolve().parent
DATA_DIR = PROJECT_DIR / "data"
DB_PATH = PROJECT_DIR / "netflix.db"

# Load CSV files into SQLite
with sqlite3.connect(DB_PATH) as con:

    for csv_file in sorted(DATA_DIR.glob("*.csv")):
        df = pd.read_csv(csv_file)

        table_name = csv_file.stem

        df.to_sql(
            table_name,
            con,
            if_exists="replace",
            index=False
        )

        print(f"{table_name}: {len(df):,} rows loaded")

    # Verify tables
    tables = pd.read_sql_query(
        """
        SELECT name
        FROM sqlite_master
        WHERE type = 'table'
        ORDER BY name;
        """,
        con
    )

    print("\nTables in database:")
    print(tables.to_string(index=False))

print("\nDatabase build complete.")