# One-way ANOVA: does the summer mean daily maximum differ between the low
# (below 300 m) and high (above 300 m) elevation classes?

source(file.path("R", "common.R"))
check_packages("car")

d <- load_analysis_sample()

group_n <- tapply(d$tmax_summer, d$elevation_class, length)
group_mean <- tapply(d$tmax_summer, d$elevation_class, mean)
group_sd <- tapply(d$tmax_summer, d$elevation_class, sd)
normality_p <- tapply(d$tmax_summer, d$elevation_class, function(x) shapiro.test(x)$p.value)
bartlett <- bartlett.test(tmax_summer ~ elevation_class, data = d)
levene <- car::leveneTest(tmax_summer ~ elevation_class, data = d)
aov_table <- anova(lm(tmax_summer ~ elevation_class, data = d))

report <- c(
  sprintf("Stations: %d", nrow(d)),
  sprintf("  %s: n = %d, mean = %.2f °C, sd = %.2f °C, Shapiro-Wilk p = %.3f",
          names(group_n), group_n, group_mean, group_sd, normality_p),
  sprintf("Bartlett test: K^2 = %.3f, p = %.3f", bartlett$statistic, bartlett$p.value),
  sprintf("Levene test: F = %.3f, p = %.3f", levene[1, "F value"], levene[1, "Pr(>F)"]),
  sprintf("ANOVA: F(%d, %d) = %.2f, p = %.2e",
          aov_table$Df[1], aov_table$Df[2], aov_table$`F value`[1], aov_table$`Pr(>F)`[1]),
  sprintf("Difference in means (low - high): %.2f °C", group_mean["low"] - group_mean["high"])
)
write_lines(report, "anova_elevation.txt")

save_png(function() {
  op <- par(mar = c(4.5, 4.5, 2, 1))
  on.exit(par(op))
  boxplot(tmax_summer ~ elevation_class, data = d, col = c("grey85", "grey60"),
          names = c("low (< 300 m)", "high (> 300 m)"), xlab = "Elevation class",
          ylab = "Mean daily maximum, summer 2020 (°C)",
          main = "Summer maximum temperature by elevation class")
  stripchart(tmax_summer ~ elevation_class, data = d, vertical = TRUE, add = TRUE,
             method = "jitter", pch = 16, cex = 0.7)
}, "anova_elevation.png", width = 6, height = 5)

cat(report, sep = "\n")
