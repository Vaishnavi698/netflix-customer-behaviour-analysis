from pathlib import Path
import pandas as pd

PROJECT_DIR = Path(__file__).resolve().parent
DATA_DIR = PROJECT_DIR / "data"

sessions_path = DATA_DIR / "sessions.csv"

# Load sessions
df = pd.read_csv(sessions_path)

# Find invalid rows
invalid_mask = (
    (df["content_items_viewed"] < 0)
    | (df["content_items_watched"] < 0)
    | (df["content_items_watched"] > df["content_items_viewed"])
)

invalid_count = invalid_mask.sum()

print(f"Invalid session rows found: {invalid_count}")

# Fix only the impossible watched > viewed cases
df.loc[invalid_mask, "content_items_watched"] = (
    df.loc[invalid_mask, "content_items_watched"]
    .clip(upper=df.loc[invalid_mask, "content_items_viewed"])
)

# Save corrected sessions
df.to_csv(sessions_path, index=False)

print("sessions.csv updated successfully.")

# Verify
remaining_invalid = (
    (df["content_items_viewed"] < 0)
    | (df["content_items_watched"] < 0)
    | (df["content_items_watched"] > df["content_items_viewed"])
).sum()

print(f"Remaining invalid rows: {remaining_invalid}")