# 📓 Data Cleaning Journal – Insta Dataset

**Date:** `2025-10-07`  
**Author:** `Calista Jajalla`  
**Dataset:** [Instacart Market Basket Analysis](https://www.kaggle.com/datasets/psparks/instacart-market-basket-analysis/data?select=aisles.csv) (`aisles`, `departments`, `products`, `orders`, `order_products_prior`, `order_products_train`)  
**Purpose:** Consolidate **data quality checks**, validate **table integrity**, and create **metrics for dashboards**.

---

## 🔗 Table of Contents

- [1️⃣ Overview](#1️⃣-overview)  
- [2️⃣ Setup – DQ Log Table](#2️⃣-setup--dq-log-table)  
- [3️⃣ Global Checks](#3️⃣-global-checks)  
  - [3.1 Row Counts](#31-row-counts)  
  - [3.2 Primary Key Uniqueness](#32-primary-key-uniqueness)  
- [4️⃣ Table-Level Checks & Story](#4️⃣-table-level-checks--story)  
  - [4.1. Duplicate Checks and Removal Candidates](#1-duplicate-checks-and-removal-candidates)  
  - [4.2. Uniqueness of Primary Key](#2-uniqueness-of-primary-key)  
  - [4.3. Null or Missing Value Checks](#3-null-or-missing-value-checks)  
  - [4.4. Referential Integrity Checks (Foreign Key Validation)](#4-referential-integrity-checks-foreign-key-validation)  
  - [4.5. Domain / Category Checks](#5-domain--category-checks)  
  - [4.6. Text Length / String Constraints](#6-text-length--string-constraints)  
  - [4.7. Erroneous Row Detection (Schema Mismatch)](#7-erroneous-row-detection-schema-mismatch)  
- [5️⃣ Data Quality Checks Summary](#5️⃣-data-quality-checks-summary)
- [6️⃣ Next Steps & Links](#6️⃣-next-steps--links)

---

## 1️⃣ Overview

**Goal:** Ensure raw data integrity and prepare it for downstream analytics. We focus on six core **data quality categories**:

- **Volume Checks:** row counts and totals.  
- **Uniqueness Checks:** primary key uniqueness.  
- **Completeness Checks:** critical fields not null or empty.  
- **Referential Integrity:** foreign keys match related tables.  
- **Domain/Range Checks:** values within expected ranges.  
- **Duplicates & Anomalies:** detect full-row duplicates and logical inconsistencies.

**Workflow:**

1. Inspect raw tables in Kaggle (valid, mismatched, missing, unique, and most common)
2. Apply DQ checks (SQL queries).  
3. Store results in a central DQ log table: `raw._cali_insta__dq_checks`.  
4. Analyze outcomes (status: PASS/WARN/FAIL).

![Alt text](../v2/Instacart.png "Instacart")
---

## 2️⃣ Setup – DQ Log Table

I created a **central table** to store all DQ metrics, with each row represents one check. Having a central log allows us to track historical DQ results, summarize KPIs, and build dashboards.

```sql
CREATE TABLE IF NOT EXISTS raw._cali_insta__dq_checks
(
    check_time DateTime DEFAULT now(),
    table_name String,
    check_name String,
    status UInt8,        -- INFO=0, PASS=1, WARN=2, FAIL=3
    metric_value Float64,
    metric_text String
)
ENGINE = MergeTree()
ORDER BY (table_name, check_time);
```
## DQ Log Table Columns

| Column         | Type     | Purpose                                                                            |
| -------------- | -------- | ---------------------------------------------------------------------------------- |
| `check_time`   | DateTime | Timestamp of the DQ check. Defaults to `now()`.                                    |
| `table_name`   | String   | Table being checked (e.g., `raw___insta_orders`).                                  |
| `check_name`   | String   | Name of the DQ rule (e.g., `row_count`, `distinct_product_id`).                    |
| `status`       | UInt8    | Numeric indicator of check result. Values: `0=INFO`, `1=PASS`, `2=WARN`, `3=FAIL`. |
| `metric_value` | Float64  | Numeric value of the metric (e.g., row count, percentage nulls, reorder rate).     |
| `metric_text`  | String   | Human-readable description of the metric or rule (helps dashboards & logs).        |

---

## 🟢 Status Codes

The `status` column is central to interpreting results.

0 – INFO
- **Purpose:** Used for informational checks.  
- **Example:** Logging row counts just for awareness, not as a strict DQ rule. A soft check and does **not trigger alerts**.

1 – PASS
- **Purpose:** Check passed successfully.  
- **Example:** Row counts within expected range, primary keys are unique, foreign keys all valid. Indicates **healthy data**.

2 – WARN
- **Purpose:** Check is borderline or slightly outside expected thresholds.  
- **Example:** Minor missing values (<5%), reorder rate slightly off. Alerts you that **review may be needed**, but it isn’t critical.

3 – FAIL
- **Purpose:** Check failed or violated critical rules.  
- **Example:** Duplicate primary keys, required fields null, FK references missing. Signals **action is needed (cleaning)**.

### Sample DQ Results:

Below is a **preview of the DQ checks** for the Insta dataset. Full results are saved in the CSV file: [full results CSV](data/insta_dq_checks.csv).

| check_time         | table_name                      | check_name                    | status | metric_value     | metric_text                                |
|-------------------|--------------------------------|-------------------------------|--------|----------------|-------------------------------------------|
| 2025-10-07 13:33:46 | raw___insta_order_products_train | order_fk_missing              | 1      | 0              | order_id not found in orders               |
| 2025-10-07 13:33:46 | raw___insta_order_products_train | product_fk_missing            | 1      | 0              | product_id not found in products           |
| 2025-10-07 13:33:46 | raw___insta_order_products_train | reorder_rate_baseline         | 1      | 59.8594412751  | expected reorder ~59%                      |
| 2025-10-07 13:33:46 | raw___insta_order_products_train | add_to_cart_order_min_ge1     | 1      | 1              | min add_to_cart_order should be >=1        |
| 2025-10-07 13:33:46 | raw___insta_order_products_train | reordered_domain              | 1      | 0              | reordered not in {0,1}                     |

---
## 3️⃣ Global Checks

### 3.1 Row Counts

This SQL block performs **global data quality checks** for each raw table in the Instacart dataset. The focus here is **volume validation**. It ensures that each table has data before we proceed to more detailed checks.

Purpose:

* Verify that each raw table contains rows (non-empty).
* Log the results into the central DQ table `raw._cali_insta__dq_checks`.
* Capture both **metric value** (number of rows) and **status** (informational in this case).

SQL Breakdown:

```sql
INSERT INTO raw._cali_insta__dq_checks
SELECT now(), 'raw___insta_aisles', 'row_count', toUInt8(0) AS status,
       toFloat64(count()) AS metric_value,
       'row count' AS metric_text
FROM raw.raw___insta_aisles

UNION ALL
SELECT now(), 'raw___insta_departments', 'row_count', 0,
       toFloat64(count()),
       'row count'
FROM raw.raw___insta_departments

UNION ALL
SELECT now(), 'raw___insta_products', 'row_count', 0,
       toFloat64(count()),
       'row count'
FROM raw.raw___insta_products

UNION ALL
SELECT now(), 'raw___insta_orders', 'row_count', 0,
       toFloat64(count()),
       'row count'
FROM raw.raw___insta_orders

UNION ALL
SELECT now(), 'raw___insta_order_products_prior', 'row_count', 0,
       toFloat64(count()),
       'row count'
FROM raw.raw___insta_order_products_prior

UNION ALL
SELECT now(), 'raw___insta_order_products_train', 'row_count', 0,
       toFloat64(count()),
       'row count'
FROM raw.raw___insta_order_products_train;
```

### 3.2  Distinct ID Counts (Uniqueness of Primary Keys)

This SQL block records **distinct ID counts** for each raw dataset table to verify **primary key uniqueness**.

Purpose:

* Ensure there are no duplicate identifiers across dimensions or facts.  
* Each result is inserted into the centralized **`raw._cali_insta__dq_checks`** table
* **Status = 0 (INFO)** since these checks are primarily informational metrics rather than pass/fail thresholds.

SQL Breakdown:

```sql
-- Distinct ID counts (uniqueness of primary keys)
INSERT INTO raw._cali_insta__dq_checks
SELECT now(), 'raw___insta_aisles', 'distinct_aisle_id', 0,
       toFloat64(uniqExact(aisle_id)),
       'unique aisle IDs'
FROM raw.raw___insta_aisles

UNION ALL
SELECT now(), 'raw___insta_departments', 'distinct_department_id', 0,
       toFloat64(uniqExact(department_id)),
       'unique department IDs'
FROM raw.raw___insta_departments

UNION ALL
SELECT now(), 'raw___insta_products', 'distinct_product_id', 0,
       toFloat64(uniqExact(product_id)),
       'unique product IDs'
FROM raw.raw___insta_products

UNION ALL
SELECT now(), 'raw___insta_orders', 'distinct_order_id', 0,
       toFloat64(uniqExact(order_id)),
       'unique order IDs'
FROM raw.raw___insta_orders;
```
---
## 4️⃣ Table-Level Data Quality Checks (Summary and Explanation)

This section defines the per-table checks used for the **Instacart dataset**. Each table was tested for **integrity, consistency, and reference completeness** based on the Kaggle dataset, then logged into the shared audit table `raw._cali_insta__dq_checks`.

The main principle was the same as the global checks, basically classifying checks into:
- **1 = PASS** (meets expected conditions)
- **2 = WARN** (slightly off but still acceptable range)
- **3 = FAIL** (requires data cleaning or investigation)

### 4.1 Duplicate Checks and Removal Candidates

Detecting duplicate rows helps identify redundant data that can inflate aggregates or cause inconsistencies when joining tables. Rather than dropping them immediately, duplicates were logged for manual validation or SQL removal later.

**Coder's notes**: These are **not the exact codes** that I run. I used per table checks so the arrangment and the format changed from the codes listed below. Also, I used a lot of UNION ALL per table :>.

Sample codes:
```sql
-- Aisles
SELECT count() - uniqExact(SHA256(concat(toString(aisle_id),'||', ifNull(aisle,'')))) AS dup_rows
FROM raw.raw___insta_aisles;

-- Departments
SELECT count() - uniqExact(SHA256(concat(toString(department_id),'||', ifNull(department,'')))) AS dup_rows
FROM raw.raw___insta_departments;

-- Products
SELECT count() - uniqExact(SHA256(concat(toString(product_id),'||', ifNull(product_name,''),'||',toString(aisle_id),'||',toString(department_id)))) AS dup_rows
FROM raw.raw___insta_products;
```
### 4.2 Uniqueness of Primary Key

These checks confirm that every key field (e.g., order_id, product_id) is unique. Violations here directly influence table integrity and the accuracy of foreign key mapping.

Sample codes:
```sql
SELECT uniqExact(aisle_id) AS unique_aisles FROM raw.raw___insta_aisles;
SELECT uniqExact(department_id) AS unique_departments FROM raw.raw___insta_departments;
SELECT uniqExact(product_id) AS unique_products FROM raw.raw___insta_products;
SELECT uniqExact(order_id) AS unique_orders FROM raw.raw___insta_orders;
```

### 4.3 Null or Missing Value Checks

isnull().sum() identifies incomplete records that could break joins or cause null propagation during transformations. Empty string filters is also an extra layer of validation, especially for text-based columns like product or department names.

Sample codes:
```sql
-- Aisles
SELECT countIf(aisle IS NULL OR aisle = '') AS missing FROM raw.raw___insta_aisles;

-- Departments
SELECT countIf(department IS NULL OR department = '') AS missing FROM raw.raw___insta_departments;

-- Products
SELECT
    countIf(product_name IS NULL OR product_name = '') +
    countIf(aisle_id IS NULL) +
    countIf(department_id IS NULL) AS total_missing
FROM raw.raw___insta_products;

-- Orders
SELECT (countIf(days_since_prior_order IS NULL) / count()) * 100 AS pct_missing
FROM raw.raw___insta_orders;
```

### 4.4 Referential Integrity Checks (Foreign Key Validation)

These ensure that linked tables reference valid entries. For instance, every order_id in the prior table must exist in the orders table, preventing orphaned records and preserving relational structure.

Sample codes:
```sql
-- Products referencing Aisles and Departments
SELECT count() AS missing_aisle_ref
FROM raw.raw___insta_products p
LEFT JOIN raw.raw___insta_aisles a ON p.aisle_id = a.aisle_id
WHERE a.aisle_id IS NULL;

SELECT count() AS missing_department_ref
FROM raw.raw___insta_products p
LEFT JOIN raw.raw___insta_departments d ON p.department_id = d.department_id
WHERE d.department_id IS NULL;

-- Order_Products_Prior
SELECT count() AS missing_product_fk
FROM raw.raw___insta_order_products_prior op
LEFT JOIN raw.raw___insta_products p ON op.product_id = p.product_id
WHERE p.product_id IS NULL;

SELECT count() AS missing_order_fk
FROM raw.raw___insta_order_products_prior op
LEFT JOIN raw.raw___insta_orders o ON op.order_id = o.order_id
WHERE o.order_id IS NULL;

-- Order_Products_Train
SELECT count() AS missing_product_fk
FROM raw.raw___insta_order_products_train op
LEFT JOIN raw.raw___insta_products p ON op.product_id = p.product_id
WHERE p.product_id IS NULL;

SELECT count() AS missing_order_fk
FROM raw.raw___insta_order_products_train op
LEFT JOIN raw.raw___insta_orders o ON op.order_id = o.order_id
WHERE o.order_id IS NULL;
```

### 4.5 Domain / Category Checks

These validate that categorical fields (like reordered flags or department_ids) contain only permissible values. Such checks test consistency and prevent invalid groupings in analysis or modeling.

Sample codes:
```sql
-- Orders: Valid day-of-week (0–6) and hour-of-day (0–23)
SELECT countIf(toInt32(order_dow) < 0 OR toInt32(order_dow) > 6) AS invalid_dow
FROM raw.raw___insta_orders;

SELECT countIf(toInt32(order_hour_of_day) < 0 OR toInt32(order_hour_of_day) > 23) AS invalid_hour
FROM raw.raw___insta_orders;

-- Order_Products_Prior and Train: reordered flag in {0,1}
SELECT countIf(reordered NOT IN (0,1) OR reordered IS NULL) AS invalid
FROM raw.raw___insta_order_products_prior;

SELECT countIf(reordered NOT IN (0,1) OR reordered IS NULL) AS invalid
FROM raw.raw___insta_order_products_train;

-- Orders: order_number domain
SELECT max(order_number) AS max_order_number FROM raw.raw___insta_orders;
```

### 4.6 Text Length / String Constraints

String length validation (e.g., product names not exceeding 512 characters) detects anomalies from poorly imported or corrupted text data. This can also help standardize downstream text analytics and metadata consistency.

Sample code:
```sql
-- Products: product_name length <= 512 characters
SELECT count() AS over_512
FROM raw.raw___insta_products
WHERE lengthUTF8(product_name) > 512;
```

### 4.7 Statistical / Aggregate Health Checks

Checks general table size expectations or metric baselines. 

- Where did I get this info from? 

  - Ans: From Kaggle :>. I checked 'Data Explorer' of dataset, specifically aisles.csv, departments.csv, products.csv.

- Is this part necessary?

  - Ans: Not really, since we already know what's in the dataset. Although this can be helpful for checking ingestion problems.

Sample code:
```sql
-- Orders baseline: row and user count
SELECT count() AS total_orders, uniqExact(user_id) AS unique_users
FROM raw.raw___insta_orders;

-- Products baseline: expected ~49,688 unique products
SELECT uniqExact(product_id) AS unique_products FROM raw.raw___insta_products;

-- Reorder rate (expected ~59%)
SELECT
    toFloat64(sum(toUInt64(reordered))) / toFloat64(count()) * 100.0 AS reorder_pct
FROM raw.raw___insta_order_products_prior;

SELECT
    toFloat64(sum(toUInt64(reordered))) / toFloat64(count()) * 100.0 AS reorder_pct
FROM raw.raw___insta_order_products_train;
```
---
## 5️⃣ Data Quality Checks Summary

| Table Name | Checks Performed |
|-------------|------------------|
| **orders** | **Duplicate Checks:** `orders.duplicated().sum()` to detect repeated order entries.<br>**Primary Key Uniqueness:** `orders['order_id'].is_unique` to verify unique identifiers.<br>**Null Checks:** `orders.isnull().sum()` for missing attributes.<br>**Referential Integrity:** Ensured `order_id` exists in dependent tables (`prior`, `train`). |
| **products** | **Duplicate Checks:** `products.duplicated().sum()` to identify repeated product rows.<br>**Primary Key Uniqueness:** `products['product_id'].is_unique` to maintain product integrity.<br>**Null or Missing Values:** `products.isnull().sum()` and filtering empty product names.<br>**Domain Checks:** `products['aisle_id']` and `products['department_id']` to verify expected categorical values.<br>**String Constraints:** `df['product_name'].str.len().max()` to flag overlong or malformed names. |
| **departments** | **Duplicate Checks:** `departments.duplicated().sum()` for repeated department rows.<br>**Primary Key Uniqueness:** `departments['department_id'].is_unique`.<br>**Null Checks:** `departments.isnull().sum()` and empty strings for department names. |
| **aisles** | **Duplicate Checks:** `aisles.duplicated().sum()`.<br>**Primary Key Uniqueness:** `aisles['aisle_id'].is_unique`.<br>**Null Checks:** `aisles.isnull().sum()` and string emptiness for aisle names. |
| **prior** | **Duplicate Checks:** `prior.duplicated().sum()` to catch repeated order-product pairs.<br>**Null Checks:** `prior.isnull().sum()`.<br>**Referential Integrity:** `prior[~prior['product_id'].isin(products['product_id'])]` and `prior[~prior['order_id'].isin(orders['order_id'])]` to confirm valid foreign key links.<br>**Domain Checks:** `prior['reordered'].unique()` expecting `{0,1}` values only. |
| **train** | **Null Checks:** `train.isnull().sum()`.<br>**Referential Integrity:** Verified all `product_id` and `order_id` values exist in `products` and `orders`.<br>**Domain Checks:** Ensured `train['reordered']` values conform to binary categories `{0,1}`. |

### Again, full results are saved in the CSV file: [full results CSV](data/insta_dq_checks.csv).

---
MEMA SECTION (coz nde ko pa naayos format sa sql)
Here's the my sql queries that I run for cleaning:

[full results CSV](data/insta_dq_checks.csv). ### << Not real link, full query is a work in progress....
---
## 6️⃣ Next Steps & Links
- Store results in central DQ table (raw._cali_insta__dq_checks).
- Perform 'Sanity checks' for data. Like, does the data makes sense? Are prices correct? Are there outliers, keme. 

Reference: 
- [Instacart Market Basket Analysis](https://www.kaggle.com/datasets/psparks/instacart-market-basket-analysis/data?select=aisles.csv)
- Sir Myk's Notes
- [Data Cleaning Materials](https://www.telm.ai/blog/sql-data-quality-checks/)
- Datacamp my love <3<3



