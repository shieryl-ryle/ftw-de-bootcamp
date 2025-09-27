#!/usr/bin/env python3
from clickhouse_driver import Client

def check_actual_tables():
    client = Client(
        host='54.87.106.52',
        port=9000,
        user='ftw_user',
        password='ftw_pass',
        database='raw',
        secure=False
    )
    
    # Check the actual tables that exist
    tables_to_check = [
        'chinook___grp2_2albums_shi',
        'chinook___grp2_2artists_shi',
        'chinook___customer_shi',
        'chinook___invoice_shi',
        'chinook___invoice_line_shi',
        'chinook___track_shi'
    ]
    
    for table in tables_to_check:
        print(f"\n=== {table} ===")
        try:
            result = client.execute(f'DESCRIBE {table}')
            print("Columns:")
            for row in result:
                print(f'  {row[0]} ({row[1]})')
                
            # Show count
            count_result = client.execute(f'SELECT COUNT(*) FROM {table}')
            print(f"Row count: {count_result[0][0]}")
            
        except Exception as e:
            print(f'  Error: {e}')

if __name__ == "__main__":
    check_actual_tables()