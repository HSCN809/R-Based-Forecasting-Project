Sys.setenv(CURL_SSL_BACKEND = "openssl")

# Fixed identifiers for the selected TÜİK table verified through tuikr.
target_theme_id <- 6
target_node_id <- 1
target_dataflow_id <- "TR,DF_TARIM_URUNLERI_UFE_DEGISIM_V1,1.0"

project_source_info <- function() {
  list(
    student_name = "Hüseyin Berat Özen",
    student_number = "138722005",
    dataset_name = "Agricultural Products Producer Price Index",
    theme = "Price Statistics",
    table_name = "Producer Price Index of Agricultural Products and Rates of Change [2020=100]",
    dataflow_id = target_dataflow_id,
    selected_variable = "Change compared to the previous month (%)",
    frequency = "Monthly",
    access_date = as.character(Sys.Date())
  )
}

run_with_retry <- function(description, expr, attempts = 4, pause_seconds = 3) {
  expr_call <- substitute(expr)
  expr_env <- parent.frame()
  last_error <- NULL

  for (attempt in seq_len(attempts)) {
    result <- tryCatch(
      eval(expr_call, envir = expr_env),
      error = function(error) {
        last_error <<- error
        NULL
      }
    )

    if (!is.null(result)) {
      return(result)
    }

    message(description, " failed on attempt ", attempt, ": ", conditionMessage(last_error))
    if (attempt < attempts) {
      Sys.sleep(pause_seconds)
    }
  }

  stop(last_error)
}

# Decode compact Data Browser observation offsets into dimension indexes.
decode_offset <- function(offset, sizes) {
  indexes <- integer(length(sizes))
  remainder <- offset

  for (position in rev(seq_along(sizes))) {
    indexes[position] <- remainder %% sizes[position]
    remainder <- remainder %/% sizes[position]
  }

  indexes
}

# Retrieve the verified TÜİK dataflow through reproducible R code.
read_data_browser_json <- function(dataflow_id = target_dataflow_id, node_id = target_node_id) {
  data_url <- paste0(
    "https://databrowser2.tuik.gov.tr/api/core/nodes/",
    node_id,
    "/datasets/",
    dataflow_id,
    "/data"
  )

  handle <- curl::new_handle(
    useragent = paste(
      "Mozilla/5.0 (Windows NT 10.0; Win64; x64)",
      "AppleWebKit/537.36 (KHTML, like Gecko)",
      "Chrome/122.0.0.0 Safari/537.36"
    )
  )
  curl::handle_setheaders(
    handle,
    "Accept" = "application/json, text/plain, */*",
    "Content-Type" = "application/json"
  )
  curl::handle_setopt(handle, postfields = "[]")

  response <- run_with_retry(
    "Data Browser JSON request",
    curl::curl_fetch_memory(data_url, handle = handle)
  )

  if (response$status_code != 200) {
    stop("Data Browser API returned HTTP status ", response$status_code, call. = FALSE)
  }

  jsonlite::fromJSON(rawToChar(response$content), simplifyVector = FALSE)
}

# Convert the JSON-stat style payload into one row per observation.
decode_data_browser_values <- function(payload) {
  dimension_ids <- payload$id
  dimension_sizes <- as.integer(payload$size)
  value_offsets <- as.integer(names(payload$value))
  value_numbers <- as.numeric(unlist(payload$value, use.names = FALSE))

  dimension_codes <- lapply(dimension_ids, function(dimension_id) {
    unlist(payload$dimension[[dimension_id]]$category$index, use.names = FALSE)
  })
  names(dimension_codes) <- dimension_ids

  decoded_rows <- lapply(seq_along(value_offsets), function(i) {
    indexes <- decode_offset(value_offsets[i], dimension_sizes)
    codes <- vapply(seq_along(indexes), function(j) {
      dimension_codes[[j]][indexes[j] + 1]
    }, character(1))

    row <- as.list(codes)
    names(row) <- dimension_ids
    row$obs_value <- value_numbers[i]
    row
  })

  dplyr::bind_rows(decoded_rows)
}

fetch_selected_series <- function() {
  # Confirm that the selected dataflow exists in the tuikr catalog before analysis.
  tables <- run_with_retry(
    "tuikr::statistical_tables()",
    tuikr::statistical_tables(target_theme_id, lang = "en")
  )
  target_table <- tables[
    !is.na(tables$dataflow_id) & tables$dataflow_id == target_dataflow_id,
  ]

  if (nrow(target_table) != 1) {
    stop("Target dataflow was not found uniquely through tuikr::statistical_tables().", call. = FALSE)
  }

  payload <- read_data_browser_json(target_dataflow_id, target_node_id)
  long_data <- decode_data_browser_values(payload)

  # Select the monthly Türkiye total rate-of-change series required for forecasting.
  selected_series <- long_data |>
    dplyr::filter(
      INDICATOR == "F_TARUFE",
      UNIT_MEASURE == "RO",
      FREQ == "M",
      REF_AREA == "TR",
      DEGISIM == "2",
      BAZ_YIL == "2020",
      TAORBA_2008_2_678 == "A"
    ) |>
    dplyr::transmute(
      period = TIME_PERIOD,
      date = as.Date(paste0(TIME_PERIOD, "-01")),
      value = obs_value
    ) |>
    dplyr::arrange(date)

  if (nrow(selected_series) == 0) {
    stop("Selected monthly rate-of-change series is empty.", call. = FALSE)
  }

  list(
    source_info = project_source_info(),
    verified_table = target_table,
    raw_payload_label = payload$label,
    series = selected_series
  )
}

next_month_period <- function(period) {
  latest_date <- as.Date(paste0(period, "-01"))
  format(seq(latest_date, by = "month", length.out = 2)[2], "%Y-%m")
}
