SELECT 'customers' t, COUNT(*) FROM customers
UNION ALL SELECT 'orders', COUNT(*) FROM orders
UNION ALL SELECT 'order_items', COUNT(*) FROM order_items
UNION ALL SELECT 'order_payments', COUNT(*) FROM order_payments
UNION ALL SELECT 'order_reviews', COUNT(*) FROM order_reviews
UNION ALL SELECT 'products', COUNT(*) FROM products
UNION ALL SELECT 'sellers', COUNT(*) FROM sellers;

SELECT COUNT(*) AS total, COUNT(DISTINCT order_id) AS uniq FROM orders;


SELECT order_status, COUNT(*) AS n,
       ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 2) AS pct
FROM orders GROUP BY order_status ORDER BY n DESC;

SELECT
  COUNT(*) FILTER (WHERE order_approved_at IS NULL) AS no_approval,
  COUNT(*) FILTER (WHERE order_delivered_carrier_date IS NULL) AS no_carrier,
  COUNT(*) FILTER (WHERE order_delivered_customer_date IS NULL) AS no_delivery
FROM orders;

SELECT MIN(order_purchase_timestamp::timestamp),
       MAX(order_purchase_timestamp::timestamp)
FROM orders;

SELECT DATE_TRUNC('month', order_purchase_timestamp::timestamp) AS month,
       COUNT(*) AS orders
FROM orders GROUP BY 1 ORDER BY 1;

SELECT COUNT(*) FROM order_items oi
LEFT JOIN orders o ON o.order_id = oi.order_id
WHERE o.order_id IS NULL;

SELECT MIN(price), ROUND(AVG(price)::numeric,2), MAX(price),
       MIN(freight_value), MAX(freight_value)
FROM order_items;

SELECT COUNT(*) AS review_rows, COUNT(DISTINCT order_id) AS orders_reviewed
FROM order_reviews;

-- A: top 10 priciest items
SELECT order_id, product_id, price, freight_value
FROM order_items ORDER BY price DESC LIMIT 10;

-- B: delivered orders with no delivery date
SELECT COUNT(*) FROM orders
WHERE order_status = 'delivered' AND order_delivered_customer_date IS NULL;

-- C: orders with more than one review
SELECT COUNT(*) FROM (
  SELECT order_id FROM order_reviews GROUP BY order_id HAVING COUNT(*) > 1
) t;

-- D: canceled orders that still have a delivery date
SELECT COUNT(*) FROM orders
WHERE order_status = 'canceled' AND order_delivered_customer_date IS NOT NULL;