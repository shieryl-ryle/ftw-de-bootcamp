-- models/clean/stg_products.sql
-- Staging model for products - standardize data types and handle nulls

{{ config(materialized='view', schema='clean') }}

SELECT 
    CAST(product_id AS UInt32) AS product_id,
    TRIM(product_name) AS product_name,
    CAST(aisle_id AS UInt32) AS aisle_id,
    CAST(department_id AS UInt32) AS department_id
FROM {{ source('raw', 'raw___insta_products') }}
WHERE product_id IS NOT NULL
  AND product_name IS NOT NULL 
  AND product_name != ''