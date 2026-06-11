# Internal checks and input preparation


# Fixed asset universe for the package use: equity, bond, and cash.
REQUIRED_ASSETS <- c("equity", "bond", "cash")
REQUIRED_ASSET_RETURNS <- paste0(REQUIRED_ASSETS, "_return")


# Checks that a data frame contains all columns required by the next step.
check_required_columns <- function(data, cols, data_name) {
  missing_cols <- setdiff(cols, names(data))

  if (length(missing_cols) > 0) {
    stop(
      data_name,
      " is missing required columns: ",
      paste(missing_cols, collapse = ", "),
      call. = FALSE
    )
  }

  invisible(data)
}


# Validates a date column before any join or time-series ordering.
check_date_column <- function(data, data_name) {
  original_date <- data$date

  # Accept Date/POSIX date-time objects directly; otherwise require character
  # strings that R can parse as dates.
  parsed_date <- if (inherits(original_date, "Date")) {
    original_date
  } else if (inherits(original_date, "POSIXt")) {
    as.Date(original_date)
  } else if (is.character(original_date)) {
    suppressWarnings(as.Date(original_date))
  } else {
    stop(
      data_name,
      "$date must be a Date column or character dates in YYYY-MM-DD format.",
      call. = FALSE
    )
  }

  # Stop if any date cannot be parsed or is missing.
  if (any(is.na(parsed_date))) {
    stop(
      data_name,
      "$date must contain valid dates, preferably in YYYY-MM-DD format.",
      call. = FALSE
    )
  }

  # Monthly data should have one observation per date in each input table.
  if (anyDuplicated(parsed_date) > 0) {
    stop(data_name, "$date must be unique.", call. = FALSE)
  }

  data$date <- parsed_date
  data
}


# Converts the user-facing portfolio table into the internal format.
#
# The function adds return_col internally:
#   equity -> equity_return
#   bond   -> bond_return
#   cash   -> cash_return
prepare_portfolio <- function(portfolio) {
  # Check that the portfolio table has the two user-facing columns.
  check_required_columns(portfolio, c("asset", "weight"), "portfolio")

  # Normalize asset names so "Equity" and "equity" are treated the same.
  portfolio <- portfolio |>
    dplyr::mutate(asset = tolower(.data$asset))

  # Check that users did not provide unsupported assets.
  unknown_assets <- setdiff(portfolio$asset, REQUIRED_ASSETS)
  if (length(unknown_assets) > 0) {
    stop(
      "portfolio$asset must only contain: ",
      paste(REQUIRED_ASSETS, collapse = ", "),
      call. = FALSE
    )
  }

  # Check that each asset appears once.
  if (anyDuplicated(portfolio$asset) > 0) {
    stop("portfolio$asset values must be unique.", call. = FALSE)
  }

  # Check that the fixed equity/bond/cash universe is complete.
  missing_assets <- setdiff(REQUIRED_ASSETS, portfolio$asset)
  if (length(missing_assets) > 0) {
    stop(
      "portfolio is missing required asset rows: ",
      paste(missing_assets, collapse = ", "),
      call. = FALSE
    )
  }

  # Add internal return column names used later by the portfolio engine.
  portfolio <- portfolio |>
    dplyr::mutate(return_col = paste0(.data$asset, "_return"))

  # Check that weights are numeric.
  if (!is.numeric(portfolio$weight)) {
    stop("portfolio$weight must be numeric.", call. = FALSE)
  }

  # Check that weights are not NA, Inf, or -Inf.
  if (any(!is.finite(portfolio$weight))) {
    stop("portfolio weights must be finite numeric values.", call. = FALSE)
  }

  # Check that the package is not receiving short positions.
  if (any(portfolio$weight < 0)) {
    stop("portfolio weights must be non-negative.", call. = FALSE)
  }

  # Check that the three asset weights form a fully invested portfolio.
  weight_sum <- sum(portfolio$weight)
  if (!isTRUE(all.equal(weight_sum, 1, tolerance = 1e-6))) {
    stop("portfolio weights must sum to 1.", call. = FALSE)
  }

  portfolio |>
    dplyr::mutate(.asset_order = match(.data$asset, REQUIRED_ASSETS)) |>
    dplyr::arrange(.data$.asset_order) |>
    dplyr::select(.data$asset, .data$return_col, .data$weight)
}


# Aligns macro predictors and asset returns by date before model fitting.
#
prepare_model_data <- function(macro_data, return_data) {
  # Check that both input tables have a date column for alignment.
  check_required_columns(macro_data, "date", "macro_data")
  check_required_columns(return_data, "date", "return_data")

  # Use every macro column except date as a predictor.
  predictors <- setdiff(names(macro_data), "date")

  # Use every return-data column except date as an asset return.
  returns <- setdiff(names(return_data), "date")

  # Check that there is at least one macro predictor.
  if (length(predictors) == 0) {
    stop("macro_data must contain at least one predictor column.", call. = FALSE)
  }

  # Check that there is at least one asset return series.
  if (length(returns) == 0) {
    stop("return_data must contain at least one return column.", call. = FALSE)
  }

  # Check that macro and return columns do not reuse the same names.
  overlapping_names <- intersect(predictors, returns)
  if (length(overlapping_names) > 0) {
    stop(
      "macro_data and return_data must not share non-date column names: ",
      paste(overlapping_names, collapse = ", "),
      call. = FALSE
    )
  }

  # Keep only modelling columns and validate dates before alignment.
  macro_data <- macro_data |>
    dplyr::select(.data$date, dplyr::all_of(predictors)) |>
    check_date_column("macro_data")

  return_data <- return_data |>
    dplyr::select(.data$date, dplyr::all_of(returns)) |>
    check_date_column("return_data")

  # Check that all macro predictors are numeric.
  if (!all(vapply(macro_data[predictors], is.numeric, logical(1)))) {
    stop("macro predictors must be numeric.", call. = FALSE)
  }

  # Check that all asset returns are numeric.
  if (!all(vapply(return_data[returns], is.numeric, logical(1)))) {
    stop("asset return columns must be numeric.", call. = FALSE)
  }

  # Align macro predictors and asset returns on overlapping complete dates.
  data <- dplyr::inner_join(macro_data, return_data, by = "date") |>
    dplyr::arrange(.data$date) |>
    tidyr::drop_na()

  # Check that the aligned sample is long enough for monthly time-series work.
  if (nrow(data) < 24) {
    stop("At least 24 overlapping complete monthly observations are required.",
         call. = FALSE)
  }

  list(data = data, returns = returns, predictors = predictors)
}
