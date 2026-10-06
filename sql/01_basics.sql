-- ============================================================
-- SESSION 1: SQL BASICS
-- ============================================================

-- Explore the users table
SELECT *
FROM users
LIMIT 10;


-- Count total users
SELECT COUNT(*) AS total_users
FROM users;


-- Display only user IDs
SELECT user_id
FROM users
LIMIT 10;


-- Display user ID and country
SELECT
    user_id,
    country
FROM users
LIMIT 10;


-- Display unique countries
SELECT DISTINCT country
FROM users;


-- Display unique subscription plans
SELECT DISTINCT subscription_plan
FROM users;


-- Display unique engagement segments
SELECT DISTINCT engagement_segment
FROM users;