{{ config(materialized='table', schema='mart') }}

-- Business Analytics: Customer Segmentation & Churn Risk
-- Segments customers by behavior and identifies churn risk for retention campaigns
WITH customer_behavior AS (
    SELECT 
        du.user_id,
        
        -- Order history metrics
        du.total_orders,
        du.total_products,
        du.total_reorders,
        du.avg_days_between_orders,
        du.user_reorder_rate,
        
        -- Recency analysis
        du.days_since_first_order,
        du.days_since_last_order,
        
        -- Basket behavior
        ROUND(du.total_products * 1.0 / du.total_orders, 2) as avg_basket_size,
        
        -- Time patterns from orders
        fo.max_order_number,
        fo.avg_days_since_prior_order,
        fo.most_frequent_dow,
        fo.most_frequent_hour,
        
        -- Engagement metrics
        CASE 
            WHEN du.days_since_last_order <= 7 THEN 'Active'
            WHEN du.days_since_last_order <= 30 THEN 'Recent'  
            WHEN du.days_since_last_order <= 90 THEN 'Declining'
            ELSE 'Dormant'
        END as recency_segment,
        
        CASE 
            WHEN du.total_orders >= 50 THEN 'High Frequency'
            WHEN du.total_orders >= 20 THEN 'Medium Frequency'
            WHEN du.total_orders >= 5 THEN 'Low Frequency'
            ELSE 'New Customer'
        END as frequency_segment,
        
        CASE 
            WHEN du.user_reorder_rate >= 80 THEN 'Highly Loyal'
            WHEN du.user_reorder_rate >= 60 THEN 'Loyal'
            WHEN du.user_reorder_rate >= 40 THEN 'Moderately Loyal'
            ELSE 'Low Loyalty'
        END as loyalty_segment

    FROM {{ ref('g2_v2_dim_users_star') }} du
    LEFT JOIN {{ ref('g2_v2_fact_orders_star') }} fo 
        ON CAST(du.user_id AS String) = CAST(fo.user_id AS String)
),

customer_segments AS (
    SELECT 
        *,
        -- RFM-style segmentation
        CASE 
            WHEN recency_segment = 'Active' AND frequency_segment IN ('High Frequency', 'Medium Frequency') 
                 AND loyalty_segment IN ('Highly Loyal', 'Loyal') THEN 'VIP Champions'
            WHEN recency_segment IN ('Active', 'Recent') AND frequency_segment = 'High Frequency' THEN 'Loyal Customers'
            WHEN recency_segment = 'Active' AND frequency_segment IN ('Low Frequency', 'New Customer') THEN 'New Customers'
            WHEN recency_segment = 'Recent' AND loyalty_segment IN ('Highly Loyal', 'Loyal') THEN 'Potential Loyalists'
            WHEN recency_segment IN ('Declining', 'Dormant') AND frequency_segment = 'High Frequency' THEN 'At Risk'
            WHEN recency_segment = 'Declining' AND frequency_segment IN ('Medium Frequency', 'Low Frequency') THEN 'Cannot Lose'
            WHEN recency_segment = 'Dormant' THEN 'Lost Customers'
            ELSE 'Others'
        END as customer_segment,
        
        -- Churn risk scoring (0-100 scale)
        CAST(
            (CASE 
                WHEN recency_segment = 'Dormant' THEN 40
                WHEN recency_segment = 'Declining' THEN 25  
                WHEN recency_segment = 'Recent' THEN 10
                ELSE 5
            END) +
            (CASE 
                WHEN frequency_segment = 'New Customer' THEN 20
                WHEN frequency_segment = 'Low Frequency' THEN 15
                WHEN frequency_segment = 'Medium Frequency' THEN 5
                ELSE 0
            END) +
            (CASE 
                WHEN loyalty_segment = 'Low Loyalty' THEN 20
                WHEN loyalty_segment = 'Moderately Loyal' THEN 10
                WHEN loyalty_segment = 'Loyal' THEN 5
                ELSE 0
            END) +
            (CASE 
                WHEN avg_days_between_orders > 30 THEN 15
                WHEN avg_days_between_orders > 14 THEN 10
                ELSE 0
            END)
        AS UInt8) as churn_risk_score
        
    FROM customer_behavior
)

SELECT 
    user_id,
    
    -- Behavioral metrics
    total_orders,
    total_products, 
    avg_basket_size,
    user_reorder_rate,
    days_since_last_order,
    avg_days_between_orders,
    
    -- Time patterns
    most_frequent_dow,
    most_frequent_hour,
    
    -- Segmentation
    recency_segment,
    frequency_segment,
    loyalty_segment,
    customer_segment,
    
    -- Churn analysis
    churn_risk_score,
    CASE 
        WHEN churn_risk_score >= 70 THEN 'High Risk'
        WHEN churn_risk_score >= 40 THEN 'Medium Risk'
        WHEN churn_risk_score >= 20 THEN 'Low Risk'
        ELSE 'Stable'
    END as churn_risk_level,
    
    -- Recommended actions
    CASE 
        WHEN customer_segment = 'VIP Champions' THEN 'Reward & Retain'
        WHEN customer_segment = 'Loyal Customers' THEN 'Maintain Satisfaction'
        WHEN customer_segment = 'New Customers' THEN 'Onboard & Educate'
        WHEN customer_segment = 'Potential Loyalists' THEN 'Engage & Convert'
        WHEN customer_segment = 'At Risk' THEN 'Win Back Campaign'
        WHEN customer_segment = 'Cannot Lose' THEN 'Urgent Retention'
        WHEN customer_segment = 'Lost Customers' THEN 'Re-activation Campaign'
        ELSE 'Monitor'
    END as recommended_action

FROM customer_segments
ORDER BY churn_risk_score DESC, total_orders DESC