"""Load into a separate eca_project2 schema; Python 3 + psql, no extra packages.
Standard libpq PG* variables/service or psql password prompt provide connection.
An existing schema makes this transaction fail without changing its contents.
"""
from pathlib import Path
import csv, subprocess, argparse
p=argparse.ArgumentParser();p.add_argument('--database',default='practice');args=p.parse_args()
root=Path(__file__).resolve().parent
commands=['BEGIN;', (root/'schema.sql').read_text()]
for table in ['customers','products','orders','order_items','returns']:
 with (root/'data'/(table+'.csv')).open(newline='',encoding='utf-8') as f:
  rows=csv.reader(f);columns=next(rows)
  for row in rows:
   if len(row)!=len(columns):raise ValueError('Bad row in '+table)
   values=["NULL" if value=='' else "'"+value.replace("'","''")+"'" for value in row]
   commands.append('INSERT INTO '+table+' ('+','.join(columns)+') VALUES ('+','.join(values)+');')
commands.append('COMMIT;')
subprocess.run(['psql','--no-psqlrc','--dbname='+args.database,'--set=ON_ERROR_STOP=1'],input='\n'.join(commands),text=True,check=True)
