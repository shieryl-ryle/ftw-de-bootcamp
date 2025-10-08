# 🚀 Complete InstaCart Churn Project Guide
## Build a Production-Ready Data Engineering Pipeline from Scratch

### 📋 **What You'll Build**
A complete end-to-end data engineering pipeline using the Instacart Market Basket dataset to analyze customer churn and shopping behaviors. This project demonstrates:

- **Data Normalization (3NF)** → Ensure data integrity and eliminate redundancy
- **Dimensional Modeling (Star Schema)** → Optimize for analytical queries
- **Business Analytics** → Generate actionable insights for stakeholders
- **Data Quality Monitoring** → Maintain trust in business decisions

---

## 🎯 **Business Problem We're Solving**

### **Primary Question:**
*"How can we reduce customer churn and optimize product placement through data-driven insights?"*

### **What Makes This Project Valuable:**
- **49,688 products** to analyze for performance trends
- **206,209 customers** to segment and retain
- **32.4M transactions** to mine for behavioral patterns
- **Rich behavioral data**: reorder rates, cart positions, time preferences

---

## 📊 **Project Architecture Overview**

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   DATA SOURCE   │    │   EXTRACTION    │    │  TRANSFORMATION │    │   ANALYTICS     │
│                 │    │                 │    │                 │    │                 │
│ • Instacart CSV │───▶│ • dlt Pipeline  │───▶│ • dbt (3NF)     │───▶│ • Star Schema   │
│ • 6 Tables      │    │ • ClickHouse    │    │ • Normalization │    │ • Business KPIs │
│ • 36M Records   │    │ • Data Quality  │    │ • Data Cleaning │    │ • Churn Analysis│
└─────────────────┘    └─────────────────┘    └─────────────────┘    └─────────────────┘
```

---
### **SKIP IF DONE**
### **Step 1: Clone the Repository**

```bash
# Clone the bootcamp repository
git clone https://github.com/shieryl-ryle/ftw-de-bootcamp.git
cd ftw-de-bootcamp

# Create your working branch
git checkout g2/v2
git pull
git checkout -b v2/your-name

```

### **Step 2: Environment Setup**

```bash
# If using Windows, ensure you're in WSL2 Ubuntu
wsl

# Navigate to project directory
cd /path/to/ftw-de-bootcamp

# Make scripts executable
chmod +x scripts/*.sh
```

### **Step 3: Start Infrastructure (Docker)**

```bash
# Start ClickHouse database and Metabase
docker compose --compatibility up -d --profile core

# Verify services are running
docker ps
# Should show: clickhouse and metabase containers
```

**Expected Output:**
```
CONTAINER ID   IMAGE                              COMMAND              STATUS
abc123         clickhouse/clickhouse-server:23.12 "/entrypoint.sh"     Up 2 minutes
def456         metabase/metabase:latest          "java -jar app.jar"   Up 2 minutes
```

---

## 📥 **Phase 1: Data Extraction & Loading (ELT)**

### **Understanding the Dataset**

The Instacart dataset contains 6 related tables:
- **Products** (49,688): Product catalog with hierarchies
- **Orders** (3.4M): Customer orders with timing data  
- **Order Products** (32.4M): Line items linking orders to products
- **Aisles** (134): Product aisle categories
- **Departments** (21): High-level product categories
- **Users** (206K): Implicit from orders table

### **OPTIONAL PART: Datasets are already extracted on the remote**
### **Step 4: Create Data Extraction Pipeline**

Since there's no existing Instagram-specific dlt pipeline, we'll create one:

```bash
# Create the Instagram dlt pipeline
touch dlt/extract-loads/10-dlt-instacart-churn-pipeline.py
```

Create the pipeline file:

```python
# dlt/extract-loads/10-dlt-instagram-churn-pipeline.py
import dlt
import pandas as pd
from pathlib import Path

def load_instacart_data():
    """Load Instacart dataset from CSV files into ClickHouse"""
    
    # Define data source path (you'll need to download the dataset)
    data_path = Path("dlt/extract-loads/staging/instacart/")
    
    @dlt.resource(name="raw___insta_products", write_disposition="replace")
    def extract_products():
        """Extract products with aisle and department relationships"""
        df = pd.read_csv(data_path / "products.csv")
        return df.to_dict('records')
    
    @dlt.resource(name="raw___insta_orders", write_disposition="replace") 
    def extract_orders():
        """Extract customer orders with timing data"""
        df = pd.read_csv(data_path / "orders.csv")
        return df.to_dict('records')
    
    @dlt.resource(name="raw___insta_order_products_train", write_disposition="replace")
    def extract_order_products_train():
        """Extract training dataset order-product relationships"""
        df = pd.read_csv(data_path / "order_products__train.csv")
        return df.to_dict('records')
        
    @dlt.resource(name="raw___insta_order_products_prior", write_disposition="replace")
    def extract_order_products_prior():
        """Extract prior dataset order-product relationships"""  
        df = pd.read_csv(data_path / "order_products__prior.csv")
        return df.to_dict('records')
    
    @dlt.resource(name="raw___insta_aisles", write_disposition="replace")
    def extract_aisles():
        """Extract product aisle master data"""
        df = pd.read_csv(data_path / "aisles.csv") 
        return df.to_dict('records')
        
    @dlt.resource(name="raw___insta_departments", write_disposition="replace") 
    def extract_departments():
        """Extract product department master data"""
        df = pd.read_csv(data_path / "departments.csv")
        return df.to_dict('records')

    # Configure pipeline
    pipeline = dlt.pipeline(
        pipeline_name="instacart-churn-pipeline",
        destination="clickhouse",
        dataset_name="raw"
    )
    
    # Load all resources
    info = pipeline.run([
        extract_products(),
        extract_orders(), 
        extract_order_products_train(),
        extract_order_products_prior(),
        extract_aisles(),
        extract_departments()
    ])
    
    print(f"Pipeline completed. Loaded {info}")

if __name__ == "__main__":
    load_instacart_data()
```

### **Step 5: Download Dataset**

You'll need to download the Instacart dataset:

```bash
# Create staging directory
mkdir -p dlt/extract-loads/staging/instacart

# Download from Kaggle (requires Kaggle account and API key)
# Or manually download from: https://www.kaggle.com/c/instacart-market-basket-analysis/data

# Expected files:
# - products.csv
# - orders.csv  
# - order_products__train.csv
# - order_products__prior.csv
# - aisles.csv
# - departments.csv
```

### **Step 6: Run Data Pipeline**

```bash
# Run the Instagram churn pipeline
docker compose --profile jobs run --rm dlt python extract-loads/10-dlt-instacart-churn-pipeline.py
```

**Verify Data Loading:**
```bash
# Connect to ClickHouse to verify data
docker exec -it clickhouse clickhouse-client

# Check loaded tables
SHOW TABLES FROM raw WHERE name LIKE '%insta%';

# Verify record counts
SELECT 'products' as table_name, count() as records FROM raw.raw___insta_products
UNION ALL
SELECT 'orders' as table_name, count() as records FROM raw.raw___insta_orders
UNION ALL  
SELECT 'order_products_train' as table_name, count() as records FROM raw.raw___insta_order_products_train;
```

---
## Don't skip this part
## 🧹 **Phase 2: Data Transformation & Normalization (dbt)**

### **Understanding Normalization**

We'll implement **Third Normal Form (3NF)** to:
- **Eliminate redundancy**: Store each fact in exactly one place
- **Prevent update anomalies**: Changes only need to happen in one location  
- **Ensure data integrity**: Enforce business rules through proper relationships

### **Step 7: Set Up dbt Project**

```bash
# Navigate to dbt transforms directory
cd dbt/transforms/09_insta_churn

# Verify dbt project structure
ls -la
# Should show: dbt_project.yml, profiles.yml, models/, macros/
```

### **Step 8: Configure dbt Connection**

Verify `profiles.yml` configuration:

```yaml
# dbt/transforms/09_insta_churn/profiles.yml
clickhouse_ftw:
  target: remote
  outputs:
    remote:
      type: clickhouse
      host: clickhouse  # Use "clickhouse" for local Docker, or remote IP for remote setup
      port: 9000
      user: default
      password: ""
      database: default
      schema: clean
      secure: false
```

### **Step 9: Define Source Tables**

The `sources.yml` defines our raw data:

```yaml
# models/sources.yml
version: 2

sources:
  - name: raw
    schema: raw
    description: "Raw Instacart dataset loaded via dlt pipeline"
    tables:
      - name: raw___insta_products
        description: "Product catalog with aisle/department relationships"
        columns:
          - name: product_id
            description: "Unique product identifier"
            tests:
              - not_null
              - unique
          - name: product_name
            tests:
              - not_null
          - name: aisle_id
            tests:
              - not_null
          - name: department_id
            tests:
              - not_null
      
      - name: raw___insta_orders
        description: "Customer orders with behavioral data"
        columns:
          - name: order_id
            tests:
              - not_null
              - unique
          - name: user_id
            tests:
              - not_null
      
      # ... additional source definitions
```

### **Step 10: Implement 3NF Models**

#### **10.1: Departments (Clean Master Data)**

```sql
-- models/clean/g2_v2_departments_3nf.sql
{{ config(materialized='table', schema='clean') }}

SELECT 
    CAST(department_id AS UInt32) AS department_id,
    TRIM(department) AS department_name,
    
    -- Data quality flags
    CASE 
        WHEN TRIM(department) IS NULL OR TRIM(department) = '' THEN 1
        ELSE 0 
    END AS has_missing_name
    
FROM {{ source('raw', 'raw___insta_departments') }}
WHERE department_id IS NOT NULL
```

#### **10.2: Aisles (Referentially Intact)**

```sql
-- models/clean/g2_v2_aisles_3nf.sql  
{{ config(materialized='table', schema='clean') }}

SELECT 
    CAST(a.aisle_id AS UInt32) AS aisle_id,
    TRIM(a.aisle) AS aisle_name,
    CAST(a.department_id AS UInt32) AS department_id,
    
    -- Data quality flags
    CASE 
        WHEN TRIM(a.aisle) IS NULL OR TRIM(a.aisle) = '' THEN 1
        ELSE 0 
    END AS has_missing_name,
    
    -- Referential integrity check
    CASE 
        WHEN d.department_id IS NULL THEN 1
        ELSE 0
    END AS has_invalid_department_fk
    
FROM {{ source('raw', 'raw___insta_aisles') }} a
LEFT JOIN {{ source('raw', 'raw___insta_departments') }} d
    ON a.department_id = d.department_id
WHERE a.aisle_id IS NOT NULL
```

#### **10.3: Products (3NF - Eliminates Transitive Dependency)**

```sql  
-- models/clean/g2_v2_products_3nf.sql
{{ config(materialized='table', schema='clean') }}

SELECT 
    CAST(product_id AS UInt32) AS product_id,
    TRIM(product_name) AS product_name,
    
    -- Direct FK to aisle only (3NF compliance)
    CAST(aisle_id AS UInt32) AS aisle_id,
    
    -- REMOVED: department_id (transitive dependency eliminated)
    -- Department is accessible via: product → aisle → department
    
    -- Derived attributes for business analysis
    CASE 
        WHEN LOWER(product_name) LIKE '%organic%' THEN 1 
        ELSE 0 
    END AS is_organic,
    
    CASE 
        WHEN LOWER(product_name) LIKE '%gluten%free%' OR 
             LOWER(product_name) LIKE '%gluten-free%' THEN 1 
        ELSE 0 
    END AS is_gluten_free,
    
    -- Data quality flags  
    CASE 
        WHEN TRIM(product_name) IS NULL OR TRIM(product_name) = '' THEN 1
        ELSE 0 
    END AS has_missing_name
    
FROM {{ source('raw', 'raw___insta_products') }}
WHERE product_id IS NOT NULL
```

#### **10.4: Orders (Customer Behavior Analysis)**

```sql
-- models/clean/g2_v2_orders_3nf.sql
{{ config(materialized='table', schema='clean') }}

SELECT 
    CAST(order_id AS UInt32) AS order_id,
    CAST(user_id AS UInt32) AS user_id,  
    CAST(order_number AS UInt16) AS order_number,
    CAST(order_dow AS UInt8) AS order_dow,
    CAST(order_hour_of_day AS UInt8) AS order_hour_of_day,
    
    -- Handle null days_since_prior_order (first orders)
    CASE 
        WHEN days_since_prior_order IS NULL THEN 0
        ELSE CAST(days_since_prior_order AS UInt16) 
    END AS days_since_prior_order,
    
    -- Derived time segments for analysis
    CASE 
        WHEN order_hour_of_day BETWEEN 6 AND 11 THEN 'Morning'
        WHEN order_hour_of_day BETWEEN 12 AND 17 THEN 'Afternoon'  
        WHEN order_hour_of_day BETWEEN 18 AND 22 THEN 'Evening'
        ELSE 'Night'
    END AS time_segment,
    
    CASE 
        WHEN order_dow IN (0, 6) THEN 'Weekend'
        ELSE 'Weekday'  
    END AS day_type
    
FROM {{ source('raw', 'raw___insta_orders') }}
WHERE order_id IS NOT NULL AND user_id IS NOT NULL
```

#### **10.5: Order Products (Combines Train + Prior)**

```sql
-- models/clean/g2_v2_order_products_3nf.sql
{{ config(materialized='table', schema='clean') }}

-- Union train and prior datasets with source tracking
WITH combined_order_products AS (
    SELECT 
        CAST(order_id AS UInt32) AS order_id,
        CAST(product_id AS UInt32) AS product_id, 
        CAST(add_to_cart_order AS UInt8) AS add_to_cart_order,
        CAST(reordered AS UInt8) AS reordered,
        'train' AS dataset_source
    FROM {{ source('raw', 'raw___insta_order_products_train') }}
    
    UNION ALL
    
    SELECT 
        CAST(order_id AS UInt32) AS order_id,
        CAST(product_id AS UInt32) AS product_id,
        CAST(add_to_cart_order AS UInt8) AS add_to_cart_order, 
        CAST(reordered AS UInt8) AS reordered,
        'prior' AS dataset_source
    FROM {{ source('raw', 'raw___insta_order_products_prior') }}
)

SELECT 
    order_id,
    product_id, 
    dataset_source,
    add_to_cart_order,
    reordered,
    
    -- Business logic flags
    CASE WHEN add_to_cart_order = 1 THEN 1 ELSE 0 END AS is_first_item,
    CASE WHEN reordered = 1 THEN 1 ELSE 0 END AS is_reorder,
    
    -- Composite primary key components
    ROW_NUMBER() OVER (
        PARTITION BY order_id, product_id, dataset_source 
        ORDER BY add_to_cart_order
    ) as row_num

FROM combined_order_products
WHERE order_id IS NOT NULL AND product_id IS NOT NULL
```

#### **10.6: Users (Aggregated Customer Metrics)**

```sql
-- models/clean/g2_v2_users_3nf.sql  
{{ config(materialized='table', schema='clean') }}

WITH user_order_stats AS (
    SELECT 
        user_id,
        COUNT(DISTINCT order_id) AS total_orders,
        MAX(order_number) AS max_order_number,
        MIN(order_number) AS min_order_number,
        AVG(days_since_prior_order) AS avg_days_between_orders,
        MAX(days_since_prior_order) AS max_days_between_orders,
        
        -- Time-based metrics
        MIN(order_dow) AS first_order_dow,
        MAX(order_dow) AS last_order_dow,
        COUNT(DISTINCT order_dow) AS unique_order_days,
        
        -- Behavioral patterns
        AVG(order_hour_of_day) AS avg_order_hour,
        COUNT(CASE WHEN order_dow IN (0, 6) THEN 1 END) AS weekend_orders,
        COUNT(CASE WHEN order_dow NOT IN (0, 6) THEN 1 END) AS weekday_orders
        
    FROM {{ ref('g2_v2_orders_3nf') }}
    GROUP BY user_id
),

user_product_stats AS (
    SELECT 
        o.user_id,
        COUNT(DISTINCT op.product_id) AS total_unique_products,
        SUM(op.reordered) AS total_reorders,
        COUNT(op.order_id) AS total_items_purchased,
        AVG(op.add_to_cart_order) AS avg_cart_position
        
    FROM {{ ref('g2_v2_orders_3nf') }} o
    JOIN {{ ref('g2_v2_order_products_3nf') }} op ON o.order_id = op.order_id
    GROUP BY o.user_id
)

SELECT 
    CAST(os.user_id AS UInt32) AS user_id,
    
    -- Order behavior metrics
    os.total_orders,
    os.max_order_number,
    os.avg_days_between_orders,
    os.max_days_between_orders,
    
    -- Product behavior metrics  
    ps.total_unique_products,
    ps.total_items_purchased,
    ps.total_reorders,
    ps.avg_cart_position,
    
    -- Calculated KPIs
    CASE 
        WHEN ps.total_items_purchased > 0 THEN 
            ps.total_reorders / ps.total_items_purchased 
        ELSE 0 
    END AS user_reorder_rate,
    
    CASE 
        WHEN os.total_orders > 0 THEN 
            ps.total_items_purchased / os.total_orders 
        ELSE 0 
    END AS avg_basket_size,
    
    -- Time preference patterns
    os.avg_order_hour,
    os.weekend_orders,
    os.weekday_orders,
    CASE 
        WHEN os.weekend_orders + os.weekday_orders > 0 THEN
            os.weekend_orders / (os.weekend_orders + os.weekday_orders)
        ELSE 0
    END AS weekend_preference_ratio,
    
    -- Customer segmentation flags
    CASE 
        WHEN os.total_orders >= 50 THEN 'High Frequency'
        WHEN os.total_orders >= 20 THEN 'Medium Frequency'  
        WHEN os.total_orders >= 5 THEN 'Low Frequency'
        ELSE 'Very Low Frequency'
    END AS order_frequency_segment,
    
    CASE
        WHEN ps.user_reorder_rate >= 0.8 THEN 'Loyal'
        WHEN ps.user_reorder_rate >= 0.5 THEN 'Regular' 
        WHEN ps.user_reorder_rate >= 0.2 THEN 'Occasional'
        ELSE 'New/Experimental'
    END AS loyalty_segment

FROM user_order_stats os
JOIN user_product_stats ps ON os.user_id = ps.user_id
```

### **Step 11: Run 3NF Transformations**

```bash
# Test dbt connection
docker compose --profile jobs run --rm dbt debug

# Run the 3NF models
docker compose --profile jobs run --rm dbt run --models clean

# Run data quality tests
docker compose --profile jobs run --rm dbt test --models clean
```

**Expected Output:**
```
Running with dbt=1.0.0
Found 6 models, 15 tests, 0 snapshots, 0 analyses, 165 macros, 0 operations, 0 seed files, 6 sources, 0 exposures, 0 metrics

Completed successfully
Done. PASS=6 WARN=0 ERROR=0 SKIP=0 TOTAL=6
```

---

## ⭐ **Phase 3: Dimensional Modeling (Star Schema)**

### **Why Star Schema After 3NF?**

1. **3NF ensures data integrity** → Clean, consistent base tables
2. **Star schema optimizes analytics** → Fast aggregations and joins
3. **Business-friendly structure** → Intuitive for analysts and BI tools

### **Step 12: Design Star Schema**

Our star schema consists of:
- **Fact Tables**: Store quantitative business events
- **Dimension Tables**: Store descriptive attributes for analysis

```
       ┌─────────────────┐
       │   DIM_PRODUCTS  │
       │                 │◄─────┐
       │ product_id (PK) │      │
       │ product_name    │      │
       │ aisle_name      │      │
       │ department_name │      │
       │ is_organic      │      │
       └─────────────────┘      │
                                │
       ┌─────────────────┐      │    ┌─────────────────┐
       │   DIM_CUSTOMERS │      │    │ FACT_ORDER_PRODS│
       │                 │◄─────┼────┤                 │
       │ user_id (PK)    │      │    │ order_id        │
       │ total_orders    │      │    │ product_id   (FK)│
       │ loyalty_segment │      │    │ user_id      (FK)│
       │ avg_basket_size │      │    │ add_to_cart_ord │
       └─────────────────┘      │    │ reordered       │
                                │    │ dataset_source  │
       ┌─────────────────┐      │    └─────────────────┘
       │   DIM_TIME      │      │              │
       │                 │◄─────┘              │
       │ order_id (PK)   │                     │
       │ order_dow       │                     │
       │ order_hour      │                     │
       │ time_segment    │                     │
       │ day_type        │                     │
       └─────────────────┘                     │
                                               ▼
                                    ┌─────────────────┐
                                    │   FACT_ORDERS   │
                                    │                 │
                                    │ order_id (PK)   │
                                    │ user_id      (FK)│
                                    │ order_number    │
                                    │ basket_size     │
                                    │ total_reorders  │
                                    │ avg_cart_pos    │
                                    └─────────────────┘
```

### **Step 13: Build Dimension Tables**

#### **13.1: Products Dimension (Denormalized)**

```sql
-- models/mart/g2_v2_dim_products_star.sql
{{ config(materialized='table', schema='mart') }}

SELECT 
    p.product_id,
    p.product_name,
    p.is_organic,
    p.is_gluten_free,
    
    -- Aisle information (denormalized)
    a.aisle_id,
    a.aisle_name,
    
    -- Department information (denormalized)  
    d.department_id,
    d.department_name,
    
    -- Product hierarchy path for drill-down analysis
    CONCAT(d.department_name, ' > ', a.aisle_name, ' > ', p.product_name) AS product_hierarchy,
    
    -- Business categorization
    CASE 
        WHEN d.department_name IN ('produce', 'meat seafood', 'dairy eggs') THEN 'Fresh'
        WHEN d.department_name IN ('frozen', 'canned goods', 'dry goods pasta') THEN 'Packaged' 
        WHEN d.department_name IN ('beverages', 'snacks') THEN 'Consumables'
        ELSE 'Other'
    END AS product_category,
    
    -- Analytics flags
    CASE WHEN p.is_organic = 1 THEN 'Organic' ELSE 'Conventional' END AS organic_label,
    CASE WHEN p.is_gluten_free = 1 THEN 'Gluten-Free' ELSE 'Regular' END AS gluten_label
    
FROM {{ ref('g2_v2_products_3nf') }} p
JOIN {{ ref('g2_v2_aisles_3nf') }} a ON p.aisle_id = a.aisle_id  
JOIN {{ ref('g2_v2_departments_3nf') }} d ON a.department_id = d.department_id
```

#### **13.2: Customers Dimension (Behavioral Segments)**

```sql
-- models/mart/g2_v2_dim_customers.sql
{{ config(materialized='table', schema='mart') }}

SELECT 
    user_id,
    total_orders,
    total_unique_products,
    total_items_purchased, 
    avg_basket_size,
    user_reorder_rate,
    avg_days_between_orders,
    
    -- Behavioral segments
    order_frequency_segment,
    loyalty_segment,
    
    -- Shopping patterns
    weekend_preference_ratio,
    avg_order_hour,
    
    -- Customer value tiers
    CASE 
        WHEN total_items_purchased >= 500 THEN 'High Value'
        WHEN total_items_purchased >= 100 THEN 'Medium Value'
        WHEN total_items_purchased >= 20 THEN 'Low Value'  
        ELSE 'New Customer'
    END AS customer_value_tier,
    
    -- Churn risk assessment
    CASE 
        WHEN max_days_between_orders > 60 AND total_orders < 5 THEN 'High Risk'
        WHEN max_days_between_orders > 30 AND user_reorder_rate < 0.3 THEN 'Medium Risk'
        WHEN user_reorder_rate > 0.6 AND total_orders > 10 THEN 'Low Risk'
        ELSE 'Moderate Risk'
    END AS churn_risk_segment,
    
    -- Engagement level
    CASE
        WHEN total_orders >= 20 AND avg_days_between_orders <= 14 THEN 'Highly Engaged'
        WHEN total_orders >= 10 AND avg_days_between_orders <= 21 THEN 'Engaged' 
        WHEN total_orders >= 5 AND avg_days_between_orders <= 30 THEN 'Moderately Engaged'
        ELSE 'Low Engagement'
    END AS engagement_level
    
FROM {{ ref('g2_v2_users_3nf') }}
```

#### **13.3: Time Dimension**

```sql  
-- models/mart/g2_v2_dim_time_star.sql
{{ config(materialized='table', schema='mart') }}

SELECT 
    order_id,
    order_dow,
    order_hour_of_day,
    days_since_prior_order,
    time_segment,
    day_type,
    
    -- Extended time attributes for analysis
    CASE order_dow
        WHEN 0 THEN 'Sunday'
        WHEN 1 THEN 'Monday' 
        WHEN 2 THEN 'Tuesday'
        WHEN 3 THEN 'Wednesday'
        WHEN 4 THEN 'Thursday'
        WHEN 5 THEN 'Friday'
        WHEN 6 THEN 'Saturday'
    END AS day_name,
    
    -- Purchase timing patterns
    CASE 
        WHEN days_since_prior_order = 0 THEN 'Same Day'
        WHEN days_since_prior_order <= 3 THEN 'Within 3 Days'
        WHEN days_since_prior_order <= 7 THEN 'Within Week'  
        WHEN days_since_prior_order <= 14 THEN 'Within 2 Weeks'
        WHEN days_since_prior_order <= 30 THEN 'Within Month'
        ELSE 'Over Month'
    END AS purchase_recency,
    
    -- Business day classification
    CASE 
        WHEN order_dow BETWEEN 1 AND 5 THEN 1 
        ELSE 0 
    END AS is_business_day,
    
    -- Peak shopping hours
    CASE
        WHEN order_hour_of_day BETWEEN 9 AND 11 THEN 1 
        ELSE 0 
    END AS is_morning_peak,
    
    CASE
        WHEN order_hour_of_day BETWEEN 15 AND 17 THEN 1
        ELSE 0  
    END AS is_afternoon_peak
    
FROM {{ ref('g2_v2_orders_3nf') }}
```

### **Step 14: Build Fact Tables**

#### **14.1: Order Products Fact (Granular Transaction Level)**

```sql
-- models/mart/g2_v2_fact_order_products_star.sql 
{{ config(materialized='table', schema='mart') }}

SELECT 
    -- Dimension foreign keys
    op.order_id,
    op.product_id, 
    o.user_id,
    
    -- Degenerate dimensions (attributes stored in fact)
    op.dataset_source,
    op.add_to_cart_order,
    
    -- Facts (measures)
    op.reordered,
    op.is_first_item,
    op.is_reorder,
    
    -- Derived measures for analysis
    1 AS quantity_ordered,  -- Each row = 1 product ordered
    
    -- Order context measures
    o.order_number,
    o.days_since_prior_order,
    
    -- Product context (for fast filtering without joins)
    p.department_name,
    p.aisle_name,
    p.product_category,
    p.is_organic,
    
    -- Customer context (for segmentation analysis)
    c.loyalty_segment,
    c.customer_value_tier,
    c.churn_risk_segment,
    
    -- Time context (for temporal analysis)  
    t.day_type,
    t.time_segment,
    t.purchase_recency

FROM {{ ref('g2_v2_order_products_3nf') }} op
JOIN {{ ref('g2_v2_orders_3nf') }} o ON op.order_id = o.order_id
JOIN {{ ref('g2_v2_dim_products_star') }} p ON op.product_id = p.product_id  
JOIN {{ ref('g2_v2_dim_customers') }} c ON o.user_id = c.user_id
JOIN {{ ref('g2_v2_dim_time_star') }} t ON op.order_id = t.order_id
```

#### **14.2: Orders Fact (Aggregated Order Level)**

```sql
-- models/mart/g2_v2_fact_orders_star.sql
{{ config(materialized='table', schema='mart') }}

WITH order_aggregates AS (
    SELECT 
        order_id,
        COUNT(DISTINCT product_id) AS basket_size,
        SUM(reordered) AS total_reorders,
        COUNT(*) AS total_items,
        AVG(add_to_cart_order) AS avg_cart_position,
        MAX(add_to_cart_order) AS max_cart_position,
        
        -- Product mix analytics  
        COUNT(DISTINCT CASE WHEN p.is_organic = 1 THEN product_id END) AS organic_items,
        COUNT(DISTINCT CASE WHEN p.product_category = 'Fresh' THEN product_id END) AS fresh_items,
        COUNT(DISTINCT p.department_name) AS unique_departments,
        COUNT(DISTINCT p.aisle_name) AS unique_aisles
        
    FROM {{ ref('g2_v2_order_products_3nf') }} op
    JOIN {{ ref('g2_v2_dim_products_star') }} p ON op.product_id = p.product_id
    GROUP BY order_id
)

SELECT 
    -- Dimension foreign keys
    o.order_id,
    o.user_id,
    
    -- Order attributes
    o.order_number, 
    o.days_since_prior_order,
    
    -- Aggregated facts from order products
    oa.basket_size,
    oa.total_reorders,  
    oa.total_items,
    oa.avg_cart_position,
    oa.organic_items,
    oa.fresh_items,
    oa.unique_departments,
    oa.unique_aisles,
    
    -- Calculated measures
    CASE 
        WHEN oa.total_items > 0 THEN oa.total_reorders / oa.total_items 
        ELSE 0 
    END AS order_reorder_rate,
    
    CASE 
        WHEN oa.total_items > 0 THEN oa.organic_items / oa.total_items
        ELSE 0  
    END AS organic_item_ratio,
    
    -- Business flags
    CASE WHEN oa.basket_size >= 20 THEN 1 ELSE 0 END AS is_large_basket,
    CASE WHEN oa.total_reorders >= oa.total_items * 0.7 THEN 1 ELSE 0 END AS is_reorder_heavy,
    
    -- Context from dimensions (avoid joins in analysis)
    c.loyalty_segment,
    c.customer_value_tier,  
    c.churn_risk_segment,
    t.day_type,
    t.time_segment

FROM {{ ref('g2_v2_orders_3nf') }} o
JOIN order_aggregates oa ON o.order_id = oa.order_id
JOIN {{ ref('g2_v2_dim_customers') }} c ON o.user_id = c.user_id
JOIN {{ ref('g2_v2_dim_time_star') }} t ON o.order_id = t.order_id
```

### **Step 15: Run Dimensional Models**

```bash
# Run all mart models (star schema)
docker compose --profile jobs run --rm dbt run --models mart

# Run tests to ensure data quality
docker compose --profile jobs run --rm dbt test --models mart

# Generate documentation
docker compose --profile jobs run --rm dbt docs generate
docker compose --profile jobs run --rm dbt docs serve --port 8080
```

---

## 📊 **Phase 4: Business Analytics & KPIs**

Now that we have clean normalized data and optimized star schema, let's build business analytics that answer our key questions.

### **Step 16: Customer Churn Analysis**

```sql
-- models/mart/g2_v2_analytics_customer_churn.sql
{{ config(materialized='table', schema='mart') }}

WITH customer_metrics AS (
    SELECT 
        user_id,
        loyalty_segment,
        churn_risk_segment,
        engagement_level,
        customer_value_tier,
        total_orders,
        avg_days_between_orders,
        user_reorder_rate,
        max_days_between_orders,
        total_items_purchased,
        
        -- Recency analysis (days since last order)
        -- Note: In real scenario, you'd compare against current date
        max_days_between_orders AS days_since_last_order,
        
        -- Frequency scoring
        CASE 
            WHEN total_orders >= 50 THEN 5
            WHEN total_orders >= 30 THEN 4  
            WHEN total_orders >= 15 THEN 3
            WHEN total_orders >= 5 THEN 2
            ELSE 1
        END AS frequency_score,
        
        -- Monetary scoring (based on total items as proxy)
        CASE
            WHEN total_items_purchased >= 500 THEN 5
            WHEN total_items_purchased >= 200 THEN 4
            WHEN total_items_purchased >= 50 THEN 3  
            WHEN total_items_purchased >= 10 THEN 2
            ELSE 1
        END AS monetary_score
        
    FROM {{ ref('g2_v2_dim_customers') }}
),

rfm_analysis AS (
    SELECT 
        *,
        -- Recency scoring (lower days = higher score)
        CASE
            WHEN days_since_last_order <= 7 THEN 5
            WHEN days_since_last_order <= 14 THEN 4
            WHEN days_since_last_order <= 30 THEN 3
            WHEN days_since_last_order <= 60 THEN 2  
            ELSE 1
        END AS recency_score,
        
        -- RFM composite score
        frequency_score + monetary_score AS fm_score
        
    FROM customer_metrics
),

churn_segments AS (
    SELECT 
        *,
        recency_score + frequency_score + monetary_score AS rfm_total_score,
        
        -- Customer lifecycle segmentation
        CASE
            WHEN recency_score >= 4 AND frequency_score >= 4 AND monetary_score >= 4 THEN 'Champions'
            WHEN recency_score >= 3 AND frequency_score >= 3 AND monetary_score >= 3 THEN 'loyal_customers'  
            WHEN recency_score >= 3 AND frequency_score >= 2 THEN 'potential_loyalists'
            WHEN recency_score >= 4 AND frequency_score <= 2 THEN 'new_customers'
            WHEN recency_score >= 2 AND frequency_score >= 3 THEN 'at_risk'
            WHEN recency_score <= 2 AND frequency_score >= 2 THEN 'cannot_lose_them'
            WHEN recency_score <= 2 AND frequency_score <= 2 AND monetary_score >= 3 THEN 'hibernating_high_value'
            WHEN recency_score <= 2 AND frequency_score <= 2 THEN 'lost_customers'
            ELSE 'others'
        END AS lifecycle_segment,
        
        -- Churn probability scoring
        CASE  
            WHEN days_since_last_order > 60 AND frequency_score <= 2 THEN 0.9
            WHEN days_since_last_order > 45 AND user_reorder_rate < 0.3 THEN 0.75
            WHEN days_since_last_order > 30 AND frequency_score <= 3 THEN 0.6
            WHEN days_since_last_order > 21 AND user_reorder_rate < 0.5 THEN 0.4
            WHEN days_since_last_order > 14 THEN 0.25
            ELSE 0.1
        END AS churn_probability
        
    FROM rfm_analysis
)

SELECT 
    user_id,
    lifecycle_segment,
    churn_risk_segment,
    churn_probability,
    rfm_total_score,
    recency_score, 
    frequency_score,
    monetary_score,
    days_since_last_order,
    total_orders,
    user_reorder_rate,
    total_items_purchased,
    
    -- Action recommendations  
    CASE lifecycle_segment
        WHEN 'Champions' THEN 'Reward loyalty, ask for reviews, upsell premium products'
        WHEN 'loyal_customers' THEN 'Recommend complementary products, offer exclusive deals'
        WHEN 'potential_loyalists' THEN 'Offer membership program, recommend based on purchase history'
        WHEN 'new_customers' THEN 'Provide onboarding support, educational content'
        WHEN 'at_risk' THEN 'Send personalized offers, win-back campaign'  
        WHEN 'cannot_lose_them' THEN 'Aggressive retention campaign, personal outreach'
        WHEN 'hibernating_high_value' THEN 'Re-engagement campaign with special incentives'
        WHEN 'lost_customers' THEN 'Ignore or very low-cost win-back campaign'
        ELSE 'Standard marketing approach'
    END AS recommended_action
    
FROM churn_segments
ORDER BY churn_probability DESC, rfm_total_score DESC
```

### **Step 17: Product Performance Analytics**

```sql
-- models/mart/g2_v2_analytics_product_performance.sql  
{{ config(materialized='table', schema='mart') }}

WITH product_stats AS (
    SELECT 
        p.product_id,
        p.product_name,
        p.department_name,
        p.aisle_name, 
        p.product_category,
        p.is_organic,
        
        -- Volume metrics
        COUNT(DISTINCT f.order_id) AS total_orders_containing,
        COUNT(DISTINCT f.user_id) AS unique_customers,
        SUM(f.quantity_ordered) AS total_quantity_sold,
        
        -- Reorder analytics
        SUM(f.reordered) AS total_reorders,
        COUNT(*) AS total_purchases,
        SUM(f.reordered) / COUNT(*) AS reorder_rate,
        
        -- Cart behavior
        AVG(f.add_to_cart_order) AS avg_cart_position,
        SUM(f.is_first_item) AS times_first_in_cart,
        
        -- Customer penetration
        COUNT(DISTINCT f.user_id) / (SELECT COUNT(DISTINCT user_id) FROM {{ ref('g2_v2_dim_customers') }}) AS customer_penetration_rate
        
    FROM {{ ref('g2_v2_dim_products_star') }} p
    JOIN {{ ref('g2_v2_fact_order_products_star') }} f ON p.product_id = f.product_id
    GROUP BY p.product_id, p.product_name, p.department_name, p.aisle_name, p.product_category, p.is_organic
),

product_rankings AS (
    SELECT 
        *,
        -- Performance rankings within department
        ROW_NUMBER() OVER (PARTITION BY department_name ORDER BY total_quantity_sold DESC) AS dept_volume_rank,
        ROW_NUMBER() OVER (PARTITION BY department_name ORDER BY reorder_rate DESC) AS dept_reorder_rank,
        ROW_NUMBER() OVER (PARTITION BY department_name ORDER BY customer_penetration_rate DESC) AS dept_penetration_rank,
        
        -- Overall rankings
        ROW_NUMBER() OVER (ORDER BY total_quantity_sold DESC) AS overall_volume_rank,
        ROW_NUMBER() OVER (ORDER BY reorder_rate DESC) AS overall_reorder_rank,
        
        -- Performance scoring  
        CASE 
            WHEN reorder_rate >= 0.8 THEN 'Excellent'
            WHEN reorder_rate >= 0.6 THEN 'Good'
            WHEN reorder_rate >= 0.4 THEN 'Average' 
            WHEN reorder_rate >= 0.2 THEN 'Poor'
            ELSE 'Very Poor'
        END AS reorder_performance,
        
        CASE
            WHEN customer_penetration_rate >= 0.5 THEN 'High Penetration'
            WHEN customer_penetration_rate >= 0.2 THEN 'Medium Penetration'
            WHEN customer_penetration_rate >= 0.05 THEN 'Low Penetration'
            ELSE 'Very Low Penetration'  
        END AS penetration_level
        
    FROM product_stats
),

product_classification AS (
    SELECT 
        *,
        -- ABC Analysis based on volume
        CASE
            WHEN overall_volume_rank <= (SELECT COUNT(*) * 0.2 FROM product_rankings) THEN 'A - Top 20%'
            WHEN overall_volume_rank <= (SELECT COUNT(*) * 0.5 FROM product_rankings) THEN 'B - Middle 30%'  
            ELSE 'C - Bottom 50%'
        END AS abc_classification,
        
        -- Product lifecycle stage
        CASE
            WHEN reorder_rate >= 0.7 AND customer_penetration_rate >= 0.3 THEN 'Star Products'
            WHEN reorder_rate >= 0.5 AND customer_penetration_rate >= 0.15 THEN 'Cash Cows'
            WHEN reorder_rate < 0.3 AND customer_penetration_rate >= 0.2 THEN 'Question Marks'  
            WHEN reorder_rate < 0.4 AND customer_penetration_rate < 0.1 THEN 'Dogs'
            ELSE 'Developing'
        END AS product_lifecycle_stage,
        
        -- Strategic recommendations
        CASE
            WHEN reorder_rate >= 0.7 AND customer_penetration_rate >= 0.3 THEN 'Maintain quality, expand availability'
            WHEN reorder_rate >= 0.5 AND customer_penetration_rate >= 0.15 THEN 'Optimize pricing, cross-sell'
            WHEN reorder_rate < 0.3 AND customer_penetration_rate >= 0.2 THEN 'Improve product quality, gather feedback'
            WHEN reorder_rate < 0.4 AND customer_penetration_rate < 0.1 THEN 'Consider discontinuation'
            ELSE 'Monitor performance, targeted marketing'
        END AS strategic_recommendation
        
    FROM product_rankings
)

SELECT 
    product_id,
    product_name,
    department_name,
    aisle_name,
    product_category,
    is_organic,
    
    -- Performance metrics
    total_quantity_sold,
    unique_customers, 
    reorder_rate,
    customer_penetration_rate,
    avg_cart_position,
    
    -- Rankings
    overall_volume_rank,
    overall_reorder_rank,
    dept_volume_rank,
    dept_reorder_rank,
    
    -- Classifications
    abc_classification,
    product_lifecycle_stage,
    reorder_performance,
    penetration_level,
    strategic_recommendation,
    
    -- Financial potential (assuming unit contribution)
    total_quantity_sold * reorder_rate AS loyalty_value_score
    
FROM product_classification  
ORDER BY total_quantity_sold DESC
```

### **Step 18: Market Basket Analysis**

```sql
-- models/mart/g2_v2_analytics_market_basket.sql
{{ config(materialized='table', schema='mart') }}

WITH product_combinations AS (
    -- Find products frequently bought together
    SELECT 
        f1.product_id AS product_a_id,
        f2.product_id AS product_b_id,
        p1.product_name AS product_a_name,
        p2.product_name AS product_b_name, 
        p1.department_name AS product_a_dept,
        p2.department_name AS product_b_dept,
        COUNT(DISTINCT f1.order_id) AS orders_with_both,
        COUNT(DISTINCT f1.user_id) AS customers_buying_both
        
    FROM {{ ref('g2_v2_fact_order_products_star') }} f1
    JOIN {{ ref('g2_v2_fact_order_products_star') }} f2 
        ON f1.order_id = f2.order_id 
        AND f1.product_id < f2.product_id  -- Avoid duplicates and self-joins
    JOIN {{ ref('g2_v2_dim_products_star') }} p1 ON f1.product_id = p1.product_id
    JOIN {{ ref('g2_v2_dim_products_star') }} p2 ON f2.product_id = p2.product_id
    GROUP BY f1.product_id, f2.product_id, p1.product_name, p2.product_name, p1.department_name, p2.department_name
    HAVING COUNT(DISTINCT f1.order_id) >= 10  -- Minimum support threshold
),

individual_product_stats AS (
    SELECT 
        product_id,
        COUNT(DISTINCT order_id) AS total_orders_containing
    FROM {{ ref('g2_v2_fact_order_products_star') }}
    GROUP BY product_id
),

market_basket_metrics AS (
    SELECT 
        pc.*,
        pa.total_orders_containing AS product_a_total_orders,
        pb.total_orders_containing AS product_b_total_orders,
        
        -- Total orders for support calculation
        (SELECT COUNT(DISTINCT order_id) FROM {{ ref('g2_v2_fact_order_products_star') }}) AS total_orders,
        
        -- Support: P(A and B)
        orders_with_both / (SELECT COUNT(DISTINCT order_id) FROM {{ ref('g2_v2_fact_order_products_star') }}) AS support,
        
        -- Confidence: P(B|A) = P(A and B) / P(A)  
        CASE 
            WHEN pa.total_orders_containing > 0 THEN 
                orders_with_both / pa.total_orders_containing 
            ELSE 0 
        END AS confidence_a_to_b,
        
        -- Confidence: P(A|B) = P(A and B) / P(B)
        CASE
            WHEN pb.total_orders_containing > 0 THEN  
                orders_with_both / pb.total_orders_containing
            ELSE 0
        END AS confidence_b_to_a,
        
        -- Lift: P(A and B) / (P(A) * P(B))  
        CASE
            WHEN pa.total_orders_containing > 0 AND pb.total_orders_containing > 0 THEN
                (orders_with_both / (SELECT COUNT(DISTINCT order_id) FROM {{ ref('g2_v2_fact_order_products_star') }})) / 
                ((pa.total_orders_containing / (SELECT COUNT(DISTINCT order_id) FROM {{ ref('g2_v2_fact_order_products_star') }})) * 
                 (pb.total_orders_containing / (SELECT COUNT(DISTINCT order_id) FROM {{ ref('g2_v2_fact_order_products_star') }})))
            ELSE 0
        END AS lift
        
    FROM product_combinations pc
    JOIN individual_product_stats pa ON pc.product_a_id = pa.product_id  
    JOIN individual_product_stats pb ON pc.product_b_id = pb.product_id
),

actionable_associations AS (
    SELECT 
        *,
        -- Association strength classification
        CASE
            WHEN lift >= 2.0 AND confidence_a_to_b >= 0.3 THEN 'Very Strong'
            WHEN lift >= 1.5 AND confidence_a_to_b >= 0.2 THEN 'Strong'  
            WHEN lift >= 1.2 AND confidence_a_to_b >= 0.1 THEN 'Moderate'
            WHEN lift >= 1.0 THEN 'Weak'
            ELSE 'No Association'  
        END AS association_strength,
        
        -- Cross-selling opportunity scoring
        CASE
            WHEN lift >= 1.5 AND confidence_a_to_b >= 0.2 AND orders_with_both >= 50 THEN 5  
            WHEN lift >= 1.3 AND confidence_a_to_b >= 0.15 AND orders_with_both >= 25 THEN 4
            WHEN lift >= 1.2 AND confidence_a_to_b >= 0.1 AND orders_with_both >= 15 THEN 3
            WHEN lift >= 1.1 AND orders_with_both >= 10 THEN 2
            ELSE 1
        END AS cross_sell_opportunity_score,
        
        -- Business recommendations
        CASE 
            WHEN lift >= 2.0 AND confidence_a_to_b >= 0.3 THEN 'Bundle products, place nearby in store'
            WHEN lift >= 1.5 AND confidence_a_to_b >= 0.2 THEN 'Recommend in shopping cart, targeted promotions'  
            WHEN lift >= 1.2 AND confidence_a_to_b >= 0.1 THEN 'Email recommendations, app suggestions'
            ELSE 'Monitor for seasonal patterns'
        END AS recommendation_strategy
        
    FROM market_basket_metrics
    WHERE lift >= 1.0  -- Only show positive associations
)

SELECT 
    product_a_id,
    product_b_id, 
    product_a_name,
    product_b_name,
    product_a_dept,
    product_b_dept,
    
    -- Association metrics
    orders_with_both,
    support,
    confidence_a_to_b,
    confidence_b_to_a, 
    lift,
    
    -- Business metrics
    association_strength,
    cross_sell_opportunity_score,
    recommendation_strategy,
    
    -- Additional context
    customers_buying_both,
    product_a_total_orders,
    product_b_total_orders
    
FROM actionable_associations  
ORDER BY cross_sell_opportunity_score DESC, lift DESC
LIMIT 1000  -- Top associations for business action
```

### **Step 19: Run Business Analytics**

```bash
# Run all analytics models
docker compose --profile jobs run --rm dbt run --models +mart.g2_v2_analytics

# Test the analytics models  
docker compose --profile jobs run --rm dbt test --models +mart.g2_v2_analytics

# Check model results
docker exec -it clickhouse clickhouse-client
```

**Verify Analytics in ClickHouse:**
```sql
-- Top products by volume
SELECT product_name, total_quantity_sold, reorder_rate, abc_classification 
FROM mart.g2_v2_analytics_product_performance 
ORDER BY total_quantity_sold DESC 
LIMIT 10;

-- Customer churn segments  
SELECT lifecycle_segment, COUNT(*) as customers, AVG(churn_probability) as avg_churn_prob
FROM mart.g2_v2_analytics_customer_churn
GROUP BY lifecycle_segment
ORDER BY avg_churn_prob DESC;

-- Top product associations
SELECT product_a_name, product_b_name, lift, confidence_a_to_b, association_strength
FROM mart.g2_v2_analytics_market_basket  
ORDER BY lift DESC
LIMIT 10;
```

---

## 📊 **Phase 5: Data Quality & Monitoring Dashboard**

### **Step 20: Implement Data Quality Monitoring**

```sql
-- models/mart/g2_v2_dq_monitoring_dashboard.sql
{{ config(materialized='table', schema='mart') }}

WITH data_quality_checks AS (
    -- Check 1: Record counts and completeness
    SELECT 
        'raw_data_completeness' AS check_category,
        'Products table completeness' AS check_name,
        COUNT(*) AS total_records,
        COUNT(CASE WHEN product_name IS NULL OR TRIM(product_name) = '' THEN 1 END) AS null_records,
        ROUND(100.0 * COUNT(CASE WHEN product_name IS NULL OR TRIM(product_name) = '' THEN 1 END) / COUNT(*), 2) AS null_percentage,
        CASE 
            WHEN COUNT(CASE WHEN product_name IS NULL OR TRIM(product_name) = '' THEN 1 END) = 0 THEN 'PASS'
            WHEN COUNT(CASE WHEN product_name IS NULL OR TRIM(product_name) = '' THEN 1 END) / COUNT(*) < 0.01 THEN 'WARNING'
            ELSE 'FAIL'
        END AS quality_status,
        CURRENT_TIMESTAMP() AS check_timestamp
    FROM {{ source('raw', 'raw___insta_products') }}
    
    UNION ALL
    
    -- Check 2: Referential integrity
    SELECT 
        'referential_integrity' AS check_category,
        'Products-Aisles FK integrity' AS check_name,
        COUNT(*) AS total_records,
        COUNT(CASE WHEN a.aisle_id IS NULL THEN 1 END) AS null_records,
        ROUND(100.0 * COUNT(CASE WHEN a.aisle_id IS NULL THEN 1 END) / COUNT(*), 2) AS null_percentage,
        CASE 
            WHEN COUNT(CASE WHEN a.aisle_id IS NULL THEN 1 END) = 0 THEN 'PASS'
            ELSE 'FAIL'
        END AS quality_status,
        CURRENT_TIMESTAMP() AS check_timestamp
    FROM {{ source('raw', 'raw___insta_products') }} p
    LEFT JOIN {{ source('raw', 'raw___insta_aisles') }} a ON p.aisle_id = a.aisle_id
    
    UNION ALL
    
    -- Check 3: Data freshness (order dates)
    SELECT 
        'data_freshness' AS check_category,
        'Order data recency' AS check_name,
        COUNT(*) AS total_records,
        COUNT(CASE WHEN days_since_prior_order > 365 THEN 1 END) AS null_records,
        ROUND(100.0 * COUNT(CASE WHEN days_since_prior_order > 365 THEN 1 END) / COUNT(*), 2) AS null_percentage,
        CASE 
            WHEN COUNT(CASE WHEN days_since_prior_order > 365 THEN 1 END) / COUNT(*) < 0.1 THEN 'PASS'
            WHEN COUNT(CASE WHEN days_since_prior_order > 365 THEN 1 END) / COUNT(*) < 0.3 THEN 'WARNING'
            ELSE 'FAIL'
        END AS quality_status,
        CURRENT_TIMESTAMP() AS check_timestamp
    FROM {{ source('raw', 'raw___insta_orders') }}
    WHERE days_since_prior_order IS NOT NULL
    
    UNION ALL
    
    -- Check 4: Business rule validation
    SELECT 
        'business_rules' AS check_category,
        'Valid reorder flag logic' AS check_name,
        COUNT(*) AS total_records,
        COUNT(CASE WHEN reordered NOT IN (0, 1) THEN 1 END) AS null_records,
        ROUND(100.0 * COUNT(CASE WHEN reordered NOT IN (0, 1) THEN 1 END) / COUNT(*), 2) AS null_percentage,
        CASE 
            WHEN COUNT(CASE WHEN reordered NOT IN (0, 1) THEN 1 END) = 0 THEN 'PASS'
            ELSE 'FAIL'
        END AS quality_status,
        CURRENT_TIMESTAMP() AS check_timestamp
    FROM (
        SELECT reordered FROM {{ source('raw', 'raw___insta_order_products_train') }}
        UNION ALL  
        SELECT reordered FROM {{ source('raw', 'raw___insta_order_products_prior') }}
    )
    
    UNION ALL
    
    -- Check 5: Duplicate detection
    SELECT 
        'duplicates' AS check_category,
        'Product ID uniqueness' AS check_name,
        COUNT(*) AS total_records,
        COUNT(*) - COUNT(DISTINCT product_id) AS null_records,
        ROUND(100.0 * (COUNT(*) - COUNT(DISTINCT product_id)) / COUNT(*), 2) AS null_percentage,
        CASE 
            WHEN COUNT(*) = COUNT(DISTINCT product_id) THEN 'PASS'
            ELSE 'FAIL'
        END AS quality_status,
        CURRENT_TIMESTAMP() AS check_timestamp
    FROM {{ source('raw', 'raw___insta_products') }}
)

SELECT 
    check_category,
    check_name,
    total_records,
    null_records AS issues_found,
    null_percentage AS issue_percentage,
    quality_status,
    check_timestamp,
    
    -- Alert priority
    CASE quality_status
        WHEN 'FAIL' THEN 1
        WHEN 'WARNING' THEN 2  
        WHEN 'PASS' THEN 3
    END AS priority,
    
    -- Recommended actions
    CASE 
        WHEN check_category = 'raw_data_completeness' AND quality_status = 'FAIL' THEN 'Investigate data source quality'
        WHEN check_category = 'referential_integrity' AND quality_status = 'FAIL' THEN 'Fix FK relationships'  
        WHEN check_category = 'data_freshness' AND quality_status = 'FAIL' THEN 'Update data pipeline schedule'
        WHEN check_category = 'business_rules' AND quality_status = 'FAIL' THEN 'Validate business logic'
        WHEN check_category = 'duplicates' AND quality_status = 'FAIL' THEN 'Remove duplicate records'
        ELSE 'Monitor trends'
    END AS recommended_action

FROM data_quality_checks  
ORDER BY priority ASC, total_records DESC
```

### **Step 21: Business KPI Dashboard**

```sql
-- models/mart/g2_v2_business_kpi_dashboard.sql
{{ config(materialized='table', schema='mart') }}

WITH business_metrics AS (
    -- Customer metrics
    SELECT 
        'Customer Metrics' AS metric_category,
        'Total Active Customers' AS metric_name,
        COUNT(DISTINCT user_id) AS metric_value,
        'customers' AS unit,
        1 AS sort_order
    FROM {{ ref('g2_v2_dim_customers') }}
    
    UNION ALL
    
    SELECT 
        'Customer Metrics' AS metric_category,
        'High-Value Customers' AS metric_name, 
        COUNT(*) AS metric_value,
        'customers' AS unit,
        2 AS sort_order
    FROM {{ ref('g2_v2_dim_customers') }}
    WHERE customer_value_tier = 'High Value'
    
    UNION ALL
    
    SELECT 
        'Customer Metrics' AS metric_category,
        'At-Risk Customers' AS metric_name,
        COUNT(*) AS metric_value, 
        'customers' AS unit,
        3 AS sort_order
    FROM {{ ref('g2_v2_analytics_customer_churn') }}
    WHERE churn_probability >= 0.7
    
    UNION ALL
    
    -- Product metrics
    SELECT 
        'Product Performance' AS metric_category,
        'Total Active Products' AS metric_name,
        COUNT(DISTINCT product_id) AS metric_value,
        'products' AS unit,
        4 AS sort_order
    FROM {{ ref('g2_v2_analytics_product_performance') }}
    
    UNION ALL
    
    SELECT 
        'Product Performance' AS metric_category,
        'Star Products (Top Performers)' AS metric_name,
        COUNT(*) AS metric_value,
        'products' AS unit, 
        5 AS sort_order
    FROM {{ ref('g2_v2_analytics_product_performance') }}
    WHERE product_lifecycle_stage = 'Star Products'
    
    UNION ALL
    
    -- Order metrics  
    SELECT 
        'Order Analytics' AS metric_category,
        'Total Orders' AS metric_name,
        COUNT(DISTINCT order_id) AS metric_value,
        'orders' AS unit,
        6 AS sort_order  
    FROM {{ ref('g2_v2_fact_orders_star') }}
    
    UNION ALL
    
    SELECT 
        'Order Analytics' AS metric_category,
        'Average Basket Size' AS metric_name,
        ROUND(AVG(basket_size), 2) AS metric_value,
        'items/order' AS unit,
        7 AS sort_order
    FROM {{ ref('g2_v2_fact_orders_star') }}
    
    UNION ALL
    
    SELECT 
        'Order Analytics' AS metric_category, 
        'Overall Reorder Rate' AS metric_name,
        ROUND(AVG(order_reorder_rate) * 100, 2) AS metric_value,
        'percentage' AS unit,
        8 AS sort_order
    FROM {{ ref('g2_v2_fact_orders_star') }}
    
    UNION ALL
    
    -- Revenue proxy metrics
    SELECT 
        'Revenue Indicators' AS metric_category,
        'Total Items Sold' AS metric_name,
        COUNT(*) AS metric_value,
        'items' AS unit,
        9 AS sort_order
    FROM {{ ref('g2_v2_fact_order_products_star') }}
    
    UNION ALL
    
    SELECT 
        'Revenue Indicators' AS metric_category,
        'Organic Items Percentage' AS metric_name, 
        ROUND(100.0 * COUNT(CASE WHEN is_organic = 1 THEN 1 END) / COUNT(*), 2) AS metric_value,
        'percentage' AS unit,
        10 AS sort_order
    FROM {{ ref('g2_v2_fact_order_products_star') }}
),

kpi_targets AS (
    SELECT 
        metric_category,
        metric_name, 
        metric_value,
        unit,
        sort_order,
        
        -- Set performance targets
        CASE metric_name
            WHEN 'Total Active Customers' THEN 200000
            WHEN 'High-Value Customers' THEN metric_value * 0.15  -- Target 15% high-value
            WHEN 'At-Risk Customers' THEN metric_value * 0.05      -- Target max 5% at-risk  
            WHEN 'Star Products (Top Performers)' THEN metric_value * 0.20  -- Target 20% stars
            WHEN 'Average Basket Size' THEN 15.0                   -- Target 15 items/order
            WHEN 'Overall Reorder Rate' THEN 60.0                  -- Target 60% reorder rate
            WHEN 'Organic Items Percentage' THEN 25.0              -- Target 25% organic
            ELSE metric_value
        END AS target_value,
        
        -- Performance status
        CASE 
            WHEN metric_name = 'At-Risk Customers' AND metric_value <= metric_value * 0.05 THEN 'Excellent'
            WHEN metric_name = 'At-Risk Customers' AND metric_value <= metric_value * 0.10 THEN 'Good' 
            WHEN metric_name = 'At-Risk Customers' THEN 'Needs Attention'
            WHEN metric_name = 'Average Basket Size' AND metric_value >= 15 THEN 'Excellent'
            WHEN metric_name = 'Average Basket Size' AND metric_value >= 12 THEN 'Good'
            WHEN metric_name = 'Average Basket Size' THEN 'Needs Attention'
            WHEN metric_name = 'Overall Reorder Rate' AND metric_value >= 60 THEN 'Excellent'
            WHEN metric_name = 'Overall Reorder Rate' AND metric_value >= 50 THEN 'Good'
            WHEN metric_name = 'Overall Reorder Rate' THEN 'Needs Attention'
            ELSE 'Good'  -- Default for informational metrics
        END AS performance_status
        
    FROM business_metrics
)

SELECT 
    metric_category,
    metric_name,
    metric_value,
    target_value,
    unit,
    performance_status,
    
    -- Performance indicator
    CASE performance_status
        WHEN 'Excellent' THEN '🟢'  
        WHEN 'Good' THEN '🟡'
        WHEN 'Needs Attention' THEN '🔴'
        ELSE '📊'
    END AS status_indicator,
    
    -- Variance from target
    CASE 
        WHEN target_value > 0 THEN 
            ROUND(100.0 * (metric_value - target_value) / target_value, 2)
        ELSE NULL
    END AS variance_from_target_pct,
    
    CURRENT_TIMESTAMP() AS dashboard_updated_at
    
FROM kpi_targets
ORDER BY sort_order
```

### **Step 22: Set Up Metabase Dashboard**

```bash
# Access Metabase at http://localhost:3001
# Default setup - create admin account

# Connect to ClickHouse database:
# Host: clickhouse (or your remote IP)  
# Port: 8123
# Database: default
# Username: default
# Password: (leave blank)
```

**Metabase Dashboard Configuration:**

1. **Executive Summary Dashboard**
   - Customer count trends
   - Revenue indicators 
   - Product performance overview
   - Churn risk alerts

2. **Customer Analytics Dashboard**  
   - Churn probability distribution
   - Customer lifecycle segments
   - RFM analysis charts
   - Retention cohort analysis

3. **Product Performance Dashboard**
   - ABC analysis charts
   - Product lifecycle matrix
   - Reorder rate trends  
   - Market basket associations

4. **Operational Dashboard**
   - Data quality monitoring
   - Pipeline health status
   - Processing times
   - Error rates

---
## BELOW THIS ARE OPTIONAL

## 🚀 **Phase 6: Deployment & Production Setup**

### **Step 23: Production Environment Configuration**

```yaml
# docker-compose.prod.yml
version: '3.8'

services:
  clickhouse:
    image: clickhouse/clickhouse-server:23.12
    restart: unless-stopped
    container_name: clickhouse-prod
    ports:
      - "8123:8123" 
      - "9000:9000"
    volumes:
      - clickhouse_data_prod:/var/lib/clickhouse
      - ./clickhouse/config.d:/etc/clickhouse-server/config.d:ro
      - ./clickhouse/users.d:/etc/clickhouse-server/users.d:ro
    environment:
      - CLICKHOUSE_DB=instacart_prod
      - CLICKHOUSE_USER=instacart_user
      - CLICKHOUSE_PASSWORD=${CLICKHOUSE_PASSWORD}
    networks:
      - instacart-network

  dbt:
    build: ./dbt
    container_name: dbt-prod
    depends_on:
      - clickhouse
    volumes:
      - ./dbt/transforms/09_insta_churn:/app
      - ./dbt/logs:/app/logs
    environment:
      - DBT_PROFILES_DIR=/app
      - DBT_TARGET=production
    networks:
      - instacart-network
    command: ["dbt", "run", "--target", "production"]

  metabase:
    image: metabase/metabase:latest
    restart: unless-stopped
    container_name: metabase-prod
    ports:
      - "3001:3000"
    environment:
      - MB_DB_TYPE=h2
      - MB_DB_FILE=/metabase-data/metabase.db
    volumes:
      - metabase_data_prod:/metabase-data
    networks:
      - instacart-network

volumes:
  clickhouse_data_prod:
  metabase_data_prod:

networks:
  instacart-network:
    driver: bridge
```

### **Step 24: Automated Pipeline Scheduling**

```python
# scripts/run_pipeline.py
#!/usr/bin/env python3
"""
Automated Instagram Churn Analysis Pipeline
Runs: Data extraction → dbt transformation → Quality checks → Notifications
"""

import subprocess
import logging
import sys
from datetime import datetime
import json

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler(f'logs/pipeline_{datetime.now().strftime("%Y%m%d")}.log'),
        logging.StreamHandler(sys.stdout)
    ]
)

def run_command(command, description):
    """Execute shell command and handle errors"""
    logging.info(f"Starting: {description}")
    try:
        result = subprocess.run(command, shell=True, check=True, capture_output=True, text=True)
        logging.info(f"✅ Completed: {description}")
        return True, result.stdout
    except subprocess.CalledProcessError as e:
        logging.error(f"❌ Failed: {description}")
        logging.error(f"Error: {e.stderr}")
        return False, e.stderr

def check_data_quality():
    """Check data quality metrics from dbt"""
    logging.info("Checking data quality...")
    
    # Query data quality dashboard
    dq_query = """
    SELECT check_name, quality_status, issue_percentage 
    FROM mart.g2_v2_dq_monitoring_dashboard 
    WHERE quality_status = 'FAIL'
    """
    
    success, output = run_command(
        f'docker exec clickhouse clickhouse-client --query="{dq_query}" --format=JSON',
        "Data quality check"
    )
    
    if success and output.strip():
        failures = json.loads(output)
        if failures:
            logging.warning(f"⚠️  Data quality issues found: {len(failures)} failures")
            for failure in failures:
                logging.warning(f"  - {failure['check_name']}: {failure['issue_percentage']}% issues")
            return False
    
    logging.info("✅ All data quality checks passed")
    return True

def run_full_pipeline():
    """Execute complete pipeline"""
    pipeline_start = datetime.now()
    
    logging.info("🚀 Starting Instagram Churn Analysis Pipeline")
    
    # Step 1: Data extraction (dlt)
    success, _ = run_command(
        "docker compose --profile jobs run --rm dlt python extract-loads/10-dlt-instagram-churn-pipeline.py",
        "Data extraction (dlt)"
    )
    if not success:
        logging.error("❌ Pipeline failed at data extraction")
        return False
    
    # Step 2: Data transformation (dbt)
    success, _ = run_command(
        "docker compose --profile jobs run --rm dbt run",
        "Data transformation (dbt)"
    )
    if not success:
        logging.error("❌ Pipeline failed at data transformation") 
        return False
    
    # Step 3: Data quality tests
    success, _ = run_command(
        "docker compose --profile jobs run --rm dbt test",
        "Data quality tests"
    )
    if not success:
        logging.warning("⚠️ Some data quality tests failed")
    
    # Step 4: Data quality monitoring
    dq_passed = check_data_quality()
    
    # Step 5: Generate documentation
    run_command(
        "docker compose --profile jobs run --rm dbt docs generate",
        "Generate dbt documentation"
    )
    
    pipeline_end = datetime.now()
    duration = pipeline_end - pipeline_start
    
    logging.info(f"🎉 Pipeline completed in {duration}")
    logging.info(f"Data quality status: {'✅ PASSED' if dq_passed else '⚠️ ISSUES DETECTED'}")
    
    return True

if __name__ == "__main__":
    success = run_full_pipeline()
    sys.exit(0 if success else 1)
```

### **Step 25: Add Cron Job for Automation**

```bash
# Add to crontab for daily pipeline execution
# Run every day at 2 AM
0 2 * * * cd /path/to/ftw-de-bootcamp && python scripts/run_pipeline.py

# Weekly full refresh (Sundays at 1 AM)
0 1 * * 0 cd /path/to/ftw-de-bootcamp && docker compose --profile jobs run --rm dbt run --full-refresh
```

---

## 🔍 **Phase 7: Testing & Validation**

### **Step 26: Comprehensive Testing Strategy**

```sql
-- tests/business_logic_tests.sql
-- Custom dbt tests for business logic validation

-- Test 1: Customer reorder rates should be between 0 and 1
SELECT user_id, user_reorder_rate
FROM {{ ref('g2_v2_dim_customers') }}  
WHERE user_reorder_rate < 0 OR user_reorder_rate > 1;

-- Test 2: Order numbers should be sequential for each customer
WITH order_gaps AS (
    SELECT 
        user_id,
        order_number,
        LAG(order_number) OVER (PARTITION BY user_id ORDER BY order_number) AS prev_order_number,
        order_number - LAG(order_number) OVER (PARTITION BY user_id ORDER BY order_number) AS gap
    FROM {{ ref('g2_v2_orders_3nf') }}
)
SELECT user_id, order_number, prev_order_number, gap
FROM order_gaps  
WHERE gap > 1 AND prev_order_number IS NOT NULL;

-- Test 3: Product hierarchy consistency
SELECT p.product_id, p.product_name
FROM {{ ref('g2_v2_dim_products_star') }} p
LEFT JOIN {{ ref('g2_v2_aisles_3nf') }} a ON p.aisle_id = a.aisle_id  
LEFT JOIN {{ ref('g2_v2_departments_3nf') }} d ON p.department_id = d.department_id
WHERE a.aisle_id IS NULL OR d.department_id IS NULL;

-- Test 4: Fact table referential integrity
SELECT f.order_id, f.product_id  
FROM {{ ref('g2_v2_fact_order_products_star') }} f
LEFT JOIN {{ ref('g2_v2_dim_products_star') }} p ON f.product_id = p.product_id
WHERE p.product_id IS NULL;
```

### **Step 27: Performance Testing**

```sql
-- Query performance benchmarks
EXPLAIN PLAN FOR
SELECT 
    p.department_name,
    COUNT(*) AS total_orders,
    AVG(f.basket_size) AS avg_basket_size,
    SUM(f.total_reorders) / SUM(f.total_items) AS dept_reorder_rate
FROM {{ ref('g2_v2_fact_orders_star') }} f
JOIN {{ ref('g2_v2_dim_customers') }} c ON f.user_id = c.user_id
JOIN {{ ref('g2_v2_fact_order_products_star') }} fp ON f.order_id = fp.order_id  
JOIN {{ ref('g2_v2_dim_products_star') }} p ON fp.product_id = p.product_id
WHERE c.customer_value_tier = 'High Value'
GROUP BY p.department_name
ORDER BY dept_reorder_rate DESC;
```

### **Step 28: Business Validation Queries**

```sql  
-- Validate business insights match expectations

-- 1. Top products should have high reorder rates
SELECT product_name, total_quantity_sold, reorder_rate
FROM mart.g2_v2_analytics_product_performance
ORDER BY total_quantity_sold DESC
LIMIT 20;

-- 2. High-value customers should have higher basket sizes
SELECT 
    customer_value_tier,
    AVG(avg_basket_size) AS avg_basket_size,
    AVG(user_reorder_rate) AS avg_reorder_rate,
    COUNT(*) AS customer_count
FROM mart.g2_v2_dim_customers  
GROUP BY customer_value_tier
ORDER BY avg_basket_size DESC;

-- 3. Market basket associations should make business sense
SELECT 
    product_a_name,
    product_b_name, 
    product_a_dept,
    product_b_dept,
    lift,
    confidence_a_to_b
FROM mart.g2_v2_analytics_market_basket
WHERE lift >= 2.0
ORDER BY lift DESC
LIMIT 10;
```

---

## 📚 **Phase 8: Documentation & Knowledge Transfer**

### **Step 29: Create Project Documentation**

```markdown
# Instagram Churn Analysis - Technical Documentation

## Architecture Overview
This project implements a complete data engineering pipeline for customer churn analysis using:
- **Data Lake**: Raw CSV files 
- **Data Warehouse**: ClickHouse (columnar, fast aggregations)
- **Transformation Layer**: dbt (SQL-based, version controlled)  
- **Visualization**: Metabase (self-service BI)

## Data Model Design Decisions

### Why 3NF First?
1. **Data Integrity**: Eliminates update anomalies
2. **Consistency**: Single source of truth for each fact  
3. **Maintainability**: Changes only required in one place
4. **Foundation**: Clean base for dimensional modeling

### Why Star Schema Second?  
1. **Performance**: Optimized for analytical queries
2. **Simplicity**: Business users understand dimensional model
3. **Flexibility**: Easy to add new metrics and dimensions
4. **Scalability**: Handles large data volumes efficiently

## Business Logic Explanations

### Customer Segmentation
- **RFM Analysis**: Recency, Frequency, Monetary scoring
- **Lifecycle Stages**: Champions, Loyal, At-Risk, Lost
- **Churn Prediction**: Based on purchasing patterns

### Product Classification  
- **ABC Analysis**: Pareto principle (80/20 rule)
- **Product Lifecycle**: Star, Cash Cow, Question Mark, Dog
- **Performance Metrics**: Reorder rate, customer penetration

## Key Performance Indicators

| Metric | Target | Business Impact |
|--------|--------|----------------|  
| Customer Retention Rate | >90% | Revenue stability |
| Average Basket Size | >15 items | Order value |
| Reorder Rate | >60% | Customer loyalty |
| High-Value Customers | >15% | Revenue concentration |
| At-Risk Customers | <5% | Churn prevention |

## Troubleshooting Guide

### Common Issues
1. **dbt Connection Errors**: Check ClickHouse container status
2. **Memory Issues**: Increase Docker memory allocation  
3. **Performance Issues**: Add indexes, optimize queries
4. **Data Quality Issues**: Check source data integrity
```

### **Step 30: Create User Guide**

```markdown
# Instagram Churn Analysis - User Guide

## For Business Analysts

### Key Dashboards
1. **Executive Summary**: High-level KPIs and trends
2. **Customer Analytics**: Churn risk and segmentation  
3. **Product Performance**: Sales and reorder analysis
4. **Market Basket**: Cross-selling opportunities

### How to Use Insights  
- **Churn Prevention**: Target at-risk customers with personalized offers
- **Product Strategy**: Focus on star products, improve question marks  
- **Cross-selling**: Implement market basket recommendations
- **Customer Retention**: Develop loyalty programs for high-value segments

### Business Questions You Can Answer
1. Which customers are likely to churn next month?
2. What products should we promote together?
3. Which customer segments are most profitable?  
4. How can we increase average basket size?
5. Which products have declining performance?

## For Data Analysts  

### Query Examples
```sql
-- Customer churn risk analysis
SELECT lifecycle_segment, COUNT(*), AVG(churn_probability)
FROM mart.g2_v2_analytics_customer_churn  
GROUP BY lifecycle_segment;

-- Product cross-sell opportunities  
SELECT product_a_name, product_b_name, lift
FROM mart.g2_v2_analytics_market_basket
WHERE lift >= 1.5 ORDER BY lift DESC;
```

### Adding New Metrics
1. Create new dbt model in `models/mart/`
2. Define business logic in SQL
3. Add tests in `models/schema.yml`  
4. Run `dbt run --models +your_new_model`
5. Add to Metabase dashboards

## For Data Engineers

### Pipeline Maintenance
- **Daily**: Monitor data quality dashboard
- **Weekly**: Review pipeline performance metrics  
- **Monthly**: Optimize slow queries, update documentation
- **Quarterly**: Review and update business logic

### Scaling Considerations
- **Data Volume**: Partition large tables by date
- **Query Performance**: Add materialized views for complex aggregations
- **Infrastructure**: Scale ClickHouse cluster horizontally
- **Processing**: Implement incremental models in dbt
```

---

## 🎯 **Expected Learning Outcomes**

By completing this project, you will have learned:

### **Technical Skills**
- **Data Engineering**: End-to-end pipeline design and implementation
- **SQL Mastery**: Complex analytical queries, window functions, CTEs  
- **dbt Expertise**: Modeling, testing, documentation, deployment
- **Docker**: Container orchestration and environment management
- **ClickHouse**: Columnar database optimization and performance tuning

### **Business Skills**  
- **Customer Analytics**: Churn prediction, segmentation, RFM analysis
- **Product Analytics**: Performance measurement, lifecycle management
- **Market Basket Analysis**: Association rules, cross-selling strategies
- **KPI Development**: Metric definition, target setting, performance monitoring

### **Data Modeling Skills**
- **Normalization**: 1NF, 2NF, 3NF implementation and trade-offs
- **Dimensional Modeling**: Star schema design, fact/dimension tables
- **Data Quality**: Testing strategies, monitoring, alerting
- **Performance Optimization**: Query tuning, indexing, partitioning

---

## 🚀 **Next Steps & Extensions**

### **Advanced Features to Add**
1. **Machine Learning**: Implement churn prediction models using scikit-learn
2. **Real-time Processing**: Add Kafka for streaming data ingestion
3. **Advanced Analytics**: Cohort analysis, customer lifetime value
4. **API Development**: Create REST API for serving predictions  
5. **A/B Testing**: Framework for testing marketing campaigns

### **Production Enhancements**
1. **CI/CD Pipeline**: Automated testing and deployment
2. **Infrastructure as Code**: Terraform for cloud provisioning
3. **Monitoring**: Comprehensive logging, metrics, alerting
4. **Security**: Authentication, authorization, data encryption  
5. **Backup & Recovery**: Automated backup strategies

### **Business Applications**
1. **Marketing Automation**: Triggered campaigns based on churn risk
2. **Inventory Management**: Demand forecasting using purchase patterns  
3. **Pricing Optimization**: Dynamic pricing based on customer segments
4. **Recommendation Engine**: Personalized product suggestions
5. **Store Layout**: Optimize product placement using market basket insights

---

## ✅ **Project Checklist**

- [ ] Environment setup (Docker, WSL2, Git)
- [ ] Data extraction pipeline (dlt)  
- [ ] 3NF normalization (dbt clean layer)
- [ ] Star schema implementation (dbt mart layer)
- [ ] Business analytics models  
- [ ] Data quality monitoring
- [ ] Metabase dashboards
- [ ] Performance optimization
- [ ] Testing and validation
- [ ] Documentation and knowledge transfer
- [ ] Production deployment
- [ ] Automated scheduling  

---

## 🔗 **Resources & References**

### **Documentation**
- [dbt Documentation](https://docs.getdbt.com/)
- [ClickHouse Documentation](https://clickhouse.com/docs/)
- [Metabase Documentation](https://www.metabase.com/docs/)

### **Learning Resources**  
- [Kimball Dimensional Modeling](https://www.kimballgroup.com/)
- [dbt Learn](https://courses.getdbt.com/)
- [ClickHouse Tutorial](https://clickhouse.com/docs/en/tutorial/)

### **Community**
- [dbt Community Slack](https://getdbt.slack.com/)
- [ClickHouse Community](https://github.com/ClickHouse/ClickHouse)
- [r/dataengineering](https://reddit.com/r/dataengineering)

---

**🎉 Congratulations! You've built a production-ready data engineering pipeline for customer churn analysis. This project demonstrates advanced data modeling, business analytics, and engineering best practices that are directly applicable in real-world scenarios.**

<function_calls>
<invoke name="manage_todo_list">
<parameter name="todoList">[{"description": "Analyze dbt models, data sources, and infrastructure setup", "id": 1, "title": "Examine project structure", "status": "completed"}, {"description": "Write comprehensive guide with setup, implementation, and explanations", "id": 2, "title": "Create complete step-by-step guide", "status": "completed"}, {"description": "Include code examples, configurations, and troubleshooting", "id": 3, "title": "Add technical details", "status": "in-progress"}, {"description": "Explain design decisions and analytical models", "id": 4, "title": "Document business logic", "status": "not-started"}]