-- =============================================================
-- 03_raw_country_lookup.sql
-- Static country/region dimension table.
-- Seeded with ISO-3166 data so joins always resolve.
-- =============================================================

USE covid_pipeline;

DROP TABLE IF EXISTS raw_country_lookup;

CREATE TABLE raw_country_lookup (
    iso_code       CHAR(3)      NOT NULL,
    location       VARCHAR(100) NOT NULL,
    continent      VARCHAR(50),
    population     BIGINT,
    population_density DECIMAL(10,2),
    median_age     DECIMAL(4,1),
    gdp_per_capita DECIMAL(12,2),
    PRIMARY KEY (iso_code)
);

-- Seed with the most common countries from OWID data.
-- Extend this list as needed when you load the full dataset.
INSERT INTO raw_country_lookup
    (iso_code, location, continent, population, median_age)
VALUES
    ('AFG', 'Afghanistan',      'Asia',          38928341,  18.6),
    ('ALB', 'Albania',          'Europe',         2877800,  38.0),
    ('DZA', 'Algeria',          'Africa',        43851043,  29.1),
    ('ARG', 'Argentina',        'South America', 45195777,  32.4),
    ('AUS', 'Australia',        'Oceania',       25499881,  38.7),
    ('AUT', 'Austria',          'Europe',         9006400,  44.4),
    ('BRA', 'Brazil',           'South America',213993441,  33.5),
    ('CAN', 'Canada',           'North America', 37742157,  41.8),
    ('CHL', 'Chile',            'South America', 19116209,  35.5),
    ('CHN', 'China',            'Asia',        1439323774,  38.4),
    ('COL', 'Colombia',         'South America', 50882884,  31.2),
    ('CZE', 'Czechia',          'Europe',        10708982,  43.3),
    ('DNK', 'Denmark',          'Europe',         5792203,  42.3),
    ('EGY', 'Egypt',            'Africa',       102334403,  25.3),
    ('FIN', 'Finland',          'Europe',         5540718,  43.1),
    ('FRA', 'France',           'Europe',        67391582,  42.3),
    ('DEU', 'Germany',          'Europe',        83900471,  45.7),
    ('GRC', 'Greece',           'Europe',        10423056,  45.3),
    ('HUN', 'Hungary',          'Europe',         9660350,  43.6),
    ('IND', 'India',            'Asia',        1380004385,  28.4),
    ('IDN', 'Indonesia',        'Asia',         273523621,  29.7),
    ('IRN', 'Iran',             'Asia',          83992953,  32.0),
    ('IRL', 'Ireland',          'Europe',         4937796,  38.7),
    ('ISR', 'Israel',           'Asia',           8655541,  30.6),
    ('ITA', 'Italy',            'Europe',        60461828,  47.3),
    ('JPN', 'Japan',            'Asia',          126476458,  48.7),
    ('KAZ', 'Kazakhstan',       'Asia',          18776707,  31.6),
    ('KEN', 'Kenya',            'Africa',        53771300,  20.1),
    ('KOR', 'South Korea',      'Asia',          51269183,  43.7),
    ('MEX', 'Mexico',           'North America', 128932753,  29.3),
    ('MAR', 'Morocco',          'Africa',        36910558,  29.3),
    ('NLD', 'Netherlands',      'Europe',        17134873,  43.2),
    ('NZL', 'New Zealand',      'Oceania',        4822233,  38.1),
    ('NGA', 'Nigeria',          'Africa',       206139587,  18.1),
    ('NOR', 'Norway',           'Europe',         5421242,  39.8),
    ('PAK', 'Pakistan',         'Asia',          220892331,  23.8),
    ('PER', 'Peru',             'South America', 32971846,  31.0),
    ('PHL', 'Philippines',      'Asia',          109581085,  25.7),
    ('POL', 'Poland',           'Europe',        37846605,  41.7),
    ('PRT', 'Portugal',         'Europe',        10196707,  46.2),
    ('ROU', 'Romania',          'Europe',        19237682,  42.5),
    ('RUS', 'Russia',           'Europe',       145934460,  39.6),
    ('SAU', 'Saudi Arabia',     'Asia',          34813867,  31.9),
    ('ZAF', 'South Africa',     'Africa',        59308690,  27.6),
    ('ESP', 'Spain',            'Europe',        46754783,  44.9),
    ('SWE', 'Sweden',           'Europe',        10099270,  41.1),
    ('CHE', 'Switzerland',      'Europe',         8654618,  43.1),
    ('THA', 'Thailand',         'Asia',          69799978,  40.1),
    ('TUR', 'Turkey',           'Asia',          84339067,  32.0),
    ('UKR', 'Ukraine',          'Europe',        43733759,  41.4),
    ('GBR', 'United Kingdom',   'Europe',        67886004,  40.8),
    ('USA', 'United States',    'North America', 331002647,  38.3),
    ('VNM', 'Vietnam',          'Asia',          97338583,  30.9),
    ('ZWE', 'Zimbabwe',         'Africa',        14862927,  20.0);

SELECT COUNT(*) AS countries_seeded FROM raw_country_lookup;
