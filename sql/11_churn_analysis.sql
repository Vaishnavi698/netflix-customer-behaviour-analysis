-- ============================================================
-- NETFLIX CUSTOMER BEHAVIOUR ANALYTICS
-- 11 - CHURN ANALYSIS
-- ============================================================
--
-- Purpose:
-- Analyze customer cancellation behaviour and identify
-- engagement patterns associated with churn.
--
-- Main questions:
-- 1. How much churn exists?
-- 2. Which customer segments have higher churn?
-- 3. Does engagement differ between churned and active users?
-- 4. How does churn vary by subscription plan?
-- 5. What behaviour is visible before cancellation?
--
-- Important:
-- This dataset is synthetic. Results are for portfolio/
-- analytical demonstration, not real Netflix decisions.
-- ============================================================


-- ============================================================
-- 1. OVERALL CHURN RATE
--
-- Churn rate =
-- Cancelled users / Total users
-- ============================================================

SELECT

    COUNT(*) AS total_users,

    SUM(
        CASE
            WHEN status = 'cancelled'
            THEN 1
            ELSE 0
        END
    ) AS cancelled_users,

    ROUND(
        100.0 *
        SUM(
            CASE
                WHEN status = 'cancelled'
                THEN 1
                ELSE 0
            END
        )
        / NULLIF(COUNT(*), 0),
        2
    ) AS churn_rate_pct

FROM subscriptions;


-- ============================================================
-- 2. CHURN BY SUBSCRIPTION PLAN
-- ============================================================

SELECT

    plan,

    COUNT(*) AS users,

    SUM(
        CASE
            WHEN status = 'cancelled'
            THEN 1
            ELSE 0
        END
    ) AS cancelled_users,

    ROUND(
        100.0 *
        SUM(
            CASE
                WHEN status = 'cancelled'
                THEN 1
                ELSE 0
            END
        )
        / NULLIF(COUNT(*), 0),
        2
    ) AS churn_rate_pct

FROM subscriptions

GROUP BY
    plan

ORDER BY
    churn_rate_pct DESC;


-- ============================================================
-- 3. CHURN BY ENGAGEMENT SEGMENT
-- ============================================================

SELECT

    u.engagement_segment,

    COUNT(*) AS users,

    SUM(
        CASE
            WHEN s.status = 'cancelled'
            THEN 1
            ELSE 0
        END
    ) AS cancelled_users,

    ROUND(
        100.0 *
        SUM(
            CASE
                WHEN s.status = 'cancelled'
                THEN 1
                ELSE 0
            END
        )
        / NULLIF(COUNT(*), 0),
        2
    ) AS churn_rate_pct

FROM users u

JOIN subscriptions s
    ON u.user_id = s.user_id

GROUP BY
    u.engagement_segment

ORDER BY
    churn_rate_pct DESC;


-- ============================================================
-- 4. CHURN BY ACQUISITION CHANNEL
-- ============================================================

SELECT

    u.acquisition_channel,

    COUNT(*) AS users,

    SUM(
        CASE
            WHEN s.status = 'cancelled'
            THEN 1
            ELSE 0
        END
    ) AS cancelled_users,

    ROUND(
        100.0 *
        SUM(
            CASE
                WHEN s.status = 'cancelled'
                THEN 1
                ELSE 0
            END
        )
        / NULLIF(COUNT(*), 0),
        2
    ) AS churn_rate_pct

FROM users u

JOIN subscriptions s
    ON u.user_id = s.user_id

GROUP BY
    u.acquisition_channel

ORDER BY
    churn_rate_pct DESC;


-- ============================================================
-- 5. CHURN BY DEVICE
-- ============================================================

SELECT

    u.device_primary,

    COUNT(*) AS users,

    SUM(
        CASE
            WHEN s.status = 'cancelled'
            THEN 1
            ELSE 0
        END
    ) AS cancelled_users,

    ROUND(
        100.0 *
        SUM(
            CASE
                WHEN s.status = 'cancelled'
                THEN 1
                ELSE 0
            END
        )
        / NULLIF(COUNT(*), 0),
        2
    ) AS churn_rate_pct

FROM users u

JOIN subscriptions s
    ON u.user_id = s.user_id

GROUP BY
    u.device_primary

ORDER BY
    churn_rate_pct DESC;


-- ============================================================
-- 6. CHURN BY CANCELLATION REASON
--
-- Only cancelled subscriptions are included.
-- ============================================================

SELECT

    cancellation_reason,

    COUNT(*) AS cancelled_users,

    ROUND(
        100.0 * COUNT(*)
        / SUM(COUNT(*)) OVER (),
        2
    ) AS share_of_cancellations_pct

FROM subscriptions

WHERE status = 'cancelled'

GROUP BY
    cancellation_reason

ORDER BY
    cancelled_users DESC;


-- ============================================================
-- 7. ENGAGEMENT COMPARISON:
--    CANCELLED VS ACTIVE USERS
--
-- Compares session behaviour between groups.
-- ============================================================

WITH user_sessions AS (

    SELECT

        u.user_id,

        s.status,

        COUNT(DISTINCT se.session_id)
            AS session_count,

        COALESCE(
            AVG(se.session_duration_min),
            0
        ) AS avg_session_duration,

        COALESCE(
            SUM(se.content_items_watched),
            0
        ) AS total_content_watched

    FROM subscriptions s

    JOIN users u
        ON s.user_id = u.user_id

    LEFT JOIN sessions se
        ON u.user_id = se.user_id

    GROUP BY
        u.user_id,
        s.status
)

SELECT

    status,

    COUNT(*) AS users,

    ROUND(
        AVG(session_count),
        2
    ) AS avg_sessions_per_user,

    ROUND(
        AVG(avg_session_duration),
        2
    ) AS avg_session_duration,

    ROUND(
        AVG(total_content_watched),
        2
    ) AS avg_content_watched

FROM user_sessions

GROUP BY
    status

ORDER BY
    status;


-- ============================================================
-- 8. CHURN BY SESSION ENGAGEMENT
--
-- Creates simple engagement buckets based on total
-- session count.
-- ============================================================

WITH user_sessions AS (

    SELECT

        u.user_id,

        s.status,

        COUNT(DISTINCT se.session_id)
            AS session_count

    FROM subscriptions s

    JOIN users u
        ON s.user_id = u.user_id

    LEFT JOIN sessions se
        ON u.user_id = se.user_id

    GROUP BY
        u.user_id,
        s.status
),

bucketed AS (

    SELECT

        user_id,
        status,
        session_count,

        CASE
            WHEN session_count = 0
                THEN 'No Sessions'

            WHEN session_count BETWEEN 1 AND 5
                THEN 'Low Engagement'

            WHEN session_count BETWEEN 6 AND 15
                THEN 'Medium Engagement'

            ELSE 'High Engagement'
        END AS engagement_bucket

    FROM user_sessions
)

SELECT

    engagement_bucket,

    COUNT(*) AS users,

    SUM(
        CASE
            WHEN status = 'cancelled'
            THEN 1
            ELSE 0
        END
    ) AS cancelled_users,

    ROUND(
        100.0 *
        SUM(
            CASE
                WHEN status = 'cancelled'
                THEN 1
                ELSE 0
            END
        )
        / NULLIF(COUNT(*), 0),
        2
    ) AS churn_rate_pct

FROM bucketed

GROUP BY
    engagement_bucket

ORDER BY
    churn_rate_pct DESC;


-- ============================================================
-- 9. 30-DAY PRE-CANCELLATION ACTIVITY
--
-- Measures activity in the 30 days before cancellation.
--
-- This helps determine whether users show lower engagement
-- shortly before cancellation.
-- ============================================================

WITH cancelled_users AS (

    SELECT

        user_id,

        cancellation_date

    FROM subscriptions

    WHERE status = 'cancelled'
      AND cancellation_date IS NOT NULL
),

pre_churn_activity AS (

    SELECT

        cu.user_id,

        cu.cancellation_date,

        COUNT(DISTINCT s.session_id)
            AS sessions_before_cancel,

        COALESCE(
            SUM(s.session_duration_min),
            0
        ) AS total_minutes_before_cancel,

        COALESCE(
            SUM(s.content_items_watched),
            0
        ) AS content_watched_before_cancel

    FROM cancelled_users cu

    LEFT JOIN sessions s

        ON cu.user_id = s.user_id

        AND DATE(s.session_start)
            >= DATE(
                cu.cancellation_date,
                '-30 day'
            )

        AND DATE(s.session_start)
            < DATE(cu.cancellation_date)

    GROUP BY
        cu.user_id,
        cu.cancellation_date
)

SELECT

    COUNT(*) AS cancelled_users,

    ROUND(
        AVG(sessions_before_cancel),
        2
    ) AS avg_sessions_last_30d,

    ROUND(
        AVG(total_minutes_before_cancel),
        2
    ) AS avg_minutes_last_30d,

    ROUND(
        AVG(content_watched_before_cancel),
        2
    ) AS avg_content_watched_last_30d

FROM pre_churn_activity;


-- ============================================================
-- 10. PRE-CANCELLATION ACTIVITY BY ENGAGEMENT SEGMENT
-- ============================================================

WITH cancelled_users AS (

    SELECT

        s.user_id,

        s.cancellation_date,

        u.engagement_segment

    FROM subscriptions s

    JOIN users u
        ON s.user_id = u.user_id

    WHERE s.status = 'cancelled'
      AND s.cancellation_date IS NOT NULL
),

pre_churn_activity AS (

    SELECT

        cu.user_id,

        cu.engagement_segment,

        COUNT(DISTINCT se.session_id)
            AS sessions_before_cancel,

        COALESCE(
            SUM(se.session_duration_min),
            0
        ) AS total_minutes_before_cancel

    FROM cancelled_users cu

    LEFT JOIN sessions se

        ON cu.user_id = se.user_id

        AND DATE(se.session_start)
            >= DATE(
                cu.cancellation_date,
                '-30 day'
            )

        AND DATE(se.session_start)
            < DATE(cu.cancellation_date)

    GROUP BY
        cu.user_id,
        cu.engagement_segment
)

SELECT

    engagement_segment,

    COUNT(*) AS cancelled_users,

    ROUND(
        AVG(sessions_before_cancel),
        2
    ) AS avg_sessions_last_30d,

    ROUND(
        AVG(total_minutes_before_cancel),
        2
    ) AS avg_minutes_last_30d

FROM pre_churn_activity

GROUP BY
    engagement_segment

ORDER BY
    avg_sessions_last_30d ASC;


-- ============================================================
-- 11. CHURN LABEL PERFORMANCE
--
-- Uses churn_labels to measure how many users are predicted
-- to cancel within the next 30 days at each snapshot.
-- ============================================================

SELECT

    snapshot_date,

    COUNT(*) AS users,

    SUM(cancelled_in_next_30d)
        AS users_cancelled_next_30d,

    ROUND(
        100.0 *
        AVG(cancelled_in_next_30d),
        2
    ) AS next_30d_churn_rate_pct

FROM churn_labels

GROUP BY
    snapshot_date

ORDER BY
    snapshot_date;


-- ============================================================
-- 12. CHURN LABEL SUMMARY
-- ============================================================

SELECT

    COUNT(*) AS total_labels,

    SUM(cancelled_in_next_30d)
        AS positive_labels,

    ROUND(
        100.0 *
        AVG(cancelled_in_next_30d),
        2
    ) AS positive_rate_pct

FROM churn_labels;


-- ============================================================
-- 13. CHURN RISK SUMMARY
--
-- Combines engagement segment, subscription status and
-- recent activity into one business-facing output.
-- ============================================================

WITH user_activity AS (

    SELECT

        u.user_id,

        u.engagement_segment,

        s.status,

        COUNT(DISTINCT se.session_id)
            AS total_sessions,

        COALESCE(
            AVG(se.session_duration_min),
            0
        ) AS avg_session_duration

    FROM users u

    JOIN subscriptions s
        ON u.user_id = s.user_id

    LEFT JOIN sessions se
        ON u.user_id = se.user_id

    GROUP BY
        u.user_id,
        u.engagement_segment,
        s.status
)

SELECT

    engagement_segment,

    status,

    COUNT(*) AS users,

    ROUND(
        AVG(total_sessions),
        2
    ) AS avg_sessions,

    ROUND(
        AVG(avg_session_duration),
        2
    ) AS avg_session_duration

FROM user_activity

GROUP BY
    engagement_segment,
    status

ORDER BY
    engagement_segment,
    status;