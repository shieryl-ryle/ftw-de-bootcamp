# OULAD Dataset - Group 2 Complete Data Pipeline Documentation

## Overview
This document explains the complete data pipeline we built for the OULAD (Open University Learning Analytics Dataset) for Group 2, from raw CSV files to analytical insights using modern data engineering tools.

## Table of Contents
1. [Data Pipeline Architecture](#data-pipeline-architecture)
2. [Phase 1: Data Ingestion (DLT)](#phase-1-data-ingestion-dlt)
3. [Phase 2: Data Transformation (dbt)](#phase-2-data-transformation-dbt)
4. [Phase 3: Analytics Layer](#phase-3-analytics-layer)
5. [Final Results](#final-results)
6. [How to Run the Pipeline](#how-to-run-the-pipeline)
7. [Troubleshooting](#troubleshooting)

---

## Data Pipeline Architecture

```
📁 CSV Files (Raw Data)
    ↓
🔄 DLT Pipeline (Data Loading Tool)
    ↓
🗄️ ClickHouse Raw Schema (grp2_oulad___*)
    ↓
🔧 dbt Transformations (Data Build Tool)
    ↓
📊 ClickHouse Clean Schema (grp2_*_clean)
    ↓
🏢 ClickHouse Mart Schema (grp2_dim_*, grp2_fact_*, grp2_*_analysis)
    ↓
📈 Analytics & Visualizations
```

**Tools Used:**
- **DLT (Data Loading Tool)**: Ingests CSV files into database
- **dbt (Data Build Tool)**: Transforms raw data into clean, analytical tables
- **ClickHouse**: Data warehouse database
- **DBeaver**: Database GUI for viewing results

---

## Phase 1: Data Ingestion (DLT)

### 1.1 What We Had
Raw CSV files in the staging directory:
- `assessments.csv` - Course assessment information
- `courses.csv` - Course module details
- `studentAssessment.csv` - Student assessment results
- `studentInfo.csv` - Student demographic data
- `studentRegistration.csv` - Student enrollment data
- `studentVle.csv` - Student VLE interaction data
- `vle.csv` - VLE content and activities

### 1.2 What We Did
Created `Grp2-dlt-student-pipeline.py` with multiple approaches for loading data:

```python
# Approach 1: Single resource (all files in one table)
# Approach 2: Separate resources (each file gets its own table) ← We used this
# Approach 3: Dynamic discovery (automatically find CSV files)
```

### 1.3 DLT Pipeline Configuration
- **Pipeline Name**: `oulad-pipeline`
- **Destination**: ClickHouse database
- **Dataset Name**: `GRP2_OULAD`
- **Schema**: `raw`

### 1.4 Tables Created in Raw Schema
After running DLT, these tables were created:
```
raw/
├── grp2_oulad___assessments
├── grp2_oulad___courses  
├── grp2_oulad___student_assessment
├── grp2_oulad___student_info
├── grp2_oulad___student_registration
├── grp2_oulad___vle
└── studentVle (different naming pattern)
```

### 1.5 How to Run DLT
```bash
# Navigate to DLT directory
cd /home/ishi/ftw-de-bootcamp/dlt/extract-loads

# Run the pipeline
python Grp2-dlt-student-pipeline.py
```

---

## Phase 2: Data Transformation (dbt)

### 2.1 Why dbt?
- **Problem**: Raw data has inconsistencies, missing values, and isn't analysis-ready
- **Solution**: dbt transforms raw data into clean, standardized tables
- **Benefits**: 
  - Version control for SQL transformations
  - Automatic dependency management
  - Documentation generation
  - Testing capabilities

### 2.2 dbt Project Structure
```
08_student/
├── dbt_project.yml          # Project configuration
├── models/
│   ├── sources.yml          # Define raw data sources
│   ├── clean/               # Clean layer models
│   │   ├── assessments_clean.sql
│   │   ├── courses_clean.sql
│   │   ├── student_assessment_clean.sql
│   │   ├── student_info_clean.sql
│   │   ├── student_registration_clean.sql
│   │   ├── student_vle_clean.sql
│   │   └── vle_clean.sql
│   └── mart/                # Analytics layer models
│       ├── student_journey_complete.sql
│       ├── student_engagement_analysis.sql
│       ├── module_performance_analysis.sql
│       ├── vle_content_analysis.sql
│       └── student_performance_by_demographics.sql
└── macros/
    └── generate_schema_name.sql  # Schema naming logic
```

### 2.3 Clean Layer Transformations

#### What Each Clean Model Does:

**assessments_clean.sql**
- Removes `?` values and converts to proper data types
- Standardizes assessment types (TMA → Tutor Marked Assignment)
- Categorizes assessments by weight (High/Medium/Low Weight)
- Creates composite keys for joining

**courses_clean.sql**  
- Cleans course duration data
- Extracts year and period from presentation codes
- Categorizes course length (Short/Medium/Long Course)

**student_info_clean.sql**
- Standardizes gender values (M → Male, F → Female)
- Cleans demographic fields (region, education, age bands)
- Converts disability flags to readable format (Y → Yes, N → No)
- Creates result categories

**student_registration_clean.sql**
- Converts registration/unregistration dates
- Creates registration status (Active/Unregistered)
- Builds student-course composite keys

**student_vle_clean.sql**
- Cleans click interaction data
- Categorizes engagement levels based on clicks
- Creates interaction tracking keys

**vle_clean.sql**
- Cleans VLE content metadata
- Categorizes activities by type
- Manages week availability windows

### 2.4 Mart Layer Analytics

#### What Each Mart Model Provides:

**student_journey_complete.sql**
- **Purpose**: 360° view of each student's learning journey
- **Combines**: Student info + Course details + Registrations + Assessments + VLE engagement
- **Insights**: Complete student lifecycle from enrollment to outcome

**student_engagement_analysis.sql**
- **Purpose**: VLE engagement patterns and outcomes
- **Metrics**: Total clicks, active days, engagement categories
- **Insights**: How VLE usage correlates with success

**module_performance_analysis.sql**
- **Purpose**: Course-level performance metrics
- **Metrics**: Pass rates, average scores, completion rates
- **Insights**: Which courses are most/least successful

**vle_content_analysis.sql**
- **Purpose**: Content effectiveness analysis
- **Metrics**: Click patterns, popular activities, engagement by content type
- **Insights**: Which VLE materials are most engaging

**student_performance_by_demographics.sql**
- **Purpose**: Demographic performance analysis
- **Metrics**: Success rates by gender, age, region, education level
- **Insights**: Identify demographic patterns in student success

### 2.5 dbt Configuration Details

**Schema Strategy:**
- Raw data: `raw` schema (grp2_oulad___*)
- Clean tables: `clean` schema (grp2_*_clean) 
- Dimensional models: `mart` schema (grp2_dim_*, grp2_fact_*)
- Analytics views: `mart` schema (grp2_*_analysis)

**Materialization Strategy:**
- Clean layer: `table` (materialized for fast queries)
- Mart layer: `view` (dynamic, always up-to-date)

**Naming Convention:**
- All Group 2 objects prefixed with `grp2_`
- Clean tables: `grp2_[entity]_clean`
- Mart views: `grp2_[analysis_name]`

### 2.6 How to Run dbt
```bash
# Navigate to dbt project
cd /home/ishi/ftw-de-bootcamp/dbt/transforms/08_student

# Run all models
docker compose --profile jobs run --rm -w /workdir/transforms/08_student dbt build --profiles-dir . --target remote

# Run specific layer
dbt run --models clean.*    # Only clean models
dbt run --models mart.*     # Only mart models
```

---

## Phase 3: Analytics Layer

### 3.1 What We Achieved
After running the complete pipeline, we have:

**Production Clean Schema (11 tables)**
```
clean.grp2_assessments_clean
clean.grp2_courses_clean
clean.grp2_student_assessment_clean
clean.grp2_student_demographics_clean
clean.grp2_student_info_clean
clean.grp2_student_registration_clean
clean.grp2_student_vle_clean
clean.grp2_vle_engagement_clean
clean.grp2_assessment_performance_clean
clean.grp2_vle_clean
clean.grp2_student_data_clean
```

**Production Mart Schema (Analytics + Dimensional Models)**
```
mart.grp2_demographics_dropout_analysis
mart.grp2_dim_student
mart.grp2_dim_course  
mart.grp2_dim_assessment
mart.grp2_fact_student_assessments
mart.grp2_fact_vle_interactions
```

### 3.2 Key Data Quality Improvements
- **Null Handling**: Converted `?` values to proper NULLs
- **Data Type Consistency**: Proper integers, strings, and dates
- **Standardization**: Consistent naming and categorization
- **Enrichment**: Added calculated fields and categories
- **Relationships**: Created proper join keys between tables

---

## Final Results

### What You Can Now Do:

1. **Student Analysis**: Query complete student journeys from enrollment to completion
2. **Course Effectiveness**: Analyze which courses have best outcomes
3. **Engagement Patterns**: Understand how VLE usage affects success
4. **Demographic Insights**: Identify success patterns by student characteristics
5. **Content Optimization**: See which VLE materials are most effective

### Sample Queries:

```sql
-- Top performing students by engagement
SELECT student_id, final_result, total_vle_clicks, engagement_level
FROM sandbox.grp2_student_journey_complete 
WHERE final_result IN ('Pass', 'Distinction')
ORDER BY total_vle_clicks DESC;

-- Course success rates
SELECT code_module, 
       COUNT(*) as total_students,
       AVG(avg_assessment_score) as avg_score
FROM sandbox.grp2_student_journey_complete
GROUP BY code_module
ORDER BY avg_score DESC;

-- Engagement vs Outcome analysis
SELECT engagement_level, 
       outcome_category,
       COUNT(*) as student_count
FROM sandbox.grp2_student_journey_complete
GROUP BY engagement_level, outcome_category;
```

---

## How to Run the Complete Pipeline

### Prerequisites
- Docker environment set up
- ClickHouse database access
- CSV files in staging directory

### Step-by-Step Process

1. **Ingest Raw Data (DLT)**
```bash
cd /home/ishi/ftw-de-bootcamp/dlt/extract-loads
python Grp2-dlt-student-pipeline.py
```

2. **Transform Data (dbt)**
```bash
cd /home/ishi/ftw-de-bootcamp/dbt/transforms/08_student
docker compose --profile jobs run --rm -w /workdir/transforms/08_student dbt build --profiles-dir . --target remote
```

3. **Verify Results**
- Open DBeaver
- Connect to ClickHouse
- Navigate to `sandbox` schema
- See all `grp2_*` tables and views

---

## Troubleshooting

### Common Issues and Solutions

**Issue**: DLT table naming mismatches
- **Solution**: Check actual table names in DBeaver and update `sources.yml`

**Issue**: dbt schema permission errors
- **Solution**: Use `sandbox` schema instead of `clean`/`mart`

**Issue**: Column not found errors  
- **Solution**: Check clean model column names match what's used in mart models

**Issue**: Missing VLE table
- **Solution**: Ensure `vle()` function is included in DLT pipeline run

### Key Files Modified
- `dbt_project.yml`: Schema configuration
- `sources.yml`: Raw table definitions  
- `generate_schema_name.sql`: Schema naming logic
- All model files: Group naming and schema settings

---

---

## Phase 4: Data Normalization (Dimensional Modeling)

### 4.1 Why Normalize?
After proving our pipeline works in sandbox, we need to create a properly normalized dimensional model:
- **Fact Tables**: Store measurable events (assessments, VLE interactions)
- **Dimension Tables**: Store descriptive attributes (students, courses, time)
- **Benefits**: Reduced redundancy, improved performance, standard analytics patterns

### 4.2 Proposed Dimensional Model

#### Dimension Tables:
```sql
-- Student Dimension
dim_student (student_id, gender, region, age_band, education_level, has_disability)

-- Course Dimension  
dim_course (course_id, code_module, code_presentation, course_length, presentation_year)

-- Assessment Dimension
dim_assessment (assessment_id, assessment_type, weight, date)

-- VLE Content Dimension
dim_vle_content (site_id, activity_type, week_from, week_to)

-- Date Dimension
dim_date (date_id, date, year, month, week, day_of_week)
```

#### Fact Tables:
```sql
-- Student Assessment Facts
fact_student_assessment (student_id, assessment_id, course_id, score, submission_date, is_banked)

-- VLE Interaction Facts  
fact_vle_interactions (student_id, site_id, course_id, date_id, sum_clicks)

-- Student Registration Facts
fact_registrations (student_id, course_id, registration_date, unregistration_date, final_result)
```

### 4.3 Next Steps
1. Create normalized dimension and fact models in dbt
2. Use proper schema (not sandbox)
3. Implement slowly changing dimensions (SCD) where needed
4. Create data marts on top of dimensional model

---

## Summary

We built a complete modern data pipeline that:
1. **Ingests** CSV files into a data warehouse using DLT
2. **Transforms** raw data into clean, analysis-ready tables using dbt
3. **Creates** dimensional models (facts and dimensions) for analytics
4. **Provides** business analytics answering key questions about student success
5. **Ensures** data quality and consistency throughout
6. **Uses** production schemas (clean/mart) with proper separation of concerns
7. **Delivers** actionable insights on demographic dropout patterns

This pipeline follows data engineering best practices and provides a production-ready foundation for analytics and visualization work.

## Final Production Results

**✅ Production Deployment Complete:**
- **Raw Schema**: 7 tables (grp2_oulad___*)
- **Clean Schema**: 11 clean tables (grp2_*_clean)  
- **Mart Schema**: 6 tables (3 dimensions + 2 facts + 1 analytics view)

**✅ Business Questions Answered:**
- "Do demographics influence dropout?" → `mart.grp2_demographics_dropout_analysis`

**✅ Dimensional Model:**
- Student, Course, Assessment dimensions
- Student Assessment and VLE Interaction facts
- Ready for advanced analytics and BI tools

**Pipeline Runtime**: ~3-4 minutes end-to-end
**Data Coverage**: Complete OULAD dataset with demographic dropout analysis
**Architecture**: Production-ready with clean/mart schema separation