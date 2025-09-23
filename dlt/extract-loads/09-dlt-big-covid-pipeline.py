# extract-loads/09-dlt-big-covid-pipeline.py

import dlt
import pandas as pd
from typing import Optional

# ---------------------------------------------------------------------------
# This script ingests a large COVID-19 dataset into ClickHouse using dlt.
# The dataset is hosted as a public CSV file on Google Cloud Storage.
# ---------------------------------------------------------------------------

CSV_URL = "https://storage.googleapis.com/covid19-open-data/v3/epidemiology.csv"

# ---------------------------------------------------------------------------
# Column type hints (schema definition)
#
# Why? → When dlt loads data into ClickHouse, it tries to infer the column types.
# If the first batch of data is empty (all NULLs), dlt can't guess the type.
# By specifying types here, we make sure the table schema is always correct.
# ---------------------------------------------------------------------------
COLUMNS = {
    "date": {"data_type": "date", "nullable": True},             # Dates can be null
    "location_key": {"data_type": "text", "nullable": True},     # Location codes (string)
    "new_confirmed": {"data_type": "bigint", "nullable": True},  # Daily counts (can be missing)
    "new_deceased": {"data_type": "bigint", "nullable": True},
    "new_recovered": {"data_type": "bigint", "nullable": True},
    "new_tested": {"data_type": "bigint", "nullable": True},
    "cumulative_confirmed": {"data_type": "bigint", "nullable": True},
    "cumulative_deceased": {"data_type": "bigint", "nullable": True},
    "cumulative_recovered": {"data_type": "bigint", "nullable": True},
    "cumulative_tested": {"data_type": "bigint", "nullable": True},
}

# ---------------------------------------------------------------------------
# Define a dlt resource → this is like a data "source" for the pipeline.
#
# - We tell dlt the table name to create in ClickHouse
# - We attach the schema (COLUMNS) so all fields are materialized
# - The function yields chunks of data, so dlt can load them in batches
# ---------------------------------------------------------------------------
@dlt.resource(
    name="covid19_epidemiology",            # Internal resource name
    table_name="covid19_epidemiology",      # Destination table name in ClickHouse
    write_disposition="append",             # Append new rows each run
    columns=COLUMNS,                        # Use our schema definition
)
def covid_epidemiology(row_limit: Optional[int] = None, chunk_rows: int = 50_000):
    """
    Stream the CSV file in chunks and stop after 'row_limit' rows.

    Parameters:
    - row_limit: total number of rows to ingest (None = all rows)
    - chunk_rows: how many rows to process at once (keeps memory low)
    """
    rows_emitted = 0  # Keep track of how many rows we’ve already yielded

    # Pandas can stream CSVs in chunks → avoids loading the entire file in RAM
    for chunk in pd.read_csv(
        CSV_URL,
        chunksize=chunk_rows,
        dtype_backend="pyarrow",  # Uses Apache Arrow backend (faster + memory efficient)
    ):
        # --- Basic data cleaning ---
        # Convert the "date" column to proper Python dates
        if "date" in chunk.columns:
            chunk["date"] = pd.to_datetime(chunk["date"], errors="coerce").dt.date

        # Ensure numeric columns are integers but allow NULLs (pandas "Int64" type)
        for col in [
            "new_confirmed","new_deceased","new_recovered","new_tested",
            "cumulative_confirmed","cumulative_deceased","cumulative_recovered","cumulative_tested",
        ]:
            if col in chunk.columns:
                chunk[col] = pd.to_numeric(chunk[col], errors="coerce").astype("Int64")

        # --- Apply row_limit if user requested ---
        if row_limit is not None:
            remaining = row_limit - rows_emitted
            if remaining <= 0:  # Stop if we’ve already reached the limit
                break
            if len(chunk) > remaining:
                # Trim the chunk so we don’t go past the limit
                chunk = chunk.iloc[:remaining]

        rows_emitted += len(chunk)

        # Yield this chunk to dlt → it will prepare it for loading
        yield chunk

        # Stop if we’ve ingested enough rows
        if row_limit is not None and rows_emitted >= row_limit:
            break


# ---------------------------------------------------------------------------
# Pipeline runner
#
# - Creates a dlt pipeline object
# - Runs our covid_epidemiology resource
# - Writes results into ClickHouse
# ---------------------------------------------------------------------------
def run(row_limit: Optional[int] = 500, chunk_rows: int = 20_000):
    print(f"Starting ingestion with row_limit={row_limit}, chunk_rows={chunk_rows}")

    # Define the pipeline
    pipe = dlt.pipeline(
        pipeline_name="covid19_epidemiology_pipeline",  # Pipeline identifier
        destination="clickhouse",                      # Destination DB (from env vars)
        dataset_name="covid19_open_data",              # Schema/namespace in ClickHouse
    )

    # Run the pipeline with our resource
    load_info = pipe.run(
        covid_epidemiology(row_limit=row_limit, chunk_rows=chunk_rows),
        loader_file_format="parquet",  # Parquet = compact, faster for ClickHouse
    )

    print("Ingestion completed.")
    print(load_info)


# ---------------------------------------------------------------------------
# Entry point when running this script directly.
#
# Example: Only load the first 500 rows, in batches of 100 rows each.
# ---------------------------------------------------------------------------
if __name__ == "__main__":
    run(row_limit=500, chunk_rows=100)
