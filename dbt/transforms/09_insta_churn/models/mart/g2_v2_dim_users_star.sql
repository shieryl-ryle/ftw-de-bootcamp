-- models/mart/g2_v2_dim_users_star.sql  
-- STAR SCHEMA: User/Customer dimension
-- Includes behavioral segmentation and customer attributes
-- PK: user_id
-- Materialized as TABLE for Metabase dashboard performance

{{ config(
    materialized='table', 
    schema='mart',
    order_by='customer_id'
) }}

SELECT 
    -- Customer identifiers
    user_id AS customer_id,
    user_id, -- Keep original for FK relationships
    
    -- Customer metrics
    total_orders,
    first_order_number,
    last_order_number,
    unique_order_days_count,
    unique_order_hours_count,
    avg_days_between_orders,
    train_orders,
    prior_orders,
    
    -- Customer segmentation 
    customer_segment,
    
    -- Enhanced segmentation based on behavior
    CASE 
        WHEN total_orders >= 100 THEN 'VIP'
        WHEN total_orders >= 50 THEN 'Platinum'
        WHEN total_orders >= 20 THEN 'Gold' 
        WHEN total_orders >= 10 THEN 'Silver'
        WHEN total_orders >= 5 THEN 'Bronze'
        ELSE 'New'
    END AS loyalty_tier,
    
    CASE 
        WHEN avg_days_between_orders <= 7 THEN 'Weekly Shopper'
        WHEN avg_days_between_orders <= 14 THEN 'Bi-Weekly Shopper'
        WHEN avg_days_between_orders <= 30 THEN 'Monthly Shopper'
        ELSE 'Occasional Shopper'
    END AS shopping_frequency,
    
    -- Customer lifetime value proxy
    CASE 
        WHEN total_orders >= 50 AND avg_days_between_orders <= 14 THEN 'High Value'
        WHEN total_orders >= 20 AND avg_days_between_orders <= 30 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS clv_segment,
    
    -- Engagement indicators
    CASE 
        WHEN unique_order_days_count >= 5 THEN 'High Engagement'
        WHEN unique_order_days_count >= 3 THEN 'Medium Engagement'
        ELSE 'Low Engagement'
    END AS engagement_level,
    
    -- Metadata
    created_at,
    'star_schema' AS schema_type
    
FROM {{ ref('g2_v2_users_3nf') }}