-- ============================================================
-- 13_powerbi_views.sql
-- Purpose: Create Power BI-ready analytical views
-- ============================================================


-- ============================================================
-- 1. USER SUMMARY
-- One row per user
-- ============================================================

DROP VIEW IF EXISTS v_user_summary;

CREATE VIEW v_user_summary AS

WITH session_summary AS (
    SELECT
        user_id,
        COUNT(*) AS total_sessions,
        ROUND(AVG(session_duration_min), 2) AS avg_session_duration,
        ROUND(SUM(session_duration_min), 2) AS total_session_minutes,
        SUM(content_items_viewed) AS total_content_viewed,
        SUM(content_items_watched) AS total_content_watched,
        MIN(session_start) AS first_session_date,
        MAX(session_start) AS last_session_date
    FROM sessions
    GROUP BY user_id
),

activity_summary AS (
    SELECT
        user_id,
        COUNT(
            CASE
                WHEN session_count > 0 THEN 1
            END
        ) AS active_days
    FROM daily_activity
    GROUP BY user_id
)

SELECT
    u.user_id,
    u.signup_date,
    u.country,
    u.city,
    u.age_group,
    u.acquisition_channel,
    u.device_primary,
    u.subscription_plan,
    u.household_size,
    u.engagement_segment,
    u.engagement_propensity,

    COALESCE(s.total_sessions, 0) AS total_sessions,
    COALESCE(s.avg_session_duration, 0) AS avg_session_duration,
    COALESCE(s.total_session_minutes, 0) AS total_session_minutes,
    COALESCE(s.total_content_viewed, 0) AS total_content_viewed,
    COALESCE(s.total_content_watched, 0) AS total_content_watched,

    s.first_session_date,
    s.last_session_date,

    COALESCE(a.active_days, 0) AS active_days

FROM users u

LEFT JOIN session_summary s
    ON u.user_id = s.user_id

LEFT JOIN activity_summary a
    ON u.user_id = a.user_id;


-- ============================================================
-- 2. RETENTION COHORTS
-- Cohort = week of first activity
-- Activity = daily_activity where session_count > 0
--
-- This aligns the Power BI retention view with the
-- post-activation retention analysis.
-- ============================================================

DROP VIEW IF EXISTS v_retention_cohorts;

CREATE VIEW v_retention_cohorts AS

WITH first_activity AS (

    SELECT
        user_id,
        MIN(date(activity_date)) AS first_activity_date
    FROM daily_activity
    WHERE session_count > 0
    GROUP BY user_id

),

activated_users AS (

    SELECT
        user_id,
        first_activity_date,

        date(
            first_activity_date,
            '-' || (
                (strftime('%w', first_activity_date) + 6) % 7
            ) || ' days'
        ) AS activation_cohort_week

    FROM first_activity

),

activity AS (

    SELECT
        user_id,
        date(activity_date) AS activity_date
    FROM daily_activity
    WHERE session_count > 0

),

cohort_activity AS (

    SELECT DISTINCT
        au.user_id,
        au.activation_cohort_week,
        a.activity_date,

        CAST(
            (
                julianday(a.activity_date)
                - julianday(au.first_activity_date)
            ) / 7
            AS INTEGER
        ) AS weeks_since_activation

    FROM activated_users au

    JOIN activity a
        ON au.user_id = a.user_id

)

SELECT
    activation_cohort_week AS cohort_week,
    weeks_since_activation,
    COUNT(DISTINCT user_id) AS active_users

FROM cohort_activity

GROUP BY
    activation_cohort_week,
    weeks_since_activation

ORDER BY
    activation_cohort_week,
    weeks_since_activation;


-- ============================================================
-- 3. CHURN FEATURES
-- One row per user
--
-- churn_30d_flag = latest available churn label for the user.
--
-- IMPORTANT:
-- The 5.02% metric from churn analysis is a LABEL-level rate:
-- 1,768 positive labels / 40,548 total labels.
--
-- This user-level flag is a different metric and should not
-- be presented as the same 5.02% rate.
-- ============================================================

DROP VIEW IF EXISTS v_churn_features;

CREATE VIEW v_churn_features AS

WITH session_features AS (

    SELECT
        user_id,
        COUNT(*) AS total_sessions,
        ROUND(AVG(session_duration_min), 2) AS avg_session_duration,
        ROUND(SUM(session_duration_min), 2) AS total_session_minutes,
        SUM(content_items_viewed) AS total_content_viewed,
        SUM(content_items_watched) AS total_content_watched,
        MIN(session_start) AS first_session_date,
        MAX(session_start) AS last_session_date
    FROM sessions
    GROUP BY user_id

),

activity_features AS (

    SELECT
        user_id,

        COUNT(
            CASE
                WHEN session_count > 0 THEN 1
            END
        ) AS active_days,

        SUM(session_count) AS activity_sessions,
        SUM(total_session_minutes) AS activity_minutes

    FROM daily_activity
    GROUP BY user_id

),

latest_churn_snapshot AS (

    SELECT
        user_id,
        cancelled_in_next_30d AS churn_30d_flag

    FROM (

        SELECT
            user_id,
            snapshot_date,
            cancelled_in_next_30d,

            ROW_NUMBER() OVER (
                PARTITION BY user_id
                ORDER BY snapshot_date DESC
            ) AS rn

        FROM churn_labels

    )

    WHERE rn = 1

)

SELECT
    u.user_id,

    u.age_group,
    u.country,
    u.city,
    u.acquisition_channel,
    u.device_primary,
    u.subscription_plan,
    u.household_size,

    u.engagement_segment,
    u.engagement_propensity,

    COALESCE(s.total_sessions, 0) AS total_sessions,
    COALESCE(s.avg_session_duration, 0) AS avg_session_duration,
    COALESCE(s.total_session_minutes, 0) AS total_session_minutes,
    COALESCE(s.total_content_viewed, 0) AS total_content_viewed,
    COALESCE(s.total_content_watched, 0) AS total_content_watched,

    COALESCE(a.active_days, 0) AS active_days,

    s.first_session_date,
    s.last_session_date,

    COALESCE(c.churn_30d_flag, 0) AS churn_30d_flag

FROM users u

LEFT JOIN session_features s
    ON u.user_id = s.user_id

LEFT JOIN activity_features a
    ON u.user_id = a.user_id

LEFT JOIN latest_churn_snapshot c
    ON u.user_id = c.user_id;


-- ============================================================
-- 4. EXPERIMENT RESULTS
-- One row per experiment + variant
--
-- IMPORTANT:
-- Only exposed users are included in recommendation metrics.
-- This aligns the view with the locked experiment analysis.
-- ============================================================

DROP VIEW IF EXISTS v_experiment_results;

CREATE VIEW v_experiment_results AS

WITH assignments AS (

    SELECT
        experiment_name,
        variant,

        COUNT(*) AS assigned_users,

        SUM(
            CASE
                WHEN exposed = 1 THEN 1
                ELSE 0
            END
        ) AS exposed_users

    FROM experiments

    GROUP BY
        experiment_name,
        variant

),

recommendation_metrics AS (

    SELECT
        e.experiment_name,
        e.variant,

        COUNT(r.recommendation_id) AS impressions,

        SUM(
            CASE
                WHEN r.clicked = 1 THEN 1
                ELSE 0
            END
        ) AS clicks,

        SUM(
            CASE
                WHEN r.watch_started = 1 THEN 1
                ELSE 0
            END
        ) AS watch_starts,

        SUM(
            CASE
                WHEN r.watch_completed = 1 THEN 1
                ELSE 0
            END
        ) AS completions

    FROM experiments e

    JOIN recommendations r
        ON e.user_id = r.user_id

    WHERE e.exposed = 1

    GROUP BY
        e.experiment_name,
        e.variant

)

SELECT
    a.experiment_name,
    a.variant,

    a.assigned_users,
    a.exposed_users,

    COALESCE(r.impressions, 0) AS impressions,
    COALESCE(r.clicks, 0) AS clicks,
    COALESCE(r.watch_starts, 0) AS watch_starts,
    COALESCE(r.completions, 0) AS completions,

    ROUND(
        100.0 * r.clicks
        / NULLIF(r.impressions, 0),
        2
    ) AS ctr_pct,

    ROUND(
        100.0 * r.watch_starts
        / NULLIF(r.clicks, 0),
        2
    ) AS click_to_start_pct,

    ROUND(
        100.0 * r.completions
        / NULLIF(r.watch_starts, 0),
        2
    ) AS completion_pct

FROM assignments a

LEFT JOIN recommendation_metrics r
    ON a.experiment_name = r.experiment_name
    AND a.variant = r.variant;