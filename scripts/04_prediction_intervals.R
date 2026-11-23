# Simple regressions on latitude and on longitude: 95% confidence intervals
# for the mean response and 95% prediction intervals for new stations.

source(file.path("R", "common.R"))

d <- load_analysis_sample()
lines_out <- character()

plot_intervals <- function(var, label) {
  fit <- lm(as.formula(paste("tmax_summer ~", var)), data = d)
  grid <- data.frame(seq(min(d[[var]]), max(d[[var]]), length.out = 100))
  names(grid) <- var
  ci <- predict(fit, grid, interval = "confidence", level = 0.95)
  pi <- predict(fit, grid, interval = "prediction", level = 0.95)
  x <- grid[[var]]
  matplot(x, cbind(pi[, 2:3], ci[, 2:3]), type = "l", lty = c(2, 2, 1, 1),
          col = c("steelblue", "steelblue", "darkorange", "darkorange"), lwd = 2,
          xlab = label, ylab = "Mean daily maximum, summer 2020 (°C)",
          main = paste("Regression on", tolower(label)),
          ylim = range(c(pi, d$tmax_summer)))
  lines(x, ci[, 1], lwd = 1)
  points(d[[var]], d$tmax_summer, pch = 16, cex = 0.8)
  legend("topright", c("95% confidence interval", "95% prediction interval"),
         col = c("darkorange", "steelblue"), lty = c(1, 2), lwd = 2, bty = "n", cex = 0.8)
  s <- summary(fit)
  sprintf("%s: slope = %.3f °C per degree (p = %.2e), R^2 = %.3f, mean CI width = %.2f °C, mean PI width = %.2f °C",
          label, coef(fit)[2], s$coefficients[2, 4], s$r.squared,
          mean(ci[, 3] - ci[, 2]), mean(pi[, 3] - pi[, 2]))
}

save_png(function() {
  op <- par(mfrow = c(1, 2), mar = c(4.5, 4.5, 2, 1))
  on.exit(par(op))
  lines_out <<- c(plot_intervals("latitude", "Latitude"),
                  plot_intervals("longitude", "Longitude"))
}, "prediction_intervals.png", width = 11, height = 4.5)

write_lines(lines_out, "prediction_intervals.txt")
cat(lines_out, sep = "\n")
