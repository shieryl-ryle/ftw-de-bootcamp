-- models/sandbox/g2_v2_test_fact_columns.sql  
-- Test model to validate fact table column structure

{{ config(materialized='table', schema='sandbox') }}

SELECT 
    order_id,
    product_id, 
    customer_id,
    department_id,
    aisle_id,
    order_dow,
    order_hour_of_day,
    is_reorder,
    dataset_source
FROM {{ ref('g2_v2_fact_orders') }}
LIMIT 100