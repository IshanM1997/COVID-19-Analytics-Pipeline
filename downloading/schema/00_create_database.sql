-- =============================================================
-- 00_create_database.sql
-- Run this first. Creates the database and a dedicated user.
-- =============================================================

CREATE DATABASE IF NOT EXISTS covid_pipeline
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

USE covid_pipeline;

-- Create a dedicated user (optional but good practice)
-- Change the password before use in any non-local environment.
CREATE USER IF NOT EXISTS 'covid_user'@'localhost' IDENTIFIED BY 'Covid@Pipeline1';
GRANT ALL PRIVILEGES ON covid_pipeline.* TO 'covid_user'@'localhost';
FLUSH PRIVILEGES;

SELECT 'Database covid_pipeline created successfully.' AS status;
