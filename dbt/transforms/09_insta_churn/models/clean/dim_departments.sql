-- clean/dim_departments.sql  
-- 3NF: Department entity (already normalized in source)
-- PK: department_id
-- No transitive dependencies

{{ config(materialized='table', schema='clean') }}

SELECT 
    CAST(department_id AS UInt32) AS department_id,
    TRIM(department) AS department_name,
    -- Add metadata
    now() AS created_at
FROM {{ source('raw', 'raw___insta_departments') }}
WHERE department_id IS NOT NULL
  AND department IS NOT NULL
  AND department != ''