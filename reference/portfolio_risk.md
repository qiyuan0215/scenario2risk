# Estimate portfolio downside risk under simulated macro-financial scenarios

`portfolio_risk()` fits a factor-augmented VAR model to monthly macro
predictors and equity/bond/cash returns, simulates future return paths,
and reports terminal portfolio loss risk over the requested horizon.

## Usage

``` r
portfolio_risk(
  macro_data,
  return_data,
  portfolio,
  horizon = 60,
  n_scenarios = 1000,
  k = 2,
  var_lag = 1,
  seed = 123
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

  Integer forecast horizon in months. Default is `60`.

- n_scenarios:

  Integer number of simulated future paths. Default is `1000`.

- k:

  Integer number of principal-component macro factors used in the FAVAR
  state vector. Default is `2`.

- var_lag:

  Integer lag order for the VAR fitted to macro factors and asset
  returns. Default is `1`.

- seed:

  Integer random seed used for bootstrap simulation. Default is `123`.

## Value

An object of class `portfolio_risk`, a list with: `risk_summary`, a
one-row table of mean loss, median loss, probability of loss, 95 percent
VaR, and 95 percent expected shortfall; `loss_distribution`, one
terminal loss per simulated scenario.

## Examples

``` r
risk <- portfolio_risk(
  macro_data = demo_macro_data,
  return_data = demo_return_data,
  portfolio = demo_portfolio_weights,
  horizon = 60,
  n_scenarios = 500,
  k = 2,
  var_lag = 1,
  seed = 123
)
```
