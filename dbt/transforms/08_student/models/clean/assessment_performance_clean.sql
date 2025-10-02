-- Clean Assessment Performance - link between VLE engagement and academic outcomes
{{ config(
    materialized='table', 
    alias='grp2_assessment_performance_clean'
) }}

SELECT 
    student_id,
    
    -- Course context
    a.code_module,
    a.code_presentation, 
    CONCAT(a.code_module, '_', a.code_presentation) as course_key,
    
    -- Performance metrics
    COUNT(sa.assessment_id) as total_assessments,
    AVG(sa.score) as avg_score,
    SUM(CASE WHEN sa.score >= 40 THEN 1 ELSE 0 END) as assessments_passed,
    SUM(CASE WHEN sa.score >= 85 THEN 1 ELSE 0 END) as distinctions_earned,
    SUM(CASE WHEN sa.score IS NULL THEN 1 ELSE 0 END) as assessments_not_submitted,
    
    -- Performance categories (for engagement analysis)
    CASE 
        WHEN AVG(sa.score) >= 85 THEN 'Excellent'
        WHEN AVG(sa.score) >= 70 THEN 'Good'
        WHEN AVG(sa.score) >= 40 THEN 'Satisfactory'  
        WHEN AVG(sa.score) > 0 THEN 'Poor'
        ELSE 'No Submissions'
    END as performance_category,
    
    -- Submission behavior (engagement indicator)
    CASE 
        WHEN SUM(CASE WHEN sa.score IS NULL THEN 1 ELSE 0 END) = 0 THEN 'All Submitted'
        WHEN SUM(CASE WHEN sa.score IS NULL THEN 1 ELSE 0 END) <= 1 THEN 'Mostly Submitted'
        WHEN SUM(CASE WHEN sa.score IS NOT NULL THEN 1 ELSE 0 END) > 0 THEN 'Partially Submitted'
        ELSE 'No Submissions'
    END as submission_pattern,
    
    -- First assessment score (approximation using MIN assessment_id as earliest)
    MIN(CASE WHEN a.assessment_id IS NOT NULL THEN sa.score END) as first_assessment_score,
     
    now() as processed_at
    
FROM {{ ref('student_assessment_clean') }} sa
LEFT JOIN {{ ref('assessments_clean') }} a 
    ON sa.assessment_id = a.assessment_id
WHERE sa.student_id IS NOT NULL
GROUP BY sa.student_id, a.code_module, a.code_presentation