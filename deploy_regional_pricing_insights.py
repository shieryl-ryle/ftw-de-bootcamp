#!/usr/bin/env python3
"""
Deploy Regional Pricing Insights Analysis
Create comprehensive regional pricing analysis table for Metabase
"""

from clickhouse_driver import Client

def deploy_regional_pricing_insights():
    """Deploy regional pricing insights table to ClickHouse mart schema."""
    
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
        print("🧹 Dropping existing pricing insights table if it exists...")
        client.execute("DROP TABLE IF EXISTS mart.g2_regional_pricing_insights_shi")
        
        # Step 2: Create table structure
        print("📋 Creating regional pricing insights table structure...")
        create_table_query = """
        CREATE TABLE mart.g2_regional_pricing_insights_shi (
            country String,
            region String,
            total_purchases UInt32,
            total_revenue Decimal(10,2),
            avg_price_paid Decimal(4,2),
            min_price_paid Decimal(4,2),
            max_price_paid Decimal(4,2),
            unique_price_points UInt8,
            low_price_purchases UInt32,
            high_price_purchases UInt32,
            low_price_percentage Decimal(5,2),
            high_price_percentage Decimal(5,2),
            price_sensitivity_score Decimal(5,2),
            unique_customers UInt32,
            avg_purchase_per_customer Decimal(6,2),
            unique_genres_purchased UInt16
        ) ENGINE = MergeTree()
        ORDER BY (country)
        """
        client.execute(create_table_query)
        print("✅ Table structure created successfully")
        
        # Step 3: Insert comprehensive pricing insights data
        print("📊 Inserting regional pricing insights data...")
        insert_query = """
        INSERT INTO mart.g2_regional_pricing_insights_shi
        SELECT 
            country,
            CASE 
                WHEN country IN ('USA', 'Canada') THEN 'North America'
                WHEN country IN ('Brazil', 'Chile', 'Argentina') THEN 'South America'
                WHEN country IN ('United Kingdom', 'France', 'Germany', 'Portugal', 'Spain', 'Italy', 'Netherlands', 'Norway', 'Czech Republic', 'Austria', 'Belgium', 'Denmark', 'Finland', 'Hungary', 'Ireland', 'Poland', 'Sweden') THEN 'Europe'
                WHEN country IN ('India') THEN 'Asia'
                WHEN country IN ('Australia') THEN 'Oceania'
                ELSE 'Other'
            END as region,
            COUNT(il.invoice_line_id) as total_purchases,
            ROUND(SUM(il.unit_price * il.quantity), 2) as total_revenue,
            ROUND(AVG(il.unit_price), 2) as avg_price_paid,
            MIN(il.unit_price) as min_price_paid,
            MAX(il.unit_price) as max_price_paid,
            COUNT(DISTINCT il.unit_price) as unique_price_points,
            SUM(CASE WHEN il.unit_price = 0.99 THEN 1 ELSE 0 END) as low_price_purchases,
            SUM(CASE WHEN il.unit_price = 1.99 THEN 1 ELSE 0 END) as high_price_purchases,
            ROUND(SUM(CASE WHEN il.unit_price = 0.99 THEN 1 ELSE 0 END) * 100.0 / COUNT(il.invoice_line_id), 2) as low_price_percentage,
            ROUND(SUM(CASE WHEN il.unit_price = 1.99 THEN 1 ELSE 0 END) * 100.0 / COUNT(il.invoice_line_id), 2) as high_price_percentage,
            ROUND(
                CASE 
                    WHEN COUNT(DISTINCT il.unit_price) = 1 THEN 
                        CASE WHEN MIN(il.unit_price) = 0.99 THEN 100.0 ELSE 0.0 END
                    ELSE 
                        (SUM(CASE WHEN il.unit_price = 0.99 THEN 1 ELSE 0 END) * 100.0 / COUNT(il.invoice_line_id))
                END, 2
            ) as price_sensitivity_score,
            COUNT(DISTINCT i.customer_id) as unique_customers,
            ROUND(SUM(il.unit_price * il.quantity) / COUNT(DISTINCT i.customer_id), 2) as avg_purchase_per_customer,
            COUNT(DISTINCT t.genre_id) as unique_genres_purchased
        FROM raw.chinook___invoice_line_shi il
        JOIN raw.chinook___invoice_shi i ON il.invoice_id = i.invoice_id
        JOIN raw.chinook___customer_shi c ON i.customer_id = c.customer_id
        JOIN raw.chinook___track_shi t ON il.track_id = t.track_id
        GROUP BY 
            c.country,
            CASE 
                WHEN country IN ('USA', 'Canada') THEN 'North America'
                WHEN country IN ('Brazil', 'Chile', 'Argentina') THEN 'South America'
                WHEN country IN ('United Kingdom', 'France', 'Germany', 'Portugal', 'Spain', 'Italy', 'Netherlands', 'Norway', 'Czech Republic', 'Austria', 'Belgium', 'Denmark', 'Finland', 'Hungary', 'Ireland', 'Poland', 'Sweden') THEN 'Europe'
                WHEN country IN ('India') THEN 'Asia'
                WHEN country IN ('Australia') THEN 'Oceania'
                ELSE 'Other'
            END
        HAVING total_purchases > 0
        ORDER BY total_revenue DESC
        """
        client.execute(insert_query)
        print("✅ Regional pricing insights data inserted successfully")
        
        # Step 4: Verify and show results
        result = client.execute('SELECT COUNT(*) FROM mart.g2_regional_pricing_insights_shi')
        row_count = result[0][0]
        print(f"📊 Table contains {row_count} countries")
        
        # Show top regional pricing insights
        print("\n📋 Regional Pricing Insights (Top 10 Countries by Revenue):")
        top_insights = client.execute('''
            SELECT 
                country, 
                region,
                total_revenue, 
                avg_price_paid, 
                price_sensitivity_score,
                low_price_percentage,
                high_price_percentage,
                unique_customers
            FROM mart.g2_regional_pricing_insights_shi
            ORDER BY total_revenue DESC
            LIMIT 10
        ''')
        
        print("Country          | Region        | Revenue | Avg Price | Sensitivity | Low% | High% | Customers")
        print("-" * 95)
        for row in top_insights:
            print(f"{row[0]:<16} | {row[1]:<13} | ${row[2]:>7} | ${row[3]:>8} | {row[4]:>10}% | {row[5]:>4}% | {row[6]:>5}% | {row[7]:>9}")
        
        # Show regional summary
        print("\n🌍 Regional Summary:")
        regional_summary = client.execute('''
            SELECT 
                region,
                COUNT(*) as countries,
                SUM(total_revenue) as region_revenue,
                AVG(avg_price_paid) as avg_regional_price,
                AVG(price_sensitivity_score) as avg_price_sensitivity,
                SUM(unique_customers) as total_customers
            FROM mart.g2_regional_pricing_insights_shi
            GROUP BY region
            ORDER BY region_revenue DESC
        ''')
        
        print("Region           | Countries | Revenue   | Avg Price | Sensitivity | Customers")
        print("-" * 75)
        for row in regional_summary:
            print(f"{row[0]:<16} | {row[1]:>9} | ${row[2]:>8} | ${row[3]:>8.2f} | {row[4]:>10.1f}% | {row[5]:>9}")
        
        print("\n🎉 Regional Pricing Insights deployment complete!")
        print("   📍 Database: mart")
        print("   📊 Table: g2_regional_pricing_insights_shi")
        print("   📈 Includes: Country, Region, Price Sensitivity, Purchase Patterns")
        print("\n💡 Key Insights Available:")
        print("   • Price sensitivity by country (preference for $0.99 vs $1.99)")
        print("   • Regional pricing patterns and customer behavior")
        print("   • Purchase volume and revenue analysis")
        print("   • Customer value metrics per region")
        
    except Exception as e:
        print(f"❌ Error during deployment: {e}")
        raise

if __name__ == "__main__":
    deploy_regional_pricing_insights()