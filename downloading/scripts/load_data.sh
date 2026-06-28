#!/usr/bin/env bash
# =============================================================
# load_data.sh
# Automates the full pipeline run in order.
# Usage: bash scripts/load_data.sh
# Set MYSQL_USER, MYSQL_PASS, MYSQL_HOST as env vars or edit below.
# =============================================================

set -euo pipefail

MYSQL_USER="${MYSQL_USER:-root}"
MYSQL_PASS="${MYSQL_PASS:-root}"
MYSQL_HOST="${MYSQL_HOST:-127.0.0.1}"
MYSQL_PORT="${MYSQL_PORT:-3306}"
DB="covid_pipeline"

MYSQL_CMD="mysql -h $MYSQL_HOST -P $MYSQL_PORT -u $MYSQL_USER -p$MYSQL_PASS $DB"

echo "==> Running COVID-19 Analytics Pipeline"
echo "    Host: $MYSQL_HOST:$MYSQL_PORT | DB: $DB"
echo ""

run_sql() {
    echo "--> $1"
    $MYSQL_CMD < "$1"
    echo "    done."
}

run_sql schema/00_create_database.sql
run_sql raw/01_raw_covid_cases.sql
run_sql raw/02_raw_vaccinations.sql
run_sql raw/03_raw_country_lookup.sql
run_sql staging/04_stg_cases.sql
run_sql staging/05_stg_vaccinations.sql
run_sql staging/06_stg_country_dim.sql
run_sql marts/07_mart_daily_trends.sql
run_sql marts/08_mart_country_summary.sql
run_sql marts/09_mart_wave_detection.sql
run_sql views/10_vw_global_trend.sql
run_sql views/11_vw_top_countries.sql
run_sql views/12_vw_vacc_vs_cases.sql

echo ""
echo "==> Pipeline complete. Run your sanity check:"
echo "    SELECT location, total_cases, case_fatality_rate"
echo "    FROM covid_pipeline.vw_top_countries"
echo "    ORDER BY total_cases DESC LIMIT 10;"
