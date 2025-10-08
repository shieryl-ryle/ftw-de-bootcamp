-- models/mart/g2_v2_customer_frequency_segmentation.sql
-- BUSINESS ANALYTICS #5: Customer Frequency Segmentation  
-- RFM-style analysis for customer churn prediction

{{ config(materialized='view', schema='mart') }}

WITH customer_metrics AS (
    SELECT 
        c.customer_id,
        c.total_orders,
        c.avg_days_between_orders,
        c.frequency_segment,
        c.ordering_pattern,
        
        -- Recency calculation (days since last order)
        -- Note: In real scenario, you'd calculate from current date
        -- Using order_number as proxy for recency here
        c.last_order_number,
        
        -- Monetary proxy (basket size and product variety)
        COUNT(DISTINCT f.product_id) AS unique_products_purchased,
        COUNT(DISTINCT f.department_id) AS unique_departments_shopped,  
        COUNT(*) AS total_items_purchased,
        ROUND(COUNT(*) / c.total_orders, 2) AS avg_basket_size,
        
        -- Loyalty indicators
        SUM(f.is_reorder) AS total_reorders,
        ROUND(100.0 * SUM(f.is_reorder) / COUNT(*), 2) AS personal_reorder_rate_pct,
        
        -- Shopping behavior patterns
        COUNT(DISTINCT f.order_dow) AS active_days_of_week,
        COUNT(DISTINCT f.order_hour_of_day) AS active_hours_of_day
        
    FROM {{ ref('g2_v2_dim_customers') }} c
    INNER JOIN {{ ref('g2_v2_fact_orders') }} f 
        ON c.customer_id = f.customer_id
    GROUP BY 
        c.customer_id, c.total_orders, c.avg_days_between_orders,
        c.frequency_segment, c.ordering_pattern, c.last_order_number
)

SELECT 
    customer_id,
    
    -- Original segments
    frequency_segment,
    ordering_pattern,
    
    -- RFM-style scoring (simplified)
    CASE 
        WHEN total_orders >= 50 THEN 5
        WHEN total_orders >= 30 THEN 4  
        WHEN total_orders >= 15 THEN 3
        WHEN total_orders >= 5 THEN 2
        ELSE 1
    END AS frequency_score,
    
    CASE 
        WHEN last_order_number >= 80 THEN 5  -- Recent orders
        WHEN last_order_number >= 60 THEN 4
        WHEN last_order_number >= 40 THEN 3
        WHEN last_order_number >= 20 THEN 2
        ELSE 1
    END AS recency_score,
    
    CASE 
        WHEN total_items_purchased >= 500 THEN 5
        WHEN total_items_purchased >= 200 THEN 4
        WHEN total_items_purchased >= 100 THEN 3
        WHEN total_items_purchased >= 50 THEN 2
        ELSE 1  
    END AS monetary_score,
    
    -- Comprehensive customer segmentation
    CASE 
        WHEN total_orders >= 30 AND personal_reorder_rate_pct >= 60 THEN 'VIP Loyal'
        WHEN total_orders >= 15 AND personal_reorder_rate_pct >= 40 THEN 'Regular Loyal'  
        WHEN total_orders >= 30 AND personal_reorder_rate_pct < 40 THEN 'High Volume Explorer'
        WHEN total_orders BETWEEN 10 AND 30 THEN 'Growing Customer'
        WHEN total_orders BETWEEN 5 AND 10 THEN 'Occasional Shopper'
        ELSE 'New/Dormant Customer'
    END AS customer_lifecycle_segment,
    
    -- Churn risk indicators
    CASE 
        WHEN avg_days_between_orders > 45 THEN 'High Risk'
        WHEN avg_days_between_orders > 21 THEN 'Medium Risk'
        ELSE 'Low Risk'  
    END AS churn_risk_level,
    
    -- Detailed metrics
    total_orders,
    avg_days_between_orders,
    unique_products_purchased,
    unique_departments_shopped,
    avg_basket_size,
    personal_reorder_rate_pct,
    active_days_of_week,
    active_hours_of_day,
    
    -- Version tracking
    'g2_v2' AS version_tag,
    now() AS created_at
    
FROM customer_metrics  
ORDER BY total_orders DESC, personal_reorder_rate_pct DESC