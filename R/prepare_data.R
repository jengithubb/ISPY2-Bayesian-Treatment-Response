# Reconstructed from the archived BIOSTAT 226 report. No data are bundled.
read_source <- function(path) {
  if (!file.exists(path)) stop("Missing input file: ", path, call. = FALSE)
  if (tolower(tools::file_ext(path)) == "xlsx") {
    if (!requireNamespace("readxl", quietly = TRUE)) stop("Install readxl to read XLSX inputs.")
    x <- as.data.frame(readxl::read_excel(path), check.names = FALSE)
  } else {
    x <- read.csv(path, stringsAsFactors = FALSE, check.names = FALSE)
  }
  names(x) <- make.names(names(x))
  if (anyDuplicated(names(x))) stop("Column names are duplicated after normalization.")
  x
}

require_columns <- function(x, cols) {
  missing <- setdiff(cols, names(x))
  if (length(missing)) stop("Missing columns: ", paste(missing, collapse = ", "), call. = FALSE)
}

join_inputs <- function(clinical, imaging) {
  require_columns(clinical, c("Patient_ID", "pCR", "HR", "HER2"))
  require_columns(imaging, c("CLINICAL.TRIAL.SUBJECT.ID", "LD_T0", "SPHERICITY_T0"))
  a <- as.character(clinical$Patient_ID)
  b <- as.character(imaging$CLINICAL.TRIAL.SUBJECT.ID)
  for (ids in list(a, b)) {
    if (anyNA(ids) || any(!nzchar(trimws(ids))) || anyDuplicated(ids)) {
      stop("Patient IDs must be nonmissing and unique in each input; resolve duplicates before joining.")
    }
  }
  # Equivalent full join for the selected variables; clinical row order first.
  ids <- union(a, b)
  ia <- match(ids, a)
  ib <- match(ids, b)
  joined <- data.frame(
    pCR = clinical$pCR[ia], HR = clinical$HR[ia], HER2 = clinical$HER2[ia],
    LD_T0 = imaging$LD_T0[ib], SPHERICITY_T0 = imaging$SPHERICITY_T0[ib]
  )
  attr(joined, "join_audit") <- data.frame(
    measure = c("clinical_rows", "imaging_rows", "matched_ids", "union_ids"),
    value = c(length(a), length(b), sum(a %in% b), length(ids))
  )
  joined
}

prepare_data <- function(x) {
  cols <- c("pCR", "LD_T0", "SPHERICITY_T0", "HR", "HER2")
  require_columns(x, cols)
  dat <- x[, cols, drop = FALSE]
  for (name in cols) {
    raw <- trimws(as.character(dat[[name]]))
    raw[raw == ""] <- NA_character_
    value <- suppressWarnings(as.numeric(raw))
    if (any(!is.na(raw) & is.na(value))) stop("Nonnumeric value in ", name, "; check the data dictionary.")
    if (any(!is.na(value) & !is.finite(value))) stop("Nonfinite value in ", name)
    dat[[name]] <- value
  }
  for (name in c("pCR", "HR", "HER2")) {
    if (any(!is.na(dat[[name]]) & !(dat[[name]] %in% c(0, 1)))) {
      stop(name, " must be coded 0/1; verify coding before running.")
    }
  }
  keep <- complete.cases(dat)
  audit <- data.frame(measure = c("input_rows", "complete_cases", "excluded_incomplete"),
                      value = c(nrow(dat), sum(keep), sum(!keep)))
  dat <- dat[keep, , drop = FALSE]
  if (nrow(dat) < 3L) stop("Insufficient complete cases.")
  for (name in c("pCR", "HR", "HER2")) {
    if (length(unique(dat[[name]])) != 2L) stop("Both 0 and 1 must occur in ", name)
  }
  scaling <- data.frame(variable = c("LD_T0", "SPHERICITY_T0"), mean = NA_real_, sd = NA_real_)
  for (i in seq_len(nrow(scaling))) {
    name <- scaling$variable[i]
    scaling$mean[i] <- mean(dat[[name]])
    scaling$sd[i] <- sd(dat[[name]])
    if (!is.finite(scaling$sd[i]) || scaling$sd[i] <= 0) stop("Zero variance in ", name)
    dat[[paste0(name, "_z")]] <- (dat[[name]] - scaling$mean[i]) / scaling$sd[i]
  }
  dat$pCR <- as.integer(dat$pCR)
  dat$HR <- factor(dat$HR, levels = c(0, 1))
  dat$HER2 <- factor(dat$HER2, levels = c(0, 1))
  list(data = dat, audit = rbind(attr(x, "join_audit"), audit), scaling = scaling)
}
