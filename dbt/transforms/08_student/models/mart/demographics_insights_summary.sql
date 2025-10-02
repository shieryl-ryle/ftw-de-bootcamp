-- Simplified demographics insights
{{ config(
    materialized='view',
    alias='grp2_demographics_insights_summary'
) }}

SELECT 
    'Demographics Impact' as insight_category,
    'Dropout Risk Analysis' as insight_type,
    CONCAT(
        gender, ' | ', 
        age_band, ' | ', 
        highest_education, ' | ',
        CASE WHEN has_disability = 1 THEN 'Has Disability' ELSE 'No Disability' END
    ) as risk_factor,
    dropout_rate_pct as impact_metric,
    total_students as sample_size,
    statistical_confidence,
    CASE 
        WHEN dropout_rate_pct > 40 THEN 'CRITICAL: Implement targeted support programs'
        WHEN dropout_rate_pct > 30 THEN 'HIGH PRIORITY: Early intervention needed'
        WHEN dropout_rate_pct < 15 THEN 'SUCCESS PATTERN: Maintain current support level'
        ELSE 'MONITOR: Standard support with attention to trends'
    END as interpretation
    
FROM {{ ref('demographics_dropout_analysis') }}
WHERE risk_classification IN ('High Risk Group', 'Elevated Risk')
    AND statistical_confidence IN ('High Confidence', 'Medium Confidence')
ORDER BY dropout_rate_pct DESC
LIMIT 20