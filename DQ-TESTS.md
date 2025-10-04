# 🚀 FTW Data Engineering Bootcamp – Auto MPG Pipeline (dbt)

This module demonstrates an end-to-end mini data pipeline using **dlt**, **ClickHouse**, and **dbt** with the [Auto MPG dataset](https://archive.ics.uci.edu/dataset/9/auto+mpg).

It includes:

* A `clean` layer (typed, standardized)
* A `mart` layer (aggregated cylinders by origin)
* dbt **tests** (structural + semantic)
* dbt **docs** (static HTML site)

---

## 📂 Folder Structure

```
ftw-de-bootcamp/
└── dbt/
    └── transforms/
        └── 01_mpg/
            ├── models/
            │   ├── clean/
            │   │   └── schema.yml
            │   └── mart/
            │       └── schema.yml
            ├── target/              # dbt docs output (after generation)
            └── ...
```

---

## 🧪 Running dbt Tests

### Clean (structural tests)

* Validate not-null constraints, accepted values, and row count consistency.
* Defined in: `models/clean/schema.yml`

### Mart (semantic tests)

* Validate aggregated results are within expected ranges.
* Defined in: `models/mart/schema.yml`

**Run tests:**

```bash
docker compose --profile jobs run --rm \
  -w /workdir/transforms/01_mpg \
  dbt test --profiles-dir . --target local
```

---

## ⚙️ Execute Models & Run Pipeline

Build all models (`staging` → `clean` → `mart`) in this module:

```bash
docker compose --profile jobs run --rm \
  -w /workdir/transforms/01_mpg \
  dbt build --profiles-dir . --target local
```

---

## 📖 Generate Documentation

Generate static HTML documentation for this dbt project:

```bash
docker compose --profile jobs run --rm \
  -w /workdir/transforms/01_mpg \
  dbt docs generate --profiles-dir . --target local --static
```

Open the docs locally:

```
ftw-de-bootcamp/dbt/transforms/01_mpg/target/index.html
```

---

## ✅ Summary

* **Tests:** run `dbt test` for data quality checks
* **Build:** run `dbt build` to execute models
* **Docs:** run `dbt docs generate` and open `target/index.html`

