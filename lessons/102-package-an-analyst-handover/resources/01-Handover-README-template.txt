# Analyst handover

Purpose: [Decision or report this bundle supports]
Prepared on: [Date and version]
Owner: [Responsible team or approved contact]
Reporting period or cutoff: [Period, cutoff, and relevant time basis]
Approved input location: [Access-controlled location and input identifier; no credentials]
Output location: [Approved destination]

## Files
- `sql/sales_summary.sql` — checked query; replace this example name with the actual file name.
- `workbook/sales_report.xlsx` — checked report; replace this example name with the actual file name.
- `dictionary/data_dictionary.csv` — fields, grain, null rules, and sources.
- `checks/control_totals.csv` — recorded checks by run and cutoff.
- `refresh/runbook.md` — refresh sequence, checks, and failure handling.

## Reading and running order
1. Read `dictionary/data_dictionary.csv` and the approved metric definitions at [location].
2. Obtain the approved input and confirm its reporting cutoff.
3. Run the checked query in the authorized environment, following `refresh/runbook.md`.
4. Refresh `workbook/sales_report.xlsx` from the controlled output.
5. Record and compare checks in `checks/control_totals.csv` before sharing the report.

## Review before handoff
Open every listed path. Confirm the file names, input and output locations, cutoff, metric definitions, owner, and prior verified checks are present. Remove bracketed instructions only after replacing them with real details.