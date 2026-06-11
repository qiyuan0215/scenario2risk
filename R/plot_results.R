#' Plot simulated terminal portfolio losses
#'
#' `plot_portfolio_risk()` visualizes the terminal-loss distribution returned
#' by `portfolio_risk()`. The vertical red line marks the 95 percent VaR
#' reported in the object.
#'
#' @param object An object returned by `portfolio_risk()`.
#'
#' @returns A `ggplot` object showing simulated terminal portfolio losses.
#' @export
#'
#' @examples
#' risk <- portfolio_risk(
#'   demo_macro_data,
#'   demo_return_data,
#'   demo_portfolio_weights,
#'   n_scenarios = 500
#' )
#' plot_portfolio_risk(risk)
plot_portfolio_risk <- function(object) {
  # Plot the simulated terminal-loss distribution from portfolio_risk().
  if (!inherits(object, "portfolio_risk")) {
    stop("object must be returned by portfolio_risk().", call. = FALSE)
  }

  # Draw the same 95% VaR reported in object$risk_summary.
  var_95 <- object$risk_summary$var_95

  ggplot2::ggplot(
    object$loss_distribution,
    ggplot2::aes(x = .data$terminal_loss)
  ) +
    ggplot2::geom_histogram(
      bins = 35,
      fill = "#4c78a8",
      color = "white",
      alpha = 0.85
    ) +
    ggplot2::geom_vline(
      xintercept = var_95,
      color = "#d62728",
      linewidth = 0.9
    ) +
    ggplot2::labs(
      x = "Terminal portfolio loss",
      y = "Scenario count",
      title = "Simulated terminal portfolio loss"
    ) +
    ggplot2::theme_minimal()
}


#' Plot rolling VaR exceedance rates
#'
#' `plot_model_check()` visualizes the VaR exceedance-rate comparison returned
#' by `model_check()`. The dashed red line marks the expected exceedance rate
#' for 95 percent VaR.
#'
#' @param object An object returned by `model_check()`.
#'
#' @returns A `ggplot` object comparing realized VaR exceedance rates.
#' @export
#'
#' @examples
#' check <- model_check(
#'   demo_macro_data,
#'   demo_return_data,
#'   demo_portfolio_weights,
#'   n_scenarios = 200,
#'   n_origins = 24,
#'   use_parallel = FALSE
#' )
#' plot_model_check(check)
plot_model_check <- function(object) {
  # Plot VaR exceedance rates from model_check().
  if (!inherits(object, "model_check")) {
    stop("object must be returned by model_check().", call. = FALSE)
  }

  # The dashed line is the target exceedance rate for 95% VaR.
  expected_exceedance <- object$var_exceedance$expected_exceedance[1]

  ggplot2::ggplot(
    object$var_exceedance,
    ggplot2::aes(x = reorder(.data$model, .data$var_95_exceedance),
                 y = .data$var_95_exceedance)
  ) +
    ggplot2::geom_col(fill = "#54a24b", width = 0.7) +
    ggplot2::geom_hline(
      yintercept = expected_exceedance,
      color = "#d62728",
      linewidth = 0.8,
      linetype = "dashed"
    ) +
    ggplot2::coord_flip() +
    ggplot2::scale_y_continuous(
      labels = function(x) paste0(round(100 * x), "%")
    ) +
    ggplot2::labs(
      x = NULL,
      y = "VaR exceedance rate",
      title = "Rolling h-period VaR exceedance"
    ) +
    ggplot2::theme_minimal()
}
