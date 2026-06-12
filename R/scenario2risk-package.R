#' scenario2risk: Macro-financial scenario portfolio risk analysis
#'
#' `scenario2risk` provides tools for scenario-based portfolio risk analysis
#' using monthly macro-financial predictors and a factor-augmented VAR model.
#' The package is designed for a simple three-asset setting with equity, bond,
#' and cash returns.
#'
#' The main user-facing functions are:
#'
#' - [portfolio_risk()] to estimate terminal-loss risk metrics such as VaR and
#'   expected shortfall
#' - [model_check()] to compare rolling VaR exceedance rates for the FAVAR
#'   scenario model and a historical simulation benchmark
#' - [plot_portfolio_risk()] to visualize the simulated terminal-loss
#'   distribution
#' - [plot_model_check()] to visualize rolling VaR exceedance diagnostics
#'
#' The package also includes built-in example datasets:
#'
#' - [demo_macro_data]
#' - [demo_return_data]
#' - [demo_portfolio_weights]
#'
#' @name scenario2risk
#' @docType package
#' @useDynLib scenario2risk, .registration = TRUE
#' @importFrom rlang .data
#' @importFrom Rcpp sourceCpp
"_PACKAGE"
