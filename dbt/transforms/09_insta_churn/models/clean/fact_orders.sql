-- clean/fact_orders.sql
-- 3NF: Order header entity with proper normalization
-- PK: order_id
-- FK: user_id 
-- Atomic values, no transitive dependencies

{{ config(materialized='table', schema='clean') }}

SELECT 
    CAST(order_id AS UInt32) AS order_id,
    CAST(user_id AS UInt32) AS user_id,
    
    -- Order sequence and timing
    CAST(order_number AS UInt32) AS order_number,
    CAST(order_dow AS UInt8) AS order_day_of_week,
    CAST(order_hour_of_day AS UInt8) AS order_hour_of_day,
    
    -- Days since previous order (handle nulls)
    CASE 
        WHEN days_since_prior_order = 'nan' THEN NULL
        ELSE CAST(days_since_prior_order AS Float32)
    END AS days_since_prior_order,
    
    -- Dataset split
    eval_set AS evaluation_set,
    
    -- Derived temporal attributes
    CASE order_dow 
        WHEN '0' THEN 'Sunday'
        WHEN '1' THEN 'Monday'  
        WHEN '2' THEN 'Tuesday'
        WHEN '3' THEN 'Wednesday'
        WHEN '4' THEN 'Thursday'
        WHEN '5' THEN 'Friday'
        WHEN '6' THEN 'Saturday'
        ELSE 'Unknown'
    END AS order_day_name,
    
    CASE 
        WHEN CAST(order_hour_of_day AS UInt8) BETWEEN 6 AND 11 THEN 'Morning'
        WHEN CAST(order_hour_of_day AS UInt8) BETWEEN 12 AND 17 THEN 'Afternoon'
        WHEN CAST(order_hour_of_day AS UInt8) BETWEEN 18 AND 21 THEN 'Evening'
        ELSE 'Night'
    END AS order_time_of_day,
    
    -- Weekend flag
    CASE 
        WHEN CAST(order_dow AS UInt8) IN (0, 6) THEN 1
        ELSE 0
    END AS is_weekend,
    
    -- Add metadata
    now() AS created_at
    
FROM {{ source('raw', 'raw___insta_orders') }}
WHERE order_id IS NOT NULL 
  AND user_id IS NOT NULL