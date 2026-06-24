-- =============================================================
-- 11_vw_top_countries.sql
-- Country leaderboard with rankings.
-- =============================================================

USE covid_pipeline;

CREATE OR REPLACE VIEW vw_top_countries AS
SELECT
    s.iso_code,
    s.location,
    s.continent,
    s.population,
    s.total_cases,
    s.total_deaths,
    s.case_fatality_rate,
    s.peak_daily_cases,
    s.pct_fully_vaccinated,
    s.days_tracked,
    s.first_case_date,

    -- Cases per million population
    ROUND(s.total_cases  / NULLIF(s.population, 0) * 1000000, 1) AS cases_per_million,
    ROUND(s.total_deaths / NULLIF(s.population, 0) * 1000000, 1) AS deaths_per_million,

    -- Rankings
    RANK() OVER (ORDER BY s.total_cases  DESC) AS rank_by_total_cases,
    RANK() OVER (ORDER BY s.total_deaths DESC) AS rank_by_total_deaths,
    RANK() OVER (ORDER BY s.case_fatality_rate DESC NULLS LAST) AS rank_by_cfr,
    RANK() OVER (
        ORDER BY s.pct_fully_vaccinated DESC NULLS LAST
    ) AS rank_by_vaccination

FROM mart_country_summary s
ORDER BY total_cases DESC;

-- Top 10 by cases
SELECT iso_code, location, total_cases, case_fatality_rate,
       pct_fully_vaccinated, rank_by_total_cases
FROM vw_top_countries
LIMIT 10;
