WITH cat AS (
  SELECT t.product_category_name_english AS category,
         CASE WHEN f.purchased_at < '2018-06-01' THEN 'A_Jan_May' ELSE 'B_Jun_Aug' END AS period,
         f.price, f.order_id
  FROM fact_sales f
  JOIN products p ON p.product_id = f.product_id
  LEFT JOIN product_category_name_translation t
         ON t.product_category_name = p.product_category_name
  WHERE f.purchased_at >= '2018-01-01'
)
SELECT category,
       ROUND((SUM(price) FILTER (WHERE period = 'A_Jan_May') / 5)::numeric, 0) AS rev_per_month_A,
       ROUND((SUM(price) FILTER (WHERE period = 'B_Jun_Aug') / 3)::numeric, 0) AS rev_per_month_B
FROM cat
GROUP BY category
ORDER BY SUM(price) DESC
LIMIT 15;