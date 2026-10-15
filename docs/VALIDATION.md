# Validation scope

## Checked during repository preparation

- All four R source files parsed with the Tree-sitter R grammar without syntax errors.
- R chunks in the editable report parsed without syntax errors.
- Python report/figure generator executed successfully.
- Reference posterior estimates and LOO differences compared with the source PDF.
- Original PDF copied without modification.
- Local Markdown links, figure references and archive contents checked.
- Clean PDF rendered for visual review.

## Newly supplied input audit

The two original workbooks were read with pandas/openpyxl. Unique, nonmissing
participant IDs were confirmed. All 384 MRI subjects matched the 985-row clinical
table; the full join had 985 rows and yielded 384 cases complete for the five
analysis variables, excluding 601 incomplete rows. Binary coding was checked,
and predictor means/sample SDs and category counts were recorded.

See `results/validation/` for aggregate counts, scaling constants and SHA-256 input
checksums. No participant-level records are included. This independent Python audit
confirms the cohort selection, but does not execute or validate the R/Stan model fit.

## Not yet verified

- R execution: an R executable was not available in the preparation environment.
- The included base-R synthetic preprocessing tests have not been executed.
- R Markdown knitting, brms/Stan compilation and sampling have not been executed.
- Original fitted objects and posterior draws were not supplied.
- Numerical model results have not been reproduced in a new R/Stan run.

The included historical figures are redrawn from aggregate results. They are
not evidence that the reconstructed analysis has been rerun. Before using new
results, execute the preprocessing checks and full analysis locally, inspect
diagnostics, and compare the generated audit tables and estimates with the source.
