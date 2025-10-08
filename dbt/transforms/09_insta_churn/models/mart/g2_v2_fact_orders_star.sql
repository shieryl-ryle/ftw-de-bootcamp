-- models/mart/g2_v2_fact_orders_star.sql
-- STAR SCHEMA: Order header fact table
-- Grain: One row per order
-- Contains order-level metrics and FK to dimensions
-- Materialized as TABLE for Metabase dashboard performance

{{ config(
    materialized='table', 
    schema='mart',
    order_by='order_id'
) }}

SELECT 
    -- Primary Key
    o.order_id,
    
    -- Dimension Foreign Keys
    o.user_id AS customer_id,
    CAST(o.order_dow AS String) || '_' || CAST(o.order_hour_of_day AS String) AS time_key,
    
    -- Order attributes
    o.order_number,
    o.eval_set,
    o.days_since_prior_order,
    o.is_weekend,
    o.time_of_day,
    
    -- Calculated order metrics
    CASE 
        WHEN o.days_since_prior_order IS NULL THEN 1 
        ELSE 0 
    END AS is_first_order,
    
    CASE 
        WHEN o.days_since_prior_order <= 7 THEN 'High Frequency'
        WHEN o.days_since_prior_order <= 30 THEN 'Medium Frequency'
        WHEN o.days_since_prior_order > 30 THEN 'Low Frequency'
        ELSE 'First Order'
    END AS order_frequency_category,
    
    -- Order timing analysis
    CASE 
        WHEN o.order_dow IN (0, 6) AND o.order_hour_of_day BETWEEN 10 AND 18 THEN 'Weekend Shopping'
        WHEN o.order_dow BETWEEN 1 AND 5 AND o.order_hour_of_day BETWEEN 17 AND 20 THEN 'After Work'
        WHEN o.order_dow BETWEEN 1 AND 5 AND o.order_hour_of_day BETWEEN 10 AND 14 THEN 'Lunch Break'
        ELSE 'Other Times'
    END AS shopping_occasion,
    
    -- Metrics (measures)
    1 AS order_count, -- For aggregation
    
    -- Metadata
    o.created_at,
    'star_schema' AS schema_type
    
FROM {{ ref('g2_v2_orders_3nf') }} o