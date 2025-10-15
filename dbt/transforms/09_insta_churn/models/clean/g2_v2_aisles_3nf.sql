-- models/clean/g2_v2_aisles_3nf.sql
-- 3NF: Aisle entity with department FK
-- PK: aisle_id
-- FK: department_id (from aisle → department relationship)
-- Removes transitive dependency: product → aisle → department

{{ config(materialized='table', schema='clean') }}

WITH aisle_department_mapping AS (
    -- Extract aisle-to-department mapping from products table
    SELECT DISTINCT
        CAST(p.aisle_id AS UInt32) AS aisle_id,
        CAST(p.department_id AS UInt32) AS department_id
    FROM {{ source('raw', 'raw___insta_products') }} p
    WHERE p.aisle_id IS NOT NULL 
      AND p.department_id IS NOT NULL
)

SELECT 
    a.aisle_id,
    TRIM(a.aisle) AS aisle_name,
    
    -- FK to department (establishes hierarchy)
    adm.department_id,
    
    -- Metadata
    now() AS created_at,
    'g2_v2_3nf' AS normalization_tag
    
FROM {{ source('raw', 'raw___insta_aisles') }} a
INNER JOIN aisle_department_mapping adm 
    ON CAST(a.aisle_id AS UInt32) = adm.aisle_id
WHERE a.aisle_id IS NOT NULL
  AND a.aisle IS NOT NULL  
  AND TRIM(a.aisle) != ''