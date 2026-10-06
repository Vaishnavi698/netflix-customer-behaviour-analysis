-- ============================================================
-- SESSION 6: SUBQUERIES & CTEs
-- ============================================================


-- 1. Users whose household size is above the average
SELECT
    user_id,
    household_size
FROM users
WHERE household_size > (
    SELECT AVG(household_size)
    FROM users
)
ORDER BY household_size DESC;


-- 2. Sessions longer than the average session
SELECT
    session_id,
    user_id,
    session_duration_min
FROM sessions
WHERE session_duration_min > (
    SELECT AVG(session_duration_min)
    FROM sessions
)
ORDER BY session_duration_min DESC;


-- 3. Countries with more users than the average country
SELECT
    country,
    COUNT(*) AS user_count
FROM users
GROUP BY country
HAVING COUNT(*) > (
    SELECT AVG(country_count)
    FROM (
        SELECT COUNT(*) AS country_count
        FROM users
        GROUP BY country
    )
)
ORDER BY user_count DESC;


-- 4. CTE: calculate average session duration by user
WITH user_sessions AS (
    SELECT
        user_id,
        COUNT(*) AS session_count,
        AVG(session_duration_min) AS avg_session_duration
    FROM sessions
    GROUP BY user_id
)
SELECT
    user_id,
    session_count,
    avg_session_duration
FROM user_sessions
ORDER BY avg_session_duration DESC
LIMIT 20;


-- 5. CTE: users with at least 5 sessions
WITH user_session_counts AS (
    SELECT
        user_id,
        COUNT(*) AS session_count
    FROM sessions
    GROUP BY user_id
)
SELECT
    user_id,
    session_count
FROM user_session_counts
WHERE session_count >= 5
ORDER BY session_count DESC;


-- 6. CTE: average session duration by country
WITH country_sessions AS (
    SELECT
        u.country,
        s.session_duration_min
    FROM users u
    JOIN sessions s
        ON u.user_id = s.user_id
)
SELECT
    country,
    COUNT(*) AS session_count,
    AVG(session_duration_min) AS avg_session_duration
FROM country_sessions
GROUP BY country
ORDER BY avg_session_duration DESC;