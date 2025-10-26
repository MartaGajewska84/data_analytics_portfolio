-- ==========================================================
-- File: 01_create_db_raw_and_clean_view.sql
-- Purpose:
--   1) Create the project database and RAW/DW schemas
--   2) Create the RAW landing table for the CSV file
--   3) Create a cleaned DW view (null-free, typed/normalized)
--   4) Sanity-check the cleaned view
-- Notes:
--   - Run this in Snowsight (or SnowSQL) before loading/pipelines
--   - The RAW table is empty after creation; load your CSV into it
-- ==========================================================

-- ----------------------------------------------------------
-- 0) Create (or reuse) the database for the project
-- ----------------------------------------------------------
CREATE DATABASE IF NOT EXISTS TIKTOK_DB;

-- Always work in this database for the rest of the script
USE DATABASE TIKTOK_DB;

-- ----------------------------------------------------------
-- 1) Schemas: RAW (landing) and DW (modeled)
-- ----------------------------------------------------------
CREATE SCHEMA IF NOT EXISTS RAW;   -- landing zone for raw CSV
CREATE SCHEMA IF NOT EXISTS DW;    -- data warehouse / modeled layer

-- Set current schema to RAW to create the landing table
USE SCHEMA RAW;

-- ----------------------------------------------------------
-- 2) RAW table definition (structure matches the CSV columns)
--    Load your CSV into this table via Snowsight "Load Data"
-- ----------------------------------------------------------
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
-- 3) Cleaned view in DW schema
--    - trims/normalizes text columns
--    - safely casts numerics with TRY_TO_NUMBER
--    - filters out any rows that end up NULL/blank after cleaning
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
-- 4) Quick sanity check of the cleaned view
-- ----------------------------------------------------------
SELECT *
FROM V_TIKTOK_CLEAN
LIMIT 10;

