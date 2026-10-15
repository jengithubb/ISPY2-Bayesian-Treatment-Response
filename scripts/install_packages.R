# Run explicitly once. A working C++ toolchain is also needed for Stan.
packages <- c("brms", "rstan", "loo", "posterior", "bayesplot", "ggplot2",
              "readxl", "rmarkdown", "knitr")
missing <- packages[!vapply(packages, requireNamespace, logical(1), quietly = TRUE)]
if (length(missing)) install.packages(missing, repos = "https://cloud.r-project.org")
message("R packages checked. See README.md for Stan toolchain requirements.")
