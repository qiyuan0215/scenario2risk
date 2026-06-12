test_that("model_check returns two exceedance summaries", {
  check <- model_check(
    macro_data = demo_macro_data,
    return_data = demo_return_data,
    portfolio = demo_portfolio_weights,
    horizon = 6,
    n_scenarios = 20,
    k = 2,
    var_lag = 1,
    seed = 123,
    window = 120,
    n_origins = 3
  )

  expect_s3_class(check, "model_check")
  expect_named(check, "var_exceedance")
  expect_equal(nrow(check$var_exceedance), 2)
  expect_named(
    check$var_exceedance,
    c("model", "var_95_exceedance", "expected_exceedance",
      "n_origins", "n_exceedances")
  )

  expect_equal(
    check$var_exceedance$model,
    c("favar_scenario", "historical_simulation")
  )
  expect_true(all(check$var_exceedance$var_95_exceedance >= 0))
  expect_true(all(check$var_exceedance$var_95_exceedance <= 1))
  expect_true(
    all(check$var_exceedance$n_exceedances <= check$var_exceedance$n_origins)
  )
})

test_that("model_check is reproducible for a fixed seed", {
  check_1 <- model_check(
    macro_data = demo_macro_data,
    return_data = demo_return_data,
    portfolio = demo_portfolio_weights,
    horizon = 6,
    n_scenarios = 20,
    k = 2,
    var_lag = 1,
    seed = 123,
    window = 120,
    n_origins = 3
  )

  check_2 <- model_check(
    macro_data = demo_macro_data,
    return_data = demo_return_data,
    portfolio = demo_portfolio_weights,
    horizon = 6,
    n_scenarios = 20,
    k = 2,
    var_lag = 1,
    seed = 123,
    window = 120,
    n_origins = 3
  )

  expect_equal(check_1$var_exceedance, check_2$var_exceedance)
})
