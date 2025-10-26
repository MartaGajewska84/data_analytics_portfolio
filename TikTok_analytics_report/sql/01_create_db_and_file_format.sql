-- ==========================================================
-- File: 01_create_db_and_file_format.sql
-- Project: TikTok_analytics_report
-- Purpose:
--   • Create the project database and RAW schema
--   • Define a reusable CSV FILE FORMAT so Snowflake can parse
--     TikTok dataset correctly (header, quotes, NULLs, #N/A)
--
-- After running:
--   - Load tiktok_dataset.csv using this file format
--   - File format to select in Snowsight: RAW.TIKTOK_CSV_FORMAT
-- ==========================================================

-- ----------------------------------------------------------
-- 0) Create (or reuse) the project database
-- ----------------------------------------------------------
CREATE DATABASE IF NOT EXISTS TIKTOK_DB;
USE DATABASE TIKTOK_DB;

-- ----------------------------------------------------------
-- 1) Create RAW schema
--    RAW – landing zone for the original CSV data
-- ----------------------------------------------------------
CREATE SCHEMA IF NOT EXISTS RAW;

-- ----------------------------------------------------------
-- 2) Define the reusable CSV FILE FORMAT
--    Configuration details:
--      • FIELD_DELIMITER = ','       → standard comma-separated file
--      • SKIP_HEADER = 1             → first row contains column names
--      • FIELD_OPTIONALLY_ENCLOSED_BY = '"' → allows commas/newlines in quotes
--      • TRIM_SPACE = TRUE           → removes spaces around values
--      • NULL_IF = ('', 'NULL', '#N/A') → treats these as SQL NULLs
--      • EMPTY_FIELD_AS_NULL = TRUE  → empty fields become NULL
-- ----------------------------------------------------------
USE SCHEMA RAW;

CREATE OR REPLACE FILE FORMAT RAW.TIKTOK_CSV_FORMAT
  TYPE = CSV
  FIELD_DELIMITER = ','
  SKIP_HEADER = 1
  FIELD_OPTIONALLY_ENCLOSED_BY = '"'
  TRIM_SPACE = TRUE
  NULL_IF = ('', 'NULL', '#N/A')
  EMPTY_FIELD_AS_NULL = TRUE;

-- ----------------------------------------------------------
-- 3) (Optional) Verify the file format exists
-- ----------------------------------------------------------
-- SHOW FILE FORMATS IN SCHEMA RAW;

-- ----------------------------------------------------------
-- 📥 Next step (manual UI step in Snowsight):
--   1. Navigate to Data → TIKTOK_DB → RAW → Tables
--   2. Create the table structure (next script: 02_create_raw_table_and_clean_view.sql)
--   3. Click "Load Data"
--   4. Select File Format → RAW.TIKTOK_CSV_FORMAT ✅
--   5. Choose local CSV (tiktok_dataset.csv)
-- ----------------------------------------------------------

