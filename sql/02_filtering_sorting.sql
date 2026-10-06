-- ============================================================
-- SESSION 2: FILTERING & SORTING
-- ============================================================


-- Basic WHERE
SELECT *
FROM users
WHERE country = 'India';


-- Filter using IN
SELECT *
FROM users
WHERE country IN ('India', 'United States');


-- Filter by subscription plan
SELECT *
FROM users
WHERE subscription_plan = 'Premium';


-- Filter by engagement segment
SELECT *
FROM users
WHERE engagement_segment = 'High';


-- Sort users by signup date
SELECT *
FROM users
ORDER BY signup_date DESC
LIMIT 20;


-- Sort by household size
SELECT
    user_id,
    household_size
FROM users
ORDER BY household_size DESC;


-- Find users with missing country
SELECT *
FROM users
WHERE country IS NULL;


-- Find users with a household size greater than 2
SELECT *
FROM users
WHERE household_size > 2;