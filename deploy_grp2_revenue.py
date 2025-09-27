#!/usr/bin/env python3
"""
Deploy Grp2 Revenue Analysis to ClickHouse
This script creates the mart table for Top Revenue by Genre per Country
so it can be accessed in Metabase.
"""

from clickhouse_driver import Client

def deploy_revenue_analysis():
    """Deploy the revenue analysis table to ClickHouse mart schema."""
    
    client = Client(
        host='54.87.106.52',
        port=9000,
        user='ftw_user',
        password='ftw_pass',
        database='mart',  # Target database for deployment
        secure=False
    )
    
    # First, ensure the mart database exists
    try:
        client.execute('CREATE DATABASE IF NOT EXISTS mart')
        print("✓ Ensured mart database exists")
    except Exception as e:
        print(f"Warning: Could not create mart database: {e}")
    
    # Step 1: Drop table if exists
    drop_query = "DROP TABLE IF EXISTS mart.g2_top_revenue_by_genre_per_country_shi"
    
    # Step 2: Create table structure
    create_query = """
    CREATE TABLE mart.g2_top_revenue_by_genre_per_country_shi (
        country String,
        genre_name String,
        total_revenue Decimal(10,2),
        unique_customers UInt32,
        total_tracks_sold UInt32,
        total_quantity UInt32,
        genre_rank UInt32
    ) ENGINE = MergeTree()
    ORDER BY (country, total_revenue)
    """
    
    # Step 3: Insert data - simplified approach without CTE
    insert_query = """
    INSERT INTO mart.g2_top_revenue_by_genre_per_country_shi
    SELECT 
        country,
        genre_name,
        ROUND(total_revenue, 2) as total_revenue,
        unique_customers,
        total_tracks_sold,
        total_quantity,
        ROW_NUMBER() OVER (PARTITION BY country ORDER BY total_revenue DESC) as genre_rank
    FROM (
        SELECT 
            c.country,
            g.name as genre_name,
            SUM(il.unit_price * il.quantity) as total_revenue,
            COUNT(DISTINCT i.customer_id) as unique_customers,
            COUNT(il.invoice_line_id) as total_tracks_sold,
            SUM(il.quantity) as total_quantity
        FROM raw.chinook___invoice_line_shi il
        JOIN raw.chinook___invoice_shi i 
            ON il.invoice_id = i.invoice_id
        JOIN raw.chinook___customer_shi c 
            ON i.customer_id = c.customer_id
        JOIN raw.chinook___track_shi t 
            ON il.track_id = t.track_id
        JOIN raw.chinook___genre_shi g 
            ON t.genre_id = g.genre_id
        GROUP BY 
            c.country, 
            g.name
    ) revenue_by_genre_country
    WHERE ROW_NUMBER() OVER (PARTITION BY country ORDER BY total_revenue DESC) <= 5
    ORDER BY 
        country ASC,
        total_revenue DESC
    """
    
    try:
        print("🚀 Deploying revenue analysis table...")
        print("  - Dropping existing table...")
        client.execute(drop_query)
        print("  - Creating table structure...")
        client.execute(create_query)
        print("  - Inserting data...")
        client.execute(insert_query)
        print("✅ Successfully created mart.g2_top_revenue_by_genre_per_country_shi")
        
        # Verify the table was created and show sample data
        result = client.execute('SELECT COUNT(*) FROM mart.g2_top_revenue_by_genre_per_country_shi')
        row_count = result[0][0]
        print(f"📊 Table created with {row_count} rows")
        
        # Show sample results
        print("\n📋 Sample results (Top 10 rows):")
        sample_data = client.execute('''
            SELECT country, genre_name, total_revenue, unique_customers, genre_rank
            FROM mart.g2_top_revenue_by_genre_per_country_shi
            LIMIT 10
        ''')
        
        print("Country | Genre | Revenue | Customers | Rank")
        print("-" * 50)
        for row in sample_data:
            print(f"{row[0]:<12} | {row[1]:<15} | ${row[2]:>8} | {row[3]:>9} | {row[4]}")
            
        print("\n🎉 Deployment complete! The table is now available in Metabase as:")
        print("   Database: mart")
        print("   Table: g2_top_revenue_by_genre_per_country_shi")
        
    except Exception as e:
        print(f"❌ Error deploying table: {e}")
        raise

if __name__ == "__main__":
    deploy_revenue_analysis()