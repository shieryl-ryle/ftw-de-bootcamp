-- Student Journey Analysis - Complete student lifecycle view
{{ config(
    materialized='view',
    alias='grp2_student_journey_complete',
    schema='sandbox'
) }}

WITH student_base AS (
    SELECT 
        si.student_id,
        si.code_module,
        si.code_presentation,
        si.gender,
        si.region,
        si.highest_education,
        si.age_band,
        si.has_disability,
        si.final_result,
        
        -- Course info
        c.module_presentation_length,
        c.course_duration_category,
        c.presentation_year,
        c.presentation_period,
        
        -- Registration info  
        sr.date_registration,
        sr.date_unregistration,
        sr.registration_status
        
    FROM {{ ref('student_info_clean') }} si
    LEFT JOIN {{ ref('courses_clean') }} c
        ON si.code_module = c.code_module 
        AND si.code_presentation = c.code_presentation
    LEFT JOIN {{ ref('student_registration_clean') }} sr
        ON si.student_id = sr.student_id
        AND si.code_module = sr.code_module
        AND si.code_presentation = sr.code_presentation
),

assessment_performance AS (
    SELECT 
        sa.student_id,
        a.code_module,
        a.code_presentation,
        COUNT(sa.assessment_id) as total_assessments,
        AVG(sa.score) as avg_assessment_score,
        SUM(CASE WHEN sa.pass_fail_status = 'Pass' THEN 1 ELSE 0 END) as assessments_passed,
        SUM(CASE WHEN sa.score IS NULL THEN 1 ELSE 0 END) as assessments_not_submitted
        
    FROM {{ ref('student_assessment_clean') }} sa
    JOIN {{ ref('assessments_clean') }} a
        ON sa.assessment_id = a.assessment_id
    GROUP BY sa.student_id, a.code_module, a.code_presentation
),

vle_engagement AS (
    SELECT 
        sv.student_id,
        sv.code_module, 
        sv.code_presentation,
        COUNT(DISTINCT sv.site_id) as unique_vle_sites_accessed,
        SUM(sv.sum_click) as total_vle_clicks,
        COUNT(DISTINCT sv.date) as days_active_on_vle,
        AVG(sv.sum_click) as avg_daily_clicks
        
    FROM {{ ref('student_vle_clean') }} sv
    GROUP BY sv.student_id, sv.code_module, sv.code_presentation
)

SELECT 
    sb.*,
    
    -- Assessment metrics
    COALESCE(ap.total_assessments, 0) as total_assessments,
    COALESCE(ap.avg_assessment_score, 0) as avg_assessment_score,
    COALESCE(ap.assessments_passed, 0) as assessments_passed,
    COALESCE(ap.assessments_not_submitted, 0) as assessments_not_submitted,
    
    -- VLE engagement metrics
    COALESCE(ve.unique_vle_sites_accessed, 0) as unique_vle_sites_accessed,
    COALESCE(ve.total_vle_clicks, 0) as total_vle_clicks,
    COALESCE(ve.days_active_on_vle, 0) as days_active_on_vle,
    COALESCE(ve.avg_daily_clicks, 0) as avg_daily_clicks,
    
    -- Derived insights
    CASE 
        WHEN sb.final_result IN ('Pass', 'Distinction') THEN 'Success'
        WHEN sb.final_result = 'Fail' THEN 'Failure'
        WHEN sb.final_result = 'Withdrawn' THEN 'Withdrawal'
        ELSE 'Other'
    END as outcome_category,
    
    CASE 
        WHEN ve.total_vle_clicks >= 1000 THEN 'High Engagement'
        WHEN ve.total_vle_clicks >= 100 THEN 'Medium Engagement'
        WHEN ve.total_vle_clicks > 0 THEN 'Low Engagement'
        ELSE 'No Engagement'
    END as engagement_level,
    
    CASE 
        WHEN ap.avg_assessment_score >= 70 THEN 'High Performer'
        WHEN ap.avg_assessment_score >= 40 THEN 'Average Performer'
        WHEN ap.avg_assessment_score > 0 THEN 'Low Performer'
        ELSE 'No Assessment Data'
    END as performance_level,
    
    -- Create comprehensive student key
    CONCAT(toString(sb.student_id), '_', sb.code_module, '_', sb.code_presentation) as student_journey_key

FROM student_base sb
LEFT JOIN assessment_performance ap
    ON sb.student_id = ap.student_id
    AND sb.code_module = ap.code_module
    AND sb.code_presentation = ap.code_presentation
LEFT JOIN vle_engagement ve
    ON sb.student_id = ve.student_id  
    AND sb.code_module = ve.code_module
    AND sb.code_presentation = ve.code_presentation