-- models/mart/g2_v2_fact_order_products_star.sql
-- STAR SCHEMA: Order line items fact table (main analytical table)
-- Grain: One row per order + product combination
-- Contains all FK to dimensions and key business measures
-- Materialized as TABLE for Metabase dashboard performance

{{ config(
    materialized='table', 
    schema='mart',
    order_by='(order_id, product_id)'
) }}

SELECT 
    -- Composite Primary Key
    op.order_id,
    op.product_id,
    op.dataset_source,
    
    -- Dimension Foreign Keys
    o.user_id AS customer_id,
    CAST(o.order_dow AS String) || '_' || CAST(o.order_hour_of_day AS String) AS time_key,
    
    -- Order context
    o.order_number,
    o.eval_set,
    o.days_since_prior_order,
    
    -- Product context in cart
    op.add_to_cart_order,
    op.reordered,
    op.purchase_type,
    op.cart_position,
    
    -- Key Business Measures
    op.quantity AS items_ordered, -- Always 1 in this dataset
    op.reordered AS reorder_flag,
    
    CASE WHEN op.reordered = 1 THEN 1 ELSE 0 END AS reorder_count,
    CASE WHEN op.reordered = 0 THEN 1 ELSE 0 END AS first_purchase_count,
    
    -- Behavioral measures
    CASE 
        WHEN op.add_to_cart_order = 1 THEN 1 
        ELSE 0 
    END AS is_first_item_in_cart,
    
    CASE 
        WHEN op.add_to_cart_order <= 3 THEN 1 
        ELSE 0 
    END AS is_priority_item,
    
    -- Customer journey measures
    CASE 
        WHEN o.days_since_prior_order IS NULL THEN 1 
        ELSE 0 
    END AS is_customer_first_order,
    
    CASE 
        WHEN o.days_since_prior_order <= 7 THEN 1 
        ELSE 0 
    END AS is_frequent_reorder,
    
    -- Shopping pattern measures
    CASE 
        WHEN o.order_dow IN (0, 6) THEN 1 
        ELSE 0 
    END AS is_weekend_order,
    
    CASE 
        WHEN o.order_hour_of_day BETWEEN 17 AND 20 THEN 1 
        ELSE 0 
    END AS is_evening_rush,
    
    -- Churn risk indicators (for analysis #8)
    CASE 
        WHEN o.days_since_prior_order > 60 THEN 1 
        ELSE 0 
    END AS is_long_gap_order,
    
    CASE 
        WHEN op.reordered = 0 AND o.order_number > 5 THEN 1 
        ELSE 0 
    END AS is_new_product_exploration,
    
    -- Revenue proxy (for CLV analysis)
    1 AS revenue_proxy, -- Each item represents revenue unit
    
    -- Metadata
    op.created_at,
    'star_schema' AS schema_type
    
FROM {{ ref('g2_v2_order_products_3nf') }} op
INNER JOIN {{ ref('g2_v2_orders_3nf') }} o 
    ON op.order_id = o.order_id