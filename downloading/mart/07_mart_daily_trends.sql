-- =============================================================
-- 07_mart_daily_trends.sql
-- Materialised mart table: daily trends per country.
--
-- Window functions used:
--   AVG() OVER (ROWS BETWEEN 6 PRECEDING AND CURRENT ROW)  -> 7-day rolling avg
--   SUM() OVER (ROWS UNBOUNDED PRECEDING)                  -> cumulative totals
--   RANK() OVER (PARTITION BY report_date ORDER BY ...)    -> daily global rank
--   LAG()                                                  -> day-over-day delta
--
-- Stored as a TABLE (not a view) so we can add an index and
-- avoid recomputing window functions on every query.
-- Refresh: TRUNCATE + re-run INSERT when new data loads.
-- =============================================================

USE covid_pipeline;

DROP TABLE IF EXISTS mart_daily_trends;

CREATE TABLE mart_daily_trends (
    iso_code            CHAR(3)        NOT NULL,
    location            VARCHAR(100)   NOT NULL,
    report_date         DATE           NOT NULL,
    new_cases           INT,
    new_deaths          INT,
    cases_7day_avg      DECIMAL(12,1),
    deaths_7day_avg     DECIMAL(10,1),
    cumulative_cases    BIGINT,
    cumulative_deaths   BIGINT,
    daily_rank          INT,
    cases_vs_prev_day   INT,            -- day-over-day delta
    PRIMARY KEY (iso_code, report_date),
    INDEX idx_date      (report_date),
    INDEX idx_location  (location)
);

INSERT INTO mart_daily_trends
WITH base AS (
    SELECT
        iso_code,
        location,
        report_date,
        COALESCE(new_cases,  0) AS new_cases,
        COALESCE(new_deaths, 0) AS new_deaths
    FROM stg_cases
    WHERE continent IS NOT NULL
),
rolling AS (
    SELECT
        iso_code,
        location,
        report_date,
        new_cases,
        new_deaths,

        -- 7-day rolling average
        ROUND(
            AVG(new_cases) OVER (
                PARTITION BY iso_code
                ORDER BY report_date
                ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
            ), 1
        ) AS cases_7day_avg,

        ROUND(
            AVG(new_deaths) OVER (
                PARTITION BY iso_code
                ORDER BY report_date
                ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
            ), 1
        ) AS deaths_7day_avg,

        -- Running cumulative totals
        SUM(new_cases) OVER (
            PARTITION BY iso_code
            ORDER BY report_date
            ROWS UNBOUNDED PRECEDING
        ) AS cumulative_cases,

        SUM(new_deaths) OVER (
            PARTITION BY iso_code
            ORDER BY report_date
            ROWS UNBOUNDED PRECEDING
        ) AS cumulative_deaths,

        -- Daily global rank by new cases
        RANK() OVER (
            PARTITION BY report_date
            ORDER BY new_cases DESC
        ) AS daily_rank,

        -- Day-over-day delta using LAG
        new_cases - LAG(new_cases, 1, 0) OVER (
            PARTITION BY iso_code
            ORDER BY report_date
        ) AS cases_vs_prev_day

    FROM base
)
SELECT
    iso_code,
    location,
    report_date,
    new_cases,
    new_deaths,
    cases_7day_avg,
    deaths_7day_avg,
    cumulative_cases,
    cumulative_deaths,
    daily_rank,
    cases_vs_prev_day
FROM rolling;

SELECT
    COUNT(*)                 AS rows_inserted,
    COUNT(DISTINCT iso_code) AS countries,
    MIN(report_date)         AS from_date,
    MAX(report_date)         AS to_date
FROM mart_daily_trends;
