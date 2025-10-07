

  create view `clean`.`stg_chinook__artist__dbt_tmp` 
  
    
    
  as (
    

-- Standardize column names/types per table; no business logic.
select
  cast(artist_id as Nullable(Int64))      as artist_id,
  cast(name      as Nullable(String))     as artist_name
from `raw`.`chinook___artists`
    
  )
      
      
                    -- end_of_sql
                    
                    