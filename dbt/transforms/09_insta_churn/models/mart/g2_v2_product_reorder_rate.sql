-- models/mart/g2_v2_product_reorder_rate.sql
-- BUSINESS ANALYTICS #4: Product Reorder Rate Analysis
-- Identifies products with highest customer loyalty and repurchase behavior

{{ config(materialized='view', schema='mart') }}

SELECT 
    -- Product identification
    f.product_id,
    p.product_name,
    p.department_name,
    p.aisle_name,
    
    -- Order volume metrics
    COUNT(*) AS total_orders,
    COUNT(DISTINCT f.customer_id) AS unique_customers,
    COUNT(DISTINCT f.order_id) AS unique_transactions,
    
    -- Reorder analysis
    SUM(CASE WHEN f.reordered = 0 THEN 1 ELSE 0 END) AS first_time_orders,
    SUM(CASE WHEN f.reordered = 1 THEN 1 ELSE 0 END) AS reorders,
    
    -- Reorder rates
    ROUND(100.0 * SUM(f.reordered) / COUNT(*), 2) AS overall_reorder_rate_pct,
    ROUND(100.0 * SUM(f.reordered) / NULLIF(SUM(CASE WHEN f.reordered = 0 THEN 1 ELSE 0 END), 0), 2) AS reorder_conversion_rate_pct,
    
    -- Customer loyalty metrics
    ROUND(COUNT(*) / COUNT(DISTINCT f.customer_id), 2) AS avg_orders_per_customer,
    ROUND(SUM(f.reordered) / COUNT(DISTINCT f.customer_id), 2) AS avg_reorders_per_customer,
    
    -- Repeat purchase patterns
    COUNT(DISTINCT CASE WHEN f.reordered = 1 THEN f.customer_id END) AS customers_with_reorders,
    ROUND(100.0 * COUNT(DISTINCT CASE WHEN f.reordered = 1 THEN f.customer_id END) / COUNT(DISTINCT f.customer_id), 2) AS customer_retention_rate_pct,
    
    -- Category benchmarking (simplified for ClickHouse)
    ROUND(100.0 * SUM(f.reordered) / COUNT(*), 2) AS reorder_rate_pct_calc,
    
    -- Rankings and classifications
    ROW_NUMBER() OVER (ORDER BY ROUND(100.0 * SUM(f.reordered) / COUNT(*), 2) DESC) AS reorder_rate_rank,
    ROW_NUMBER() OVER (PARTITION BY p.department_name ORDER BY ROUND(100.0 * SUM(f.reordered) / COUNT(*), 2) DESC) AS dept_reorder_rank,
    
    -- Reorder performance categories
    CASE 
        WHEN ROUND(100.0 * SUM(f.reordered) / COUNT(*), 2) >= 70 THEN 'Very High Loyalty'
        WHEN ROUND(100.0 * SUM(f.reordered) / COUNT(*), 2) >= 50 THEN 'High Loyalty'
        WHEN ROUND(100.0 * SUM(f.reordered) / COUNT(*), 2) >= 30 THEN 'Medium Loyalty'
        WHEN ROUND(100.0 * SUM(f.reordered) / COUNT(*), 2) >= 15 THEN 'Low Loyalty'
        ELSE 'Very Low Loyalty'
    END AS loyalty_tier,
    
    -- Business implications
    CASE 
        WHEN ROUND(100.0 * SUM(f.reordered) / COUNT(*), 2) >= 60 AND COUNT(*) >= 1000 THEN 'Core Staple Product'
        WHEN ROUND(100.0 * SUM(f.reordered) / COUNT(*), 2) >= 40 AND COUNT(*) >= 500 THEN 'Regular Purchase Item' 
        WHEN ROUND(100.0 * SUM(f.reordered) / COUNT(*), 2) < 20 AND COUNT(*) >= 1000 THEN 'One-Time Purchase'
        WHEN COUNT(*) < 100 THEN 'Niche Product'
        ELSE 'Occasional Purchase'
    END AS product_category,
    
    -- Version tracking
    'g2_v2' AS version_tag,
    now() AS created_at
    
FROM {{ ref('g2_v2_fact_orders') }} f
INNER JOIN {{ ref('g2_v2_dim_products') }} p 
    ON f.product_id = p.product_id
GROUP BY 
    f.product_id,
    p.product_name,
    p.department_name,
    p.aisle_name
HAVING COUNT(*) >= 10  -- Filter for statistically significant products
ORDER BY overall_reorder_rate_pct DESC, total_orders DESC