

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