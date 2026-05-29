Sys.setenv(CURL_SSL_BACKEND = "openssl")

source("R/dependencies.R")

render_project_notebook <- function() {
  render_log <- tempfile("forecasting-render-", fileext = ".log")
  log_connection <- file(render_log, open = "wt")
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

  tryCatch(
    {
      suppressPackageStartupMessages(
        suppressMessages(
          suppressWarnings(
            rmarkdown::render(
              input = "forecasting_project.Rmd",
              output_file = "forecasting_project.html",
              quiet = TRUE
            )
          )
        )
      )
      close_sinks()
    },
    error = function(error) {
      close_sinks()
      cat("Render failed. Render log:\n")
      cat(readLines(render_log, warn = FALSE), sep = "\n")
      stop(error)
    }
  )
}

cat("R-Based Forecasting Project\n")
cat("Step 1/5 - Checking and installing required packages...\n")
ensure_project_packages()

cat("Step 2/5 - Preparing output folders...\n")
dir.create("outputs/tables", recursive = TRUE, showWarnings = FALSE)
dir.create("outputs/figures", recursive = TRUE, showWarnings = FALSE)

cat("Step 3/5 - Checking Pandoc availability...\n")
if (!rmarkdown::pandoc_available()) {
  stop(
    paste(
      "Pandoc is required to render forecasting_project.html.",
      "Please install RStudio or Pandoc, then run source(\"main.R\") again."
    ),
    call. = FALSE
  )
}

cat("Step 4/5 - Rendering forecasting_project.Rmd...\n")
render_project_notebook()

cat("Step 5/5 - Render completed.\n")
cat("Output file: forecasting_project.html\n")
