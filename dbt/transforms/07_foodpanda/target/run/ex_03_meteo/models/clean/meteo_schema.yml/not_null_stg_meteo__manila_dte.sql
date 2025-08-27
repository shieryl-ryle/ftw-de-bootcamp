
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
    



select dte
from `clean`.`stg_meteo__manila`
where dte is null



    ) dbt_internal_test