

  create view `mart`.`vw_btc__latest_24h__dbt_tmp` 
  
    
    
  as (
    

WITH (SELECT max(last_updated_utc) FROM `clean`.`stg_btc__market_price`) AS ts_max
SELECT
  *
FROM `clean`.`stg_btc__market_price`
WHERE last_updated_utc >= ts_max - INTERVAL 24 HOUR
ORDER BY last_updated_utc
    
  )
      
      
                    -- end_of_sql
                    
                    