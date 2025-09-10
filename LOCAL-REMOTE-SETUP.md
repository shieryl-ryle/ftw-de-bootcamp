# 🚀 Running the Bootcamp Environment

## Option 1: Fully Local (everything on your laptop)

**What runs locally:** ClickHouse, PostgreSQL (Chinook), Metabase, dlt, dbt.

1. **Start the core stack**

   ```bash
   docker compose --compatibility up -d --profile core
   ```

   This launches:

   * ClickHouse (`localhost:8123`, `localhost:9000`)
   * PostgreSQL Chinook (`localhost:5432`)
   * Metabase (`http://localhost:3001`)

2. **Verify services are healthy**

   * `docker ps` should show `clickhouse`, `chinook_postgres`, and `metabase` as running.
   * Health checks:

     ```bash
     docker logs clickhouse | tail -n 20
     docker logs chinook_postgres | tail -n 20
     ```

3. **Run a dlt pipeline**
   Example (Auto MPG pipeline):

   ```bash
   docker compose --profile jobs run --rm dlt python pipelines/dlt-mpg-pipeline.py
   ```

4. **Run dbt transformations/tests**

   ```bash
   docker compose --profile jobs run --rm dbt run
   docker compose --profile jobs run --rm dbt test
   ```

5. **Explore in Metabase**
   Open [http://localhost:3001](http://localhost:3001).
   Add a new database connection → ClickHouse → use:

   * Host: `clickhouse`
   * Port: `8123`
   * User: `ftw_user`
   * Pass: `ftw_pass`
   * DB: `raw` / `clean` / `mart` (as needed)

---

## Option 2: Remote Hybrid (server runs core; students run jobs)

**What runs where:**

* **Server (AWS VPS, e.g. Ubuntu 22.04)**: ClickHouse, PostgreSQL (Chinook), Metabase
* **Student laptops**: only dlt + dbt jobs (no ClickHouse/Metabase containers)

---

### 1. On the Server (teacher side)

1. **Open ports in firewall/security group**

   * TCP `8123` (ClickHouse HTTP)
   * TCP `9000` (ClickHouse native)
   * TCP `3001` (Metabase web)

2. **Start only core services**

   ```bash
   docker compose --compatibility up -d --profile core
   ```

3. **Check health**

   ```bash
   docker ps
   curl http://localhost:8123/ping
   ```

4. **Verify Metabase**
   Visit `http://<SERVER_IP>:3001` in your browser.
   Teacher can pre-create a Metabase account & connect ClickHouse.

---

### 2. On Student Laptops

1. **Do NOT start core**
   Students only run jobs (`dlt` / `dbt`).

2. **Edit env configs**
   In `compose.yaml` (or export via `.env` overrides):

   ```yaml
   # For dlt
   DESTINATION__CLICKHOUSE__CREDENTIALS__HOST: "<SERVER_IP>"
   DESTINATION__CLICKHOUSE__CREDENTIALS__PORT: "9000"
   DESTINATION__CLICKHOUSE__CREDENTIALS__HTTP_PORT: "8123"
   DESTINATION__CLICKHOUSE__CREDENTIALS__USERNAME: "ftw_user"
   DESTINATION__CLICKHOUSE__CREDENTIALS__PASSWORD: "ftw_pass"
   DESTINATION__CLICKHOUSE__CREDENTIALS__DATABASE: "raw"

   # For dbt
   CH_HOST: "<SERVER_IP>"
   CH_HTTP_PORT: "8123"
   CH_TCP_PORT: "9000"
   CH_USER: "ftw_user"
   CH_PASS: "ftw_pass"
   DBT_SCHEMA: "ftw_<student_alias>"   # 👈 IMPORTANT! unique per student
   ```

3. **Run dlt job**

   ```bash
   docker compose --profile jobs run --rm dlt python pipelines/dlt-mpg-pipeline.py
   ```

4. **Run dbt (remote target)**
   Update `profiles.yaml` to point to the server:

   ```yaml
   clickhouse_ftw:
     target: remote
     outputs:
       remote:
         type: clickhouse
         host: <SERVER_IP>
         port: 8123
         user: ftw_user
         password: ftw_pass
         schema: ftw_<student_alias>
   ```

   Then run:

   ```bash
   docker compose --profile jobs run --rm dbt run
   docker compose --profile jobs run --rm dbt test
   ```

5. **Check results in Metabase**
   Students access: `http://<SERVER_IP>:3001`.

---

✅ **Summary**

* **Local mode:** everything (ClickHouse, Postgres, Metabase, dlt, dbt) runs on your laptop.
* **Remote hybrid:** teacher runs core on server, students point dlt/dbt jobs to server IP.
* **Isolation:** each student must use their own `DBT_SCHEMA` (e.g., `ftw_myk01`).

 