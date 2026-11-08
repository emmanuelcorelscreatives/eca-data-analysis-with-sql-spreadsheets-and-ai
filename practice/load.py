"""Load the synthetic retailer kit into an EMPTY practice database; Python 3 + psql only.
Create practice first, then run from any directory. Standard PGHOST, PGPORT,
PGUSER, PGDATABASE, PGPASSFILE/interactive password apply. No credentials are saved.
Existing tables cause a transaction rollback; this script never drops tables.
"""
from pathlib import Path
import csv, subprocess
root = Path(__file__).resolve().parent
commands = ["BEGIN;", (root / "sql/schema.sql").read_text()]
for name in ("customers", "products", "orders", "order_items", "returns"):
    with (root / "data" / (name + ".csv")).open(newline="", encoding="utf-8") as source:
        reader = csv.reader(source)
        columns = next(reader)
        for row in reader:
            if len(row) != len(columns):
                raise ValueError("Invalid CSV row in " + name)
            values = ["NULL" if value == "" else "'" + value.replace("'", "''") + "'" for value in row]
            commands.append("INSERT INTO " + name + " (" + ",".join(columns) + ") VALUES (" + ",".join(values) + ");")
commands.append("COMMIT;")
subprocess.run(["psql", "--dbname=practice", "--no-psqlrc", "--set=ON_ERROR_STOP=1"], input="\n".join(commands), text=True, check=True)
