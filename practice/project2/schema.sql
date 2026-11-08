-- Separate Project 2 namespace; never reset or replace an existing dataset.
CREATE SCHEMA eca_project2;
SET LOCAL search_path TO eca_project2, pg_catalog;
CREATE TABLE customers (customer_id text PRIMARY KEY);
CREATE TABLE products (product_id text PRIMARY KEY, category text);
CREATE TABLE orders (order_id text PRIMARY KEY, customer_id text REFERENCES customers(customer_id), order_ts timestamptz NOT NULL, status text NOT NULL);
CREATE TABLE order_items (order_item_id text PRIMARY KEY, order_id text REFERENCES orders(order_id), product_id text REFERENCES products(product_id), quantity integer CHECK(quantity >= 0), unit_price numeric(12,2) CHECK(unit_price >= 0));
CREATE TABLE returns (return_id text PRIMARY KEY, order_item_id text REFERENCES order_items(order_item_id), refund_amount numeric(12,2) NOT NULL CHECK(refund_amount >= 0));
