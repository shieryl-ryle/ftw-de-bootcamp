-- Clean and standardize the raw student data
{{ config(
    materialized='table',
    alias='grp2_student_data_clean'
) }}

SELECT 
    id_student,
    code_module,
    code_presentation,
    CASE 
        WHEN gender = 'M' THEN 'Male'
        WHEN gender = 'F' THEN 'Female'
        ELSE 'Unknown'
    END as gender,
    region,
    highest_education,
    imd_band,
    age_band,
    COALESCE(num_of_prev_attempts, 0) as num_of_prev_attempts,
    COALESCE(studied_credits, 0) as studied_credits,
    CASE 
        WHEN disability = 'Y' THEN 'Yes'
        WHEN disability = 'N' THEN 'No'
        ELSE 'Unknown'
    END as has_disability,
    final_result,
    -- Create a composite key
    CONCAT(code_module, '_', code_presentation, '_', toString(id_student)) as student_course_key,
    -- Add processing timestamp
    now() as processed_at
FROM {{ source('raw', 'grp2_oulad___student_info') }}
WHERE id_student IS NOT NULL