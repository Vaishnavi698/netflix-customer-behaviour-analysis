-- ============================================================
-- NETFLIX CUSTOMER BEHAVIOUR ANALYTICS
-- 08 - FUNNEL ANALYSIS
-- ============================================================
--
-- Purpose:
-- Analyze the customer journey from content discovery
-- to content completion.
--
-- Funnel:
-- Impression
--     ↓
-- Click
--     ↓
-- Watch Start
--     ↓
-- Completion
--
-- Main KPIs:
-- - CTR
-- - Click-to-Start %
-- - Start-to-Completion %
-- - Overall Impression-to-Completion %
--
-- Important:
-- This dataset is synthetic. Results are for portfolio/
-- analytical demonstration, not real Netflix decisions.
-- ============================================================


-- ============================================================
-- 1. OVERALL CONTENT FUNNEL
--
-- Measures the complete content journey.
-- ============================================================

SELECT
    COUNT(
        CASE
            WHEN event_type = 'content_impression'
            THEN 1
        END
    ) AS impressions,

    COUNT(
        CASE
            WHEN event_type = 'content_click'
            THEN 1
        END
    ) AS clicks,

    COUNT(
        CASE
            WHEN event_type = 'watch_start'
            THEN 1
        END
    ) AS watch_starts,

    COUNT(
        CASE
            WHEN event_type = 'watch_complete'
            THEN 1
        END
    ) AS completions

FROM events;


-- ============================================================
-- 2. FUNNEL CONVERSION RATES
--
-- CTR:
-- Clicks / Impressions
--
-- Click-to-Start:
-- Watch Starts / Clicks
--
-- Start-to-Completion:
-- Completions / Watch Starts
--
-- Overall Conversion:
-- Completions / Impressions
-- ============================================================

WITH funnel AS (
    SELECT

        COUNT(
            CASE
                WHEN event_type = 'content_impression'
                THEN 1
            END
        ) AS impressions,

        COUNT(
            CASE
                WHEN event_type = 'content_click'
                THEN 1
            END
        ) AS clicks,

        COUNT(
            CASE
                WHEN event_type = 'watch_start'
                THEN 1
            END
        ) AS watch_starts,

        COUNT(
            CASE
                WHEN event_type = 'watch_complete'
                THEN 1
            END
        ) AS completions

    FROM events
)

SELECT

    impressions,
    clicks,
    watch_starts,
    completions,

    ROUND(
        100.0 * clicks
        / NULLIF(impressions, 0),
        2
    ) AS ctr_pct,

    ROUND(
        100.0 * watch_starts
        / NULLIF(clicks, 0),
        2
    ) AS click_to_start_pct,

    ROUND(
        100.0 * completions
        / NULLIF(watch_starts, 0),
        2
    ) AS start_to_completion_pct,

    ROUND(
        100.0 * completions
        / NULLIF(impressions, 0),
        2
    ) AS impression_to_completion_pct

FROM funnel;


-- ============================================================
-- 3. FUNNEL BY DEVICE
--
-- Helps identify whether customer behaviour differs
-- across devices.
-- ============================================================

WITH funnel AS (
    SELECT
        s.device,

        COUNT(
            CASE
                WHEN e.event_type = 'content_impression'
                THEN 1
            END
        ) AS impressions,

        COUNT(
            CASE
                WHEN e.event_type = 'content_click'
                THEN 1
            END
        ) AS clicks,

        COUNT(
            CASE
                WHEN e.event_type = 'watch_start'
                THEN 1
            END
        ) AS watch_starts,

        COUNT(
            CASE
                WHEN e.event_type = 'watch_complete'
                THEN 1
            END
        ) AS completions

    FROM events e

    JOIN sessions s
        ON e.session_id = s.session_id

    GROUP BY
        s.device
)

SELECT

    device,

    impressions,
    clicks,
    watch_starts,
    completions,

    ROUND(
        100.0 * clicks
        / NULLIF(impressions, 0),
        2
    ) AS ctr_pct,

    ROUND(
        100.0 * watch_starts
        / NULLIF(clicks, 0),
        2
    ) AS click_to_start_pct,

    ROUND(
        100.0 * completions
        / NULLIF(watch_starts, 0),
        2
    ) AS start_to_completion_pct,

    ROUND(
        100.0 * completions
        / NULLIF(impressions, 0),
        2
    ) AS impression_to_completion_pct

FROM funnel

ORDER BY
    ctr_pct DESC;


-- ============================================================
-- 4. FUNNEL BY PLATFORM
--
-- Compares behaviour across web/mobile/TV platforms.
-- ============================================================

WITH funnel AS (
    SELECT
        s.platform,

        COUNT(
            CASE
                WHEN e.event_type = 'content_impression'
                THEN 1
            END
        ) AS impressions,

        COUNT(
            CASE
                WHEN e.event_type = 'content_click'
                THEN 1
            END
        ) AS clicks,

        COUNT(
            CASE
                WHEN e.event_type = 'watch_start'
                THEN 1
            END
        ) AS watch_starts,

        COUNT(
            CASE
                WHEN e.event_type = 'watch_complete'
                THEN 1
            END
        ) AS completions

    FROM events e

    JOIN sessions s
        ON e.session_id = s.session_id

    GROUP BY
        s.platform
)

SELECT

    platform,

    impressions,
    clicks,
    watch_starts,
    completions,

    ROUND(
        100.0 * clicks
        / NULLIF(impressions, 0),
        2
    ) AS ctr_pct,

    ROUND(
        100.0 * watch_starts
        / NULLIF(clicks, 0),
        2
    ) AS click_to_start_pct,

    ROUND(
        100.0 * completions
        / NULLIF(watch_starts, 0),
        2
    ) AS start_to_completion_pct,

    ROUND(
        100.0 * completions
        / NULLIF(impressions, 0),
        2
    ) AS impression_to_completion_pct

FROM funnel

ORDER BY
    ctr_pct DESC;


-- ============================================================
-- 5. RECOMMENDATION FUNNEL
--
-- Uses the recommendations table directly.
--
-- Funnel:
-- Impression → Click → Watch Start → Completion
-- ============================================================

SELECT

    SUM(impression) AS impressions,

    SUM(clicked) AS clicks,

    SUM(watch_started) AS watch_starts,

    SUM(watch_completed) AS completions,

    ROUND(
        100.0 * SUM(clicked)
        / NULLIF(SUM(impression), 0),
        2
    ) AS ctr_pct,

    ROUND(
        100.0 * SUM(watch_started)
        / NULLIF(SUM(clicked), 0),
        2
    ) AS click_to_start_pct,

    ROUND(
        100.0 * SUM(watch_completed)
        / NULLIF(SUM(watch_started), 0),
        2
    ) AS start_to_completion_pct,

    ROUND(
        100.0 * SUM(watch_completed)
        / NULLIF(SUM(impression), 0),
        2
    ) AS impression_to_completion_pct

FROM recommendations;


-- ============================================================
-- 6. RECOMMENDATION FUNNEL BY POSITION
--
-- Helps determine whether recommendation placement
-- affects user engagement.
-- ============================================================

SELECT

    position,

    COUNT(*) AS impressions,

    SUM(clicked) AS clicks,

    SUM(watch_started) AS watch_starts,

    SUM(watch_completed) AS completions,

    ROUND(
        100.0 * SUM(clicked)
        / NULLIF(COUNT(*), 0),
        2
    ) AS ctr_pct,

    ROUND(
        100.0 * SUM(watch_started)
        / NULLIF(SUM(clicked), 0),
        2
    ) AS click_to_start_pct,

    ROUND(
        100.0 * SUM(watch_completed)
        / NULLIF(SUM(watch_started), 0),
        2
    ) AS start_to_completion_pct

FROM recommendations

GROUP BY
    position

ORDER BY
    position;


-- ============================================================
-- 7. RECOMMENDATION FUNNEL BY TYPE
--
-- Compares recommendation strategies.
-- ============================================================

SELECT

    recommendation_type,

    COUNT(*) AS impressions,

    SUM(clicked) AS clicks,

    SUM(watch_started) AS watch_starts,

    SUM(watch_completed) AS completions,

    ROUND(
        100.0 * SUM(clicked)
        / NULLIF(COUNT(*), 0),
        2
    ) AS ctr_pct,

    ROUND(
        100.0 * SUM(watch_started)
        / NULLIF(SUM(clicked), 0),
        2
    ) AS click_to_start_pct,

    ROUND(
        100.0 * SUM(watch_completed)
        / NULLIF(SUM(watch_started), 0),
        2
    ) AS start_to_completion_pct

FROM recommendations

GROUP BY
    recommendation_type

ORDER BY
    ctr_pct DESC;


-- ============================================================
-- 8. FUNNEL BY SUBSCRIPTION PLAN
--
-- Connects customer journey performance with plan type.
-- ============================================================

WITH funnel AS (
    SELECT
        u.subscription_plan,

        COUNT(
            CASE
                WHEN e.event_type = 'content_impression'
                THEN 1
            END
        ) AS impressions,

        COUNT(
            CASE
                WHEN e.event_type = 'content_click'
                THEN 1
    
            END
        ) AS clicks,

        COUNT(
            CASE
                WHEN e.event_type = 'watch_start'
                THEN 1
            END
        ) AS watch_starts,

        COUNT(
            CASE
                WHEN e.event_type = 'watch_complete'
                THEN 1
            END
        ) AS completions

    FROM events e

    JOIN users u
        ON e.user_id = u.user_id

    GROUP BY
        u.subscription_plan
)

SELECT

    subscription_plan,

    impressions,
    clicks,
    watch_starts,
    completions,

    ROUND(
        100.0 * clicks
        / NULLIF(impressions, 0),
        2
    ) AS ctr_pct,

    ROUND(
        100.0 * watch_starts
        / NULLIF(clicks, 0),
        2
    ) AS click_to_start_pct,

    ROUND(
        100.0 * completions
        / NULLIF(watch_starts, 0),
        2
    ) AS start_to_completion_pct,

    ROUND(
        100.0 * completions
        / NULLIF(impressions, 0),
        2
    ) AS impression_to_completion_pct

FROM funnel

ORDER BY
    ctr_pct DESC;


-- ============================================================
-- 9. FUNNEL BY ENGAGEMENT SEGMENT
--
-- Identifies differences in content journey behaviour
-- across customer engagement segments.
-- ============================================================

WITH funnel AS (
    SELECT
        u.engagement_segment,

        COUNT(
            CASE
                WHEN e.event_type = 'content_impression'
                THEN 1
            END
        ) AS impressions,

        COUNT(
            CASE
                WHEN e.event_type = 'content_click'
                THEN 1
            END
        ) AS clicks,

        COUNT(
            CASE
                WHEN e.event_type = 'watch_start'
                THEN 1
            END
        ) AS watch_starts,

        COUNT(
            CASE
                WHEN e.event_type = 'watch_complete'
                THEN 1
            END
        ) AS completions

    FROM events e

    JOIN users u
        ON e.user_id = u.user_id

    GROUP BY
        u.engagement_segment
)

SELECT

    engagement_segment,

    impressions,
    clicks,
    watch_starts,
    completions,

    ROUND(
        100.0 * clicks
        / NULLIF(impressions, 0),
        2
    ) AS ctr_pct,

    ROUND(
        100.0 * watch_starts
        / NULLIF(clicks, 0),
        2
    ) AS click_to_start_pct,

    ROUND(
        100.0 * completions
        / NULLIF(watch_starts, 0),
        2
    ) AS start_to_completion_pct,

    ROUND(
        100.0 * completions
        / NULLIF(impressions, 0),
        2
    ) AS impression_to_completion_pct

FROM funnel

ORDER BY
    ctr_pct DESC;