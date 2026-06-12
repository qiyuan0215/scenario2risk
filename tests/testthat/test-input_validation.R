test_that("portfolio_risk errors if a required return column is missing", {
  bad_return_data <- demo_return_data[, c("date", "equity_return", "bond_return")]

  expect_error(
    portfolio_risk(
      macro_data = demo_macro_data,
      return_data = bad_return_data,
      portfolio = demo_portfolio_weights
    ),
    "missing required columns"
  )
})

test_that("portfolio_risk errors if portfolio weights do not sum to 1", {
  bad_portfolio <- demo_portfolio_weights
  bad_portfolio$weight <- c(0.5, 0.4, 0.4)

  expect_error(
    portfolio_risk(
      macro_data = demo_macro_data,
      return_data = demo_return_data,
      portfolio = bad_portfolio
    ),
    "weights must sum to 1"
  )
})

test_that("portfolio_risk errors if a required asset row is missing", {
  bad_portfolio <- demo_portfolio_weights[demo_portfolio_weights$asset != "cash", ]

  expect_error(
    portfolio_risk(
      macro_data = demo_macro_data,
      return_data = demo_return_data,
      portfolio = bad_portfolio
    ),
    "missing required asset rows"
  )
})

test_that("portfolio_risk errors if macro_data has no predictor columns", {
  bad_macro_data <- demo_macro_data["date"]

  expect_error(
    portfolio_risk(
      macro_data = bad_macro_data,
      return_data = demo_return_data,
      portfolio = demo_portfolio_weights
    ),
    "must contain at least one predictor column"
  )
})

test_that("portfolio_risk errors if return_data dates are duplicated", {
  bad_return_data <- rbind(demo_return_data, demo_return_data[1, ])

  expect_error(
    portfolio_risk(
      macro_data = demo_macro_data,
      return_data = bad_return_data,
      portfolio = demo_portfolio_weights
    ),
    "return_data\\$date must be unique"
  )
})

test_that("portfolio_risk errors if var_lag is not positive", {
  expect_error(
    portfolio_risk(
      macro_data = demo_macro_data,
      return_data = demo_return_data,
      portfolio = demo_portfolio_weights,
      var_lag = 0
    ),
    "var_lag must be a positive integer"
  )
})

test_that("model_check errors if window is not larger than horizon", {
  expect_error(
    model_check(
      macro_data = demo_macro_data,
      return_data = demo_return_data,
      portfolio = demo_portfolio_weights,
      horizon = 12,
      window = 12
    ),
    "window must be larger than horizon"
  )
})

test_that("model_check errors if the rolling window is too long", {
  expect_error(
    model_check(
      macro_data = demo_macro_data,
      return_data = demo_return_data,
      portfolio = demo_portfolio_weights,
      horizon = 12,
      window = 1000
    ),
    "Not enough observations"
  )
})
