Sys.setenv(CURL_SSL_BACKEND = "openssl")

source("R/dependencies.R")
ensure_project_packages()

dir.create("outputs/tables", recursive = TRUE, showWarnings = FALSE)
dir.create("outputs/figures", recursive = TRUE, showWarnings = FALSE)

if (!rmarkdown::pandoc_available()) {
  stop(
    paste(
      "Pandoc is required to render forecasting_project.html.",
      "Please install RStudio or Pandoc, then run source(\"main.R\") again."
    ),
    call. = FALSE
  )
}

rmarkdown::render(
  input = "forecasting_project.Rmd",
  output_file = "forecasting_project.html",
  quiet = FALSE
)

cat("\nProject rendered successfully: forecasting_project.html\n")
