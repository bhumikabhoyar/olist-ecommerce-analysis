SELECT
  ROUND(SUM(f.price) FILTER (WHERE f.is_late)::numeric, 0)      AS late_revenue,
  ROUND(SUM(f.price)::numeric, 0)                               AS total_revenue,
  ROUND((100.0 * SUM(f.price) FILTER (WHERE f.is_late) / SUM(f.price))::numeric, 1) AS late_share_pct
FROM fact_sales f
WHERE f.delivered_at IS NOT NULL;