{{ config(materialized='table', schema='mart') }}

-- Business Analytics: Top Products Performance Analysis
-- Identifies top performing products for inventory management and promotion strategies
WITH product_performance AS (
    SELECT 
        dp.`p.product_id` as product_id,
        dp.`p.product_name` as product_name,
        dp.`a.aisle_name` as aisle,
        dp.`d.department_name` as department,
        
        -- Volume metrics
        COUNT(DISTINCT fop.order_id) as total_orders,
        COUNT(*) as total_quantity_sold,
        COUNT(DISTINCT fop.customer_id) as unique_customers,
        
        -- Reorder behavior 
        SUM(CASE WHEN fop.reordered = 1 THEN 1 ELSE 0 END) as total_reorders,
        ROUND(
            SUM(CASE WHEN fop.reordered = 1 THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 
            2
        ) as reorder_rate_pct,
        
        -- Cart position analysis  
        ROUND(AVG(fop.add_to_cart_order), 2) as avg_cart_position,
        MIN(fop.add_to_cart_order) as min_cart_position,
        MAX(fop.add_to_cart_order) as max_cart_position,
        
        -- Customer penetration
        ROUND(COUNT(DISTINCT fop.customer_id) * 100.0 / 
              (SELECT COUNT(DISTINCT customer_id) FROM {{ ref('g2_v2_fact_order_products_star') }}), 2) as customer_penetration_pct

    FROM {{ ref('g2_v2_fact_order_products_star') }} fop
    LEFT JOIN {{ ref('g2_v2_dim_products_star') }} dp 
        ON CAST(fop.product_id AS String) = CAST(dp.`p.product_id` AS String)
    GROUP BY dp.`p.product_id`, dp.`p.product_name`, dp.`a.aisle_name`, dp.`d.department_name`
),

product_rankings AS (
    SELECT 
        *,
        -- Performance rankings
        ROW_NUMBER() OVER (ORDER BY total_orders DESC) as volume_rank,
        ROW_NUMBER() OVER (ORDER BY reorder_rate_pct DESC) as loyalty_rank,
        ROW_NUMBER() OVER (ORDER BY unique_customers DESC) as reach_rank,
        ROW_NUMBER() OVER (ORDER BY customer_penetration_pct DESC) as penetration_rank,
        
        -- Department rankings
        ROW_NUMBER() OVER (PARTITION BY department ORDER BY total_orders DESC) as dept_volume_rank,
        ROW_NUMBER() OVER (PARTITION BY department ORDER BY reorder_rate_pct DESC) as dept_loyalty_rank,
        
        -- Product classifications
        CASE 
            WHEN reorder_rate_pct >= 80 THEN 'Staple Product'
            WHEN reorder_rate_pct >= 60 THEN 'Regular Product'
            WHEN reorder_rate_pct >= 40 THEN 'Occasional Product'
            ELSE 'Impulse Product'
        END as product_type,
        
        CASE 
            WHEN total_orders >= 10000 THEN 'High Volume'
            WHEN total_orders >= 1000 THEN 'Medium Volume'
            WHEN total_orders >= 100 THEN 'Low Volume'
            ELSE 'Very Low Volume'
        END as volume_category,
        
        CASE 
            WHEN customer_penetration_pct >= 10 THEN 'Mass Market'
            WHEN customer_penetration_pct >= 5 THEN 'Popular'
            WHEN customer_penetration_pct >= 1 THEN 'Niche'
            ELSE 'Specialty'
        END as market_reach
        
    FROM product_performance
)

SELECT 
    product_id,
    product_name,
    aisle,
    department,
    
    -- Performance metrics
    total_orders,
    total_quantity_sold,
    unique_customers,
    total_reorders,
    reorder_rate_pct,
    
    -- Cart behavior
    avg_cart_position,
    
    -- Market metrics
    customer_penetration_pct,
    
    -- Classifications
    product_type,
    volume_category,
    market_reach,
    
    -- Rankings
    volume_rank,
    loyalty_rank,
    reach_rank,
    dept_volume_rank,
    dept_loyalty_rank,
    
    -- Business insights
    CASE 
        WHEN volume_rank <= 100 AND loyalty_rank <= 100 THEN 'Star Product'
        WHEN volume_rank <= 500 AND loyalty_rank <= 200 THEN 'Core Product'  
        WHEN volume_rank <= 1000 AND reorder_rate_pct >= 50 THEN 'Loyal Niche'
        WHEN volume_rank <= 100 AND reorder_rate_pct < 30 THEN 'High Impulse'
        WHEN loyalty_rank <= 100 AND volume_rank > 1000 THEN 'Hidden Gem'
        ELSE 'Standard Product'
    END as strategic_category

FROM product_rankings
ORDER BY total_orders DESC
LIMIT 5000