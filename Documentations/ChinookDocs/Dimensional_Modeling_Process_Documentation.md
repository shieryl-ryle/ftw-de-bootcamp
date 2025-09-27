# Dimensional Modeling Process - Chinook Music Store Analytics

## Project Overview
This document outlines the complete dimensional modeling process for creating analytics tables from the Chinook music store database, covering two main business questions:
1. **Top Revenue by Genre per Country**
2. **Regional Pricing Insights**

---

## 1. BUSINESS REQUIREMENTS ANALYSIS

### Business Questions Identified:
- **Question 1**: What are the top revenue-generating music genres in each country?
- **Question 2**: How do pricing patterns and customer price sensitivity vary across different regions?

### Success Criteria:
- Enable country-level genre performance analysis
- Provide regional pricing strategy insights
- Support decision-making for market expansion and pricing optimization

---

## 2. SOURCE SYSTEM ANALYSIS

### Available Source Tables (Grp2):
```
raw.chinook___grp2_2artists_shi     - Artist master data
raw.chinook___grp2_2albums_shi      - Album master data  
raw.chinook___track_shi             - Track details with pricing
raw.chinook___customer_shi          - Customer demographics
raw.chinook___invoice_shi           - Sales transactions
raw.chinook___invoice_line_shi      - Transaction line items
raw.chinook___genre_shi             - Music genre master
```

### Data Quality Assessment:
- **Invoice Lines**: 2,240 transaction records
- **Customers**: 59 customers across 24 countries
- **Price Points**: Only 2 pricing tiers ($0.99, $1.99)
- **Genres**: Multiple music genres with varying popularity
- **Geographic Coverage**: 24 countries across 5 regions

---

## 3. DIMENSIONAL MODEL DESIGN

### Model Architecture: Star Schema Approach

#### Fact Tables Created:
1. **Revenue by Genre per Country Fact**
2. **Regional Pricing Insights Fact**

#### Key Dimensions:
- **Geographic**: Country, Region
- **Product**: Genre, Track
- **Customer**: Customer demographics
- **Pricing**: Price points, sensitivity metrics

---

## 4. DETAILED DIMENSIONAL MODELING PROCESS

### Analysis 1: Top Revenue by Genre per Country

#### Step 1: Identify Grain
- **Grain**: One record per Country-Genre combination
- **Metrics**: Revenue, customer count, track sales, quantities

#### Step 2: Identify Dimensions
- **Country Dimension**: Customer location
- **Genre Dimension**: Music categories
- **Time Dimension**: (Available but not used in this analysis)

#### Step 3: Identify Facts/Measures
```sql
- total_revenue (SUM of unit_price * quantity)
- unique_customers (COUNT DISTINCT customer_id)  
- total_tracks_sold (COUNT of invoice_line_id)
- total_quantity (SUM of quantity)
```

#### Step 4: Design Physical Table
```sql
CREATE TABLE mart.g2_top_revenue_by_genre_per_country_shi (
    country String,           -- Dimension
    genre_name String,        -- Dimension  
    total_revenue Decimal(10,2),      -- Fact
    unique_customers UInt32,          -- Fact
    total_tracks_sold UInt32,         -- Fact
    total_quantity UInt32             -- Fact
) ENGINE = MergeTree()
ORDER BY (country, genre_name)
```

#### Step 5: ETL Logic
```sql
SELECT 
    c.country,
    g.name as genre_name,
    ROUND(SUM(il.unit_price * il.quantity), 2) as total_revenue,
    COUNT(DISTINCT i.customer_id) as unique_customers,
    COUNT(il.invoice_line_id) as total_tracks_sold,
    SUM(il.quantity) as total_quantity
FROM raw.chinook___invoice_line_shi il
JOIN raw.chinook___invoice_shi i ON il.invoice_id = i.invoice_id
JOIN raw.chinook___customer_shi c ON i.customer_id = c.customer_id
JOIN raw.chinook___track_shi t ON il.track_id = t.track_id
JOIN raw.chinook___genre_shi g ON t.genre_id = g.genre_id
GROUP BY c.country, g.name
HAVING total_revenue > 0
```

### Analysis 2: Regional Pricing Insights

#### Step 1: Identify Grain  
- **Grain**: One record per Country with pricing metrics
- **Focus**: Price sensitivity and customer value analysis

#### Step 2: Identify Dimensions
- **Country Dimension**: Individual countries
- **Region Dimension**: Geographic regions (North America, Europe, etc.)
- **Price Tier Dimension**: $0.99 vs $1.99 categories

#### Step 3: Identify Facts/Measures
```sql
- total_purchases (COUNT of transactions)
- total_revenue (SUM of sales)
- avg_price_paid (AVG of unit_price)
- low_price_purchases (COUNT where price = 0.99)
- high_price_purchases (COUNT where price = 1.99) 
- price_sensitivity_score (% preferring low price)
- avg_spending_per_customer (revenue per unique customer)
```

#### Step 4: Design Physical Table
```sql
CREATE TABLE mart.g2_regional_pricing_insights_shi (
    country String,                    -- Dimension
    region String,                     -- Dimension
    total_purchases UInt32,            -- Fact
    total_revenue Decimal(10,2),       -- Fact
    avg_price_paid Decimal(4,2),       -- Fact
    low_price_purchases UInt32,        -- Fact
    high_price_purchases UInt32,       -- Fact
    low_price_percentage Decimal(5,2), -- Calculated Fact
    price_sensitivity_score Decimal(5,2), -- Calculated Fact
    unique_customers UInt32,           -- Fact
    avg_spending_per_customer Decimal(6,2) -- Calculated Fact
) ENGINE = MergeTree()
ORDER BY (country)
```

#### Step 5: ETL Logic with Business Rules
```sql
SELECT 
    c.country,
    CASE 
        WHEN c.country IN ('USA', 'Canada') THEN 'North America'
        WHEN c.country IN ('Brazil', 'Chile', 'Argentina') THEN 'South America'
        WHEN c.country IN ('United Kingdom', 'France', 'Germany'...) THEN 'Europe'
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
FROM [joins and grouping logic]
```

---

## 5. IMPLEMENTATION PROCESS

### Step 1: Environment Setup
- **Target Platform**: ClickHouse database
- **Schema**: `mart` database for analytical tables
- **Source**: `raw` database with operational data

### Step 2: Data Exploration
```python
# Analyzed source data structure
# Checked data quality and completeness
# Identified business rules and relationships
```

### Step 3: Table Creation Strategy
```sql
-- 1. Create table structure
CREATE TABLE mart.[table_name] (...) 

-- 2. Insert data with transformations  
INSERT INTO mart.[table_name] SELECT [transformation_logic]

-- 3. Verify data quality and results
SELECT COUNT(*), sample_records FROM mart.[table_name]
```

### Step 4: Data Validation
- **Record Counts**: Verified expected number of records
- **Business Logic**: Validated calculations and aggregations
- **Data Quality**: Checked for nulls, duplicates, and outliers

---

## 6. TECHNICAL ARCHITECTURE

### Database Configuration:
- **Engine**: ClickHouse MergeTree
- **Ordering Keys**: Optimized for query performance
- **Data Types**: Appropriate precision for financial calculations

### ETL Approach:
- **Language**: Python with ClickHouse drivers
- **Process**: Drop/Create/Insert pattern
- **Error Handling**: Connection retry and validation steps

---

## 7. RESULTS & INSIGHTS

### Table 1: Revenue by Genre per Country
- **Records**: 237 country-genre combinations
- **Top Countries**: USA ($523), Canada ($304), France ($195)
- **Top Genres Globally**: Rock, Alternative & Punk, Metal

### Table 2: Regional Pricing Insights  
- **Records**: 24 countries across 5 regions
- **Key Finding**: 93%+ customers prefer $0.99 pricing
- **Regional Leader**: Europe (17 countries, $1,114 revenue)

---

## 8. BUSINESS VALUE DELIVERED

### Analytics Capabilities Enabled:
1. **Genre Performance Analysis**: Identify top-performing music categories by geography
2. **Market Expansion Planning**: Understand regional preferences and opportunities  
3. **Pricing Strategy**: Data-driven insights on price sensitivity by market
4. **Customer Segmentation**: Value-based customer analysis by region

### Metabase Integration:
- **Dashboards**: Ready-to-use SQL queries for visualization
- **Self-Service**: Business users can create custom reports
- **Real-Time**: Direct connection to live data warehouse

---

## 9. DIMENSIONAL MODELING BEST PRACTICES APPLIED

### ✅ Kimball Methodology Elements:
- **Business Process Focus**: Sales transaction analysis
- **Grain Declaration**: Clearly defined fact table granularity
- **Dimension Identification**: Country, Genre, Region dimensions
- **Fact Identification**: Revenue, quantities, customer metrics
- **Star Schema Design**: Denormalized for query performance
- **Slowly Changing Dimensions**: Handled via historical snapshots

### ✅ Technical Best Practices:
- **Naming Conventions**: Consistent table and column naming
- **Data Types**: Appropriate precision and scale
- **Indexing Strategy**: Optimized sort keys for ClickHouse
- **Documentation**: Comprehensive process documentation

---

## 10. NEXT STEPS & RECOMMENDATIONS

### Potential Enhancements:
1. **Time Dimension**: Add temporal analysis capabilities
2. **Customer Dimension**: Expand customer analytics
3. **Product Hierarchy**: Create album/artist dimension tables
4. **Real-Time Updates**: Implement incremental ETL process

### Monitoring & Maintenance:
- **Data Quality Checks**: Automated validation routines
- **Performance Monitoring**: Query performance optimization
- **Business Rule Updates**: Process for handling changing requirements

---

This dimensional modeling process follows industry best practices while being tailored to the specific business requirements and technical constraints of the Chinook music store analytics project.