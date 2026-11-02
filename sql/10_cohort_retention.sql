WITH cohorts AS (
  SELECT customer_unique_id, MIN(order_month) AS cohort
  FROM cohort_orders GROUP BY 1
),
activity AS (
  SELECT DISTINCT o.customer_unique_id, c.cohort,
         ((EXTRACT(YEAR FROM o.order_month) - EXTRACT(YEAR FROM c.cohort)) * 12
          + EXTRACT(MONTH FROM o.order_month) - EXTRACT(MONTH FROM c.cohort))::int AS month_n
  FROM cohort_orders o
  JOIN cohorts c ON c.customer_unique_id = o.customer_unique_id
)
SELECT cohort,
       COUNT(DISTINCT customer_unique_id) FILTER (WHERE month_n = 0) AS cohort_size,
       ROUND(100.0 * COUNT(DISTINCT customer_unique_id) FILTER (WHERE month_n = 1)
             / COUNT(DISTINCT customer_unique_id) FILTER (WHERE month_n = 0), 2) AS m1_pct,
       ROUND(100.0 * COUNT(DISTINCT customer_unique_id) FILTER (WHERE month_n = 3)
             / COUNT(DISTINCT customer_unique_id) FILTER (WHERE month_n = 0), 2) AS m3_pct,
       ROUND(100.0 * COUNT(DISTINCT customer_unique_id) FILTER (WHERE month_n = 6)
             / COUNT(DISTINCT customer_unique_id) FILTER (WHERE month_n = 0), 2) AS m6_pct
FROM activity
WHERE cohort BETWEEN '2017-01-01' AND '2017-12-01'
GROUP BY cohort
ORDER BY cohort;