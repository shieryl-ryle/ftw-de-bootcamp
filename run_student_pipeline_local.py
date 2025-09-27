#!/usr/bin/env python3

import os
import csv
import sys

def Grp2_StudentInfo():
    """
    Load studentInfo.csv data from local data directory.
    """
    csv_path = "/home/runner/work/ftw-de-bootcamp/ftw-de-bootcamp/data/studentInfo.csv"
    
    print(f"Loading CSV from: {csv_path}")
    
    # Check if file exists
    if not os.path.exists(csv_path):
        raise FileNotFoundError(f"CSV file not found: {csv_path}")
    
    try:
        # Read CSV file
        data = []
        with open(csv_path, 'r') as file:
            reader = csv.DictReader(file)
            original_columns = reader.fieldnames
            print(f"Original columns: {list(original_columns)}")
            
            for row in reader:
                # Clean column names for ClickHouse compatibility
                clean_row = {}
                for key, value in row.items():
                    clean_key = key.replace(' ', '_').replace('-', '_').lower()
                    clean_row[clean_key] = value if value else ''
                data.append(clean_row)
        
        print(f"Loaded {len(data)} rows and {len(original_columns)} columns")
        
        # Get cleaned column names
        if data:
            cleaned_columns = list(data[0].keys())
            print(f"Cleaned columns: {cleaned_columns}")
        
        print(f"Data processing completed successfully!")
        print(f"Sample of processed data:")
        if data:
            for i, record in enumerate(data[:3]):
                print(f"Record {i+1}: {record}")
        
        return data
            
    except Exception as e:
        print(f"Error processing CSV: {str(e)}")
        raise

if __name__ == "__main__":
    print("=== Running Student Information Pipeline ===")
    result = Grp2_StudentInfo()
    print(f"\n=== Pipeline Summary ===")
    print(f"Successfully processed {len(result)} student records")
    if result:
        print(f"Columns: {list(result[0].keys())}")
    print("Pipeline completed successfully!")