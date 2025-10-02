-- Clean VLE materials and activities data
{{ config(
    materialized='table',
    alias='grp2_vle_clean',
    schema='sandbox'
) }}

SELECT
    -- Clean site_id
    CAST(NULLIF(TRIM(CAST(id_site As String)), '?') AS Int64) AS site_id,
    
    NULLIF(TRIM(code_module), '?') AS code_module,
    NULLIF(TRIM(code_presentation), '?') AS code_presentation,
    
    -- Clean activity_type
    NULLIF(TRIM(activity_type), '?') AS activity_type,
    
    -- Clean week fields
    CASE 
        WHEN TRIM(CAST(week_from AS String)) IN ('?', '', '0') THEN NULL
        ELSE CAST(week_from AS Nullable(Int64))
    END AS week_from,
    
    CASE 
        WHEN TRIM(CAST(week_to AS String)) IN ('?', '', '0') THEN NULL
        ELSE CAST(week_to AS Nullable(Int64))
    END AS week_to,
    
    -- Add derived fields
    CASE
        WHEN week_to IS NOT NULL AND week_from IS NOT NULL 
        THEN week_to - week_from + 1
        ELSE NULL
    END AS activity_duration_weeks,
    
    CASE
        WHEN activity_type IN ('quiz', 'exam', 'assessment') THEN 'Assessment'
        WHEN activity_type IN ('resource', 'page', 'url') THEN 'Content'
        WHEN activity_type IN ('forum', 'wiki', 'collaborate') THEN 'Interactive'
        ELSE 'Other'
    END AS activity_category,
    
    -- Create composite key
    CONCAT(code_module, '_', code_presentation, '_', toString(site_id)) AS site_course_key,
    
    -- Add processing timestamp
    now() AS processed_at
    
FROM {{ source('raw', 'grp2_oulad___vle') }}
WHERE TRIM(CAST(id_site AS String)) NOT IN ('?', '', '0')
  AND id_site IS NOT NULL