-- models/mart/g2_v2_fact_orders.sql
-- MART LAYER: Main fact table for order transactions
-- Dimensional Modeling: Star schema fact table
-- Core table for all 9 churn analysis requirements

{{ config(materialized='view', schema='mart') }}

SELECT 
    -- Fact table grain: One row per order-product combination
    op.order_id,
    op.product_id,
    o.user_id AS customer_id,
    
    -- Dimension foreign keys
    p.department_id,
    p.aisle_id,
    
    -- Temporal dimensions (derived from order)
    o.order_dow,
    o.order_hour_of_day,
    o.order_number,
    
    -- Measures and metrics
    1 AS quantity_ordered,  -- Each row = 1 item ordered
    op.add_to_cart_order,
    op.reordered,
    
    -- Calculated measures for analysis
    CASE 
        WHEN op.reordered = 1 THEN 1 
        ELSE 0 
    END AS is_reorder,
    
    -- Customer behavior measures
    o.days_since_prior_order,
    
    CASE 
        WHEN o.days_since_prior_order IS NULL THEN 'First Order'
        WHEN o.days_since_prior_order <= 7 THEN 'Within Week'
        WHEN o.days_since_prior_order <= 14 THEN 'Within 2 Weeks'
        WHEN o.days_since_prior_order <= 30 THEN 'Within Month'
        ELSE 'Over Month'
    END AS recency_bucket,
    
    -- Dataset source for analysis
    op.dataset_source,
    
    -- Metadata
    op.version_tag
    
FROM {{ ref('g2_v2_cleaned_order_products') }} op
INNER JOIN {{ ref('g2_v2_cleaned_orders') }} o 
    ON op.order_id = o.order_id
INNER JOIN {{ ref('g2_v2_cleaned_products') }} p 
    ON op.product_id = p.product_id