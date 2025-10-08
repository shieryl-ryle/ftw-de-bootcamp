-- models/clean/g2_v2_order_products_3nf.sql
-- 3NF: Order line items (many-to-many resolution)
-- PK: Composite (order_id + product_id + dataset_source)
-- FK: order_id, product_id
-- Resolves M:M relationship between orders and products

{{ config(materialized='table', schema='clean') }}

WITH train_items AS (
    SELECT 
        CAST(order_id AS UInt32) AS order_id,
        CAST(product_id AS UInt32) AS product_id,
        CAST(add_to_cart_order AS UInt8) AS add_to_cart_order,
        CAST(reordered AS UInt8) AS reordered,
        'train' AS dataset_source
    FROM {{ source('raw', 'raw___insta_order_products_train') }}
    WHERE order_id IS NOT NULL 
      AND product_id IS NOT NULL
      AND add_to_cart_order IS NOT NULL
),

prior_items AS (
    SELECT 
        CAST(order_id AS UInt32) AS order_id,
        CAST(product_id AS UInt32) AS product_id,
        CAST(add_to_cart_order AS UInt8) AS add_to_cart_order,
        CAST(reordered AS UInt8) AS reordered,
        'prior' AS dataset_source
    FROM {{ source('raw', 'raw___insta_order_products_prior') }}
    WHERE order_id IS NOT NULL 
      AND product_id IS NOT NULL
      AND add_to_cart_order IS NOT NULL
)

SELECT 
    -- Composite Primary Key
    order_id,
    product_id,
    dataset_source,
    
    -- Line item attributes
    add_to_cart_order,
    reordered,
    
    -- Derived attributes
    CASE 
        WHEN reordered = 1 THEN 'Repeat Purchase'
        ELSE 'First Purchase'
    END AS purchase_type,
    
    CASE 
        WHEN add_to_cart_order = 1 THEN 'First Item'
        WHEN add_to_cart_order <= 5 THEN 'Top 5'
        WHEN add_to_cart_order <= 10 THEN 'Top 10'
        ELSE 'Later Items'
    END AS cart_position,
    
    -- Implicit quantity (each row = 1 item in Instacart dataset)
    1 AS quantity,
    
    -- Metadata
    now() AS created_at,
    'g2_v2_3nf' AS normalization_tag
    
FROM (
    SELECT * FROM train_items
    UNION ALL  
    SELECT * FROM prior_items
)