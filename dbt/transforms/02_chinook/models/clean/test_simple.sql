{{ config(materialized="table", schema="clean") }}

-- Simple test model
SELECT 1 as test_column