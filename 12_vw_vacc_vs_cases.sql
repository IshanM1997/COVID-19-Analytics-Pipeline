-- =============================================================
-- 12_vw_vacc_vs_cases.sql
-- Joins vaccination rate against case trajectory.
-- Useful for scatter/correlation charts: did high vaccination
-- rates correspond to lower case surges post-2021?
-- =============================================================

USE covid_pipeline;

CREATE OR REPLACE VIEW vw_vacc_vs_cases AS
SELECT
    t.iso_code,
    t.location,
    t.report_date,
    t.new_cases,
    t.cases_7day_avg,
    t.cumulative_cases,
    t.cumulative_deaths,
    s.pct_fully_vaccinated,
    s.pct_vaccinated_at_least_one,
    s.case_fatality_rate,
    s.population,

    -- Vaccination tier (for grouped analysis)
    CASE
        WHEN s.pct_fully_vaccinated >= 60 THEN 'high (60%+)'
        WHEN s.pct_fully_vaccinated >= 30 THEN 'medium (30-60%)'
        WHEN s.pct_fully_vaccinated >  0  THEN 'low (<30%)'
        ELSE 'no data'
    END AS vacc_tier,

    -- Cases per million (normalised for population size)
    ROUND(
        t.cumulative_cases / NULLIF(s.population, 0) * 1000000,
        1
    ) AS cumulative_cases_per_million

FROM mart_daily_trends    t
JOIN mart_country_summary s ON t.iso_code = s.iso_code
WHERE t.report_date >= '2021-01-01'   -- vaccination rollout period
  AND s.population  >  1000000;       -- exclude micro-states

-- Summary by vaccination tier
SELECT
    vacc_tier,
    COUNT(DISTINCT iso_code)             AS countries,
    ROUND(AVG(cases_7day_avg), 0)        AS avg_daily_cases,
    ROUND(AVG(case_fatality_rate), 3)    AS avg_cfr,
    ROUND(AVG(pct_fully_vaccinated), 1)  AS avg_vacc_pct
FROM vw_vacc_vs_cases
WHERE report_date = (SELECT MAX(report_date) FROM vw_vacc_vs_cases)
GROUP BY vacc_tier
ORDER BY avg_vacc_pct DESC;
