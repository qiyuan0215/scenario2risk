# Plot rolling VaR exceedance rates

`plot_model_check()` visualizes the VaR exceedance-rate comparison
returned by
[`model_check()`](https://qiyuan0215.github.io/scenario2risk/reference/model_check.md).
The dashed red line marks the expected exceedance rate for 95 percent
VaR.

## Usage

``` r
plot_model_check(object)
```

## Arguments

- object:

  An object returned by
  [`model_check()`](https://qiyuan0215.github.io/scenario2risk/reference/model_check.md).

## Value

A `ggplot` object comparing realized VaR exceedance rates.

## Examples

``` r
check <- model_check(
  demo_macro_data,
  demo_return_data,
  demo_portfolio_weights,
  n_scenarios = 200,
  n_origins = 24
)
plot_model_check(check)
```
