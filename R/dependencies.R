Sys.setenv(CURL_SSL_BACKEND = "openssl")

project_cran_packages <- c(
  "curl", "jsonlite", "tibble", "dplyr", "tidyr",
  "ggplot2", "zoo", "forecast", "knitr", "rmarkdown"
)

project_log <- function(message, verbose = TRUE) {
  if (isTRUE(verbose)) {
    cat(message, "\n", sep = "")
  }
}

project_package_available <- function(package) {
  package_check_log <- tempfile("package-check-", fileext = ".log")
  log_connection <- file(package_check_log, open = "wt")
  output_sink_active <- FALSE
  message_sink_active <- FALSE

  close_sinks <- function() {
    if (message_sink_active) {
      sink(type = "message")
      message_sink_active <<- FALSE
    }
    if (output_sink_active) {
      sink()
      output_sink_active <<- FALSE
    }
    close(log_connection)
  }

  sink(log_connection)
  output_sink_active <- TRUE
  sink(log_connection, type = "message")
  message_sink_active <- TRUE

  result <- tryCatch(
    suppressPackageStartupMessages(
      suppressMessages(
        suppressWarnings(
          requireNamespace(package, quietly = TRUE)
        )
      )
    ),
    error = function(error) FALSE,
    finally = close_sinks()
  )

  result
}

ensure_cran_package <- function(package, verbose = TRUE) {
  if (project_package_available(package)) {
    project_log(paste0("  - ", package, ": already installed"), verbose)
    return(invisible(TRUE))
  }

  project_log(paste0("  - ", package, ": installing from CRAN"), verbose)
  install.packages(package, repos = "https://cloud.r-project.org", quiet = !verbose)
  invisible(TRUE)
}

ensure_tuikr_package <- function(verbose = TRUE) {
  if (project_package_available("tuikr")) {
    project_log("  - tuikr: already installed", verbose)
    return(invisible(TRUE))
  }

  project_log("  - tuikr: installing from GitHub", verbose)
  ensure_cran_package("remotes", verbose = verbose)
  remotes::install_github("emraher/tuikr", upgrade = "never", quiet = !verbose)
  invisible(TRUE)
}

ensure_project_packages <- function(verbose = TRUE) {
  project_log("Checking required R packages...", verbose)

  for (package in project_cran_packages) {
    ensure_cran_package(package, verbose = verbose)
  }

  ensure_tuikr_package(verbose = verbose)
  project_log("Package check completed.", verbose)
  invisible(TRUE)
}
