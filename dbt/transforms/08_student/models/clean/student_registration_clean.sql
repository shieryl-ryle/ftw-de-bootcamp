-- Clean student registration data
{{ config(
    materialized='table',
    alias='grp2_student_registration_clean'
) }}

SELECT
    NULLIF(TRIM(code_module), '?') AS code_module,
    NULLIF(TRIM(code_presentation), '?') AS code_presentation,
    
    -- Clean student_id conversion
    CAST(NULLIF(TRIM(CAST(id_student AS String)), '?') AS Int64) AS student_id,
    
    -- Clean date fields with proper null handling
    CASE 
        WHEN TRIM(CAST(date_registration AS String)) IN ('?', '', '0') THEN NULL
        ELSE CAST(date_registration AS Nullable(Int64))
    END AS date_registration,
    
    CASE 
        WHEN TRIM(CAST(date_unregistration AS String)) IN ('?', '', '0') THEN NULL
        ELSE CAST(date_unregistration AS Nullable(Int64))
    END AS date_unregistration,
    
    -- Add derived fields
    CASE 
        WHEN date_unregistration IS NOT NULL THEN 'Unregistered'
        ELSE 'Active'
    END AS registration_status,
    
    -- Create composite key
    CONCAT(code_module, '_', code_presentation, '_', toString(student_id)) AS student_course_key,
    
    -- Add processing timestamp
    now() AS processed_at
    
FROM {{ source('raw', 'grp2_oulad___student_registration') }}
WHERE TRIM(CAST(id_student AS String)) NOT IN ('?', '', '0')
  AND id_student IS NOT NULL