# Multiple linear regression for the summer mean daily maximum temperature:
# initial model, influence analysis, backward elimination, final model and
# diagnostics.

source(file.path("R", "common.R"))
check_packages("car")

d <- load_stations()

# 1. Initial model on all 37 stations ------------------------------------------
full_all <- lm(FULL_FORMULA, data = d)

# 2. Influential stations (Cook's distance on the initial model) ---------------
infl <- influential_stations(d)
write.csv(transform(infl, cooks_distance = round(cooks_distance, 4),
                    threshold = round(threshold, 4)),
          file.path(RESULTS_DIR, "cooks_distance.csv"), row.names = FALSE)

save_png(function() {
  op <- par(mar = c(4.5, 4.5, 2, 1))
  on.exit(par(op))
  plot(fitted(full_all), infl$cooks_distance, pch = 16,
       col = ifelse(infl$influential, "darkorange", "grey30"),
       xlab = "Fitted values (°C)", ylab = "Cook's distance",
       main = "Influence of each station on the initial model")
  abline(h = infl$threshold[1], lty = 2)
  with(infl[infl$influential, ],
       text(fitted(full_all)[infl$influential], cooks_distance, station, pos = 2, cex = 0.8))
}, "cooks_distance.png")

d2 <- d[!infl$influential, ]

# 3. Backward elimination on the remaining stations (partial F-tests) ---------
fit <- lm(FULL_FORMULA, data = d2)
log <- character()
repeat {
  tests <- drop1(fit, test = "F")[-1, ]
  p <- setNames(tests[, "Pr(>F)"], rownames(tests))
  log <- c(log, paste0("Candidates: ",
                       paste(sprintf("%s (p = %.3f)", names(p), p), collapse = ", ")))
  if (max(p) < 0.05) break
  drop <- names(which.max(p))
  log <- c(log, paste0("  removed: ", drop))
  fit <- update(fit, as.formula(paste(". ~ . -", drop)))
}
log <- c(log, paste("Selected model:", deparse(formula(fit), width.cutoff = 200)))
write_lines(log, "backward_elimination.txt")

# 4. Final model -----------------------------------------------------------------
final <- lm(FINAL_FORMULA, data = d2)
stopifnot(setequal(attr(terms(final), "term.labels"), attr(terms(fit), "term.labels")))

s_full <- summary(full_all)
s <- summary(final)
coefs <- as.data.frame(s$coefficients)
coefs$term <- rownames(coefs)
names(coefs) <- c("estimate", "std_error", "t_value", "p_value", "term")
coefs <- coefs[, c("term", "estimate", "std_error", "t_value", "p_value")]
write.csv(transform(coefs, estimate = signif(estimate, 5), std_error = signif(std_error, 4),
                    t_value = round(t_value, 3), p_value = signif(p_value, 3)),
          file.path(RESULTS_DIR, "final_model_coefficients.csv"), row.names = FALSE)

vifs <- car::vif(final)
shapiro <- shapiro.test(residuals(final))
fstat <- s$fstatistic

report <- c(
  "Initial model (37 stations)",
  sprintf("  R^2 = %.3f, adjusted R^2 = %.3f", s_full$r.squared, s_full$adj.r.squared),
  sprintf("Influential stations removed (Cook's distance > %.3f): %s",
          infl$threshold[1], paste(infl$station[infl$influential], collapse = ", ")),
  "",
  sprintf("Final model: %s", deparse(FINAL_FORMULA, width.cutoff = 200)),
  sprintf("  stations = %d, residual df = %d", nrow(d2), final$df.residual),
  sprintf("  R^2 = %.3f, adjusted R^2 = %.3f", s$r.squared, s$adj.r.squared),
  sprintf("  residual standard error = %.3f °C", s$sigma),
  sprintf("  F = %.2f on %d and %d df, p = %.2e", fstat[1], fstat[2], fstat[3],
          pf(fstat[1], fstat[2], fstat[3], lower.tail = FALSE)),
  sprintf("  max VIF = %.2f", max(vifs)),
  sprintf("  Shapiro-Wilk on residuals: W = %.3f, p = %.3f", shapiro$statistic, shapiro$p.value),
  "",
  "Coefficients:",
  capture.output(print(signif(s$coefficients, 4)))
)
write_lines(report, "final_model_summary.txt")

# 5. Diagnostics -------------------------------------------------------------------
save_png(function() {
  op <- par(mfrow = c(1, 2), mar = c(4.5, 4.5, 2, 1))
  on.exit(par(op))
  plot(fitted(final), residuals(final), pch = 16, xlab = "Fitted values (°C)",
       ylab = "Residuals (°C)", main = "Residuals against fitted values")
  abline(h = 0, lty = 2)
  qqnorm(residuals(final), pch = 16, main = "Normal Q-Q plot of residuals")
  qqline(residuals(final), lty = 2)
}, "final_model_diagnostics.png", width = 10, height = 4.5)

cat(report, sep = "\n")
