# Internal tool: portfolio paths and terminal-loss risk metrics.
# Not exported; called by portfolio_risk() and model_check().

portfolio_impact <- function(return_paths, portfolio, initial_value = 100) {
  # First convert simulated asset returns into simulated portfolio values.
  paths <- build_portfolio_paths(
    return_paths = return_paths,
    portfolio = portfolio,
    initial_value = initial_value
  )

  # Each scenario contributes exactly one horizon-end loss.
  loss_distribution <- paths |>
    dplyr::group_by(.data$scenario_id) |>
    dplyr::summarise(
      terminal_value = dplyr::last(.data$value),
      n_months = dplyr::n(),
      .groups = "drop"
    ) |>
    dplyr::mutate(
      terminal_loss = 1 - .data$terminal_value / initial_value
    )

  # VaR and ES are calculated from the horizon-end loss distribution.
  losses <- loss_distribution$terminal_loss[
    is.finite(loss_distribution$terminal_loss)
  ]
  var_95 <- as.numeric(stats::quantile(losses, 0.95, na.rm = TRUE))
  es_95 <- mean(losses[losses >= var_95], na.rm = TRUE)


  risk_summary <- tibble::tibble(
    mean_loss = mean(losses, na.rm = TRUE),
    median_loss = stats::median(losses, na.rm = TRUE),
    probability_of_loss = mean(losses > 0, na.rm = TRUE),
    var_95 = var_95,
    es_95 = es_95
  )

  list(
    summary = risk_summary,
    loss_distribution = loss_distribution,
    paths = paths,
    initial_value = initial_value
  )
}

build_portfolio_paths <- function(return_paths, portfolio, initial_value) {
  # Move simulated returns from long format to one column per asset return.
  returns_wide <- return_paths |>
    dplyr::select(
      dplyr::all_of(c("scenario_id", "date", "return_col", "return"))
    ) |>
    tidyr::pivot_wider(names_from = "return_col", values_from = "return") |>
    dplyr::arrange(.data$scenario_id, .data$date)

  # Matrix multiplication applies portfolio weights to every simulated month.
  weights <- stats::setNames(portfolio$weight, portfolio$return_col)
  asset_matrix <- as.matrix(returns_wide[, names(weights), drop = FALSE])
  portfolio_return <- as.numeric(asset_matrix %*% weights)

  # Compound monthly portfolio returns into a value path for each scenario.
  returns_wide |>
    dplyr::mutate(portfolio_return = portfolio_return) |>
    dplyr::group_by(.data$scenario_id) |>
    dplyr::arrange(.data$date, .by_group = TRUE) |>
    dplyr::mutate(
      value = initial_value * cumprod(1 + .data$portfolio_return)
    ) |>
    dplyr::ungroup()
}
