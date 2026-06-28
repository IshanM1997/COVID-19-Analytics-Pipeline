-- =============================================================
-- 08_mart_country_summary.sql
-- One row per country: peak cases, case fatality rate,
-- vaccination rate, and days tracked.
--
-- CTE chain:
--   peak_cases    -> MAX new_cases/deaths per country
--   latest_totals -> most recent total_cases / total_deaths
--   cfr           -> case fatality rate from latest totals
--   vacc_rate     -> highest people_fully_vaccinated_per_hundred
-- =============================================================

USE covid_pipeline;

DROP TABLE IF EXISTS mart_country_summary;

CREATE TABLE mart_country_summary (
    iso_code                CHAR(3)        NOT NULL,
    location                VARCHAR(100),
    continent               VARCHAR(50),
    population              BIGINT,
    first_case_date         DATE,
    last_report_date        DATE,
    days_tracked            INT,
    peak_daily_cases        INT,
    peak_daily_deaths       INT,
    total_cases             BIGINT,
    total_deaths            BIGINT,
    case_fatality_rate      DECIMAL(6,3),
    pct_fully_vaccinated    DECIMAL(6,2),
    pct_vaccinated_at_least_one DECIMAL(6,2),
    PRIMARY KEY (iso_code)
);

INSERT INTO mart_country_summary
WITH peak_cases AS (
    SELECT
        iso_code,
        MAX(new_cases)   AS peak_daily_cases,
        MAX(new_deaths)  AS peak_daily_deaths,
        MIN(report_date) AS first_case_date,
        MAX(report_date) AS last_report_date,
        DATEDIFF(MAX(report_date), MIN(report_date)) AS days_tracked
    FROM stg_cases
    WHERE continent IS NOT NULL
    GROUP BY iso_code
),
latest_totals AS (
    -- Subquery gets the latest report_date per country
    SELECT c.iso_code, c.total_cases, c.total_deaths
    FROM stg_cases c
    INNER JOIN (
        SELECT iso_code, MAX(report_date) AS max_date
        FROM stg_cases
        WHERE continent IS NOT NULL
        GROUP BY iso_code
    ) latest ON c.iso_code = latest.iso_code
           AND c.report_date = latest.max_date
),
cfr AS (
    SELECT
        iso_code,
        total_cases,
        total_deaths,
        ROUND(
            total_deaths / NULLIF(total_cases, 0) * 100,
            3
        ) AS case_fatality_rate
    FROM latest_totals
),
vacc_rate AS (
    SELECT
        iso_code,
        ROUND(MAX(people_fully_vaccinated_per_hundred), 2)  AS pct_fully_vaccinated,
        ROUND(MAX(people_vaccinated_per_hundred), 2)        AS pct_vaccinated_at_least_one
    FROM stg_vaccinations
    GROUP BY iso_code
)
SELECT
    p.iso_code,
    d.location,
    d.continent,
    d.population,
    p.first_case_date,
    p.last_report_date,
    p.days_tracked,
    p.peak_daily_cases,
    p.peak_daily_deaths,
    c.total_cases,
    c.total_deaths,
    c.case_fatality_rate,
    v.pct_fully_vaccinated,
    v.pct_vaccinated_at_least_one
FROM peak_cases       p
JOIN cfr              c ON p.iso_code = c.iso_code
JOIN stg_country_dim  d ON p.iso_code = d.iso_code
LEFT JOIN vacc_rate   v ON p.iso_code = v.iso_code;

SELECT
    COUNT(*)  AS countries_summarised,
    ROUND(AVG(case_fatality_rate), 3) AS avg_cfr,
    ROUND(AVG(pct_fully_vaccinated), 1) AS avg_pct_vaccinated
FROM mart_country_summary;
