

select
  assumeNotNull(last_updated_utc) as last_updated_utc,   -- non-null for CH MergeTree keys
  last_updated_manila,
  coin_id,
  symbol,
  name,
  image_url,
  price_usd,
  market_cap_usd,
  market_cap_rank,
  total_volume_usd,
  high_24h_usd,
  low_24h_usd,
  price_change_24h_usd,
  price_change_pct_24h
from `clean`.`stg_btc__market_price`