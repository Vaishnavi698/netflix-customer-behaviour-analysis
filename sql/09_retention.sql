-- ============================================================
-- NETFLIX CUSTOMER BEHAVIOUR ANALYTICS
-- 09 - RETENTION ANALYSIS
-- ============================================================


-- 1. Signup-based Day 1, Day 7 and Day 30 retention
-- Checks whether users had activity after signup.

WITH user_activity AS (
    SELECT
        u.user_id,
        DATE(u.signup_date) AS signup_date,
        DATE(d.activity_date) AS activity_date
    FROM users u
    JOIN daily_activity d
        ON u.user_id = d.user_id
    WHERE d.session_count > 0
),

retention_flags AS (
    SELECT
        user_id,

        MAX(
            CASE
                WHEN activity_date = DATE(signup_date, '+1 day')
                THEN 1 ELSE 0
            END
        ) AS retained_d1,

        MAX(
            CASE
                WHEN activity_date = DATE(signup_date, '+7 day')
                THEN 1 ELSE 0
            END
        ) AS retained_d7,

        MAX(
            CASE
                WHEN activity_date = DATE(signup_date, '+30 day')
                THEN 1 ELSE 0
            END
        ) AS retained_d30

    FROM user_activity
    GROUP BY user_id
)

SELECT
    COUNT(*) AS users,

    SUM(retained_d1) AS d1_users,
    ROUND(
        100.0 * SUM(retained_d1) / COUNT(*),
        2
    ) AS d1_retention_pct,

    SUM(retained_d7) AS d7_users,
    ROUND(
        100.0 * SUM(retained_d7) / COUNT(*),
        2
    ) AS d7_retention_pct,

    SUM(retained_d30) AS d30_users,
    ROUND(
        100.0 * SUM(retained_d30) / COUNT(*),
        2
    ) AS d30_retention_pct

FROM retention_flags;


-- 2. Activation within 7 days of signup
-- A user is considered activated if they have a session
-- within 7 days after signup.

WITH first_session AS (
    SELECT
        u.user_id,
        DATE(u.signup_date) AS signup_date,
        MIN(DATE(s.session_start)) AS first_session_date
    FROM users u
    LEFT JOIN sessions s
        ON u.user_id = s.user_id
    GROUP BY u.user_id
)

SELECT
    COUNT(*) AS total_users,

    SUM(
        CASE
            WHEN first_session_date IS NOT NULL
             AND julianday(first_session_date) - julianday(signup_date)
                 BETWEEN 0 AND 7
            THEN 1
            ELSE 0
        END
    ) AS activated_users,

    ROUND(
        100.0 *
        SUM(
            CASE
                WHEN first_session_date IS NOT NULL
                 AND julianday(first_session_date) - julianday(signup_date)
                     BETWEEN 0 AND 7
                THEN 1
                ELSE 0
            END
        ) / COUNT(*),
        2
    ) AS activation_rate_pct

FROM first_session;


-- 3. Activation by acquisition channel

WITH first_session AS (
    SELECT
        u.user_id,
        u.acquisition_channel,
        DATE(u.signup_date) AS signup_date,
        MIN(DATE(s.session_start)) AS first_session_date
    FROM users u
    LEFT JOIN sessions s
        ON u.user_id = s.user_id
    GROUP BY
        u.user_id,
        u.acquisition_channel
)

SELECT
    acquisition_channel,

    COUNT(*) AS total_users,

    SUM(
        CASE
            WHEN first_session_date IS NOT NULL
             AND julianday(first_session_date) - julianday(signup_date)
                 BETWEEN 0 AND 7
            THEN 1
            ELSE 0
        END
    ) AS activated_users,

    ROUND(
        100.0 *
        SUM(
            CASE
                WHEN first_session_date IS NOT NULL
                 AND julianday(first_session_date) - julianday(signup_date)
                     BETWEEN 0 AND 7
                THEN 1
                ELSE 0
            END
        ) / COUNT(*),
        2
    ) AS activation_rate_pct

FROM first_session

GROUP BY acquisition_channel

ORDER BY activation_rate_pct DESC;


-- 4. Retention by subscription plan

WITH user_activity AS (
    SELECT
        u.user_id,
        u.subscription_plan,
        DATE(u.signup_date) AS signup_date,
        DATE(d.activity_date) AS activity_date
    FROM users u
    JOIN daily_activity d
        ON u.user_id = d.user_id
    WHERE d.session_count > 0
),

retention_flags AS (
    SELECT
        user_id,
        subscription_plan,

        MAX(
            CASE
                WHEN activity_date = DATE(signup_date, '+7 day')
                THEN 1 ELSE 0
            END
        ) AS retained_d7,

        MAX(
            CASE
                WHEN activity_date = DATE(signup_date, '+30 day')
                THEN 1 ELSE 0
            END
        ) AS retained_d30

    FROM user_activity

    GROUP BY
        user_id,
        subscription_plan
)

SELECT
    subscription_plan,
    COUNT(*) AS users,

    SUM(retained_d7) AS d7_users,

    ROUND(
        100.0 * SUM(retained_d7) / COUNT(*),
        2
    ) AS d7_retention_pct,

    SUM(retained_d30) AS d30_users,

    ROUND(
        100.0 * SUM(retained_d30) / COUNT(*),
        2
    ) AS d30_retention_pct

FROM retention_flags

GROUP BY subscription_plan

ORDER BY d30_retention_pct DESC;


-- 5. Retention by engagement segment

WITH user_activity AS (
    SELECT
        u.user_id,
        u.engagement_segment,
        DATE(u.signup_date) AS signup_date,
        DATE(d.activity_date) AS activity_date
    FROM users u
    JOIN daily_activity d
        ON u.user_id = d.user_id
    WHERE d.session_count > 0
),

retention_flags AS (
    SELECT
        user_id,
        engagement_segment,

        MAX(
            CASE
                WHEN activity_date = DATE(signup_date, '+7 day')
                THEN 1 ELSE 0
            END
        ) AS retained_d7,

        MAX(
            CASE
                WHEN activity_date = DATE(signup_date, '+30 day')
                THEN 1 ELSE 0
            END
        ) AS retained_d30

    FROM user_activity

    GROUP BY
        user_id,
        engagement_segment
)

SELECT
    engagement_segment,
    COUNT(*) AS users,

    ROUND(
        100.0 * SUM(retained_d7) / COUNT(*),
        2
    ) AS d7_retention_pct,

    ROUND(
        100.0 * SUM(retained_d30) / COUNT(*),
        2
    ) AS d30_retention_pct

FROM retention_flags

GROUP BY engagement_segment

ORDER BY d30_retention_pct DESC;


-- 6. First-session retention
-- Measures retention from the user's first actual session,
-- rather than from signup.

WITH first_sessions AS (
    SELECT
        user_id,
        MIN(DATE(session_start)) AS first_session_date
    FROM sessions
    GROUP BY user_id
),

activity_after_first_session AS (
    SELECT
        f.user_id,
        f.first_session_date,
        DATE(d.activity_date) AS activity_date
    FROM first_sessions f
    JOIN daily_activity d
        ON f.user_id = d.user_id
    WHERE d.session_count > 0
)

SELECT
    COUNT(DISTINCT user_id) AS activated_users,

    COUNT(
        DISTINCT CASE
            WHEN activity_date
                 = DATE(first_session_date, '+7 day')
            THEN user_id
        END
    ) AS retained_after_7_days,

    ROUND(
        100.0 *
        COUNT(
            DISTINCT CASE
                WHEN activity_date
                     = DATE(first_session_date, '+7 day')
                THEN user_id
            END
        ) / COUNT(DISTINCT user_id),
        2
    ) AS first_session_d7_retention_pct

FROM activity_after_first_session;