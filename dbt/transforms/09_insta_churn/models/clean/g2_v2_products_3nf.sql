-- models/clean/g2_v2_products_3nf.sql
-- 3NF: Product entity (removes transitive dependencies)
-- PK: product_id  
-- FK: aisle_id (direct dependency only)
-- REMOVES: department_id (transitive: product → aisle → department)

{{ config(materialized='table', schema='clean') }}

SELECT 
    CAST(product_id AS UInt32) AS product_id,
    TRIM(product_name) AS product_name,
    
    -- Direct FK to aisle only (3NF compliance)
    CAST(aisle_id AS UInt32) AS aisle_id,
    
    -- REMOVED: department_id (transitive dependency eliminated)
    -- Department is accessible via: product → aisle → department
    
    -- Data quality flags
    CASE 
        WHEN TRIM(product_name) IS NULL OR TRIM(product_name) = '' THEN 1
        ELSE 0 
    END AS has_missing_name,
    
    -- Derived product attributes
    CASE 
        WHEN LOWER(product_name) LIKE '%organic%' THEN 1 
        ELSE 0 
    END AS is_organic,
    CASE 
        WHEN LOWER(product_name) LIKE '%gluten%free%' OR LOWER(product_name) LIKE '%gluten-free%' THEN 1 
        ELSE 0 
    END AS is_gluten_free,
    
    -- Metadata
    now() AS created_at,
    'g2_v2_3nf' AS normalization_tag
    
FROM {{ source('raw', 'raw___insta_products') }}
WHERE product_id IS NOT NULL
  AND aisle_id IS NOT NULL  
  AND product_name IS NOT NULL
  AND TRIM(product_name) != ''