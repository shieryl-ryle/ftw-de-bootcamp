-- models/clean/g2_v2_cleaned_orders.sql
-- CLEAN LAYER: Clean and standardize order data
-- Responsibility: Data types, null handling, basic validation
-- Extract customer info will happen in MART dimensional modeling

{{ config(materialized='table', schema='clean') }}

SELECT 
    -- Primary identifiers
    CAST(order_id AS UInt32) AS order_id,
    CAST(user_id AS UInt32) AS user_id,
    
    -- Order sequence and metadata
    TRIM(eval_set) AS eval_set,
    CAST(order_number AS UInt16) AS order_number,
    
    -- Temporal data - clean and validate
    CAST(order_dow AS UInt8) AS order_dow,
    CAST(order_hour_of_day AS UInt8) AS order_hour_of_day,
    
    -- Handle days_since_prior_order (can be 'nan' string)
    CASE 
        WHEN days_since_prior_order = 'nan' OR days_since_prior_order IS NULL THEN NULL
        WHEN days_since_prior_order = '' THEN NULL
        ELSE CAST(days_since_prior_order AS Nullable(UInt16))
    END AS days_since_prior_order,
    
    -- Add metadata
    now() AS cleaned_at,
    'g2_v2' AS version_tag
    
FROM {{ source('raw', 'raw___insta_orders') }}
WHERE 
    -- Data quality filters
    order_id IS NOT NULL
    AND user_id IS NOT NULL
    AND eval_set IS NOT NULL
    AND order_number IS NOT NULL
    AND order_dow BETWEEN 0 AND 6  -- Valid day of week
    AND order_hour_of_day BETWEEN 0 AND 23  -- Valid hour