-- models/mart/g2_v2_data_quality_summary.sql
-- DATA QUALITY MONITORING: Post-dimensional modeling validation
-- Monitors data quality across all layers after 3NF normalization and star schema creation

{{ config(materialized='view', schema='mart') }}

WITH raw_counts AS (
    SELECT 
        'products' AS entity,
        COUNT(*) AS raw_count,
        COUNT(DISTINCT product_id) AS raw_unique_count
    FROM {{ source('raw', 'raw___insta_products') }}
    
    UNION ALL
    
    SELECT 
        'orders' AS entity,
        COUNT(*) AS raw_count,
        COUNT(DISTINCT order_id) AS raw_unique_count  
    FROM {{ source('raw', 'raw___insta_orders') }}
    
    UNION ALL
    
    SELECT 
        'order_products_combined' AS entity,
        COUNT(*) AS raw_count,
        COUNT(*) AS raw_unique_count  -- Grain is order+product, no single unique key
    FROM (
        SELECT order_id, product_id FROM {{ source('raw', 'raw___insta_order_products_train') }}
        UNION ALL
        SELECT order_id, product_id FROM {{ source('raw', 'raw___insta_order_products_prior') }}
    )
),

clean_counts AS (
    SELECT 
        'products' AS entity,
        COUNT(*) AS clean_count,
        COUNT(DISTINCT product_id) AS clean_unique_count
    FROM {{ ref('g2_v2_cleaned_products') }}
    
    UNION ALL
    
    SELECT 
        'orders' AS entity,
        COUNT(*) AS clean_count,
        COUNT(DISTINCT order_id) AS clean_unique_count
    FROM {{ ref('g2_v2_cleaned_orders') }}
    
    UNION ALL
    
    SELECT 
        'order_products_combined' AS entity,
        COUNT(*) AS clean_count,
        COUNT(*) AS clean_unique_count
    FROM {{ ref('g2_v2_cleaned_order_products') }}
),

mart_counts AS (
    SELECT 
        'fact_orders' AS entity,
        COUNT(*) AS mart_count,
        COUNT(DISTINCT order_id || '_' || product_id) AS mart_unique_count
    FROM {{ ref('g2_v2_fact_orders') }}
    
    UNION ALL
    
    SELECT 
        'dim_customers' AS entity, 
        COUNT(*) AS mart_count,
        COUNT(DISTINCT customer_id) AS mart_unique_count
    FROM {{ ref('g2_v2_dim_customers') }}
    
    UNION ALL
    
    SELECT 
        'dim_products' AS entity,
        COUNT(*) AS mart_count, 
        COUNT(DISTINCT product_id) AS mart_unique_count
    FROM {{ ref('g2_v2_dim_products') }}
)

SELECT 
    COALESCE(r.entity, c.entity, m.entity) AS data_entity,
    
    -- Volume tracking across layers  
    COALESCE(r.raw_count, 0) AS raw_total_records,
    COALESCE(c.clean_count, 0) AS clean_total_records,
    COALESCE(m.mart_count, 0) AS mart_total_records,
    
    -- Data quality metrics
    COALESCE(r.raw_count, 0) - COALESCE(c.clean_count, 0) AS records_dropped_in_cleaning,
    ROUND(100.0 * COALESCE(c.clean_count, 0) / NULLIF(COALESCE(r.raw_count, 0), 0), 2) AS clean_data_retention_pct,
    
    -- Referential integrity checks
    CASE 
        WHEN r.entity IN ('products', 'orders') THEN
            CASE WHEN r.raw_unique_count = c.clean_unique_count THEN 'PASS' ELSE 'FAIL' END
        ELSE 'N/A'
    END AS unique_key_integrity_check,
    
    -- Data completeness flags
    CASE 
        WHEN COALESCE(c.clean_count, 0) = 0 THEN 'CRITICAL: No clean data'
        WHEN COALESCE(c.clean_count, 0) < COALESCE(r.raw_count, 0) * 0.95 THEN 'WARNING: >5% data loss'
        WHEN COALESCE(c.clean_count, 0) < COALESCE(r.raw_count, 0) * 0.99 THEN 'INFO: Minor data loss'
        ELSE 'PASS: Minimal data loss'
    END AS data_quality_status,
    
    -- Pipeline health indicators
    CASE 
        WHEN m.entity IS NOT NULL THEN 'Available'
        ELSE 'Missing'
    END AS mart_availability,
    
    -- Metadata
    'g2_v2' AS version_tag,
    now() AS dq_check_timestamp
    
FROM raw_counts r
FULL OUTER JOIN clean_counts c ON r.entity = c.entity  
FULL OUTER JOIN mart_counts m ON COALESCE(r.entity, c.entity) = m.entity

ORDER BY 
    CASE data_entity 
        WHEN 'products' THEN 1
        WHEN 'orders' THEN 2  
        WHEN 'order_products_combined' THEN 3
        WHEN 'fact_orders' THEN 4
        WHEN 'dim_customers' THEN 5
        WHEN 'dim_products' THEN 6
        ELSE 99
    END