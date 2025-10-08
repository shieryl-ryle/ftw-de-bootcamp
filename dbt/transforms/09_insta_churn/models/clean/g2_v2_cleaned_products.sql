-- models/clean/g2_v2_cleaned_products.sql
-- CLEAN LAYER: Data cleansing and standardization for products
-- Responsibility: Clean data types, handle nulls, basic normalization
-- NOT dimensional modeling yet (that goes to MART)

{{ config(materialized='table', schema='clean') }}

SELECT 
    -- Standardized data types
    CAST(product_id AS UInt32) AS product_id,
    TRIM(product_name) AS product_name,
    CAST(aisle_id AS UInt32) AS aisle_id,
    CAST(department_id AS UInt32) AS department_id,
    
    -- Add metadata for tracking
    now() AS cleaned_at,
    'g2_v2' AS version_tag
    
FROM {{ source('raw', 'raw___insta_products') }}
WHERE 
    -- Data quality filters
    product_id IS NOT NULL
    AND product_name IS NOT NULL 
    AND product_name != ''
    AND TRIM(product_name) != ''
    AND aisle_id IS NOT NULL
    AND department_id IS NOT NULL