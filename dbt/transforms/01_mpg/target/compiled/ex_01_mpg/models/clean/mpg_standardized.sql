

-- Source columns are already Nullable with correct types.
-- Keep them as-is to preserve nullability and avoid insert errors.

select
  toFloat64OrNull(mpg)          as mpg,
  toInt32OrNull(cylinders)      as cylinders,
  toFloat64OrNull(displacement) as displacement,
  toFloat64OrNull(horsepower)   as horsepower,
  toInt32OrNull(weight)         as weight,
  toFloat64OrNull(acceleration) as acceleration,
  toInt32OrNull(model_year)     as model_year,
  trim(origin)                  as origin,
  trim(name)                    as make
from `raw`.`autompg___cars`
where horsepower is not null
  and isFinite(horsepower)