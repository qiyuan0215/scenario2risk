# Internal helper: FAVAR state simulation.
# Not exported; called by portfolio_risk() and model_check().

simulate_favar_states <- function(macro_data,
                                  return_data,
                                  horizon = 60,
                                  n_scenarios = 1000,
                                  k = 2,
                                  var_lag = 1,
                                  seed = 123) {
  model_data <- prepare_model_data(macro_data, return_data)
  data <- model_data$data
  returns <- model_data$returns
  predictors <- model_data$predictors

  # Fit FAVAR once, then simulate future states.
  fit <- fit_favar(data, returns, predictors, k = k, var_lag = var_lag)
  states <- simulate_favar(fit, horizon, n_scenarios, seed)

  list(
    states = states,
    returns = returns
  )
}

make_macro_factors <- function(data, predictors, k = 2) {
  # Keep dates for later joins; PCA itself only uses numeric predictors.
  x <- data |>
    dplyr::select(dplyr::all_of(c("date", predictors)))

  k <- min(k, length(predictors))

  # Scaling the predictors for the PCA.
  scaled_x <- scale(x[, predictors, drop = FALSE])
  pca <- stats::prcomp(scaled_x, center = FALSE, scale. = FALSE)

  # Store the first k principal-component scores as macro factors.
  factor_names <- paste0("factor", seq_len(k))
  scores <- tibble::as_tibble(pca$x[, seq_len(k), drop = FALSE])
  names(scores) <- factor_names
  scores <- dplyr::bind_cols(tibble::tibble(date = x$date), scores)

  list(
    scores = scores,
    pca = pca,
    k = k
  )
}

fit_favar <- function(data, returns, predictors, k, var_lag = 1) {
  var_lag <- as.integer(var_lag)
  if (!is.finite(var_lag) || var_lag < 1) {
    stop("var_lag must be a positive integer.", call. = FALSE)
  }

  factors <- make_macro_factors(data, predictors, k = k)
  factor_cols <- paste0("factor", seq_len(factors$k))

  # Combine estimated macro factors with observed asset returns.
  state_data <- factors$scores |>
    dplyr::left_join(
      data |> dplyr::select(dplyr::all_of(c("date", returns))),
      by = "date"
    )

  state_cols <- c(factor_cols, returns)
  y <- as.data.frame(state_data[, state_cols, drop = FALSE])

  if (nrow(y) <= var_lag + 5) {
    stop(
      "Not enough complete observations for the requested VAR lag.",
      call. = FALSE
    )
  }

  # Estimate a VAR(p) with a constant using the vars package.
  # Equation form: y_t = constant + A1*y_{t-1} + ... + Ap*y_{t-p} + u_t.
  var_fit <- vars::VAR(y, p = var_lag, type = "const")
  var_coef <- stats::coef(var_fit)

  # Convert vars::VAR coefficient tables into arrays used by the simulator.
  transition <- extract_var_transition(var_coef, state_cols, var_lag)

  # Extract one intercept per state equation.
  constant <- vapply(
    var_coef,
    function(eq) eq["const", "Estimate"],
    numeric(1)
  )
  names(constant) <- state_cols

  residuals <- as.matrix(stats::residuals(var_fit))
  residuals <- sweep(residuals, 2, colMeans(residuals), "-")

  # Store the latest p states so simulated paths can start at the final sample.
  last_states <- y[seq.int(nrow(y), nrow(y) - var_lag + 1), , drop = FALSE]
  last_states <- as.matrix(last_states)
  colnames(last_states) <- state_cols

  list(
    factors = factors,
    state_data = state_data,
    factor_cols = factor_cols,
    model = list(
      state_cols = state_cols,
      constant = constant,
      transition = transition,
      residuals = residuals,
      last_states = last_states,
      var_lag = var_lag
    )
  )
}

extract_var_transition <- function(var_coef, state_cols, var_lag) {
  n_state <- length(state_cols)

  # transition[i, j, lag] is the coefficient from state i at lag p to
  # equation j at the current time.
  transition <- array(
    NA_real_,
    dim = c(n_state, n_state, var_lag),
    dimnames = list(state_cols, state_cols, paste0("lag", seq_len(var_lag)))
  )

  for (lag in seq_len(var_lag)) {
    # vars::VAR names lagged rows as variable.l1, variable.l2, etc.
    lag_rows <- paste0(state_cols, ".l", lag)
    transition[, , lag] <- do.call(
      cbind,
      lapply(var_coef, function(eq) eq[lag_rows, "Estimate"])
    )
  }

  transition
}

simulate_favar <- function(fit, horizon, n_scenarios, seed) {
  # The simulation loop is implemented in C++ to keep this R
  # engine focused on data preparation and model fitting.

  set.seed(seed)

  states <- simulate_favar_cpp(
    constant = as.numeric(fit$model$constant),
    transition = as.numeric(fit$model$transition),
    residuals = as.matrix(fit$model$residuals),
    last_states = as.matrix(fit$model$last_states),
    horizon = as.integer(horizon),
    n_scenarios = as.integer(n_scenarios)
  )

  # Rcpp returns a plain array, so restore state names for downstream indexing.
  dimnames(states) <- list(NULL, NULL, fit$model$state_cols)

  states
}
