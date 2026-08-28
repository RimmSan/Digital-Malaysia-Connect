import csv
import json
import urllib.request

CSV_URL = "https://storage.dosm.gov.my/population/population_state.csv"
OUTPUT_FILE = "population_state.json"

print("Downloading official DOSM state population dataset...")

with urllib.request.urlopen(CSV_URL) as response:
    data = response.read().decode("utf-8")

rows = []

reader = csv.DictReader(data.splitlines())

for row in reader:
    # Keep only total population records:
    # both sexes + all ages + all ethnicities
    if (
        row["sex"] == "both"
        and row["age"] == "overall"
        and row["ethnicity"] == "overall"
    ):
        rows.append({
            "state": row["state"],
            "date": row["date"],
            "population": float(row["population"]),
        })

# Sort by state, then year
rows.sort(
    key=lambda x: (
        x["state"],
        x["date"],
    )
)

with open(
    OUTPUT_FILE,
    "w",
    encoding="utf-8",
) as file:
    json.dump(
        rows,
        file,
        indent=2,
        ensure_ascii=False,
    )

print(f"Done! Saved {len(rows)} records to {OUTPUT_FILE}")