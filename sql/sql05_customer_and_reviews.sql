SELECT o.is_late, COUNT(*) AS orders, ROUND(AVG(r.review_score), 2) AS avg_score
FROM orders_clean o
JOIN reviews_dedup r ON r.order_id = o.order_id
WHERE o.order_status = 'delivered' AND o.delivered_at IS NOT NULL
GROUP BY o.is_late;