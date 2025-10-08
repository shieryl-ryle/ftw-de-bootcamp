
  
    
    
    
        
         


        insert into `mart`.`dim_artist__dbt_backup`
        ("artist_id", "artist_name")

-- Simple conformed dimension for artists.
select
  artist_id,
  artist_name
from `clean`.`stg_chinook__artist`
  