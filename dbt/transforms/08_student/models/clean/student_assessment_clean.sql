-- Clean student assessment data
{{ config(
    materialized='table',
    alias='grp2_student_assessment_clean'
) }}

SELECT
    -- Clean assessment_id
    CAST(NULLIF(TRIM(CAST(id_assessment AS String)), '?') AS Int64) AS assessment_id,
    
    -- Clean student_id
    CAST(NULLIF(TRIM(CAST(id_student As String)), '?') AS Int64) AS student_id,
    
    -- Clean date_submitted
    CASE 
        WHEN TRIM(CAST(date_submitted AS String)) IN ('?', '', '0') THEN NULL
        ELSE CAST(date_submitted AS Nullable(Int64))
    END AS date_submitted,
    
    -- Clean is_banked (convert to boolean)
    CASE 
        WHEN TRIM(CAST(is_banked AS String)) = '1' THEN true
        WHEN TRIM(CAST(is_banked AS String)) = '0' THEN false
        ELSE NULL
    END AS is_banked,
    
    -- Clean score
    CASE 
        WHEN TRIM(CAST(score As String)) IN ('?', '') THEN NULL
        ELSE CAST(score AS Nullable(Float64))
    END AS score,
    
    -- Add derived fields
    CASE 
        WHEN score >= 85 THEN 'Distinction'
        WHEN score >= 70 THEN 'Pass 2'
        WHEN score >= 55 THEN 'Pass 3' 
        WHEN score >= 40 THEN 'Pass 4'
        WHEN score IS NOT NULL THEN 'Fail'
        ELSE 'Not Submitted'
    END AS grade_band,
    
    CASE 
        WHEN score IS NULL THEN 'Not Submitted'
        WHEN score >= 40 THEN 'Pass'
        ELSE 'Fail'
    END AS pass_fail_status,
    
    -- Create composite keys
    CONCAT(toString(assessment_id), '_', toString(student_id)) AS student_assessment_key,
    
    -- Add processing timestamp
    now() AS processed_at
    
FROM {{ source('raw', 'grp2_oulad___student_assessment') }}
WHERE TRIM(CAST(id_assessment AS String)) NOT IN ('?', '', '0')
  AND id_assessment IS NOT NULL
  AND TRIM(CAST(id_student As String)) NOT IN ('?', '', '0')
  AND id_student IS NOT NULL