-- Student Performance Data Mart
{{ config(
    materialized='view',
    alias='grp2_mart_student_performance',
    schema='sandbox'
) }}

SELECT 
    -- Student information
    ds.student_id,
    ds.gender,
    ds.region,
    ds.age_band,
    ds.highest_education,
    
    -- Course information
    dc.code_module,
    dc.code_presentation,
    dc.course_duration_category,
    
    -- Performance metrics
    AVG(fsa.score) as avg_assessment_score,
    COUNT(fsa.assessment_id) as total_assessments,
    SUM(fsa.is_pass) as assessments_passed,
    SUM(fsa.is_distinction) as distinctions_earned,
    
    -- Engagement metrics  
    COUNT(DISTINCT fvi.interaction_date) as active_days,
    SUM(fvi.click_count) as total_clicks,
    AVG(fvi.click_count) as avg_daily_clicks,
    
    -- Outcome
    fr.final_result,
    fr.is_successful,
    fr.days_enrolled,
    
    -- Performance categories
    CASE 
        WHEN AVG(fsa.score) >= 85 THEN 'High Performer'
        WHEN AVG(fsa.score) >= 70 THEN 'Good Performer'  
        WHEN AVG(fsa.score) >= 40 THEN 'Average Performer'
        ELSE 'At Risk'
    END as performance_category,
    
    CASE 
        WHEN SUM(fvi.click_count) >= 1000 THEN 'Highly Engaged'
        WHEN SUM(fvi.click_count) >= 100 THEN 'Moderately Engaged'
        WHEN SUM(fvi.click_count) > 0 THEN 'Lightly Engaged'  
        ELSE 'Disengaged'
    END as engagement_category

FROM {{ ref('dim_student') }} ds
JOIN {{ ref('fact_registrations') }} fr 
    ON ds.student_id = fr.student_id
JOIN {{ ref('dim_course') }} dc
    ON fr.course_id = dc.course_id
LEFT JOIN {{ ref('fact_student_assessments') }} fsa
    ON ds.student_id = fsa.student_id  
    AND fr.course_id = fsa.course_id
LEFT JOIN {{ ref('fact_vle_interactions') }} fvi
    ON ds.student_id = fvi.student_id
    AND fr.course_id = fvi.course_id
    
GROUP BY 
    ds.student_id, ds.gender, ds.region, ds.age_band, ds.highest_education,
    dc.code_module, dc.code_presentation, dc.course_duration_category,
    fr.final_result, fr.is_successful, fr.days_enrolled