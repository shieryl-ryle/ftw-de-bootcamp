
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
    



select last_updated_utc
from `clean`.`stg_btc__market_price`
where last_updated_utc is null



    ) dbt_internal_test