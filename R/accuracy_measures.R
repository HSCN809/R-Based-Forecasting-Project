forecast_accuracy <- function(actual, forecast) {
  # Keep accuracy calculations on matched actual/forecast periods only.
  ok <- is.finite(actual) & is.finite(forecast)
  actual <- actual[ok]
  forecast <- forecast[ok]

  error <- actual - forecast
  bias <- mean(error)
  mad <- mean(abs(error))
  mse <- mean(error^2)
  mape <- mean(abs(error / actual)) * 100
  rsfe <- sum(error)
  tracking_signal <- if (mad == 0) NA_real_ else rsfe / mad

  data.frame(
    Bias = bias,
    MAD = mad,
    MSE = mse,
    MAPE = mape,
    RSFE = rsfe,
    Tracking_Signal = tracking_signal
  )
}

comparison_row <- function(method_name, actual, forecast, next_forecast, applicable = TRUE, note = "") {
  if (!applicable) {
    return(data.frame(
      Method = method_name,
      Bias = NA_real_,
      MAD = NA_real_,
      MSE = NA_real_,
      MAPE = NA_real_,
      RSFE = NA_real_,
      Tracking_Signal = NA_real_,
      Next_Period_Forecast = NA_real_,
      Applicable = FALSE,
      Note = note
    ))
  }

  metrics <- forecast_accuracy(actual, forecast)
  data.frame(
    Method = method_name,
    metrics,
    Next_Period_Forecast = next_forecast,
    Applicable = TRUE,
    Note = note
  )
}

forecast_error_rows <- function(method_result, test_data) {
  # Preserve the detailed forecast errors behind each aggregate comparison row.
  applicable <- if (is.null(method_result$applicable)) TRUE else method_result$applicable

  if (!applicable) {
    return(data.frame(
      Method = method_result$method,
      Period = NA_character_,
      Actual = NA_real_,
      Forecast = NA_real_,
      Forecast_Error = NA_real_,
      Applicable = FALSE,
      Note = method_result$note
    ))
  }

  data.frame(
    Method = method_result$method,
    Period = test_data$period,
    Actual = test_data$value,
    Forecast = method_result$forecast,
    Forecast_Error = test_data$value - method_result$forecast,
    Applicable = TRUE,
    Note = method_result$note
  )
}
