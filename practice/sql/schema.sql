CREATE TABLE customers (customer_id text PRIMARY KEY, customer_name text NOT NULL, region text NOT NULL);
CREATE TABLE products (product_id text PRIMARY KEY, product_name text NOT NULL, category text NOT NULL);
CREATE TABLE orders (order_id text PRIMARY KEY, customer_id text REFERENCES customers, order_date date NOT NULL, region text NOT NULL, status text NOT NULL, amount numeric(12,2) NOT NULL);
-- Product reference deliberately allows NULL/P999 for the missing-match exercise.
CREATE TABLE order_items (order_item_id text PRIMARY KEY, order_id text NOT NULL REFERENCES orders, product_id text, quantity integer NOT NULL CHECK (quantity>=0), unit_price numeric(12,2) NOT NULL, discount_amount numeric(12,2) NOT NULL, line_revenue numeric(12,2) NOT NULL);
CREATE TABLE returns (return_id text PRIMARY KEY, order_item_id text NOT NULL REFERENCES order_items, return_date date NOT NULL, quantity_returned integer NOT NULL CHECK (quantity_returned>=0), refund_amount numeric(12,2) NOT NULL);
