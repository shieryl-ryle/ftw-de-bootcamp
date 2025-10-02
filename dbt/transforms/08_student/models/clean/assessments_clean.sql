-- Clean assessments data
{{ config(
    materialized='table',
    alias='grp2_assessments_clean',
    schema='sandbox'
) }}

SELECT
    NULLIF(TRIM(code_module), '?') AS code_module,
    NULLIF(TRIM(code_presentation), '?') AS code_presentation,
    
    -- Clean assessment_id
    CAST(NULLIF(TRIM(CAST(id_assessment AS String)), '?') AS Int64) AS assessment_id,
    
    -- Standardize assessment_type
    CASE 
        WHEN UPPER(TRIM(assessment_type)) = 'TMA' THEN 'Tutor Marked Assignment'
        WHEN UPPER(TRIM(assessment_type)) = 'CMA' THEN 'Computer Marked Assignment'
        WHEN UPPER(TRIM(assessment_type)) = 'EXAM' THEN 'Final Exam'
        ELSE NULLIF(TRIM(assessment_type), '?')
    END AS assessment_type,
    
    -- Clean date field
    CASE 
        WHEN TRIM(CAST(date AS String)) IN ('?', '', '0') THEN NULL
        ELSE CAST(date AS Nullable(Int64))
    END AS assessment_date,
    
    -- Clean weight field
    CASE 
        WHEN TRIM(CAST(weight As String)) IN ('?', '', '0') THEN NULL
        ELSE CAST(weight AS Nullable(Float64))
    END AS weight_percentage,
    
    -- Add derived fields
    CASE 
        WHEN weight >= 50 THEN 'High Weight'
        WHEN weight >= 20 THEN 'Medium Weight'
        WHEN weight > 0 THEN 'Low Weight'
        ELSE 'No Weight'
    END AS weight_category,
    
    -- Create composite key
    CONCAT(code_module, '_', code_presentation, '_', toString(assessment_id)) AS assessment_key,
    
    -- Add processing timestamp
    now() AS processed_at
    
FROM {{ source('raw', 'grp2_oulad___assessments') }}
WHERE TRIM(CAST(id_assessment AS String)) NOT IN ('?', '', '0')
  AND id_assessment IS NOT NULL