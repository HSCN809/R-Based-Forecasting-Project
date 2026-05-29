theme_project <- function() {
  ggplot2::theme_minimal(base_size = 11) +
    ggplot2::theme(
      plot.title = ggplot2::element_text(face = "bold"),
      legend.position = "bottom"
    )
}

save_actual_series_plot <- function(series, path) {
  plot <- ggplot2::ggplot(series, ggplot2::aes(x = date, y = value)) +
    ggplot2::geom_line(color = "#1f77b4", linewidth = 0.6) +
    ggplot2::labs(
      title = "Agricultural Products Producer Price Index Monthly Change",
      x = "Period",
      y = "Monthly rate of change (%)"
    ) +
    theme_project()

  ggplot2::ggsave(path, plot, width = 9, height = 5, dpi = 150)
  plot
}

save_forecast_plot <- function(test_data, forecast, method_name, path) {
  plot_data <- dplyr::bind_rows(
    data.frame(date = test_data$date, value = test_data$value, series = "Actual"),
    data.frame(date = test_data$date, value = forecast, series = "Forecast")
  )

  plot <- ggplot2::ggplot(plot_data, ggplot2::aes(x = date, y = value, color = series)) +
    ggplot2::geom_line(linewidth = 0.65) +
    ggplot2::geom_point(size = 1.5) +
    ggplot2::scale_color_manual(values = c("Actual" = "#1f77b4", "Forecast" = "#d62728")) +
    ggplot2::labs(
      title = paste("Actual vs Forecast -", method_name),
      x = "Period",
      y = "Monthly rate of change (%)",
      color = NULL
    ) +
    theme_project()

  ggplot2::ggsave(path, plot, width = 9, height = 5, dpi = 150)
  plot
}

save_superior_plot <- function(full_series, next_period, next_forecast, method_name, path) {
  next_date <- as.Date(paste0(next_period, "-01"))
  plot_data <- dplyr::bind_rows(
    data.frame(date = full_series$date, value = full_series$value, series = "Actual"),
    data.frame(date = next_date, value = next_forecast, series = "Final forecast")
  )

  plot <- ggplot2::ggplot(plot_data, ggplot2::aes(x = date, y = value, color = series)) +
    ggplot2::geom_line(data = subset(plot_data, series == "Actual"), linewidth = 0.55) +
    ggplot2::geom_point(data = subset(plot_data, series == "Final forecast"), size = 3) +
    ggplot2::scale_color_manual(values = c("Actual" = "#1f77b4", "Final forecast" = "#d62728")) +
    ggplot2::labs(
      title = paste("Final Forecast Using", method_name),
      x = "Period",
      y = "Monthly rate of change (%)",
      color = NULL
    ) +
    theme_project()

  ggplot2::ggsave(path, plot, width = 9, height = 5, dpi = 150)
  plot
}
