#!/usr/bin/env python3
from clickhouse_driver import Client

def check_grp2_tables():
    client = Client(
        host='54.87.106.52',
        port=9000,  # Native TCP port
        user='ftw_user',
        password='ftw_pass',
        database='raw',
        secure=False
    )
    
    tables = [
        'chinook___grp2_2track_shi',
        'chinook___grp2_2customer_shi',
        'chinook___grp2_2invoice_shi',
        'chinook___grp2_2invoice_line_shi'
    ]
    
    for table in tables:
        print(f"\n=== {table} ===")
        try:
            result = client.execute(f'DESCRIBE {table}')
            for row in result:
                print(f'  {row[0]} - {row[1]}')
                
            # Show sample data
            print("Sample data:")
            sample = client.execute(f'SELECT * FROM {table} LIMIT 3')
            for i, row in enumerate(sample[:3]):
                print(f'  Row {i+1}: {row}')
        except Exception as e:
            print(f'  Error: {e}')

if __name__ == "__main__":
    check_grp2_tables()