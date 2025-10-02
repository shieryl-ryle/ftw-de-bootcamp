-- VLE Interactions Fact Table  
{{ config(
    materialized='table',
    alias='grp2_fact_vle_interactions',
    schema='mart'
) }}

SELECT 
    -- Surrogate key
    CONCAT(sv.student_id, '_', sv.site_id, '_', sv.date) as fact_key,
    
    -- Foreign keys
    sv.student_id,
    sv.site_id, 
    CONCAT(sv.code_module, '_', sv.code_presentation) as course_id,
    sv.date as interaction_date,
    
    -- Measures
    sv.sum_click as click_count,
    
    -- Derived measures
    CASE 
        WHEN sv.sum_click > 100 THEN 1 ELSE 0
    END as is_high_engagement,
    
    CASE 
        WHEN sv.sum_click > 0 THEN 1 ELSE 0  
    END as is_active,
    
    -- Session categorization
    CASE 
        WHEN sv.sum_click >= 50 THEN 'Intensive'
        WHEN sv.sum_click >= 10 THEN 'Moderate'
        WHEN sv.sum_click > 0 THEN 'Light'
        ELSE 'Passive'
    END as session_intensity,
    
    -- Metadata
    now() as created_at
    
FROM {{ ref('student_vle_clean') }} sv
WHERE sv.student_id IS NOT NULL 
  AND sv.site_id IS NOT NULL
  AND sv.date IS NOT NULL