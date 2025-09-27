#!/usr/bin/env python3

import os
import psycopg2
import dlt
from typing import Iterator, Dict, Any


@dlt.resource(write_disposition="replace")
def Grp2_2albums_shi() -> Iterator[Dict[str, Any]]:
    """
    Load albums data from PostgreSQL Chinook database.
    """
    # Connection parameters for PostgreSQL
    conn_params = {
        'host': os.getenv('POSTGRES_HOST'),
        'port': os.getenv('POSTGRES_PORT', '5432'),
        'database': os.getenv('POSTGRES_DB'),
        'user': os.getenv('POSTGRES_USER'),
        'password': os.getenv('POSTGRES_PASSWORD')
    }
    
    # Connect to PostgreSQL
    conn = psycopg2.connect(**conn_params)
    cursor = conn.cursor()
    
    try:
        # Query albums data
        cursor.execute("SELECT * FROM Album")
        columns = [desc[0] for desc in cursor.description]
        
        # Yield each row as a dictionary
        for row in cursor.fetchall():
            yield dict(zip(columns, row))
            
    finally:
        cursor.close()
        conn.close()


if __name__ == "__main__":
    # Initialize the pipeline
    pipeline = dlt.pipeline(
        pipeline_name="chinook-albums-grp2",
        destination="clickhouse",
        dataset_name="raw"
    )
    
    # Run the pipeline
    load_info = pipeline.run(Grp2_2albums_shi())
    
    # Print results
    print(f"Pipeline completed successfully!")
    print(f"Load info: {load_info}")