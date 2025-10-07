

  create view `clean`.`stg_meteo__regions_daily` 
  
    
    
  as (
    -- models/clean/stg_meteo__regions_daily.sql


select
  cast(region_code as String)          as region_code,
  cast(region_name as String)          as region_name,
  toFloat64(latitude)                  as latitude,
  toFloat64(longitude)                 as longitude,
  toDate(date)                         as dte,
  toFloat64(temp_min)                  as temp_min_c,
  toFloat64(temp_max)                  as temp_max_c,
  toFloat64(precipitation)             as precip_mm,
  toInt32(weather_code)                as weather_code
from `raw`.`meteo___regions_daily`
    
  )
      
      
                    -- end_of_sql
                    
                    