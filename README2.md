
# FTW DE Bootcamp — Local & Remote Setup

This bootcamp uses a simple, reproducible ELT stack:

* **Extract/Load:** `dlt`
* **Warehouse:** ClickHouse
* **Transform:** `dbt`
* **BI:** Metabase

All services are defined in **one** `compose.yaml` and controlled by **profiles**:

* `core` = long-running (ClickHouse, Metabase, Chinook Postgres)
* `jobs` = one-shot (dlt, dbt)

> Students can run **all-in-one locally**, **or** run **dlt/dbt locally** against a **teacher-hosted** ClickHouse/Metabase.

```mermaid
flowchart LR
  SRC[(Datasets<br>APIs/Web)]
  DLT[dlt (jobs)]
  CH[(ClickHouse)]
  DBT[dbt (jobs)]
  META[Metabase (core)]
  SRC --> DLT --> CH
  CH --> DBT --> CH --> META
  classDef a fill:#eef6ff,stroke:#2b6cb0;
  class DLT,DBT a
```

---

## 0) Prerequisites

**Windows 10/11 (recommended path)**

* Enable virtualization in BIOS/UEFI
* Install **WSL2 + Ubuntu 22.04**:

  ```powershell
  wsl --install -d Ubuntu-22.04
  wsl --set-default-version 2
  ```
* Install **Docker Desktop** → Settings → **Use WSL 2 engine**, enable integration for Ubuntu-22.04
* In WSL:

  ```bash
  sudo apt update && sudo apt install -y git openssh-client
  git config --global core.autocrlf input   # avoid CRLF in scripts
  ```
* Clone the repo **inside WSL** (e.g., `~/projects/ftw-de-bootcamp`), not under `/mnt/c/...`

**macOS (Intel or Apple Silicon)**

* Install **Docker Desktop** (latest)
* Install **Git** (Xcode CLT or Homebrew)
* Apple Silicon: if an image complains about architecture, we already left a comment in `compose.yaml` to add `platform: linux/amd64` to that service.

---

## 1) Choose Your Mode (Edit `compose.yaml` only)

Open `compose.yaml` and find these **two blocks**. Switch between **LOCAL** and **REMOTE** by editing the commented lines only.

### A) dlt → ClickHouse destination

```yaml
  dlt:
    environment:
      # LOCAL (default): service name "clickhouse"
      # REMOTE: set to your SERVER public IP/DNS (e.g., "34.12.34.56")
      DESTINATION__CLICKHOUSE__CREDENTIALS__HOST:       "clickhouse"   # ← change for REMOTE
      DESTINATION__CLICKHOUSE__CREDENTIALS__PORT:       "9000"
      DESTINATION__CLICKHOUSE__CREDENTIALS__HTTP_PORT:  "8123"
      DESTINATION__CLICKHOUSE__CREDENTIALS__USERNAME:   "ftw_user"     # set by teacher on server
      DESTINATION__CLICKHOUSE__CREDENTIALS__PASSWORD:   "ftw_pass"     # set by teacher on server
      DESTINATION__CLICKHOUSE__CREDENTIALS__DATABASE:   "raw"
      DESTINATION__CLICKHOUSE__CREDENTIALS__SECURE:     "0"
```

### B) dbt target & credentials

```yaml
  dbt:
    environment:
      # DBT_TARGET choices live in ./dbt/profiles.yml (e.g., local / remote)
      DBT_TARGET: "local"                     # ← set to "remote" for REMOTE mode
      CH_HOST: "clickhouse"                   # ← change to "<SERVER_IP_OR_DNS>" for REMOTE
      CH_HTTP_PORT: "8123"
      CH_TCP_PORT:  "9000"
      CH_USER: "ftw_user"                     # set by teacher on server
      CH_PASS: "ftw_pass"                     # set by teacher on server
      DBT_SCHEMA: "default"                   # REMOTE: use "ftw_<student_alias>"
```

> **Why edit the YAML?** To keep onboarding simple—no shell exports. All students follow the same instructions.

---

## 2) Teacher/Admin — Server Setup

1. **Expose ports** on your server/security group (inbound):

   * **8123** (ClickHouse HTTP), **9000** (native TCP, optional if not needed externally), **3001** (Metabase)

2. **Start long-running services on the server**:

```bash
docker compose --compatibility up -d --profile core
```

3. **Sanity checks (on the server)**:

```bash
curl -s "http://localhost:8123" -d "SELECT version(), now();"
# Expect two columns (version, timestamp)

docker logs -f metabase | head -n 50   # Metabase warms up on first boot
```

4. **(Optional) Per-student isolation**

   * Provide each student a unique **DBT\_SCHEMA** like `ftw_alice01`.
   * You already ship `ftw_user.xml` for ClickHouse auth; if you maintain separate users/quotas, update that file accordingly.

---

## 3) Students — Run It

### Option A — **LOCAL all-in-one** (laptop)

```bash
# Start core services locally (ClickHouse, Metabase, Chinook Postgres)
docker compose --compatibility up -d --profile core

# Ingest (dlt)
docker compose --profile jobs run --rm dlt python pipelines/01-dlt-mpg-pipeline.py

# Transform (dbt)
docker compose --profile jobs run --rm dbt run
docker compose --profile jobs run --rm dbt test

# Open Metabase locally
# http://localhost:3001
```

### Option B — **REMOTE** (local dlt/dbt → teacher’s server)

* Ensure you edited `compose.yaml` (blocks above) to set:

  * `DBT_TARGET: "remote"`
  * `CH_HOST: "<SERVER_IP_OR_DNS>"`
  * `DBT_SCHEMA: "ftw_<your_alias>"`

Then run:

```bash
# Do NOT start core locally. Just run jobs:
docker compose --profile jobs run --rm dlt python pipelines/dlt-mpg-pipeline.py
docker compose --profile jobs run --rm dbt run
docker compose --profile jobs run --rm dbt test

# Metabase on the server:
# http://<SERVER_IP_OR_DNS>:3001
```

---

## 4) Quick Validation (Pass/Fail)

**ClickHouse responds**

```bash
curl -s "http://<CH_HOST>:8123" -d "SELECT 1;"
# Expect: 1
```

**Data arrived (Auto MPG)**

```bash
# LOCAL
docker compose exec clickhouse clickhouse-client --query "SELECT count() FROM auto_mpg___mpg_raw;"
# REMOTE (from your laptop using HTTP)
curl -s "http://<CH_HOST>:8123" -d "SELECT count() FROM ftw_<alias>.auto_mpg___mpg_raw;"
# Expect count() > 0
```

**dbt ran & tests passed**

```bash
docker compose --profile jobs run --rm dbt run
docker compose --profile jobs run --rm dbt test
# Expect: 0 failures (or whatever you ship intentionally)
```

**Metabase loads**

* Local: `http://localhost:3001`
* Remote: `http://<SERVER_IP_OR_DNS>:3001`
  Add the ClickHouse connection in the Metabase wizard if not preseeded:

```
Host: clickhouse (local) or <SERVER_IP_OR_DNS> (remote)
Port: 8123
User: ftw_user
Pass: ftw_pass
```

---

## 5) Daily Commands

| Goal                         | Command                                                                           |
| ---------------------------- | --------------------------------------------------------------------------------- |
| Start core (local or server) | `docker compose --compatibility up -d --profile core`                             |
| Run a dlt pipeline           | `docker compose --profile jobs run --rm dlt python pipelines/dlt-mpg-pipeline.py` |
| Run dbt models               | `docker compose --profile jobs run --rm dbt run`                                  |
| Run dbt tests                | `docker compose --profile jobs run --rm dbt test`                                 |
| See logs                     | `docker compose logs -f clickhouse` · `docker compose logs -f metabase`           |
| Stop all (keep data)         | `docker compose down`                                                             |
| Wipe data (careful)          | `docker compose down -v`                                                          |

---

## 6) OS Watch-outs

**Windows 10/11**

* Run commands in **WSL2 (Ubuntu)**, not PowerShell/CMD.
* Keep the repo inside WSL (e.g., `~/projects/...`) for performance & correct line endings.
* Allocate Docker Desktop **2–4 CPUs & 4–8 GB RAM**.
* If ports **8123/3001** are busy, stop the conflicting app or change the **left-hand** port in `compose.yaml`.

**macOS**

* First launch of Metabase can take \~1 minute; check `docker logs -f metabase`.
* On Apple Silicon, if a service fails due to architecture, add:

  ```yaml
  platform: linux/amd64
  ```

  to that service in `compose.yaml` (emulation is slower; use only if needed).

---

## 7) Troubleshooting

| Symptom                    | Likely cause                       | Fix                                                               |
| -------------------------- | ---------------------------------- | ----------------------------------------------------------------- |
| `curl :8123` fails         | Wrong host/port or server firewall | Verify `CH_HOST`, open ports 8123/3001 on server                  |
| `dbt debug` cannot connect | `DBT_TARGET` / creds mismatch      | Recheck `compose.yaml` dbt env block                              |
| dlt duplicates on rerun    | Missing/changed dlt state dir      | Keep `.dlt/` folder; define unique keys in dbt incremental models |
| Metabase keeps restarting  | First-run warmup or low memory     | Wait 60–90s; increase Docker memory                               |
| Scripts failing on Windows | CRLF line endings                  | `git config --global core.autocrlf input` and reclone if needed   |

---

## 8) What’s Included (repo sketch)

```
ftw-de-bootcamp/
├── compose.yaml
├── clickhouse/
│   ├── initdb/                      # optional bootstrap SQL
│   └── users.d/ftw_user.xml         # ClickHouse user/roles
├── dbt/
│   ├── profiles.yml                 # has 'local' & 'remote' targets
│   ├── models/...
│   └── Dockerfile
├── dlt/
│   ├── pipelines/dlt-mpg-pipeline.py
│   ├── requirements.txt
│   └── Dockerfile
└── postgres/
    └── initdb/                      # loads Chinook sample
```

---

### That’s it!

* **Edit two small env blocks** in `compose.yaml` to switch modes.
* Use the same `docker compose` commands on **Windows (WSL2)** and **macOS**.
* For class, teacher runs only `core` on the server; students run `jobs` locally pointing to the server.
