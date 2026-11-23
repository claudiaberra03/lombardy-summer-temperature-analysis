# Descriptive statistics and pairwise relationships for the 37 stations.

source(file.path("R", "common.R"))

d <- load_stations()
num_vars <- c("latitude", "longitude", "altitude_m", "tmin_summer", "tmax_summer",
              "tmean_summer", "trange_summer", "precip_summer")

summary_table <- data.frame(
  variable = num_vars,
  min = sapply(d[num_vars], min),
  median = sapply(d[num_vars], median),
  mean = sapply(d[num_vars], mean),
  max = sapply(d[num_vars], max),
  row.names = NULL
)
write.csv(transform(summary_table, min = round(min, 3), median = round(median, 3),
                    mean = round(mean, 3), max = round(max, 3)),
          file.path(RESULTS_DIR, "descriptive_statistics.csv"), row.names = FALSE)

counts <- c(
  sprintf("Stations: %d", nrow(d)),
  sprintf("Elevation class: low %d, high %d",
          sum(d$elevation_class == "low"), sum(d$elevation_class == "high")),
  sprintf("Lakeside: no %d, yes %d", sum(d$lakeside == "no"), sum(d$lakeside == "yes"))
)
write_lines(counts, "group_counts.txt")

corr <- cor(d[num_vars])
write.csv(round(corr, 3), file.path(RESULTS_DIR, "correlation_matrix.csv"))

save_png(function() {
  op <- par(mar = c(7, 7, 2, 2))
  on.exit(par(op))
  n <- length(num_vars)
  image(1:n, 1:n, corr[, n:1], zlim = c(-1, 1), axes = FALSE, xlab = "", ylab = "",
        col = hcl.colors(41, "Blue-Red 3", rev = TRUE))
  axis(1, 1:n, num_vars, las = 2, cex.axis = 0.8)
  axis(2, 1:n, rev(num_vars), las = 2, cex.axis = 0.8)
  for (i in 1:n) for (j in 1:n) text(i, n + 1 - j, sprintf("%.2f", corr[i, j]), cex = 0.7)
  title("Pearson correlation between station variables")
}, "correlation_matrix.png", width = 7, height = 6.5)

save_png(function() {
  op <- par(mfrow = c(1, 3), mar = c(4.5, 4.5, 2, 1))
  on.exit(par(op))
  for (v in c("latitude", "longitude", "altitude_m")) {
    plot(d[[v]], d$tmax_summer, pch = 16, xlab = v,
         ylab = "Mean daily maximum, summer 2020 (°C)")
  }
}, "tmax_vs_location.png", width = 10, height = 3.8)

cat(counts, sep = "\n")
