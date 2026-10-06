-- ============================================================
-- SESSION 5: CASE STATEMENTS & DATES
-- ============================================================


-- 1. Categorize users based on household size
SELECT
    user_id,
    household_size,
    CASE
        WHEN household_size = 1 THEN 'Single'
        WHEN household_size = 2 THEN 'Small Household'
        WHEN household_size >= 3 THEN 'Large Household'
        ELSE 'Unknown'
    END AS household_category
FROM users
LIMIT 20;


-- 2. Categorize session duration
SELECT
    session_id,
    user_id,
    session_duration_min,
    CASE
        WHEN session_duration_min < 20 THEN 'Short'
        WHEN session_duration_min < 60 THEN 'Medium'
        ELSE 'Long'
    END AS session_category
FROM sessions
LIMIT 20;


-- 3. Count sessions by duration category
SELECT
    CASE
        WHEN session_duration_min < 20 THEN 'Short'
        WHEN session_duration_min < 60 THEN 'Medium'
        ELSE 'Long'
    END AS session_category,
    COUNT(*) AS session_count
FROM sessions
GROUP BY session_category
ORDER BY session_count DESC;


-- 4. Calculate average session duration by device
SELECT
    device,
    AVG(session_duration_min) AS avg_session_duration
FROM sessions
GROUP BY device
ORDER BY avg_session_duration DESC;


-- 5. Extract year from signup date
SELECT
    user_id,
    signup_date,
    strftime('%Y', signup_date) AS signup_year
FROM users
LIMIT 20;


-- 6. Count users by signup year
SELECT
    strftime('%Y', signup_date) AS signup_year,
    COUNT(*) AS user_count
FROM users
GROUP BY signup_year
ORDER BY signup_year;


-- 7. Count events by activity date
SELECT
    activity_date,
    COUNT(*) AS event_count
FROM events
GROUP BY activity_date
ORDER BY activity_date
LIMIT 20;


-- 8. Find sessions longer than 60 minutes
SELECT
    session_id,
    user_id,
    session_start,
    session_end,
    session_duration_min
FROM sessions
WHERE session_duration_min > 60
ORDER BY session_duration_min DESC
LIMIT 20;


-- 9. Compare cancelled vs active subscriptions
SELECT
    status,
    COUNT(*) AS subscription_count
FROM subscriptions
GROUP BY status;


-- 10. Categorize subscription price
SELECT
    subscription_id,
    plan,
    monthly_price,
    CASE
        WHEN monthly_price < 10 THEN 'Low Price'
        WHEN monthly_price < 20 THEN 'Mid Price'
        ELSE 'High Price'
    END AS price_category
FROM subscriptions
LIMIT 20;