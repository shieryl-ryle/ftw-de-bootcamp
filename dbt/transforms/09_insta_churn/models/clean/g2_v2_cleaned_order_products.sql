-- models/clean/g2_v2_cleaned_order_products.sql
-- CLEAN LAYER: Combine and clean order_products from train + prior datasets
-- Responsibility: Union datasets, standardize data types, basic validation

{{ config(materialized='table', schema='clean') }}

WITH train_data AS (
    SELECT 
        CAST(order_id AS UInt32) AS order_id,
        CAST(product_id AS UInt32) AS product_id,
        CAST(add_to_cart_order AS UInt8) AS add_to_cart_order,
        CAST(reordered AS UInt8) AS reordered,
        'train' AS dataset_source
    FROM {{ source('raw', 'raw___insta_order_products_train') }}
    WHERE order_id IS NOT NULL 
      AND product_id IS NOT NULL
),

prior_data AS (
    SELECT 
        CAST(order_id AS UInt32) AS order_id,
        CAST(product_id AS UInt32) AS product_id,
        CAST(add_to_cart_order AS UInt8) AS add_to_cart_order,
        CAST(reordered AS UInt8) AS reordered,
        'prior' AS dataset_source
    FROM {{ source('raw', 'raw___insta_order_products_prior') }}
    WHERE order_id IS NOT NULL 
      AND product_id IS NOT NULL
)

SELECT 
    order_id,
    product_id,
    add_to_cart_order,
    reordered,
    dataset_source,
    
    -- Add metadata
    now() AS cleaned_at,
    'g2_v2' AS version_tag
    
FROM train_data

UNION ALL

SELECT 
    order_id,
    product_id,
    add_to_cart_order,
    reordered,
    dataset_source,
    now() AS cleaned_at,
    'g2_v2' AS version_tag
    
FROM prior_data