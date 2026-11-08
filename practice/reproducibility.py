"""Create the actual lesson98 March input/query/output and SHA256 manifest."""
from pathlib import Path
from datetime import datetime, timezone
from decimal import Decimal
import csv, hashlib, io
root=Path(__file__).resolve().parents[1]
run=root/'runs/2025-03'
for name in ('inputs','queries','outputs'):(run/name).mkdir(parents=True,exist_ok=True)
with (root/'practice/data/orders.csv').open(newline='',encoding='utf-8') as f:
    source=csv.DictReader(f);fields=source.fieldnames;rows=[r for r in source if '2025-03-01' <= r['order_date'] < '2025-04-01']
with (run/'inputs/orders_export.csv').open('w',newline='',encoding='utf-8') as f:
    w=csv.DictWriter(f,fields,lineterminator='\n');w.writeheader();w.writerows(rows)
query="SELECT '2025-03' AS period, COUNT(*) AS order_count, SUM(amount) AS gross_sales FROM orders WHERE order_date >= DATE '2025-03-01' AND order_date < DATE '2025-04-01' AND status = 'completed';\n"
(run/'queries/monthly_sales.sql').write_text(query,encoding='utf-8')
# Independently check this output against the same SQL in PostgreSQL before capture.
qualifying=[r for r in rows if r['status']=='completed']
with (run/'outputs/monthly_sales.csv').open('w',newline='',encoding='utf-8') as f:
    w=csv.writer(f,lineterminator='\n');w.writerow(['period','order_count','gross_sales']);w.writerow(['2025-03',len(qualifying),f"{sum((Decimal(r['amount']) for r in qualifying),Decimal('0')):.2f}"])
lines=['Report name: March gross sales','Run identifier: 2025-03-synthetic-retailer']
for label,path in [('Input 1','inputs/orders_export.csv'),('Query','queries/monthly_sales.sql'),('Output','outputs/monthly_sales.csv')]:
    lines += [label+' path, relative to this manifest: '+path,label+' SHA256: '+hashlib.sha256((run/path).read_bytes()).hexdigest()]
lines += ['Input 1 upstream export or snapshot ID: synthetic-retailer-v1','Query Git commit: not applicable (content identified by SHA256)','Reporting start: 2025-03-01 inclusive, calendar date without timezone','Reporting cutoff: 2025-04-01 exclusive, calendar date without timezone','Metric definitions: gross_sales = SUM(amount), completed orders in the stated period, refunds excluded, illustrative USD rounded to two decimals; order_count = qualifying order rows','Generated at: '+datetime.now(timezone.utc).isoformat(),'Execution: output calculated by Python Decimal; verify against saved SQL on the same practice data before presenting a database result.']
(run/'run_manifest.txt').write_text('\n'.join(lines)+'\n',encoding='utf-8')
print('Created actual March files and SHA256 manifest.')
