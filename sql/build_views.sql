-- build_views.sql
-- All views used by the Olist analysis, in dependency order.
-- Run by run_pipeline.py (keep this file free of the percent character).
 
-- 1. Orders in the analysis window (Jan 2017 to Aug 2018), dates cast from text
CREATE OR REPLACE VIEW orders_clean AS
SELECT
  order_id, customer_id, order_status,
  order_purchase_timestamp::timestamp        AS purchased_at,
  order_delivered_customer_date::timestamp   AS delivered_at,
  order_estimated_delivery_date::timestamp   AS estimated_at,
  (order_delivered_customer_date::timestamp > order_estimated_delivery_date::timestamp) AS is_late
FROM orders
WHERE order_purchase_timestamp::timestamp >= '2017-01-01'
  AND order_purchase_timestamp::timestamp <  '2018-09-01';
 
-- 2. One review per order (latest review wins)
CREATE OR REPLACE VIEW reviews_dedup AS
SELECT DISTINCT ON (order_id) order_id, review_score
FROM order_reviews
ORDER BY order_id, review_creation_date DESC;
 
-- 3. Item-level sales of delivered orders
CREATE OR REPLACE VIEW fact_sales AS
SELECT o.order_id, o.customer_id, o.purchased_at, o.delivered_at,
       o.estimated_at, o.is_late,
       oi.product_id, oi.seller_id, oi.price, oi.freight_value
FROM orders_clean o
JOIN order_items oi ON oi.order_id = o.order_id
WHERE o.order_status = 'delivered';
 
-- 4. Order-level fact table for Power BI
CREATE OR REPLACE VIEW fact_orders AS
WITH base AS (
  SELECT o.order_id, c.customer_unique_id, c.customer_state,
         o.purchased_at, o.purchased_at::date AS order_date,
         o.is_late, r.review_score,
         SUM(oi.price) AS revenue, SUM(oi.freight_value) AS freight
  FROM orders_clean o
  JOIN customers c    ON c.customer_id = o.customer_id
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
 
-- 5. Item-level fact table with category names for Power BI
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
 
-- 6. One point per zip prefix (the geolocation table has many rows per zip)
CREATE OR REPLACE VIEW geo_zip AS
SELECT geolocation_zip_code_prefix AS zip,
       AVG(geolocation_lat) AS lat,
       AVG(geolocation_lng) AS lng
FROM geolocation
GROUP BY 1;
 
-- 7. Average seller-to-customer distance per order (haversine, km)
CREATE OR REPLACE VIEW order_distance AS
SELECT oi.order_id,
       AVG(6371 * 2 * ASIN(LEAST(1.0, SQRT(
           POWER(SIN(RADIANS(gc.lat - gs.lat) / 2), 2) +
           COS(RADIANS(gs.lat)) * COS(RADIANS(gc.lat)) *
           POWER(SIN(RADIANS(gc.lng - gs.lng) / 2), 2))))) AS distance_km
FROM order_items oi
JOIN orders o     ON o.order_id = oi.order_id
JOIN customers c  ON c.customer_id = o.customer_id
JOIN sellers s    ON s.seller_id = oi.seller_id
JOIN geo_zip gc   ON gc.zip = c.customer_zip_code_prefix
JOIN geo_zip gs   ON gs.zip = s.seller_zip_code_prefix
GROUP BY oi.order_id;
 