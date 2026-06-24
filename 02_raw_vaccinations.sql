-- =============================================================
-- 02_raw_vaccinations.sql
-- Raw landing table for vaccination data (OWID or WHO source).
-- =============================================================

USE covid_pipeline;

DROP TABLE IF EXISTS raw_vaccinations;

CREATE TABLE raw_vaccinations (
    iso_code                            TEXT,
    location                            TEXT,
    report_date                         TEXT,
    total_vaccinations                  TEXT,
    people_vaccinated                   TEXT,
    people_fully_vaccinated             TEXT,
    total_boosters                      TEXT,
    new_vaccinations                    TEXT,
    new_vaccinations_smoothed           TEXT,
    total_vaccinations_per_hundred      TEXT,
    people_vaccinated_per_hundred       TEXT,
    people_fully_vaccinated_per_hundred TEXT,
    total_boosters_per_hundred          TEXT,
    new_vaccinations_smoothed_per_million TEXT,
    loaded_at                           TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Update path to match your secure_file_priv directory.
LOAD DATA INFILE '/var/lib/mysql-files/owid-covid-vaccinations.csv'
INTO TABLE raw_vaccinations
FIELDS TERMINATED BY ','
       ENCLOSED BY '"'
LINES  TERMINATED BY '\n'
IGNORE 1 ROWS
(iso_code, location, report_date,
 total_vaccinations, people_vaccinated, people_fully_vaccinated,
 total_boosters, new_vaccinations, new_vaccinations_smoothed,
 total_vaccinations_per_hundred, people_vaccinated_per_hundred,
 people_fully_vaccinated_per_hundred, total_boosters_per_hundred,
 new_vaccinations_smoothed_per_million);

SELECT
    COUNT(*)                  AS total_rows_loaded,
    COUNT(DISTINCT iso_code)  AS distinct_countries
FROM raw_vaccinations;
