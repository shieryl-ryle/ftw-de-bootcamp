# Dimensional Model Diagrams

## 1. Source System Entity Relationship

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                           CHINOOK SOURCE SYSTEM                            │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│   ┌──────────────┐    ┌──────────────┐    ┌──────────────┐                │
│   │   CUSTOMER   │    │   INVOICE    │    │INVOICE_LINE  │                │
│   │──────────────│    │──────────────│    │──────────────│                │
│   │customer_id PK│───▶│customer_id FK│    │invoice_id FK │                │
│   │first_name    │    │invoice_id PK │◀───│track_id FK   │                │
│   │last_name     │    │invoice_date  │    │unit_price    │                │
│   │country       │    │total         │    │quantity      │                │
│   │city          │    │              │    │              │                │
│   └──────────────┘    └──────────────┘    └──────────────┘                │
│                                                    │                        │
│   ┌──────────────┐    ┌──────────────┐           │                        │
│   │    GENRE     │    │    TRACK     │           │                        │
│   │──────────────│    │──────────────│           │                        │
│   │genre_id PK   │───▶│genre_id FK   │◀──────────┘                        │
│   │name          │    │track_id PK   │                                     │
│   └──────────────┘    │name          │                                     │
│                       │unit_price    │                                     │
│                       │album_id FK   │                                     │
│                       └──────────────┘                                     │
│                                │                                           │
│   ┌──────────────┐    ┌──────────────┐    ┌──────────────┐                │
│   │   ARTIST     │    │    ALBUM     │    │              │                │
│   │──────────────│    │──────────────│    │              │                │
│   │artist_id PK  │───▶│artist_id FK  │◀───┘              │                │
│   │name          │    │album_id PK   │                   │                │
│   └──────────────┘    │title         │                   │                │
│                       └──────────────┘                   │                │
└─────────────────────────────────────────────────────────────────────────────┘
```

## 2. Dimensional Model - Star Schema Design

### Analysis 1: Revenue by Genre per Country

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                    REVENUE BY GENRE PER COUNTRY MART                       │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│              FACT TABLE: g2_top_revenue_by_genre_per_country_shi            │
│                    ┌────────────────────────────────────┐                   │
│ ┌─────────────────▶│           REVENUE FACTS            │◀─────────────────┐ │
│ │                  │────────────────────────────────────│                  │ │
│ │                  │ country (FK)                       │                  │ │
│ │                  │ genre_name (FK)                    │                  │ │
│ │                  │ total_revenue                      │                  │ │
│ │                  │ unique_customers                   │                  │ │
│ │                  │ total_tracks_sold                  │                  │ │
│ │                  │ total_quantity                     │                  │ │
│ │                  └────────────────────────────────────┘                  │ │
│ │                                                                          │ │
│ │ ┌─────────────────────┐                    ┌─────────────────────┐       │ │
│ │ │  COUNTRY DIMENSION  │                    │  GENRE DIMENSION    │       │ │
│ └─│─────────────────────│                    │─────────────────────│───────┘ │
│   │ country (PK)        │                    │ genre_name (PK)     │         │
│   │ region              │                    │ genre_category      │         │
│   │ continent           │                    │ price_tier          │         │
│   └─────────────────────┘                    └─────────────────────┘         │
│                                                                             │
│   Grain: One record per Country-Genre combination                           │
│   Purpose: Analyze music genre performance by geographic location           │
└─────────────────────────────────────────────────────────────────────────────┘
```

### Analysis 2: Regional Pricing Insights

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                        REGIONAL PRICING INSIGHTS MART                      │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│                 FACT TABLE: g2_regional_pricing_insights_shi               │
│                    ┌────────────────────────────────────┐                   │
│ ┌─────────────────▶│           PRICING FACTS            │◀─────────────────┐ │
│ │                  │────────────────────────────────────│                  │ │
│ │                  │ country (FK)                       │                  │ │
│ │                  │ region (FK)                        │                  │ │
│ │                  │ total_purchases                    │                  │ │
│ │                  │ total_revenue                      │                  │ │
│ │                  │ avg_price_paid                     │                  │ │
│ │                  │ low_price_purchases                │                  │ │
│ │                  │ high_price_purchases               │                  │ │
│ │                  │ price_sensitivity_score            │                  │ │
│ │                  │ avg_spending_per_customer          │                  │ │
│ │                  └────────────────────────────────────┘                  │ │
│ │                                                                          │ │
│ │ ┌─────────────────────┐                    ┌─────────────────────┐       │ │
│ │ │  COUNTRY DIMENSION  │                    │  REGION DIMENSION   │       │ │
│ └─│─────────────────────│                    │─────────────────────│───────┘ │
│   │ country (PK)        │                    │ region (PK)         │         │
│   │ country_code        │                    │ continent           │         │
│   │ market_tier         │                    │ economic_zone       │         │
│   └─────────────────────┘                    └─────────────────────┘         │
│                                                                             │
│   Grain: One record per Country with pricing analytics                     │
│   Purpose: Analyze price sensitivity and customer value by region          │
└─────────────────────────────────────────────────────────────────────────────┘
```

## 3. Data Flow Architecture

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                           DATA FLOW PROCESS                                │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│   SOURCE SYSTEM          ETL PROCESS           ANALYTICAL LAYER             │
│                                                                             │
│ ┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐           │
│ │   PostgreSQL    │    │     Python      │    │   ClickHouse    │           │
│ │   (Chinook DB)  │───▶│   ETL Scripts   │───▶│   (Mart Layer)  │           │
│ │                 │    │                 │    │                 │           │
│ │ • Customers     │    │ • Data Extract  │    │ • Revenue Facts │           │
│ │ • Invoices      │    │ • Transform     │    │ • Pricing Facts │           │
│ │ • Tracks        │    │ • Quality Check │    │ • Aggregations  │           │
│ │ • Genres        │    │ • Load Process  │    │ • Calculations  │           │
│ │                 │    │                 │    │                 │           │
│ └─────────────────┘    └─────────────────┘    └─────────────────┘           │
│                                                        │                    │
│                                                        │                    │
│                        ┌─────────────────────────────────┘                 │
│                        ▼                                                   │
│                ┌─────────────────┐                                         │
│                │    METABASE     │                                         │
│                │  (Visualization) │                                         │
│                │                 │                                         │
│                │ • Dashboards    │                                         │
│                │ • Reports       │                                         │
│                │ • Ad-hoc Query  │                                         │
│                │ • Self-Service  │                                         │
│                └─────────────────┘                                         │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

## 4. Implementation Timeline

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                          PROJECT TIMELINE                                  │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│ Phase 1: Requirements & Design (Day 1)                                     │
│ ├─ Business requirements gathering                                          │
│ ├─ Source system analysis                                                   │
│ ├─ Dimensional model design                                                 │
│ └─ Technical architecture planning                                          │
│                                                                             │
│ Phase 2: Development & Testing (Day 1)                                     │
│ ├─ Source data exploration                                                  │
│ ├─ ETL script development                                                   │
│ ├─ Data quality validation                                                  │
│ └─ Performance optimization                                                 │
│                                                                             │
│ Phase 3: Deployment & Validation (Day 1)                                  │
│ ├─ Production deployment                                                    │
│ ├─ Data validation & testing                                               │
│ ├─ Metabase query development                                              │
│ └─ Documentation & handover                                                │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```