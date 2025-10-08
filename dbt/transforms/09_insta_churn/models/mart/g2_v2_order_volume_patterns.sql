-- models/mart/g2_v2_order_volume_patterns.sql  
-- BUSINESS ANALYTICS #3: Order Volume Patterns (Day/Hour)
-- Analyzes temporal ordering patterns for demand forecasting

{{ config(materialized='view', schema='mart') }}

SELECT 
    -- Temporal dimensions
    order_dow,
    CASE order_dow
        WHEN 0 THEN 'Sunday'
        WHEN 1 THEN 'Monday' 
        WHEN 2 THEN 'Tuesday'
        WHEN 3 THEN 'Wednesday'
        WHEN 4 THEN 'Thursday'
        WHEN 5 THEN 'Friday'
        WHEN 6 THEN 'Saturday'
    END AS day_name,
    
    order_hour_of_day,
    CASE 
        WHEN order_hour_of_day BETWEEN 6 AND 11 THEN 'Morning (6-11)'
        WHEN order_hour_of_day BETWEEN 12 AND 17 THEN 'Afternoon (12-17)'
        WHEN order_hour_of_day BETWEEN 18 AND 22 THEN 'Evening (18-22)'
        ELSE 'Night/Early (23-5)'
    END AS time_period,
    
    -- Volume metrics
    COUNT(DISTINCT order_id) AS unique_orders,
    COUNT(*) AS total_items_ordered,
    COUNT(DISTINCT customer_id) AS unique_customers,
    
    -- Average basket metrics
    ROUND(COUNT(*) / COUNT(DISTINCT order_id), 2) AS avg_items_per_order,
    
    -- Reorder patterns
    SUM(is_reorder) AS total_reorders,
    ROUND(100.0 * SUM(is_reorder) / COUNT(*), 2) AS reorder_rate_pct,
    
    -- Market share by time
    ROUND(100.0 * COUNT(DISTINCT order_id) / SUM(COUNT(DISTINCT order_id)) OVER (), 2) AS order_share_pct,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 2) AS item_share_pct,
    
    -- Day of week analysis  
    ROUND(100.0 * COUNT(DISTINCT order_id) / SUM(COUNT(DISTINCT order_id)) OVER (PARTITION BY order_dow), 2) AS hour_share_within_day_pct,
    
    -- Rankings
    ROW_NUMBER() OVER (ORDER BY COUNT(DISTINCT order_id) DESC) AS order_volume_rank,
    ROW_NUMBER() OVER (PARTITION BY order_dow ORDER BY COUNT(DISTINCT order_id) DESC) AS hourly_rank_within_day,
    
    -- Peak indicators
    CASE 
        WHEN ROW_NUMBER() OVER (ORDER BY COUNT(DISTINCT order_id) DESC) <= 5 THEN 'Peak Hour'
        WHEN ROW_NUMBER() OVER (ORDER BY COUNT(DISTINCT order_id) DESC) <= 24 THEN 'High Volume'
        WHEN ROW_NUMBER() OVER (ORDER BY COUNT(DISTINCT order_id) DESC) <= 48 THEN 'Medium Volume'
        ELSE 'Low Volume'
    END AS volume_category,
    
    -- Version tracking
    'g2_v2' AS version_tag,
    now() AS created_at
    
FROM {{ ref('g2_v2_fact_orders') }}
GROUP BY order_dow, order_hour_of_day
ORDER BY unique_orders DESC