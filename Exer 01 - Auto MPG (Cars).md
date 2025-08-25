# Exercise 01 — Auto MPG (Cars)

**Goal:**
Ingest the Auto MPG dataset with **dlt** → land in **ClickHouse** (`raw.autompg___cars`) → build a simple **dbt** model → verify the result → (optionally) explore in DBeaver / Metabase.
# https://archive.ics.uci.edu/dataset/9/auto+mpg

## 0) Start core services

```bash
# Start ClickHouse, Metabase, Chinook PG
docker compose --profile core --compatibility up -d
```

## 1) Quick sanity checks (ClickHouse is up)

```bash
docker compose exec clickhouse clickhouse-client --query "SELECT now();"
docker compose exec clickhouse clickhouse-client --query "SHOW DATABASES;"
docker compose exec clickhouse clickhouse-client --query "SELECT database,name FROM system.tables WHERE name LIKE 'autompg%' ORDER BY database,name;"
```

## 2) Build the dlt image (first time only)

```bash
docker compose build dlt
```

## 3) Ingest Auto MPG with dlt

```bash
docker compose --profile jobs run --rm dlt \
  python extract-loads/dlt-mpg-pipeline.py
```

## 4) Verify raw data landed

```bash
docker compose exec clickhouse \
  clickhouse-client --query "SELECT * FROM raw.autompg___cars LIMIT 10;"
```

## 5) Build the dbt exercise (01\_mpg)

> Assumes these files exist:
>
> * `dbt/transforms/01_mpg/dbt_project.yml` (profile name matches your local `profiles.yml`)
> * `dbt/transforms/01_mpg/profiles.yml` (target **local**, `schema: clean`)
> * `dbt/transforms/01_mpg/models/sources.yml` (source **raw\.autompg\_\_\_cars**)
> * `dbt/transforms/01_mpg/models/cylinders_by_origin.sql` (uses `{{ source('raw','autompg___cars') }}`)

```bash
docker compose --profile jobs run --rm \
  -w /workdir/transforms/01_mpg \
  dbt build --profiles-dir . --target local
```

## 6) Verify the model output

```bash
# The model is a VIEW/TABLE in the database specified by your profiles.yml (e.g., "clean")
docker compose exec clickhouse \
  clickhouse-client --query "SELECT * FROM clean.cylinders_by_origin ORDER BY origin;"
```

> If you instead configured `schema: mart` in the exercise’s `profiles.yml`, query:
>
> ```bash
> docker compose exec clickhouse \
>   clickhouse-client --query "SELECT * FROM mart.cylinders_by_origin;"
> ```

## 7) (Optional) Validate in DBeaver

* Create a **ClickHouse** connection:

  * Host: `localhost` (or your server IP)
  * Port: `8123`
  * User: `ftw_user` (or `default`)
  * Password: `ftw_pass` (or empty if using `default`)
* Run:

  ```sql
  SELECT * FROM raw.autompg___cars LIMIT 10;
  SELECT * FROM clean.cylinders_by_origin;
  ```

## 8) (Optional) Configure Metabase

* Open `http://localhost:3001` (or `http://<server>:3001`)
* Add ClickHouse:

  ```
  Host: clickhouse (or server IP)  •  Port: 8123
  User: ftw_user  •  Pass: ftw_pass  •  SSL: off
  ```
* Build a quick bar chart: **avg\_cyl by origin** from `clean.cylinders_by_origin`.

## 9) Stop core services (keep data)

```bash
docker compose --profile core stop
```

---

### Common gotchas & quick fixes

* **“source not found” in dbt**
  Ensure `sources.yml` lives under `dbt/transforms/01_mpg/models/` and uses:

  ```yaml
  sources:
    - name: raw
      schema: raw
      tables:
        - name: autompg___cars
  ```

  and your model references `{{ source('raw','autompg___cars') }}`.

* **dbt profile/target mismatch**
  If you see “profile … doesn’t have a target named local”, either:

  * run with `--target default`, or
  * set `target: local` and define an `outputs.local:` block in `profiles.yml`.

* **Auth errors to ClickHouse (ftw\_user)**
  Temporarily switch to the built-in `default` user (no password) in your dlt/dbt config, or ensure `ftw_user` exists and matches the password in `clickhouse/users.d/ftw_user.xml`, then `docker compose restart clickhouse`.
