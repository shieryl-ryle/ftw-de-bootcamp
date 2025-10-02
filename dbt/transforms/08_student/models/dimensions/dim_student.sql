-- Student Dimension Table
{{ config(
    materialized='table',
    alias='grp2_dim_student',
    schema='mart'
) }}

SELECT DISTINCT
    student_id,
    
    -- Demographics
    gender,
    region,
    age_band,
    highest_education,
    has_disability,
    imd_band,
    
    -- Academic history
    num_of_prev_attempts,
    studied_credits,
    
    -- Metadata
    now() as created_at,
    'dbt' as created_by
    
FROM {{ ref('student_info_clean') }}
WHERE student_id IS NOT NULL