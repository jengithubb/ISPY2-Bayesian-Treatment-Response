# Reconstruction record

## Source and scope

Source: `reports/source-course-report.pdf`, supplied by the author. Its title page
is dated 2026-03-05. The editable original was unavailable. The source PDF is
retained unchanged; the clean report is a new presentation of the recorded analysis.

## Preserved analysis choices

- Full join by the clinical patient identifier and MRI subject identifier.
- Complete-case filtering on pCR, diameter, sphericity, HR and HER2.
- Standardization of diameter and sphericity using complete-case means and SDs.
- Bernoulli likelihood and logit link; imaging-only, additive and interaction formulas.
- Intercept prior Normal(0, 1.5), imaging coefficients Normal(0, 0.7),
  receptor and interaction coefficients Normal(0, 1).
- Four chains; 4,000 iterations; 2,000 warmup; seed 123.
- LOO comparison and additive-model refit using package-default priors.

The default `brms` coefficient priors should not all be described as proper weakly
informative priors: the source's `get_prior()` output includes flat defaults for
class `b`. A new run records the installed package versions.

## Packaging changes

- Relative paths replace personal Downloads paths; XLSX can be read directly.
- Input schemas, binary coding, ID uniqueness and nonzero predictor variation are checked.
- Aggregate cohort and scaling audits are exported; raw rows are not.
- The R script adds a binary-outcome bar posterior predictive check. The source used
  a density overlay. New diagnostic exports are additions, not original results.
- New runs go to `results/rerun/`; transcribed historical values stay in `results/reference/`.
- OR exports exponentiate coefficient estimates and interval endpoints only. The source
  exponentiated the entire `fixef()` matrix, including its standard-error column;
  exponentiating a log-scale SD does not produce an OR standard error.

## Result provenance

| Item | Source PDF page | Included file |
|---|---:|---|
| Cohort size and preprocessing | 3-4 | README and report |
| Additive posterior estimates | 7-8 | `results/reference/posterior_odds_ratios.csv` |
| Additive R-hat and ESS | 9 | Clean report text |
| LOO differences and standard errors | 14 | `results/reference/loo_comparison.csv` |
| Default-prior ORs | 15 | `results/reference/default_prior_odds_ratios.csv` |

The source retains compiler error messages alongside subsequent sampling outputs.
The clean report does not reproduce console noise, but it also does not claim an
error-free original execution. Raw posterior draws and full LOO diagnostics were
not available for independent review. Exact reproduction is unverified.

Plots are newly drawn from reported aggregate estimates. They are not newly fitted
results or reconstructed patient observations. Rounded reference values must never
be used to fabricate posterior draws, ROC curves or patient-level predictions.

## Input audit added after data became available

The supplied clinical (985 rows) and MRI-feature (384 rows) workbooks were audited
in Python. All MRI IDs matched clinical IDs and the complete-case cohort was 384,
consistent with the course report. Input checksums, counts and scaling constants
are retained under `results/validation/`. Posterior draws remain unavailable and
the reconstructed R model has not been rerun. Original data are not bundled.
