-- ==========================================================
-- File: 03_create_star_schema.sql
-- Project: TikTok_analytics_report
-- Purpose:
--   • Define the dimensional (star schema) data model for TikTok analytics
--   • Create all dimension and fact tables under the DW schema
--
-- Model overview:
--   Grain: one row per video in FACT_VIDEO_ENGAGEMENT
--
--   DIM_VIDEO               – unique metadata per video
--   DIM_CLAIM_STATUS        – claim/opinion classification
--   DIM_VERIFIED_STATUS     – author verification (verified / not verified)
--   DIM_AUTHOR_BAN_STATUS   – author account ban state
--   FACT_VIDEO_ENGAGEMENT   – engagement metrics (views, likes, shares, etc.)
--
-- Prerequisites:
--   1. 01_create_db_and_file_format.sql (database + RAW schema)
--   2. 02_create_raw_table_and_clean_view.sql (cleaned view ready)
-- ==========================================================

-- ----------------------------------------------------------
-- 0) Set context: use the data warehouse schema
-- ----------------------------------------------------------
USE DATABASE TIKTOK_DB;
CREATE SCHEMA IF NOT EXISTS DW;
USE SCHEMA DW;

-- ----------------------------------------------------------
-- 1) Dimension: Video
--    Stores basic video-level metadata.
--    VIDEO_KEY is a surrogate key (auto-incremented)
--    VIDEO_ID is the natural key from source data.
-- ----------------------------------------------------------
CREATE OR REPLACE TABLE DIM_VIDEO (
  VIDEO_KEY                INTEGER IDENTITY(1,1) PRIMARY KEY,
  VIDEO_ID                 VARCHAR NOT NULL UNIQUE,
  VIDEO_DURATION_SEC       INTEGER,
  VIDEO_TRANSCRIPTION_TEXT VARCHAR
);

-- ----------------------------------------------------------
-- 2) Dimension: Claim Status
--    Describes whether a video contains a claim or an opinion.
-- ----------------------------------------------------------
CREATE OR REPLACE TABLE DIM_CLAIM_STATUS (
  CLAIM_STATUS_KEY INTEGER IDENTITY(1,1) PRIMARY KEY,
  CLAIM_STATUS     VARCHAR UNIQUE
);

-- ----------------------------------------------------------
-- 3) Dimension: Verified Status
--    Indicates if the video’s author is verified or not.
-- ----------------------------------------------------------
CREATE OR REPLACE TABLE DIM_VERIFIED_STATUS (
  VERIFIED_STATUS_KEY INTEGER IDENTITY(1,1) PRIMARY KEY,
  VERIFIED_STATUS     VARCHAR UNIQUE
);

-- ----------------------------------------------------------
-- 4) Dimension: Author Ban Status
--    Describes the current ban state of the author.
-- ----------------------------------------------------------
CREATE OR REPLACE TABLE DIM_AUTHOR_BAN_STATUS (
  AUTHOR_BAN_STATUS_KEY INTEGER IDENTITY(1,1) PRIMARY KEY,
  AUTHOR_BAN_STATUS     VARCHAR UNIQUE
);

-- ----------------------------------------------------------
-- 5) Fact: Video Engagement
--    Central table capturing all engagement metrics.
--    Each record links to dimension keys.
-- ----------------------------------------------------------
CREATE OR REPLACE TABLE FACT_VIDEO_ENGAGEMENT (
  VIDEO_KEY             INTEGER NOT NULL REFERENCES DIM_VIDEO(VIDEO_KEY),
  CLAIM_STATUS_KEY      INTEGER REFERENCES DIM_CLAIM_STATUS(CLAIM_STATUS_KEY),
  VERIFIED_STATUS_KEY   INTEGER REFERENCES DIM_VERIFIED_STATUS(VERIFIED_STATUS_KEY),
  AUTHOR_BAN_STATUS_KEY INTEGER REFERENCES DIM_AUTHOR_BAN_STATUS(AUTHOR_BAN_STATUS_KEY),
  VIDEO_VIEW_COUNT      INTEGER,
  VIDEO_LIKE_COUNT      INTEGER,
  VIDEO_SHARE_COUNT     INTEGER,
  VIDEO_DOWNLOAD_COUNT  INTEGER,
  VIDEO_COMMENT_COUNT   INTEGER,
  CONSTRAINT FACT_VIDEO_ENGAGEMENT_PK PRIMARY KEY (VIDEO_KEY)
);

-- ----------------------------------------------------------
-- ✅ Verification (optional)
-- ----------------------------------------------------------
-- SHOW TABLES IN SCHEMA DW;
-- DESC TABLE DIM_VIDEO;
-- DESC TABLE FACT_VIDEO_ENGAGEMENT;

