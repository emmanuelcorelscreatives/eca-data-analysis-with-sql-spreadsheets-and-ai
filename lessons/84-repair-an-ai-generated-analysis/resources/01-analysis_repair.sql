-- Fictional teaching fixture. Read-only: no tables are created or changed.
-- Net sales: completed-order item gross less refunds recorded before
-- 2025-03-15 00:00:00+00; report by UTC order month.
WITH
orders(order_id, ordered_at, status) AS (
    VALUES
        (101, TIMESTAMPTZ '2025-01-05 12:00:00+00', 'completed'),
        (102, TIMESTAMPTZ '2025-01-20 12:00:00+00', 'completed'),
        (103, TIMESTAMPTZ '2025-02-03 12:00:00+00', 'completed'),
        (104, TIMESTAMPTZ '2025-02-08 12:00:00+00', 'cancelled')
),
order_items(order_id, item_id, quantity, unit_price) AS (
    VALUES
        (101, 1, 1, 100.00::numeric),
        (101, 2, 1,  50.00::numeric),
        (102, 3, 1,  80.00::numeric),
        (103, 4, 1, 120.00::numeric),
        (104, 5, 1, 200.00::numeric)
),
return_events(order_id, item_id, refunded_at, refund_amount) AS (
    VALUES
        (101, 1, TIMESTAMPTZ '2025-02-10 12:00:00+00', 30.00::numeric),
        (101, 1, TIMESTAMPTZ '2025-02-12 12:00:00+00', 20.00::numeric),
        (103, 4, TIMESTAMPTZ '2025-03-01 12:00:00+00', 10.00::numeric)
),
-- Original mistake: an order-level join multiplies its item rows.
bad_rows AS (
    SELECT date_trunc('month', o.ordered_at AT TIME ZONE 'UTC')::date AS order_month,
           i.quantity * i.unit_price AS gross,
           COALESCE(r.refund_amount, 0::numeric) AS refund
    FROM orders o
    JOIN order_items i ON i.order_id = o.order_id
    LEFT JOIN return_events r
      ON r.order_id = o.order_id
     AND r.refunded_at < TIMESTAMPTZ '2025-03-15 00:00:00+00'
    WHERE o.status = 'completed'
      AND o.ordered_at >= TIMESTAMPTZ '2025-01-01 00:00:00+00'
      AND o.ordered_at <  TIMESTAMPTZ '2025-03-01 00:00:00+00'
),
bad_month AS (
    SELECT order_month, SUM(gross - refund) AS net
    FROM bad_rows GROUP BY order_month
),
scoped_items AS (
    SELECT o.order_id, i.item_id,
           date_trunc('month', o.ordered_at AT TIME ZONE 'UTC')::date AS order_month,
           i.quantity * i.unit_price AS gross
    FROM orders o
    JOIN order_items i ON i.order_id = o.order_id
    WHERE o.status = 'completed'
      AND o.ordered_at >= TIMESTAMPTZ '2025-01-01 00:00:00+00'
      AND o.ordered_at <  TIMESTAMPTZ '2025-03-01 00:00:00+00'
),
returns_by_item AS (
    SELECT order_id, item_id, SUM(refund_amount) AS refund_total
    FROM return_events
    WHERE refunded_at < TIMESTAMPTZ '2025-03-15 00:00:00+00'
    GROUP BY order_id, item_id
),
repaired_rows AS (
    SELECT s.order_id, s.item_id, s.order_month, s.gross,
           COALESCE(rb.refund_total, 0::numeric) AS refund
    FROM scoped_items s
    LEFT JOIN returns_by_item rb
      ON rb.order_id = s.order_id
     AND rb.item_id = s.item_id
),
repaired_month AS (
    SELECT order_month, SUM(gross - refund) AS net
    FROM repaired_rows GROUP BY order_month
),
-- Separate order-level calculation: never join item rows to event rows.
independent_orders AS (
    SELECT o.order_id,
           date_trunc('month', o.ordered_at AT TIME ZONE 'UTC')::date AS order_month,
           (SELECT SUM(i.quantity * i.unit_price)
              FROM order_items i WHERE i.order_id = o.order_id) AS gross,
           COALESCE((SELECT SUM(r.refund_amount)
                       FROM return_events r
                      WHERE r.order_id = o.order_id
                        AND r.refunded_at < TIMESTAMPTZ '2025-03-15 00:00:00+00'),
                    0::numeric) AS refund
    FROM orders o
    WHERE o.status = 'completed'
      AND o.ordered_at >= TIMESTAMPTZ '2025-01-01 00:00:00+00'
      AND o.ordered_at <  TIMESTAMPTZ '2025-03-01 00:00:00+00'
),
independent_month AS (
    SELECT order_month, SUM(gross - refund) AS net
    FROM independent_orders GROUP BY order_month
),
unmatched_return_keys AS (
    SELECT r.order_id, r.item_id
    FROM return_events r
    WHERE r.refunded_at < TIMESTAMPTZ '2025-03-15 00:00:00+00'
      AND NOT EXISTS (
          SELECT 1 FROM order_items i
          WHERE i.order_id = r.order_id AND i.item_id = r.item_id
      )
),
checks(check_name, observed, expected) AS (
    SELECT 'bad_january_reproduced',
           (SELECT net FROM bad_month WHERE order_month = DATE '2025-01-01'),
           280::numeric
    UNION ALL SELECT 'bad_join_rows', (SELECT COUNT(*) FROM bad_rows), 6::numeric
    UNION ALL SELECT 'scoped_item_rows', (SELECT COUNT(*) FROM scoped_items), 4::numeric
    UNION ALL SELECT 'repaired_item_rows', (SELECT COUNT(*) FROM repaired_rows), 4::numeric
    UNION ALL SELECT 'unmatched_return_keys',
                     (SELECT COUNT(*) FROM unmatched_return_keys), 0::numeric
    UNION ALL SELECT 'repaired_january_net',
                     (SELECT net FROM repaired_month WHERE order_month = DATE '2025-01-01'),
                     180::numeric
    UNION ALL SELECT 'repaired_february_net',
                     (SELECT net FROM repaired_month WHERE order_month = DATE '2025-02-01'),
                     110::numeric
    UNION ALL SELECT 'independent_january_net',
                     (SELECT net FROM independent_month WHERE order_month = DATE '2025-01-01'),
                     180::numeric
    UNION ALL SELECT 'independent_february_net',
                     (SELECT net FROM independent_month WHERE order_month = DATE '2025-02-01'),
                     110::numeric
    UNION ALL SELECT 'repaired_two_month_net',
                     (SELECT SUM(net) FROM repaired_month), 290::numeric
)
SELECT check_name, observed, expected,
       observed IS NOT DISTINCT FROM expected AS passes
FROM checks
ORDER BY check_name;

-- PostgreSQL documentation for the behaviors used here:
-- Joins and grouping: https://www.postgresql.org/docs/current/queries-table-expressions.html
-- Aggregate functions: https://www.postgresql.org/docs/current/functions-aggregate.html
-- Date/time functions: https://www.postgresql.org/docs/current/functions-datetime.html