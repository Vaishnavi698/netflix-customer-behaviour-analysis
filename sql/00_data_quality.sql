-- ============================================================
-- NETFLIX CUSTOMER BEHAVIOUR ANALYTICS
-- DATA QUALITY CHECKS
-- ============================================================
--
-- Purpose:
-- Validate that the dataset is structurally and logically
-- safe to use for customer behaviour analysis.
--
-- Checks:
-- 1. Duplicate records
-- 2. NULL values
-- 3. Orphan keys
-- 4. Invalid numeric values
-- 5. Date/timeline consistency
-- 6. Content validity
-- 7. Basic date ranges
-- ============================================================


-- ============================================================
-- 1. DUPLICATE CHECKS
-- ============================================================

-- Duplicate users
SELECT
    user_id,
    COUNT(*) AS duplicate_count
FROM users
GROUP BY user_id
HAVING COUNT(*) > 1;


-- Duplicate sessions
SELECT
    session_id,
    COUNT(*) AS duplicate_count
FROM sessions
GROUP BY session_id
HAVING COUNT(*) > 1;


-- Duplicate subscriptions
SELECT
    subscription_id,
    COUNT(*) AS duplicate_count
FROM subscriptions
GROUP BY subscription_id
HAVING COUNT(*) > 1;


-- Duplicate content
SELECT
    content_id,
    COUNT(*) AS duplicate_count
FROM content
GROUP BY content_id
HAVING COUNT(*) > 1;


-- ============================================================
-- 2. NULL CHECKS
-- ============================================================

-- Users
SELECT
    COUNT(*) AS total_users,
    SUM(CASE WHEN user_id IS NULL THEN 1 ELSE 0 END) AS null_user_id,
    SUM(CASE WHEN signup_date IS NULL THEN 1 ELSE 0 END) AS null_signup_date,
    SUM(CASE WHEN country IS NULL THEN 1 ELSE 0 END) AS null_country,
    SUM(CASE WHEN subscription_plan IS NULL THEN 1 ELSE 0 END) AS null_subscription_plan
FROM users;


-- Sessions
SELECT
    COUNT(*) AS total_sessions,
    SUM(CASE WHEN session_id IS NULL THEN 1 ELSE 0 END) AS null_session_id,
    SUM(CASE WHEN user_id IS NULL THEN 1 ELSE 0 END) AS null_user_id,
    SUM(CASE WHEN session_start IS NULL THEN 1 ELSE 0 END) AS null_session_start,
    SUM(CASE WHEN session_end IS NULL THEN 1 ELSE 0 END) AS null_session_end
FROM sessions;


-- Subscriptions
SELECT
    COUNT(*) AS total_subscriptions,
    SUM(CASE WHEN subscription_id IS NULL THEN 1 ELSE 0 END) AS null_subscription_id,
    SUM(CASE WHEN user_id IS NULL THEN 1 ELSE 0 END) AS null_user_id,
    SUM(CASE WHEN start_date IS NULL THEN 1 ELSE 0 END) AS null_start_date
FROM subscriptions;


-- ============================================================
-- 3. ORPHAN KEY CHECKS
-- ============================================================

-- Sessions without a matching user
SELECT
    COUNT(*) AS orphan_sessions
FROM sessions s
LEFT JOIN users u
    ON s.user_id = u.user_id
WHERE u.user_id IS NULL;


-- Events without a matching session
SELECT
    COUNT(*) AS orphan_events
FROM events e
LEFT JOIN sessions s
    ON e.session_id = s.session_id
WHERE s.session_id IS NULL;


-- Events without a matching user
SELECT
    COUNT(*) AS orphan_event_users
FROM events e
LEFT JOIN users u
    ON e.user_id = u.user_id
WHERE u.user_id IS NULL;


-- Recommendations without a matching user
SELECT
    COUNT(*) AS orphan_recommendation_users
FROM recommendations r
LEFT JOIN users u
    ON r.user_id = u.user_id
WHERE u.user_id IS NULL;


-- ============================================================
-- 4. INVALID NUMERIC VALUES
-- ============================================================

-- Negative session duration
SELECT
    COUNT(*) AS negative_session_duration
FROM sessions
WHERE session_duration_min < 0;


-- Watch percentage outside 0–100
SELECT
    COUNT(*) AS invalid_watch_percentage
FROM events
WHERE watch_percentage < 0
   OR watch_percentage > 100;


-- Negative watch duration
SELECT
    COUNT(*) AS negative_watch_duration
FROM events
WHERE watch_duration_sec < 0;


-- Invalid recommendation flags
SELECT
    COUNT(*) AS invalid_recommendation_flags
FROM recommendations
WHERE impression NOT IN (0, 1)
   OR clicked NOT IN (0, 1)
   OR watch_started NOT IN (0, 1)
   OR watch_completed NOT IN (0, 1);


-- Invalid session content counts
SELECT
    COUNT(*) AS invalid_content_counts
FROM sessions
WHERE content_items_viewed < 0
   OR content_items_watched < 0
   OR content_items_watched > content_items_viewed;


-- ============================================================
-- 5. SESSION TIMELINE CHECKS
-- ============================================================

-- Session ending before it starts
SELECT
    COUNT(*) AS invalid_session_timeline
FROM sessions
WHERE session_end < session_start;


-- Sessions occurring before signup
SELECT
    COUNT(*) AS sessions_before_signup
FROM sessions s
JOIN users u
    ON s.user_id = u.user_id
WHERE date(s.session_start) < date(u.signup_date);


-- ============================================================
-- 6. SUBSCRIPTION TIMELINE CHECKS
-- ============================================================

-- Subscription ending before it starts
SELECT
    COUNT(*) AS invalid_subscription_dates
FROM subscriptions
WHERE end_date IS NOT NULL
  AND date(end_date) < date(start_date);


-- Cancellation before subscription start
SELECT
    COUNT(*) AS cancellation_before_start
FROM subscriptions
WHERE cancellation_date IS NOT NULL
  AND date(cancellation_date) < date(start_date);


-- Cancellation after subscription end
SELECT
    COUNT(*) AS cancellation_after_end
FROM subscriptions
WHERE cancellation_date IS NOT NULL
  AND end_date IS NOT NULL
  AND date(cancellation_date) > date(end_date);


-- ============================================================
-- 7. CONTENT CHECKS
-- ============================================================

-- Invalid content duration
SELECT
    COUNT(*) AS invalid_content_duration
FROM content
WHERE duration_min <= 0;


-- Popularity score outside 0–100
SELECT
    COUNT(*) AS invalid_popularity_score
FROM content
WHERE popularity_score < 0
   OR popularity_score > 100;


-- ============================================================
-- 8. BASIC DATE RANGE CHECKS
-- ============================================================

SELECT
    MIN(signup_date) AS earliest_signup,
    MAX(signup_date) AS latest_signup
FROM users;


SELECT
    MIN(session_start) AS earliest_session,
    MAX(session_start) AS latest_session
FROM sessions;


SELECT
    MIN(activity_date) AS earliest_activity,
    MAX(activity_date) AS latest_activity
FROM daily_activity;


-- ============================================================
-- 9. DAILY ACTIVITY SANITY CHECK
-- ============================================================

-- Session counts should never be negative
SELECT
    COUNT(*) AS negative_session_count
FROM daily_activity
WHERE session_count < 0;


-- Session minutes should never be negative
SELECT
    COUNT(*) AS negative_session_minutes
FROM daily_activity
WHERE total_session_minutes < 0;

-- ============================================================
-- INVESTIGATE INVALID CONTENT COUNTS
-- ============================================================

SELECT
    session_id,
    user_id,
    session_start,
    content_items_viewed,
    content_items_watched
FROM sessions
WHERE content_items_viewed < 0
   OR content_items_watched < 0
   OR content_items_watched > content_items_viewed
ORDER BY content_items_watched - content_items_viewed DESC;