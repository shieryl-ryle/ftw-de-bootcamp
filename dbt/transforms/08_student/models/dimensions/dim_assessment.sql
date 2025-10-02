-- Assessment Dimension Table
{{ config(
    materialized='table',
    alias='grp2_dim_assessment',
    schema='mart'
) }}

SELECT DISTINCT
    assessment_id,
    
    -- Assessment identifiers  
    code_module,
    code_presentation,
    
    -- Assessment attributes
    assessment_type,
    assessment_date,
    weight_percentage,
    weight_category,
    
    -- Create course foreign key
    CONCAT(code_module, '_', code_presentation) as course_id,
    
    -- Derived attributes
    CASE 
        WHEN assessment_date <= 100 THEN 'Early'
        WHEN assessment_date <= 200 THEN 'Mid'  
        WHEN assessment_date <= 300 THEN 'Late'
        ELSE 'Final'
    END as assessment_timing,
    
    -- Metadata
    now() as created_at,
    'dbt' as created_by
    
FROM {{ ref('assessments_clean') }}
WHERE assessment_id IS NOT NULL