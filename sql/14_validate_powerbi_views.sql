-- ============================================================
-- 14_validate_powerbi_views.sql
-- Validate Power BI-ready views
-- ============================================================


-- ============================================================
-- 1. USER SUMMARY
-- Expected: 10,000 rows, one per user
-- ============================================================

SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT user_id) AS unique_users
FROM v_user_summary;


-- ============================================================
-- 2. RETENTION COHORTS
-- Check cohort structure
-- ============================================================

SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT cohort_week) AS cohort_count,
    MIN(cohort_week) AS first_cohort,
    MAX(cohort_week) AS latest_cohort
FROM v_retention_cohorts;


-- ============================================================
-- 3. CHURN FEATURES
-- Expected: 10,000 rows, one per user
-- ============================================================

SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT user_id) AS unique_users,

    SUM(
        CASE
            WHEN churn_30d_flag = 1 THEN 1
            ELSE 0
        END
    ) AS churn_positive_users,

    ROUND(
        100.0 * SUM(
            CASE
                WHEN churn_30d_flag = 1 THEN 1
                ELSE 0
            END
        ) / COUNT(*),
        2
    ) AS churn_rate_pct

FROM v_churn_features;


-- ============================================================
-- 4. EXPERIMENT RESULTS
-- Expected: 6 rows
-- 3 experiments × 2 variants
-- ============================================================

SELECT
    experiment_name,
    variant,
    assigned_users,
    exposed_users,
    impressions,
    clicks,
    watch_starts,
    completions,
    ctr_pct,
    click_to_start_pct,
    completion_pct
FROM v_experiment_results
ORDER BY
    experiment_name,
    variant;


-- ============================================================
-- 5. SAMPLE USER SUMMARY
-- ============================================================

SELECT *
FROM v_user_summary
LIMIT 5;


-- ============================================================
-- 6. SAMPLE CHURN FEATURES
-- ============================================================

SELECT *
FROM v_churn_features
LIMIT 5;