# Synthetic retailer data dictionary

This is invented course practice data, not a real retailer or personal data. Currency is illustrative USD. Identifiers are text; preserve leading zeros. Dates are ISO calendar dates, not timestamps. CSV encoding is UTF-8, comma-delimited with headers; an empty product_id means SQL NULL.

| Table | Grain and key | Fields and meaning |
|---|---|---|
| customers | One customer, customer_id | customer_name synthetic display name; region customer region |
| products | One listed product, product_id | product_name, category |
| orders | One purchase, order_id | customer_id joins customers; order_date; region at purchase; status; amount gross line revenue, before recorded refunds |
| order_items | One purchased line, order_item_id | order_id joins orders; product_id nullable/possibly unmatched; quantity units on the line; unit_price USD per unit; discount_amount USD per line; line_revenue = quantity * unit_price - discount_amount |
| returns | One return/refund event, return_id | order_item_id joins order_items; return_date; quantity_returned physical units for this event (zero allowed for a refund adjustment); refund_amount USD |

An order can have several lines; this small base extract happens to have one each. A line is not one physical unit. A line can have multiple refund events: L101 has two events, the second a monetary adjustment. Aggregate returns to line grain before joining to prevent multiplication of sales. Do not treat event counts as returned-unit counts.

The two final lines intentionally have unmatched product references: L111 has P999 (absent from products), L112 has NULL. Preserve both as exceptions. No category should be invented for either. Customer keys are complete/unique and every order matches a customer. Separate inline VALUES examples and lesson-specific CSVs are independent fixtures, not a replacement for these tables.

Reporting periods use half-open dates: January [2025-01-01,2025-02-01), February [2025-02-01,2025-03-01), March [2025-03-01,2025-04-01). Gross sales includes all completed orders; refunds are separate event-date amounts. Net after refunds requires declaring the chosen event/order-date convention. Do not silently mix them.
