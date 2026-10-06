-- ============================================================
-- NETFLIX CUSTOMER BEHAVIOUR ANALYTICS
-- Schema Check
-- ============================================================

-- 1. List all tables
SELECT
    name
FROM sqlite_master
WHERE type = 'table'
ORDER BY name;


-- 2. Users
PRAGMA table_info(users);


-- 3. Content
PRAGMA table_info(content);


-- 4. Subscriptions
PRAGMA table_info(subscriptions);


-- 5. Sessions
PRAGMA table_info(sessions);


-- 6. Events
PRAGMA table_info(events);


-- 7. Recommendations
PRAGMA table_info(recommendations);


-- 8. Ads
PRAGMA table_info(ads);


-- 9. Experiments
PRAGMA table_info(experiments);


-- 10. Daily activity
PRAGMA table_info(daily_activity);


-- 11. Churn labels
PRAGMA table_info(churn_labels);