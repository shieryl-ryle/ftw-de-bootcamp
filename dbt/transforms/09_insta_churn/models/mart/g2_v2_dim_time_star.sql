-- models/mart/g2_v2_dim_time_star.sql
-- STAR SCHEMA: Time dimension for temporal analysis
-- Grain: day of week + hour of day combinations
-- PK: time_key (composite)
-- Materialized as TABLE for Metabase dashboard performance

{{ config(
    materialized='table', 
    schema='mart',
    order_by='(order_dow, order_hour_of_day)'
) }}

WITH time_combinations AS (
    -- Generate all possible day/hour combinations from actual data
    SELECT DISTINCT
        order_dow,
        order_hour_of_day
    FROM {{ ref('g2_v2_orders_3nf') }}
    WHERE order_dow IS NOT NULL 
      AND order_hour_of_day IS NOT NULL
)

SELECT 
    -- Composite primary key
    CAST(order_dow AS String) || '_' || CAST(order_hour_of_day AS String) AS time_key,
    
    -- Day of week attributes
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
    
    -- Hour of day attributes  
    order_hour_of_day,
    CASE 
        WHEN order_hour_of_day BETWEEN 6 AND 11 THEN 'Morning'
        WHEN order_hour_of_day BETWEEN 12 AND 17 THEN 'Afternoon'
        WHEN order_hour_of_day BETWEEN 18 AND 22 THEN 'Evening'
        ELSE 'Night'
    END AS time_period,
    
    -- Day type classifications
    CASE 
        WHEN order_dow IN (0, 6) THEN 'Weekend'
        ELSE 'Weekday'
    END AS day_type,
    
    CASE 
        WHEN order_dow = 0 THEN 'Sunday'
        WHEN order_dow = 6 THEN 'Saturday'  
        WHEN order_dow IN (1, 5) THEN 'Monday/Friday'
        ELSE 'Mid-Week'
    END AS day_category,
    
    -- Hour classifications
    CASE 
        WHEN order_hour_of_day BETWEEN 7 AND 9 THEN 'Morning Rush'
        WHEN order_hour_of_day BETWEEN 17 AND 19 THEN 'Evening Rush'
        WHEN order_hour_of_day BETWEEN 10 AND 16 THEN 'Midday'
        WHEN order_hour_of_day BETWEEN 20 AND 23 THEN 'Night'
        ELSE 'Early Hours'
    END AS hour_category,
    
    -- Business hour flag
    CASE 
        WHEN order_hour_of_day BETWEEN 8 AND 20 AND order_dow BETWEEN 1 AND 5 THEN 1
        ELSE 0
    END AS is_business_hours,
    
    -- Peak shopping indicators
    CASE 
        WHEN order_dow IN (0, 6) AND order_hour_of_day BETWEEN 10 AND 18 THEN 'Weekend Peak'
        WHEN order_dow BETWEEN 1 AND 5 AND order_hour_of_day BETWEEN 17 AND 20 THEN 'Weekday Evening Peak'
        WHEN order_dow BETWEEN 1 AND 5 AND order_hour_of_day BETWEEN 10 AND 14 THEN 'Weekday Lunch'
        ELSE 'Off-Peak'
    END AS shopping_peak_indicator,
    
    -- Metadata
    now() AS created_at,
    'star_schema' AS schema_type
    
FROM time_combinations
ORDER BY order_dow, order_hour_of_day