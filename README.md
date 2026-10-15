# Bayesian Modeling of Breast Cancer Treatment Response

**Jennifer Zhu | BIOSTAT 226 course project | I-SPY2 imaging cohort**

An interpretable Bayesian analysis of how pretreatment MRI tumor size, shape,
and receptor status relate to pathologic complete response (pCR).

[Read the report](reports/bayesian-treatment-response-report.pdf) ·
[View analysis code](scripts/run_analysis.R) ·
[Data instructions](data/README.md) ·
[Reconstruction notes](docs/RECONSTRUCTION.md)

![Posterior odds ratios from the archived course analysis](figures/posterior-odds-ratios.png)

## Research question

Do baseline longest tumor diameter and sphericity provide information about pCR,
and does adding HR and HER2 status improve model fit and expected predictive performance?

The course analysis compared three Bayesian logistic regression models using
`brms` and Stan. All models used the same 384 complete-case observations.

| Model | Predictors |
|---|---|
| Imaging only | Standardized tumor diameter + sphericity |
| Additive | Imaging features + HR + HER2 |
| Interaction | Imaging features + HR + HER2 + HR × HER2 |

## Findings from the archived report

| Additive-model predictor | Odds ratio | 95% credible interval |
|---|---:|---:|
| Diameter, per SD | 0.77 | 0.57–1.01 |
| Sphericity, per SD | 1.13 | 0.88–1.45 |
| HR-positive vs negative | 0.29 | 0.18–0.46 |
| HER2-positive vs negative | 2.60 | 1.56–4.32 |

Adding receptor status improved the reported LOO model comparison. Relative to
the additive model, the imaging-only model had an ELPD difference of -17.9
(SE 5.8); the interaction model differed by -0.5 (SE 0.4). The additive model
provided a parsimonious summary of these data. These are observational
associations and internal model comparisons, not a validated clinical tool.

## What this repository demonstrates

- Joining clinical and MRI-feature tables with explicit input validation.
- Complete-case cohort construction and standardized continuous predictors.
- Regularizing priors, MCMC estimation, and posterior uncertainty summaries.
- Posterior predictive checks, convergence diagnostics, and LOO comparison.
- A default-prior sensitivity analysis and careful interpretation of limitations.

## Repository contents

| Path | Purpose |
|---|---|
| `R/prepare_data.R` | Input reading, ID checks, full join, cohort construction and scaling |
| `scripts/run_analysis.R` | Fit three models and one sensitivity model; export diagnostics and plots |
| `scripts/install_packages.R` | Install missing R packages when explicitly run |
| `reports/analysis-report.Rmd` | Editable report source; renders archived results without fitting models |
| `reports/bayesian-treatment-response-report.pdf` | Clean portfolio report |
| `reports/source-course-report.pdf` | Unmodified source PDF, retained for provenance |
| `results/reference/` | Aggregate results transcribed from the source PDF |
| `results/validation/` | Aggregate audit of the newly supplied clinical and MRI workbooks |
| `figures/` | Figures drawn from the archived aggregate results |
| `tests/check_preparation.R` | Synthetic-data checks for joining and preprocessing |
| `docs/` | Reconstruction notes, validation status and upload guide |

## Run the analysis

The published report and figures can be read immediately. R, a working Stan C++
toolchain, and the original data tables are needed to refit models.

1. Open `ISPY2-Bayesian-Treatment-Response.Rproj` in RStudio, or set the working
   directory to this repository root.
2. Install packages once:

```r
source("scripts/install_packages.R")
```

The archived run used R 4.4.x and brms 2.23.0. The installer installs currently
available packages; an exact original environment lockfile is not available.
For Stan setup, follow the [official RStan guide](https://github.com/stan-dev/rstan/wiki/RStan-Getting-Started).

3. Put the two input tables in `data/` as described in [data/README.md](data/README.md).
   Alternatively, provide `data/analysis_input.csv` with the five required columns.
4. Validate inputs first, then fit models:

```bash
Rscript scripts/run_analysis.R --prepare-only
Rscript scripts/run_analysis.R
```

The run uses four chains, 4,000 iterations per chain, 2,000 warmup iterations,
and seed 123. New model fits, tables, diagnostics, plots and session information
are saved in `results/rerun/`. Inspect divergent transitions, R-hat, effective
sample sizes and Pareto-k diagnostics before interpreting a new run.

To run the lightweight preprocessing checks (base R only):

```bash
Rscript tests/check_preparation.R
```

To render the editable report as HTML without fitting models, run from the root:

```r
rmarkdown::render("reports/analysis-report.Rmd")
```

RStudio includes Pandoc; command-line rendering also needs Pandoc installed.

The included PDF and figures can optionally be regenerated from the archived
aggregate CSVs with Python (no R, Stan or patient data needed):

```bash
python -m pip install -r requirements-report.txt
python scripts/render_reference_assets.py
```

This redraws reference results only; it never refits a model or replaces reference
values with new-run outputs.

## Reconstruction and reproducibility

The original editable analysis file was unavailable. This repository reconstructs
the visible analysis from the author's archived PDF. The displayed numerical
results and figures come from that PDF, not from a new model run. Raw data,
posterior draws and original fitted-model objects are not included. The reconstructed
R code has been checked statically but has not been executed with R/Stan in this
preparation environment. The supplied data were independently audited in Python:
985 clinical records and 384 MRI-feature records joined to 985 unique IDs, yielding
384 complete cases and 601 exclusions. This confirms the cohort count, not the
posterior estimates. Aggregate checks are in `results/validation/`. See [validation status](docs/VALIDATION.md).

OR point estimates follow the original convention: exponentiated posterior mean
log-odds coefficients. They are not posterior means computed directly on the OR scale.

## Limitations

This is a complete-case course analysis with a small baseline feature set and no
independent external validation. Treatment arm is not adjusted for in these
reconstructed models. Receptor associations should not be interpreted as causal
treatment effects. The original global standardization is preserved; the reported
LOO comparison is not a fully refitted preprocessing-and-model validation pipeline.

## Data and method sources

- [I-SPY2 collection, The Cancer Imaging Archive](https://www.cancerimagingarchive.net/collection/ispy2/).
  Obtain the clinical cohort table and Multi-feature MRI NACT table there, and follow
  their current citation and usage requirements.
- [brms documentation](https://paulbuerkner.com/brms/).
- The author's [archived course report](reports/source-course-report.pdf), dated March 5, 2026 on its title page.

No patient-level records are bundled. Data-source licenses remain separate from this repository.
