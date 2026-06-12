# Internal helper: terminal-loss risk metrics from simulated states.
# Not exported; called by portfolio_risk() and model_check().

portfolio_impact <- function(states, returns, portfolio, initial_value = 100) {
  terminal_value <- terminal_portfolio_values(
    states = states,
    returns = returns,
    portfolio = portfolio,
    initial_value = initial_value
  )

  # Each simulated path contributes one horizon-end portfolio value and loss.
  loss_distribution <- tibble::tibble(
    scenario_id = seq_along(terminal_value),
    terminal_value = terminal_value,
    n_months = dim(states)[2],
    terminal_loss = 1 - terminal_value / initial_value
  )

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
    initial_value = initial_value
  )
}

terminal_portfolio_values <- function(states, returns, portfolio, initial_value) {
  weights <- stats::setNames(portfolio$weight, portfolio$return_col)
  return_cols <- portfolio$return_col[portfolio$return_col %in% returns]

  # Collapse the simulated asset-return states into one portfolio return per
  # scenario-month using the fixed equity/bond/cash weights.
  portfolio_return <- matrix(
    0,
    nrow = dim(states)[1],
    ncol = dim(states)[2]
  )

  for (return_col in return_cols) {
    portfolio_return <- portfolio_return +
      states[, , return_col, drop = TRUE] * weights[[return_col]]
  }

  # Sum log gross returns across months, then exponentiate once to recover each
  # scenario's terminal growth factor without an explicit row-wise loop.
  terminal_growth <- exp(rowSums(log1p(portfolio_return)))
  initial_value * terminal_growth
}
