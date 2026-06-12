# scenario2risk: Macro-financial scenario portfolio risk analysis

`scenario2risk` provides tools for scenario-based portfolio risk
analysis using monthly macro-financial predictors and a factor-augmented
VAR model. The package is designed for a simple three-asset setting with
equity, bond, and cash returns.

## Details

The main user-facing functions are:

- [`portfolio_risk()`](https://qiyuan0215.github.io/scenario2risk/reference/portfolio_risk.md)
  to estimate terminal-loss risk metrics such as VaR and expected
  shortfall

- [`model_check()`](https://qiyuan0215.github.io/scenario2risk/reference/model_check.md)
  to compare rolling VaR exceedance rates for the FAVAR scenario model
  and a historical simulation benchmark

- [`plot_portfolio_risk()`](https://qiyuan0215.github.io/scenario2risk/reference/plot_portfolio_risk.md)
  to visualize the simulated terminal-loss distribution

- [`plot_model_check()`](https://qiyuan0215.github.io/scenario2risk/reference/plot_model_check.md)
  to visualize rolling VaR exceedance diagnostics

The package also includes built-in example datasets:

- [demo_macro_data](https://qiyuan0215.github.io/scenario2risk/reference/demo_macro_data.md)

- [demo_return_data](https://qiyuan0215.github.io/scenario2risk/reference/demo_return_data.md)

- [demo_portfolio_weights](https://qiyuan0215.github.io/scenario2risk/reference/demo_portfolio_weights.md)

## See also

Useful links:

- <https://qiyuan0215.github.io/scenario2risk/>

## Author

**Maintainer**: Qiyuan Li <qiyuan.li@hotmail.com>
