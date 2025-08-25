

  create view `mart`.`cylinders_by_origin` 
  
    
    
  as (
    

select
  origin,
  avg(cylinders) as avg_cylinders,
  count()        as n
from `clean`.`mpg_standardized`
group by origin
    
  )
      
      
                    -- end_of_sql
                    
                    