# user function: rolling VaR model check.
# Answers: How often do h-period realized losses exceed FAVAR VaR and
# Historical Simulation VaR?

#' @export
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
  # The public wrapper validates the fixed equity/bond/cash inputs before the
  # rolling engine starts refitting models.
  required_returns <- REQUIRED_ASSET_RETURNS
  check_required_columns(return_data, c("date", required_returns), "return_data")

  portfolio <- prepare_portfolio(portfolio)

  # Keep only the fixed asset-return universe used by the package story.
  return_data <- return_data |>
    dplyr::select(.data$date, dplyr::all_of(required_returns))

  model_check_engine(
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
}
