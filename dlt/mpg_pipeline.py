# dlt/pipeline.py
import dlt, pandas as pd

@dlt.resource(name="mpg_raw")
def mpg():
    yield pd.read_csv("https://raw.githubusercontent.com/mwaskom/seaborn-data/master/mpg.csv")

if __name__ == "__main__":
    p = dlt.pipeline(
        pipeline_name="auto_mpg_pipeline",
        destination="clickhouse",
        dataset_name="auto_mpg",
    )
    p.run(mpg())          # dlt pulls creds from env-vars
