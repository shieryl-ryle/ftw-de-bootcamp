-- models/clean/g2_v2_users_3nf.sql
-- 3NF: User/Customer entity (extracted from orders)
-- PK: user_id
-- Aggregated customer attributes (no transitive dependencies)

{{ config(materialized='table', schema='clean') }}

SELECT 
    CAST(user_id AS UInt32) AS user_id,
    
    -- Derived customer attributes from order behavior
    COUNT(DISTINCT order_id) AS total_orders,
    MIN(CAST(order_number AS UInt16)) AS first_order_number,
    MAX(CAST(order_number AS UInt16)) AS last_order_number,
    
    -- Temporal behavior patterns
    COUNT(DISTINCT order_dow) AS unique_order_days_count,
    COUNT(DISTINCT order_hour_of_day) AS unique_order_hours_count,
    
    -- Ordering frequency
    AVG(CASE 
        WHEN days_since_prior_order != 'nan' AND days_since_prior_order IS NOT NULL 
        THEN CAST(days_since_prior_order AS Float32) 
        ELSE NULL 
    END) AS avg_days_between_orders,
    
    -- Customer lifecycle stage
    CASE 
        WHEN COUNT(DISTINCT order_id) = 1 THEN 'One-Time'
        WHEN COUNT(DISTINCT order_id) BETWEEN 2 AND 5 THEN 'New'  
        WHEN COUNT(DISTINCT order_id) BETWEEN 6 AND 20 THEN 'Regular'
        WHEN COUNT(DISTINCT order_id) BETWEEN 21 AND 50 THEN 'Loyal'
        ELSE 'Champion'
    END AS customer_segment,
    
    -- Data source tracking
    COUNT(CASE WHEN eval_set = 'train' THEN 1 END) AS train_orders,
    COUNT(CASE WHEN eval_set = 'prior' THEN 1 END) AS prior_orders,
    
    -- Metadata
    now() AS created_at,
    'g2_v2_3nf' AS normalization_tag
    
FROM {{ source('raw', 'raw___insta_orders') }}
WHERE user_id IS NOT NULL
GROUP BY user_id