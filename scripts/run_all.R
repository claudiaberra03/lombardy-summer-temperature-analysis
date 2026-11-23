# Runs the complete analysis from the repository root:
#   Rscript scripts/run_all.R

scripts <- c("01_exploration.R", "02_regression.R", "03_anova_elevation.R",
             "04_prediction_intervals.R", "05_cross_validation.R", "06_station_map.R")

for (s in scripts) {
  cat("\n==>", s, "\n")
  source(file.path("scripts", s), local = new.env())
}
cat("\nResults written to results/ and figures/.\n")
