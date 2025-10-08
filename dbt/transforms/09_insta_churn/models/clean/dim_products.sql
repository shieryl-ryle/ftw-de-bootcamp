-- clean/dim_products.sql
-- 3NF: Product entity with proper FK relationships
-- PK: product_id  
-- FK: aisle_id, department_id
-- Removes transitive dependency: product → department (now: product → aisle → department)

{{ config(materialized='table', schema='clean') }}

SELECT 
    CAST(p.product_id AS UInt32) AS product_id,
    TRIM(p.product_name) AS product_name,
    CAST(p.aisle_id AS UInt32) AS aisle_id,
    CAST(p.department_id AS UInt32) AS department_id,
    
    -- Data quality flags
    CASE 
        WHEN p.product_name IS NULL OR p.product_name = '' THEN 1
        ELSE 0 
    END AS is_missing_name,
    
    -- Add metadata
    now() AS created_at
    
FROM {{ source('raw', 'raw___insta_products') }} p
WHERE p.product_id IS NOT NULL
  AND p.aisle_id IS NOT NULL  
  AND p.department_id IS NOT NULL