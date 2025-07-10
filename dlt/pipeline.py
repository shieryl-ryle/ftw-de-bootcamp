# dlt/pipeline.py
import dlt, pandas as pd

@dlt.resource(name="mpg_raw")
def mpg():
    yield pd.read_csv("https://raw.githubusercontent.com/mwaskom/seaborn-data/master/mpg.csv")

if __name__ == "__main__":
    p = dlt.pipeline(
        pipeline_name="bootcamp",
        destination="clickhouse",
        dataset_name="sample_cars",
    )
    p.run(mpg())          # dlt pulls creds from env-vars
