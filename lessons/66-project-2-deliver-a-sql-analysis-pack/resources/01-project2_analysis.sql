-- Project 2 example: verify table names, columns, status values, and metric rules against your course schema.
-- Assumed tables: orders(order_id, customer_id, order_ts, status),
-- order_items(order_item_id, order_id, product_id, quantity, unit_price),
-- products(product_id, category), customers(customer_id).
-- Example period: [2025-01-01 00:00:00+00, 2025-04-01 00:00:00+00).
-- Qualifying status: paid. Gross revenue: SUM(quantity * unit_price) on qualifying items.
-- Returns are NOT deducted. Resolve exceptions identified by project2_controls.sql
-- before trusting product, category, or customer answers.

-- Q1. What is gross revenue for qualifying items in the period?
SELECT SUM(oi.quantity * oi.unit_price) AS gross_revenue
FROM orders AS o
JOIN order_items AS oi ON oi.order_id = o.order_id
WHERE o.status = 'paid'
  AND o.order_ts >= TIMESTAMPTZ '2025-01-01 00:00:00+00'
  AND o.order_ts <  TIMESTAMPTZ '2025-04-01 00:00:00+00';

-- Q2. What is gross revenue in each reporting month, including months with no lines?
WITH calendar AS (
    SELECT generate_series(
        DATE '2025-01-01', DATE '2025-03-01', INTERVAL '1 month'
    )::date AS reporting_month
), monthly AS (
    SELECT date_trunc('month', o.order_ts AT TIME ZONE 'UTC')::date AS reporting_month,
           SUM(oi.quantity * oi.unit_price) AS gross_revenue
    FROM orders AS o
    JOIN order_items AS oi ON oi.order_id = o.order_id
    WHERE o.status = 'paid'
      AND o.order_ts >= TIMESTAMPTZ '2025-01-01 00:00:00+00'
      AND o.order_ts <  TIMESTAMPTZ '2025-04-01 00:00:00+00'
    GROUP BY 1
)
SELECT c.reporting_month, COALESCE(m.gross_revenue, 0) AS gross_revenue
FROM calendar AS c
LEFT JOIN monthly AS m ON m.reporting_month = c.reporting_month
ORDER BY c.reporting_month;

-- Q3. What is gross revenue by recorded product category?
-- A missing product match or category will appear as a null category; investigate it.
SELECT p.category, SUM(oi.quantity * oi.unit_price) AS gross_revenue
FROM orders AS o
JOIN order_items AS oi ON oi.order_id = o.order_id
LEFT JOIN products AS p ON p.product_id = oi.product_id
WHERE o.status = 'paid'
  AND o.order_ts >= TIMESTAMPTZ '2025-01-01 00:00:00+00'
  AND o.order_ts <  TIMESTAMPTZ '2025-04-01 00:00:00+00'
GROUP BY p.category
ORDER BY gross_revenue DESC NULLS LAST, p.category NULLS LAST;

-- Q4. Which products rank highest by gross revenue? Equal revenues share a rank.
-- Product identifier supplies deterministic output order within a tie.
WITH product_totals AS (
    SELECT oi.product_id, SUM(oi.quantity * oi.unit_price) AS gross_revenue
    FROM orders AS o
    JOIN order_items AS oi ON oi.order_id = o.order_id
    WHERE o.status = 'paid'
      AND o.order_ts >= TIMESTAMPTZ '2025-01-01 00:00:00+00'
      AND o.order_ts <  TIMESTAMPTZ '2025-04-01 00:00:00+00'
    GROUP BY oi.product_id
)
SELECT product_id, gross_revenue,
       DENSE_RANK() OVER (ORDER BY gross_revenue DESC) AS revenue_rank
FROM product_totals
ORDER BY gross_revenue DESC NULLS LAST, product_id NULLS LAST;

-- Q5. What revenue did each customer contribute, and what share of total?
-- A null share means the total denominator is zero or unavailable.
WITH customer_totals AS (
    SELECT o.customer_id, SUM(oi.quantity * oi.unit_price) AS gross_revenue
    FROM orders AS o
    JOIN order_items AS oi ON oi.order_id = o.order_id
    WHERE o.status = 'paid'
      AND o.order_ts >= TIMESTAMPTZ '2025-01-01 00:00:00+00'
      AND o.order_ts <  TIMESTAMPTZ '2025-04-01 00:00:00+00'
    GROUP BY o.customer_id
)
SELECT customer_id, gross_revenue,
       gross_revenue / NULLIF(SUM(gross_revenue) OVER (), 0) AS revenue_share
FROM customer_totals
ORDER BY gross_revenue DESC NULLS LAST, customer_id NULLS LAST;

-- Q6. Which listed customers have no paid order in the period?
-- A paid order without items still disqualifies a customer from this list.
SELECT c.customer_id
FROM customers AS c
WHERE NOT EXISTS (
    SELECT 1
    FROM orders AS o
    WHERE o.customer_id = c.customer_id
      AND o.status = 'paid'
      AND o.order_ts >= TIMESTAMPTZ '2025-01-01 00:00:00+00'
      AND o.order_ts <  TIMESTAMPTZ '2025-04-01 00:00:00+00'
)
ORDER BY c.customer_id;