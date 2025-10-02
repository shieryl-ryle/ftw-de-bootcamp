#!/usr/bin/env python3
try:
    from clickhouse_driver import Client
    
    print("Connecting to remote ClickHouse...")
    
    client = Client(
        host='54.87.106.52',
        port=9000,
        user='ftw_user',
        password='ftw_pass',
        database='raw',
        secure=False,
        connect_timeout=30,
        send_receive_timeout=60
    )
    
    print("Listing all tables with 'chinook' in name:")
    result = client.execute("SHOW TABLES LIKE '%chinook%'")
    for table in result:
        if 'Grp2' in table[0]:
            print(f"  *** {table[0]} (Grp2 table)")
        else:
            print(f"  - {table[0]}")
    
    print(f"\nTotal tables found: {len(result)}")
        
except Exception as e:
    print(f"Error: {e}")