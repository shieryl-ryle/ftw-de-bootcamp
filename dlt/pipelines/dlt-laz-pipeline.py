# pipelines/lazada_clickhouse_pipeline.py
import dlt
from playwright.sync_api import sync_playwright

@dlt.resource(write_disposition="append", name="lazada_products")
def lazada_scraped_data():
    """
    Scrapes mechanical keyboard listings from Lazada Philippines
    and yields one record per product.
    """
    url = "https://www.lazada.com.ph/catalog/?q=mechanical+keyboard"
    with sync_playwright() as pw:
        browser = pw.chromium.launch(headless=True)
        page = browser.new_page()
        page.goto(url)
        # wait until products appear
        page.wait_for_selector("div[data-qa-locator='product-item']")
        # scroll to load more
        page.evaluate("window.scrollBy(0, document.body.scrollHeight)")
        page.wait_for_timeout(2000)
        for card in page.query_selector_all("div[data-qa-locator='product-item']"):
            # some cards may be missing elements — skip on error
            try:
                name_el  = card.query_selector("[title]")
                price_el = card.query_selector('span:has-text("₱")')
                link_el  = card.query_selector("a")

                yield {
                    "name":  name_el.get_attribute("title") if name_el else None,
                    "price": price_el.inner_text().strip()   if price_el else None,
                    "url":   link_el.get_attribute("href")   if link_el else None,
                }
            except Exception:
                continue
        browser.close()

def run():
    pipeline = dlt.pipeline(
        pipeline_name="dlt-laz-pipeline",
        destination="clickhouse",
        dataset_name="lazada_products",
        dev_mode=True         # allow DLT to create database+table on first run
    )
    print("Fetching and loading...")
    info = pipeline.run(lazada_scraped_data())

    print("records loaded:", info)

if __name__ == "__main__":
    run()

 