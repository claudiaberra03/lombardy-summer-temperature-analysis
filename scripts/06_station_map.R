# Station locations coloured by the two-group cluster label stored in the
# dataset, and by the residual of the final model. Plain longitude-latitude
# axes are used, so no map service or API key is required.

source(file.path("R", "common.R"))

d_all <- load_stations()
infl <- influential_stations(d_all)
d <- d_all[!infl$influential, ]
final <- lm(FINAL_FORMULA, data = d)

save_png(function() {
  op <- par(mfrow = c(1, 2), mar = c(4.5, 4.5, 2, 1))
  on.exit(par(op))

  cols <- c("0" = "steelblue", "1" = "darkorange")
  plot(d_all$longitude, d_all$latitude, pch = 16, cex = 1.4,
       col = cols[as.character(d_all$cluster)], asp = 1 / cos(45.7 * pi / 180),
       xlab = "Longitude (°E)", ylab = "Latitude (°N)", main = "Cluster label")
  points(d_all$longitude[infl$influential], d_all$latitude[infl$influential],
         pch = 4, cex = 1.6, lwd = 2)
  legend("bottomright", c("cluster 0", "cluster 1", "removed (Cook's distance)"),
         pch = c(16, 16, 4), col = c(cols, "black"), bty = "n", cex = 0.8)

  r <- residuals(final)
  plot(d$longitude, d$latitude, pch = 21, cex = 0.8 + 2 * abs(r) / max(abs(r)),
       bg = ifelse(r > 0, "firebrick", "steelblue"), asp = 1 / cos(45.7 * pi / 180),
       xlab = "Longitude (°E)", ylab = "Latitude (°N)", main = "Residuals of the final model")
  legend("bottomright", c("observed > fitted", "observed < fitted"), pch = 21,
         pt.bg = c("firebrick", "steelblue"), bty = "n", cex = 0.8)
}, "station_map.png", width = 11, height = 5)

cat("Saved figures/station_map.png\n")
