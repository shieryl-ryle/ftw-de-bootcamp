
  
    
    
    
        
         


        insert into `clean`.`mpg_standardized__dbt_backup`
        ("mpg", "cylinders", "displacement", "horsepower", "weight", "acceleration", "model_year", "origin", "make")

-- Source columns are already Nullable with correct types.
-- Keep them as-is to preserve nullability and avoid insert errors.

select
  mpg,            -- Nullable(Float64)
  cylinders,      -- Nullable(Int64)
  displacement,   -- Nullable(Float64)
  horsepower,     -- Nullable(Float64)
  weight,         -- Nullable(Int64)
  acceleration,   -- Nullable(Float64)
  model_year,     -- Nullable(Int64)
  origin,         -- Nullable(String)
  name as make    -- Nullable(String)
from `raw`.`autompg___cars`
  