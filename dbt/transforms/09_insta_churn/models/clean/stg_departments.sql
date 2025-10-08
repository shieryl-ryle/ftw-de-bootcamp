-- models/clean/stg_departments.sql
-- Staging model for departments

{{ config(materialized='view', schema='clean') }}

SELECT 
    CAST(department_id AS UInt32) AS department_id,
    TRIM(department) AS department_name
FROM {{ source('raw', 'raw___insta_departments') }}
WHERE department_id IS NOT NULL
  AND department IS NOT NULL
  AND department != ''