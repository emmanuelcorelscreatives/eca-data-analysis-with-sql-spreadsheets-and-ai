# Retailer practice kit — Emmanuel Corels Academy

This synthetic kit supports the saved Data Analysis with SQL, Spreadsheets and AI course. It supplies the five promised retailer tables. It does not replace independent inline SQL/CSV examples in later lessons.

## Local setup

Install PostgreSQL with psql and Python 3. Create an isolated empty database named practice with a local role you control. Configure your own connection with PostgreSQL's normal PGHOST/PGPORT/PGUSER and password prompt or private pgpass file. No Academy password or hosted sandbox is supplied. Never connect this loader to production.

From the repository root, run `python practice/load.py`, then `psql --dbname=practice --set=ON_ERROR_STOP=1 --file=practice/sql/checks.sql`. On Windows use `py` if that is your Python launcher. The loader is transactional, never drops tables and refuses existing tables. For pgAdmin, connect to the same local practice database and confirm `SELECT current_database();` and all five tables after loading.

Open data/*.csv in Excel or Google Sheets with identifiers as text, ISO dates and decimal numbers. Read DATA_DICTIONARY.md before interpreting grain or joining returns. CONTROL_TOTALS.json and EXERCISES.md provide checks, tasks and solution totals. The small extract includes January, a February second period and March for reproducibility. Product-key exceptions and repeated return events are intentional, documented exercise cases.

See reproducibility.py for the actual March run and hash manifest. No generated value is labelled as an executed result until the supplied checks are run.

From the repository root, run `python practice/reproducibility.py`, then `psql --dbname=practice --set=ON_ERROR_STOP=1 --file=practice/sql/run_march.sql` to verify the March CSV calculation in PostgreSQL. The run uses line revenue and distinct order IDs for completed sales, excludes return events, and preserves hashes and paths relative to the run manifest. The temporary import table disappears at commit.

The March run interprets each supplied calendar date at midnight UTC and applies the saved lecture's exact inclusive start and exclusive cutoff: 2025-03-01 00:00:00 UTC through 2025-04-01 00:00:00 UTC. The SQL explicitly uses AT TIME ZONE and TIMESTAMPTZ; the base CSV dictionary still describes date-only source fields.

## Lesson 49: check the actual join results

The orders/customers walkthrough uses this starter kit directly. After loading it, the saved checks return 12 total orders, 12 matched orders, no duplicate customer keys and no null customer keys. The ordered join sample returns the first 10 rows; that LIMIT does not count all matching orders.

[Executed queries, schemas and expected result rows](verification/lesson49_inner_join.json) record the actual checks against these synthetic files. Rerun the commands after changing data; do not copy a count from a screenshot. Other lessons can define independent inline VALUES fixtures, whose original data and answers remain separate.


## Lesson 66: separate Project 2 schema

Use [the Project 2 kit](project2/README.md) for the saved `order_ts` / `paid` analysis-pack queries. It includes a separate transactional loader, synthetic input CSVs, six actual answer extracts, four separate controls, an independent verifier and exercises. It does not change the basic kit or replace independent inline SQL fixtures.
