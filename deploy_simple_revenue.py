#!/usr/bin/env python3
"""
Deploy Grp2 Revenue Analysis to ClickHouse - Simplified Version
This script creates the mart table for Top Revenue by Genre per Country
so it can be accessed in Metabase.
"""

from clickhouse_driver import Client

def deploy_simple_revenue_analysis():
    """Deploy a simplified revenue analysis table to ClickHouse mart schema."""
    
    client = Client(
        host='54.87.106.52',
        port=9000,
        user='ftw_user',
        password='ftw_pass',
        database='mart',
        secure=False
    )
    
    # First, ensure the mart database exists
    try:
        client.execute('CREATE DATABASE IF NOT EXISTS mart')
        print("✓ Ensured mart database exists")
    except Exception as e:
        print(f"Warning: Could not create mart database: {e}")
    
    try:
        # Drop existing table
        print("🧹 Dropping existing table if it exists...")
        client.execute("DROP TABLE IF EXISTS mart.g2_top_revenue_by_genre_per_country_shi")
        
        # Create and populate table in one step
        print("🚀 Creating revenue analysis table...")
        create_and_insert_query = """
        CREATE TABLE mart.g2_top_revenue_by_genre_per_country_shi
        ENGINE = MergeTree()
        ORDER BY (country, total_revenue) AS
        SELECT 
            country,
            genre_name,
            total_revenue,
            unique_customers,
            total_tracks_sold,
            total_quantity,
            genre_rank
        FROM (
            SELECT 
                country,
                genre_name,
                total_revenue,
                unique_customers,
                total_tracks_sold,
                total_quantity,
                ROW_NUMBER() OVER (PARTITION BY country ORDER BY total_revenue DESC) as genre_rank
            FROM (
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
            ) grouped_data
        ) ranked_data
        WHERE genre_rank <= 5
        ORDER BY country, total_revenue DESC
        """
        
        client.execute(create_and_insert_query)
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
            ORDER BY country, genre_rank
            LIMIT 10
        ''')
        
        print("Country          | Genre               | Revenue | Customers | Rank")
        print("-" * 70)
        for row in sample_data:
            print(f"{row[0]:<16} | {row[1]:<19} | ${row[2]:>7} | {row[3]:>9} | {row[4]}")
            
        print("\n🎉 Deployment complete! The table is now available in Metabase as:")
        print("   Database: mart")
        print("   Table: g2_top_revenue_by_genre_per_country_shi")
        
    except Exception as e:
        print(f"❌ Error deploying table: {e}")
        raise

if __name__ == "__main__":
    deploy_simple_revenue_analysis()