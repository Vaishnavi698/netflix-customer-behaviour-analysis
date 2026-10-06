import sqlite3
from pathlib import Path
import pandas as pd


# ============================================================
# Configuration
# ============================================================

PROJECT_DIR = Path(__file__).resolve().parent
DB_PATH = PROJECT_DIR / "netflix.db"
OUTPUT_DIR = PROJECT_DIR / "powerbi_data"


# ============================================================
# Create output directory
# ============================================================

OUTPUT_DIR.mkdir(exist_ok=True)


# ============================================================
# Power BI views to export
# ============================================================

VIEWS = {
    "v_user_summary": "user_summary.csv",
    "v_retention_cohorts": "retention_cohorts.csv",
    "v_churn_features": "churn_features.csv",
    "v_experiment_results": "experiment_results.csv",
}


# ============================================================
# Export views
# ============================================================

print("=" * 70)
print("POWER BI DATA EXPORT")
print("=" * 70)

with sqlite3.connect(DB_PATH) as con:

    for view_name, file_name in VIEWS.items():

        df = pd.read_sql_query(
            f"SELECT * FROM {view_name}",
            con
        )

        output_path = OUTPUT_DIR / file_name

        df.to_csv(
            output_path,
            index=False
        )

        print(
            f"{view_name:<25} "
            f"{len(df):>8,} rows  ->  {file_name}"
        )


print("=" * 70)
print("Power BI export completed successfully.")
print(f"Output folder: {OUTPUT_DIR}")
print("=" * 70)