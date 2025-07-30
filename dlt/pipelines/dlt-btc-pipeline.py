import time
import requests
import dlt

@dlt.resource(write_disposition="append", name="market_price")
def bitcoin_markets():

    # edit .dlt/secrets.toml to add your CoinGecko API key
    api_key = dlt.secrets["coingecko"]["api_key"]

    """
    Hits /coins/markets and yields the Bitcoin market object.

    Endpoint: https://api.coingecko.com/api/v3/coins/markets
    """
    url = "https://api.coingecko.com/api/v3/coins/markets"
    params = {
        "vs_currency": "usd",
        "ids": "bitcoin"
    }
    headers = {"x_cg_pro_api_key": api_key}
    resp = requests.get(url, params=params, headers=headers)
    resp.raise_for_status()
    data = resp.json()  # list of market objects, here only bitcoin

    for obj in data:
        yield {
            "id": obj.get("id"),
            "symbol": obj.get("symbol"),
            "name": obj.get("name"),
            "image": obj.get("image"),
            "current_price": obj.get("current_price"),
            "market_cap": obj.get("market_cap"),
            "market_cap_rank": obj.get("market_cap_rank"),
            "total_volume": obj.get("total_volume"),
            "high_24h": obj.get("high_24h"),
            "low_24h": obj.get("low_24h"),
            "price_change_24h": obj.get("price_change_24h"),
            "price_change_percentage_24h": obj.get("price_change_percentage_24h"),
            "last_updated": obj.get("last_updated"),
        }


def run():
    pipeline = dlt.pipeline(
        pipeline_name="dlt-btc-pipeline",
        destination="clickhouse",
        dataset_name="btc",
        dev_mode=False   # creates DB & tables if they don't exist
    )
    print("Fetching and loading...")
    #while True:
    info = pipeline.run(bitcoin_markets())
 
    print("records loaded:", info)


if __name__ == "__main__":
    run()

