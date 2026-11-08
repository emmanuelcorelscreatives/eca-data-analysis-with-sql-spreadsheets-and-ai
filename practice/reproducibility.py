"""Create lesson98's real March files and hashes from the supplied synthetic data.
Python 3 only. Then verify with the actual PostgreSQL command in README.md.
"""
from pathlib import Path
from datetime import datetime, timezone
from decimal import Decimal
import csv, hashlib
root = Path(__file__).resolve().parents[1]
run = root / 'runs/2025-03'
for name in ('inputs', 'queries', 'outputs'):
    (run / name).mkdir(parents=True, exist_ok=True)
with (root / 'practice/data/orders.csv').open(newline='', encoding='utf-8') as source:
    orders = {r['order_id']: r for r in csv.DictReader(source)}
with (root / 'practice/data/order_items.csv').open(newline='', encoding='utf-8') as source:
    items = list(csv.DictReader(source))
rows = []
for item in items:
    order = orders[item['order_id']]
    if '2025-03-01' <= order['order_date'] < '2025-04-01':
        rows.append({**{k:order[k] for k in ('order_id','order_date','status')},
                     'order_item_id':item['order_item_id'], 'line_revenue':item['line_revenue']})
with (run / 'inputs/orders_export.csv').open('w', newline='', encoding='utf-8') as output:
    writer = csv.DictWriter(output, ['order_id','order_date','status','order_item_id','line_revenue'], lineterminator='\n')
    writer.writeheader(); writer.writerows(rows)
query = """SELECT '2025-03' AS period,
       COUNT(DISTINCT order_id) AS order_count,
       SUM(line_revenue) AS monthly_revenue
FROM orders_export
WHERE (order_date::timestamp AT TIME ZONE 'UTC') >= TIMESTAMPTZ '2025-03-01 00:00:00+00'
  AND (order_date::timestamp AT TIME ZONE 'UTC') < TIMESTAMPTZ '2025-04-01 00:00:00+00'
  AND status = 'completed';
"""
(run / 'queries/monthly_sales.sql').write_text(query, encoding='utf-8')
qualifying = [r for r in rows if r['status'] == 'completed']
with (run / 'outputs/monthly_sales.csv').open('w', newline='', encoding='utf-8') as output:
    writer = csv.writer(output, lineterminator='\n')
    writer.writerow(['period','order_count','monthly_revenue'])
    writer.writerow(['2025-03', len({r['order_id'] for r in qualifying}),
                     f"{sum((Decimal(r['line_revenue']) for r in qualifying), Decimal('0')):.2f}"])
lines = ['Report: March sales',
         'Run identifier: 2025-03-synthetic-retailer',
         'Input: inputs\\orders_export.csv',
         'Query: queries\\monthly_sales.sql',
         'Output: outputs\\monthly_sales.csv']
for label, path in [('Input','inputs/orders_export.csv'), ('Query','queries/monthly_sales.sql'), ('Output','outputs/monthly_sales.csv')]:
    lines.append(label + ' SHA256: ' + hashlib.sha256((run / path).read_bytes()).hexdigest())
lines += ['Reporting start: 2025-03-01 00:00:00 UTC (inclusive)',
          'Reporting cutoff: 2025-04-01 00:00:00 UTC (exclusive)',
          'Monthly revenue: Sum of line revenue for completed sales within the reporting window, USD; exclude return events; round to two decimal places for display only.',
          'Order count: Distinct order_id values for the same qualifying completed sales.',
          'Generated at: ' + datetime.now(timezone.utc).isoformat(),
          'Input upstream export or snapshot ID: synthetic-retailer-v1',
          'Query Git commit: not applicable (identified by SHA256)',
          'Calculation: Python Decimal; compare with PostgreSQL using practice/sql/run_march.sql.']
(run / 'run_manifest.txt').write_text('\n'.join(lines) + '\n', encoding='utf-8')
print('Created actual March files and SHA256 manifest.')
