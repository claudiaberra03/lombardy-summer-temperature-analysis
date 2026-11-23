# Out-of-sample error of the final model: leave-one-out and repeated 5-fold
# cross-validation on the stations retained after the influence analysis.
# Model selection was carried out on the same stations, so these estimates
# are optimistic (see README, Limitations).

source(file.path("R", "common.R"))

d <- load_analysis_sample()
y <- d$tmax_summer
n <- nrow(d)
tss <- sum((y - mean(y))^2)

cv_metrics <- function(pred) c(mse = mean((y - pred)^2), r2_cv = 1 - sum((y - pred)^2) / tss)

loo_pred <- vapply(seq_len(n), function(i)
  predict(lm(FINAL_FORMULA, data = d[-i, ]), d[i, ]), numeric(1))
loo <- cv_metrics(loo_pred)

set.seed(2025)
k <- 5
repeats <- 100
kfold <- t(replicate(repeats, {
  folds <- sample(rep(seq_len(k), length.out = n))
  pred <- numeric(n)
  for (f in seq_len(k)) {
    pred[folds == f] <- predict(lm(FINAL_FORMULA, data = d[folds != f, ]), d[folds == f, ])
  }
  cv_metrics(pred)
}))

report <- c(
  sprintf("Stations: %d", n),
  sprintf("Leave-one-out: MSE = %.3f °C^2 (RMSE = %.2f °C), R^2_cv = %.3f",
          loo["mse"], sqrt(loo["mse"]), loo["r2_cv"]),
  sprintf("%d-fold, %d repetitions (seed 2025): MSE = %.3f ± %.3f °C^2, R^2_cv = %.3f ± %.3f (mean ± sd)",
          k, repeats, mean(kfold[, "mse"]), sd(kfold[, "mse"]),
          mean(kfold[, "r2_cv"]), sd(kfold[, "r2_cv"]))
)
write_lines(report, "cross_validation.txt")
cat(report, sep = "\n")
