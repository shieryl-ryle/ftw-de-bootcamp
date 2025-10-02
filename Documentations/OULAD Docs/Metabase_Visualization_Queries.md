# Metabase Visualization Queries for OULAD Demographic Dropout Analysis

## Business Question: "Do demographics influence dropout?"
**Source**: `mart.grp2_demographics_dropout_analysis`

---

## Query 1: Dropout Rate by Demographics (Bar Chart)
**Visualization**: Horizontal Bar Chart
**Purpose**: Show which demographic groups have highest dropout rates

```sql
SELECT 
    CONCAT(gender, ' | ', age_band) as demographic_group,
    dropout_rate_pct,
    total_students,
    statistical_confidence,
    risk_classification
FROM mart.grp2_demographics_dropout_analysis
WHERE statistical_confidence IN ('High Confidence', 'Medium Confidence')
    AND total_students >= 20
ORDER BY dropout_rate_pct DESC
LIMIT 10
```

**Metabase Settings:**
- Chart Type: Bar Chart (Horizontal)
- X-axis: `demographic_group`  
- Y-axis: `dropout_rate_pct`
- Goal Line: Add at overall average dropout rate

---

## Query 2: Education Level Impact (Column Chart)
**Visualization**: Column Chart
**Purpose**: Compare dropout rates across education levels

```sql
SELECT 
    highest_education,
    ROUND(AVG(dropout_rate_pct), 2) as avg_dropout_rate,
    ROUND(AVG(success_rate_pct), 2) as avg_success_rate,
    SUM(total_students) as total_students,
    COUNT(*) as demographic_segments
FROM mart.grp2_demographics_dropout_analysis
WHERE statistical_confidence IN ('High Confidence', 'Medium Confidence')
GROUP BY highest_education
HAVING SUM(total_students) >= 50
ORDER BY avg_dropout_rate DESC
```

**Metabase Settings:**
- Chart Type: Column Chart
- X-axis: `highest_education`
- Y-axis: `avg_dropout_rate` and `avg_success_rate` (Multiple Metrics)

---

## Query 3: Age Band Analysis (Line Chart)
**Visualization**: Line Chart
**Purpose**: Show dropout trends across age groups

```sql
SELECT 
    age_band,
    gender,
    ROUND(AVG(dropout_rate_pct), 2) as dropout_rate,
    SUM(total_students) as students
FROM mart.grp2_demographics_dropout_analysis
WHERE statistical_confidence IN ('High Confidence', 'Medium Confidence')
GROUP BY age_band, gender
HAVING SUM(total_students) >= 30
ORDER BY 
    CASE age_band
        WHEN '0-35' THEN 1
        WHEN '35-55' THEN 2  
        WHEN '55+' THEN 3
        ELSE 4
    END
```

**Metabase Settings:**
- Chart Type: Line Chart
- X-axis: `age_band`
- Y-axis: `dropout_rate`
- Series: `gender` (separate lines for Male/Female)

---

## Query 4: Disability Impact Analysis (Pie Chart)
**Visualization**: Pie Chart
**Purpose**: Compare students with/without disabilities

```sql
SELECT 
    CASE WHEN has_disability = 1 THEN 'Has Disability' ELSE 'No Disability' END as disability_status,
    ROUND(AVG(dropout_rate_pct), 2) as avg_dropout_rate,
    SUM(total_students) as total_students
FROM mart.grp2_demographics_dropout_analysis
WHERE statistical_confidence IN ('High Confidence', 'Medium Confidence')
GROUP BY has_disability
```

**Metabase Settings:**
- Chart Type: Pie Chart
- Dimension: `disability_status`
- Metric: `avg_dropout_rate`
- Show percentages and values

---

## Query 5: Regional Risk Heatmap (Table/Heatmap)
**Visualization**: Table with conditional formatting
**Purpose**: Show geographic patterns in dropout risk

```sql
SELECT 
    region,
    COUNT(*) as risk_segments,
    ROUND(AVG(dropout_rate_pct), 2) as avg_dropout_rate,
    SUM(total_students) as total_students,
    SUM(CASE WHEN risk_classification = 'High Risk Group' THEN 1 ELSE 0 END) as high_risk_segments,
    STRING_AGG(
        CASE WHEN risk_classification IN ('High Risk Group', 'Elevated Risk') 
        THEN CONCAT(gender, '-', age_band, ' (', CAST(dropout_rate_pct as VARCHAR), '%)')
        END, 
        ', '
    ) as at_risk_demographics
FROM mart.grp2_demographics_dropout_analysis
WHERE statistical_confidence IN ('High Confidence', 'Medium Confidence')
GROUP BY region
ORDER BY avg_dropout_rate DESC
---

## Query 6: Top Risk Factors Dashboard (Summary)
**Visualization**: Number Cards + Table
**Purpose**: Executive summary of key risk factors

```sql
-- Main metrics
SELECT 
    'Overall Stats' as category,
    ROUND(AVG(dropout_rate_pct), 2) as overall_dropout_rate,
    COUNT(DISTINCT CONCAT(gender, age_band, highest_education, region)) as demographic_combinations,
    SUM(total_students) as total_students_analyzed
FROM mart.grp2_demographics_dropout_analysis
WHERE statistical_confidence IN ('High Confidence', 'Medium Confidence')

UNION ALL

-- Highest risk group
SELECT 
    'Highest Risk Group' as category,
    MAX(dropout_rate_pct) as overall_dropout_rate,
    COUNT(*) as demographic_combinations,
    SUM(total_students) as total_students_analyzed
FROM mart.grp2_demographics_dropout_analysis
WHERE risk_classification = 'High Risk Group'
    AND statistical_confidence IN ('High Confidence', 'Medium Confidence')

UNION ALL

-- Success patterns
SELECT 
    'Success Patterns' as category,
    MIN(dropout_rate_pct) as overall_dropout_rate,
    COUNT(*) as demographic_combinations,
    SUM(total_students) as total_students_analyzed
FROM mart.grp2_demographics_dropout_analysis  
WHERE risk_classification = 'Low Risk Group'
    AND statistical_confidence IN ('High Confidence', 'Medium Confidence')
```

**Metabase Settings:**
- Chart Type: Number Cards for key metrics
- Additional Table showing breakdown

---

## Query 7: Action Priority Matrix (Scatter Plot)
**Visualization**: Scatter Plot
**Purpose**: Prioritize intervention efforts (Impact vs Effort)

```sql
SELECT 
    CONCAT(gender, ' | ', age_band, ' | ', highest_education) as demographic_group,
    dropout_rate_pct as impact_score,
    total_students as population_size,
    dropout_rate_vs_average as risk_deviation,
    risk_classification,
    CASE 
        WHEN dropout_rate_pct > 40 AND total_students > 100 THEN 'Critical Priority'
        WHEN dropout_rate_pct > 35 AND total_students > 50 THEN 'High Priority'  
        WHEN dropout_rate_pct > 25 THEN 'Medium Priority'
        ELSE 'Monitor'
    END as intervention_priority
FROM mart.grp2_demographics_dropout_analysis
WHERE statistical_confidence IN ('High Confidence', 'Medium Confidence')
    AND total_students >= 10
```

**Metabase Settings:**
- Chart Type: Scatter Plot
- X-axis: `population_size` (Student Count)
- Y-axis: `impact_score` (Dropout Rate %)

---

## Dashboard Layout Recommendations

### **Executive Dashboard**
1. **Top Row**: Number cards (Query 6) - Overall stats
2. **Second Row**: Bar chart (Query 1) + Pie chart (Query 4)
3. **Third Row**: Column chart (Query 2) + Line chart (Query 3)
4. **Bottom Row**: Regional heatmap table (Query 5)

### **Detailed Analysis Dashboard**
1. **Priority Matrix**: Scatter plot (Query 7)
2. **Detailed Breakdowns**: All demographic combinations
3. **Filters**: Add filters for statistical_confidence, region, risk_classification

### **Key Insights to Highlight**
- Which demographic combinations have >40% dropout rate
- Education level patterns (e.g., do A-Levels perform better?)
- Age and gender interactions
- Regional variations
- Disability impact quantification

These queries will provide comprehensive visualizations to answer "Do demographics influence dropout?" with clear, actionable insights for stakeholder presentations.