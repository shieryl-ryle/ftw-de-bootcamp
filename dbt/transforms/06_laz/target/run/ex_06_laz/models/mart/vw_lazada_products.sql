

  create view `mart`.`vw_lazada_products__dbt_tmp` 
  
    
    
  as (
    

select
  url,
  name,
  page,
  price_raw,
  min_price,
  max_price,
  price_avg,
  is_price_range
from `clean`.`stg_lazada_products`
    
  )
      
      
                    -- end_of_sql
                    
                    