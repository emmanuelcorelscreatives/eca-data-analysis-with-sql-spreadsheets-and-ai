"""Execute saved read-only SQL, export results, and independently check CSV data.
Requires Python 3 + psql. Uses the same libpq connection options as load.py.
Never changes data or rewrites the saved question/control statements.
"""
from pathlib import Path
import argparse,csv,datetime,decimal,hashlib,io,json,subprocess
D=decimal.Decimal
p=argparse.ArgumentParser();p.add_argument('--database',default='practice');args=p.parse_args();root=Path(__file__).resolve().parent

def rows(name):
 with (root/'data'/(name+'.csv')).open(newline='',encoding='utf-8') as f:return list(csv.DictReader(f))
def split_statements(source):
 # Preserve authored bytes; semicolons inside comments/quoted literals do not
 # end SQL statements. Nested block comments and doubled quote escapes count.
 result=[];start=0;i=0;quote=None;line_comment=False;block_depth=0;has_code=False
 while i<len(source):
  char=source[i];pair=source[i:i+2]
  if line_comment:
   if char=='\n':line_comment=False
  elif block_depth:
   if pair=='/*':block_depth+=1;i+=1
   elif pair=='*/':block_depth-=1;i+=1
  elif quote:
   if char==quote:
    if i+1<len(source) and source[i+1]==quote:i+=1
    else:quote=None
  elif pair=='--':line_comment=True;i+=1
  elif pair=='/*':block_depth=1;i+=1
  elif char in ("'",'"'):quote=char;has_code=True
  elif char==';':
   if has_code:result.append(source[start:i+1].strip())
   start=i+1;has_code=False
  elif not char.isspace():has_code=True
  i+=1
 if quote or block_depth:raise ValueError('Unterminated SQL literal/comment')
 if has_code:result.append(source[start:].strip())
 return result

def statements(file):return split_statements((root/file).read_text())
assert len(split_statements("-- q; x\nSELECT ';' AS \"a;b\"; /* a; /* b; */ c; */ SELECT 2; -- tail;"))==2

def execute(sql):
 run=subprocess.run(['psql','-X','--dbname='+args.database,'--set=ON_ERROR_STOP=1','--csv','-q','-c',"BEGIN READ ONLY; SET LOCAL search_path TO eca_project2, pg_catalog; SET LOCAL TIME ZONE 'UTC';\n"+sql+'\nROLLBACK;'],text=True,capture_output=True,check=True)
 data=list(csv.DictReader(io.StringIO(run.stdout)))
 return run.stdout,data

orders={x['order_id']:x for x in rows('orders')};customers=rows('customers');products={x['product_id']:x for x in rows('products')};items=rows('order_items')
start=datetime.datetime.fromisoformat('2025-01-01T00:00:00+00:00');end=datetime.datetime.fromisoformat('2025-04-01T00:00:00+00:00')
qualifying={key:o for key,o in orders.items() if o['status']=='paid' and start<=datetime.datetime.fromisoformat(o['order_ts'])<end}
lines=[x for x in items if x['order_id'] in qualifying];total=sum((D(x['quantity'])*D(x['unit_price']) for x in lines),D(0));monthly={f'2025-{m:02}-01':D(0) for m in range(1,4)};category={};product={};customer={}
for x in lines:
 o=qualifying[x['order_id']];amount=D(x['quantity'])*D(x['unit_price']);month=datetime.datetime.fromisoformat(o['order_ts']).astimezone(datetime.timezone.utc).strftime('%Y-%m-01');monthly[month]+=amount
 cat=products[x['product_id']]['category'];category[cat]=category.get(cat,D(0))+amount;product[x['product_id']]=product.get(x['product_id'],D(0))+amount;customer[o['customer_id']]=customer.get(o['customer_id'],D(0))+amount
expected_no_paid=sorted(c['customer_id'] for c in customers if c['customer_id'] not in {o['customer_id'] for o in qualifying.values()});rank={v:i+1 for i,v in enumerate(sorted(set(product.values()),reverse=True))};ties={v for v in product.values() if list(product.values()).count(v)>1}
analysis=statements('project2_analysis.sql');controls=statements('project2_controls.sql');assert len(analysis)==6 and len(controls)==4
names=['q01_revenue.csv','q02_monthly_revenue.csv','q03_category_revenue.csv','q04_product_ranking.csv','q05_customer_share.csv','q06_customers_without_paid_orders.csv'];cnames=['c01_reconciliation.csv','c02_exceptions.csv','c03_month_coverage.csv','c03_product_ties.csv'];observations={}
for name,query in zip(names+cnames,analysis+controls):
 raw,data=execute(query);folder='answers' if name in names else 'controls';file=root/folder/name;file.write_text(raw);assert list(csv.DictReader(io.StringIO(file.read_text())))==data
 observations[name]={'query':query,'rows':data,'csvSha256':hashlib.sha256(file.read_bytes()).hexdigest(),'rowCount':len(data)}
r=lambda name:observations[name]['rows']
assert len(r(names[0]))==1 and D(r(names[0])[0]['gross_revenue'])==total
assert {x['reporting_month']:D(x['gross_revenue']) for x in r(names[1])}==monthly
assert {x['category']:D(x['gross_revenue']) for x in r(names[2])}==category
assert [(x['product_id'],D(x['gross_revenue']),int(x['revenue_rank'])) for x in r(names[3])]==[(k,product[k],rank[product[k]]) for k in sorted(product,key=lambda k:(-product[k],k))]
assert [(x['customer_id'],D(x['gross_revenue']),D(x['revenue_share'])) for x in r(names[4])]==[(k,customer[k],customer[k]/total) for k in sorted(customer,key=lambda k:(-customer[k],k))]
assert [x['customer_id'] for x in r(names[5])]==expected_no_paid
c1=r(cnames[0])[0];assert int(c1['paid_orders_with_items'])==len({x['order_id'] for x in lines}) and int(c1['qualifying_item_rows'])==len(lines) and D(c1['control_gross_revenue'])==total
no_items=sorted(set(qualifying)-{x['order_id'] for x in items});c2=r(cnames[1])[0];assert {key:int(value) for key,value in c2.items()}=={'null_line_inputs':0,'missing_product_keys':0,'missing_categories':0,'missing_customer_keys':0,'paid_orders_without_items':len(no_items)}
assert [x['expected_reporting_month'] for x in r(cnames[2])]==list(monthly)
assert [(x['product_id'],D(x['gross_revenue']),int(x['tie_group_rank'])) for x in r(cnames[3])]==[(k,product[k],sorted(ties,reverse=True).index(product[k])+1) for k in sorted(product,key=lambda k:(-product[k],k)) if product[k] in ties]
assert sum((D(x['gross_revenue']) for x in r(names[1])),D(0))==total
for n in names[2:5]:assert sum((D(x['gross_revenue']) for x in r(n)),D(0))==total
assert sum((D(x['revenue_share']) for x in r(names[4])),D(0))==1
assert len(qualifying)==5 and len(lines)==7 and total==D('400.00') and no_items==['O2005']
report={'checkedAt':datetime.datetime.now(datetime.timezone.utc).isoformat(),'actualExecution':True,'schema':'eca_project2','savedAnalysisAndControlsUnchanged':True,'independentPythonDecimalChecksPassed':True,'allExtractHeadersAndRowsReopened':True,'inputFiles':{f.name:hashlib.sha256(f.read_bytes()).hexdigest() for f in sorted((root/'data').glob('*.csv'))},'sourceFiles':{n:hashlib.sha256((root/n).read_bytes()).hexdigest() for n in ['project2_analysis.sql','project2_controls.sql']},'observations':observations,'independentExpected':{'totalGrossRevenue':str(total),'monthlyGrossRevenue':{k:str(v) for k,v in monthly.items()},'paidOrders':len(qualifying),'paidOrdersWithItems':len({x['order_id'] for x in lines}),'qualifyingItemRows':len(lines),'paidOrdersWithoutItems':no_items,'customersWithoutPaidOrders':expected_no_paid},'exceptionDecision':'O2005 is an intentional synthetic paid order without item rows. It contributes no line revenue, disqualifies C204 from Q6, and is retained with a disclosed limitation; this is not an assertion that a real business exception was resolved. Investigate the analogous exception in your own dataset.'}
(root/'VERIFICATION.json').write_text(json.dumps(report,indent=2)+'\n');print(json.dumps({'actualExecution':True,'independentPythonDecimalChecksPassed':True,'answerExports':6,'controlExports':4,'grossRevenue':str(total),'paidOrdersWithoutItems':no_items}))
