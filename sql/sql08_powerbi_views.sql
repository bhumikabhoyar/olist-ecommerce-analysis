CREATE OR REPLACE VIEW fact_orders AS
WITH base AS (
  SELECT o.order_id, c.customer_unique_id, c.customer_state,
         o.purchased_at, o.purchased_at::date AS order_date,
         o.is_late, r.review_score,
         SUM(oi.price) AS revenue, SUM(oi.freight_value) AS freight
  FROM orders_clean o
  JOIN customers c   ON c.customer_id = o.customer_id
  JOIN order_items oi ON oi.order_id = o.order_id
  LEFT JOIN reviews_dedup r ON r.order_id = o.order_id
  WHERE o.order_status = 'delivered'
  GROUP BY o.order_id, c.customer_unique_id, c.customer_state,
           o.purchased_at, o.is_late, r.review_score
)
SELECT *,
  ROW_NUMBER() OVER (PARTITION BY customer_unique_id
                     ORDER BY purchased_at, order_id) = 1 AS is_first_order
FROM base;

CREATE OR REPLACE VIEW fact_items AS
SELECT oc.order_id, oc.purchased_at::date AS order_date,
       oi.product_id, oi.seller_id, oi.price, oi.freight_value,
       t.product_category_name_english AS category
FROM orders_clean oc
JOIN order_items oi ON oi.order_id = oc.order_id
JOIN products p ON p.product_id = oi.product_id
LEFT JOIN product_category_name_translation t
       ON t.product_category_name = p.product_category_name
WHERE oc.order_status = 'delivered';