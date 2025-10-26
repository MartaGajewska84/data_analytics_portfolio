-- ==========================================================
-- File: 04_load_star_schema.sql
-- Project: TikTok_analytics_report
-- Purpose:
--   • Populate the dimensional star schema from the cleaned view (DW.V_TIKTOK_CLEAN)
--   • Refresh dimension and fact tables using MERGE and INSERT logic
--   • Perform validation and data quality checks
--
-- Model overview:
--   DIM_VIDEO, DIM_CLAIM_STATUS, DIM_VERIFIED_STATUS, DIM_AUTHOR_BAN_STATUS
--   FACT_VIDEO_ENGAGEMENT
--
-- Prerequisites:
--   1. 01_create_db_and_file_format.sql
--   2. 02_create_raw_table_and_clean_view.sql
--   3. 03_create_star_schema.sql
-- ==========================================================

-- ----------------------------------------------------------
-- Set context
-- ----------------------------------------------------------
USE DATABASE TIKTOK_DB;
USE SCHEMA DW;

-- ----------------------------------------------------------
-- Populate dimension tables from the cleaned view
-- ----------------------------------------------------------

-- DIM_CLAIM_STATUS
MERGE INTO DW.DIM_CLAIM_STATUS d
USING (
  SELECT DISTINCT CLAIM_STATUS
  FROM TIKTOK_DB.DW.V_TIKTOK_CLEAN
  WHERE CLAIM_STATUS IS NOT NULL
) s
ON d.CLAIM_STATUS = s.CLAIM_STATUS
WHEN NOT MATCHED THEN
  INSERT (CLAIM_STATUS) VALUES (s.CLAIM_STATUS);

-- DIM_VERIFIED_STATUS
MERGE INTO DW.DIM_VERIFIED_STATUS d
USING (
  SELECT DISTINCT VERIFIED_STATUS
  FROM TIKTOK_DB.DW.V_TIKTOK_CLEAN
  WHERE VERIFIED_STATUS IS NOT NULL
) s
ON d.VERIFIED_STATUS = s.VERIFIED_STATUS
WHEN NOT MATCHED THEN
  INSERT (VERIFIED_STATUS) VALUES (s.VERIFIED_STATUS);

-- DIM_AUTHOR_BAN_STATUS
MERGE INTO DW.DIM_AUTHOR_BAN_STATUS d
USING (
  SELECT DISTINCT AUTHOR_BAN_STATUS
  FROM TIKTOK_DB.DW.V_TIKTOK_CLEAN
  WHERE AUTHOR_BAN_STATUS IS NOT NULL
) s
ON d.AUTHOR_BAN_STATUS = s.AUTHOR_BAN_STATUS
WHEN NOT MATCHED THEN
  INSERT (AUTHOR_BAN_STATUS) VALUES (s.AUTHOR_BAN_STATUS);

-- DIM_VIDEO
MERGE INTO DW.DIM_VIDEO d
USING (
  SELECT
    VIDEO_ID,
    ANY_VALUE(VIDEO_DURATION_SEC)       AS VIDEO_DURATION_SEC,
    ANY_VALUE(VIDEO_TRANSCRIPTION_TEXT) AS VIDEO_TRANSCRIPTION_TEXT
  FROM TIKTOK_DB.DW.V_TIKTOK_CLEAN
  WHERE VIDEO_ID IS NOT NULL
  GROUP BY VIDEO_ID
) s
ON d.VIDEO_ID = s.VIDEO_ID
WHEN MATCHED AND (
     NVL(d.VIDEO_DURATION_SEC, -1) <> NVL(s.VIDEO_DURATION_SEC, -1)
  OR NVL(d.VIDEO_TRANSCRIPTION_TEXT, '') <> NVL(s.VIDEO_TRANSCRIPTION_TEXT, '')
) THEN UPDATE SET
  VIDEO_DURATION_SEC       = s.VIDEO_DURATION_SEC,
  VIDEO_TRANSCRIPTION_TEXT = s.VIDEO_TRANSCRIPTION_TEXT
WHEN NOT MATCHED THEN
  INSERT (VIDEO_ID, VIDEO_DURATION_SEC, VIDEO_TRANSCRIPTION_TEXT)
  VALUES (s.VIDEO_ID, s.VIDEO_DURATION_SEC, s.VIDEO_TRANSCRIPTION_TEXT);

-- ----------------------------------------------------------
-- Populate fact table
--    (INSERT only — append new engagement rows)
-- ----------------------------------------------------------
INSERT INTO DW.FACT_VIDEO_ENGAGEMENT (
  VIDEO_KEY,
  CLAIM_STATUS_KEY,
  VERIFIED_STATUS_KEY,
  AUTHOR_BAN_STATUS_KEY,
  VIDEO_VIEW_COUNT,
  VIDEO_LIKE_COUNT,
  VIDEO_SHARE_COUNT,
  VIDEO_DOWNLOAD_COUNT,
  VIDEO_COMMENT_COUNT
)
SELECT
  v.VIDEO_KEY,
  cs.CLAIM_STATUS_KEY,
  vs.VERIFIED_STATUS_KEY,
  ab.AUTHOR_BAN_STATUS_KEY,
  c.VIDEO_VIEW_COUNT::INTEGER,
  c.VIDEO_LIKE_COUNT::INTEGER,
  c.VIDEO_SHARE_COUNT::INTEGER,
  c.VIDEO_DOWNLOAD_COUNT::INTEGER,
  c.VIDEO_COMMENT_COUNT::INTEGER
FROM TIKTOK_DB.DW.V_TIKTOK_CLEAN c
JOIN DW.DIM_VIDEO v
  ON v.VIDEO_ID = c.VIDEO_ID
LEFT JOIN DW.DIM_CLAIM_STATUS cs
  ON cs.CLAIM_STATUS = c.CLAIM_STATUS
LEFT JOIN DW.DIM_VERIFIED_STATUS vs
  ON vs.VERIFIED_STATUS = c.VERIFIED_STATUS
LEFT JOIN DW.DIM_AUTHOR_BAN_STATUS ab
  ON ab.AUTHOR_BAN_STATUS = c.AUTHOR_BAN_STATUS;

-- ==========================================================
-- 🔍 VALIDATION & DATA QUALITY TESTS
-- ==========================================================

-- ----------------------------------------------------------
-- ✅ Validation – row counts per table
-- Purpose:
--   - Ensure all dimension and fact tables contain records.
--   - Confirms that data successfully loaded from the cleaned view.
-- Expected outcome:
--   - Each dimension table has at least one row.
--   - FACT_VIDEO_ENGAGEMENT has the same number of rows as in the cleaned view.
-- ----------------------------------------------------------

SELECT 'DIM_CLAIM_STATUS'      AS TABLE_NAME, COUNT(*) AS ROW_COUNT FROM DW.DIM_CLAIM_STATUS
UNION ALL
SELECT 'DIM_VERIFIED_STATUS',  COUNT(*) FROM DW.DIM_VERIFIED_STATUS
UNION ALL
SELECT 'DIM_AUTHOR_BAN_STATUS',COUNT(*) FROM DW.DIM_AUTHOR_BAN_STATUS
UNION ALL
SELECT 'DIM_VIDEO',            COUNT(*) FROM DW.DIM_VIDEO
UNION ALL
SELECT 'FACT_VIDEO_ENGAGEMENT',COUNT(*) FROM DW.FACT_VIDEO_ENGAGEMENT;

-- ----------------------------------------------------------
-- ✅ Referential integrity checks – missing foreign keys
-- Purpose:
--   - Verify all FACT table foreign key columns have matching values in dimensions.
--   - Detect any orphan records or lookup mismatches.
-- Expected outcome:
--   - Each query should return a count of 0 (no missing keys).
-- ----------------------------------------------------------

-- Missing VIDEO_KEY
SELECT COUNT(*) AS missing_video_keys
FROM DW.FACT_VIDEO_ENGAGEMENT f
LEFT JOIN DW.DIM_VIDEO v ON v.VIDEO_KEY = f.VIDEO_KEY
WHERE v.VIDEO_KEY IS NULL;

-- Missing CLAIM_STATUS_KEY
SELECT COUNT(*) AS missing_claim_keys
FROM DW.FACT_VIDEO_ENGAGEMENT f
LEFT JOIN DW.DIM_CLAIM_STATUS c ON c.CLAIM_STATUS_KEY = f.CLAIM_STATUS_KEY
WHERE c.CLAIM_STATUS_KEY IS NULL;

-- Missing VERIFIED_STATUS_KEY
SELECT COUNT(*) AS missing_verified_keys
FROM DW.FACT_VIDEO_ENGAGEMENT f
LEFT JOIN DW.DIM_VERIFIED_STATUS v ON v.VERIFIED_STATUS_KEY = f.VERIFIED_STATUS_KEY
WHERE v.VERIFIED_STATUS_KEY IS NULL;

-- Missing AUTHOR_BAN_STATUS_KEY
SELECT COUNT(*) AS missing_author_ban_keys
FROM DW.FACT_VIDEO_ENGAGEMENT f
LEFT JOIN DW.DIM_AUTHOR_BAN_STATUS a ON a.AUTHOR_BAN_STATUS_KEY = f.AUTHOR_BAN_STATUS_KEY
WHERE a.AUTHOR_BAN_STATUS_KEY IS NULL;

-- ----------------------------------------------------------
-- ✅ Uniqueness – each natural key should appear only once
-- Purpose:
--   - Ensure dimension tables have no duplicate natural keys.
--   - Detect accidental duplicate inserts.
-- Expected outcome:
--   - All returned duplicate counts should be 0.
-- ----------------------------------------------------------

SELECT 'DIM_VIDEO' AS TABLE_NAME, COUNT(*) AS duplicates
FROM (
  SELECT VIDEO_ID
  FROM DW.DIM_VIDEO
  GROUP BY VIDEO_ID
  HAVING COUNT(*) > 1
)
GROUP BY 1
UNION ALL
SELECT 'DIM_CLAIM_STATUS', COUNT(*) FROM (
  SELECT CLAIM_STATUS FROM DW.DIM_CLAIM_STATUS GROUP BY CLAIM_STATUS HAVING COUNT(*) > 1
)
UNION ALL
SELECT 'DIM_VERIFIED_STATUS', COUNT(*) FROM (
  SELECT VERIFIED_STATUS FROM DW.DIM_VERIFIED_STATUS GROUP BY VERIFIED_STATUS HAVING COUNT(*) > 1
)
UNION ALL
SELECT 'DIM_AUTHOR_BAN_STATUS', COUNT(*) FROM (
  SELECT AUTHOR_BAN_STATUS FROM DW.DIM_AUTHOR_BAN_STATUS GROUP BY AUTHOR_BAN_STATUS HAVING COUNT(*) > 1
);

-- ----------------------------------------------------------
-- ✅ Sanity check – numeric columns should be non-negative
-- Purpose:
--   - Validate that engagement metrics (views, likes, etc.) contain only valid (>= 0) values.
-- Expected outcome:
--   - All returned values should be 0 (no negative counts).
-- ----------------------------------------------------------

SELECT
  SUM(IFF(VIDEO_VIEW_COUNT < 0,1,0))     AS neg_views,
  SUM(IFF(VIDEO_LIKE_COUNT < 0,1,0))     AS neg_likes,
  SUM(IFF(VIDEO_SHARE_COUNT < 0,1,0))    AS neg_shares,
  SUM(IFF(VIDEO_DOWNLOAD_COUNT < 0,1,0)) AS neg_downloads,
  SUM(IFF(VIDEO_COMMENT_COUNT < 0,1,0))  AS neg_comments
FROM DW.FACT_VIDEO_ENGAGEMENT;

-- ----------------------------------------------------------
-- ✅ Aggregation check – sample analytical summary
-- Purpose:
--   - Quick business-level validation of data correctness.
--   - Confirms meaningful averages and groupings.
-- Expected outcome:
--   - Returns aggregated metrics by claim, verification, and author ban status.
--   - Average views, likes, and shares should look plausible (non-null, non-negative).
-- ----------------------------------------------------------

SELECT
  cs.CLAIM_STATUS,
  vs.VERIFIED_STATUS,
  ab.AUTHOR_BAN_STATUS,
  COUNT(*) AS video_count,
  AVG(f.VIDEO_VIEW_COUNT)  AS avg_views,
  AVG(f.VIDEO_LIKE_COUNT)  AS avg_likes,
  AVG(f.VIDEO_SHARE_COUNT) AS avg_shares
FROM DW.FACT_VIDEO_ENGAGEMENT f
JOIN DW.DIM_CLAIM_STATUS cs      ON cs.CLAIM_STATUS_KEY = f.CLAIM_STATUS_KEY
JOIN DW.DIM_VERIFIED_STATUS vs   ON vs.VERIFIED_STATUS_KEY = f.VERIFIED_STATUS_KEY
JOIN DW.DIM_AUTHOR_BAN_STATUS ab ON ab.AUTHOR_BAN_STATUS_KEY = f.AUTHOR_BAN_STATUS_KEY
GROUP BY 1,2,3
ORDER BY video_count DESC;

