-- Run from the repository root. Local PostgreSQL practice database only.
BEGIN;
CREATE TEMP TABLE orders_export (order_id text, order_date date, status text, order_item_id text, line_revenue numeric(12,2)) ON COMMIT DROP;
\copy orders_export FROM 'runs/2025-03/inputs/orders_export.csv' WITH (FORMAT csv, HEADER true)
\ir ../../runs/2025-03/queries/monthly_sales.sql
COMMIT;
