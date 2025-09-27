# Chinook Music Store - Business Analytics Documentation

## 📊 Business Intelligence Queries & Analysis Themes

This document provides comprehensive coverage of all analytical themes for the Chinook music store database, including completed implementations and planned future analyses.

---

## 🎯 **ANALYTICAL THEMES OVERVIEW**

### ✅ **COMPLETED ANALYSES**
1. [Top Revenue by Genre per Country](#1-top-revenue-by-genre-per-country-✅)
2. [Regional Pricing Insights](#2-regional-pricing-insights-✅)
3. [Popular Tracks by Quantity Sold](#5-popular-tracks-by-quantity-sold-✅)

### ✅ **ADDITIONAL COMPLETED ANALYSES**
4. [Customer Segmentation by Spending Tier](#3-customer-segmentation-by-spending-tier-✅)
5. [Monthly Sales Trend](#4-monthly-sales-trend-✅)
6. [Employee Sales Performance](#6-employee-sales-performance-✅)

---

## 1. TOP REVENUE BY GENRE PER COUNTRY ✅

### Business Question:
*"Which music genres generate the highest revenue in each country?"*

### Business Value:
- Market-specific marketing campaign planning
- Genre portfolio optimization by geography
- International expansion decision support
- Regional music preference insights

### Implementation Status: **COMPLETED**

### Query:
```sql
SELECT 
    country,
    genre_name,
    total_revenue,
    unique_customers,
    total_tracks_sold,
    total_quantity
FROM mart.g2_top_revenue_by_genre_per_country_shi
ORDER BY country, total_revenue DESC;
```

### Key Insights:
- **Coverage**: 24 countries, 25 music genres
- **Top Markets**: USA ($523), Canada ($304), France ($195)
- **Leading Genres**: Rock, Alternative & Punk, Latin
- **Total Records**: 237 country-genre combinations

### Use Cases:
- Marketing budget allocation by country-genre
- Inventory planning for regional markets
- Partnership opportunities with local artists
- Competition analysis by market segment

---

## 2. REGIONAL PRICING INSIGHTS ✅

### Business Question:
*"How do pricing patterns and customer price sensitivity vary across different regions?"*

### Business Value:
- Regional pricing strategy optimization
- Price elasticity understanding
- Customer value maximization
- Market penetration analysis

### Implementation Status: **COMPLETED**

### Query:
```sql
SELECT 
    country,
    region,
    total_revenue,
    avg_price_paid,
    price_sensitivity_score,
    unique_customers,
    avg_spending_per_customer
FROM mart.g2_regional_pricing_insights_shi
ORDER BY total_revenue DESC;
```

### Key Insights:
- **Price Sensitivity**: 93%+ customers prefer $0.99 pricing globally
- **Regional Performance**: Europe leads with $1,114 total revenue
- **Customer Value**: Chile shows highest average spending per customer ($46.62)
- **Market Opportunities**: Identified premium pricing acceptance in select markets

### Use Cases:
- Dynamic pricing strategy development
- Premium product positioning by market
- Customer acquisition cost optimization
- Revenue forecasting models

---

## 3. CUSTOMER SEGMENTATION BY SPENDING TIER 🔄

### Business Question:
*"How can we segment customers based on their spending behavior for targeted marketing?"*

### Business Value:
- Personalized marketing campaigns
- Customer lifetime value optimization
- Retention strategy development
- Cross-selling and upselling opportunities

### Implementation Status: **COMPLETED**

### Ready-to-Use Queries for Metabase:

#### 1. Customer Spending Distribution Analysis:
```sql
SELECT
   MIN(total_spend) AS min_spend,
   MAX(total_spend) AS max_spend,
   AVG(total_spend) AS avg_spend,
   COUNT(*) AS total_customers,
   quantile(0.25)(total_spend) AS q1_spend,
   quantile(0.5)(total_spend) AS median_spend,
   quantile(0.75)(total_spend) AS q3_spend
FROM (
   SELECT
       c.customer_key,
       SUM(f.line_amount) AS total_spend
   FROM mart.fact_invoice_line_maryam f
   JOIN mart.dim_customer__maryam c
       ON f.customer_key = c.customer_key
   GROUP BY c.customer_key
) customer_totals;
```

#### 2. Customer Segmentation with Tiers:
```sql
SELECT
   c.customer_key,
   c.first_name,
   c.last_name,
   c.country,
   SUM(f.line_amount) AS total_spend,
   CASE
       WHEN SUM(f.line_amount) >= 130 THEN 'High'
       WHEN SUM(f.line_amount) BETWEEN 115 AND 130 THEN 'Medium'
       ELSE 'Low'
   END AS spending_tier
FROM mart.fact_invoice_line_maryam f
JOIN mart.dim_customer__maryam c
   ON f.customer_key = c.customer_key
GROUP BY c.customer_key, c.first_name, c.last_name, c.country
ORDER BY total_spend DESC;
```

#### 3. Count of Customers per Spending Tier:
```sql
SELECT
   spending_tier,
   COUNT(*) AS customer_count,
   AVG(total_spend) AS avg_spend_in_tier,
   MIN(total_spend) AS min_spend_in_tier,
   MAX(total_spend) AS max_spend_in_tier
FROM (
   SELECT
       c.customer_key,
       SUM(f.line_amount) AS total_spend,
       CASE
           WHEN SUM(f.line_amount) >= 130 THEN 'High'
           WHEN SUM(f.line_amount) BETWEEN 115 AND 130 THEN 'Medium'
           ELSE 'Low'
       END AS spending_tier
   FROM mart.fact_invoice_line_maryam f
   JOIN mart.dim_customer__maryam c
       ON f.customer_key = c.customer_key
   GROUP BY c.customer_key
) t
GROUP BY spending_tier
ORDER BY CASE spending_tier 
    WHEN 'High' THEN 1
    WHEN 'Medium' THEN 2
    WHEN 'Low' THEN 3
END;
```

#### 4. Country-wise Spending Tier Analysis:
```sql
WITH customer_tiers AS (
    SELECT
        c.customer_key,
        c.country,
        SUM(f.line_amount) AS total_spend,
        CASE
            WHEN SUM(f.line_amount) >= 130 THEN 'High'
            WHEN SUM(f.line_amount) BETWEEN 115 AND 130 THEN 'Medium'
            ELSE 'Low'
        END AS spending_tier
    FROM mart.fact_invoice_line_maryam f
    JOIN mart.dim_customer__maryam c
        ON f.customer_key = c.customer_key
    GROUP BY c.customer_key, c.country
)
SELECT
    country,
    spending_tier,
    COUNT(*) AS customers_in_tier,
    AVG(total_spend) AS avg_spend,
    SUM(total_spend) AS total_country_tier_revenue
FROM customer_tiers
GROUP BY country, spending_tier
ORDER BY total_country_tier_revenue DESC;
```

### Planned Insights:
- Customer distribution across High/Medium/Low spending tiers
- Geographic patterns in customer value
- Correlation between spending tier and music preferences
- Retention rates by customer segment

### Use Cases:
- Targeted email marketing campaigns
- Loyalty program tier design
- Customer acquisition strategy
- Personalized product recommendations

---

## 4. MONTHLY SALES TREND ✅

### Business Question:
*"What are the seasonal patterns and growth trends in our monthly sales performance?"*

### Business Value:
- Seasonal inventory planning
- Sales forecasting accuracy
- Marketing campaign timing
- Revenue growth tracking

### Implementation Status: **COMPLETED**

### Ready-to-Use Queries for Metabase:

#### 1. Monthly Sales Trend Analysis:
```sql
SELECT 
    toYear(i.invoice_date) as year,
    toMonth(i.invoice_date) as month,
    CONCAT(toString(toYear(i.invoice_date)), '-', 
           lpad(toString(toMonth(i.invoice_date)), 2, '0')) as year_month,
    COUNT(DISTINCT i.invoice_id) as total_invoices,
    COUNT(DISTINCT i.customer_id) as unique_customers,
    SUM(il.unit_price * il.quantity) as total_revenue,
    SUM(il.quantity) as total_quantity,
    AVG(il.unit_price * il.quantity) as avg_transaction_value,
    COUNT(il.invoice_line_id) as total_line_items
FROM raw.chinook___invoice_shi i
JOIN raw.chinook___invoice_line_shi il ON i.invoice_id = il.invoice_id
GROUP BY toYear(i.invoice_date), toMonth(i.invoice_date)
ORDER BY year, month;
```

#### 2. Seasonal Pattern Analysis:
```sql
SELECT 
    toMonth(i.invoice_date) as month_number,
    CASE toMonth(i.invoice_date)
        WHEN 1 THEN 'January'
        WHEN 2 THEN 'February' 
        WHEN 3 THEN 'March'
        WHEN 4 THEN 'April'
        WHEN 5 THEN 'May'
        WHEN 6 THEN 'June'
        WHEN 7 THEN 'July'
        WHEN 8 THEN 'August'
        WHEN 9 THEN 'September'
        WHEN 10 THEN 'October'
        WHEN 11 THEN 'November'
        WHEN 12 THEN 'December'
    END as month_name,
    CASE 
        WHEN toMonth(i.invoice_date) IN (12, 1, 2) THEN 'Winter'
        WHEN toMonth(i.invoice_date) IN (3, 4, 5) THEN 'Spring'
        WHEN toMonth(i.invoice_date) IN (6, 7, 8) THEN 'Summer'
        WHEN toMonth(i.invoice_date) IN (9, 10, 11) THEN 'Fall'
    END as season,
    COUNT(DISTINCT i.invoice_id) as total_transactions,
    SUM(il.unit_price * il.quantity) as total_revenue,
    AVG(il.unit_price * il.quantity) as avg_transaction_value,
    COUNT(DISTINCT i.customer_id) as unique_customers
FROM raw.chinook___invoice_shi i
JOIN raw.chinook___invoice_line_shi il ON i.invoice_id = il.invoice_id
GROUP BY toMonth(i.invoice_date), month_name, season
ORDER BY month_number;
```

### Key Insights:
- **Monthly Revenue**: Consistent revenue patterns with monthly averages around $37-38
- **Customer Engagement**: 6-7 unique customers per month on average
- **Seasonal Trends**: Revenue patterns show consistency across seasons
- **Transaction Values**: Average transaction values remain stable over time

### Implemented Views:
- `mart.vw_monthly_sales_trend_shi` - Monthly aggregated sales data
- `mart.vw_seasonal_analysis_shi` - Seasonal pattern analysis
- `mart.vw_monthly_growth_rate_shi` - Month-over-month growth calculations

### Use Cases:
- Budget planning and forecasting
- Seasonal marketing campaign planning
- Inventory management optimization
- Performance benchmark setting

---

## 5. POPULAR TRACKS BY QUANTITY SOLD ✅

### Business Question:
*"Which individual tracks are most popular based on sales volume?"*

### Business Value:
- Hit song identification
- Artist performance evaluation
- Playlist curation guidance
- Licensing negotiation insights

### Implementation Status: **COMPLETED**

### Query:
```sql
CREATE OR REPLACE VIEW mart.vw_top_tracks_maryam AS
SELECT
   t.track_key,
   t.track_name,
   al.album_title,
   ar.artist_name,
   SUM(f.quantity) AS total_units_sold
FROM mart.fact_invoice_line_maryam f
JOIN mart.dim_track_maryam t
   ON f.track_key = t.track_key
JOIN mart.dim_album_maryam al
   ON t.album_key = al.album_id
JOIN mart.dim_artist_maryam ar
   ON al.artist_id = ar.artist_id
GROUP BY t.track_key, t.track_name, al.album_title, ar.artist_name
ORDER BY total_units_sold DESC
LIMIT 20;
```

### Key Insights:
- Top 20 tracks by sales volume
- Artist and album performance correlation
- Genre preferences reflected in individual track sales
- Cross-selling opportunities identification

### Use Cases:
- Playlist creation and curation
- Artist royalty negotiations
- Marketing campaign focus tracks
- Recommendation engine training data

---

## 6. EMPLOYEE SALES PERFORMANCE ✅

### Business Question:
*"How do individual employees perform in terms of sales generation and customer management?"*

### Business Value:
- Sales team performance evaluation
- Commission calculation support
- Training needs identification
- Territory optimization

### Implementation Status: **COMPLETED**

### Ready-to-Use Queries for Metabase:

#### 1. Employee Performance Overview:
```sql
SELECT 
    e.employee_id,
    CONCAT(e.first_name, ' ', e.last_name) as employee_name,
    e.title as job_title,
    e.hire_date,
    COUNT(DISTINCT i.invoice_id) as total_sales_transactions,
    COUNT(DISTINCT i.customer_id) as unique_customers_served,
    SUM(il.unit_price * il.quantity) as total_revenue_generated,
    AVG(il.unit_price * il.quantity) as avg_transaction_value,
    SUM(il.quantity) as total_units_sold,
    ROUND(SUM(il.unit_price * il.quantity) / COUNT(DISTINCT i.invoice_id), 2) as avg_revenue_per_sale
FROM raw.chinook___employee_maryam e
LEFT JOIN raw.chinook___customer_maryam c ON e.employee_id = c.support_rep_id
LEFT JOIN raw.chinook___invoice_maryam i ON c.customer_id = i.customer_id
LEFT JOIN raw.chinook___invoice_line_maryam il ON i.invoice_id = il.invoice_id
WHERE e.employee_id IS NOT NULL
GROUP BY e.employee_id, employee_name, e.title, e.hire_date
ORDER BY total_revenue_generated DESC;
```

#### 2. Employee Performance Rankings with Tiers:
```sql
WITH employee_performance AS (
    SELECT 
        e.employee_id,
        CONCAT(e.first_name, ' ', e.last_name) as employee_name,
        e.title as job_title,
        SUM(il.unit_price * il.quantity) as total_revenue_generated,
        COUNT(DISTINCT i.customer_id) as unique_customers_served,
        COUNT(DISTINCT i.invoice_id) as total_sales_transactions
    FROM raw.chinook___employee_maryam e
    LEFT JOIN raw.chinook___customer_maryam c ON e.employee_id = c.support_rep_id
    LEFT JOIN raw.chinook___invoice_maryam i ON c.customer_id = i.customer_id
    LEFT JOIN raw.chinook___invoice_line_maryam il ON i.invoice_id = il.invoice_id
    WHERE e.employee_id IS NOT NULL
    GROUP BY e.employee_id, employee_name, e.title
)
SELECT 
    employee_name,
    job_title,
    total_revenue_generated,
    unique_customers_served,
    total_sales_transactions,
    RANK() OVER (ORDER BY total_revenue_generated DESC) as revenue_rank,
    CASE 
        WHEN total_revenue_generated >= 2000 THEN 'Top Performer'
        WHEN total_revenue_generated >= 1000 THEN 'High Performer'
        WHEN total_revenue_generated >= 100 THEN 'Good Performer'
        WHEN total_revenue_generated > 0 THEN 'Developing'
        ELSE 'No Sales'
    END as performance_tier
FROM employee_performance
ORDER BY total_revenue_generated DESC;
```

#### 3. Employee Customer Relationship Analysis:
```sql
SELECT 
    e.employee_id,
    CONCAT(e.first_name, ' ', e.last_name) as employee_name,
    COUNT(DISTINCT c.customer_id) as total_customers_assigned,
    COUNT(DISTINCT CASE WHEN i.invoice_id IS NOT NULL THEN c.customer_id END) as active_customers,
    COUNT(DISTINCT CASE WHEN i.invoice_id IS NULL THEN c.customer_id END) as inactive_customers,
    ROUND(
        COUNT(DISTINCT CASE WHEN i.invoice_id IS NOT NULL THEN c.customer_id END) * 100.0 / 
        COUNT(DISTINCT c.customer_id), 2
    ) as customer_activation_rate_percent,
    AVG(customer_lifetime_value) as avg_customer_lifetime_value
FROM raw.chinook___employee_maryam e
LEFT JOIN raw.chinook___customer_maryam c ON e.employee_id = c.support_rep_id
LEFT JOIN (
    SELECT 
        customer_id, 
        SUM(il.unit_price * il.quantity) as customer_lifetime_value
    FROM raw.chinook___invoice_maryam i
    JOIN raw.chinook___invoice_line_maryam il ON i.invoice_id = il.invoice_id
    GROUP BY customer_id
) clv ON c.customer_id = clv.customer_id
LEFT JOIN raw.chinook___invoice_maryam i ON c.customer_id = i.customer_id
WHERE c.customer_id IS NOT NULL
GROUP BY e.employee_id, employee_name
ORDER BY avg_customer_lifetime_value DESC;
```

### Key Insights:
- **Top Performers**: Jane Peacock leads with $2,499.12 in revenue and 21 customers
- **Performance Tiers**: Clear separation between high, medium, and low performers
- **Customer Management**: 100% activation rate across all sales support agents
- **Average CLV**: Customer lifetime values range from $116-120 per customer

### Implemented Views:
- `mart.vw_employee_sales_performance_maryam` - Overall performance metrics
- `mart.vw_employee_territory_analysis_maryam` - Territory performance analysis
- `mart.vw_employee_performance_ranking_maryam` - Performance rankings and tiers
- `mart.vw_employee_customer_relationships_maryam` - Customer relationship metrics

### Use Cases:
- Performance review preparation
- Sales incentive program design
- Territory boundary optimization
- Training program development

---

## 📈 **IMPLEMENTATION ROADMAP**

### Phase 1: Foundation (Completed)
- ✅ Core dimensional models: Star Schema
- ✅ Revenue analysis by genre/country
- ✅ Regional pricing insights
- ✅ Popular tracks analysis

### Phase 2: Customer Analytics (Completed)
- ✅ Customer segmentation implementation
- ✅ Customer lifetime value analysis

### Phase 3: Temporal Analytics (Planned)
- ✅ Monthly sales trend analysis
- ✅ Seasonal pattern identification

### Phase 4: Operational Analytics (Planned)
- ✅ Employee performance metrics

---

## 🔧 **TECHNICAL IMPLEMENTATION NOTES**

### Database Schema:
- **Source**: PostgreSQL (Chinook operational database)
- **Target**: ClickHouse (mart layer for analytics)

### Performance Considerations:
- Materialized views for complex aggregations
- Appropriate indexing on frequently queried columns
- Partitioning strategies for time-based analyses
- Caching for dashboard queries

### Data Quality Measures:
- Automated validation scripts
- Data lineage documentation
- Error handling and retry logic
- Monitoring and alerting systems

---

## 📊 **METABASE DASHBOARD INTEGRATION**

### Current Dashboards:

#### 1. **Revenue Performance Dashboard - Top Revenue by Genre per Country**
![Top Revenue by Genre per Country](../../assets/dashboards/Metabase-Top%20Revenue%20by%20Genre%20per%20Country-9_27_2025,%202_40_39%20PM.png)

#### 2. **Pricing Analytics Dashboard - Regional Pricing Insights**  
![Regional Pricing Insights](../../assets/dashboards/Metabase-Regional%20Pricing%20Insights-9_27_2025,%202_40_43%20PM.png)

#### 3. **Customer Segmentation Dashboard**
![Customer Segmentation by Spending Tier](../../assets/dashboards/Metabase-Customer%20Segmentation%20by%20Spending%20Tier-9_27_2025,%202_40_26%20PM.png)

#### 4. **Sales Trend Dashboard - Monthly Sales Analysis** 
![Monthly Sales Trend](../../assets/dashboards/Metabase-Monthly%20Sales%20Trend-9_27_2025,%202_40_49%20PM.png)

#### 5. **Employee Performance Dashboard**
![Employee Sales Performance](../../assets/dashboards/Metabase-Employee%20Sales%20Performance-9_27_2025,%202_40_46%20PM.png)

#### 6. **Track Popularity Dashboard**
![Popular Tracks](../../assets/dashboards/Metabase-Popular%20Tracks.png)

---

*This document serves as the comprehensive guide for all business analytics initiatives within the Chinook music store data warehouse project. Regular updates will be made as new analyses are completed and insights are discovered by Group 2.*