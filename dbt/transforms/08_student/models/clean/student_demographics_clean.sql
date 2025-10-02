-- Clean Student Demographics - focused on dropout analysis
{{ config(
    materialized='table',
    alias='grp2_student_demographics_clean'
) }}

SELECT 
    student_id,
    
    -- Demographics for dropout analysis
    gender,
    region, 
    age_band,
    highest_education,
    imd_band,  -- Deprivation index
    has_disability,
    
    -- Academic history (dropout predictors)
    num_of_prev_attempts,
    studied_credits,
    
    -- Course context  
    code_module,
    code_presentation,
    final_result,
    
    -- Dropout indicator (key business metric)
    CASE 
        WHEN final_result = 'Withdrawn' THEN 1
        ELSE 0
    END as is_dropout,
    
    -- Success indicator
    CASE 
        WHEN final_result IN ('Pass', 'Distinction') THEN 1
        ELSE 0  
    END as is_successful,
    
    -- Risk categories based on demographics
    CASE 
        WHEN num_of_prev_attempts > 0 THEN 'High Risk'
        WHEN has_disability = 'Yes' THEN 'Medium Risk'
        WHEN imd_band IN ('0-10%', '10-20%') THEN 'Medium Risk'
        ELSE 'Low Risk'
    END as dropout_risk_profile,
    
    -- Create composite keys
    CONCAT(code_module, '_', code_presentation) as course_key,
    
    now() as processed_at
    
FROM {{ ref('student_info_clean') }}
WHERE student_id IS NOT NULL