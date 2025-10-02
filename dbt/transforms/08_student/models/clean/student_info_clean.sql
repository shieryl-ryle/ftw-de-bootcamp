-- Clean student info data
{{ config(
    materialized='table',
    alias='grp2_student_info_clean'
) }}

SELECT
    NULLIF(TRIM(code_module), '?') AS code_module,
    NULLIF(TRIM(code_presentation), '?') AS code_presentation,
    
    -- Clean student_id
    CAST(NULLIF(TRIM(CAST(id_student AS String)), '?') AS Int64) AS student_id,
    
    -- Standardize gender
    CASE 
        WHEN UPPER(TRIM(gender)) = 'M' THEN 'Male'
        WHEN UPPER(TRIM(gender)) = 'F' THEN 'Female'
        ELSE 'Unknown'
    END AS gender,
    
    NULLIF(TRIM(region), '?') AS region,
    NULLIF(TRIM(highest_education), '?') AS highest_education,
    NULLIF(TRIM(imd_band), '?') AS imd_band,
    NULLIF(TRIM(age_band), '?') AS age_band,
    
    -- Clean numeric fields
    CASE 
        WHEN TRIM(CAST(num_of_prev_attempts AS String)) IN ('?', '') THEN 0
        ELSE COALESCE(CAST(num_of_prev_attempts AS Int64), 0)
    END AS num_of_prev_attempts,
    
    CASE 
        WHEN TRIM(CAST(studied_credits AS String)) IN ('?', '') THEN 0
        ELSE COALESCE(CAST(studied_credits AS Int64), 0)
    END AS studied_credits,
    
    -- Standardize disability
    CASE 
        WHEN UPPER(TRIM(disability)) = 'Y' THEN 'Yes'
        WHEN UPPER(TRIM(disability)) = 'N' THEN 'No'
        ELSE 'Unknown'
    END AS has_disability,
    
    NULLIF(TRIM(final_result), '?') AS final_result,
    
    -- Add derived fields
    CASE 
        WHEN final_result IN ('Pass', 'Distinction') THEN 'Success'
        WHEN final_result = 'Fail' THEN 'Fail'
        WHEN final_result = 'Withdrawn' THEN 'Withdrawn'
        ELSE 'Other'
    END AS result_category,
    
    CASE
        WHEN num_of_prev_attempts = 0 THEN 'First_Time'
        WHEN num_of_prev_attempts = 1 THEN 'Second_Attempt'
        ELSE 'Multiple_Attempts'
    END AS attempt_category,
    
    -- Create composite key
    CONCAT(code_module, '_', code_presentation, '_', toString(student_id)) AS student_course_key,
    
    -- Add processing timestamp
    now() AS processed_at
    
FROM {{ source('raw', 'grp2_oulad___student_info') }}
WHERE TRIM(CAST(id_student AS String)) NOT IN ('?', '', '0')
  AND id_student IS NOT NULL