-- clean/dim_aisles.sql
-- 3NF: Aisle entity with FK to departments  
-- PK: aisle_id
-- FK: department_id (via products, but we'll enforce relationship)

{{ config(materialized='table', schema='clean') }}

SELECT 
    CAST(aisle_id AS UInt32) AS aisle_id,
    TRIM(aisle) AS aisle_name,
    -- Add metadata
    now() AS created_at
FROM {{ source('raw', 'raw___insta_aisles') }}
WHERE aisle_id IS NOT NULL
  AND aisle IS NOT NULL
  AND aisle != ''