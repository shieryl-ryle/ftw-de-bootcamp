

-- Keep album grain; standardize names/types.
select
  cast(album_id  as Nullable(Int64))      as album_id,
  cast(title     as Nullable(String))     as album_title,
  cast(artist_id as Nullable(Int64))      as artist_id
from `raw`.`chinook___albums`