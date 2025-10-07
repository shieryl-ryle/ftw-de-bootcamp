
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
    



select coin_id
from `clean`.`stg_btc__market_price`
where coin_id is null



    ) dbt_internal_test