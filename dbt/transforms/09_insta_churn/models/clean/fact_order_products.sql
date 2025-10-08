-- clean/fact_order_products.sql  
-- 3NF: Order line items (transaction-level facts)
-- PK: order_id + product_id + dataset_source
-- FK: order_id, product_id
-- Combines train and prior datasets with proper source tracking

{{ config(materialized='table', schema='clean') }}

WITH order_products_combined AS (
    -- Training dataset
    SELECT 
        CAST(order_id AS UInt32) AS order_id,
        CAST(product_id AS UInt32) AS product_id,
        CAST(add_to_cart_order AS UInt32) AS add_to_cart_order,
        CAST(reordered AS UInt8) AS reordered,
        'train' AS dataset_source
    FROM {{ source('raw', 'raw___insta_order_products_train') }}
    WHERE order_id IS NOT NULL 
      AND product_id IS NOT NULL
      
    UNION ALL
    
    -- Prior/Historical dataset  
    SELECT 
        CAST(order_id AS UInt32) AS order_id,
        CAST(product_id AS UInt32) AS product_id,
        CAST(add_to_cart_order AS UInt32) AS add_to_cart_order,
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
    
    -- Derived attributes
    CASE 
        WHEN reordered = 1 THEN 'Repeat Purchase'
        ELSE 'First Purchase' 
    END AS purchase_type,
    
    -- Cart position insights
    CASE 
        WHEN add_to_cart_order = 1 THEN 'First Item'
        WHEN add_to_cart_order <= 5 THEN 'Top 5 Items'
        WHEN add_to_cart_order <= 10 THEN 'Top 10 Items'
        ELSE 'Later Items'
    END AS cart_position_group,
    
    -- Add metadata  
    now() AS created_at
    
FROM order_products_combined