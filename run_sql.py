import sqlite3
import sys
from pathlib import Path
import pandas as pd


PROJECT_DIR = Path(__file__).resolve().parent
DB_PATH = PROJECT_DIR / "netflix.db"
SQL_DIR = PROJECT_DIR / "sql"


# ============================================================
# 1. Choose SQL file
# ============================================================

if len(sys.argv) < 2:
    print("Usage:")
    print("  python run_sql.py 10")
    print("  python run_sql.py 12")
    print("  python run_sql.py 12_experiment_analysis")
    sys.exit(1)


file_input = sys.argv[1]


if file_input.endswith(".sql"):
    file_name = file_input

elif file_input.isdigit():
    matches = list(SQL_DIR.glob(f"{file_input}_*.sql"))

    if not matches:
        print(f"No SQL file found starting with: {file_input}_")
        sys.exit(1)

    if len(matches) > 1:
        print("Multiple SQL files found:")
        for match in matches:
            print(f"  {match.name}")
        sys.exit(1)

    file_name = matches[0].name

else:
    file_name = f"{file_input}.sql"


SQL_PATH = SQL_DIR / file_name


# ============================================================
# 2. Check SQL file
# ============================================================

if not SQL_PATH.exists():
    print(f"SQL file not found: {SQL_PATH}")
    sys.exit(1)


print()
print(f"Running: {SQL_PATH.name}")
print("=" * 70)


# ============================================================
# 3. Read SQL file
# ============================================================

sql = SQL_PATH.read_text(encoding="utf-8")


# ============================================================
# 4. Split SQL into individual statements
# ============================================================

statements = [
    statement.strip()
    for statement in sql.split(";")
    if statement.strip()
]


# ============================================================
# ============================================================
# 5. Execute statements
# ============================================================

with sqlite3.connect(DB_PATH) as con:

    for i, statement in enumerate(statements, start=1):

        print()
        print("=" * 70)
        print(f"RESULT {i}")
        print("=" * 70)

        try:

            # Remove leading SQL comments before checking statement type
            clean_statement = statement

            while clean_statement.lstrip().startswith("--"):
                lines = clean_statement.splitlines()

                remaining_lines = []

                for line in lines:
                    if not line.lstrip().startswith("--"):
                        remaining_lines.append(line)

                clean_statement = "\n".join(remaining_lines).strip()

            # Execute queries that return results
            if clean_statement.upper().startswith(
                ("SELECT", "WITH", "PRAGMA")
            ):

                result = pd.read_sql_query(clean_statement, con)

                if result.empty:
                    print("No rows returned.")
                else:
                    print(result.to_string(index=False))

            else:
                con.execute(clean_statement)
                print("Statement executed successfully.")

        except Exception as e:

            print()
            print("SQL execution failed.")
            print(f"Statement #{i}")
            print("-" * 70)
            print(e)
            print()
            print("SQL statement:")
            print(clean_statement)

            sys.exit(1)


print()
print("=" * 70)
print("SQL file completed successfully.")
print("=" * 70)