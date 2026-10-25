#!/usr/bin/env Rscript

# ==============================================================================
# Script: extract_data.R
# Description: Extracts every table from D4011.xls (STATEC Logement en chiffres)
#              into tidy, well-structured CSV files in the data/ directory.
# ==============================================================================

suppressPackageStartupMessages({
  library(readxl)
  library(dplyr)
  library(tidyr)
  library(stringr)
})

# Locate root directory and files
repo_root <- if (file.exists("D4011.xls")) {
  "."
} else if (file.exists("../D4011.xls")) {
  ".."
} else {
  getwd()
}

excel_path <- file.path(repo_root, "D4011.xls")
output_dir <- file.path(repo_root, "data")

if (!file.exists(excel_path)) {
  stop("Excel file not found at: ", excel_path)
}

if (!dir.exists(output_dir)) {
  dir.create(output_dir, recursive = TRUE)
  message("Created directory: ", output_dir)
}

message("Reading sheets from: ", excel_path)

# ------------------------------------------------------------------------------
# Helper: Save table and report summary
# ------------------------------------------------------------------------------
save_extracted_csv <- function(df, filename, description) {
  dest <- file.path(output_dir, filename)
  write.csv(df, dest, row.names = FALSE, na = "")
  message(sprintf("  ✓ Saved %-42s (%2d rows, %2d cols) -> %s",
                  paste0("'", filename, "'"), nrow(df), ncol(df), description))
}

# ==============================================================================
# 1. FRENCH TABLES (Tables 1, 2, 3)
# ==============================================================================
message("\n--- Extracting French Tables ---")

# --- 1.1 Sheet: 'FR indices logements' ---
raw_ind_fr <- read_excel(excel_path, sheet = "FR indices logements", col_names = FALSE)
q_head_ind_fr <- which(apply(raw_ind_fr, 1, function(r) any(str_detect(r, regex("s[ée]rie trimestrielle", ignore_case = TRUE)), na.rm = TRUE)))[1]
a_head_ind_fr <- which(apply(raw_ind_fr, 1, function(r) any(str_detect(r, regex("s[ée]rie r[ée]trospective annuelle", ignore_case = TRUE)), na.rm = TRUE)))[1]

# Quarterly series
df_q_ind_fr <- raw_ind_fr[(q_head_ind_fr + 1):(a_head_ind_fr - 1), 1:17]
colnames(df_q_ind_fr) <- c(
  "annee", "trimestre",
  "indice_ensemble", "var_trim_ensemble_pct", "var_annuelle_ensemble_pct",
  "indice_anciens", "var_trim_anciens_pct", "var_annuelle_anciens_pct",
  "indice_maisons", "var_trim_maisons_pct", "var_annuelle_maisons_pct",
  "indice_appartements_anciens", "var_trim_appartements_anciens_pct", "var_annuelle_appartements_anciens_pct",
  "indice_neufs", "var_trim_neufs_pct", "var_annuelle_neufs_pct"
)

clean_q_ind_fr <- df_q_ind_fr %>%
  fill(annee, .direction = "down") %>%
  filter(!is.na(trimestre) & str_detect(trimestre, "T[1-4]")) %>%
  mutate(
    annee = as.integer(annee),
    trimestre = str_extract(trimestre, "T[1-4]"),
    across(-c(annee, trimestre), as.numeric)
  )

save_extracted_csv(clean_q_ind_fr, "indices_logements_trimestriel.csv",
                   "Indices des prix des logements (Trimestriel)")

# Annual series
df_a_ind_fr <- raw_ind_fr[(a_head_ind_fr + 1):nrow(raw_ind_fr), c(1, 3, 5, 6, 8, 9, 11, 12, 14, 15, 17)]
colnames(df_a_ind_fr) <- c(
  "annee",
  "indice_moyen_ensemble", "var_annuelle_ensemble_pct",
  "indice_moyen_anciens", "var_annuelle_anciens_pct",
  "indice_moyen_maisons", "var_annuelle_maisons_pct",
  "indice_moyen_appartements_anciens", "var_annuelle_appartements_anciens_pct",
  "indice_moyen_neufs", "var_annuelle_neufs_pct"
)

clean_a_ind_fr <- df_a_ind_fr %>%
  filter(!is.na(annee) & str_detect(annee, "^[0-9]{4}$")) %>%
  mutate(
    annee = as.integer(annee),
    across(-annee, as.numeric)
  )

save_extracted_csv(clean_a_ind_fr, "indices_logements_annuel.csv",
                   "Indices des prix des logements (Annuel)")


# --- 1.2 Sheet: 'FR prix moy' ---
raw_pm_fr <- read_excel(excel_path, sheet = "FR prix moy", col_names = FALSE)
q_head_pm_fr <- which(apply(raw_pm_fr, 1, function(r) any(str_detect(r, regex("s[ée]rie trimestrielle", ignore_case = TRUE)), na.rm = TRUE)))[1]
a_head_pm_fr <- which(apply(raw_pm_fr, 1, function(r) any(str_detect(r, regex("s[ée]rie r[ée]trospective annuelle", ignore_case = TRUE)), na.rm = TRUE)))[1]

# Quarterly series
df_q_pm_fr <- raw_pm_fr[(q_head_pm_fr + 1):(a_head_pm_fr - 1), 1:11]
colnames(df_q_pm_fr) <- c(
  "annee", "trimestre",
  "prix_moyen_total_eur", "surface_moyenne_total_m2", "prix_moyen_m2_total_eur",
  "prix_moyen_ancien_eur", "surface_moyenne_ancien_m2", "prix_moyen_m2_ancien_eur",
  "prix_moyen_neuf_eur", "surface_moyenne_neuf_m2", "prix_moyen_m2_neuf_eur"
)

clean_q_pm_fr <- df_q_pm_fr %>%
  fill(annee, .direction = "down") %>%
  filter(!is.na(trimestre) & str_detect(trimestre, "T[1-4]")) %>%
  mutate(
    annee = as.integer(annee),
    trimestre = str_extract(trimestre, "T[1-4]"),
    across(-c(annee, trimestre), as.numeric)
  )

save_extracted_csv(clean_q_pm_fr, "prix_moyens_appartements_trimestriel.csv",
                   "Prix moyens des appartements (Trimestriel)")

# Annual series
df_a_pm_fr <- raw_pm_fr[(a_head_pm_fr + 1):nrow(raw_pm_fr), c(1, 3:11)]
colnames(df_a_pm_fr) <- c(
  "annee",
  "prix_moyen_total_eur", "surface_moyenne_total_m2", "prix_moyen_m2_total_eur",
  "prix_moyen_ancien_eur", "surface_moyenne_ancien_m2", "prix_moyen_m2_ancien_eur",
  "prix_moyen_neuf_eur", "surface_moyenne_neuf_m2", "prix_moyen_m2_neuf_eur"
)

clean_a_pm_fr <- df_a_pm_fr %>%
  filter(!is.na(annee) & str_detect(annee, "^[0-9]{4}$")) %>%
  mutate(
    annee = as.integer(annee),
    across(-annee, as.numeric)
  )

save_extracted_csv(clean_a_pm_fr, "prix_moyens_appartements_annuel.csv",
                   "Prix moyens des appartements (Annuel)")


# --- 1.3 Sheet: 'FR nbre actes + vol fin' ---
raw_tx_fr <- read_excel(excel_path, sheet = "FR nbre actes + vol fin", col_names = FALSE)
q_head_tx_fr <- which(apply(raw_tx_fr, 1, function(r) any(str_detect(r, regex("s[ée]rie trimestrielle", ignore_case = TRUE)), na.rm = TRUE)))[1]
a_head_tx_fr <- which(apply(raw_tx_fr, 1, function(r) any(str_detect(r, regex("s[ée]rie r[ée]trospective annuelle", ignore_case = TRUE)), na.rm = TRUE)))[1]

# Quarterly series
df_q_tx_fr <- raw_tx_fr[(q_head_tx_fr + 1):(a_head_tx_fr - 1), 1:14]
colnames(df_q_tx_fr) <- c(
  "annee", "trimestre",
  "nb_actes_total", "var_annuelle_nb_actes_total_pct", "vol_fin_total_mio_eur", "var_annuelle_vol_fin_total_pct",
  "nb_actes_ancien", "var_annuelle_nb_actes_ancien_pct", "vol_fin_ancien_mio_eur", "var_annuelle_vol_fin_ancien_pct",
  "nb_actes_neuf", "var_annuelle_nb_actes_neuf_pct", "vol_fin_neuf_mio_eur", "var_annuelle_vol_fin_neuf_pct"
)

clean_q_tx_fr <- df_q_tx_fr %>%
  fill(annee, .direction = "down") %>%
  filter(!is.na(trimestre) & str_detect(trimestre, "T[1-4]")) %>%
  mutate(
    annee = as.integer(annee),
    trimestre = str_extract(trimestre, "T[1-4]"),
    across(-c(annee, trimestre), as.numeric)
  )

save_extracted_csv(clean_q_tx_fr, "transactions_volumes_trimestriel.csv",
                   "Transactions et volumes financiers (Trimestriel)")

# Annual series
df_a_tx_fr <- raw_tx_fr[(a_head_tx_fr + 1):nrow(raw_tx_fr), c(1, 3:14)]
colnames(df_a_tx_fr) <- c(
  "annee",
  "nb_actes_total", "var_annuelle_nb_actes_total_pct", "vol_fin_total_mio_eur", "var_annuelle_vol_fin_total_pct",
  "nb_actes_ancien", "var_annuelle_nb_actes_ancien_pct", "vol_fin_ancien_mio_eur", "var_annuelle_vol_fin_ancien_pct",
  "nb_actes_neuf", "var_annuelle_nb_actes_neuf_pct", "vol_fin_neuf_mio_eur", "var_annuelle_vol_fin_neuf_pct"
)

clean_a_tx_fr <- df_a_tx_fr %>%
  filter(!is.na(annee) & str_detect(annee, "^[0-9]{4}$")) %>%
  mutate(
    annee = as.integer(annee),
    across(-annee, as.numeric)
  )

save_extracted_csv(clean_a_tx_fr, "transactions_volumes_annuel.csv",
                   "Transactions et volumes financiers (Annuel)")


# ==============================================================================
# 2. ENGLISH TABLES (Tables 1, 2, 3)
# ==============================================================================
message("\n--- Extracting English Tables ---")

# --- 2.1 Sheet: 'EN house price index' ---
raw_ind_en <- read_excel(excel_path, sheet = "EN house price index", col_names = FALSE)
q_head_ind_en <- which(apply(raw_ind_en, 1, function(r) any(str_detect(r, regex("quarterly series", ignore_case = TRUE)), na.rm = TRUE)))[1]
a_head_ind_en <- which(apply(raw_ind_en, 1, function(r) any(str_detect(r, regex("annual series", ignore_case = TRUE)), na.rm = TRUE)))[1]

# Quarterly series
df_q_ind_en <- raw_ind_en[(q_head_ind_en + 1):(a_head_ind_en - 1), 1:17]
colnames(df_q_ind_en) <- c(
  "year", "quarter",
  "index_total", "quarterly_change_total_pct", "annual_change_total_pct",
  "index_existing", "quarterly_change_existing_pct", "annual_change_existing_pct",
  "index_houses", "quarterly_change_houses_pct", "annual_change_houses_pct",
  "index_apartments_existing", "quarterly_change_apartments_existing_pct", "annual_change_apartments_existing_pct",
  "index_new", "quarterly_change_new_pct", "annual_change_new_pct"
)

clean_q_ind_en <- df_q_ind_en %>%
  fill(year, .direction = "down") %>%
  filter(!is.na(quarter) & str_detect(quarter, "[TQ][1-4]")) %>%
  mutate(
    year = as.integer(year),
    quarter = str_replace(str_extract(quarter, "[TQ][1-4]"), "T", "Q"),
    across(-c(year, quarter), as.numeric)
  )

save_extracted_csv(clean_q_ind_en, "house_price_index_quarterly.csv",
                   "House price index (Quarterly)")

# Annual series
df_a_ind_en <- raw_ind_en[(a_head_ind_en + 1):nrow(raw_ind_en), c(1, 3, 5, 6, 8, 9, 11, 12, 14, 15, 17)]
colnames(df_a_ind_en) <- c(
  "year",
  "annual_avg_index_total", "annual_change_total_pct",
  "annual_avg_index_existing", "annual_change_existing_pct",
  "annual_avg_index_houses", "annual_change_houses_pct",
  "annual_avg_index_apartments_existing", "annual_change_apartments_existing_pct",
  "annual_avg_index_new", "annual_change_new_pct"
)

clean_a_ind_en <- df_a_ind_en %>%
  filter(!is.na(year) & str_detect(year, "^[0-9]{4}$")) %>%
  mutate(
    year = as.integer(year),
    across(-year, as.numeric)
  )

save_extracted_csv(clean_a_ind_en, "house_price_index_annual.csv",
                   "House price index (Annual)")


# --- 2.2 Sheet: 'EN average prices' ---
raw_pm_en <- read_excel(excel_path, sheet = "EN average prices", col_names = FALSE)
q_head_pm_en <- which(apply(raw_pm_en, 1, function(r) any(str_detect(r, regex("quarterly series", ignore_case = TRUE)), na.rm = TRUE)))[1]
a_head_pm_en <- which(apply(raw_pm_en, 1, function(r) any(str_detect(r, regex("annual series", ignore_case = TRUE)), na.rm = TRUE)))[1]

# Quarterly series
df_q_pm_en <- raw_pm_en[(q_head_pm_en + 1):(a_head_pm_en - 1), 1:11]
colnames(df_q_pm_en) <- c(
  "year", "quarter",
  "avg_price_total_eur", "avg_area_total_m2", "avg_price_m2_total_eur",
  "avg_price_existing_eur", "avg_area_existing_m2", "avg_price_m2_existing_eur",
  "avg_price_new_eur", "avg_area_new_m2", "avg_price_m2_new_eur"
)

clean_q_pm_en <- df_q_pm_en %>%
  fill(year, .direction = "down") %>%
  filter(!is.na(quarter) & str_detect(quarter, "[TQ][1-4]")) %>%
  mutate(
    year = as.integer(year),
    quarter = str_replace(str_extract(quarter, "[TQ][1-4]"), "T", "Q"),
    across(-c(year, quarter), as.numeric)
  )

save_extracted_csv(clean_q_pm_en, "average_prices_quarterly.csv",
                   "Average apartment prices (Quarterly)")

# Annual series
df_a_pm_en <- raw_pm_en[(a_head_pm_en + 1):nrow(raw_pm_en), c(1, 3:11)]
colnames(df_a_pm_en) <- c(
  "year",
  "avg_price_total_eur", "avg_area_total_m2", "avg_price_m2_total_eur",
  "avg_price_existing_eur", "avg_area_existing_m2", "avg_price_m2_existing_eur",
  "avg_price_new_eur", "avg_area_new_m2", "avg_price_m2_new_eur"
)

clean_a_pm_en <- df_a_pm_en %>%
  filter(!is.na(year) & str_detect(year, "^[0-9]{4}$")) %>%
  mutate(
    year = as.integer(year),
    across(-year, as.numeric)
  )

save_extracted_csv(clean_a_pm_en, "average_prices_annual.csv",
                   "Average apartment prices (Annual)")


# --- 2.3 Sheet: 'EN nbr trans + total value' ---
raw_tx_en <- read_excel(excel_path, sheet = "EN nbr trans + total value", col_names = FALSE)
q_head_tx_en <- which(apply(raw_tx_en, 1, function(r) any(str_detect(r, regex("quarterly series", ignore_case = TRUE)), na.rm = TRUE)))[1]
a_head_tx_en <- which(apply(raw_tx_en, 1, function(r) any(str_detect(r, regex("annual series", ignore_case = TRUE)), na.rm = TRUE)))[1]

# Quarterly series
df_q_tx_en <- raw_tx_en[(q_head_tx_en + 1):(a_head_tx_en - 1), 1:14]
colnames(df_q_tx_en) <- c(
  "year", "quarter",
  "nb_transactions_total", "annual_change_nb_transactions_total_pct", "financial_volume_total_mio_eur", "annual_change_financial_volume_total_pct",
  "nb_transactions_existing", "annual_change_nb_transactions_existing_pct", "financial_volume_existing_mio_eur", "annual_change_financial_volume_existing_pct",
  "nb_transactions_new", "annual_change_nb_transactions_new_pct", "financial_volume_new_mio_eur", "annual_change_financial_volume_new_pct"
)

clean_q_tx_en <- df_q_tx_en %>%
  fill(year, .direction = "down") %>%
  filter(!is.na(quarter) & str_detect(quarter, "[TQ][1-4]")) %>%
  mutate(
    year = as.integer(year),
    quarter = str_replace(str_extract(quarter, "[TQ][1-4]"), "T", "Q"),
    across(-c(year, quarter), as.numeric)
  )

save_extracted_csv(clean_q_tx_en, "transactions_volumes_quarterly.csv",
                   "Number of transactions and total value (Quarterly)")

# Annual series
df_a_tx_en <- raw_tx_en[(a_head_tx_en + 1):nrow(raw_tx_en), c(1, 3:14)]
colnames(df_a_tx_en) <- c(
  "year",
  "nb_transactions_total", "annual_change_nb_transactions_total_pct", "financial_volume_total_mio_eur", "annual_change_financial_volume_total_pct",
  "nb_transactions_existing", "annual_change_nb_transactions_existing_pct", "financial_volume_existing_mio_eur", "annual_change_financial_volume_existing_pct",
  "nb_transactions_new", "annual_change_nb_transactions_new_pct", "financial_volume_new_mio_eur", "annual_change_financial_volume_new_pct"
)

clean_a_tx_en <- df_a_tx_en %>%
  filter(!is.na(year) & str_detect(year, "^[0-9]{4}$")) %>%
  mutate(
    year = as.integer(year),
    across(-year, as.numeric)
  )

save_extracted_csv(clean_a_tx_en, "transactions_volumes_annual.csv",
                   "Number of transactions and total value (Annual)")

message("\nAll tables successfully extracted and written to: ", output_dir)
