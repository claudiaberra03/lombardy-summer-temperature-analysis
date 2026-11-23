# Data

The analysis uses `station_summaries_summer2020.csv`, with one row per weather station (37 stations, UTF-8, comma-separated).

## Provenance

The underlying daily minimum and maximum temperatures and daily precipitation for 2020 were obtained from ARPA Lombardia, the regional environmental protection agency of Lombardy, which operates the regional weather monitoring network. The group computed the summer summaries for each station (mean daily minimum, maximum and mean temperature, mean daily range and mean daily precipitation), added the station coordinates and altitude, and defined the two categorical variables and the cluster label. The daily records and the aggregation step are not included in this repository.

## Availability

The station file is not distributed in this repository, because the terms for redistributing ARPA Lombardia measurements, and data derived from them, have not been confirmed. The tables in `results/` and the figures in `figures/` were generated from it. To rerun the analysis, place `station_summaries_summer2020.csv` with the columns below in this folder. The underlying daily measurements can be requested from ARPA Lombardia.

## Columns

| Column | Unit | Notes |
| --- | --- | --- |
| `station` | – | Station name (municipality) |
| `latitude`, `longitude` | decimal degrees | WGS84 |
| `altitude_m` | m | |
| `tmin_summer`, `tmax_summer`, `tmean_summer` | °C | Means over summer 2020 of the daily values |
| `trange_summer` | °C | Mean daily range (maximum − minimum) |
| `precip_summer` | mm | Mean daily precipitation over summer 2020 |
| `lake_label_original` | – | Lake variable as coded in the original spreadsheet (see below) |
| `elevation_class` | – | `low` (104–296 m) or `high` (309–535 m) |
| `cluster` | – | Two-group cluster label (0/1) based on the stations' daily maximum temperatures |

## Coding note: lake proximity

In the original spreadsheet the lake variable takes the values `Vicino` (near) and `Lontano` (far). The 12 stations coded `Lontano` are the lakeside ones (Abbadia Lariana, Como, Lavena Ponte Tresa, Laveno Mombello, Luino, Porlezza, Porto Ceresio, Ranzanico, Sarnico, Tavernola Bergamasca, Tremezzo, Varano Borghi), so the labels were inverted. The column is kept unchanged, and `R/common.R` derives the variable `lakeside` from it explicitly. Because the variable is binary, this only changes the sign of its coefficient: its p-values and the selected model are unaffected.
