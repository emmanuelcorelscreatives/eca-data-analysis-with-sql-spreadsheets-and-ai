-- Run after load.py: psql --dbname=practice --set=ON_ERROR_STOP=1 --file=practice/sql/checks.sql
DO $$ BEGIN
 IF (SELECT count(*) FROM customers) <> 5 OR (SELECT count(*) FROM products) <> 4 OR (SELECT count(*) FROM orders) <> 12 OR (SELECT count(*) FROM order_items) <> 12 OR (SELECT count(*) FROM returns) <> 4 THEN RAISE EXCEPTION 'Unexpected table row counts'; END IF;
 IF (SELECT sum(amount) FROM orders) <> 375 OR (SELECT sum(line_revenue) FROM order_items) <> 375 OR (SELECT sum(refund_amount) FROM returns) <> 32.50 THEN RAISE EXCEPTION 'Unexpected monetary control totals'; END IF;
 IF (SELECT count(*) FROM orders o JOIN customers c USING(customer_id)) <> 12 THEN RAISE EXCEPTION 'Customer join mismatch'; END IF;
 IF (SELECT count(*) FROM order_items oi LEFT JOIN products p USING(product_id)) <> 12 OR (SELECT count(*) FROM order_items oi LEFT JOIN products p USING(product_id) WHERE p.product_id IS NULL) <> 2 THEN RAISE EXCEPTION 'Product join mismatch'; END IF;
 IF EXISTS (SELECT 1 FROM orders GROUP BY date_trunc('month',order_date) HAVING count(*) <> 4 OR sum(amount) <> 125) THEN RAISE EXCEPTION 'Monthly totals mismatch'; END IF;
END $$;
SELECT 'retailer checks passed' AS result;
