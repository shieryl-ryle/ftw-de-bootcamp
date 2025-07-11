SELECT 
  origin,
  avg(cylinders) AS avg_cyl,
  count() AS n
FROM `default`.`sample_cars___mpg_raw`  # Now matches
GROUP BY origin