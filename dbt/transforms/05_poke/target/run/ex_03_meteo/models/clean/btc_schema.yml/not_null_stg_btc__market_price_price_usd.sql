
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
    



select price_usd
from `clean`.`stg_btc__market_price`
where price_usd is null



    ) dbt_internal_test