-- Run controls separately after adapting the same illustrative schema and period.
-- C1. Independent direct count and total; compare control_gross_revenue with Q1,
-- the sum of Q2, Q3, Q4, and Q5 revenue, and record any difference.
SELECT COUNT(DISTINCT o.order_id) AS paid_orders_with_items,
       COUNT(*) AS qualifying_item_rows,
       SUM(oi.quantity * oi.unit_price) AS control_gross_revenue
FROM orders AS o
JOIN order_items AS oi ON oi.order_id = o.order_id
WHERE o.status = 'paid'
  AND o.order_ts >= TIMESTAMPTZ '2025-01-01 00:00:00+00'
  AND o.order_ts <  TIMESTAMPTZ '2025-04-01 00:00:00+00';

-- C2. Exceptions that can invalidate or change the interpretation of answers.
WITH paid_orders AS (
    SELECT o.order_id, o.customer_id
    FROM orders AS o
    WHERE o.status = 'paid'
      AND o.order_ts >= TIMESTAMPTZ '2025-01-01 00:00:00+00'
      AND o.order_ts <  TIMESTAMPTZ '2025-04-01 00:00:00+00'
), item_checks AS (
    SELECT COUNT(*) FILTER (
               WHERE oi.quantity IS NULL OR oi.unit_price IS NULL
           ) AS null_line_inputs,
           COUNT(*) FILTER (
               WHERE p.product_id IS NULL
           ) AS missing_product_keys,
           COUNT(*) FILTER (
               WHERE p.product_id IS NOT NULL AND p.category IS NULL
           ) AS missing_categories
    FROM paid_orders AS o
    JOIN order_items AS oi ON oi.order_id = o.order_id
    LEFT JOIN products AS p ON p.product_id = oi.product_id
), order_checks AS (
    SELECT COUNT(*) FILTER (
               WHERE c.customer_id IS NULL
           ) AS missing_customer_keys,
           COUNT(*) FILTER (
               WHERE NOT EXISTS (
                   SELECT 1 FROM order_items AS oi
                   WHERE oi.order_id = o.order_id
               )
           ) AS paid_orders_without_items
    FROM paid_orders AS o
    LEFT JOIN customers AS c ON c.customer_id = o.customer_id
)
SELECT i.null_line_inputs, i.missing_product_keys, i.missing_categories,
       r.missing_customer_keys, r.paid_orders_without_items
FROM item_checks AS i CROSS JOIN order_checks AS r;

-- C3. Inspect period coverage and the product tie rule independently of exports.
-- Run each SELECT separately: a PostgreSQL WITH clause belongs to one statement.
SELECT generate_series(
    DATE '2025-01-01', DATE '2025-03-01', INTERVAL '1 month'
)::date AS expected_reporting_month;

WITH product_totals AS (
    SELECT oi.product_id, SUM(oi.quantity * oi.unit_price) AS gross_revenue
    FROM orders AS o
    JOIN order_items AS oi ON oi.order_id = o.order_id
    WHERE o.status = 'paid'
      AND o.order_ts >= TIMESTAMPTZ '2025-01-01 00:00:00+00'
      AND o.order_ts <  TIMESTAMPTZ '2025-04-01 00:00:00+00'
    GROUP BY oi.product_id
), tied_totals AS (
    SELECT gross_revenue
    FROM product_totals
    GROUP BY gross_revenue
    HAVING COUNT(*) > 1
)
SELECT p.product_id, p.gross_revenue,
       DENSE_RANK() OVER (ORDER BY p.gross_revenue DESC) AS tie_group_rank
FROM product_totals AS p
JOIN tied_totals AS t ON t.gross_revenue IS NOT DISTINCT FROM p.gross_revenue
ORDER BY p.gross_revenue DESC NULLS LAST, p.product_id NULLS LAST;

-- Empty tie output means no product-revenue tie was observed in this period.
-- Compare any displayed ties against Q4's ranks. Also confirm Q2 has exactly
-- the three expected month labels, and note which zeros came from its calendar.