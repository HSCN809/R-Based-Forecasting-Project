Sys.setenv(CURL_SSL_BACKEND = "openssl")

project_cran_packages <- c(
  "curl", "jsonlite", "tibble", "dplyr", "tidyr",
  "ggplot2", "zoo", "forecast", "knitr", "rmarkdown"
)

ensure_cran_package <- function(package) {
  if (requireNamespace(package, quietly = TRUE)) {
    return(invisible(TRUE))
  }

  install.packages(package, repos = "https://cloud.r-project.org")
  invisible(TRUE)
}

ensure_tuikr_package <- function() {
  if (requireNamespace("tuikr", quietly = TRUE)) {
    return(invisible(TRUE))
  }

  ensure_cran_package("remotes")
  remotes::install_github("emraher/tuikr", upgrade = "never")
  invisible(TRUE)
}

ensure_project_packages <- function() {
  for (package in project_cran_packages) {
    ensure_cran_package(package)
  }

  ensure_tuikr_package()
  invisible(TRUE)
}
