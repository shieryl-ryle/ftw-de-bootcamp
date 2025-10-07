

select
  origin,
  avg(cylinders) as avg_cylinders,
  count()        as n
from `clean`.`mpg_standardized`
group by origin