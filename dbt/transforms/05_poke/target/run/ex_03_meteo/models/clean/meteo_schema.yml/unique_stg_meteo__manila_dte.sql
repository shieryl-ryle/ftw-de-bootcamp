
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
    

select
    dte as unique_field,
    count(*) as n_records

from `clean`.`stg_meteo__manila`
where dte is not null
group by dte
having count(*) > 1



    ) dbt_internal_test