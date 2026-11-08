# Project 2 exercises

1. Load the supplied schema and identify the grain, key, period and status rule for each of the six saved queries before running it. Predict which endpoint and status rows will be excluded, then compare with actual execution.
2. Run Q1–Q6 separately. Export the six results with the filenames in the submission checklist. Reopen each export and compare column names and record counts with the result grid.
3. Execute the four separate control statements. Independently add the monthly, category, product and customer revenue results. Explain why five qualifying paid orders can coexist with four item-bearing orders and seven qualifying item rows.
4. Inspect February's zero and the tied product ranks. Distinguish a calendar-produced zero from an observed sales row. Explain why the tie-breaker orders rows but does not replace the dense-rank tie rule.
5. Complete the metric notes using observed results and the actual execution time. Document O2005's missing item rows and why C204 must not appear in the no-paid-orders answer. Do not invent an item value or label the case fully clean.
6. In a **separate learner copy** of the dataset, add one explicitly synthetic item to O2005: product P203, quantity 1, unit price 20.00, with a new unique item key. Record that this is a controlled practice change. Rerun all answers and controls. Predict the total and February revenue change, the exception count change, and whether Q6 should change; justify each result from the unchanged question definitions.
7. Build a second independent scenario in a separate schema with your own synthetic values. Include a boundary date, a tie and an order-versus-revenue distinction. Submit its setup/data, six commented read-only answers, six extracts, separate control results and completed notes. The reference solution's numbers are not valid observations for your new scenario.

Assessment checks whether someone else can reproduce your results, whether every exception is disclosed and investigated appropriately, and whether your explanation keeps the question, filter, grain and gross-revenue definition consistent.
