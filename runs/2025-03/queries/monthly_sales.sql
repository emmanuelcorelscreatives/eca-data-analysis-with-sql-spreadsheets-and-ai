SELECT '2025-03' AS period, COUNT(*) AS order_count, SUM(amount) AS gross_sales FROM orders WHERE order_date >= DATE '2025-03-01' AND order_date < DATE '2025-04-01' AND status = 'completed';
