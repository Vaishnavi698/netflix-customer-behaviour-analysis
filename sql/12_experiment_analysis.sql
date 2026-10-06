-- ============================================================
-- NETFLIX CUSTOMER BEHAVIOUR ANALYTICS
-- 12 - EXPERIMENT ANALYSIS
-- ============================================================
--
-- Purpose:
-- Evaluate A/B experiment performance by comparing control
-- and treatment variants across engagement KPIs.
--
-- Experiments:
-- 1. Homepage Personalization
-- 2. Autoplay Next Episode
-- 3. New Release Row
--
-- Method:
-- - Use exposed users only for experiment outcome analysis.
-- - Compare treatment variants against Control.
-- - Report absolute difference and relative lift.
-- - Use an approximate two-proportion z-test for CTR.
--
-- Important:
-- This dataset is synthetic. Results are for portfolio/
-- analytical demonstration, not real Netflix decisions.
-- ============================================================


-- ============================================================
-- 1. EXPERIMENT ASSIGNMENT BALANCE
-- ============================================================

SELECT
    experiment_name,
    variant,

    COUNT(*) AS assigned_users,

    ROUND(
        100.0 * COUNT(*)
        / SUM(COUNT(*)) OVER (
            PARTITION BY experiment_name
        ),
        2
    ) AS assignment_pct

FROM experiments

GROUP BY
    experiment_name,
    variant

ORDER BY
    experiment_name,
    variant;


-- ============================================================
-- 2. EXPOSURE RATE
-- ============================================================

SELECT
    experiment_name,
    variant,

    COUNT(*) AS assigned_users,

    SUM(exposed) AS exposed_users,

    ROUND(
        100.0 * SUM(exposed)
        / NULLIF(COUNT(*), 0),
        2
    ) AS exposure_rate_pct

FROM experiments

GROUP BY
    experiment_name,
    variant

ORDER BY
    experiment_name,
    variant;


-- ============================================================
-- 3. HOMEPAGE PERSONALIZATION
-- KPI: CONTENT CTR
--
-- CTR = content_click / content_impression
-- ============================================================

WITH experiment_users AS (
    SELECT
        user_id,
        variant
    FROM experiments
    WHERE experiment_name = 'Homepage Personalization'
      AND exposed = 1
),

user_metrics AS (
    SELECT
        eu.user_id,
        eu.variant,

        SUM(
            CASE
                WHEN e.event_type = 'content_impression'
                THEN 1
                ELSE 0
            END
        ) AS impressions,

        SUM(
            CASE
                WHEN e.event_type = 'content_click'
                THEN 1
                ELSE 0
            END
        ) AS clicks

    FROM experiment_users eu

    LEFT JOIN events e
        ON eu.user_id = e.user_id

    GROUP BY
        eu.user_id,
        eu.variant
)

SELECT
    variant,

    COUNT(*) AS users,

    SUM(impressions) AS impressions,

    SUM(clicks) AS clicks,

    ROUND(
        100.0 * SUM(clicks)
        / NULLIF(SUM(impressions), 0),
        2
    ) AS ctr_pct

FROM user_metrics

GROUP BY
    variant

ORDER BY
    ctr_pct DESC;


-- ============================================================
-- 4. AUTOPLAY NEXT EPISODE
-- KPIs:
-- - Average session duration
-- - Average content watched
-- ============================================================

WITH experiment_users AS (
    SELECT
        user_id,
        variant
    FROM experiments
    WHERE experiment_name = 'Autoplay Next Episode'
      AND exposed = 1
),

user_metrics AS (
    SELECT
        eu.user_id,
        eu.variant,

        COUNT(s.session_id) AS sessions,

        AVG(s.session_duration_min)
            AS avg_session_duration,

        SUM(s.content_items_watched)
            AS content_watched

    FROM experiment_users eu

    LEFT JOIN sessions s
        ON eu.user_id = s.user_id

    GROUP BY
        eu.user_id,
        eu.variant
)

SELECT
    variant,

    COUNT(*) AS users,

    SUM(sessions) AS sessions,

    ROUND(
        AVG(avg_session_duration),
        2
    ) AS avg_session_duration,

    ROUND(
        AVG(content_watched),
        2
    ) AS avg_content_watched

FROM user_metrics

GROUP BY
    variant

ORDER BY
    avg_session_duration DESC;


-- ============================================================
-- 5. NEW RELEASE ROW
-- KPI: RECOMMENDATION CTR
-- ============================================================

WITH experiment_users AS (
    SELECT
        user_id,
        variant
    FROM experiments
    WHERE experiment_name = 'New Release Row'
      AND exposed = 1
),

user_metrics AS (
    SELECT
        eu.user_id,
        eu.variant,

        COUNT(r.recommendation_id) AS impressions,

        SUM(
            CASE
                WHEN r.clicked = 1
                THEN 1
                ELSE 0
            END
        ) AS clicks

    FROM experiment_users eu

    LEFT JOIN recommendations r
        ON eu.user_id = r.user_id

    GROUP BY
        eu.user_id,
        eu.variant
)

SELECT
    variant,

    COUNT(*) AS users,

    SUM(impressions) AS impressions,

    SUM(clicks) AS clicks,

    ROUND(
        100.0 * SUM(clicks)
        / NULLIF(SUM(impressions), 0),
        2
    ) AS ctr_pct

FROM user_metrics

GROUP BY
    variant

ORDER BY
    ctr_pct DESC;


-- ============================================================
-- 6. EXPERIMENT KPI SUMMARY
-- ============================================================

WITH user_metrics AS (
    SELECT
        e.experiment_name,
        e.variant,
        e.user_id,

        COUNT(DISTINCT s.session_id)
            AS sessions,

        COALESCE(
            AVG(s.session_duration_min),
            0
        ) AS avg_session_duration,

        COALESCE(
            SUM(s.content_items_watched),
            0
        ) AS content_watched

    FROM experiments e

    LEFT JOIN sessions s
        ON e.user_id = s.user_id

    WHERE e.exposed = 1

    GROUP BY
        e.experiment_name,
        e.variant,
        e.user_id
)

SELECT
    experiment_name,
    variant,

    COUNT(*) AS users,

    ROUND(
        AVG(sessions),
        2
    ) AS avg_sessions_per_user,

    ROUND(
        AVG(avg_session_duration),
        2
    ) AS avg_session_duration,

    ROUND(
        AVG(content_watched),
        2
    ) AS avg_content_watched

FROM user_metrics

GROUP BY
    experiment_name,
    variant

ORDER BY
    experiment_name,
    variant;


-- ============================================================
-- 7. SESSION DURATION LIFT VS CONTROL
-- ============================================================

WITH experiment_metrics AS (
    SELECT
        e.experiment_name,
        e.variant,

        COUNT(DISTINCT e.user_id) AS users,

        AVG(s.session_duration_min)
            AS avg_session_duration

    FROM experiments e

    LEFT JOIN sessions s
        ON e.user_id = s.user_id

    WHERE e.exposed = 1

    GROUP BY
        e.experiment_name,
        e.variant
),

control_metrics AS (
    SELECT
        experiment_name,

        avg_session_duration
            AS control_avg_session_duration

    FROM experiment_metrics

    WHERE LOWER(variant) = 'control'
)

SELECT
    em.experiment_name,
    em.variant,

    em.users,

    ROUND(
        em.avg_session_duration,
        2
    ) AS avg_session_duration,

    ROUND(
        em.avg_session_duration
        - cm.control_avg_session_duration,
        2
    ) AS absolute_change,

    ROUND(
        100.0 *
        (
            em.avg_session_duration
            - cm.control_avg_session_duration
        )
        / NULLIF(
            cm.control_avg_session_duration,
            0
        ),
        2
    ) AS lift_pct

FROM experiment_metrics em

JOIN control_metrics cm
    ON em.experiment_name = cm.experiment_name

ORDER BY
    em.experiment_name,
    lift_pct DESC;


-- ============================================================
-- 8. RECOMMENDATION FUNNEL BY EXPERIMENT
--
-- Metrics:
-- - CTR
-- - Click -> Start
-- - Start -> Completion
-- ============================================================

WITH experiment_users AS (
    SELECT
        user_id,
        experiment_name,
        variant

    FROM experiments

    WHERE exposed = 1
),

metrics AS (
    SELECT
        eu.experiment_name,
        eu.variant,

        COUNT(r.recommendation_id)
            AS impressions,

        SUM(
            CASE
                WHEN r.clicked = 1
                THEN 1
                ELSE 0
            END
        ) AS clicks,

        SUM(
            CASE
                WHEN r.watch_started = 1
                THEN 1
                ELSE 0
            END
        ) AS watch_starts,

        SUM(
            CASE
                WHEN r.watch_completed = 1
                THEN 1
                ELSE 0
            END
        ) AS completions

    FROM experiment_users eu

    LEFT JOIN recommendations r
        ON eu.user_id = r.user_id

    GROUP BY
        eu.experiment_name,
        eu.variant
)

SELECT
    experiment_name,
    variant,

    impressions,
    clicks,
    watch_starts,
    completions,

    ROUND(
        100.0 * clicks
        / NULLIF(impressions, 0),
        2
    ) AS ctr_pct,

    ROUND(
        100.0 * watch_starts
        / NULLIF(clicks, 0),
        2
    ) AS click_to_start_pct,

    ROUND(
        100.0 * completions
        / NULLIF(watch_starts, 0),
        2
    ) AS completion_pct

FROM metrics

ORDER BY
    experiment_name,
    ctr_pct DESC;


-- ============================================================
-- 9. HOMEPAGE PERSONALIZATION
-- CTR LIFT VS CONTROL
-- ============================================================

WITH variant_metrics AS (
    SELECT
        e.variant,

        SUM(
            CASE
                WHEN ev.event_type = 'content_impression'
                THEN 1
                ELSE 0
            END
        ) AS impressions,

        SUM(
            CASE
                WHEN ev.event_type = 'content_click'
                THEN 1
                ELSE 0
            END
        ) AS clicks

    FROM experiments e

    LEFT JOIN events ev
        ON e.user_id = ev.user_id

    WHERE e.experiment_name = 'Homepage Personalization'
      AND e.exposed = 1

    GROUP BY
        e.variant
),

metrics AS (
    SELECT
        variant,
        impressions,
        clicks,

        1.0 * clicks
        / NULLIF(impressions, 0)
        AS ctr

    FROM variant_metrics
),

control AS (
    SELECT
        ctr AS control_ctr

    FROM metrics

    WHERE LOWER(variant) = 'control'
)

SELECT
    m.variant,

    m.impressions,
    m.clicks,

    ROUND(
        100.0 * m.ctr,
        2
    ) AS ctr_pct,

    ROUND(
        100.0 * (m.ctr - c.control_ctr),
        2
    ) AS absolute_change_pp,

    ROUND(
        100.0 *
        (m.ctr - c.control_ctr)
        / NULLIF(c.control_ctr, 0),
        2
    ) AS lift_pct

FROM metrics m

CROSS JOIN control c

ORDER BY
    lift_pct DESC;


-- ============================================================
-- 10. HOMEPAGE PERSONALIZATION
-- APPROXIMATE TWO-PROPORTION Z-TEST
--
-- The z-score is used as the significance indicator.
--
-- |z| >= 1.96 is treated as statistically significant
-- at approximately the 5% level.
--
-- We intentionally do not report a p-value here because
-- SQLite does not provide a native normal CDF function.
-- ============================================================

WITH variant_metrics AS (
    SELECT
        e.variant,

        SUM(
            CASE
                WHEN ev.event_type = 'content_impression'
                THEN 1
                ELSE 0
            END
        ) AS impressions,

        SUM(
            CASE
                WHEN ev.event_type = 'content_click'
                THEN 1
                ELSE 0
            END
        ) AS clicks

    FROM experiments e

    LEFT JOIN events ev
        ON e.user_id = ev.user_id

    WHERE e.experiment_name = 'Homepage Personalization'
      AND e.exposed = 1

    GROUP BY
        e.variant
),

rates AS (
    SELECT
        variant,
        impressions,
        clicks,

        1.0 * clicks
        / NULLIF(impressions, 0)
        AS conversion_rate

    FROM variant_metrics
),

control AS (
    SELECT
        impressions AS control_n,
        clicks AS control_clicks,
        conversion_rate AS control_rate

    FROM rates

    WHERE LOWER(variant) = 'control'
),

treatment AS (
    SELECT
        impressions AS treatment_n,
        clicks AS treatment_clicks,
        conversion_rate AS treatment_rate

    FROM rates

    WHERE LOWER(variant) = 'treatment'
),

test AS (
    SELECT
        control_n,
        control_clicks,
        control_rate,

        treatment_n,
        treatment_clicks,
        treatment_rate,

        1.0 *
        (control_clicks + treatment_clicks)
        / NULLIF(
            control_n + treatment_n,
            0
        ) AS pooled_rate

    FROM control
    CROSS JOIN treatment
),

statistics AS (
    SELECT
        *,

        treatment_rate - control_rate
            AS difference,

        SQRT(
            pooled_rate
            * (1.0 - pooled_rate)
            * (
                1.0 / control_n
                + 1.0 / treatment_n
            )
        ) AS standard_error

    FROM test
)

SELECT
    ROUND(
        100.0 * control_rate,
        2
    ) AS control_ctr_pct,

    ROUND(
        100.0 * treatment_rate,
        2
    ) AS treatment_ctr_pct,

    ROUND(
        100.0 * difference,
        2
    ) AS difference_pp,

    ROUND(
        100.0 * difference
        / NULLIF(control_rate, 0),
        2
    ) AS lift_pct,

    ROUND(
        difference
        / NULLIF(standard_error, 0),
        3
    ) AS z_score,

    CASE
        WHEN ABS(
            difference
            / NULLIF(standard_error, 0)
        ) >= 1.96
        THEN 'Statistically significant'
        ELSE 'Not statistically significant'
    END AS significance_flag

FROM statistics;


-- ============================================================
-- 11. EXPERIMENT DECISION SUMMARY
-- ============================================================

WITH experiment_metrics AS (
    SELECT
        e.experiment_name,
        e.variant,

        COUNT(DISTINCT e.user_id)
            AS users,

        AVG(s.session_duration_min)
            AS avg_session_duration

    FROM experiments e

    LEFT JOIN sessions s
        ON e.user_id = s.user_id

    WHERE e.exposed = 1

    GROUP BY
        e.experiment_name,
        e.variant
),

control AS (
    SELECT
        experiment_name,

        avg_session_duration
            AS control_duration

    FROM experiment_metrics

    WHERE LOWER(variant) = 'control'
)

SELECT
    em.experiment_name,
    em.variant,

    em.users,

    ROUND(
        em.avg_session_duration,
        2
    ) AS avg_session_duration,

    ROUND(
        em.avg_session_duration
        - c.control_duration,
        2
    ) AS duration_change,

    ROUND(
        100.0 *
        (
            em.avg_session_duration
            - c.control_duration
        )
        / NULLIF(c.control_duration, 0),
        2
    ) AS duration_lift_pct,

    CASE
        WHEN em.avg_session_duration
             > c.control_duration
        THEN 'Higher engagement'

        WHEN em.avg_session_duration
             < c.control_duration
        THEN 'Lower engagement'

        ELSE 'No change'
    END AS interpretation

FROM experiment_metrics em

JOIN control c
    ON em.experiment_name = c.experiment_name

ORDER BY
    em.experiment_name,
    duration_lift_pct DESC;