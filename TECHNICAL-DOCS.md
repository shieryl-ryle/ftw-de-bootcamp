# 📘 How to Write Foundational Data Engineering Documentation

This guide shows you how to document a **data engineering project** in a way that is both **practical** (anyone can run it) and **professional** (it looks like real-world DE work).

We’ll combine **hand-written docs** (for context, conventions, and how-tos) with **auto-generated docs** (dbt Docs, for lineage and metadata).

---

## 🏗️ Step 1 — Document the Architecture

Always start with a big-picture view: *what tools are in your stack, and how data flows through them*.

Example (our bootcamp stack):

```
dlt (ingestion) → raw (ClickHouse) → dbt transforms (clean, mart) → Metabase (dashboards)
```

Add a diagram or ASCII art. Make sure readers know:

* What’s **raw**, **clean**, and **mart**
* Which tool does what
* Where they should start if something breaks

---

## 📂 Step 2 — Document Your Sources

Even if dbt can “see” tables, define them in `sources.yml` so they show up in lineage.

```yaml
version: 2
sources:
  - name: raw
    schema: raw
    tables:
      - name: autompg___cars
        description: "Raw Auto MPG dataset ingested via dlt."
```

👉 Sources are where lineage begins. Without them, dbt Docs starts at your first model.

---

## 🧩 Step 3 — Document Your Models

Each model gets a description in a `schema.yml`.

```yaml
version: 2
models:
  - name: mpg_standardized
    description: "Cleaned Auto MPG with typed and standardized columns."
  - name: cylinders_by_origin
    description: "Aggregates avg cylinders by origin."
```

👉 This ensures your lineage graph is meaningful, not just SQL files linked together.

---

## 📝 Step 4 — Define Conventions

Set naming standards once, so everyone stays consistent:

* **Schemas**:

  * `raw` → ingested as-is
  * `clean` → standardized
  * `mart` → business-facing
* **Tables**: `snake_case`, descriptive
* **Teaching tip**: let each student use their own schema (`ftw_<alias>`)

---

## ✅ Step 5 — Add Data Quality Tests

Even one or two tests per model show that data should be *validated, not assumed*.

```yaml
columns:
  - name: mpg
    tests:
      - not_null
      - accepted_range:
          min: 0
          max: 100
```

---

## 🔗 Step 6 — Document Execution

Write down the exact commands so anyone can reproduce your work.

### Local workflow

```bash
# Ingest
docker compose --profile jobs run dlt python pipelines/dlt-mpg-pipeline.py

# Transform
docker compose --profile jobs run dbt run

# Test
docker compose --profile jobs run dbt test
```

### Generate and serve docs (one command)

```bash
docker compose --profile jobs run --rm \
  -w /workdir/transforms/01_mpg -p 8080:8080 \
  dbt docs generate --profiles-dir . --target local && \
  dbt docs serve --profiles-dir . --target local --host 0.0.0.0 --port 8080
```

* Open [http://localhost:8080](http://localhost:8080)
* Explore lineage, columns, sources, and tests in the interactive UI

### Generate static docs (shareable)

```bash
docker compose --profile jobs run --rm \
  -w /workdir/transforms/01_mpg \
  dbt docs generate --profiles-dir . --target local --static
```

This creates `target/index.html` — a single HTML file you can commit, email, or host (e.g., GitHub Pages, Netlify).

---

## 👥 Step 7 — Roles & Governance

For team projects, clarify responsibilities:

* **Data Engineers**: ingestion + cleaning
* **Analysts**: marts + dashboards
* **Students**: practice extending models, writing docs & tests

---

## 🚀 Step 8 — Onboarding Checklist

Always write a short “Getting Started”:

1. Clone the repo
2. Install Docker (use WSL2 on Windows)
3. Start services:

   ```bash
   docker compose --profile core up -d
   ```
4. Ingest, run dbt, serve docs
5. Open Metabase at [http://localhost:3001](http://localhost:3001)

---