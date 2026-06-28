-- =============================================================
-- 05_stg_vaccinations.sql
-- Staging view: cleans raw_vaccinations.
-- - Deduplicates by (iso_code, report_date)
-- - Casts TEXT to DECIMAL / BIGINT
-- - Forward-fills cumulative columns using MAX() window trick
--   (vaccination totals are cumulative so gaps should carry forward)
-- =============================================================

USE covid_pipeline;

CREATE OR REPLACE VIEW stg_vaccinations AS
WITH deduplicated AS (
    SELECT *,
           ROW_NUMBER() OVER (
               PARTITION BY iso_code, report_date
               ORDER BY loaded_at DESC
           ) AS rn
    FROM raw_vaccinations
    WHERE iso_code    IS NOT NULL AND iso_code    != ''
      AND report_date IS NOT NULL AND report_date != ''
),
casted AS (
    SELECT
        iso_code,
        location,
        STR_TO_DATE(report_date, '%Y-%m-%d')                        AS report_date,
        CAST(NULLIF(total_vaccinations,                  '') AS BIGINT)       AS total_vaccinations,
        CAST(NULLIF(people_vaccinated,                   '') AS BIGINT)       AS people_vaccinated,
        CAST(NULLIF(people_fully_vaccinated,             '') AS BIGINT)       AS people_fully_vaccinated,
        CAST(NULLIF(total_boosters,                      '') AS BIGINT)       AS total_boosters,
        CAST(NULLIF(new_vaccinations,                    '') AS BIGINT)       AS new_vaccinations,
        CAST(NULLIF(total_vaccinations_per_hundred,      '') AS DECIMAL(8,2)) AS total_vaccinations_per_hundred,
        CAST(NULLIF(people_vaccinated_per_hundred,       '') AS DECIMAL(8,2)) AS people_vaccinated_per_hundred,
        CAST(NULLIF(people_fully_vaccinated_per_hundred, '') AS DECIMAL(8,2)) AS people_fully_vaccinated_per_hundred,
        CAST(NULLIF(total_boosters_per_hundred,          '') AS DECIMAL(8,2)) AS total_boosters_per_hundred
    FROM deduplicated
    WHERE rn = 1
),
-- Forward-fill cumulative columns using a MAX window
-- (gaps in cumulative series stay at last known value)
filled AS (
    SELECT
        iso_code,
        location,
        report_date,
        new_vaccinations,
        MAX(total_vaccinations)                  OVER w AS total_vaccinations,
        MAX(people_vaccinated)                   OVER w AS people_vaccinated,
        MAX(people_fully_vaccinated)             OVER w AS people_fully_vaccinated,
        MAX(total_boosters)                      OVER w AS total_boosters,
        MAX(total_vaccinations_per_hundred)      OVER w AS total_vaccinations_per_hundred,
        MAX(people_vaccinated_per_hundred)       OVER w AS people_vaccinated_per_hundred,
        MAX(people_fully_vaccinated_per_hundred) OVER w AS people_fully_vaccinated_per_hundred,
        MAX(total_boosters_per_hundred)          OVER w AS total_boosters_per_hundred
    FROM casted
    WINDOW w AS (
        PARTITION BY iso_code
        ORDER BY report_date
        ROWS UNBOUNDED PRECEDING
    )
)
SELECT * FROM filled;

SELECT
    COUNT(*)                 AS total_rows,
    COUNT(DISTINCT iso_code) AS countries,
    MIN(report_date)         AS earliest_date,
    MAX(report_date)         AS latest_date
FROM stg_vaccinations;
