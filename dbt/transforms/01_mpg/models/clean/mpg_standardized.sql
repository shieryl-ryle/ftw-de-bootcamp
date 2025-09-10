{{ config(materialized="table", schema="clean") }}

-- Source columns are already Nullable with correct types.
-- Keep them as-is to preserve nullability and avoid insert errors.

select
  mpg,            -- Nullable(Float64)
  cylinders,      -- Nullable(Int64)
  displacement,   -- Nullable(Float64)
  horsepower,     -- Nullable(Float64)
  /*
  coalesce(
        horsepower,
        avg(horsepower) over (partition by cylinders)
    ) as horsepower_imputed,
  */
  weight,         -- Nullable(Int64)
  acceleration,   -- Nullable(Float64)
  model_year,     -- Nullable(Int64)
  origin,         -- Nullable(String)
  name as make    -- Nullable(String)
from {{ source('raw', 'autompg___cars') }}

