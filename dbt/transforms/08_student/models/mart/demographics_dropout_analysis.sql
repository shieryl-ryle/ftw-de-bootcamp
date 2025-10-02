-- BUSINESS QUESTION 1: Do demographics influence dropout?
{{ config(
    materialized='view',
    alias='grp2_demographics_dropout_analysis'
) }}

WITH dropout_by_demographics AS (
    SELECT 
        -- Demographics
        gender,
        region,
        age_band, 
        highest_education,
        imd_band,
        has_disability,
        dropout_risk_profile,
        
        -- Dropout metrics
        COUNT(*) as total_students,
        SUM(is_dropout) as total_dropouts,
        SUM(is_successful) as total_successful,
        
        -- Calculate rates
        ROUND(SUM(is_dropout) * 100.0 / COUNT(*), 2) as dropout_rate_pct,
        ROUND(SUM(is_successful) * 100.0 / COUNT(*), 2) as success_rate_pct,
        
        -- Statistical significance indicators
        CASE 
            WHEN COUNT(*) >= 100 THEN 'High Confidence'
            WHEN COUNT(*) >= 30 THEN 'Medium Confidence'
            ELSE 'Low Confidence'
        END as statistical_confidence
        
    FROM {{ ref('student_demographics_clean') }}
    GROUP BY gender, region, age_band, highest_education, imd_band, has_disability, dropout_risk_profile
),

overall_averages AS (
    SELECT 
        ROUND(AVG(is_dropout) * 100.0, 2) as overall_dropout_rate,
        ROUND(AVG(is_successful) * 100.0, 2) as overall_success_rate
    FROM {{ ref('student_demographics_clean') }}
)

SELECT 
    d.*,
    o.overall_dropout_rate,
    o.overall_success_rate,
    
    -- Risk indicators vs overall average
    ROUND(d.dropout_rate_pct - o.overall_dropout_rate, 2) as dropout_rate_vs_average,
    
    CASE 
        WHEN d.dropout_rate_pct > o.overall_dropout_rate + 10 THEN 'High Risk Group'
        WHEN d.dropout_rate_pct > o.overall_dropout_rate + 5 THEN 'Elevated Risk'  
        WHEN d.dropout_rate_pct < o.overall_dropout_rate - 5 THEN 'Low Risk Group'
        ELSE 'Average Risk'
    END as risk_classification

FROM dropout_by_demographics d
CROSS JOIN overall_averages o
WHERE d.total_students >= 10  -- Filter for statistical relevance
ORDER BY d.dropout_rate_pct DESC