

  create view `mart`.`vw_meteo__manila_night_weather__dbt_tmp` 
  
    
    
  as (
    

with daily as (
  select
    dte,
    temp_min_c,
    temp_max_c,
    (temp_min_c + temp_max_c)/2.0 as temp_avg_c,
    precip_mm,
    weather_code
  from `clean`.`stg_meteo__manila`
),
codes as (
  select
    toInt32(weather_code)                as weather_code,
    cast(night_description as String)    as condition
  from `raw`.`meteo___wmo_codes`
)

select
  d.dte,
  d.temp_min_c,
  d.temp_max_c,
  d.temp_avg_c,
  d.precip_mm,
  d.weather_code,
  c.condition
from daily d
left join codes c
  on c.weather_code = d.weather_code
order by d.dte
    
  )
      
      
                    -- end_of_sql
                    
                    