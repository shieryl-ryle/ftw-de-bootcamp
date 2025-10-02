-- Student performance analysis by demographics
{{ config(
    materialized='view',
    alias='grp2_student_performance_by_demographics',
    schema='sandbox'
) }}

SELECT 
    gender,
    age_band,
    highest_education,
    has_disability,
    COUNT(*) as total_students,
    COUNT(CASE WHEN final_result = 'Pass' THEN 1 END) as passed_students,
    COUNT(CASE WHEN final_result = 'Fail' THEN 1 END) as failed_students,
    COUNT(CASE WHEN final_result = 'Withdrawn' THEN 1 END) as withdrawn_students,
    COUNT(CASE WHEN final_result = 'Distinction' THEN 1 END) as distinction_students,
    ROUND(COUNT(CASE WHEN final_result = 'Pass' THEN 1 END) * 100.0 / COUNT(*), 2) as pass_rate,
    AVG(studied_credits) as avg_credits_studied,
    AVG(num_of_prev_attempts) as avg_previous_attempts
FROM {{ ref('student_data_clean') }}
GROUP BY 
    gender,
    age_band, 
    highest_education,
    has_disability
ORDER BY 
    total_students DESC