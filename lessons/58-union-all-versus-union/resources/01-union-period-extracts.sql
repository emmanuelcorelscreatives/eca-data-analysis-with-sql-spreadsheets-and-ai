-- Example 1: retain all six constructed input rows.
WITH july_extract (order_id, line_no, order_date, amount) AS (
    VALUES
        ('R-101', 1, DATE '2025-07-10', 20.00::numeric(10,2)),
        ('R-102', 1, DATE '2025-07-30', 25.00::numeric(10,2)),
        ('R-103', 1, DATE '2025-07-31', 40.00::numeric(10,2))
),
august_extract (order_id, line_no, order_date, amount) AS (
    VALUES
        ('R-102', 1, DATE '2025-07-30', 25.00::numeric(10,2)),
        ('R-103', 1, DATE '2025-07-31', 45.00::numeric(10,2)),
        ('R-104', 1, DATE '2025-08-05', 30.00::numeric(10,2))
)
SELECT order_id, line_no, order_date, amount FROM july_extract
UNION ALL
SELECT order_id, line_no, order_date, amount FROM august_extract
ORDER BY order_id, line_no, amount;

-- Example 2: remove only identical four-column result rows.
WITH july_extract (order_id, line_no, order_date, amount) AS (
    VALUES
        ('R-101', 1, DATE '2025-07-10', 20.00::numeric(10,2)),
        ('R-102', 1, DATE '2025-07-30', 25.00::numeric(10,2)),
        ('R-103', 1, DATE '2025-07-31', 40.00::numeric(10,2))
),
august_extract (order_id, line_no, order_date, amount) AS (
    VALUES
        ('R-102', 1, DATE '2025-07-30', 25.00::numeric(10,2)),
        ('R-103', 1, DATE '2025-07-31', 45.00::numeric(10,2)),
        ('R-104', 1, DATE '2025-08-05', 30.00::numeric(10,2))
)
SELECT order_id, line_no, order_date, amount FROM july_extract
UNION
SELECT order_id, line_no, order_date, amount FROM august_extract
ORDER BY order_id, line_no, amount;

-- Example 3: inspect overlap on the assumed business key.
WITH july_extract (order_id, line_no, order_date, amount) AS (
    VALUES
        ('R-101', 1, DATE '2025-07-10', 20.00::numeric(10,2)),
        ('R-102', 1, DATE '2025-07-30', 25.00::numeric(10,2)),
        ('R-103', 1, DATE '2025-07-31', 40.00::numeric(10,2))
),
august_extract (order_id, line_no, order_date, amount) AS (
    VALUES
        ('R-102', 1, DATE '2025-07-30', 25.00::numeric(10,2)),
        ('R-103', 1, DATE '2025-07-31', 45.00::numeric(10,2)),
        ('R-104', 1, DATE '2025-08-05', 30.00::numeric(10,2))
)
SELECT a.order_id, a.line_no,
       a.amount AS july_amount, b.amount AS august_amount
FROM july_extract AS a
JOIN august_extract AS b
  ON a.order_id = b.order_id AND a.line_no = b.line_no
ORDER BY a.order_id, a.line_no;

-- Check against the constructed inputs: UNION ALL returns 6 rows;
-- UNION returns 5; the overlap query returns 2 matching keys.
-- Establish a source rule before deciding which version of R-103 is authoritative.
-- PostgreSQL reference: https://www.postgresql.org/docs/current/queries-union.html