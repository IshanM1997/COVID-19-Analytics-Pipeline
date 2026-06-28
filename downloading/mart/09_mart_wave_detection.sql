-- =============================================================
-- 09_mart_wave_detection.sql
-- Detects the start of each COVID wave per country.
--
-- Definition of a "wave start":
--   The 7-day rolling average crosses ABOVE 2x the prior
--   4-week minimum (i.e. cases at least doubled from the
--   recent trough), AND the previous day was still below
--   that threshold.
--
-- Window functions used:
--   MIN() OVER (ROWS BETWEEN 28 PRECEDING AND 7 PRECEDING) -> 4-week prior low
--   LAG()                                                  -> previous day value
--   ROW_NUMBER()                                           -> wave number per country
-- =============================================================

USE covid_pipeline;

DROP TABLE IF EXISTS mart_wave_detection;

CREATE TABLE mart_wave_detection (
    iso_code            CHAR(3)       NOT NULL,
    location            VARCHAR(100),
    wave_number         INT           NOT NULL,
    wave_start_date     DATE          NOT NULL,
    avg_cases_at_start  DECIMAL(12,1),
    baseline_avg        DECIMAL(12,1),
    surge_multiplier    DECIMAL(6,1),
    PRIMARY KEY (iso_code, wave_number),
    INDEX idx_wave_date (wave_start_date)
);

INSERT INTO mart_wave_detection
WITH smoothed AS (
    SELECT
        iso_code,
        location,
        report_date,
        cases_7day_avg,

        -- Minimum rolling average from 28 days ago to 7 days ago
        -- (the "recent trough" before the potential wave)
        MIN(cases_7day_avg) OVER (
            PARTITION BY iso_code
            ORDER BY report_date
            ROWS BETWEEN 28 PRECEDING AND 7 PRECEDING
        ) AS prior_4wk_low
    FROM mart_daily_trends
    WHERE cases_7day_avg IS NOT NULL
),
wave_flags AS (
    SELECT
        iso_code,
        location,
        report_date,
        cases_7day_avg,
        prior_4wk_low,

        -- Yesterday's 7-day avg
        LAG(cases_7day_avg, 1) OVER (
            PARTITION BY iso_code
            ORDER BY report_date
        ) AS prev_day_avg,

        -- Flag: today crossed above 2x baseline, yesterday had not
        CASE
            WHEN prior_4wk_low IS NOT NULL
             AND prior_4wk_low > 0
             AND cases_7day_avg > prior_4wk_low * 2
             AND LAG(cases_7day_avg, 1) OVER (
                     PARTITION BY iso_code ORDER BY report_date
                 ) <= prior_4wk_low * 2
            THEN 1
            ELSE 0
        END AS wave_start_flag
    FROM smoothed
),
numbered AS (
    SELECT
        iso_code,
        location,
        report_date        AS wave_start_date,
        cases_7day_avg     AS avg_cases_at_start,
        prior_4wk_low      AS baseline_avg,
        ROUND(cases_7day_avg / NULLIF(prior_4wk_low, 0), 1) AS surge_multiplier,
        ROW_NUMBER() OVER (
            PARTITION BY iso_code
            ORDER BY report_date
        ) AS wave_number
    FROM wave_flags
    WHERE wave_start_flag = 1
)
SELECT
    iso_code,
    location,
    wave_number,
    wave_start_date,
    avg_cases_at_start,
    baseline_avg,
    surge_multiplier
FROM numbered;

-- Summary: how many waves were detected per country on average?
SELECT
    COUNT(DISTINCT iso_code)    AS countries_with_waves,
    COUNT(*)                    AS total_waves_detected,
    ROUND(COUNT(*) / NULLIF(COUNT(DISTINCT iso_code), 0), 1) AS avg_waves_per_country,
    MAX(wave_number)            AS max_waves_single_country,
    MAX(surge_multiplier)       AS highest_surge_multiplier
FROM mart_wave_detection;
