-- VLE Content Dimension Table
{{ config(
    materialized='table',
    alias='grp2_dim_vle_content',
    schema='sandbox'
) }}

SELECT DISTINCT
    site_id,
    
    -- VLE identifiers
    code_module,
    code_presentation, 
    
    -- Content attributes
    activity_type,
    week_from,
    week_to,
    
    -- Create course foreign key
    CONCAT(code_module, '_', code_presentation) as course_id,
    
    -- Derived attributes
    (week_to - week_from + 1) as duration_weeks,
    
    CASE 
        WHEN activity_type = 'homepage' THEN 'Navigation'
        WHEN activity_type IN ('resource', 'url') THEN 'Content'
        WHEN activity_type IN ('quiz', 'assignment') THEN 'Assessment'
        WHEN activity_type IN ('forum', 'wiki') THEN 'Collaboration'
        ELSE 'Other'
    END as content_category,
    
    CASE 
        WHEN week_from <= 5 THEN 'Early Course'
        WHEN week_from <= 15 THEN 'Mid Course'
        WHEN week_from <= 25 THEN 'Late Course' 
        ELSE 'Final Period'
    END as course_period,
    
    -- Metadata
    now() as created_at,
    'dbt' as created_by
    
FROM {{ ref('vle_clean') }}
WHERE site_id IS NOT NULL