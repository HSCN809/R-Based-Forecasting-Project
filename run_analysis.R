source("R/dependencies.R")
ensure_project_packages()

library(dplyr)
library(ggplot2)

source("R/data_import.R")
source("R/forecasting_methods.R")
source("R/accuracy_measures.R")
source("R/plots.R")

dir.create("outputs/tables", recursive = TRUE, showWarnings = FALSE)
dir.create("outputs/figures", recursive = TRUE, showWarnings = FALSE)

import_result <- fetch_selected_series()
source_info <- import_result$source_info
series <- import_result$series

latest_observation <- max(series$period)
forecast_target_period <- next_month_period(latest_observation)

invisible(save_actual_series_plot(series, "outputs/figures/actual_series_plot.png"))

forecast_results <- run_all_forecasts(series, holdout = 24)
test_data <- forecast_results$data$test
method_lookup <- setNames(
  forecast_results$methods,
  vapply(forecast_results$methods, function(x) x$method, character(1))
)

accuracy_rows <- lapply(forecast_results$methods, function(method_result) {
  applicable <- if (is.null(method_result$applicable)) TRUE else method_result$applicable
  comparison_row(
    method_result$method,
    test_data$value,
    method_result$forecast,
    method_result$next_forecast,
    applicable = applicable,
    note = method_result$note
  )
})

accuracy_comparison <- bind_rows(accuracy_rows) |>
  mutate(across(where(is.numeric), ~ round(.x, 4)))

write.csv(
  accuracy_comparison,
  "outputs/tables/accuracy_comparison.csv",
  row.names = FALSE,
  fileEncoding = "UTF-8"
)

# Save the period-by-period errors required to reproduce the accuracy table.
forecast_errors <- bind_rows(lapply(
  forecast_results$methods,
  forecast_error_rows,
  test_data = test_data
)) |>
  mutate(across(where(is.numeric), ~ round(.x, 4)))

write.csv(
  forecast_errors,
  "outputs/tables/forecast_errors.csv",
  row.names = FALSE,
  fileEncoding = "UTF-8"
)

plot_files <- c(
  "Naïve Forecasting" = "naive_forecast_plot.png",
  "Moving Average" = "moving_average_plot.png",
  "Weighted Moving Average" = "weighted_moving_average_plot.png",
  "Exponential Smoothing" = "exponential_smoothing_plot.png",
  "Trend-Adjusted Exponential Smoothing" = "trend_adjusted_smoothing_plot.png",
  "Linear Trend Projection" = "trend_projection_plot.png",
  "Seasonal Indices" = "seasonal_indices_plot.png",
  "Additive Decomposition" = "additive_decomposition_plot.png",
  "Regression with Trend and Seasonal Dummy Variables" = "regression_seasonal_dummy_plot.png"
)

for (method_name in names(plot_files)) {
  save_forecast_plot(
    test_data,
    method_lookup[[method_name]]$forecast,
    method_name,
    file.path("outputs/figures", plot_files[[method_name]])
  )
}

eligible_methods <- accuracy_comparison |>
  filter(Applicable) |>
  arrange(MAPE, MAD, abs(Tracking_Signal))

superior_method_name <- eligible_methods$Method[1]
superior_result <- method_lookup[[superior_method_name]]
superior_forecast <- superior_result$next_forecast

final_forecast <- data.frame(
  Selected_Superior_Method = superior_method_name,
  Data_Access_Date = source_info$access_date,
  Latest_Available_Observation = latest_observation,
  Forecast_Target_Period = forecast_target_period,
  Forecasted_Value = round(superior_forecast, 4),
  Interpretation = paste(
    "The selected method forecasts the monthly rate of change in the Agricultural Products Producer Price Index for",
    forecast_target_period,
    "as",
    round(superior_forecast, 4),
    "percent."
  )
)

write.csv(
  final_forecast,
  "outputs/tables/final_forecast.csv",
  row.names = FALSE,
  fileEncoding = "UTF-8"
)

invisible(save_superior_plot(
  series,
  forecast_target_period,
  superior_forecast,
  superior_method_name,
  "outputs/figures/superior_method_plot.png"
))

print(accuracy_comparison)
print(final_forecast)
