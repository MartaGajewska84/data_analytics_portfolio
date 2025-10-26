-- ==========================================================
-- File: 05_create_presentation_views.sql
-- Project: TikTok_analytics_report
-- Purpose:
--   • Create analytical views in the PRESENTATION schema
--   • These views will be used directly by Power BI visuals
--   • Each view represents a business question or chart
--
-- Prerequisites:
--   - 04_load_star_schema.sql successfully executed
-- ==========================================================

-- ----------------------------------------------------------
-- Set context
-- ----------------------------------------------------------
USE DATABASE TIKTOK_DB;
CREATE SCHEMA IF NOT EXISTS PRESENTATION;

-- ==========================================================
-- 🔹 1) Total number of videos
-- Purpose:
--   - Returns the total distinct number of videos in dataset.
--   - Used for a KPI card in Power BI.
-- Expected outcome:
--   - Single-row result with column TOTAL_VIDEOS.
-- ==========================================================
CREATE OR REPLACE VIEW PRESENTATION.VW_TOTAL_VIDEOS AS
SELECT COUNT(DISTINCT v.VIDEO_ID) AS TOTAL_VIDEOS
FROM DW.FACT_VIDEO_ENGAGEMENT f
JOIN DW.DIM_VIDEO v ON f.VIDEO_KEY = v.VIDEO_KEY;


-- ==========================================================
-- 🔹 2) Total views by claim status (Pie chart)
-- Purpose:
--   - Show the proportion of total video views by CLAIM_STATUS.
--   - Used for a pie chart visualization.
-- Expected outcome:
--   - Two rows: “claim” vs “opinion” (TOTAL_VIEWS, TOTAL_VIDEOS).
-- ==========================================================
CREATE OR REPLACE VIEW PRESENTATION.VW_TOTAL_VIEWS_BY_CLAIM AS
SELECT
    cs.CLAIM_STATUS,
    SUM(f.VIDEO_VIEW_COUNT) AS TOTAL_VIEWS,
    COUNT(f.VIDEO_KEY)      AS TOTAL_VIDEOS
FROM DW.FACT_VIDEO_ENGAGEMENT f
JOIN DW.DIM_CLAIM_STATUS cs
  ON cs.CLAIM_STATUS_KEY = f.CLAIM_STATUS_KEY
GROUP BY cs.CLAIM_STATUS;


-- ==========================================================
-- 🔹 3) Trends by author ban status
-- Purpose:
--   - Analyze the distribution of videos by AUTHOR_BAN_STATUS and CLAIM_STATUS.
--   - Used for a stacked bar.
-- Expected outcome:
--   - One row per combination of CLAIM_STATUS × AUTHOR_BAN_STATUS.
-- ==========================================================
CREATE OR REPLACE VIEW PRESENTATION.VW_TRENDS_AUTHOR_BAN AS
SELECT
    cs.CLAIM_STATUS,
    ab.AUTHOR_BAN_STATUS,
    COUNT(*) AS VIDEO_COUNT
FROM DW.FACT_VIDEO_ENGAGEMENT f
JOIN DW.DIM_CLAIM_STATUS cs        ON cs.CLAIM_STATUS_KEY        = f.CLAIM_STATUS_KEY
JOIN DW.DIM_AUTHOR_BAN_STATUS ab   ON ab.AUTHOR_BAN_STATUS_KEY   = f.AUTHOR_BAN_STATUS_KEY
GROUP BY cs.CLAIM_STATUS, ab.AUTHOR_BAN_STATUS;


-- ==========================================================
-- 🔹 4) Claim status × verification status
-- Purpose:
--   - Compare the number of videos for combinations of CLAIM_STATUS and VERIFIED_STATUS.
--   - Used for a matrix or grouped bar chart.
-- Expected outcome:
--   - One row per CLAIM_STATUS × VERIFIED_STATUS pair.
-- ==========================================================
CREATE OR REPLACE VIEW PRESENTATION.VW_CLAIM_VERIFICATION AS
SELECT
    cs.CLAIM_STATUS,
    vs.VERIFIED_STATUS,
    COUNT(*) AS VIDEO_COUNT
FROM DW.FACT_VIDEO_ENGAGEMENT f
JOIN DW.DIM_CLAIM_STATUS cs      ON cs.CLAIM_STATUS_KEY      = f.CLAIM_STATUS_KEY
JOIN DW.DIM_VERIFIED_STATUS vs   ON vs.VERIFIED_STATUS_KEY   = f.VERIFIED_STATUS_KEY
GROUP BY cs.CLAIM_STATUS, vs.VERIFIED_STATUS;


-- ==========================================================
-- 🔹 5) Like count distribution by author ban status
-- Purpose:
--   - Provides raw like counts per AUTHOR_BAN_STATUS for histogram binning in Power BI.
-- Expected outcome:
--   - One row per video (AUTHOR_BAN_STATUS, VIDEO_LIKE_COUNT).
-- ==========================================================
CREATE OR REPLACE VIEW PRESENTATION.VW_LIKE_COUNT_BY_AUTHOR_BAN AS
SELECT
    ab.AUTHOR_BAN_STATUS,
    f.VIDEO_LIKE_COUNT
FROM DW.FACT_VIDEO_ENGAGEMENT f
JOIN DW.DIM_AUTHOR_BAN_STATUS ab ON ab.AUTHOR_BAN_STATUS_KEY = f.AUTHOR_BAN_STATUS_KEY;


-- ==========================================================
-- 🔹 6) Likes for opinion videos (total)
-- Purpose:
--   - Calculate total likes for videos with CLAIM_STATUS = 'opinion'.
--   - Used for KPI comparison.
-- Expected outcome:
--   - Single row with TOTAL_LIKES for opinion videos.
-- ==========================================================
CREATE OR REPLACE VIEW PRESENTATION.VW_OPINION_LIKES AS
SELECT
    cs.CLAIM_STATUS,
    SUM(f.VIDEO_LIKE_COUNT) AS TOTAL_LIKES
FROM DW.FACT_VIDEO_ENGAGEMENT f
JOIN DW.DIM_CLAIM_STATUS cs ON cs.CLAIM_STATUS_KEY = f.CLAIM_STATUS_KEY
WHERE cs.CLAIM_STATUS = 'opinion'
GROUP BY cs.CLAIM_STATUS;


-- ==========================================================
-- 🔹 7) Likes for claim videos (total)
-- Purpose:
--   - Calculate total likes for videos with CLAIM_STATUS = 'claim'.
--   - Used for KPI comparison.
-- Expected outcome:
--   - Single row with TOTAL_LIKES for claim videos.
-- ==========================================================
CREATE OR REPLACE VIEW PRESENTATION.VW_CLAIM_LIKES AS
SELECT
    cs.CLAIM_STATUS,
    SUM(f.VIDEO_LIKE_COUNT) AS TOTAL_LIKES
FROM DW.FACT_VIDEO_ENGAGEMENT f
JOIN DW.DIM_CLAIM_STATUS cs ON cs.CLAIM_STATUS_KEY = f.CLAIM_STATUS_KEY
WHERE cs.CLAIM_STATUS = 'claim'
GROUP BY cs.CLAIM_STATUS;


-- ==========================================================
-- 🔹 8) Comments for opinion videos (total)
-- Purpose:
--   - Calculate total comment counts for videos with CLAIM_STATUS = 'opinion'.
--   - Used for KPI card.
-- Expected outcome:
--   - Single row with TOTAL_COMMENTS for opinion videos.
-- ==========================================================
CREATE OR REPLACE VIEW PRESENTATION.VW_OPINION_COMMENTS AS
SELECT
    cs.CLAIM_STATUS,
    SUM(f.VIDEO_COMMENT_COUNT) AS TOTAL_COMMENTS
FROM DW.FACT_VIDEO_ENGAGEMENT f
JOIN DW.DIM_CLAIM_STATUS cs ON cs.CLAIM_STATUS_KEY = f.CLAIM_STATUS_KEY
WHERE cs.CLAIM_STATUS = 'opinion'
GROUP BY cs.CLAIM_STATUS;


-- ==========================================================
-- 🔹 9) Comments for claim videos (total)
-- Purpose:
--   - Calculate total comment counts for videos with CLAIM_STATUS = 'claim'.
--   - Used for KPI card.
-- Expected outcome:
--   - Single row with TOTAL_COMMENTS for claim videos.
-- ==========================================================
CREATE OR REPLACE VIEW PRESENTATION.VW_CLAIM_COMMENTS AS
SELECT
    cs.CLAIM_STATUS,
    SUM(f.VIDEO_COMMENT_COUNT) AS TOTAL_COMMENTS
FROM DW.FACT_VIDEO_ENGAGEMENT f
JOIN DW.DIM_CLAIM_STATUS cs ON cs.CLAIM_STATUS_KEY = f.CLAIM_STATUS_KEY
WHERE cs.CLAIM_STATUS = 'claim'
GROUP BY cs.CLAIM_STATUS;

