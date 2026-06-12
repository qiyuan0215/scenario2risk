# A Tour of scenario2risk

``` r

library(scenario2risk)
```

Welcome! Here is everything behind `scenario2risk`.

Rather than treating risk as a purely historical summary, the package
was built around the idea that downside portfolio risk can be studied
through macro-financial scenarios.

## Why this package?

Many applications stop at one of two extremes:

- simple historical summaries with little economic structure
- complex risk engines that are hard to explain and harder to package

`scenario2risk` sits in the middle. It uses a factor-augmented VAR
framework to connect macro conditions with asset returns, but exposes
that model through a small set of user-facing functions.

## Design motivation

The package was created around three practical design ideas:

1.  Macro conditions matter for portfolio risk, so the model should
    accept a flexible set of macro predictors instead of only historical
    asset returns.
2.  Users usually care about portfolio loss summaries such as VaR and
    expected shortfall, not only raw simulated return paths.
3.  A compact package should still provide model checking, so the
    scenario-based VaR output can be compared against realized rolling
    losses.

This leads to two core workflows:

- [`portfolio_risk()`](https://qiyuan0215.github.io/scenario2risk/reference/portfolio_risk.md)
  for scenario-based terminal-loss measurement
- [`model_check()`](https://qiyuan0215.github.io/scenario2risk/reference/model_check.md)
  for rolling VaR exceedance comparisons

## Package assumptions and built-in choices

Some parts of the package are intentionally flexible, while others are
fixed by design.

### Flexible part: macro predictors

The `macro_data` input can contain any set of numeric monthly predictor
series, as long as:

- there is a `date` column
- the remaining predictor columns are numeric
- there are enough overlapping monthly observations after alignment

This means users can include yield spreads, inflation measures,
labor-market variables, production indicators, sentiment variables, or
other macro-financial series they believe are informative.

### Fixed part: asset universe

The portfolio side of the package is fixed to three asset categories:

- `equity`
- `bond`
- `cash`

That fixed structure keeps the package simple and makes portfolio
aggregation and model checking easier to explain. In practice, this
means the return input must always contain:

- `equity_return`
- `bond_return`
- `cash_return`

and the portfolio weights input must contain one row for each of those
three assets.

## What should the input data look like?

The package works with three input tables:

- `macro_data`
- `return_data`
- `portfolio`

### `macro_data`

`macro_data` should be a data frame with:

- one `date` column
- one or more numeric macro predictor columns
- monthly observations

Below is the structure of the built-in example data:

``` r

head(demo_macro_data)
#>         date term_spread credit_spread gs10_change   infl_yoy unrate
#> 1 1991-01-01      0.0187        0.0141      0.0001 0.05647059  0.064
#> 2 1991-02-01      0.0191        0.0124     -0.0024 0.05312500  0.066
#> 3 1991-03-01      0.0220        0.0116      0.0026 0.04821151  0.068
#> 4 1991-04-01      0.0239        0.0108     -0.0007 0.04809930  0.067
#> 5 1991-05-01      0.0261        0.0100      0.0003 0.05034857  0.069
#> 6 1991-06-01      0.0271        0.0095      0.0021 0.04695920  0.069
#>     indpro_yoy  payroll_yoy housing_yoy consumer_sentiment real_short_rate
#> 1 -0.009614606 -0.001263783  -0.4854932               66.8     0.005729412
#> 2 -0.025779584 -0.006405570  -0.3284621               70.4     0.006275000
#> 3 -0.036186959 -0.009777453  -0.2854926               87.7     0.010888491
#> 4 -0.031105502 -0.012072141  -0.1979167               81.8     0.008400698
#> 5 -0.024949781 -0.014340605  -0.1782178               78.3     0.004251433
#> 6 -0.020371366 -0.013837051  -0.1197961               82.1     0.008740801
```

### `return_data`

`return_data` should be a data frame with:

- one `date` column
- `equity_return`
- `bond_return`
- `cash_return`

These returns should be aligned at the same monthly frequency as the
macro predictors.

``` r

head(demo_return_data)
#>         date equity_return bond_return cash_return
#> 1 1991-01-01        0.0521     -0.0148      0.0052
#> 2 1991-02-01        0.0767     -0.0062      0.0048
#> 3 1991-03-01        0.0310     -0.0130      0.0044
#> 4 1991-04-01        0.0025      0.0149      0.0053
#> 5 1991-05-01        0.0413     -0.0052      0.0047
#> 6 1991-06-01       -0.0452      0.0108      0.0042
```

### `portfolio`

`portfolio` should be a data frame with:

- one `asset` column
- one `weight` column

The package expects exactly the three supported asset names and a fully
invested long-only portfolio.

``` r

demo_portfolio_weights
#>    asset weight
#> 1 equity   0.55
#> 2   bond   0.35
#> 3   cash   0.10
```

## Overall workflow

1.  Align macro predictors and asset returns by date.
2.  Extract a small number of macro factors using principal components.
3.  Fit a VAR model to the macro factors and asset returns.
4.  Simulate future scenario paths.
5.  Aggregate simulated asset returns into portfolio-level losses.
6.  Summarize downside risk or compare VaR exceedances.

The next two sections walk through the package’s main workflows.

## Workflow 1: Estimate portfolio downside risk

We start by estimating scenario-based terminal-loss risk over a 12-month
horizon.

``` r

risk <- portfolio_risk(
  macro_data = demo_macro_data,
  return_data = demo_return_data,
  portfolio = demo_portfolio_weights,
  horizon = 12,
  n_scenarios = 200,
  k = 2,
  var_lag = 1,
  seed = 123
)

risk
#> portfolio risk
#> --------------
#> 
#> Terminal-loss risk metrics:
#> # A tibble: 1 × 5
#>   mean_loss median_loss probability_of_loss var_95 es_95
#>       <dbl>       <dbl>               <dbl>  <dbl> <dbl>
#> 1   -0.0802     -0.0740               0.195 0.0779 0.102
```

The returned object contains two main pieces:

- `risk_summary`: a one-row table of risk metrics
- `loss_distribution`: one simulated terminal loss per scenario

Printing the returned object only gives us a risk summary.

The
[`portfolio_risk()`](https://qiyuan0215.github.io/scenario2risk/reference/portfolio_risk.md)
summary contains:

- `mean_loss`: average simulated terminal loss
- `median_loss`: median simulated terminal loss
- `probability_of_loss`: share of scenarios with a positive loss
- `var_95`: 95% Value-at-Risk for terminal loss
- `es_95`: 95% Expected Shortfall

Together, these measures summarize both the center and the downside tail
of the simulated loss distribution.

We can also visualize the simulated loss distribution:

``` r

plot_portfolio_risk(risk)
```

![Portfolio risk example plot](../reference/figures/portfolio_risk.png)

In that plot, the histogram shows the simulated distribution of terminal
portfolio loss, and the vertical red line marks the estimated 95% VaR.

## Workflow 2: Check rolling VaR exceedance

Scenario-based risk estimates are more useful when they are checked
against realized outcomes. The
[`model_check()`](https://qiyuan0215.github.io/scenario2risk/reference/model_check.md)
function performs a rolling historical evaluation:

- at each forecast origin, the model is refit on the previous `window`
  months
- future portfolio losses are simulated over the chosen `horizon`
- the resulting scenario-based VaR is compared with the realized forward
  loss
- the same comparison is repeated for a historical simulation benchmark

``` r

check <- model_check(
  macro_data = demo_macro_data,
  return_data = demo_return_data,
  portfolio = demo_portfolio_weights,
  horizon = 6,
  n_scenarios = 50,
  k = 2,
  var_lag = 1,
  seed = 123,
  window = 120,
  n_origins = 6
)

check
#> rolling model check
#> -------------------
#> 
#> VaR exceedance rate:
#> # A tibble: 2 × 5
#>   model            var_95_exceedance expected_exceedance n_origins n_exceedances
#>   <chr>                        <dbl>               <dbl>     <int>         <int>
#> 1 favar_scenario                   0                0.05         6             0
#> 2 historical_simu…                 0                0.05         6             0
```

The output reports the realized exceedance frequency for:

- the FAVAR scenario model
- the historical simulation benchmark

We can visualize that comparison:

``` r

plot_model_check(check)
```

![VaR exceedance example
plot](../reference/figures/VaR%20exceedance.png)

The dashed red line marks the expected 5% exceedance rate for a 95% VaR
model.

## Notes on parameter choices

Several arguments control the behavior of the workflows:

- `horizon`: forecast horizon in months
- `n_scenarios`: number of simulated scenario paths
- `k`: number of macro factors retained
- `var_lag`: lag length of the VAR
- `window`: rolling estimation window used in
  [`model_check()`](https://qiyuan0215.github.io/scenario2risk/reference/model_check.md)
- `n_origins`: number of rolling forecast origins used in
  [`model_check()`](https://qiyuan0215.github.io/scenario2risk/reference/model_check.md)

## Limitations

The package intentionally keeps the problem simple. In particular:

- the asset universe is fixed to equity, bond, and cash
- the package is built around monthly data
- portfolio weights are long-only and fully invested
- the package is meant for clear scenario-based analysis, not full-scale
  risk infrastructure

These design choices make the package easier to explain, test, and use.
