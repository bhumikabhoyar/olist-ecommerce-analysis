-- one point per zip prefix (the geolocation table has many rows per zip)
CREATE OR REPLACE VIEW geo_zip AS
SELECT geolocation_zip_code_prefix AS zip,
       AVG(geolocation_lat) AS lat,
       AVG(geolocation_lng) AS lng
FROM geolocation
GROUP BY 1;

-- average seller-to-customer distance per order (haversine, km)
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