-- models/mart/g2_v2_department_aisle_performance.sql
-- BUSINESS ANALYTICS #2: Department & Aisle Performance
-- Analyzes performance at category and sub-category level

{{ config(materialized='view', schema='mart') }}

SELECT 
    -- Category hierarchy
    p.department_id,
    p.department_name,
    p.aisle_id,
    p.aisle_name,
    
    -- Volume metrics
    COUNT(*) AS total_orders,
    COUNT(DISTINCT f.product_id) AS unique_products,
    COUNT(DISTINCT f.customer_id) AS unique_customers,
    COUNT(DISTINCT f.order_id) AS unique_transactions,
    
    -- Performance metrics
    SUM(f.is_reorder) AS total_reorders,
    ROUND(100.0 * SUM(f.is_reorder) / COUNT(*), 2) AS reorder_rate_pct,
    
    -- Customer engagement
    ROUND(COUNT(*) / COUNT(DISTINCT f.customer_id), 2) AS avg_orders_per_customer,
    ROUND(COUNT(DISTINCT f.product_id) / COUNT(DISTINCT f.customer_id), 2) AS avg_products_per_customer,
    
    -- Market share within department
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (PARTITION BY p.department_id), 2) AS dept_market_share_pct,
    
    -- Rankings
    ROW_NUMBER() OVER (ORDER BY COUNT(*) DESC) AS overall_volume_rank,
    ROW_NUMBER() OVER (PARTITION BY p.department_id ORDER BY COUNT(*) DESC) AS dept_aisle_rank,
    ROW_NUMBER() OVER (ORDER BY ROUND(100.0 * SUM(f.is_reorder) / COUNT(*), 2) DESC) AS reorder_rank,
    
    -- Performance categories
    CASE 
        WHEN COUNT(*) >= 10000 THEN 'High Volume'
        WHEN COUNT(*) >= 5000 THEN 'Medium Volume'
        WHEN COUNT(*) >= 1000 THEN 'Low Volume'
        ELSE 'Very Low Volume'
    END AS volume_category,
    
    CASE 
        WHEN ROUND(100.0 * SUM(f.is_reorder) / COUNT(*), 2) >= 60 THEN 'High Loyalty'
        WHEN ROUND(100.0 * SUM(f.is_reorder) / COUNT(*), 2) >= 40 THEN 'Medium Loyalty'
        ELSE 'Low Loyalty'
    END AS loyalty_category,
    
    -- Version tracking
    'g2_v2' AS version_tag,
    now() AS created_at
    
FROM {{ ref('g2_v2_fact_orders') }} f
INNER JOIN {{ ref('g2_v2_dim_products') }} p 
    ON f.product_id = p.product_id
GROUP BY 
    p.department_id,
    p.department_name,
    p.aisle_id,
    p.aisle_name
ORDER BY total_orders DESC