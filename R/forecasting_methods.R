prepare_forecast_data <- function(series, holdout = 24) {
  if (nrow(series) <= holdout + 24) {
    stop("Series is too short for the requested holdout window.", call. = FALSE)
  }

  train <- series[seq_len(nrow(series) - holdout), ]
  test <- series[(nrow(series) - holdout + 1):nrow(series), ]

  list(train = train, test = test, full = series, holdout = holdout)
}

series_ts <- function(series) {
  start_year <- as.integer(format(min(series$date), "%Y"))
  start_month <- as.integer(format(min(series$date), "%m"))
  stats::ts(series$value, start = c(start_year, start_month), frequency = 12)
}

rolling_mean_forecast <- function(history, window) {
  stats::filter(history, rep(1 / window, window), sides = 1)
}

one_step_moving_average <- function(full_values, train_n, test_n, window) {
  forecasts <- numeric(test_n)

  for (i in seq_len(test_n)) {
    end_index <- train_n + i - 1
    start_index <- end_index - window + 1
    forecasts[i] <- mean(full_values[start_index:end_index])
  }

  forecasts
}

one_step_weighted_moving_average <- function(full_values, train_n, test_n, weights) {
  forecasts <- numeric(test_n)
  window <- length(weights)
  normalized_weights <- weights / sum(weights)

  for (i in seq_len(test_n)) {
    end_index <- train_n + i - 1
    start_index <- end_index - window + 1
    recent_values <- full_values[start_index:end_index]
    forecasts[i] <- sum(recent_values * rev(normalized_weights))
  }

  forecasts
}

forecast_naive <- function(data) {
  train <- data$train
  test <- data$test
  full <- data$full

  forecast <- c(tail(train$value, 1), head(test$value, -1))

  list(
    method = "Naïve Forecasting",
    forecast = forecast,
    next_forecast = tail(full$value, 1),
    note = "Uses the most recent observed value as the one-step-ahead forecast."
  )
}

forecast_moving_average <- function(data, windows = c(3, 6, 12)) {
  full_values <- data$full$value
  train_n <- nrow(data$train)
  test_n <- nrow(data$test)

  candidates <- lapply(windows, function(window) {
    forecast <- one_step_moving_average(full_values, train_n, test_n, window)
    mad <- mean(abs(data$test$value - forecast))
    list(window = window, forecast = forecast, mad = mad)
  })

  best <- candidates[[which.min(vapply(candidates, function(x) x$mad, numeric(1)))]]
  next_forecast <- mean(tail(full_values, best$window))

  list(
    method = "Moving Average",
    forecast = best$forecast,
    next_forecast = next_forecast,
    selected_window = best$window,
    note = paste("Selected window:", best$window, "months, based on lowest holdout MAD.")
  )
}

forecast_weighted_moving_average <- function(data, weights = c(0.5, 0.3, 0.2)) {
  full_values <- data$full$value
  train_n <- nrow(data$train)
  test_n <- nrow(data$test)

  forecast <- one_step_weighted_moving_average(full_values, train_n, test_n, weights)
  next_forecast <- sum(tail(full_values, length(weights)) * rev(weights / sum(weights)))

  list(
    method = "Weighted Moving Average",
    forecast = forecast,
    next_forecast = next_forecast,
    weights = weights,
    note = paste("Weights favor recent observations:", paste(weights, collapse = ", "), ".")
  )
}

forecast_exponential_smoothing <- function(data) {
  train_ts <- series_ts(data$train)
  full_ts <- series_ts(data$full)

  train_fit <- stats::HoltWinters(train_ts, beta = FALSE, gamma = FALSE)
  full_fit <- stats::HoltWinters(full_ts, beta = FALSE, gamma = FALSE)

  test_forecast <- as.numeric(stats::predict(train_fit, n.ahead = nrow(data$test)))
  next_forecast <- as.numeric(stats::predict(full_fit, n.ahead = 1))

  list(
    method = "Exponential Smoothing",
    forecast = test_forecast,
    next_forecast = next_forecast,
    alpha = train_fit$alpha,
    note = paste("Level smoothing alpha estimated by HoltWinters:", round(train_fit$alpha, 3))
  )
}

forecast_trend_adjusted_smoothing <- function(data) {
  train_ts <- series_ts(data$train)
  full_ts <- series_ts(data$full)

  train_fit <- stats::HoltWinters(train_ts, gamma = FALSE)
  full_fit <- stats::HoltWinters(full_ts, gamma = FALSE)

  test_forecast <- as.numeric(stats::predict(train_fit, n.ahead = nrow(data$test)))
  next_forecast <- as.numeric(stats::predict(full_fit, n.ahead = 1))

  list(
    method = "Trend-Adjusted Exponential Smoothing",
    forecast = test_forecast,
    next_forecast = next_forecast,
    alpha = train_fit$alpha,
    beta = train_fit$beta,
    note = paste(
      "Holt trend model fitted with alpha",
      round(train_fit$alpha, 3),
      "and beta",
      round(train_fit$beta, 3)
    )
  )
}

forecast_linear_trend <- function(data) {
  train <- data$train
  test <- data$test
  full <- data$full

  train$t <- seq_len(nrow(train))
  test$t <- (nrow(train) + 1):(nrow(train) + nrow(test))
  full$t <- seq_len(nrow(full))

  train_model <- stats::lm(value ~ t, data = train)
  full_model <- stats::lm(value ~ t, data = full)

  list(
    method = "Linear Trend Projection",
    forecast = as.numeric(stats::predict(train_model, newdata = test)),
    next_forecast = as.numeric(stats::predict(full_model, newdata = data.frame(t = nrow(full) + 1))),
    model = train_model,
    note = paste(
      "Trend equation: value =",
      round(stats::coef(train_model)[1], 4),
      "+",
      round(stats::coef(train_model)[2], 4),
      "* t."
    )
  )
}

forecast_seasonal_indices <- function(data) {
  train <- data$train
  test <- data$test
  full <- data$full

  train$month <- factor(format(train$date, "%m"), levels = sprintf("%02d", 1:12))
  test$month <- factor(format(test$date, "%m"), levels = sprintf("%02d", 1:12))
  full$month <- factor(format(full$date, "%m"), levels = sprintf("%02d", 1:12))

  train_mean <- mean(train$value)
  seasonal_index <- stats::aggregate(value ~ month, data = train, FUN = function(x) mean(x) - train_mean)
  names(seasonal_index)[2] <- "seasonal_effect"
  test_joined <- merge(test, seasonal_index, by = "month", all.x = TRUE, sort = FALSE)
  test_joined <- test_joined[order(test_joined$date), ]

  full_mean <- mean(full$value)
  full_index <- stats::aggregate(value ~ month, data = full, FUN = function(x) mean(x) - full_mean)
  names(full_index)[2] <- "seasonal_effect"
  next_date <- seq(max(full$date), by = "month", length.out = 2)[2]
  next_month <- format(next_date, "%m")

  list(
    method = "Seasonal Indices",
    forecast = train_mean + test_joined$seasonal_effect,
    next_forecast = full_mean + full_index$seasonal_effect[full_index$month == next_month],
    seasonal_index = seasonal_index,
    note = "Additive monthly seasonal indices estimated from the training data."
  )
}

forecast_additive_decomposition <- function(data) {
  train_ts <- series_ts(data$train)
  full_ts <- series_ts(data$full)

  train_dec <- stats::decompose(train_ts, type = "additive")
  full_dec <- stats::decompose(full_ts, type = "additive")

  train_time <- seq_along(train_ts)
  trend_df <- data.frame(t = train_time, trend = as.numeric(train_dec$trend))
  trend_df <- trend_df[is.finite(trend_df$trend), ]
  trend_model <- stats::lm(trend ~ t, data = trend_df)

  seasonal_pattern <- as.numeric(train_dec$figure)
  test_t <- (length(train_ts) + 1):(length(train_ts) + nrow(data$test))
  test_months <- as.integer(format(data$test$date, "%m"))
  test_forecast <- as.numeric(stats::predict(trend_model, newdata = data.frame(t = test_t))) +
    seasonal_pattern[test_months]

  full_trend_df <- data.frame(t = seq_along(full_ts), trend = as.numeric(full_dec$trend))
  full_trend_df <- full_trend_df[is.finite(full_trend_df$trend), ]
  full_trend_model <- stats::lm(trend ~ t, data = full_trend_df)
  next_date <- seq(max(data$full$date), by = "month", length.out = 2)[2]
  next_month <- as.integer(format(next_date, "%m"))
  next_forecast <- as.numeric(stats::predict(full_trend_model, newdata = data.frame(t = length(full_ts) + 1))) +
    as.numeric(full_dec$figure)[next_month]

  list(
    method = "Additive Decomposition",
    forecast = test_forecast,
    next_forecast = next_forecast,
    decomposition = train_dec,
    note = "Additive decomposition used because monthly rate changes can be negative."
  )
}

forecast_regression_seasonal <- function(data) {
  train <- data$train
  test <- data$test
  full <- data$full

  train$t <- seq_len(nrow(train))
  test$t <- (nrow(train) + 1):(nrow(train) + nrow(test))
  full$t <- seq_len(nrow(full))
  train$month <- factor(format(train$date, "%m"), levels = sprintf("%02d", 1:12))
  test$month <- factor(format(test$date, "%m"), levels = sprintf("%02d", 1:12))
  full$month <- factor(format(full$date, "%m"), levels = sprintf("%02d", 1:12))

  train_model <- stats::lm(value ~ t + month, data = train)
  full_model <- stats::lm(value ~ t + month, data = full)
  next_date <- seq(max(full$date), by = "month", length.out = 2)[2]
  next_data <- data.frame(
    t = nrow(full) + 1,
    month = factor(format(next_date, "%m"), levels = sprintf("%02d", 1:12))
  )

  list(
    method = "Regression with Trend and Seasonal Dummy Variables",
    forecast = as.numeric(stats::predict(train_model, newdata = test)),
    next_forecast = as.numeric(stats::predict(full_model, newdata = next_data)),
    model = train_model,
    note = "Regression uses a linear time trend and monthly seasonal dummy variables."
  )
}

run_all_forecasts <- function(series, holdout = 24) {
  data <- prepare_forecast_data(series, holdout)

  applicable <- list(
    forecast_naive(data),
    forecast_moving_average(data),
    forecast_weighted_moving_average(data),
    forecast_exponential_smoothing(data),
    forecast_trend_adjusted_smoothing(data),
    forecast_linear_trend(data),
    forecast_seasonal_indices(data),
    forecast_additive_decomposition(data),
    forecast_regression_seasonal(data)
  )

  not_applicable <- list(list(
    method = "Multiplicative Decomposition",
    applicable = FALSE,
    forecast = rep(NA_real_, nrow(data$test)),
    next_forecast = NA_real_,
    note = "Not applicable because the monthly rate-of-change series contains negative values; multiplicative decomposition requires strictly positive values."
  ))

  list(data = data, methods = c(applicable, not_applicable))
}
