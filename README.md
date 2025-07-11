# FTW DE BOOTCAMP

The [For the Women Foundation](https://www.ftwfoundation.org/) Data Engineering Bootcamp delivers six Saturdays of hands-on ELT for 30 scholars. This repo jump-starts your environment so you can focus on concepts and code.

**Bootcamp 6-Week Timeline**
*All sessions are Saturdays, each with a morning lecture (3 hrs) and afternoon lab (3–4 hrs).*

|  Week | Focus                              | Morning Lecture                         | Afternoon Lab                                    |
| :---: | ---------------------------------- | --------------------------------------- | ------------------------------------------------ |
| **1** | Platform & ELT Foundations         | Docker Compose, ClickHouse & dlt basics | Load MovieLens, build dim/fact tables & chart    |
| **2** | SQL Transformations & Modeling     | dbt structure, star schemas, joins      | Ingest NYC Taxi, staging + revenue mart & trends |
| **3** | Incrementals, Streaming & Testing  | dlt incremental/streaming, testing      | NOAA weather stream + station joins & dashboard  |
| **4** | Data Quality & Cleaning Messy Data | SQL cleaning patterns, dbt tests        | Ingest 311 complaints, clean, mart + pulse       |
| **5** | Capstone Kickoff & Pipeline Build  | Capstone briefing & design              | Scaffold dlt + initial dbt staging (team work)   |
| **6** | Capstone Finish & Presentations    | Finalize models, docs & CI              | Build dashboards, pulse; team demos & wrap-up    |

Note: This outline is still in development and is subject to change.

---

## 🚀 Quick Start

1. **Provision** an Ubuntu 22.04 VPS (or local VM)  
2. **Install Docker & Compose**, clone this repo, and connect via VS Code Remote-SSH  
3. **Build** custom images:  
   ```bash
   docker compose build dlt dbt
```

4. **Run** extract & transform:

   ```bash
   docker compose --profile jobs up dlt dbt
   ```
5. **Open** Metabase at `http://localhost:3001`, add the pre-seeded ClickHouse connection, and start charting.

Everything is containerized, reproducible, and CI-ready—perfect for rapid learning and real-world practice.

---

## 🔄 Pipeline Overview

```mermaid
flowchart LR
  subgraph Extract-Load
    direction LR
    SRC[(External<br>data sources)]
    DLT[dlt&nbsp;container]
    SRC --> DLT
    DLT -->|raw tables| CH[(ClickHouse)]
  end
  subgraph Transform
    direction LR
    DBT[dbt&nbsp;container]
    CH --> DBT
    DBT -->|views / tables| CH
  end
  subgraph Visualise
    direction LR
    CH --> META[Metabase UI]
  end

  classDef box fill:#d6eaf8,stroke:#036,stroke-width:1px,color:#000;
  class SRC,DLT,DBT,META box;
  style CH fill:#fde9b4,stroke:#663,stroke-width:2px,color:#000
```

> **Note:** In production you’d add a data lake (e.g. S3/Delta Lake), data catalog (Amundsen/DataHub), security/Governance (RBAC, encryption, Ranger), orchestration (Airflow/Kubernetes), observability (Prometheus/Grafana), and data quality (Great Expectations). We’ve omitted those to focus on core ELT.

Above all, this bootcamp emphasizes **SQL** with only minimal Python, YAML, and Markdown.

---

## 📊 Server Utilization

> On a server with **15.6 GiB RAM** & a modern multi-core CPU:

### 1. Image Footprint

| Image                          | Tag    |   Size |
| ------------------------------ | ------ | -----: |
| `de-bootcamp-template-dbt`     | latest | 169 MB |
| `de-bootcamp-template-dlt`     | latest | 556 MB |
| `metabase/metabase`            | latest | 864 MB |
| `clickhouse/clickhouse-server` | 23.12  |   1 GB |

> **Total:** ≈ 2.6 GB of images

### 2. Runtime Usage

| Container      |  CPU | Memory             |
| -------------- | :--: | ------------------ |
| **metabase**   | 5.7% | 914 MiB / 15.6 GiB |
| **clickhouse** | 0.6% | 168 MiB / 15.6 GiB |

---

## 🛠 Setup Instructions

To keep all work within a consistent namespace, replace all 'myk' phrases with a unique name.

### A. Provision & Harden the Server

| Step                    | Command / Action                                                                                                         | Notes                           |
| ----------------------- | ------------------------------------------------------------------------------------------------------------------------ | ------------------------------- |
| **A-1. Create VM/VPS**  | Choose Ubuntu 22.04 LTS, 2 vCPU, 4 GB RAM+, open ports 22, 8123, 9000, 3001 (or use SSH tunnel)                          |                                 |
| **A-2. Add admin user** | `bash sudo adduser myk && sudo usermod -aG sudo myk `                                                                    | Don’t use `root` for daily work |
| **A-3. Harden SSH**     | `bash sudo apt update && sudo apt install -y openssh-server git`<br/>Edit `/etc/ssh/sshd_config`: disable password auth… |                                 |
| **A-4. Copy SSH key**   | On **local** machine: `ssh-copy-id myk@<VPS_IP>` or paste into `~/.ssh/authorized_keys`                                  |                                 |

---

### B. Install Docker & Compose

```bash
sudo apt update
sudo apt install -y ca-certificates curl gnupg
sudo install -m0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
  | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
   https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" \
  | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
sudo usermod -aG docker myk   # allow Docker without sudo
newgrp docker                # refresh group
docker version               # verify installation
```

---

### C. VS Code Remote-SSH

1. Install the **Remote – SSH** extension in VS Code.
2. Add to your local `~/.ssh/config`:

   ```sshconfig
   Host ftw-vps
     HostName   <VPS_IP>
     User       myk
     Port       22
     IdentityFile ~/.ssh/id_ed25519
   ```
3. In VS Code: **Remote-SSH: Connect to Host… → ftw-vps**.

---

### D. Clone & Push the Repo

```bash
cd ~
git clone https://github.com/ogbinar/ftw-de-bootcamp.git ftw-de-bootcamp-myk
cd ftw-de-bootcamp-myk

# Point to your GitHub
git remote rename origin upstream
git remote add origin git@github.com:<your_user>/ftw-de-bootcamp.git
git branch -M main

# Tweak compose.yaml / .env if needed
git add .
git commit -m "FTW DE bootcamp setup"
git push -u origin main
```

**Directory structure:**

```text
ftw-de-bootcamp/
├── clickhouse/
│   └── users.d/
│       └── ftw_user.xml
├── compose.yaml
├── dbt/
│   ├── dbt_project.yml
│   ├── Dockerfile
│   ├── models/
│   │   ├── cylinders_by_origin.sql
│   │   └── sources.yml
│   └── profiles.yml
├── dlt/
│   ├── clickhouse.yaml
│   ├── Dockerfile
│   ├── pipeline.py
│   └── requirements.txt
└── README.md
```

---

### E. First Run

```bash
# Build images
docker compose -p myk build dlt dbt

# Start stateful services
docker compose -p myk up -d clickhouse --remove-orphans
docker compose -p myk up -d metabase --remove-orphans

# Quick ClickHouse sanity check
docker compose -p myk exec clickhouse \
  clickhouse-client --query="SELECT now();"

# Run extract 
docker compose -p myk --profile jobs run --rm dlt   python pipelines/mpg_pipeline.py

# Verify raw data
docker compose -p myk exec clickhouse \
  clickhouse-client --query="SELECT count() FROM auto_mpg___mpg_raw;"


# Run transform
docker compose -p myk --profile jobs run --rm dbt \
  run --models cylinders_by_origin

# Verify model
docker compose -p myk exec clickhouse \
  clickhouse-client --query="SELECT count() FROM cylinders_by_origin;"
```

> If ports 8123/3001 are firewall-blocked, use VS Code port forwarding.

---

### F. DBeaver (Optional)

1. Install DBeaver locally.
2. Create a **ClickHouse** connection:

   > Host: `clickhouse` Port: `8123` Database: `default`
   > User: `ftw_user` Password: `ftw_pass`
3. Run:

   ```sql
   SELECT count() FROM cylinders_by_origin;
   ```

---

### G. Metabase Setup (One-time)

1. Visit **[http://localhost:3001](http://localhost:3001)** (or forwarded port).
2. Complete the wizard, choose **ClickHouse**, enter:

   ```
   clickhouse:8123  •  ftw_user  •  ftw_pass  •  SSL: off
   ```
3. Build a bar chart of **avg\_cyl by origin** and save to **Cars Demo**.

---

## 🔄 Daily Usage

| Goal                          | Command                                    |
| ----------------------------- | ------------------------------------------ |
| **Start services**            | `docker compose -p myk up -d clickhouse metabase` |
| **Run full ELT**              | `docker compose -p myk --profile jobs up dlt dbt` |
| **Tail dlt logs**             | `docker compose -p myk  logs -f dlt`               |
| **Stop all (keep data)**      | `docker compose -p myk down -v`                      |
| **Hard reset (drop volumes)** | `./scripts/reset.sh`                       |

---

## 📝 TODO

* Add cron instructions for recurring jobs
* Develop lecture slides, exercises & assignments

---

You’re all set—edit `dlt/pipeline.py` or any dbt model, re-run the jobs, refresh Metabase, and watch new insights appear!
