#!/usr/bin/env Rscript

# ==============================================================================
# Script: extract_data.R
# Description: Extracts every table from D4011.xls and companion open datasets
#              from data.public.lu into tidy CSV files in the data/ directory.
# ==============================================================================

suppressPackageStartupMessages({
  library(readxl)
  library(dplyr)
  library(tidyr)
  library(stringr)
  library(jsonlite)
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
raw_dir <- file.path(repo_root, "data-raw")

if (!file.exists(excel_path)) {
  stop("Excel file not found at: ", excel_path)
}

if (!dir.exists(output_dir)) dir.create(output_dir, recursive = TRUE)
if (!dir.exists(raw_dir)) dir.create(raw_dir, recursive = TRUE)

message("Reading primary data from: ", excel_path)

save_extracted_csv <- function(df, filename, description) {
  dest <- file.path(output_dir, filename)
  write.csv(df, dest, row.names = FALSE, na = "")
  message(sprintf("  ✓ Saved %-44s (%2d rows, %2d cols) -> %s",
                  paste0("'", filename, "'"), nrow(df), ncol(df), description))
}

# ==============================================================================
# 1. PRIMARY EXCEL DATASETS (D4011.xls)
# ==============================================================================
message("\n--- 1. Extracting Tables from D4011.xls ---")

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
                   "Transactions et volumes d'appartements (Trimestriel)")

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
                   "Transactions et volumes d'appartements (Annuel)")

# ==============================================================================
# 2. COMPANION OPEN DATASETS (data.public.lu)
# ==============================================================================
message("\n--- 2. Fetching & Extracting Companion Datasets (data.public.lu) ---")

download_if_missing <- function(url, dest) {
  if (!file.exists(dest)) {
    message("Downloading: ", basename(dest))
    tryCatch({
      download.file(url, dest, quiet = TRUE, mode = "wb")
    }, error = function(e) {
      warning("Failed to download ", url, ": ", e$message)
    })
  }
}

# Download URLs
urls <- list(
  maisons = "https://download.data.public.lu/resources/nombre-de-ventes-dappartements-de-maisons-et-de-terrains/20260924-084013/ventes-maisons-2026t2-obs.xlsx",
  terrains = "https://download.data.public.lu/resources/nombre-de-ventes-dappartements-de-maisons-et-de-terrains/20260924-084031/ventes-terrains-2026t2-obs.xlsx",
  communes = "https://download.data.public.lu/resources/prix-de-vente-des-appartements-par-commune/20260924-084407/prix-moyen-au-metre-carre-enregistre-par-commune-2026t2.xls",
  loyers = "https://download.data.public.lu/resources/loyers-annonces-des-logements/20260924-084924/serie-retrospective-euros-courants.xls",
  geojson = "https://download.data.public.lu/resources/limites-administratives-du-grand-duche-de-luxembourg/20231123-101528/communes4326.geojson"
)

file_maisons <- file.path(raw_dir, "ventes-maisons.xlsx")
file_terrains <- file.path(raw_dir, "ventes-terrains.xlsx")
file_communes <- file.path(raw_dir, "prix-communes.xls")
file_loyers <- file.path(raw_dir, "loyers.xls")
file_geojson <- file.path(output_dir, "communes_luxembourg.geojson")

download_if_missing(urls$maisons, file_maisons)
download_if_missing(urls$terrains, file_terrains)
download_if_missing(urls$communes, file_communes)
download_if_missing(urls$loyers, file_loyers)
download_if_missing(urls$geojson, file_geojson)

# --- 2.1 Houses Sales & Financial Volumes (Graphique 3) ---
if (file.exists(file_maisons)) {
  df_maisons <- read_excel(file_maisons, skip = 5) %>%
    rename(annee = 1, trimestre = 2, nb_actes = 3, volume_eur = 4) %>%
    fill(annee, .direction = "down") %>%
    filter(!is.na(trimestre) & grepl("T[1-4]", trimestre) & !is.na(nb_actes)) %>%
    mutate(
      annee = as.integer(annee),
      trimestre = str_extract(trimestre, "T[1-4]"),
      nb_actes = as.integer(nb_actes),
      volume_eur = as.numeric(volume_eur),
      volume_mio_eur = round(volume_eur / 1e6, 2)
    )
  save_extracted_csv(df_maisons, "ventes_maisons_trimestriel.csv",
                     "Ventes et volume financier des maisons (Trimestriel)")
}

# --- 2.2 Building Plots Sales & Financial Volumes (Graphique 4) ---
if (file.exists(file_terrains)) {
  df_terrains <- read_excel(file_terrains, skip = 5) %>%
    rename(annee = 1, trimestre = 2, nb_actes = 3, volume_eur = 4) %>%
    fill(annee, .direction = "down") %>%
    filter(!is.na(trimestre) & grepl("T[1-4]", trimestre) & !is.na(nb_actes)) %>%
    mutate(
      annee = as.integer(annee),
      trimestre = str_extract(trimestre, "T[1-4]"),
      nb_actes = as.integer(nb_actes),
      volume_eur = as.numeric(volume_eur),
      volume_mio_eur = round(volume_eur / 1e6, 2)
    )
  save_extracted_csv(df_terrains, "ventes_terrains_trimestriel.csv",
                     "Ventes et volume financier des terrains à bâtir (Trimestriel)")
}

# --- 2.3 Commune Apartment Prices (Cartes 1 & 2) ---
if (file.exists(file_communes)) {
  df_communes <- read_excel(file_communes, skip = 8) %>%
    rename(
      commune = 1,
      nb_ventes_existant = 2,
      prix_m2_existant = 3,
      fourchette_existant = 4,
      nb_ventes_neuf = 5,
      prix_m2_neuf = 6,
      fourchette_neuf = 7
    ) %>%
    filter(!is.na(commune) & !grepl("Source|Remarque|Total|Précision|Commune|internet", commune, ignore.case = TRUE)) %>%
    mutate(
      # Harmonize commune names with official GeoJSON boundary properties
      commune_clean = case_when(
        commune == "Luxembourg-Ville" ~ "Luxembourg",
        commune == "Petange" ~ "Pétange",
        commune == "Preizerdaul" ~ "Préizerdaul",
        commune %in% c("Redange", "Redange-sur-Attert") ~ "Redange/Attert",
        TRUE ~ commune
      ),
      nb_ventes_existant = suppressWarnings(as.integer(nb_ventes_existant)),
      prix_m2_existant = suppressWarnings(as.numeric(prix_m2_existant)),
      nb_ventes_neuf = suppressWarnings(as.integer(nb_ventes_neuf)),
      prix_m2_neuf = suppressWarnings(as.numeric(prix_m2_neuf))
    ) %>%
    select(commune = commune_clean, commune_raw = commune, everything())
  save_extracted_csv(df_communes, "prix_communes_appartements.csv",
                     "Prix moyen au m² des appartements par commune (12 derniers mois)")
}

# --- 2.4 Advertised Rent Indices (Graphiques 8 & 9) ---
if (file.exists(file_loyers)) {
  df_loyers <- read_excel(file_loyers, sheet = "Série en Euros Courants", skip = 4) %>%
    rename(
      annee = 1,
      trimestre = 2,
      indice_vente_maison = 3,
      indice_vente_appartement = 4,
      indice_loyer_maison = 5,
      indice_loyer_appartement = 6
    ) %>%
    fill(annee, .direction = "down") %>%
    filter(!is.na(trimestre) & grepl("T[1-4]", trimestre) & !is.na(indice_loyer_appartement)) %>%
    mutate(
      annee = as.integer(annee),
      trimestre = str_extract(trimestre, "T[1-4]"),
      across(starts_with("indice_"), as.numeric)
    )
  save_extracted_csv(df_loyers, "loyers_annonces_trimestriel.csv",
                     "Indices des loyers et prix annoncés (Trimestriel)")
}

# --- 2.5 Regional Indices & Furnished Rooms Series (Graphiques 9, 10, 11) ---
focus_script <- file.path(repo_root, "scripts/extract_regional_focus.R")
if (file.exists(focus_script)) {
  source(focus_script)
}

message("\nAll tables and companion data files ready in: ", output_dir)
