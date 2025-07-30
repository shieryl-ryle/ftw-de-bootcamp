# dlt/pipeline.py
import dlt, pandas as pd


# https://archive.ics.uci.edu/dataset/9/auto+mpg
@dlt.resource(name="cars")
def mpg():
    yield pd.read_csv("https://raw.githubusercontent.com/mwaskom/seaborn-data/master/mpg.csv")

def run():
    p = dlt.pipeline(
        pipeline_name="dlt-mpg-pipeline",
        destination="clickhouse",
        dataset_name="autompg",
    )
    print("Fetching and loading...")
    info1 = p.run(mpg())          # dlt pulls creds from env-vars

    print("records loaded:", info1)


if __name__ == "__main__":
    run()