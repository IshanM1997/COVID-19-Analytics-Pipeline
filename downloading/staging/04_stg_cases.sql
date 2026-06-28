-- =============================================================
-- 04_stg_cases.sql
-- Staging view: cleans raw_covid_cases.
-- - Deduplicates by (iso_code, report_date) keeping latest load
-- - Casts TEXT columns to proper types
-- - Drops rows with negative new_cases / new_deaths (corrections)
-- - Excludes aggregated rows like "World", "Europe" (no iso_code prefix)
-- =============================================================

USE covid_pipeline;

CREATE OR REPLACE VIEW stg_cases AS
WITH deduplicated AS (
    SELECT *,
           ROW_NUMBER() OVER (
               PARTITION BY iso_code, report_date
               ORDER BY loaded_at DESC
           ) AS rn
    FROM raw_covid_cases
    WHERE iso_code    IS NOT NULL
      AND iso_code    != ''
      AND report_date IS NOT NULL
      AND report_date != ''
      AND iso_code NOT IN ('OWID_WRL','OWID_EUR','OWID_ASI',
                           'OWID_NAM','OWID_SAM','OWID_AFR','OWID_OCE')
),
casted AS (
    SELECT
        iso_code,
        continent,
        location,
        STR_TO_DATE(report_date, '%Y-%m-%d')              AS report_date,
        CAST(NULLIF(new_cases,           '') AS SIGNED)   AS new_cases,
        CAST(NULLIF(new_deaths,          '') AS SIGNED)   AS new_deaths,
        CAST(NULLIF(new_cases_smoothed,  '') AS DECIMAL(12,2)) AS new_cases_smoothed,
        CAST(NULLIF(new_deaths_smoothed, '') AS DECIMAL(10,2)) AS new_deaths_smoothed,
        CAST(NULLIF(total_cases,         '') AS BIGINT)   AS total_cases,
        CAST(NULLIF(total_deaths,        '') AS BIGINT)   AS total_deaths,
        CAST(NULLIF(hosp_patients,       '') AS SIGNED)   AS hosp_patients,
        CAST(NULLIF(icu_patients,        '') AS SIGNED)   AS icu_patients,
        CAST(NULLIF(reproduction_rate,   '') AS DECIMAL(6,2)) AS reproduction_rate,
        CAST(NULLIF(total_cases_per_million,  '') AS DECIMAL(12,2)) AS total_cases_per_million,
        CAST(NULLIF(total_deaths_per_million, '') AS DECIMAL(10,2)) AS total_deaths_per_million
    FROM deduplicated
    WHERE rn = 1
)
SELECT * FROM casted
WHERE (new_cases  IS NULL OR new_cases  >= 0)
  AND (new_deaths IS NULL OR new_deaths >= 0);

-- Quick check
SELECT
    COUNT(*)                AS total_rows,
    COUNT(DISTINCT iso_code) AS countries,
    MIN(report_date)        AS earliest_date,
    MAX(report_date)        AS latest_date,
    SUM(CASE WHEN new_cases IS NULL THEN 1 ELSE 0 END) AS null_new_cases
FROM stg_cases;
