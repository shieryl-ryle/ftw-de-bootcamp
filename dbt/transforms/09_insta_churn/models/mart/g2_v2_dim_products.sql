-- models/mart/g2_v2_dim_products.sql
-- MART LAYER: Product dimension with proper hierarchical structure
-- Dimensional Modeling: Product → Aisle → Department hierarchy
-- Includes all product attributes needed for churn analysis

{{ config(materialized='view', schema='mart') }}

SELECT 
    -- Product dimension primary key
    p.product_id,
    p.product_name,
    
    -- Aisle attributes (snowflake design)
    p.aisle_id,
    a.aisle_name,
    
    -- Department attributes (snowflake design)  
    p.department_id,
    d.department_name,
    
    -- Derived attributes for analytics
    LENGTH(p.product_name) AS product_name_length,
    CASE 
        WHEN LOWER(p.product_name) LIKE '%organic%' THEN 1 
        ELSE 0 
    END AS is_organic,
    CASE 
        WHEN LOWER(p.product_name) LIKE '%gluten%free%' OR LOWER(p.product_name) LIKE '%gluten-free%' THEN 1 
        ELSE 0 
    END AS is_gluten_free,
    
    -- Metadata
    p.cleaned_at,
    p.version_tag
    
FROM {{ ref('g2_v2_cleaned_products') }} p
LEFT JOIN {{ ref('g2_v2_cleaned_aisles') }} a 
    ON p.aisle_id = a.aisle_id
LEFT JOIN {{ ref('g2_v2_cleaned_departments') }} d 
    ON p.department_id = d.department_id