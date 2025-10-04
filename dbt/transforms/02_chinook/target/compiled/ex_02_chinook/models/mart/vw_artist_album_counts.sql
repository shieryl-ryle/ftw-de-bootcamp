

with album as (
  select album_id, artist_id
  from `clean`.`stg_chinook__album`
),
artist as (
  select artist_id, artist_name
  from `clean`.`stg_chinook__artist`
)

select
  ar.artist_id,
  ar.artist_name,
  substring(ar.artist_name, 1, 1)             as artist_initial,
  count(a.album_id)                            as album_count,
  case when count(a.album_id) >= 3 then 1 else 0 end as is_prolific -- handy filter in dashboards
from artist ar
left join album a
  on a.artist_id = ar.artist_id
group by
  ar.artist_id,
  ar.artist_name
order by album_count desc, ar.artist_name asc