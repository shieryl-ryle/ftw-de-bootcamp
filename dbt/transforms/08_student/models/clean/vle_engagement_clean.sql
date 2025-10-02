-- Clean VLE Engagement - focused on performance impact analysis  
{{ config(
    materialized='table',
    alias='grp2_vle_engagement_clean'
) }}

SELECT 
    id_student as student_id,
    code_module,
    code_presentation,
    
    -- Engagement metrics (key business metrics)
    COUNT(DISTINCT id_site) as unique_resources_accessed,
    COUNT(DISTINCT date) as active_days,
    SUM(sum_click) as total_clicks,
    AVG(sum_click) as avg_daily_clicks,
    MAX(sum_click) as max_daily_clicks,
    
    -- Engagement patterns
    COUNT(CASE WHEN sum_click > 50 THEN 1 END) as high_intensity_days,
    COUNT(CASE WHEN sum_click BETWEEN 10 AND 50 THEN 1 END) as medium_intensity_days,
    COUNT(CASE WHEN sum_click BETWEEN 1 AND 9 THEN 1 END) as low_intensity_days,
    
    -- Temporal engagement patterns
    MIN(date) as first_interaction_date,
    MAX(date) as last_interaction_date,
    (MAX(date) - MIN(date) + 1) as engagement_span_days,
    
    -- Engagement categorization (for performance analysis)
    CASE 
        WHEN SUM(sum_click) >= 1000 THEN 'High Engagement'
        WHEN SUM(sum_click) >= 300 THEN 'Medium Engagement'  
        WHEN SUM(sum_click) >= 50 THEN 'Low Engagement'
        ELSE 'Minimal Engagement'
    END as engagement_level,
    
    -- Consistency metrics
    CASE 
        WHEN COUNT(DISTINCT date) >= 30 THEN 'Consistent'
        WHEN COUNT(DISTINCT date) >= 10 THEN 'Moderate'
        ELSE 'Sporadic'
    END as engagement_consistency,
    
    -- Course progress tracking
    CASE 
        WHEN MAX(date) > 250 THEN 'Engaged Until End'
        WHEN MAX(date) > 150 THEN 'Dropped Off Late'
        WHEN MAX(date) > 50 THEN 'Dropped Off Mid'  
        ELSE 'Dropped Off Early'
    END as engagement_timeline,
    
    -- Create composite key
    CONCAT(code_module, '_', code_presentation) as course_key,
    
    now() as processed_at
    
FROM {{ source('raw', 'grp2_oulad___student_vle') }}
WHERE id_student IS NOT NULL
  AND sum_click > 0  -- Only actual interactions
GROUP BY id_student, code_module, code_presentation