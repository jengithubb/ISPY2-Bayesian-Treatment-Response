# Synthetic inputs only. Run from repository root with base R.
source("R/prepare_data.R")
expect_error <- function(expr, pattern) {
  msg <- tryCatch({force(expr); NULL}, error = function(e) conditionMessage(e))
  stopifnot(!is.null(msg), grepl(pattern, msg))
}
clinical <- data.frame(Patient_ID = c("a", "b", "c", "d", "e"),
                        pCR = c(0, 1, 0, 1, 1), HR = c(0, 1, 1, 0, 0),
                        HER2 = c(1, 0, 1, 0, 1))
imaging <- data.frame(CLINICAL.TRIAL.SUBJECT.ID = c("d", "c", "b", "a", "f"),
                      LD_T0 = c(4, 3, 2, 1, 6), SPHERICITY_T0 = c(.4, .3, .2, .1, .6))
joined <- join_inputs(clinical, imaging)
result <- prepare_data(joined)
stopifnot(nrow(joined) == 6L, nrow(result$data) == 4L,
          identical(result$data$LD_T0, c(1, 2, 3, 4)),
          abs(mean(result$data$LD_T0_z)) < 1e-12,
          abs(sd(result$data$LD_T0_z) - 1) < 1e-12,
          identical(levels(result$data$HR), c("0", "1")))
duplicate <- rbind(clinical, clinical[1, ])
expect_error(join_inputs(duplicate, imaging), "unique")
bad <- joined; bad$pCR[1] <- 2
expect_error(prepare_data(bad), "coded 0/1")
bad <- joined; bad$LD_T0 <- 1
expect_error(prepare_data(bad), "Zero variance")
bad <- joined; bad$LD_T0[1] <- "invalid"
expect_error(prepare_data(bad), "Nonnumeric")
expect_error(prepare_data(joined[, setdiff(names(joined), "HR")]), "Missing columns")
message("Synthetic preprocessing checks passed; no clinical data or model fitting used.")
