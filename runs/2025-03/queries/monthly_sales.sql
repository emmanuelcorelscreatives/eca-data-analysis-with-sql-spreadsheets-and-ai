SELECT '2025-03' AS period,
       COUNT(DISTINCT order_id) AS order_count,
       SUM(line_revenue) AS monthly_revenue
FROM orders_export
WHERE order_date >= DATE '2025-03-01'
  AND order_date < DATE '2025-04-01'
  AND status = 'completed';
