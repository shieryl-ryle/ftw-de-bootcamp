
  
    
    
    
        
         


        insert into `mart`.`dim_album__dbt_backup`
        ("album_id", "album_title", "artist_id", "artist_name")

-- Album dimension, denormalized with artist_name (common convenience).
with album as (
  select * from `clean`.`stg_chinook__album`
),
artist as (
  select * from `clean`.`stg_chinook__artist`
)
select
  a.album_id,
  a.album_title,
  a.artist_id,
  ar.artist_name
from album a
left join artist ar
  on ar.artist_id = a.artist_id
  