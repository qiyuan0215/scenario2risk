#' Check VaR exceedance rates
#'
#' `model_check()` performs a rolling, horizon-aligned VaR exceedance check.
#' At each historical forecast origin, it fits the FAVAR model on the previous
#' `window` months, simulates h-horizon portfolio losses, and compares the
#' resulting 95 percent VaR with the realized h-horizon portfolio loss. It also
#' reports the same exceedance rate for a Historical Simulation VaR benchmark.
#'
#' @param macro_data A data frame that contains `date` and macro predictor
#' columns.
#' @param return_data A data frame with `date`, `equity_return`, `bond_return`,
#'   and `cash_return` columns.
#' @param portfolio A data frame that contains weights for the required
#'   assets `equity`, `bond`, and `cash`.
#' @param horizon Integer VaR horizon in months.
#' @param n_scenarios Integer number of simulated FAVAR paths at each rolling
#'   forecast origin.
#' @param k Integer number of principal-component macro factors used in the
#'   FAVAR state vector.
#' @param var_lag Integer lag order for the VAR fitted to macro factors and
#'   asset returns.
#' @param seed Integer random seed used for bootstrap simulation.
#' @param window Integer rolling estimation window in months.
#' @param n_origins Integer number of most recent forecast origins to check.
#' @param use_parallel Logical. If `TRUE`, rolling origins are evaluated with a
#'   PSOCK cluster; otherwise they are evaluated sequentially.
#' @param n_cores Integer number of worker processes used when
#'   `use_parallel = TRUE`.
#'
#' @returns An object of class `model_check`, a list with:
#'   `var_exceedance`, a summary table comparing FAVAR scenario VaR and
#'   Historical Simulation VaR exceedance rates.
#' @export
#'
#' @examples
#' check <- model_check(
#'   macro_data = demo_macro_data,
#'   return_data = demo_return_data,
#'   portfolio = demo_portfolio_weights,
#'   horizon = 12,
#'   n_scenarios = 200,
#'   k = 2,
#'   var_lag = 1,
#'   seed = 123,
#'   window = 120,
#'   n_origins = 24,
#'   use_parallel = FALSE
#' )

model_check <- function(macro_data,
                        return_data,
                        portfolio,
                        horizon = 12,
                        n_scenarios = 300,
                        k = 2,
                        var_lag = 1,
                        seed = 123,
                        window = 120,
                        n_origins = 36,
                        use_parallel = FALSE,
                        n_cores = 2) {
  # Data prep
  required_returns <- REQUIRED_ASSET_RETURNS
  check_required_columns(return_data, c("date", required_returns), "return_data")

  portfolio <- prepare_portfolio(portfolio)


  return_data <- return_data |>
    dplyr::select(dplyr::all_of(c("date", required_returns)))

  var_exceedance <- model_check_engine(
    macro_data = macro_data,
    return_data = return_data,
    portfolio = portfolio,
    horizon = horizon,
    window = window,
    k = k,
    var_lag = var_lag,
    n_scenarios = n_scenarios,
    n_origins = n_origins,
    seed = seed,
    use_parallel = use_parallel,
    n_cores = n_cores
  )

  structure(
    list(
      var_exceedance = var_exceedance
    ),
    class = "model_check"
  )
}
