-- ============================================================
-- SESSION 10: RETENTION AFTER ACTIVATION
-- Observation-window adjusted retention
-- ============================================================

WITH first_activity AS (
    SELECT
        user_id,
        MIN(activity_date) AS first_active_date
    FROM daily_activity
    WHERE session_count > 0
    GROUP BY user_id
),

user_activity AS (
    SELECT
        da.user_id,
        fa.first_active_date,

        CAST(
            (
                julianday(da.activity_date)
                - julianday(fa.first_active_date)
            ) / 7
            AS INTEGER
        ) AS weeks_since_activation

    FROM daily_activity da
    JOIN first_activity fa
        ON da.user_id = fa.user_id

    WHERE da.session_count > 0
),

max_activity_date AS (
    SELECT MAX(activity_date) AS max_activity_date
    FROM daily_activity
),

weekly_retention AS (
    SELECT
        ua.weeks_since_activation,
        COUNT(DISTINCT ua.user_id) AS retained_users,

        (
            SELECT COUNT(*)
            FROM first_activity fa
            CROSS JOIN max_activity_date mad
            WHERE date(
                fa.first_active_date,
                '+' || (ua.weeks_since_activation * 7) || ' days'
            ) <= mad.max_activity_date
        ) AS eligible_users

    FROM user_activity ua

    GROUP BY ua.weeks_since_activation
)

SELECT
    weeks_since_activation,
    retained_users,
    eligible_users,

    ROUND(
        100.0 * retained_users / eligible_users,
        2
    ) AS retention_rate_pct

FROM weekly_retention

ORDER BY weeks_since_activation;