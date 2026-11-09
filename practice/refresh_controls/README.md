# Lesson 89: Workbook refresh controls

Emmanuel Corels Academy

This constructed practice extract uses seven paid order-item records from the supplied Project 2 fixtures. All revenue in this derived exercise is denominated in USD. The source reporting period is 2025-01-01 00:00:00 UTC inclusive through 2025-04-01 00:00:00 UTC exclusive.

Import source_extract.csv into the Google Sheets Extract tab at A1. Create Control using the lesson's supplied workbook refresh-control specification; preserve its exact cell coordinates and formulas. Independently executed source controls are 7 rows and USD 400.00, as recorded in VERIFICATION.json. Run source_extract.sql and independent_controls.sql against the supplied eca_project2 practice schema to reproduce them. Keep these source controls independent of formulas over the loaded Extract tab.

After the completed load, enter =NOW() in Control!B3, copy it and use Edit > Paste special > Values only. Confirm the spreadsheet time zone in File > Settings. Keep this fixed refresh time separate from Control!B2's source reporting cutoff. Format B12:B14 as USD currency for this practice extract. Investigate any discrepancy; do not alter expectations to force PASS.
