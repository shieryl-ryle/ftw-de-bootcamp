-- models/mart/g2_v2_top_products_sold.sql
-- BUSINESS ANALYTICS #1: Top Products Sold
-- Identifies best-selling products by volume and reorder rate

{{ config(materialized='view', schema='mart') }}

SELECT 
    -- Product information
    f.product_id,
    p.product_name,
    p.department_name,
    p.aisle_name,
    
    -- Volume metrics
    COUNT(*) AS total_orders,
    COUNT(DISTINCT f.customer_id) AS unique_customers,
    COUNT(DISTINCT f.order_id) AS unique_order_transactions,
    
    -- Reorder metrics
    SUM(f.is_reorder) AS reorder_count,
    ROUND(100.0 * SUM(f.is_reorder) / COUNT(*), 2) AS reorder_rate_pct,
    
    -- Customer loyalty metrics
    ROUND(COUNT(*) / COUNT(DISTINCT f.customer_id), 2) AS avg_orders_per_customer,
    
    -- Ranking metrics
    ROW_NUMBER() OVER (ORDER BY COUNT(*) DESC) AS volume_rank,
    ROW_NUMBER() OVER (ORDER BY ROUND(100.0 * SUM(f.is_reorder) / COUNT(*), 2) DESC) AS reorder_rank,
    
    -- Category performance
    ROW_NUMBER() OVER (PARTITION BY p.department_name ORDER BY COUNT(*) DESC) AS dept_volume_rank,
    
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
ORDER BY total_orders DESC