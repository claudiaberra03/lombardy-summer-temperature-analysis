# Shared helpers: paths, data loading and model definitions.

# All scripts are run from the repository root.
if (!file.exists(file.path("R", "common.R"))) {
  stop("Run the scripts from the repository root.", call. = FALSE)
}
ROOT <- normalizePath(".")
DATA_FILE <- file.path(ROOT, "data", "station_summaries_summer2020.csv")
RESULTS_DIR <- file.path(ROOT, "results")
FIGURES_DIR <- file.path(ROOT, "figures")
dir.create(RESULTS_DIR, showWarnings = FALSE)
dir.create(FIGURES_DIR, showWarnings = FALSE)

check_packages <- function(pkgs) {
  missing <- pkgs[!vapply(pkgs, requireNamespace, logical(1), quietly = TRUE)]
  if (length(missing) > 0) {
    stop("Missing packages: ", paste(missing, collapse = ", "),
         ". Install them with install.packages().", call. = FALSE)
  }
  invisible(lapply(pkgs, function(p) suppressPackageStartupMessages(library(p, character.only = TRUE))))
}

# Loads the 37 station-level summaries.
# The original spreadsheet coded the lake variable as "Vicino" (near) and
# "Lontano" (far), but the stations coded "Lontano" are the lakeside ones
# (Como, Tremezzo, Luino, Laveno Mombello, ...). The variable is therefore
# recoded explicitly as `lakeside`. Because it is binary, the recoding only
# changes the sign of its coefficient, not its significance.
load_stations <- function() {
  if (!file.exists(DATA_FILE)) {
    stop("Data file not found: ", DATA_FILE, ". See data/README.md.", call. = FALSE)
  }
  d <- read.csv(DATA_FILE, fileEncoding = "UTF-8", stringsAsFactors = FALSE)
  d$lakeside <- factor(ifelse(d$lake_label_original == "Lontano", "yes", "no"),
                       levels = c("no", "yes"))
  d$elevation_class <- factor(d$elevation_class, levels = c("low", "high"))
  d$cluster <- factor(d$cluster)
  d
}

# Initial model: elevation class, coordinates, their interactions,
# precipitation and lake proximity.
FULL_FORMULA <- tmax_summer ~ elevation_class * latitude + elevation_class * longitude +
  precip_summer + lakeside

# Model retained after influence analysis and backward elimination.
FINAL_FORMULA <- tmax_summer ~ elevation_class + latitude + longitude

# Cook's distance rule of thumb used in the course: D_i > 4 / (n - p).
influential_stations <- function(d) {
  fit <- lm(FULL_FORMULA, data = d)
  cd <- cooks.distance(fit)
  threshold <- 4 / (nrow(d) - fit$rank)
  data.frame(station = d$station, cooks_distance = cd,
             influential = cd > threshold, threshold = threshold)
}

load_analysis_sample <- function() {
  d <- load_stations()
  infl <- influential_stations(d)
  d[!infl$influential, ]
}

write_lines <- function(x, file) {
  writeLines(x, file.path(RESULTS_DIR, file))
}

save_png <- function(plot_fun, file, width = 7, height = 5) {
  png(file.path(FIGURES_DIR, file), width = width, height = height,
      units = "in", res = 150)
  on.exit(dev.off())
  plot_fun()
}
