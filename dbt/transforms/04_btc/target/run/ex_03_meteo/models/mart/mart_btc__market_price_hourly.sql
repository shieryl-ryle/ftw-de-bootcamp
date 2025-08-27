
        
  
    
    
    
        
         


        insert into `mart`.`mart_btc__market_price_hourly__dbt_new_data_4f63e7af_7ff6_449a_a3f7_f8e7b1b8ff20`
        ("hour_local", "coin_id", "low_usd", "high_usd", "open_usd", "close_usd")

with base as (
  select
    -- non-nullable for MergeTree keys
    toStartOfHour(toTimeZone(assumeNotNull(last_updated_utc), 'Asia/Manila')) as hour_local,
    assumeNotNull(coin_id)                                                    as coin_id,
    last_updated_utc,
    toFloat64(price_usd)                                                      as price_usd
  from `clean`.`stg_btc__market_price`
  where last_updated_utc is not null

  
    -- Recompute only latest (and previous) Manila hours
    and toStartOfHour(toTimeZone(last_updated_utc,'Asia/Manila')) >= (
      select coalesce(max(hour_local), toStartOfHour(now('Asia/Manila')) - interval 1 hour)
      from `mart`.`mart_btc__market_price_hourly`
    ) - interval 1 hour
  
)
select
  hour_local,
  coin_id,
  min(price_usd)                      as low_usd,
  max(price_usd)                      as high_usd,
  argMin(price_usd, last_updated_utc) as open_usd,   -- first in hour
  argMax(price_usd, last_updated_utc) as close_usd   -- last in hour
from base
group by hour_local, coin_id
order by hour_local, coin_id
  
      