-- =============================================================
-- 10_vw_global_trend.sql
-- Global daily rollup across all countries.
-- Useful for a single time-series chart showing worldwide trend.
-- =============================================================

USE covid_pipeline;

CREATE OR REPLACE VIEW vw_global_trend AS
SELECT
    report_date,
    SUM(new_cases)                            AS global_new_cases,
    SUM(new_deaths)                           AS global_new_deaths,
    ROUND(SUM(cases_7day_avg),  0)            AS global_7day_avg_cases,
    ROUND(SUM(deaths_7day_avg), 0)            AS global_7day_avg_deaths,
    MAX(cumulative_cases)                     AS global_cumulative_cases,
    MAX(cumulative_deaths)                    AS global_cumulative_deaths,
    COUNT(DISTINCT iso_code)                  AS countries_reporting,

    -- Week-over-week growth rate
    ROUND(
        (SUM(new_cases) - LAG(SUM(new_cases), 7) OVER (ORDER BY report_date))
        / NULLIF(LAG(SUM(new_cases), 7) OVER (ORDER BY report_date), 0) * 100,
        1
    ) AS wow_growth_pct

FROM mart_daily_trends
GROUP BY report_date
ORDER BY report_date;

-- Quick sample
SELECT * FROM vw_global_trend ORDER BY report_date DESC LIMIT 14;
