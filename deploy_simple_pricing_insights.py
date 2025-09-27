#!/usr/bin/env python3
"""
Deploy Simple Regional Pricing Insights - Working Version
Create a streamlined regional pricing analysis table
"""

from clickhouse_driver import Client

def deploy_simple_pricing_insights():
    """Deploy a simplified regional pricing insights table."""
    
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
        client.execute("DROP TABLE IF EXISTS mart.g2_regional_pricing_insights_shi")
        
        # Step 2: Create simpler table structure
        print("📋 Creating regional pricing insights table...")
        create_table_query = """
        CREATE TABLE mart.g2_regional_pricing_insights_shi (
            country String,
            region String,
            total_purchases UInt32,
            total_revenue Decimal(10,2),
            avg_price_paid Decimal(4,2),
            low_price_purchases UInt32,
            high_price_purchases UInt32,
            low_price_percentage Decimal(5,2),
            price_sensitivity_score Decimal(5,2),
            unique_customers UInt32,
            avg_spending_per_customer Decimal(6,2)
        ) ENGINE = MergeTree()
        ORDER BY (country)
        """
        client.execute(create_table_query)
        print("✅ Table structure created successfully")
        
        # Step 3: Insert simplified pricing insights data
        print("📊 Inserting regional pricing insights data...")
        insert_query = """
        INSERT INTO mart.g2_regional_pricing_insights_shi
        SELECT 
            c.country,
            CASE 
                WHEN c.country IN ('USA', 'Canada') THEN 'North America'
                WHEN c.country IN ('Brazil', 'Chile', 'Argentina') THEN 'South America'
                WHEN c.country IN ('United Kingdom', 'France', 'Germany', 'Portugal', 'Spain', 'Italy', 'Netherlands', 'Norway', 'Czech Republic', 'Austria', 'Belgium', 'Denmark', 'Finland', 'Hungary', 'Ireland', 'Poland', 'Sweden') THEN 'Europe'
                WHEN c.country IN ('India') THEN 'Asia'
                WHEN c.country IN ('Australia') THEN 'Oceania'
                ELSE 'Other'
            END as region,
            COUNT(il.invoice_line_id) as total_purchases,
            ROUND(SUM(il.unit_price * il.quantity), 2) as total_revenue,
            ROUND(AVG(il.unit_price), 2) as avg_price_paid,
            SUM(CASE WHEN il.unit_price = 0.99 THEN 1 ELSE 0 END) as low_price_purchases,
            SUM(CASE WHEN il.unit_price = 1.99 THEN 1 ELSE 0 END) as high_price_purchases,
            ROUND(SUM(CASE WHEN il.unit_price = 0.99 THEN 1 ELSE 0 END) * 100.0 / COUNT(il.invoice_line_id), 2) as low_price_percentage,
            ROUND(SUM(CASE WHEN il.unit_price = 0.99 THEN 1 ELSE 0 END) * 100.0 / COUNT(il.invoice_line_id), 2) as price_sensitivity_score,
            COUNT(DISTINCT i.customer_id) as unique_customers,
            ROUND(SUM(il.unit_price * il.quantity) / COUNT(DISTINCT i.customer_id), 2) as avg_spending_per_customer
        FROM raw.chinook___invoice_line_shi il
        JOIN raw.chinook___invoice_shi i ON il.invoice_id = i.invoice_id
        JOIN raw.chinook___customer_shi c ON i.customer_id = c.customer_id
        GROUP BY 
            c.country,
            CASE 
                WHEN c.country IN ('USA', 'Canada') THEN 'North America'
                WHEN c.country IN ('Brazil', 'Chile', 'Argentina') THEN 'South America'
                WHEN c.country IN ('United Kingdom', 'France', 'Germany', 'Portugal', 'Spain', 'Italy', 'Netherlands', 'Norway', 'Czech Republic', 'Austria', 'Belgium', 'Denmark', 'Finland', 'Hungary', 'Ireland', 'Poland', 'Sweden') THEN 'Europe'
                WHEN c.country IN ('India') THEN 'Asia'
                WHEN c.country IN ('Australia') THEN 'Oceania'
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
        
        # Show top insights
        print("\n📋 Regional Pricing Insights (Top Countries by Revenue):")
        top_insights = client.execute('''
            SELECT 
                country, 
                region,
                total_revenue, 
                avg_price_paid, 
                low_price_percentage,
                price_sensitivity_score,
                avg_spending_per_customer,
                unique_customers
            FROM mart.g2_regional_pricing_insights_shi
            ORDER BY total_revenue DESC
            LIMIT 10
        ''')
        
        print("Country          | Region        | Revenue | Avg Price | Low Price% | Sensitivity | Avg/Customer | Customers")
        print("-" * 110)
        for row in top_insights:
            print(f"{row[0]:<16} | {row[1]:<13} | ${row[2]:>7} | ${row[3]:>8} | {row[4]:>9}% | {row[5]:>10}% | ${row[6]:>11} | {row[7]:>9}")
        
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
        
        print("Region           | Countries | Revenue   | Avg Price | Price Sens% | Customers")
        print("-" * 70)
        for row in regional_summary:
            print(f"{row[0]:<16} | {row[1]:>9} | ${row[2]:>8} | ${row[3]:>8.2f} | {row[4]:>10.1f}% | {row[5]:>9}")
        
        print("\n🎯 Key Pricing Insights:")
        # Price sensitivity insights
        high_sensitivity = client.execute('''
            SELECT country, region, price_sensitivity_score 
            FROM mart.g2_regional_pricing_insights_shi 
            WHERE price_sensitivity_score > 80 
            ORDER BY price_sensitivity_score DESC
        ''')
        
        if high_sensitivity:
            print("   💰 Price-Sensitive Markets (>80% low-price purchases):")
            for row in high_sensitivity:
                print(f"      {row[0]} ({row[1]}): {row[2]}% prefer $0.99 tracks")
        
        low_sensitivity = client.execute('''
            SELECT country, region, price_sensitivity_score 
            FROM mart.g2_regional_pricing_insights_shi 
            WHERE price_sensitivity_score < 50 
            ORDER BY price_sensitivity_score ASC
        ''')
        
        if low_sensitivity:
            print("   💎 Premium Markets (<50% low-price purchases):")
            for row in low_sensitivity:
                print(f"      {row[0]} ({row[1]}): {row[2]}% prefer $0.99 tracks")
        
        print("\n🎉 Regional Pricing Insights deployment complete!")
        print("   📍 Database: mart")
        print("   📊 Table: g2_regional_pricing_insights_shi")
        print("   📈 Ready for Metabase analysis!")
        
    except Exception as e:
        print(f"❌ Error during deployment: {e}")
        raise

if __name__ == "__main__":
    deploy_simple_pricing_insights()