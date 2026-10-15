# Archived aggregate results

These values are transcribed from the source course PDF. They are not newly
computed outputs. The PDF is available at `../../reports/source-course-report.pdf`.

- `posterior_odds_ratios.csv`: additive-model `exp(fixef(fit2))`, PDF page 7.
- `default_prior_odds_ratios.csv`: sensitivity-model `exp(fixef(fit2_default))`, page 15.
- `loo_comparison.csv`: relative ELPD differences and their standard errors, page 14.

Odds-ratio point estimates use exp(posterior mean log-odds coefficient); interval
endpoints are exponentiated 2.5% and 97.5% posterior log-odds quantiles. No
exponentiated standard-error column is included. The LOO baseline has zero
difference and zero difference SE by definition, not zero uncertainty in its ELPD.
