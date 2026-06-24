-- =============================================================
-- 06_stg_country_dim.sql
-- Staging view: builds the country dimension.
-- Merges static lookup data with distinct locations from cases.
-- =============================================================

USE covid_pipeline;

CREATE OR REPLACE VIEW stg_country_dim AS
SELECT
    COALESCE(l.iso_code,  c.iso_code)  AS iso_code,
    COALESCE(l.location,  c.location)  AS location,
    COALESCE(l.continent, c.continent) AS continent,
    l.population,
    l.population_density,
    l.median_age,
    l.gdp_per_capita
FROM (
    SELECT DISTINCT iso_code, location, continent
    FROM stg_cases
) c
LEFT JOIN raw_country_lookup l ON c.iso_code = l.iso_code;

SELECT COUNT(*) AS total_countries FROM stg_country_dim;
