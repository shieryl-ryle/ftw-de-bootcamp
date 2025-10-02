-- Clean courses data
{{ config(
    materialized='table',
    alias='grp2_courses_clean'
) }}

SELECT
    NULLIF(TRIM(code_module), '?') AS code_module,
    NULLIF(TRIM(code_presentation), '?') AS code_presentation,
    
    -- Clean module_presentation_length
    CASE 
        WHEN TRIM(CAST(module_presentation_length AS String)) IN ('?', '', '0') THEN NULL
        ELSE CAST(module_presentation_length AS Nullable(Int64))
    END AS module_presentation_length,
    
    -- Add derived fields
    CASE 
        WHEN module_presentation_length >= 300 THEN 'Long Course'
        WHEN module_presentation_length >= 200 THEN 'Medium Course'
        WHEN module_presentation_length > 0 THEN 'Short Course'
        ELSE 'Unknown Duration'
    END AS course_duration_category,
    
    -- Extract presentation year and period from code_presentation
    CASE 
        WHEN LENGTH(code_presentation) >= 4 THEN 
            CAST(SUBSTRING(code_presentation, 1, 4) AS Nullable(Int64))
        ELSE NULL
    END AS presentation_year,
    
    CASE 
        WHEN LENGTH(code_presentation) >= 5 THEN 
            SUBSTRING(code_presentation, 5, 1)
        ELSE NULL
    END AS presentation_period,
    
    -- Create composite key
    CONCAT(code_module, '_', code_presentation) AS course_key,
    
    -- Add processing timestamp
    now() AS processed_at
    
FROM {{ source('raw', 'grp2_oulad___courses') }}
WHERE code_module IS NOT NULL 
  AND code_presentation IS NOT NULL
  AND TRIM(code_module) != '?'
  AND TRIM(code_presentation) != '?'