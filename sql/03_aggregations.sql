-- ============================================================
-- SESSION 3: AGGREGATIONS
-- ============================================================


-- Total number of users
SELECT COUNT(*) AS total_users
FROM users;


-- Users by country
SELECT
    country,
    COUNT(*) AS user_count
FROM users
GROUP BY country
ORDER BY user_count DESC;


-- Users by subscription plan
SELECT
    subscription_plan,
    COUNT(*) AS user_count
FROM users
GROUP BY subscription_plan
ORDER BY user_count DESC;


-- Users by engagement segment
SELECT
    engagement_segment,
    COUNT(*) AS user_count
FROM users
GROUP BY engagement_segment
ORDER BY user_count DESC;


-- Average household size
SELECT
    AVG(household_size) AS avg_household_size
FROM users;


-- Average engagement propensity
SELECT
    AVG(engagement_propensity) AS avg_engagement_propensity
FROM users;


-- Countries with more than 500 users
SELECT
    country,
    COUNT(*) AS user_count
FROM users
GROUP BY country
HAVING COUNT(*) > 500
ORDER BY user_count DESC;