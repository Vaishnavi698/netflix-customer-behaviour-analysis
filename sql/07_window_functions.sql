-- ============================================================
-- SESSION 7: WINDOW FUNCTIONS
-- Netflix Customer Behaviour Analytics
-- ============================================================


-- 1. Rank users by engagement propensity
SELECT
    user_id,
    engagement_segment,
    engagement_propensity,
    RANK() OVER (
        ORDER BY engagement_propensity DESC
    ) AS engagement_rank
FROM users
ORDER BY engagement_rank
LIMIT 20;


-- 2. Rank content by popularity within each content type
SELECT
    content_id,
    title,
    content_type,
    genre,
    popularity_score,
    RANK() OVER (
        PARTITION BY content_type
        ORDER BY popularity_score DESC
    ) AS popularity_rank
FROM content
ORDER BY content_type, popularity_rank
LIMIT 50;


-- 3. Rank users within each country by engagement propensity
SELECT
    user_id,
    country,
    engagement_propensity,
    RANK() OVER (
        PARTITION BY country
        ORDER BY engagement_propensity DESC
    ) AS country_rank
FROM users
ORDER BY country, country_rank
LIMIT 50;


-- 4. Calculate each user's session count
--    and compare it with the average session count
WITH user_sessions AS (
    SELECT
        user_id,
        COUNT(*) AS session_count
    FROM sessions
    GROUP BY user_id
)
SELECT
    user_id,
    session_count,
    AVG(session_count) OVER () AS overall_avg_sessions,
    session_count - AVG(session_count) OVER ()
        AS difference_from_average
FROM user_sessions
ORDER BY session_count DESC
LIMIT 20;


-- 5. Rank sessions by duration for each user
SELECT
    session_id,
    user_id,
    session_start,
    session_duration_min,
    ROW_NUMBER() OVER (
        PARTITION BY user_id
        ORDER BY session_duration_min DESC
    ) AS session_rank
FROM sessions
LIMIT 50;


-- 6. Find each user's longest session
WITH ranked_sessions AS (
    SELECT
        session_id,
        user_id,
        session_start,
        session_duration_min,
        ROW_NUMBER() OVER (
            PARTITION BY user_id
            ORDER BY session_duration_min DESC
        ) AS session_rank
    FROM sessions
)
SELECT
    session_id,
    user_id,
    session_start,
    session_duration_min
FROM ranked_sessions
WHERE session_rank = 1
ORDER BY session_duration_min DESC
LIMIT 20;


-- 7. Calculate running session count by user
SELECT
    user_id,
    session_id,
    session_start,
    COUNT(*) OVER (
        PARTITION BY user_id
        ORDER BY session_start
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS cumulative_sessions
FROM sessions
LIMIT 50;


-- 8. Compare each session with the user's previous session
SELECT
    user_id,
    session_id,
    session_start,
    session_duration_min,
    LAG(session_duration_min) OVER (
        PARTITION BY user_id
        ORDER BY session_start
    ) AS previous_session_duration
FROM sessions
LIMIT 50;


-- 9. Calculate change from previous session duration
WITH session_comparison AS (
    SELECT
        user_id,
        session_id,
        session_start,
        session_duration_min,
        LAG(session_duration_min) OVER (
            PARTITION BY user_id
            ORDER BY session_start
        ) AS previous_session_duration
    FROM sessions
)
SELECT
    user_id,
    session_id,
    session_start,
    session_duration_min,
    previous_session_duration,
    session_duration_min - previous_session_duration
        AS duration_change
FROM session_comparison
WHERE previous_session_duration IS NOT NULL
ORDER BY duration_change DESC
LIMIT 50;


-- 10. Rank recommendation positions by click-through rate
SELECT
    position,
    COUNT(*) AS impressions,
    SUM(clicked) AS clicks,
    ROUND(
        100.0 * SUM(clicked) / NULLIF(COUNT(*), 0),
        2
    ) AS ctr_pct,
    RANK() OVER (
        ORDER BY
            1.0 * SUM(clicked) / NULLIF(COUNT(*), 0) DESC
    ) AS ctr_rank
FROM recommendations
GROUP BY position
ORDER BY position;