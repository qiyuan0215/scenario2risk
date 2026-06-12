test_that("portfolio_risk returns a structured risk object", {
  risk <- portfolio_risk(
    macro_data = demo_macro_data,
    return_data = demo_return_data,
    portfolio = demo_portfolio_weights,
    horizon = 6,
    n_scenarios = 10,
    k = 2,
    var_lag = 1,
    seed = 123
  )

  expect_s3_class(risk, "portfolio_risk")
  expect_named(risk, c("risk_summary", "loss_distribution"))

  expect_equal(dim(risk$risk_summary), c(1, 5))
  expect_named(
    risk$risk_summary,
    c("mean_loss", "median_loss", "probability_of_loss", "var_95", "es_95")
  )
  expect_true(all(is.finite(unlist(risk$risk_summary))))
  expect_true(risk$risk_summary$es_95 >= risk$risk_summary$var_95)

  expect_equal(nrow(risk$loss_distribution), 10)
  expect_true(all(risk$loss_distribution$n_months == 6))
})

test_that("portfolio_risk is reproducible for a fixed seed", {
  risk_1 <- portfolio_risk(
    macro_data = demo_macro_data,
    return_data = demo_return_data,
    portfolio = demo_portfolio_weights,
    horizon = 6,
    n_scenarios = 10,
    k = 2,
    var_lag = 1,
    seed = 123
  )

  risk_2 <- portfolio_risk(
    macro_data = demo_macro_data,
    return_data = demo_return_data,
    portfolio = demo_portfolio_weights,
    horizon = 6,
    n_scenarios = 10,
    k = 2,
    var_lag = 1,
    seed = 123
  )

  expect_equal(risk_1$risk_summary, risk_2$risk_summary)
  expect_equal(risk_1$loss_distribution, risk_2$loss_distribution)
})
