-- Student Assessment Fact Table
{{ config(
    materialized='table',
    alias='grp2_fact_student_assessments',
    schema='mart'
) }}

SELECT 
    -- Surrogate key
    CONCAT(sa.student_id, '_', sa.assessment_id) as fact_key,
    
    -- Foreign keys
    sa.student_id,
    sa.assessment_id,
    a.course_id,
    
    -- Measures
    sa.score,
    sa.date_submitted,
    sa.is_banked,
    
    -- Derived measures
    CASE 
        WHEN sa.score >= 85 THEN 1 ELSE 0
    END as is_distinction,
    
    CASE 
        WHEN sa.score >= 40 THEN 1 ELSE 0  
    END as is_pass,
    
    CASE 
        WHEN sa.date_submitted IS NOT NULL THEN 1 ELSE 0
    END as is_submitted,
    
    -- Calculate days late (if submission after assessment date)
    CASE 
        WHEN sa.date_submitted > a.assessment_date 
        THEN sa.date_submitted - a.assessment_date
        ELSE 0
    END as days_late,
    
    -- Metadata
    now() as created_at
    
FROM {{ ref('student_assessment_clean') }} sa
LEFT JOIN {{ ref('dim_assessment') }} a
    ON sa.assessment_id = a.assessment_id