# Project 2: Deliver a SQL Analysis Pack

Emmanuel Corels Academy supplies this synthetic worked example for lesson 66 of **Data Analysis with SQL, Spreadsheets and AI**. It implements the exact illustrative `order_ts` / `status = 'paid'` schema used by the saved lesson resources. Those SQL and worksheet files are copied verbatim. The separate basic retailer kit uses different column names and status values; do not mix the two datasets or their results.

## Load and run

Use an authorized PostgreSQL practice database. Python 3 and `psql` must be available. Configure your normal libpq connection through `PGHOST`, `PGPORT`, `PGUSER` and a password prompt or password/service file; do not commit credentials.

```sh
python3 load.py --database=practice
python3 verify.py --database=practice
```

The loader creates only the new `eca_project2` schema in one transaction. If that schema already exists, loading fails and leaves its contents unchanged. It does not drop or replace tables. `LOADER_PROTECTION.json` records an actual second-load refusal and unchanged fingerprints for both this schema and the basic kit's five public tables.

In pgAdmin's Query Tool or `psql`, use the supplied schema before executing the saved answer/control statements:

```sql
SET search_path TO eca_project2, pg_catalog;
SET TIME ZONE 'UTC';
```

Run each statement in `project2_analysis.sql` separately, then each statement in `project2_controls.sql` separately. In particular, the two C3 statements each have their own query scope. Use a read-only transaction for analysis. The verification program executes every statement in a read-only transaction and exports the actual results; it does not modify data.

## Definitions and boundary cases

The reporting interval is January 1, 2025 inclusive through April 1, 2025 exclusive in UTC. Only exact lowercase `paid` orders qualify. Gross revenue is item quantity times unit price. The supplied return demonstrates that this measure does **not** deduct refunds.

The input CSVs contain six customers, three products, nine orders, eleven items and one return. They exercise:

- Both reporting interval endpoints, with an order just before the start and another exactly at the exclusive end.
- Cancelled and pending orders inside the period that must not enter revenue.
- A February calendar row with zero qualifying item revenue.
- Equal product revenues that must share a dense rank and retain deterministic product-ID ordering.
- A customer with a paid order but no items, plus customers with no qualifying paid order.

`O2005` is intentionally a paid order without item rows. C2 reports **one**, not zero, for that exception. Its listed customer `C204` is excluded from Q6 because the order exists; it contributes no item revenue. This is a disclosed synthetic exercise condition, not evidence that an analogous real business exception has been resolved. In your own analysis, investigate the source and record its treatment before drawing conclusions.

## Actually executed worked results

`VERIFICATION.json` binds the input and exact saved SQL hashes to live PostgreSQL results and independent Python Decimal checks. The checked reference run returned gross revenue **400.00**, monthly revenues **180.00 / 0 / 220.00**, seven qualifying item rows across four item-bearing paid orders, and five qualifying paid orders overall. Product `P201` and `P202` each returned **160.00**, both rank 1. `P203` returned **80.00**, rank 2. Customer shares reconcile to one; Q6 returns `C205` and `C206`.

The six actual answer CSVs are in `answers/`. Four actual control CSVs are in `controls/`; they are separate from the answers. `verify.py` reopens every exported file, checks headers and rows against execution, and reconciles answers with independently calculated source-data totals. Rerun after any data change. These reference results are not promises about a different database.

Keep the supplied `metric_notes.txt` worksheet as a blank learner template. The completed observations and exception decision for this worked example are in `VERIFICATION.json`. Follow `submission_checklist.txt` for your own submission, and use `EXERCISES.md` for independent practice.


## Browser view of the checked reference pack

Open `analysis_pack.html` from this complete folder to view the six real answer extracts beside their SQL, observed metric notes and separate controls. This is an Academy-authored browser document, not a simulated database application. It is a static reference to the execution timestamp and input hashes in `VERIFICATION.json`; after changing data, use fresh query outputs and verification instead of treating this reference page as a new run. SQL and CSV links open the corresponding supplied files.
