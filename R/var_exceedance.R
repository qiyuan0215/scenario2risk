# Internal tool: rolling VaR exceedance check.
# Not exported; called by model_check().

model_check_engine <- function(macro_data,
                               return_data,
                               portfolio,
                               horizon = 12,
                               window = 120,
                               k = 2,
                               var_lag = 1,
                               n_scenarios = 300,
                               n_origins = 36,
                               seed = 123,
                               use_parallel = FALSE,
                               n_cores = 2) {

  model_data <- prepare_model_data(macro_data, return_data)
  data <- model_data$data
  returns <- model_data$returns
  predictors <- model_data$predictors

  # Convert realized asset returns into realized portfolio returns.
  # The forward loss is the realized h-horizon terminal loss used for VaR checks.
  portfolio_returns <- realized_portfolio_returns(data, portfolio) |>
    dplyr::mutate(
      forward_return =
        cumulative_forward_return(.data$portfolio_return, horizon),
      forward_loss = -.data$forward_return
    )

  max_origin <- nrow(data) - horizon

  # Each origin needs a full training window behind it and h future months ahead.
  if (max_origin < window) {
    stop(
      "Not enough observations for this horizon and rolling window.",
      call. = FALSE
    )
  }

  # Historical Simulation VaR needs at least two overlapping h-horizon windows.
  if (window <= horizon) {
    stop(
      "window must be larger than horizon for historical simulation VaR.",
      call. = FALSE
    )
  }

  # Use the latest available origins. Each origin is one historical forecast date.
  origins <- utils::tail(seq.int(window, max_origin), n_origins)

  run_origin <- function(i) {
    origin <- origins[i]
    train_data <- data[(origin - window + 1):origin, ]
    train_port <- portfolio_returns[(origin - window + 1):origin, ]

    # Method 1: fit FAVAR on the past window and simulate h-horizon losses.
    fit <- fit_favar(
      data = train_data,
      returns = returns,
      predictors = predictors,
      k = k,
      var_lag = var_lag
    )

    states <- simulate_favar(
      fit = fit,
      horizon = horizon,
      n_scenarios = n_scenarios,
      seed = seed + i
    )

    return_paths <- make_return_paths(
      states = states,
      data = train_data,
      returns = returns,
      horizon = horizon,
      n_scenarios = n_scenarios
    )

    favar_impact <- portfolio_impact(
      return_paths = return_paths,
      portfolio = portfolio,
      initial_value = 100
    )

    # Method 2: construct h-horizon losses directly from historical portfolio
    # returns in the same training window.
    hs_losses <- historical_horizon_losses(
      x = train_port$portfolio_return,
      horizon = horizon
    )

    hs_var_95 <- as.numeric(
      stats::quantile(hs_losses, 0.95, na.rm = TRUE)
    )

    realized_loss <- portfolio_returns$forward_loss[origin]

    tibble::tibble(
      origin_date = data$date[origin],
      realized_horizon_return = portfolio_returns$forward_return[origin],
      realized_horizon_loss = realized_loss,
      favar_var_95 = favar_impact$summary$var_95,
      hs_var_95 = hs_var_95,
      favar_exceedance = realized_loss > favar_impact$summary$var_95,
      hs_exceedance = realized_loss > hs_var_95
    )
  }

  forecasts <- run_origins(
    origin_ids = seq_along(origins),
    run_origin = run_origin,
    use_parallel = use_parallel,
    n_cores = n_cores
  )

  summarize_var_exceedance(forecasts)
}


summarize_var_exceedance <- function(forecasts) {
  # The comparison is frequency-based: each origin contributes one realized
  # h-horizon loss and one exceedance indicator per VaR method.
  tibble::tibble(
    model = c("favar_scenario", "historical_simulation"),
    var_95_exceedance = c(
      mean(forecasts$favar_exceedance, na.rm = TRUE),
      mean(forecasts$hs_exceedance, na.rm = TRUE)
    ),
    expected_exceedance = 0.05,
    n_origins = c(
      sum(!is.na(forecasts$favar_exceedance)),
      sum(!is.na(forecasts$hs_exceedance))
    ),
    n_exceedances = c(
      sum(forecasts$favar_exceedance, na.rm = TRUE),
      sum(forecasts$hs_exceedance, na.rm = TRUE)
    )
  )
}


run_origins <- function(origin_ids, run_origin, use_parallel, n_cores) {
  # Sequential execution is the default because small rolling checks can be
  # slower after PSOCK cluster setup and data-transfer overhead.
  if (!isTRUE(use_parallel) || length(origin_ids) <= 1) {
    return(dplyr::bind_rows(lapply(origin_ids, run_origin)))
  }

  # Parallel execution is optional and only used when the request is meaningful.
  n_cores <- as.integer(n_cores)
  if (length(n_cores) != 1 || is.na(n_cores) || n_cores < 2) {
    return(dplyr::bind_rows(lapply(origin_ids, run_origin)))
  }

  n_cores <- min(n_cores, length(origin_ids))

  # Rolling origins are independent, so they are compatible with
  # parallel-computing.
  cluster <- parallel::makeCluster(n_cores)
  on.exit(parallel::stopCluster(cluster), add = TRUE)

  # Export the closure environment to PSOCK workers.
  parallel::clusterExport(
    cl = cluster,
    varlist = ls(environment(run_origin)),
    envir = environment(run_origin)
  )

  dplyr::bind_rows(
    parallel::parLapply(cluster, origin_ids, run_origin)
  )
}


realized_portfolio_returns <- function(data, portfolio) {
  # Apply fixed equity/bond/cash weights to realized asset returns.
  weights <- stats::setNames(portfolio$weight, portfolio$return_col)
  asset_matrix <- as.matrix(data[, names(weights), drop = FALSE])

  tibble::tibble(
    date = data$date,
    portfolio_return = as.numeric(asset_matrix %*% weights)
  )
}


cumulative_forward_return <- function(x, horizon) {
  # For origin t, use returns t+1 through t+h to form one realized h-horizon
  # return. This keeps the realized outcome aligned with the VaR horizon.
  out <- rep(NA_real_, length(x))

  for (i in seq_along(x)) {
    end <- i + horizon
    if (end <= length(x)) {
      out[i] <- prod(1 + x[(i + 1):end]) - 1
    }
  }

  out
}


historical_horizon_losses <- function(x, horizon) {
  # Historical Simulation VaR uses overlapping h-horizon losses inside the
  # training window. It is non-parametric and backward-looking.
  n_windows <- length(x) - horizon + 1
  if (n_windows < 1) {
    return(numeric())
  }

  losses <- rep(NA_real_, n_windows)

  for (i in seq_len(n_windows)) {
    losses[i] <- 1 - prod(1 + x[i:(i + horizon - 1)])
  }

  losses
}
