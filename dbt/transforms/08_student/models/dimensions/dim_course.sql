-- Course Dimension Table
{{ config(
    materialized='table',
    alias='grp2_dim_course',
    schema='mart'
) }}

SELECT DISTINCT
    -- Create composite course key
    CONCAT(code_module, '_', code_presentation) as course_id,
    
    -- Course identifiers
    code_module,
    code_presentation,
    
    -- Course attributes
    module_presentation_length,
    course_duration_category,
    presentation_year,
    presentation_period,
    
    -- Derived attributes
    CASE 
        WHEN presentation_period = 'B' THEN 'February'
        WHEN presentation_period = 'J' THEN 'October' 
        ELSE 'Unknown'
    END as presentation_month,
    
    -- Metadata
    now() as created_at,
    'dbt' as created_by
    
FROM {{ ref('courses_clean') }}
WHERE code_module IS NOT NULL 
  AND code_presentation IS NOT NULL