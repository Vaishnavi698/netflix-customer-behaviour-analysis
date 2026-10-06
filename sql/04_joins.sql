-- ============================================================
-- SESSION 4: JOINS
-- ============================================================


-- 1. Join users with their subscriptions
SELECT
    u.user_id,
    u.country,
    u.subscription_plan,
    s.plan,
    s.status
FROM users u
JOIN subscriptions s
    ON u.user_id = s.user_id
LIMIT 20;


-- 2. Show users and their subscription price
SELECT
    u.user_id,
    u.country,
    s.plan,
    s.monthly_price
FROM users u
JOIN subscriptions s
    ON u.user_id = s.user_id
LIMIT 20;


-- 3. Count subscriptions by plan
SELECT
    s.plan,
    COUNT(*) AS subscription_count
FROM subscriptions s
GROUP BY s.plan
ORDER BY subscription_count DESC;


-- 4. Join sessions with users
SELECT
    s.session_id,
    s.user_id,
    u.country,
    u.subscription_plan,
    s.device,
    s.session_duration_min
FROM sessions s
JOIN users u
    ON s.user_id = u.user_id
LIMIT 20;


-- 5. Average session duration by subscription plan
SELECT
    u.subscription_plan,
    AVG(s.session_duration_min) AS avg_session_duration
FROM users u
JOIN sessions s
    ON u.user_id = s.user_id
GROUP BY u.subscription_plan
ORDER BY avg_session_duration DESC;


-- 6. Number of sessions by country
SELECT
    u.country,
    COUNT(s.session_id) AS total_sessions
FROM users u
JOIN sessions s
    ON u.user_id = s.user_id
GROUP BY u.country
ORDER BY total_sessions DESC;