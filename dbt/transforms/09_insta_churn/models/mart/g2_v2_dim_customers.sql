-- models/mart/g2_v2_dim_customers.sql  
-- MART LAYER: Customer dimension extracted and derived from orders
-- Dimensional Modeling: Customer entity with behavioral attributes
-- Key for customer churn analysis

{{ config(materialized='view', schema='mart') }}

SELECT 
    -- Customer dimension primary key
    user_id AS customer_id,
    
    -- Customer behavioral metrics (derived from orders)
    COUNT(*) AS total_orders,
    MIN(order_number) AS first_order_number,
    MAX(order_number) AS last_order_number,
    MAX(order_number) - MIN(order_number) + 1 AS customer_lifespan_orders,
    
    -- Temporal patterns
    COUNT(DISTINCT order_dow) AS unique_order_days,
    COUNT(DISTINCT order_hour_of_day) AS unique_order_hours,
    
    -- Most common ordering patterns (using simple mode functions)
    argMax(order_dow, 1) AS preferred_order_dow,
    argMax(order_hour_of_day, 1) AS preferred_order_hour,
    
    -- Ordering frequency metrics
    AVG(days_since_prior_order) AS avg_days_between_orders,
    MIN(days_since_prior_order) AS min_days_between_orders,
    MAX(days_since_prior_order) AS max_days_between_orders,
    
    -- Customer segmentation flags
    CASE 
        WHEN COUNT(*) >= 50 THEN 'High Frequency'
        WHEN COUNT(*) >= 20 THEN 'Medium Frequency' 
        WHEN COUNT(*) >= 10 THEN 'Low Frequency'
        ELSE 'Very Low Frequency'
    END AS frequency_segment,
    
    CASE 
        WHEN AVG(days_since_prior_order) <= 7 THEN 'Weekly'
        WHEN AVG(days_since_prior_order) <= 14 THEN 'Bi-Weekly'
        WHEN AVG(days_since_prior_order) <= 30 THEN 'Monthly'
        ELSE 'Irregular'
    END AS ordering_pattern,
    
    -- Metadata
    MAX(cleaned_at) AS last_updated,
    'g2_v2' AS version_tag
    
FROM {{ ref('g2_v2_cleaned_orders') }}
WHERE user_id IS NOT NULL
GROUP BY user_id