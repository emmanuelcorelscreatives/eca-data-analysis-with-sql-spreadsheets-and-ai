# Retailer practice and checks

1. Inspect all five CSVs before loading; confirm grain, text identifiers, decimal types, UTF-8 and NULL handling using the dictionary.
2. Load the practice database and verify current_database() returns practice. Compare row counts and gross totals with CONTROL_TOTALS.json.
3. INNER JOIN orders to customers using the saved lesson49 commands. Record total orders and matched orders; check uniqueness first.
4. LEFT JOIN items to products using lesson50 commands. Separate the absent P999 reference from the NULL key; prove no lines were lost or multiplied.
5. Aggregate refund events to line grain before joining. Explain why a raw events join duplicates L101 sales. Compare total gross sales, refund amounts and the declared net convention.
6. Use January as the first extract and February as a second period. Apply identical measure/population rules and half-open date bounds. Explain why a single month's region difference is not causal evidence.
7. Run the March reproducibility example. Inspect actual input/query/output SHA256 values, relative paths and timestamp. Change a COPY of an input and show its hash changes; never alter the delivered manifest silently.

See sql/checks.sql for executable base-data assertions. Each month: 4 orders, gross sales 125.00. Full data: 12 orders/lines, gross 375.00, refunds 32.50. Products join: 12 retained lines,10 matched,2 unmatched (one NULL and one absent key). L101 has two return events; units returned =1, refund amount=7.50.
