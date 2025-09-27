# Student Information DLT Pipeline

## Overview
This pipeline loads student information data from `studentInfo.csv` into ClickHouse using DLT (Data Loading Tool).

## Files
- **Pipeline**: `dlt/extract-loads/Grp2-dlt-student-pipeline.py`
- **Data**: `data/studentInfo.csv` 
- **Config**: `compose.yaml` (DLT service configuration)

## Data Summary
- **Records**: 32,593 student records
- **Columns**: 12 columns including:
  - `code_module`, `code_presentation`, `id_student`
  - `gender`, `region`, `highest_education`
  - `imd_band`, `age_band`, `num_of_prev_attempts`
  - `studied_credits`, `disability`, `final_result`

## How to Run

### Method 1: Docker Compose (Recommended)
```bash
# Start ClickHouse and other services
docker compose --profile core up -d

# Run the DLT pipeline
docker compose --profile jobs run --rm dlt python extract-loads/Grp2-dlt-student-pipeline.py
```

### Method 2: Local Testing
```bash
# Run the demo script to verify data processing
python3 run_student_pipeline_local.py
```

## Pipeline Features
- ✅ Reads CSV data from mounted `/data` directory
- ✅ Cleans column names for ClickHouse compatibility
- ✅ Handles missing values by filling with empty strings
- ✅ Uses `write_disposition="replace"` to overwrite data
- ✅ Loads into `raw` dataset in ClickHouse
- ✅ Processes 32,593 student records successfully

## Configuration
The pipeline is configured to:
- Connect to ClickHouse (local or remote based on `compose.yaml` settings)
- Load data into `raw.grp2_studentinfo` table
- Replace existing data on each run

## Troubleshooting
- Ensure ClickHouse is running: `docker ps | grep clickhouse`
- Check ClickHouse health: `docker logs clickhouse`
- Verify data file exists: `ls -la data/studentInfo.csv`
- Test data processing: `python3 run_student_pipeline_local.py`

## Data Sample
```
code_module: AAA
code_presentation: 2013J
id_student: 11391
gender: M
region: East Anglian Region
highest_education: HE Qualification
imd_band: 90-100%
age_band: 55<=
num_of_prev_attempts: 0
studied_credits: 240
disability: N
final_result: Pass
```