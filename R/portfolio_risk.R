# user function: portfolio risk
# Answers: How large could my portfolio loss be under simulated macro scenarios?

#' @export
portfolio_risk <- function(macro_data,
                           return_data,
                           portfolio,
                           horizon = 60,
                           n_scenarios = 1000,
                           k = 2,
                           var_lag = 1,
                           seed = 123) {
  # The MVP package assumes a fixed equity/bond/cash asset universe.
  required_returns <- REQUIRED_ASSET_RETURNS
  check_required_columns(return_data, c("date", required_returns), "return_data")

  # Validate the user's portfolio weights and add internal return column names.
  portfolio <- prepare_portfolio(portfolio)

  # Drop any extra return columns so the downstream model uses the fixed assets.
  return_data <- return_data |>
    dplyr::select(.data$date, dplyr::all_of(required_returns))

  # Simulate future monthly asset-return paths from the FAVAR engine.
  return_paths <- simulate_favar_returns(
    macro_data = macro_data,
    return_data = return_data,
    horizon = horizon,
    n_scenarios = n_scenarios,
    k = k,
    var_lag = var_lag,
    seed = seed
  )

  # Convert simulated asset returns into terminal portfolio losses and VaR/ES.
  impact <- portfolio_impact(
    return_paths = return_paths,
    portfolio = portfolio,
    initial_value = 100
  )

  structure(
    list(
      # Compact user-facing summary.
      risk_summary = impact$summary,

      # One row per scenario; this is also the data used by the risk plot.
      loss_distribution = impact$loss_distribution,

      # Store modelling choices so printed objects are reproducible.
      settings = list(
        horizon = horizon,
        n_scenarios = n_scenarios,
        k = k,
        var_lag = var_lag,
        seed = seed
      )
    ),
    class = "portfolio_risk"
  )
}
