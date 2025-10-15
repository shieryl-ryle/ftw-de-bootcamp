{{ config(materialized='table', schema='mart') }}

-- Business Analytics: Department & Aisle Performance
-- Identifies top performing departments and aisles for category management
WITH department_metrics AS (
    SELECT 
        dp.`a.department_id` as department_id,
        dp.`d.department_name` as department,
        
        -- Volume metrics
        COUNT(DISTINCT fop.order_id) as total_orders,
        COUNT(*) as total_items_sold,
        COUNT(DISTINCT fop.product_id) as unique_products,
        COUNT(DISTINCT fop.customer_id) as unique_customers,
        
        -- Behavioral metrics
        ROUND(AVG(fop.add_to_cart_order), 2) as avg_cart_position,
        SUM(CASE WHEN fop.reordered = 1 THEN 1 ELSE 0 END) as reorder_items,
        ROUND(
            SUM(CASE WHEN fop.reordered = 1 THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 
            2
        ) as dept_reorder_rate_pct,
        
        -- Time patterns  
        ROUND(COUNT(*) * 1.0 / 365, 2) as avg_daily_volume
        
    FROM {{ ref('g2_v2_fact_order_products_star') }} fop
    LEFT JOIN {{ ref('g2_v2_dim_products_star') }} dp 
        ON CAST(fop.product_id AS String) = CAST(dp.`p.product_id` AS String)
    LEFT JOIN {{ ref('g2_v2_dim_time_star') }} dt 
        ON CAST(fop.time_key AS String) = CAST(dt.time_key AS String)
    GROUP BY dp.`a.department_id`, dp.`d.department_name`
),

aisle_metrics AS (
    SELECT 
        dp.`d.department_name` as department,
        dp.`p.aisle_id` as aisle_id,
        dp.`a.aisle_name` as aisle,
        
        -- Volume metrics  
        COUNT(DISTINCT fop.order_id) as aisle_total_orders,
        COUNT(*) as aisle_items_sold,
        COUNT(DISTINCT fop.product_id) as aisle_unique_products,
        COUNT(DISTINCT fop.customer_id) as aisle_customers,
        
        -- Performance metrics
        ROUND(AVG(fop.add_to_cart_order), 2) as aisle_avg_cart_position,
        ROUND(
            SUM(CASE WHEN fop.reordered = 1 THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 
            2
        ) as aisle_reorder_rate_pct
        
    FROM {{ ref('g2_v2_fact_order_products_star') }} fop
    LEFT JOIN {{ ref('g2_v2_dim_products_star') }} dp 
        ON CAST(fop.product_id AS String) = CAST(dp.`p.product_id` AS String)
    GROUP BY dp.`d.department_name`, dp.`p.aisle_id`, dp.`a.aisle_name`
)

SELECT 
    -- Department performance
    dm.department_id,
    dm.department,
    dm.total_orders as dept_orders,
    dm.total_items_sold as dept_items,
    dm.unique_products as dept_products,
    dm.unique_customers as dept_customers,
    dm.avg_cart_position as dept_avg_cart_pos,
    dm.dept_reorder_rate_pct,
    dm.avg_daily_volume as dept_daily_volume,
    
    -- Top aisle in department
    am.aisle_id as top_aisle_id,
    am.aisle as top_aisle_name,
    am.aisle_total_orders,
    am.aisle_items_sold,
    am.aisle_reorder_rate_pct,
    
    -- Rankings
    ROW_NUMBER() OVER (ORDER BY dm.total_orders DESC) as dept_volume_rank,
    ROW_NUMBER() OVER (ORDER BY dm.dept_reorder_rate_pct DESC) as dept_loyalty_rank,
    ROW_NUMBER() OVER (ORDER BY dm.unique_customers DESC) as dept_reach_rank,
    
    -- Category classification
    CASE 
        WHEN dm.dept_reorder_rate_pct >= 70 THEN 'Staple Category'
        WHEN dm.dept_reorder_rate_pct >= 50 THEN 'Regular Category'
        ELSE 'Impulse Category'
    END as category_type,
    
    CASE 
        WHEN dm.total_orders >= 100000 THEN 'High Traffic'
        WHEN dm.total_orders >= 10000 THEN 'Medium Traffic'
        ELSE 'Low Traffic' 
    END as traffic_level

FROM department_metrics dm
LEFT JOIN (
    -- Get top aisle per department by volume
    SELECT *
    FROM (
        SELECT *,
               ROW_NUMBER() OVER (PARTITION BY department ORDER BY aisle_total_orders DESC) as rn
        FROM aisle_metrics
    ) ranked_aisles
    WHERE rn = 1
) am ON dm.department = am.department

ORDER BY dm.total_orders DESC