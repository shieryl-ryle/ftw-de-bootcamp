
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
    



select temp_max_c
from `clean`.`stg_meteo__manila`
where temp_max_c is null



    ) dbt_internal_test