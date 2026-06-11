# user function: S3 print methods.


#' @method print portfolio_risk
#' @export
print.portfolio_risk <- function(x, ...) {
  cat("portfolio risk\n")
  cat("--------------\n")
  cat("\nTerminal-loss risk metrics:\n")
  print(x$risk_summary)
  cat("\nWhat to inspect:\n")
  cat("- x$loss_distribution: one terminal loss per simulated scenario\n")
  invisible(x)
}

#' @method print model_check
#' @export
print.model_check <- function(x, ...) {
  cat("rolling model check\n")
  cat("-------------------\n")
  cat("\nVaR exceedance rate:\n")
  print(x$var_exceedance)
  cat("\nWhat to inspect:\n")
  cat("- x$forecasts: one h-period realized loss and VaR pair per origin\n")
  invisible(x)
}
