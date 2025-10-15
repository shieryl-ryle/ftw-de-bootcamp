-- clean/dim_customers.sql
-- 3NF: Extract customer entity from orders table
-- PK: user_id
-- Aggregates customer-level attributes from order history

{{ config(materialized='table', schema='clean') }}

WITH customer_summary AS (
    SELECT 
        CAST(user_id AS UInt32) AS user_id,
        
        -- Customer behavior metrics
        COUNT(DISTINCT order_id) AS total_orders,
        MIN(CAST(order_number AS UInt32)) AS first_order_number,
        MAX(CAST(order_number AS UInt32)) AS last_order_number,
        
        -- Timing patterns  
        MODE(CAST(order_dow AS UInt8)) AS preferred_order_dow,
        MODE(CAST(order_hour_of_day AS UInt8)) AS preferred_order_hour,
        
        -- Order frequency
        AVG(CAST(CASE WHEN days_since_prior_order != 'nan' 
                      THEN days_since_prior_order 
                      ELSE NULL END AS Float32)) AS avg_days_between_orders,
                      
        -- Recency
        MAX(CASE WHEN eval_set = 'train' THEN CAST(order_number AS UInt32) ELSE 0 END) AS last_train_order,
        
        -- Data quality
        COUNT(*) AS total_order_records,
        now() AS created_at
        
    FROM {{ source('raw', 'raw___insta_orders') }}
    WHERE user_id IS NOT NULL
    GROUP BY CAST(user_id AS UInt32)
)

SELECT 
    user_id,
    total_orders,
    first_order_number,  
    last_order_number,
    preferred_order_dow,
    preferred_order_hour,
    avg_days_between_orders,
    last_train_order,
    
    -- Customer segmentation flags
    CASE 
        WHEN total_orders >= 50 THEN 'High Frequency'
        WHEN total_orders >= 10 THEN 'Medium Frequency'  
        ELSE 'Low Frequency'
    END AS customer_frequency_segment,
    
    CASE
        WHEN avg_days_between_orders <= 7 THEN 'Weekly'
        WHEN avg_days_between_orders <= 14 THEN 'Bi-weekly' 
        WHEN avg_days_between_orders <= 30 THEN 'Monthly'
        ELSE 'Infrequent'
    END AS customer_cadence_segment,
    
    created_at
    
FROM customer_summary
WHERE total_orders > 0