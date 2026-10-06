import sqlite3
from pathlib import Path

DB_PATH = Path("netflix.db")
SQL_PATH = Path("sql/00_data_quality.sql")

with sqlite3.connect(DB_PATH) as conn:
    cursor = conn.cursor()

    sql = SQL_PATH.read_text(encoding="utf-8")

    statements = [
        statement.strip()
        for statement in sql.split(";")
        if statement.strip()
    ]

    for i, statement in enumerate(statements, start=1):
        # Skip comment-only sections
        cleaned = "\n".join(
            line for line in statement.splitlines()
            if not line.strip().startswith("--")
        ).strip()

        if not cleaned:
            continue

        try:
            result = cursor.execute(cleaned).fetchall()

            print(f"\n{'=' * 70}")
            print(f"CHECK {i}")
            print(cleaned[:200])
            print("-" * 70)

            for row in result:
                print(row)

        except Exception as e:
            print(f"\nERROR in CHECK {i}: {e}")

print("\nData quality checks completed.")