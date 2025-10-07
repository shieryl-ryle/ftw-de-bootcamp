
  
    
    
    
        
         


        insert into `clean`.`mpg_standardized__dbt_backup`
        ("mpg", "cylinders", "displacement", "horsepower", "weight", "acceleration", "model_year", "origin", "make")

-- Source columns are already Nullable with correct types.
-- Keep them as-is to preserve nullability and avoid insert errors.

select
  toFloat64(mpg)          as mpg,
  toInt32(cylinders)      as cylinders,
  toFloat64(displacement) as displacement,
  CAST(horsepower AS Nullable(Float64)) as horsepower,
  toInt32(weight)         as weight,
  toFloat64(acceleration) as acceleration,
  toInt32(model_year)     as model_year,
  trim(origin)                  as origin,
  trim(name)                    as make
from `raw`.`autompg___cars`
-- where horsepower is not null
  -- and isFinite(horsepower)
  