-- Student-Course Bridge Table (handles many-to-many relationship)
{{ config(
    materialized='table',
    alias='grp2_bridge_student_course',
    schema='sandbox'
) }}

SELECT 
    -- Composite key
    CONCAT(student_id, '_', course_id) as bridge_key,
    
    -- Foreign keys
    student_id,
    course_id,
    
    -- Relationship attributes
    date_registration as relationship_start,
    date_unregistration as relationship_end,
    final_result,
    
    -- Relationship metrics
    CASE 
        WHEN date_unregistration IS NOT NULL 
        THEN date_unregistration - date_registration
        ELSE NULL
    END as enrollment_duration,
    
    CASE 
        WHEN final_result IN ('Pass', 'Distinction') THEN 'Successful'
        WHEN final_result = 'Fail' THEN 'Unsuccessful'  
        WHEN final_result = 'Withdrawn' THEN 'Withdrawn'
        ELSE 'In Progress'
    END as outcome_status,
    
    -- Active flag
    CASE 
        WHEN date_unregistration IS NULL THEN 1 ELSE 0
    END as is_active_enrollment,
    
    -- Metadata
    now() as created_at
    
FROM {{ ref('fact_registrations') }}
WHERE student_id IS NOT NULL 
  AND course_id IS NOT NULL