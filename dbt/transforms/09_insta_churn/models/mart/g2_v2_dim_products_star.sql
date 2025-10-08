-- models/mart/g2_v2_dim_products_star.sql
-- STAR SCHEMA: Product dimension (denormalized with hierarchy)
-- Includes: product → aisle → department hierarchy flattened
-- PK: product_id
-- Materialized as TABLE for Metabase dashboard performance

{{ config(
    materialized='table', 
    schema='mart'
) }}

SELECT 
    -- Product attributes
    p.product_id,
    p.product_name,
    p.is_organic,
    p.is_gluten_free,
    
    -- Aisle attributes (denormalized)
    p.aisle_id,
    a.aisle_name,
    
    -- Department attributes (denormalized) 
    a.department_id,
    d.department_name,
    
    -- Hierarchy path for drill-down analysis
    d.department_name || ' > ' || a.aisle_name AS product_hierarchy,
    
    -- Product classification
    CASE 
        WHEN p.is_organic = 1 AND p.is_gluten_free = 1 THEN 'Organic & Gluten-Free'
        WHEN p.is_organic = 1 THEN 'Organic'
        WHEN p.is_gluten_free = 1 THEN 'Gluten-Free' 
        ELSE 'Regular'
    END AS product_category,
    
    -- Metadata
    p.created_at,
    'star_schema' AS schema_type
    
FROM {{ ref('g2_v2_products_3nf') }} p
INNER JOIN {{ ref('g2_v2_aisles_3nf') }} a 
    ON CAST(p.aisle_id AS UInt32) = CAST(a.aisle_id AS UInt32)
INNER JOIN {{ ref('g2_v2_departments_3nf') }} d 
    ON CAST(a.department_id AS UInt32) = CAST(d.department_id AS UInt32)