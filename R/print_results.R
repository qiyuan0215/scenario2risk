# S3 print methods.


print.portfolio_risk <- function(x, ...) {
  cat("portfolio risk\n")
  cat("--------------\n")
  cat("\nTerminal-loss risk metrics:\n")
  print(x$risk_summary)
  invisible(x)
}



print.model_check <- function(x, ...) {
  cat("rolling model check\n")
  cat("-------------------\n")
  cat("\nVaR exceedance rate:\n")
  print(x$var_exceedance)
  invisible(x)
}
