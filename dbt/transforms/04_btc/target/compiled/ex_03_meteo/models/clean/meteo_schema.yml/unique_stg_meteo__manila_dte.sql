
    
    

select
    dte as unique_field,
    count(*) as n_records

from `clean`.`stg_meteo__manila`
where dte is not null
group by dte
having count(*) > 1


