-- models/clean/g2_v2_cleaned_aisles.sql
-- CLEAN LAYER: Clean and standardize aisle master data
-- Responsibility: Data cleansing only, dimensional modeling in MART

{{ config(materialized='table', schema='clean') }}

SELECT 
    CAST(aisle_id AS UInt32) AS aisle_id,
    TRIM(aisle) AS aisle_name,
    
    -- Add metadata
    now() AS cleaned_at,
    'g2_v2' AS version_tag
    
FROM {{ source('raw', 'raw___insta_aisles') }}
WHERE aisle_id IS NOT NULL
  AND aisle IS NOT NULL
  AND TRIM(aisle) != ''