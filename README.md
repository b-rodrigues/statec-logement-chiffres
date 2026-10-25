# STATEC — Le Logement en chiffres (Dynamic Quarto & Observable JS)

This repository is an experiment to translate the official STATEC / Observatoire de l'Habitat publication:

> **[Le Logement en chiffres — N° 20 — 2e trimestre 2026](https://statistiques.public.lu/en/publications/series/logement-chiffres/2026/logement-02-26.html)**  
> Authors: Marc Ferring (STATEC) & Dr Julien Licheron (Observatoire de l’habitat, LISER)

from its static PDF release into an interactive, dynamic Quarto HTML document with Observable JS graphics.

🔗 **Live Document**: [https://b-rodrigues.github.io/statec-logement-chiffres/](https://b-rodrigues.github.io/statec-logement-chiffres/)

---

## Project Structure

- `flake.nix` & `flake.lock`: Reproducible development environment powered by Nix and [rstats-on-nix](https://github.com/rstats-on-nix/nixpkgs), bundling R (`readxl`, `dplyr`, `tidyr`, `stringr`, `janitor`, `jsonlite`, `knitr`, `rmarkdown`), Quarto, and Pandoc.
- `D4011.xls`: Original statistical data released by STATEC alongside the publication.
- `scripts/extract_data.R`: R script parsing all quarterly and annual tables from `D4011.xls` into tidy CSV files.
- `data/`: Extracted CSV datasets (indices, average prices, transaction volumes).
- `index.qmd`: Quarto source document reproducing the full report and embedding interactive Observable JS charts.
- `.github/workflows/deploy.yml`: Continuous deployment workflow compiling the Quarto document inside Nix and publishing to `gh-pages`.

---

## How to Reproduce

### 1. Enter the Nix Development Shell
Ensure [Nix](https://nixos.org/) with Flakes enabled is installed, then run:

```bash
nix develop
```

### 2. Extract Data
Extract the tables from the Excel file:

```bash
Rscript scripts/extract_data.R
```

### 3. Compile the Document
Render the interactive document to HTML:

```bash
quarto render index.qmd
```
