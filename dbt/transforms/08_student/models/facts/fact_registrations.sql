-- Student Registration Fact Table
{{ config(
    materialized='table',
    alias='grp2_fact_registrations',
    schema='sandbox'
) }}

SELECT 
    -- Surrogate key
    CONCAT(sr.student_id, '_', sr.code_module, '_', sr.code_presentation) as fact_key,
    
    -- Foreign keys  
    sr.student_id,
    CONCAT(sr.code_module, '_', sr.code_presentation) as course_id,
    
    -- Measures
    sr.date_registration,
    sr.date_unregistration,
    si.final_result,
    
    -- Derived measures
    CASE 
        WHEN sr.date_unregistration IS NOT NULL 
        THEN sr.date_unregistration - sr.date_registration
        ELSE NULL
    END as days_enrolled,
    
    CASE 
        WHEN si.final_result IN ('Pass', 'Distinction') THEN 1 ELSE 0
    END as is_successful,
    
    CASE 
        WHEN si.final_result = 'Withdrawn' THEN 1 ELSE 0
    END as is_withdrawn,
    
    CASE 
        WHEN sr.date_unregistration IS NOT NULL THEN 1 ELSE 0
    END as is_unregistered,
    
    -- Calculate completion rate proxy
    CASE 
        WHEN si.final_result IS NOT NULL THEN 1 ELSE 0
    END as has_final_result,
    
    -- Metadata
    now() as created_at
    
FROM {{ ref('student_registration_clean') }} sr
LEFT JOIN {{ ref('student_info_clean') }} si
    ON sr.student_id = si.student_id 
    AND sr.code_module = si.code_module
    AND sr.code_presentation = si.code_presentation
WHERE sr.student_id IS NOT NULL