import pandas as pd

df = pd.read_parquet("population_state.parquet")

# Keep only the overall totals per state (not broken down by age/sex/ethnicity)
overall = df[
    (df['sex'] == 'both') &
    (df['age'] == 'overall') &
    (df['ethnicity'] == 'overall')
].copy()

# Keep only the most recent year per state
overall['date'] = pd.to_datetime(overall['date'])
latest = overall.sort_values('date').groupby('state').tail(1)
latest = latest.sort_values('population', ascending=False)

print(latest)

latest.to_json("population_state.json", orient="records", date_format="iso")
print("Done — population_state.json created (latest year, overall totals, sorted by population)")