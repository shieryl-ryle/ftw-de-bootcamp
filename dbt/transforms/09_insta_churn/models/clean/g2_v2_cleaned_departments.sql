-- models/clean/g2_v2_cleaned_departments.sql
-- CLEAN LAYER: Clean and standardize department master data
-- Responsibility: Data cleansing only, dimensional modeling in MART

{{ config(materialized='table', schema='clean') }}

SELECT 
    CAST(department_id AS UInt32) AS department_id,
    TRIM(department) AS department_name,
    
    -- Add metadata
    now() AS cleaned_at,
    'g2_v2' AS version_tag
    
FROM {{ source('raw', 'raw___insta_departments') }}
WHERE department_id IS NOT NULL
  AND department IS NOT NULL
  AND TRIM(department) != ''