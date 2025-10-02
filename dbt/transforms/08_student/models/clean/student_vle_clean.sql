-- Clean student VLE interaction data
{{ config(
    materialized='table',
    alias='grp2_student_vle_clean'
) }}

SELECT
    NULLIF(TRIM(code_module), '?') AS code_module,
    NULLIF(TRIM(code_presentation), '?') AS code_presentation,
    
    -- Clean student_id
    CAST(NULLIF(TRIM(CAST(id_student AS String)), '?') AS Int64) AS student_id,
    
    -- Clean site_id  
    CAST(NULLIF(TRIM(CAST(id_site AS String)), '?') AS Int64) AS site_id,
    
    -- Clean date field
    CASE 
        WHEN TRIM(CAST(date AS String)) IN ('?', '', '0') THEN NULL
        ELSE CAST(date AS Nullable(Int64))
    END AS date,
    
    -- Clean sum_click field
    CASE 
        WHEN TRIM(CAST(sum_click AS String)) IN ('?', '', '0') THEN NULL
        ELSE CAST(sum_click AS Nullable(Int64))
    END AS sum_click,
    
    -- Add derived fields
    CASE 
        WHEN sum_click > 100 THEN 'High Engagement'
        WHEN sum_click > 50 THEN 'Medium Engagement' 
        WHEN sum_click > 0 THEN 'Low Engagement'
        ELSE 'No Engagement'
    END AS engagement_level,
    
    -- Create composite keys
    CONCAT(code_module, '_', code_presentation) AS course_key,
    CONCAT(student_id, '_', id_site, '_', date) AS interaction_key,
    
    -- Add processing timestamp
    now() AS processed_at
    
FROM raw.studentVle
WHERE TRIM(CAST(id_student AS String)) NOT IN ('?', '', '0')
  AND id_student IS NOT NULL
  AND TRIM(CAST(id_site AS String)) NOT IN ('?', '', '0')
  AND id_site IS NOT NULL