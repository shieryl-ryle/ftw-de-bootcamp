#!/usr/bin/env python3

import os
import pandas as pd
import dlt
from typing import Iterator, Dict, Any


@dlt.resource(write_disposition="replace")
def Grp2_StudentInfo() -> Iterator[Dict[str, Any]]:
    """
    Load studentInfo.csv data from mounted data directory to remote ClickHouse.
    """
    csv_path = "/data/studentInfo.csv"
    
    print(f"Loading CSV from: {csv_path}")
    
    # Check if file exists
    if not os.path.exists(csv_path):
        raise FileNotFoundError(f"CSV file not found: {csv_path}")
    
    try:
        # Read CSV file
        df = pd.read_csv(csv_path)
        print(f"Loaded {len(df)} rows and {len(df.columns)} columns")
        print(f"Original columns: {list(df.columns)}")
        
        # Clean column names for ClickHouse compatibility
        df.columns = df.columns.str.replace(' ', '_').str.replace('-', '_').str.lower()
        print(f"Cleaned columns: {list(df.columns)}")
        
        # Handle missing values
        df = df.fillna('')
        
        print(f"Yielding {len(df)} student records...")
        
        # Yield each row as a dictionary
        for _, row in df.iterrows():
            yield row.to_dict()
            
    except Exception as e:
        print(f"Error processing CSV: {str(e)}")
        raise


if __name__ == "__main__":
    # Initialize the pipeline
    pipeline = dlt.pipeline(
        pipeline_name="grp2-student-pipeline",
        destination="clickhouse",
        dataset_name="raw"
    )
    
    # Run the pipeline
    load_info = pipeline.run(Grp2_StudentInfo())
    
    # Print results
    print(f"Pipeline completed successfully!")
    print(f"Load info: {load_info}")