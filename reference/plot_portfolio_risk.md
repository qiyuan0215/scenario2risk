# Plot simulated terminal portfolio losses

`plot_portfolio_risk()` visualizes the terminal-loss distribution
returned by
[`portfolio_risk()`](https://qiyuan0215.github.io/scenario2risk/reference/portfolio_risk.md).
The vertical red line marks the 95 percent VaR reported in the object.

## Usage

``` r
plot_portfolio_risk(object)
```

## Arguments

- object:

  An object returned by
  [`portfolio_risk()`](https://qiyuan0215.github.io/scenario2risk/reference/portfolio_risk.md).

## Value

A `ggplot` object showing simulated terminal portfolio losses.

## Examples

``` r
risk <- portfolio_risk(
  demo_macro_data,
  demo_return_data,
  demo_portfolio_weights,
  n_scenarios = 500
)
plot_portfolio_risk(risk)
```
