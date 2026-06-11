#' Estimate portfolio downside risk under simulated macro-financial scenarios
#'
#' `portfolio_risk()` fits a factor-augmented VAR model to monthly macro
#' predictors and equity/bond/cash returns, simulates future return paths, and
#' reports terminal portfolio loss risk over the requested horizon.
#'
#' @param macro_data A data frame that contains `date` and macro predictor
#' columns.
#' @param return_data A data frame with `date`, `equity_return`, `bond_return`,
#'   and `cash_return` columns.
#' @param portfolio A data frame that contains weights for the required
#'   assets `equity`, `bond`, and `cash`.
#' @param horizon Integer forecast horizon in months.
#' @param n_scenarios Integer number of simulated future paths.
#' @param k Integer number of principal-component macro factors used in the
#'   FAVAR state vector.
#' @param var_lag Integer lag order for the VAR fitted to macro factors and
#'   asset returns.
#' @param seed Integer random seed used for bootstrap simulation.
#'
#' @returns An object of class `portfolio_risk`, a list with:
#'   `risk_summary`, a one-row table of mean loss, median loss, probability of
#'   loss, 95 percent VaR, and 95 percent expected shortfall;
#'   `loss_distribution`, one terminal loss per simulated scenario.
#' @export
#'
#' @examples
#' risk <- portfolio_risk(
#'   macro_data = demo_macro_data,
#'   return_data = demo_return_data,
#'   portfolio = demo_portfolio_weights,
#'   horizon = 60,
#'   n_scenarios = 500,
#'   k = 2,
#'   var_lag = 1,
#'   seed = 123
#' )

portfolio_risk <- function(macro_data,
                           return_data,
                           portfolio,
                           horizon = 60,
                           n_scenarios = 1000,
                           k = 2,
                           var_lag = 1,
                           seed = 123) {
  # Data prep
  required_returns <- REQUIRED_ASSET_RETURNS
  check_required_columns(return_data, c("date", required_returns), "return_data")


  portfolio <- prepare_portfolio(portfolio)


  return_data <- return_data |>
    dplyr::select(dplyr::all_of(c("date", required_returns)))

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
      risk_summary = impact$summary,

      loss_distribution = impact$loss_distribution
    ),
    class = "portfolio_risk"
  )
}
