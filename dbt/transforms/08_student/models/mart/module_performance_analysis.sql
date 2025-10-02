-- Module performance analysis
{{ config(
    materialized='view',
    alias='grp2_module_performance_analysis',
    schema='sandbox'
) }}

SELECT 
    code_module,
    code_presentation,
    COUNT(*) as total_enrollments,
    COUNT(CASE WHEN final_result = 'Pass' THEN 1 END) as passed,
    COUNT(CASE WHEN final_result = 'Fail' THEN 1 END) as failed,
    COUNT(CASE WHEN final_result = 'Withdrawn' THEN 1 END) as withdrawn,
    COUNT(CASE WHEN final_result = 'Distinction' THEN 1 END) as distinction,
    ROUND(COUNT(CASE WHEN final_result = 'Pass' THEN 1 END) * 100.0 / COUNT(*), 2) as pass_rate,
    ROUND(COUNT(CASE WHEN final_result = 'Distinction' THEN 1 END) * 100.0 / COUNT(*), 2) as distinction_rate,
    AVG(studied_credits) as avg_credits,
    AVG(num_of_prev_attempts) as avg_retries
FROM {{ ref('student_data_clean') }}
GROUP BY 
    code_module,
    code_presentation
ORDER BY 
    pass_rate DESC