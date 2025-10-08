-- models/clean/g2_v2_departments_3nf.sql
-- 3NF: Department entity (already in 3NF)
-- PK: department_id
-- No transitive dependencies

{{ config(materialized='table', schema='clean') }}

SELECT 
    CAST(department_id AS UInt32) AS department_id,
    TRIM(department) AS department_name,
    
    -- Metadata for audit
    now() AS created_at,
    'g2_v2_3nf' AS normalization_tag
    
FROM {{ source('raw', 'raw___insta_departments') }}
WHERE department_id IS NOT NULL
  AND department IS NOT NULL
  AND TRIM(department) != ''