# Check VaR exceedance rates

`model_check()` performs a rolling, horizon-aligned VaR exceedance
check. At each historical forecast origin, it fits the FAVAR model on
the previous `window` months, simulates h-horizon portfolio losses, and
compares the resulting 95 percent VaR with the realized h-horizon
portfolio loss. It also reports the same exceedance rate for a
Historical Simulation VaR benchmark.

## Usage

``` r
model_check(
  macro_data,
  return_data,
  portfolio,
  horizon = 12,
  n_scenarios = 300,
  k = 2,
  var_lag = 1,
  seed = 123,
  window = 120,
  n_origins = 36
)
```

## Arguments

- macro_data:

  A data frame that contains `date` and macro predictor columns.

- return_data:

  A data frame with `date`, `equity_return`, `bond_return`, and
  `cash_return` columns.

- portfolio:

  A data frame that contains weights for the required assets `equity`,
  `bond`, and `cash`.

- horizon:

  Integer VaR horizon in months. Default is `12`.

- n_scenarios:

  Integer number of simulated FAVAR paths at each rolling forecast
  origin. Default is `300`.

- k:

  Integer number of principal-component macro factors used in the FAVAR
  state vector. Default is `2`.

- var_lag:

  Integer lag order for the VAR fitted to macro factors and asset
  returns. Default is `1`.

- seed:

  Integer random seed used for bootstrap simulation. Default is `123`.

- window:

  Integer rolling estimation window in months. Default is `120`.

- n_origins:

  Integer number of most recent forecast origins to check. Default is
  `36`.

## Value

An object of class `model_check`, a list with: `var_exceedance`, a
summary table comparing FAVAR scenario VaR and Historical Simulation VaR
exceedance rates.

## Examples

``` r
check <- model_check(
  macro_data = demo_macro_data,
  return_data = demo_return_data,
  portfolio = demo_portfolio_weights,
  horizon = 12,
  n_scenarios = 200,
  k = 2,
  var_lag = 1,
  seed = 123,
  window = 120,
  n_origins = 24
)
```
