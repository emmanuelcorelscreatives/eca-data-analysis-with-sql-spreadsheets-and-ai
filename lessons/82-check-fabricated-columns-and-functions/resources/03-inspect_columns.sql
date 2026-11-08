SELECT table_schema, table_name, column_name, data_type
FROM information_schema.columns
WHERE table_name = 'orders'
ORDER BY table_schema, ordinal_position;