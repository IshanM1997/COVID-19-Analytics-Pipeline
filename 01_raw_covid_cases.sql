-- =============================================================
-- 01_raw_covid_cases.sql
-- Raw landing table for OWID COVID case data.
-- All columns stored as TEXT to avoid load failures on dirty data.
-- Types are cast in the staging layer (04_stg_cases.sql).
-- =============================================================

USE covid_pipeline;

DROP TABLE IF EXISTS raw_covid_cases;

CREATE TABLE raw_covid_cases (
    iso_code            TEXT,
    continent           TEXT,
    location            TEXT,
    report_date         TEXT,
    total_cases         TEXT,
    new_cases           TEXT,
    new_cases_smoothed  TEXT,
    total_deaths        TEXT,
    new_deaths          TEXT,
    new_deaths_smoothed TEXT,
    total_cases_per_million  TEXT,
    new_cases_per_million    TEXT,
    total_deaths_per_million TEXT,
    new_deaths_per_million   TEXT,
    reproduction_rate   TEXT,
    icu_patients        TEXT,
    icu_patients_per_million TEXT,
    hosp_patients       TEXT,
    hosp_patients_per_million TEXT,
    weekly_icu_admissions     TEXT,
    weekly_hosp_admissions    TEXT,
    loaded_at           TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ---------------------------------------------------------------
-- LOAD DATA INFILE
-- Before running: copy your CSV to the secure_file_priv directory.
-- Check with: SHOW VARIABLES LIKE 'secure_file_priv';
--
-- Windows default: C:\ProgramData\MySQL\MySQL Server 8.0\Uploads\
-- Linux/Mac default: /var/lib/mysql-files/
--
-- Update the path below to match your system.
-- ---------------------------------------------------------------

LOAD DATA INFILE '/var/lib/mysql-files/owid-covid-data.csv'
INTO TABLE raw_covid_cases
FIELDS TERMINATED BY ','
       ENCLOSED BY '"'
LINES  TERMINATED BY '\n'
IGNORE 1 ROWS
(iso_code, continent, location, report_date,
 total_cases, new_cases, new_cases_smoothed,
 total_deaths, new_deaths, new_deaths_smoothed,
 total_cases_per_million, new_cases_per_million,
 total_deaths_per_million, new_deaths_per_million,
 reproduction_rate,
 icu_patients, icu_patients_per_million,
 hosp_patients, hosp_patients_per_million,
 weekly_icu_admissions, weekly_hosp_admissions);

SELECT
    COUNT(*)                                    AS total_rows_loaded,
    COUNT(DISTINCT iso_code)                    AS distinct_countries,
    MIN(STR_TO_DATE(report_date, '%Y-%m-%d'))   AS earliest_date,
    MAX(STR_TO_DATE(report_date, '%Y-%m-%d'))   AS latest_date
FROM raw_covid_cases;
