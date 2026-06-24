# COVID-19 Analytics Pipeline

A fully SQL-driven analytics pipeline using **MySQL 8**, window functions, and CTEs.  
Ingests public COVID-19 datasets, cleans them through a layered architecture, and
produces time-series trend tables and analytics views.

---

## Folder structure

```
covid-analytics-pipeline/
├── README.md
├── data/
│   └── sample/
│       └── owid-covid-sample.csv        ← 500-row sample to run without downloading
├── schema/
│   └── 00_create_database.sql           ← database + user setup
├── raw/
│   ├── 01_raw_covid_cases.sql           ← raw cases table DDL + LOAD DATA INFILE
│   ├── 02_raw_vaccinations.sql          ← raw vaccinations table DDL
│   └── 03_raw_country_lookup.sql        ← ISO codes + region lookup
├── staging/
│   ├── 04_stg_cases.sql                 ← cast types, dedup, drop negatives
│   ├── 05_stg_vaccinations.sql          ← fill nulls, cast decimals
│   └── 06_stg_country_dim.sql           ← distinct country dimension
├── marts/
│   ├── 07_mart_daily_trends.sql         ← 7-day rolling avg, cumulative totals
│   ├── 08_mart_country_summary.sql      ← peak, CFR, vaccination rate
│   └── 09_mart_wave_detection.sql       ← LAG-based wave detection
├── views/
│   ├── 10_vw_global_trend.sql           ← global daily rollup
│   ├── 11_vw_top_countries.sql          ← ranked country leaderboard
│   └── 12_vw_vacc_vs_cases.sql          ← vaccination rate vs case trajectory
└── scripts/
    └── load_data.sh                     ← automates LOAD DATA INFILE step
```

---

## Data sources

| Source | Dataset | URL |
|--------|---------|-----|
| Our World in Data | owid-covid-data.csv | https://github.com/owid/covid-19-data/tree/master/public/data |
| Johns Hopkins | time_series_covid19_confirmed_global.csv | https://github.com/CSSEGISandData/COVID-19 |
| WHO | vaccination-data.csv | https://covid19.who.int/data |

Download `owid-covid-data.csv` and place it in `data/sample/` to get started quickly.
A 500-row sample is already included so you can run the full pipeline without downloading anything.

---

## Prerequisites

| Tool | Version | Notes |
|------|---------|-------|
| MySQL | 8.0+ | Community Edition |
| VS Code | any | with cweijan MySQL extension |

### VS Code extensions to install

- **MySQL** by cweijan — database explorer + run SQL files with one click
- **SQLTools** + **SQLTools MySQL/MariaDB Driver** — alternative connection manager
- **Rainbow CSV** — makes inspecting raw CSV files much easier

---

## Quick start

### 1. Start MySQL

**Local install:**
```bash
mysql -u root -p
```

**Docker (no install needed):**
```bash
docker run --name covid-mysql -p 3306:3306 -e MYSQL_ROOT_PASSWORD=root -d mysql:8
```

### 2. Run files in order

Open each file in VS Code and press `Ctrl+Shift+E` (cweijan extension) to execute, or copy-paste into your MySQL client.

```
schema/00_create_database.sql
raw/01_raw_covid_cases.sql
raw/02_raw_vaccinations.sql
raw/03_raw_country_lookup.sql
staging/04_stg_cases.sql
staging/05_stg_vaccinations.sql
staging/06_stg_country_dim.sql
marts/07_mart_daily_trends.sql
marts/08_mart_country_summary.sql
marts/09_mart_wave_detection.sql
views/10_vw_global_trend.sql
views/11_vw_top_countries.sql
views/12_vw_vacc_vs_cases.sql
```

### 3. Fix the CSV path (important on Windows)

Run this to find where MySQL expects files:
```sql
SHOW VARIABLES LIKE 'secure_file_priv';
```

Copy your CSV to that path, then update the `LOAD DATA INFILE` path in
`raw/01_raw_covid_cases.sql` to match.

**Windows default path:** `C:\ProgramData\MySQL\MySQL Server 8.0\Uploads\`  
**Linux/Mac default path:** `/var/lib/mysql-files/`

### 4. Verify the pipeline

```sql
SELECT location, total_cases, case_fatality_rate, pct_fully_vaccinated
FROM covid_pipeline.vw_top_countries
ORDER BY total_cases DESC
LIMIT 10;
```

If you get 10 rows back, the full pipeline is working.

---

## SQL concepts demonstrated

| Concept | Where used |
|---------|-----------|
| `ROW_NUMBER()` for deduplication | `04_stg_cases.sql` |
| `CAST` + `NULLIF` for type cleaning | `04_stg_cases.sql`, `05_stg_vaccinations.sql` |
| `AVG() OVER (ROWS BETWEEN ...)` rolling average | `07_mart_daily_trends.sql` |
| `SUM() OVER (ROWS UNBOUNDED PRECEDING)` cumulative total | `07_mart_daily_trends.sql` |
| `RANK() OVER (PARTITION BY ...)` daily country ranking | `07_mart_daily_trends.sql` |
| Multi-CTE joins for summary tables | `08_mart_country_summary.sql` |
| `LAG()` for wave detection | `09_mart_wave_detection.sql` |
| `MIN() OVER` sliding window baseline | `09_mart_wave_detection.sql` |

---

## Why mart tables instead of views?

`mart_daily_trends` computes rolling averages over ~200k rows. As a view it
re-runs the window functions on every query. As a materialised table with an
index on `(iso_code, report_date)` it returns in milliseconds:

```sql
ALTER TABLE mart_daily_trends ADD INDEX idx_iso_date (iso_code, report_date);
```

Refresh it when new data loads:
```sql
TRUNCATE TABLE mart_daily_trends;
INSERT INTO mart_daily_trends ...  -- re-run 07_mart_daily_trends.sql
```
