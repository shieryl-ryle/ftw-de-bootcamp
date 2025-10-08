-- models/clean/g2_v2_orders_3nf.sql
-- 3NF: Order entity (header information only)
-- PK: order_id
-- FK: user_id
-- No line-item details (separated into order_products)

{{ config(materialized='table', schema='clean') }}

SELECT 
    -- Primary Key
    CAST(order_id AS UInt32) AS order_id,
    
    -- Foreign Key to users
    CAST(user_id AS UInt32) AS user_id,
    
    -- Order sequence and metadata  
    CAST(order_number AS UInt16) AS order_number,
    TRIM(eval_set) AS eval_set,
    
    -- Temporal attributes (atomic values)
    CAST(order_dow AS UInt8) AS order_dow,
    CAST(order_hour_of_day AS UInt8) AS order_hour_of_day,
    
    -- Days since prior order (handle 'nan' values)
    CASE 
        WHEN days_since_prior_order = 'nan' OR days_since_prior_order IS NULL THEN NULL
        WHEN days_since_prior_order = '' THEN NULL
        ELSE CAST(days_since_prior_order AS Nullable(UInt16))
    END AS days_since_prior_order,
    
    -- Derived temporal attributes
    CASE 
        WHEN CAST(order_dow AS UInt8) IN (0, 6) THEN 1 
        ELSE 0 
    END AS is_weekend,
    CASE 
        WHEN CAST(order_hour_of_day AS UInt8) BETWEEN 6 AND 11 THEN 'Morning'
        WHEN CAST(order_hour_of_day AS UInt8) BETWEEN 12 AND 17 THEN 'Afternoon'  
        WHEN CAST(order_hour_of_day AS UInt8) BETWEEN 18 AND 22 THEN 'Evening'
        ELSE 'Night'
    END AS time_of_day,
    
    -- Metadata
    now() AS created_at,
    'g2_v2_3nf' AS normalization_tag
    
FROM {{ source('raw', 'raw___insta_orders') }}
WHERE order_id IS NOT NULL
  AND user_id IS NOT NULL
  AND order_number IS NOT NULL
  AND eval_set IS NOT NULL
  AND order_dow BETWEEN 0 AND 6
  AND order_hour_of_day BETWEEN 0 AND 23