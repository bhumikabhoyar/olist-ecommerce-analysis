CREATE OR REPLACE VIEW fact_sales AS
SELECT o.order_id, o.customer_id, o.purchased_at, o.delivered_at,
       o.estimated_at, o.is_late,
       oi.product_id, oi.seller_id, oi.price, oi.freight_value
FROM orders_clean o
JOIN order_items oi ON oi.order_id = o.order_id
WHERE o.order_status = 'delivered';