# Run from the repository root: Rscript scripts/run_analysis.R
# Input-only validation: Rscript scripts/run_analysis.R --prepare-only
if (!file.exists("R/prepare_data.R")) stop("Run this command from the repository root.")
source("R/prepare_data.R")
args <- commandArgs(trailingOnly = TRUE)
if (any(!args %in% c("--prepare-only"))) stop("Supported option: --prepare-only")
out <- "results/rerun"
dir.create(out, recursive = TRUE, showWarnings = FALSE)

find_input <- function(stem) {
  choices <- file.path("data", paste0(stem, c(".xlsx", ".csv")))
  found <- choices[file.exists(choices)]
  if (!length(found)) stop("Missing input: ", stem, ". See data/README.md.", call. = FALSE)
  if (length(found) > 1L) stop("Keep only one CSV or XLSX version of ", stem)
  found
}
if (file.exists("data/analysis_input.csv")) {
  input_paths <- "data/analysis_input.csv"
  raw <- read_source(input_paths)
} else {
  input_paths <- c(find_input("ISPY2-Imaging-Cohort-1-Clinical-Data"),
                   find_input("Multi-feature-MRI-NACT-Data"))
  raw <- join_inputs(read_source(input_paths[1]), read_source(input_paths[2]))
}
prepared <- prepare_data(raw)
dat <- prepared$data
write.csv(prepared$audit, file.path(out, "cohort_audit.csv"), row.names = FALSE)
write.csv(prepared$scaling, file.path(out, "scaling.csv"), row.names = FALSE)
write.csv(data.frame(file = input_paths, md5 = unname(tools::md5sum(input_paths))),
          file.path(out, "input_checksums.csv"), row.names = FALSE)
message("Complete cases: ", nrow(dat), ". The archived report recorded 384.")
if (nrow(dat) != 384L) warning("Cohort differs from the archived report; inspect cohort_audit.csv.")
if ("--prepare-only" %in% args) quit(save = "no", status = 0)

needed <- c("brms", "rstan", "loo", "posterior", "bayesplot", "ggplot2")
missing <- needed[!vapply(needed, requireNamespace, logical(1), quietly = TRUE)]
if (length(missing)) stop("Install required packages first: ", paste(missing, collapse = ", "))
# Force the documented treatment contrasts independent of a user's R profile.
options(contrasts = c("contr.treatment", "contr.poly"))
available_cores <- parallel::detectCores()
cores <- if (is.na(available_cores)) 1L else min(4L, available_cores)
set.seed(123)

priors1 <- c(
  brms::prior(normal(0, 1.5), class = "Intercept"),
  brms::prior(normal(0, 0.7), class = "b", coef = "LD_T0_z"),
  brms::prior(normal(0, 0.7), class = "b", coef = "SPHERICITY_T0_z")
)
priors2 <- c(priors1,
  brms::prior(normal(0, 1), class = "b", coef = "HR1"),
  brms::prior(normal(0, 1), class = "b", coef = "HER21")
)
priors3 <- c(priors2, brms::prior(normal(0, 1), class = "b", coef = "HR1:HER21"))
formulas <- list(
  imaging_only = pCR ~ LD_T0_z + SPHERICITY_T0_z,
  additive = pCR ~ LD_T0_z + SPHERICITY_T0_z + HR + HER2,
  interaction = pCR ~ LD_T0_z + SPHERICITY_T0_z + HR * HER2,
  default_prior = pCR ~ LD_T0_z + SPHERICITY_T0_z + HR + HER2
)
priors <- list(imaging_only = priors1, additive = priors2, interaction = priors3)
fits <- list()
for (name in names(formulas)) {
  model_args <- list(formula = formulas[[name]], data = dat, family = brms::bernoulli(),
                     chains = 4, iter = 4000, warmup = 2000, cores = cores,
                     seed = 123, backend = "rstan")
  if (name != "default_prior") model_args$prior <- priors[[name]]
  fits[[name]] <- do.call(brms::brm, model_args)
  saveRDS(fits[[name]], file.path(out, paste0(name, ".rds")))
  capture.output(summary(fits[[name]]), file = file.path(out, paste0(name, "_summary.txt")))
  diagnostics <- posterior::summarise_draws(posterior::as_draws_df(fits[[name]]))
  write.csv(as.data.frame(diagnostics), file.path(out, paste0(name, "_diagnostics.csv")), row.names = FALSE)
  nuts <- brms::nuts_params(fits[[name]])
  capture.output(table(nuts$Value[nuts$Parameter == "divergent__"]),
                 file = file.path(out, paste0(name, "_divergences.txt")))
}

export_or <- function(fit, filename) {
  b <- brms::fixef(fit, probs = c(0.025, 0.975))
  # Reproduce the original exp(fixef) point-estimate convention. Do NOT
  # exponentiate the log-scale standard error and call it an OR standard error.
  tab <- data.frame(term = rownames(b), log_odds_mean = b[, "Estimate"],
                    log_odds_sd = b[, "Est.Error"],
                    odds_ratio = exp(b[, "Estimate"]),
                    lower_95 = exp(b[, "Q2.5"]), upper_95 = exp(b[, "Q97.5"]))
  write.csv(tab, file.path(out, filename), row.names = FALSE)
  tab
}
or <- export_or(fits$additive, "posterior_odds_ratios.csv")
export_or(fits$default_prior, "default_prior_odds_ratios.csv")
loos <- lapply(fits[c("imaging_only", "additive", "interaction")], brms::loo)
comparison <- loo::loo_compare(loos)
write.csv(data.frame(model = rownames(comparison), comparison, row.names = NULL),
          file.path(out, "loo_comparison.csv"), row.names = FALSE)
for (name in names(loos)) {
  capture.output(print(loos[[name]]), file = file.path(out, paste0(name, "_loo_diagnostics.txt")))
}
saveRDS(loos, file.path(out, "loo_objects.rds"))

png(file.path(out, "additive_traceplots.png"), width = 1600, height = 1800, res = 160)
plot(fits$additive)
dev.off()
# A binary-outcome predictive check, added during reconstruction.
ppc <- brms::pp_check(fits$additive, type = "bars", ndraws = 100)
ggplot2::ggsave(file.path(out, "posterior_predictive_check.png"), ppc, width = 7, height = 4, dpi = 180)
plot_data <- or[or$term != "Intercept", ]
forest <- ggplot2::ggplot(plot_data, ggplot2::aes(x = odds_ratio, y = term)) +
  ggplot2::geom_vline(xintercept = 1, linetype = 2, colour = "grey60") +
  ggplot2::geom_segment(ggplot2::aes(x = lower_95, xend = upper_95, yend = term), colour = "#27695A") +
  ggplot2::geom_point(size = 3, colour = "#27695A") + ggplot2::scale_x_log10() +
  ggplot2::theme_minimal(base_size = 12) +
  ggplot2::labs(x = "Odds ratio and 95% credible interval", y = NULL,
                title = "Additive model - new run")
ggplot2::ggsave(file.path(out, "posterior_odds_ratios.png"), forest, width = 8, height = 4.5, dpi = 180)
capture.output(sessionInfo(), file = file.path(out, "session_info.txt"))
message("New run saved to results/rerun/. Inspect diagnostics before interpreting results.")
