-- VLE activity patterns and content engagement analysis
{{ config(
    materialized='view',
    alias='grp2_vle_content_analysis',
    schema='sandbox'
) }}

WITH vle_activity_summary AS (
    SELECT 
        v.site_id,
        v.code_module,
        v.code_presentation,
        v.activity_type,
        v.activity_category,
        v.week_from,
        v.week_to,
        v.activity_duration_weeks,
        
        -- Student engagement with this VLE item
        COUNT(DISTINCT sv.student_id) AS unique_students,
        SUM(sv.sum_click) AS total_clicks,
        AVG(sv.sum_click) AS avg_clicks_per_student,
        
        -- Activity popularity metrics
        COUNT(sv.interaction_key) AS total_interactions,
        
        CASE 
            WHEN COUNT(DISTINCT sv.student_id) >= 50 THEN 'High_Usage'
            WHEN COUNT(DISTINCT sv.student_id) >= 10 THEN 'Medium_Usage'
            WHEN COUNT(DISTINCT sv.student_id) > 0 THEN 'Low_Usage'
            ELSE 'No_Usage'
        END AS usage_category
        
    FROM {{ ref('vle_clean') }} v
    LEFT JOIN {{ ref('student_vle_clean') }} sv 
        ON v.site_course_key = CONCAT(sv.code_module, '_', sv.code_presentation, '_', toString(sv.site_id))
    
    GROUP BY 
        v.site_id, v.code_module, v.code_presentation, v.activity_type, 
        v.activity_category, v.week_from, v.week_to, v.activity_duration_weeks
)

SELECT *,
    -- Content effectiveness scoring
    CASE 
        WHEN usage_category = 'High_Usage' AND avg_clicks_per_student >= 10 THEN 'Highly_Effective'
        WHEN usage_category IN ('High_Usage', 'Medium_Usage') AND avg_clicks_per_student >= 5 THEN 'Effective'
        WHEN usage_category IN ('Medium_Usage', 'Low_Usage') AND avg_clicks_per_student >= 1 THEN 'Moderately_Effective'
        WHEN usage_category = 'No_Usage' OR avg_clicks_per_student = 0 THEN 'Ineffective'
        ELSE 'Under_Review'
    END AS content_effectiveness,
    
    -- Week timing analysis
    CASE
        WHEN week_from <= 5 THEN 'Early_Course'
        WHEN week_from <= 15 THEN 'Mid_Course' 
        WHEN week_from <= 25 THEN 'Late_Course'
        ELSE 'End_Course'
    END AS course_timing

FROM vle_activity_summary
ORDER BY total_clicks DESC