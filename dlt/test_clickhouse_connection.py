#!/usr/bin/env python3
import os
import sys
try:
    from clickhouse_driver import Client
    
    print("Testing ClickHouse connection...")
    
    # Try with HTTP first (more likely to work through firewalls)
    try:
        print("Attempting HTTP connection...")
        client = Client(
            host='54.87.106.52',
            port=8123,
            user='ftw_user',
            password='ftw_pass',
            database='raw',
            secure=False,
            connect_timeout=30,
            send_receive_timeout=60
        )
        result = client.execute('SELECT 1')
        print(f"HTTP connection SUCCESS: {result}")
    except Exception as e:
        print(f"HTTP connection failed: {e}")
    
    # Try with native TCP
    try:
        print("Attempting native TCP connection...")
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
        result = client.execute('SELECT 1')
        print(f"Native TCP connection SUCCESS: {result}")
    except Exception as e:
        print(f"Native TCP connection failed: {e}")
        
except ImportError:
    print("clickhouse-driver not available for testing")
    sys.exit(1)