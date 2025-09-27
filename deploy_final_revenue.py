#!/usr/bin/env python3
"""
Deploy Final Revenue Analysis to ClickHouse - Step by Step Approach
This script creates the table first, then inserts the data.
"""

from clickhouse_driver import Client

def deploy_final_revenue_analysis():
    """Deploy the revenue analysis table using separate CREATE and INSERT statements."""
    
    client = Client(
        host='54.87.106.52',
        port=9000,
        user='ftw_user',
        password='ftw_pass',
        database='mart',
        secure=False
    )
    
    # Ensure mart database exists
    try:
        client.execute('CREATE DATABASE IF NOT EXISTS mart')
        print("✓ Ensured mart database exists")
    except Exception as e:
        print(f"Warning: Could not create mart database: {e}")
    
    try:
        # Step 1: Drop existing table
        print("🧹 Dropping existing table if it exists...")
        client.execute("DROP TABLE IF EXISTS mart.g2_top_revenue_by_genre_per_country_shi")
        
        # Step 2: Create table structure
        print("📋 Creating table structure...")
        create_table_query = """
        CREATE TABLE mart.g2_top_revenue_by_genre_per_country_shi (
            country String,
            genre_name String,
            total_revenue Decimal(10,2),
            unique_customers UInt32,
            total_tracks_sold UInt32,
            total_quantity UInt32
        ) ENGINE = MergeTree()
        ORDER BY (country, genre_name)
        """
        client.execute(create_table_query)
        print("✅ Table structure created successfully")
        
        # Step 3: Insert data
        print("📊 Inserting revenue data...")
        insert_query = """
        INSERT INTO mart.g2_top_revenue_by_genre_per_country_shi
        SELECT 
            c.country,
            g.name as genre_name,
            ROUND(SUM(il.unit_price * il.quantity), 2) as total_revenue,
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
        HAVING total_revenue > 0
        ORDER BY country, total_revenue DESC
        """
        client.execute(insert_query)
        print("✅ Data inserted successfully")
        
        # Step 4: Verify and show results
        result = client.execute('SELECT COUNT(*) FROM mart.g2_top_revenue_by_genre_per_country_shi')
        row_count = result[0][0]
        print(f"📊 Table contains {row_count} rows")
        
        # Show top results by country
        print("\n📋 Top revenue genres by country (sample):")
        sample_data = client.execute('''
            SELECT country, genre_name, total_revenue, unique_customers
            FROM mart.g2_top_revenue_by_genre_per_country_shi
            ORDER BY country, total_revenue DESC
            LIMIT 15
        ''')
        
        print("Country          | Genre               | Revenue | Customers")
        print("-" * 60)
        for row in sample_data:
            print(f"{row[0]:<16} | {row[1]:<19} | ${row[2]:>7} | {row[3]:>9}")
            
        # Show country summary
        print("\n🌍 Countries available:")
        countries = client.execute('''
            SELECT country, COUNT(*) as genres, SUM(total_revenue) as total_country_revenue
            FROM mart.g2_top_revenue_by_genre_per_country_shi
            GROUP BY country
            ORDER BY total_country_revenue DESC
            LIMIT 10
        ''')
        
        print("Country          | Genres | Total Revenue")
        print("-" * 40)
        for row in countries:
            print(f"{row[0]:<16} | {row[1]:>6} | ${row[2]:>10}")
            
        print("\n🎉 Deployment complete! The table is now available in Metabase:")
        print("   📍 Database: mart")
        print("   📊 Table: g2_top_revenue_by_genre_per_country_shi")
        print("   📈 Columns: country, genre_name, total_revenue, unique_customers, total_tracks_sold, total_quantity")
        print("\n💡 In Metabase, you can:")
        print("   • Filter by country to see top genres per country")
        print("   • Sort by total_revenue DESC to see highest revenue genres")
        print("   • Create charts showing revenue by genre for specific countries")
        
    except Exception as e:
        print(f"❌ Error during deployment: {e}")
        raise

if __name__ == "__main__":
    deploy_final_revenue_analysis()