-- Fictional test rows only. Does not read or change course tables.
-- Hand expectations, in SELECT-column order:
-- input_rows 8; march_rows 6; distinct_march_lines 5;
-- march_orders 5; repeated_102_rows 2;
-- missing_price_lines 1; missing_customer_lines 1;
-- zero_quantity_lines 1; zero_price_lines 1;
-- known_revenue 25 (excludes the line whose price is unknown).
WITH input(line_id, order_id, sold_at, quantity, unit_price, customer_id) AS (
    VALUES
        (101, 501, '2025-03-01 00:00:00+00'::timestamptz, 2, 10::numeric, 1),
        (102, 502, '2025-03-31 23:59:59+00'::timestamptz, 1, 5::numeric, 1),
        (102, 502, '2025-03-31 23:59:59+00'::timestamptz, 1, 5::numeric, 1),
        (103, 503, '2025-04-01 00:00:00+00'::timestamptz, 1, 7::numeric, 2),
        (104, 504, '2025-03-15 12:00:00+00'::timestamptz, 0, 9::numeric, NULL::integer),
        (105, 505, '2025-03-20 12:00:00+00'::timestamptz, 1, NULL::numeric, 3),
        (106, 506, '2025-02-28 23:59:59+00'::timestamptz, 1, 11::numeric, 4),
        (107, 507, '2025-03-10 12:00:00+00'::timestamptz, 1, 0::numeric, 5)
),
march AS (
    SELECT * FROM input
    WHERE sold_at >= '2025-03-01 00:00:00+00'::timestamptz
      AND sold_at < '2025-04-01 00:00:00+00'::timestamptz
),
unique_lines AS (
    SELECT DISTINCT * FROM march
)
SELECT
    (SELECT COUNT(*) FROM input) AS input_rows,
    (SELECT COUNT(*) FROM march) AS march_rows,
    COUNT(*) AS distinct_march_lines,
    COUNT(DISTINCT order_id) AS march_orders,
    (SELECT COUNT(*) FROM march WHERE line_id = 102) AS repeated_102_rows,
    COUNT(*) FILTER (WHERE unit_price IS NULL) AS missing_price_lines,
    COUNT(*) FILTER (WHERE customer_id IS NULL) AS missing_customer_lines,
    COUNT(*) FILTER (WHERE quantity = 0) AS zero_quantity_lines,
    COUNT(*) FILTER (WHERE unit_price = 0) AS zero_price_lines,
    SUM(quantity * unit_price) AS known_revenue
FROM unique_lines;
