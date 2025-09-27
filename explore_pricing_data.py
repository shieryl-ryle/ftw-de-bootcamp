#!/usr/bin/env python3
"""
Explore Regional Pricing Data Structure
Analyze the pricing information available in Chinook database
"""

from clickhouse_driver import Client

def explore_pricing_data():
    """Explore pricing data structure for regional insights."""
    
    client = Client(
        host='54.87.106.52',
        port=9000,
        user='ftw_user',
        password='ftw_pass',
        database='raw',
        secure=False
    )
    
    print("🔍 Exploring Regional Pricing Data Structure...\n")
    
    # 1. Check track pricing structure
    print("📀 Track Pricing Analysis:")
    track_pricing = client.execute('''
        SELECT 
            MIN(unit_price) as min_price,
            MAX(unit_price) as max_price,
            AVG(unit_price) as avg_price,
            COUNT(DISTINCT unit_price) as unique_prices,
            COUNT(*) as total_tracks
        FROM chinook___track_shi
        WHERE unit_price IS NOT NULL
    ''')
    
    for row in track_pricing:
        print(f"  Min Price: ${row[0]}")
        print(f"  Max Price: ${row[1]}")
        print(f"  Avg Price: ${row[2]:.2f}")
        print(f"  Unique Prices: {row[3]}")
        print(f"  Total Tracks: {row[4]}")
    
    # 2. Check invoice line pricing
    print("\n💰 Invoice Line Pricing Analysis:")
    invoice_pricing = client.execute('''
        SELECT 
            MIN(unit_price) as min_price,
            MAX(unit_price) as max_price,
            AVG(unit_price) as avg_price,
            COUNT(DISTINCT unit_price) as unique_prices,
            COUNT(*) as total_sales
        FROM chinook___invoice_line_shi
        WHERE unit_price IS NOT NULL
    ''')
    
    for row in invoice_pricing:
        print(f"  Min Sale Price: ${row[0]}")
        print(f"  Max Sale Price: ${row[1]}")
        print(f"  Avg Sale Price: ${row[2]:.2f}")
        print(f"  Unique Sale Prices: {row[3]}")
        print(f"  Total Sales: {row[4]}")
    
    # 3. Regional pricing patterns
    print("\n🌍 Regional Pricing Patterns:")
    regional_patterns = client.execute('''
        SELECT 
            c.country,
            COUNT(DISTINCT il.unit_price) as unique_prices_bought,
            MIN(il.unit_price) as min_purchase_price,
            MAX(il.unit_price) as max_purchase_price,
            AVG(il.unit_price) as avg_purchase_price,
            COUNT(il.invoice_line_id) as total_purchases,
            SUM(il.unit_price * il.quantity) as total_spent
        FROM chinook___invoice_line_shi il
        JOIN chinook___invoice_shi i ON il.invoice_id = i.invoice_id
        JOIN chinook___customer_shi c ON i.customer_id = c.customer_id
        GROUP BY c.country
        HAVING total_purchases > 5
        ORDER BY total_spent DESC
        LIMIT 10
    ''')
    
    print("Country          | Unique Prices | Min    | Max    | Avg    | Purchases | Total Spent")
    print("-" * 85)
    for row in regional_patterns:
        print(f"{row[0]:<16} | {row[1]:>12} | ${row[2]:<5} | ${row[3]:<5} | ${row[4]:<6.2f} | {row[5]:>9} | ${row[6]:>10.2f}")
    
    # 4. Genre pricing patterns
    print("\n🎵 Genre Pricing Patterns:")
    genre_pricing = client.execute('''
        SELECT 
            g.name as genre,
            COUNT(DISTINCT t.unit_price) as unique_track_prices,
            MIN(t.unit_price) as min_track_price,
            MAX(t.unit_price) as max_track_price,
            AVG(t.unit_price) as avg_track_price,
            COUNT(t.track_id) as total_tracks
        FROM chinook___track_shi t
        JOIN chinook___genre_shi g ON t.genre_id = g.genre_id
        GROUP BY g.name
        HAVING total_tracks > 10
        ORDER BY avg_track_price DESC
        LIMIT 10
    ''')
    
    print("Genre               | Unique Prices | Min    | Max    | Avg    | Tracks")
    print("-" * 70)
    for row in genre_pricing:
        print(f"{row[0]:<19} | {row[1]:>12} | ${row[2]:<5} | ${row[3]:<5} | ${row[4]:<6.2f} | {row[5]:>6}")
    
    # 5. Check if there are regional price differences
    print("\n📊 Regional Price Analysis Summary:")
    summary = client.execute('''
        SELECT 
            COUNT(DISTINCT c.country) as total_countries,
            COUNT(DISTINCT il.unit_price) as global_unique_prices,
            MIN(il.unit_price) as global_min_price,
            MAX(il.unit_price) as global_max_price
        FROM chinook___invoice_line_shi il
        JOIN chinook___invoice_shi i ON il.invoice_id = i.invoice_id
        JOIN chinook___customer_shi c ON i.customer_id = c.customer_id
    ''')
    
    for row in summary:
        print(f"  Total Countries with Sales: {row[0]}")
        print(f"  Global Unique Prices: {row[1]}")
        print(f"  Global Price Range: ${row[2]} - ${row[3]}")

if __name__ == "__main__":
    explore_pricing_data()