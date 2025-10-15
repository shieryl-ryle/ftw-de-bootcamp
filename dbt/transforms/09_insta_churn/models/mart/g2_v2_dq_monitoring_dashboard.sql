{{ config(materialized='table', schema='mart') }}

-- Data Quality Monitoring: Comprehensive DQ Dashboard
-- Tracks data quality metrics across all layers: raw, clean, mart
WITH raw_layer_quality AS (
    -- Raw data quality checks
    SELECT 
        'raw' as layer,
        'aisles' as table_name,
        COUNT(*) as total_rows,
        COUNT(DISTINCT aisle_id) as unique_keys,
        COUNT(*) - COUNT(DISTINCT aisle_id) as duplicate_keys,
        ROUND((COUNT(*) - COUNT(DISTINCT aisle_id)) * 100.0 / COUNT(*), 2) as duplicate_rate_pct,
        
        -- Null checks
        COUNT(*) - COUNT(aisle_id) as null_primary_keys,
        COUNT(*) - COUNT(aisle) as null_aisle_names,
        ROUND((COUNT(*) - COUNT(aisle)) * 100.0 / COUNT(*), 2) as null_rate_pct
        
    FROM {{ source('raw', 'raw___insta_aisles') }}
    
    UNION ALL
    
    SELECT 
        'raw' as layer,
        'departments' as table_name,
        COUNT(*) as total_rows,
        COUNT(DISTINCT department_id) as unique_keys,
        COUNT(*) - COUNT(DISTINCT department_id) as duplicate_keys,
        ROUND((COUNT(*) - COUNT(DISTINCT department_id)) * 100.0 / COUNT(*), 2) as duplicate_rate_pct,
        
        COUNT(*) - COUNT(department_id) as null_primary_keys,
        COUNT(*) - COUNT(department) as null_department_names,
        ROUND((COUNT(*) - COUNT(department)) * 100.0 / COUNT(*), 2) as null_rate_pct
        
    FROM {{ source('raw', 'raw___insta_departments') }}
    
    UNION ALL
    
    SELECT 
        'raw' as layer,
        'products' as table_name,
        COUNT(*) as total_rows,
        COUNT(DISTINCT product_id) as unique_keys,
        COUNT(*) - COUNT(DISTINCT product_id) as duplicate_keys,
        ROUND((COUNT(*) - COUNT(DISTINCT product_id)) * 100.0 / COUNT(*), 2) as duplicate_rate_pct,
        
        COUNT(*) - COUNT(product_id) as null_primary_keys,
        COUNT(*) - COUNT(product_name) as null_product_names,
        ROUND((COUNT(*) - COUNT(product_name)) * 100.0 / COUNT(*), 2) as null_rate_pct
        
    FROM {{ source('raw', 'raw___insta_products') }}
    
    UNION ALL
    
    SELECT 
        'raw' as layer,
        'orders' as table_name,
        COUNT(*) as total_rows,
        COUNT(DISTINCT order_id) as unique_keys,
        COUNT(*) - COUNT(DISTINCT order_id) as duplicate_keys,
        ROUND((COUNT(*) - COUNT(DISTINCT order_id)) * 100.0 / COUNT(*), 2) as duplicate_rate_pct,
        
        COUNT(*) - COUNT(order_id) as null_primary_keys,
        COUNT(*) - COUNT(user_id) as null_user_ids,
        ROUND((COUNT(*) - COUNT(user_id)) * 100.0 / COUNT(*), 2) as null_rate_pct
        
    FROM {{ source('raw', 'raw___insta_orders') }}
),

clean_layer_quality AS (
    -- Clean (3NF) layer quality checks
    SELECT 
        'clean' as layer,
        'g2_v2_departments_3nf' as table_name,
        COUNT(*) as total_rows,
        COUNT(DISTINCT department_id) as unique_keys,
        COUNT(*) - COUNT(DISTINCT department_id) as duplicate_keys,
        ROUND((COUNT(*) - COUNT(DISTINCT department_id)) * 100.0 / COUNT(*), 2) as duplicate_rate_pct,
        
        COUNT(*) - COUNT(department_id) as null_primary_keys,
        COUNT(*) - COUNT(department_name) as null_department_names,
        ROUND((COUNT(*) - COUNT(department_name)) * 100.0 / COUNT(*), 2) as null_rate_pct
        
    FROM {{ ref('g2_v2_departments_3nf') }}
    
    UNION ALL
    
    SELECT 
        'clean' as layer,
        'g2_v2_products_3nf' as table_name,
        COUNT(*) as total_rows,
        COUNT(DISTINCT product_id) as unique_keys,
        COUNT(*) - COUNT(DISTINCT product_id) as duplicate_keys,
        ROUND((COUNT(*) - COUNT(DISTINCT product_id)) * 100.0 / COUNT(*), 2) as duplicate_rate_pct,
        
        COUNT(*) - COUNT(product_id) as null_primary_keys,
        COUNT(*) - COUNT(product_name) as null_product_names,
        ROUND((COUNT(*) - COUNT(product_name)) * 100.0 / COUNT(*), 2) as null_rate_pct
        
    FROM {{ ref('g2_v2_products_3nf') }}
    
    UNION ALL
    
    SELECT 
        'clean' as layer,
        'g2_v2_users_3nf' as table_name,
        COUNT(*) as total_rows,
        COUNT(DISTINCT user_id) as unique_keys,
        COUNT(*) - COUNT(DISTINCT user_id) as duplicate_keys,
        ROUND((COUNT(*) - COUNT(DISTINCT user_id)) * 100.0 / COUNT(*), 2) as duplicate_rate_pct,
        
        COUNT(*) - COUNT(user_id) as null_primary_keys,
        COUNT(*) - COUNT(total_orders) as null_order_counts,
        ROUND((COUNT(*) - COUNT(total_orders)) * 100.0 / COUNT(*), 2) as null_rate_pct
        
    FROM {{ ref('g2_v2_users_3nf') }}
),

mart_layer_quality AS (
    -- Mart (dimensional) layer quality checks
    SELECT 
        'mart' as layer,
        'g2_v2_dim_products_star' as table_name,
        COUNT(*) as total_rows,
        COUNT(DISTINCT `p.product_id`) as unique_keys,
        COUNT(*) - COUNT(DISTINCT `p.product_id`) as duplicate_keys,
        ROUND((COUNT(*) - COUNT(DISTINCT `p.product_id`)) * 100.0 / COUNT(*), 2) as duplicate_rate_pct,
        
        COUNT(*) - COUNT(`p.product_id`) as null_primary_keys,
        COUNT(*) - COUNT(`p.product_name`) as null_product_names,
        ROUND((COUNT(*) - COUNT(`p.product_name`)) * 100.0 / COUNT(*), 2) as null_rate_pct
        
    FROM {{ ref('g2_v2_dim_products_star') }}
    
    UNION ALL
    
    SELECT 
        'mart' as layer,
        'g2_v2_fact_order_products_star' as table_name,
        COUNT(*) as total_rows,
        COUNT(DISTINCT CONCAT(CAST(order_id AS String), '-', CAST(product_id AS String))) as unique_keys,
        COUNT(*) - COUNT(DISTINCT CONCAT(CAST(order_id AS String), '-', CAST(product_id AS String))) as duplicate_keys,
        ROUND((COUNT(*) - COUNT(DISTINCT CONCAT(CAST(order_id AS String), '-', CAST(product_id AS String)))) * 100.0 / COUNT(*), 2) as duplicate_rate_pct,
        
        COUNT(*) - COUNT(order_id) as null_order_ids,
        COUNT(*) - COUNT(customer_id) as null_customer_ids,
        ROUND((COUNT(*) - COUNT(customer_id)) * 100.0 / COUNT(*), 2) as null_rate_pct
        
    FROM {{ ref('g2_v2_fact_order_products_star') }}
),

referential_integrity AS (
    -- Check referential integrity between layers
    SELECT 
        'referential_integrity' as check_type,
        'products_in_orders_exist_in_products_dim' as check_name,
        COUNT(*) as total_records,
        COUNT(dp.`p.product_id`) as matching_records,
        COUNT(*) - COUNT(dp.`p.product_id`) as orphan_records,
        ROUND((COUNT(*) - COUNT(dp.`p.product_id`)) * 100.0 / COUNT(*), 2) as integrity_violation_pct
        
    FROM {{ ref('g2_v2_fact_order_products_star') }} fop
    LEFT JOIN {{ ref('g2_v2_dim_products_star') }} dp
        ON CAST(fop.product_id AS String) = CAST(dp.`p.product_id` AS String)
        
    UNION ALL
    
    SELECT 
        'referential_integrity' as check_type,
        'customers_in_orders_exist_in_users_dim' as check_name,
        COUNT(*) as total_records,
        COUNT(du.user_id) as matching_records,
        COUNT(*) - COUNT(du.user_id) as orphan_records,
        ROUND((COUNT(*) - COUNT(du.user_id)) * 100.0 / COUNT(*), 2) as integrity_violation_pct
        
    FROM {{ ref('g2_v2_fact_order_products_star') }} fop
    LEFT JOIN {{ ref('g2_v2_dim_users_star') }} du
        ON CAST(fop.customer_id AS String) = CAST(du.user_id AS String)
),

value_range_checks AS (
    -- Check for data anomalies and value ranges
    SELECT 
        'value_range' as check_type,
        'reorder_flag_valid_values' as check_name,
        COUNT(*) as total_records,
        COUNT(CASE WHEN reordered IN (0, 1) THEN 1 END) as valid_records,
        COUNT(*) - COUNT(CASE WHEN reordered IN (0, 1) THEN 1 END) as invalid_records,
        ROUND((COUNT(*) - COUNT(CASE WHEN reordered IN (0, 1) THEN 1 END)) * 100.0 / COUNT(*), 2) as invalid_pct
        
    FROM {{ ref('g2_v2_fact_order_products_star') }}
    
    UNION ALL
    
    SELECT 
        'value_range' as check_type,
        'cart_position_reasonable' as check_name,
        COUNT(*) as total_records,
        COUNT(CASE WHEN add_to_cart_order BETWEEN 1 AND 100 THEN 1 END) as valid_records,
        COUNT(*) - COUNT(CASE WHEN add_to_cart_order BETWEEN 1 AND 100 THEN 1 END) as invalid_records,
        ROUND((COUNT(*) - COUNT(CASE WHEN add_to_cart_order BETWEEN 1 AND 100 THEN 1 END)) * 100.0 / COUNT(*), 2) as invalid_pct
        
    FROM {{ ref('g2_v2_fact_order_products_star') }}
)

-- Final consolidated quality report
SELECT 
    layer,
    table_name,
    total_rows,
    unique_keys,
    duplicate_keys,
    duplicate_rate_pct,
    null_primary_keys,
    null_rate_pct,
    
    -- Quality scoring
    CASE 
        WHEN duplicate_rate_pct = 0 AND null_rate_pct < 5 THEN 'Excellent'
        WHEN duplicate_rate_pct < 1 AND null_rate_pct < 10 THEN 'Good'
        WHEN duplicate_rate_pct < 5 AND null_rate_pct < 25 THEN 'Fair'
        ELSE 'Poor'
    END as data_quality_grade,
    
    NOW() as quality_check_timestamp

FROM (
    SELECT * FROM raw_layer_quality
    UNION ALL
    SELECT * FROM clean_layer_quality  
    UNION ALL
    SELECT * FROM mart_layer_quality
)

UNION ALL

-- Add referential integrity and value range results
SELECT 
    check_type as layer,
    check_name as table_name,
    total_records as total_rows,
    matching_records as unique_keys,
    orphan_records as duplicate_keys,
    integrity_violation_pct as duplicate_rate_pct,
    0 as null_primary_keys,
    integrity_violation_pct as null_rate_pct,
    
    CASE 
        WHEN integrity_violation_pct = 0 THEN 'Excellent'
        WHEN integrity_violation_pct < 1 THEN 'Good'
        WHEN integrity_violation_pct < 5 THEN 'Fair'
        ELSE 'Poor'
    END as data_quality_grade,
    
    NOW() as quality_check_timestamp

FROM referential_integrity

UNION ALL

SELECT 
    check_type as layer,
    check_name as table_name,
    total_records as total_rows,
    valid_records as unique_keys,
    invalid_records as duplicate_keys,
    invalid_pct as duplicate_rate_pct,
    0 as null_primary_keys,
    invalid_pct as null_rate_pct,
    
    CASE 
        WHEN invalid_pct = 0 THEN 'Excellent'
        WHEN invalid_pct < 1 THEN 'Good'
        WHEN invalid_pct < 5 THEN 'Fair'
        ELSE 'Poor'
    END as data_quality_grade,
    
    NOW() as quality_check_timestamp

FROM value_range_checks

ORDER BY layer, table_name