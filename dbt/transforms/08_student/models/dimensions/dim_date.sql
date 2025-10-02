-- Date Dimension Table (Critical for time-based analytics)
{{ config(
    materialized='table',
    alias='grp2_dim_date',
    schema='sandbox'
) }}

WITH date_spine AS (
    -- Generate dates from course data
    SELECT DISTINCT date_registration as date_value
    FROM {{ ref('student_registration_clean') }}
    WHERE date_registration IS NOT NULL
    
    UNION ALL
    
    SELECT DISTINCT date_unregistration as date_value  
    FROM {{ ref('student_registration_clean') }}
    WHERE date_unregistration IS NOT NULL
    
    UNION ALL
    
    SELECT DISTINCT assessment_date as date_value
    FROM {{ ref('assessments_clean') }}
    WHERE assessment_date IS NOT NULL
    
    UNION ALL
    
    SELECT DISTINCT date as date_value
    FROM {{ ref('student_vle_clean') }}  
    WHERE date IS NOT NULL
)

SELECT 
    date_value as date_id,
    date_value,
    
    -- Date components (if date_value represents days from start)
    CASE 
        WHEN date_value <= 31 THEN 1
        WHEN date_value <= 59 THEN 2  
        WHEN date_value <= 90 THEN 3
        WHEN date_value <= 120 THEN 4
        WHEN date_value <= 151 THEN 5
        WHEN date_value <= 181 THEN 6
        WHEN date_value <= 212 THEN 7
        WHEN date_value <= 243 THEN 8
        WHEN date_value <= 273 THEN 9
        WHEN date_value <= 304 THEN 10
        WHEN date_value <= 334 THEN 11
        ELSE 12
    END as month_number,
    
    CASE 
        WHEN date_value <= 91 THEN 1
        WHEN date_value <= 182 THEN 2  
        WHEN date_value <= 273 THEN 3
        ELSE 4
    END as quarter,
    
    CASE 
        WHEN date_value <= 7 THEN 'Week 1'
        WHEN date_value <= 14 THEN 'Week 2'
        WHEN date_value <= 21 THEN 'Week 3'  
        WHEN date_value <= 28 THEN 'Week 4'
        ELSE CONCAT('Week ', CAST(date_value / 7 + 1 AS String))
    END as week_description,
    
    CASE 
        WHEN date_value <= 100 THEN 'Early Course'
        WHEN date_value <= 200 THEN 'Mid Course'  
        WHEN date_value <= 300 THEN 'Late Course'
        ELSE 'Final Period'
    END as course_period,
    
    -- Metadata
    now() as created_at,
    'dbt' as created_by
    
FROM date_spine
WHERE date_value IS NOT NULL
ORDER BY date_value