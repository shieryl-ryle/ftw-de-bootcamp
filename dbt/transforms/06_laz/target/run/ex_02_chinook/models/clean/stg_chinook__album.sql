

  create view `clean`.`stg_chinook__album__dbt_tmp` 
  
    
    
  as (
    

-- Keep album grain; standardize names/types.
select
  cast(album_id  as Nullable(Int64))      as album_id,
  cast(title     as Nullable(String))     as album_title,
  cast(artist_id as Nullable(Int64))      as artist_id
from `raw`.`chinook___albums`
    
  )
      
      
                    -- end_of_sql
                    
                    