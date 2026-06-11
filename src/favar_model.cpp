#include <Rcpp.h>
#include <cmath>

using namespace Rcpp;

// Simulate FAVAR state paths using residual bootstrap.
//
// Model equation:
//   y_next = constant + A1 * y_lag1 + ... + Ap * y_lagp + bootstrapped_residual
//
// Inputs:
//   constant     one intercept per state variable.
//   transition   flattened VAR coefficient array from R:
//                state x state x lag, stored in R's column-major order.
//   residuals    centered VAR residual matrix used for bootstrap shocks.
//   last_states  most recent VAR lag states; row 1 is y_{t-1},
//                row 2 is y_{t-2}, and so on.
//
// Output:
//   a 3D R array with dimensions scenario x horizon x state_variable.
//
// [[Rcpp::export]]
NumericVector simulate_favar_cpp(
    NumericVector constant,
    NumericVector transition,
    NumericMatrix residuals,
    NumericMatrix last_states,
    int horizon,
    int n_scenarios) {

  int n_state = constant.size();
  int var_lag = last_states.nrow();
  int n_residuals = residuals.nrow();

  // RNGScope keeps R's random-number state consistent while C++ draws shocks.
  RNGScope rng_scope;

  NumericVector states(Dimension(n_scenarios, horizon, n_state));

  // Outer loop: independent simulated scenario paths.
  for (int s = 0; s < n_scenarios; ++s) {
    // lag_states row 0 is y_{t-1}, row 1 is y_{t-2}, and so on.
    NumericMatrix lag_states = clone(last_states);

    // Inner loop: recursively step forward one horizon period at a time.
    for (int h = 0; h < horizon; ++h) {
      // Residual bootstrap: sample one historical VAR residual vector.
      int shock_row = static_cast<int>(
        std::floor(R::runif(0.0, n_residuals))
      );

      if (shock_row >= n_residuals) {
        shock_row = n_residuals - 1;
      }

      NumericVector next(n_state);

      for (int j = 0; j < n_state; ++j) {
        double value = constant[j] + residuals(shock_row, j);

        // Add A_lag * y_{t-lag} contributions for the j-th equation.
        for (int lag = 0; lag < var_lag; ++lag) {
          for (int i = 0; i < n_state; ++i) {
            // R stores arrays in column-major order:
            // transition[i, j, lag].
            int transition_index =
              i + n_state * j + n_state * n_state * lag;

            value += lag_states(lag, i) * transition[transition_index];
          }
        }

        next[j] = value;
      }

      // Shift lag rows down so the newly simulated state becomes lag 1.
      for (int lag = var_lag - 1; lag >= 1; --lag) {
        for (int j = 0; j < n_state; ++j) {
          lag_states(lag, j) = lag_states(lag - 1, j);
        }
      }

      for (int j = 0; j < n_state; ++j) {
        lag_states(0, j) = next[j];

        // Store output using R's column-major array indexing:
        // states[scenario, horizon_step, state_variable].
        states[
          s +
          n_scenarios * h +
          n_scenarios * horizon * j
        ] = next[j];
      }
    }
  }

  return states;
}
