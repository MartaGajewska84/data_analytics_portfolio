-- ==========================================================
-- File: 02_create_raw_table_and_clean_view.sql
-- Project: TikTok_analytics_report
-- Purpose:
--   • Create the RAW table structure to receive TikTok CSV data
--   • Create the DW schema 
--   • Define a cleaned view (DW.V_TIKTOK_CLEAN) that:
--       – Trims/normalizes text fields
--       – Converts numeric text to numbers
--       – Removes NULL or blank rows
--   • Run a quick sanity check to preview cleaned data
--
-- Prerequisites:
--   1. 01_create_db_and_file_format.sql has been executed
--   2. The CSV has been loaded into RAW.TIKTOK_RAW
-- ==========================================================

-- ----------------------------------------------------------
-- 0) Set database context
-- ----------------------------------------------------------
USE DATABASE TIKTOK_DB;

-- ----------------------------------------------------------
-- 1) Ensure required schemas exist
-- ----------------------------------------------------------
CREATE SCHEMA IF NOT EXISTS RAW;   -- already created, but safe to include
CREATE SCHEMA IF NOT EXISTS DW;    -- data warehouse / modeled layer

-- ----------------------------------------------------------
-- 2) RAW table definition
--    This table matches TikTok CSV structure exactly.
--    The data is loaded via Snowsight using:
--      File Format → RAW.TIKTOK_CSV_FORMAT
-- ----------------------------------------------------------
USE SCHEMA RAW;

CREATE OR REPLACE TABLE TIKTOK_RAW (
  ROW_NUM                  NUMBER,
  CLAIM_STATUS             VARCHAR,
  VIDEO_ID                 VARCHAR,
  VIDEO_DURATION_SEC       NUMBER,
  VIDEO_TRANSCRIPTION_TEXT VARCHAR,
  VERIFIED_STATUS          VARCHAR,
  AUTHOR_BAN_STATUS        VARCHAR,
  VIDEO_VIEW_COUNT         NUMBER,
  VIDEO_LIKE_COUNT         NUMBER,
  VIDEO_SHARE_COUNT        NUMBER,
  VIDEO_DOWNLOAD_COUNT     NUMBER,
  VIDEO_COMMENT_COUNT      NUMBER
);

-- ----------------------------------------------------------
-- 3) Create the cleaned data view in DW
--    Purpose:
--      • Standardize and clean up source data
--      • Filter out missing or invalid rows
--      • Ensure numeric columns are properly cast
-- ----------------------------------------------------------
USE SCHEMA DW;

CREATE OR REPLACE VIEW V_TIKTOK_CLEAN AS
SELECT
    ROW_NUM,
    CLAIM_STATUS,
    VIDEO_ID,
    VIDEO_DURATION_SEC,
    TRIM(VIDEO_TRANSCRIPTION_TEXT)            AS VIDEO_TRANSCRIPTION_TEXT,
    LOWER(TRIM(VERIFIED_STATUS))              AS VERIFIED_STATUS,
    LOWER(TRIM(AUTHOR_BAN_STATUS))            AS AUTHOR_BAN_STATUS,
    TRY_TO_NUMBER(VIDEO_VIEW_COUNT)           AS VIDEO_VIEW_COUNT,
    TRY_TO_NUMBER(VIDEO_LIKE_COUNT)           AS VIDEO_LIKE_COUNT,
    TRY_TO_NUMBER(VIDEO_SHARE_COUNT)          AS VIDEO_SHARE_COUNT,
    TRY_TO_NUMBER(VIDEO_DOWNLOAD_COUNT)       AS VIDEO_DOWNLOAD_COUNT,
    TRY_TO_NUMBER(VIDEO_COMMENT_COUNT)        AS VIDEO_COMMENT_COUNT
FROM TIKTOK_DB.RAW.TIKTOK_RAW
WHERE
    ROW_NUM IS NOT NULL
    AND CLAIM_STATUS IS NOT NULL AND TRIM(CLAIM_STATUS) <> ''
    AND VIDEO_ID IS NOT NULL AND TRIM(VIDEO_ID) <> ''
    AND VIDEO_DURATION_SEC IS NOT NULL
    AND VIDEO_TRANSCRIPTION_TEXT IS NOT NULL AND TRIM(VIDEO_TRANSCRIPTION_TEXT) <> ''
    AND VERIFIED_STATUS IS NOT NULL AND TRIM(VERIFIED_STATUS) <> ''
    AND AUTHOR_BAN_STATUS IS NOT NULL AND TRIM(AUTHOR_BAN_STATUS) <> ''
    AND TRY_TO_NUMBER(VIDEO_VIEW_COUNT)     IS NOT NULL
    AND TRY_TO_NUMBER(VIDEO_LIKE_COUNT)     IS NOT NULL
    AND TRY_TO_NUMBER(VIDEO_SHARE_COUNT)    IS NOT NULL
    AND TRY_TO_NUMBER(VIDEO_DOWNLOAD_COUNT) IS NOT NULL
    AND TRY_TO_NUMBER(VIDEO_COMMENT_COUNT)  IS NOT NULL
;

-- ----------------------------------------------------------
-- 4) Sanity check: Preview first few rows of clean data
-- ----------------------------------------------------------
SELECT *
FROM V_TIKTOK_CLEAN
LIMIT 10;

