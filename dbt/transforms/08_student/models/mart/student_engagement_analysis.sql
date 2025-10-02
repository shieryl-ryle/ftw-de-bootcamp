-- Student engagement analysis combining registration, VLE activity, and outcomes
{{ config(
    materialized='view',
    alias='grp2_student_engagement_analysis',
    schema='sandbox'
) }}

WITH student_engagement AS (
    SELECT 
        si.student_id,
        si.code_module,
        si.code_presentation,
        si.gender,
        si.region,
        si.age_band,
        si.final_result,
        si.result_category,
        sr.registration_status,
        sr.date_registration,
        sr.date_unregistration,
        
        -- VLE engagement metrics
        COUNT(DISTINCT sv.site_id) AS unique_sites_accessed,
        SUM(sv.sum_click) AS total_clicks,
        COUNT(DISTINCT sv.date) AS active_days,
        AVG(sv.sum_click) AS avg_daily_clicks,
        
        -- Engagement categorization
        CASE 
            WHEN SUM(sv.sum_click) >= 1000 THEN 'High_Engagement'
            WHEN SUM(sv.sum_click) >= 100 THEN 'Medium_Engagement' 
            WHEN SUM(sv.sum_click) > 0 THEN 'Low_Engagement'
            ELSE 'No_Engagement'
        END AS engagement_category
        
    FROM {{ ref('student_info_clean') }} si
    LEFT JOIN {{ ref('student_registration_clean') }} sr 
        ON si.student_course_key = sr.student_course_key
    LEFT JOIN {{ ref('student_vle_clean') }} sv 
        ON si.student_course_key = sv.student_course_key
    
    GROUP BY 
        si.student_id, si.code_module, si.code_presentation, 
        si.gender, si.region, si.age_band, si.final_result, si.result_category,
        sr.registration_status, sr.date_registration, sr.date_unregistration
)

SELECT *,
    -- Performance vs engagement analysis
    CASE 
        WHEN result_category = 'Success' AND engagement_category IN ('High_Engagement', 'Medium_Engagement') 
            THEN 'High_Performer'
        WHEN result_category = 'Success' AND engagement_category = 'Low_Engagement'
            THEN 'Efficient_Learner'
        WHEN result_category IN ('Fail', 'Withdrawn') AND engagement_category IN ('High_Engagement', 'Medium_Engagement')
            THEN 'Struggling_Despite_Effort'
        WHEN result_category IN ('Fail', 'Withdrawn') AND engagement_category IN ('Low_Engagement', 'No_Engagement')
            THEN 'Disengaged'
        ELSE 'Other'
    END AS performance_engagement_profile

FROM student_engagement