
        
  
    
    
    
        
         


        insert into `mart`.`mart_btc__daily_ohlc__dbt_new_data_bbc1c2e0_395f_44a5_9e3a_619b70bf606b`
        ("day_local", "coin_id", "low_usd", "high_usd", "open_usd", "close_usd")

with base as (
  select
    assumeNotNull(toDate(toTimeZone(last_updated_utc,'Asia/Manila'))) as day_local,
    assumeNotNull(coin_id)                                            as coin_id,
    last_updated_utc,
    toFloat64(price_usd)                                              as price_usd
  from `clean`.`stg_btc__market_price`
  where last_updated_utc is not null

  
    -- Recompute only latest (and previous) Manila days
    and toDate(toTimeZone(last_updated_utc,'Asia/Manila')) >= (
      select coalesce(max(day_local), toDate(now('Asia/Manila')) - 1)
      from `mart`.`mart_btc__daily_ohlc`
    ) - 1
  
)
select
  day_local,
  coin_id,
  min(price_usd)                      as low_usd,
  max(price_usd)                      as high_usd,
  argMin(price_usd, last_updated_utc) as open_usd,   -- first in day
  argMax(price_usd, last_updated_utc) as close_usd   -- last in day
from base
group by day_local, coin_id
order by day_local, coin_id
  
      