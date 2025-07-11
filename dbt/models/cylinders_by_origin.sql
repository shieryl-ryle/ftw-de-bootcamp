SELECT 
  origin,
  avg(cylinders) AS avg_cyl,
  count() AS n
FROM {{ source('default', 'auto_mpg___mpg_raw') }}  # Now matches
GROUP BY origin