# scripts/extract_regional_focus.R
# Extracts the exact data series for Graphiques 9, 10, and 11
# from the official STATEC publication PDF vectors and tables.

library(dplyr)
library(tidyr)

# -------------------------------------------------------------
# 1. Graphique 9: Loyers annoncés et chambres meublées (2010-2025)
# -------------------------------------------------------------
# Base 100 = 2010
annees_g9 <- 2010:2025
scale_g9 <- 16.74 / 10 # 1.674 PDF units per 1 index point

# Vector dy values from PDF object 238
c1_dy <- c(0, 11.16, 9.36, 22.2, 35.4, 42.84, 51.84, 55.2, 77.4, 79.32, 84.48, 90.24, 99.48, 116.52, 125.4, 138.94)
c2_dy <- c(0, 11.28, 1.92, 14.88, 18, 27.36, 33.6, 41.4, 42.96, 52.56, 65.04, 71.04, 72.48, 86.04, 102.48, 128.76)
c3_dy <- c(0, 10.56, 12.36, 25.68, 39.48, 54.48, 63.96, 65.64, 89.16, 99.24, 107.04, 115.8, 128.04, 150, 162.6, 171.72)

df_g9 <- data.frame(
  annee = annees_g9,
  loyer_appartements_idx = round(100 + c1_dy / scale_g9, 1),
  loyer_maisons_idx = round(100 + c2_dy / scale_g9, 1),
  loyer_chambres_meublees_idx = round(100 + c3_dy / scale_g9, 1)
)

write.csv(df_g9, "data/loyers_chambres_meublees_annuel.csv", row.names = FALSE)
cat("Saved data/loyers_chambres_meublees_annuel.csv\n")

# -------------------------------------------------------------
# Quarters definition for G10 & G11 (2015 Q1 to 2026 Q2 = 46 quarters)
# -------------------------------------------------------------
quarters <- expand.grid(trimestre = paste0("Q", 1:4), annee = 2015:2026, stringsAsFactors = FALSE) %>%
  arrange(annee, trimestre) %>%
  filter(!(annee == 2026 & trimestre %in% c("Q3", "Q4"))) %>%
  mutate(
    periode = paste0(annee, " ", trimestre),
    trim_num = as.integer(substr(trimestre, 2, 2)),
    month = sprintf("%02d", (trim_num - 1) * 3 + 1),
    date = paste0(annee, "-", month, "-01")
  )

# -------------------------------------------------------------
# 2. Graphique 10: Appartements existants (Régional vs Reste du pays)
# -------------------------------------------------------------
scale_idx_g10 <- 22.71744 / 50 # 0.4543488 units per index point
scale_tx_g10 <- 11.35872 / 100 # 0.1135872 units per transaction

# Heights of bars for Reste du pays transactions (in PDF x-order)
# Rectangles: 64.757 358.824 2.28 -53.4 re ...
g10_tx_reste_h <- c(
  53.4, 61.56, 61.08, 64.32, 61.56, 65.88, 66.12, 65.52, 68.28, 73.8,
  73.8, 74.52, 71.28, 68.04, 68.28, 88.92, 57.36, 68.52, 69, 71.52,
  60.12, 54.72, 70.8, 83.88, 72.84, 73.44, 75, 67.08, 68.04, 68.16,
  66.48, 57.24, 41.76, 39.6, 42.84, 41.04, 47.16, 56.76, 61.92, 80.88,
  57.24, 96.72, 64.08, 63.24, 62.76, 19.68
)

# Heights of bars for Luxembourg transactions
# Rectangles: 67.157 323.664 2.28 -18.24 re ...
g10_tx_lux_h <- c(
  18.24, 19.8, 23.52, 19.68, 23.76, 21.36, 22.92, 26.04, 21.84, 26.64,
  26.16, 32.88, 22.2, 23.76, 22.68, 37.2, 18.36, 20.64, 24, 25.2,
  18.6, 14.88, 21.84, 26.52, 24.48, 29.4, 25.68, 25.68, 27, 25.8,
  23.4, 19.68, 14.16, 20.04, 18.36, 15, 21.84, 21.48, 26.76, 35.52,
  20.28, 41.64, 25.92, 23.04, 22.8, 27.24
)

# Line dy for Reste du pays price index
g10_idx_reste_dy <- c(
  0, 0.36, 1.44, 1.44, 2.52, 3.12, 3.36, 4.2, 5.16, 6.36,
  6.24, 2.52, 7.56, 7.92, 10.08, 11.04, 11.4, 13.68, 15.36, 17.76,
  20.88, 23.16, 26.52, 28.08, 32.28, 34.92, 37.44, 39.24, 40.92, 43.32,
  45.96, 44.04, 42, 39.48, 34.32, 31.08, 31.32, 30.96, 30.36, 31.44,
  32.28, 33.48, 31.56, 32.16, 32.28, 33.48
)

# Line dy for Luxembourg price index
g10_idx_lux_dy <- c(
  0, 2.16, 0.12, 2.88, 4.92, 3, 7.2, 6.96, 6.96, 8.64,
  8.16, 5.04, 11.52, 15.24, 14.52, 16.92, 17.52, 21.96, 23.88, 25.68,
  27.6, 30.84, 34.08, 35.52, 34.44, 38.76, 39, 41.64, 42, 43.44,
  42.36, 42.24, 38.64, 36.36, 31.56, 30.6, 28.68, 31.32, 30.84, 31.56,
  28.56, 33.12, 31.92, 33.12, 31.8, 32.16
)

df_g10 <- quarters %>%
  mutate(
    transactions_reste_pays = round(g10_tx_reste_h / scale_tx_g10),
    transactions_luxembourg = round(g10_tx_lux_h / scale_tx_g10),
    indice_prix_reste_pays = round(100 + g10_idx_reste_dy / scale_idx_g10, 1),
    indice_prix_luxembourg = round(100 + g10_idx_lux_dy / scale_idx_g10, 1)
  )

write.csv(df_g10, "data/focus_regional_appartements_existants.csv", row.names = FALSE)
cat("Saved data/focus_regional_appartements_existants.csv\n")

# -------------------------------------------------------------
# 3. Graphique 11: Appartements VEFA (Régional vs Reste du pays)
# -------------------------------------------------------------
scale_idx_g11 <- 29.25984 / 50 # 0.5851968 units per index point
scale_tx_g11 <- 14.62992 / 100 # 0.1462992 units per transaction

# Heights of bars for Reste du pays transactions
g11_tx_reste_h <- c(
  39, 44.16, 45.72, 42.24, 38.88, 42, 31.44, 46.44, 36.96, 44.04,
  32.88, 51.36, 45.12, 53.64, 41.76, 52.08, 48.72, 55.32, 45.6, 60.96,
  47.76, 38.64, 44.76, 73.08, 39.12, 31.08, 34.92, 44.28, 48.96, 39.72,
  23.28, 27.96, 10.08, 6.12, 5.52, 4.92, 4.8, 7.08, 8.88, 23.4,
  10.56, 16.56, 16.56, 7.92, 13.08, 12.84
)

# Heights of bars for Luxembourg transactions
g11_tx_lux_h <- c(
  17.04, 14.04, 15.96, 38.16, 20.28, 19.56, 30, 42, 25.56, 36,
  21.24, 36, 20.4, 26.04, 18.36, 12.96, 28.8, 23.52, 30, 17.76,
  18, 28.32, 20.16, 30.84, 16.92, 8.76, 5.52, 13.44, 9.96, 9.96,
  6, 5.64, 1.92, 9.36, 2.88, 1.32, 3.36, 4.32, 3.96, 14.88,
  10.08, 11.4, 13.08, 3, 5.04, 6.84
)

# Line dy for Reste du pays price index
g11_idx_reste_dy <- c(
  0, 2.16, 4.92, 5.04, 2.88, 5.28, 6, 6.48, 8.88, 6.24,
  8.76, 4.08, 11.04, 8.64, 11.88, 12.72, 15.24, 16.92, 17.64, 20.64,
  27.24, 26.16, 25.08, 31.92, 35.64, 36.84, 36, 42.12, 43.8, 45.96,
  50.04, 48.6, 43.44, 43.8, 37.56, 46.32, 43.44, 41.64, 41.04, 43.92,
  41.64, 46.56, 48.72, 48.84, 40.92, 43.44
)

# Line dy for Luxembourg price index
g11_idx_lux_dy <- c(
  0, 2.52, 2.52, 2.04, 6.48, 9.36, 6.24, 8.16, 7.8, 13.56,
  11.88, 7.44, 18.72, 20.52, 19.44, 17.28, 12.12, 25.8, 28.68, 35.28,
  32.64, 36.96, 35.04, 38.64, 49.92, 51.72, 56.88, 55.08, 62.4, 54.84,
  65.16, 66.6, 58.8, 61.2, 59.64, 36.84, 48.12, 52.32, 52.56, 45.84,
  47.28, 58.2, 47.16, 58.2, 57.48, 66.24
)

df_g11 <- quarters %>%
  mutate(
    transactions_reste_pays = round(g11_tx_reste_h / scale_tx_g11),
    transactions_luxembourg = round(g11_tx_lux_h / scale_tx_g11),
    indice_prix_reste_pays = round(100 + g11_idx_reste_dy / scale_idx_g11, 1),
    indice_prix_luxembourg = round(100 + g11_idx_lux_dy / scale_idx_g11, 1)
  )

write.csv(df_g11, "data/focus_regional_appartements_vefa.csv", row.names = FALSE)
cat("Saved data/focus_regional_appartements_vefa.csv\n")
