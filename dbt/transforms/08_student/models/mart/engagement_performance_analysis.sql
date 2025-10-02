-- BUSINESS QUESTION 2: How does engagement in the VLE impact performance?
{{ config(
    materialized='view',
    alias='grp2_engagement_performance_analysis'
) }}

WITH engagement_stats AS (
    SELECT 
        v.engagement_level,
        COUNT(*) as total_students,
        AVG(v.total_clicks) as avg_clicks,
        AVG(v.active_days) as avg_active_days,
        
        -- Success metrics (from student demographics)
        COUNT(s.student_id) as students_with_outcome,
        SUM(CASE WHEN s.is_successful = 1 THEN 1 ELSE 0 END) as successful_students,
        SUM(CASE WHEN s.is_dropout = 1 THEN 1 ELSE 0 END) as dropout_students,
        
        -- Calculate success rates  
        ROUND(
            SUM(CASE WHEN s.is_successful = 1 THEN 1 ELSE 0 END) * 100.0 / COUNT(s.student_id), 
            2
        ) as success_rate_pct,
        
        ROUND(
            SUM(CASE WHEN s.is_dropout = 1 THEN 1 ELSE 0 END) * 100.0 / COUNT(s.student_id), 
            2
        ) as dropout_rate_pct,
        
        -- Assessment performance where available
        COUNT(a.student_id) as students_with_assessments,
        AVG(a.avg_score) as avg_assessment_score,
        AVG(a.first_assessment_score) as avg_first_score
        
    FROM {{ ref('vle_engagement_clean') }} v
    LEFT JOIN {{ ref('student_demographics_clean') }} s
        ON v.student_id = s.student_id 
        AND v.code_module = s.code_module 
        AND v.code_presentation = s.code_presentation
    LEFT JOIN {{ ref('assessment_performance_clean') }} a
        ON v.student_id = a.student_id
        AND v.code_module = a.code_module 
        AND v.code_presentation = a.code_presentation
    WHERE v.engagement_level IS NOT NULL
    GROUP BY v.engagement_level
),

click_volume_analysis AS (
    SELECT 
        'Click Volume Analysis' as analysis_type,
        CASE 
            WHEN v.total_clicks >= 1000 THEN 'High Clicks (1000+)'
            WHEN v.total_clicks >= 300 THEN 'Medium Clicks (300-1000)'
            ELSE 'Low Clicks (<300)'
        END as engagement_level,
        
        COUNT(*) as students,
        AVG(v.total_clicks) as avg_clicks,
        
        -- Success rate where outcome is available
        ROUND(
            SUM(CASE WHEN s.is_successful = 1 THEN 1 ELSE 0 END) * 100.0 / 
            GREATEST(COUNT(s.student_id), 1), 2
        ) as success_rate_pct,
        
        AVG(a.avg_score) as avg_performance_score
        
    FROM {{ ref('vle_engagement_clean') }} v
    LEFT JOIN {{ ref('student_demographics_clean') }} s
        ON v.student_id = s.student_id 
        AND v.code_module = s.code_module 
        AND v.code_presentation = s.code_presentation
    LEFT JOIN {{ ref('assessment_performance_clean') }} a
        ON v.student_id = a.student_id
        AND v.code_module = a.code_module
        AND v.code_presentation = a.code_presentation
    GROUP BY 
        CASE 
            WHEN v.total_clicks >= 1000 THEN 'High Clicks (1000+)'
            WHEN v.total_clicks >= 300 THEN 'Medium Clicks (300-1000)'
            ELSE 'Low Clicks (<300)'
        END
)

-- Main output combining both analyses
SELECT 
    'Engagement Level Analysis' as analysis_type,
    engagement_level as dimension,
    NULL as sub_dimension,
    total_students,
    successful_students,
    success_rate_pct,
    dropout_rate_pct,
    avg_first_score as avg_first_assessment,
    avg_assessment_score as avg_overall_score,
    ROUND(avg_clicks, 0) as avg_total_clicks,
    ROUND(avg_active_days, 1) as avg_days_active,
    
    CASE 
        WHEN total_students >= 100 THEN 'High Confidence'
        WHEN total_students >= 30 THEN 'Medium Confidence'
        ELSE 'Low Confidence'
    END as statistical_confidence
    
FROM engagement_stats
WHERE total_students >= 10

UNION ALL

SELECT 
    analysis_type,
    engagement_level as dimension,
    NULL as sub_dimension,
    students as total_students,
    NULL as successful_students,
    success_rate_pct,
    NULL as dropout_rate_pct,
    NULL as avg_first_assessment,
    avg_performance_score as avg_overall_score,
    ROUND(avg_clicks, 0) as avg_total_clicks,
    NULL as avg_days_active,
    
    CASE 
        WHEN students >= 100 THEN 'High Confidence'
        WHEN students >= 30 THEN 'Medium Confidence'
        ELSE 'Low Confidence'
    END as statistical_confidence
    
FROM click_volume_analysis
WHERE students >= 10

ORDER BY analysis_type, success_rate_pct DESC