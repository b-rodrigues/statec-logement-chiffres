# STATEC — Le Logement en chiffres (Édition web interactive Quarto & Observable JS)

[![Build and Deploy to GitHub Pages](https://github.com/b-rodrigues/statec-logement-chiffres/actions/workflows/deploy.yml/badge.svg)](https://github.com/b-rodrigues/statec-logement-chiffres/actions/workflows/deploy.yml)
[![License: EUPL 1.2](https://img.shields.io/badge/License-EUPL_1.2-blue.svg)](https://joinup.ec.europa.eu/collection/eupl/eupl-text-eupl-12)
[![Quarto](https://img.shields.io/badge/Made%20with-Quarto-blue.svg)](https://quarto.org)
[![Nix](https://img.shields.io/badge/Reproducible%20with-Nix%20Flake-7ebae4.svg?logo=nixos&logoColor=white)](flake.nix)

> ⚠️ **Avertissement** : Ce projet est une expérience technique indépendante et ne constitue pas une publication officielle du STATEC ni de l'Observatoire de l'Habitat.

Ce dépôt présente une démonstration technique de transformation de la publication statistique semestrielle :

> **[STATEC / Observatoire de l'Habitat — Le Logement en chiffres (N° 20 — 2e trimestre 2026)](https://statistiques.public.lu/en/publications/series/logement-chiffres/2026/logement-02-26.html)**  
> Auteurs de l'étude : Marc Ferring (STATEC) & Dr Julien Licheron (Observatoire de l’habitat, LISER)

depuis sa version statique au format PDF vers un document web dynamique, interactif et 100% reproductible intégrant des graphiques et cartes choroplèthes interactives propulsés par **Observable JS** et **Quarto**.

🔗 **Publication en ligne (GitHub Pages)** : [https://b-rodrigues.github.io/statec-logement-chiffres/](https://b-rodrigues.github.io/statec-logement-chiffres/)

---

## Fonctionnalités interactives

- **Graphiques 1 à 4** : Évolution temporelle des prix et des volumes de transactions (appartements neufs/anciens, maisons, terrains à bâtir) avec sélection dynamique des séries, baselines de référence et infobulles précises.
- **Graphiques 5 à 7** : Tableaux de bord des prix au m² selon la classe de surface et les régions géographiques.
- **Cartes 1 & 2** : Cartes choroplèthes interactives des 100 communes du Luxembourg pour les appartements existants et la VEFA, avec infobulles au survol (`Plot.tip` / `Plot.geoCentroid`) affichant le prix moyen au m², le nombre de ventes et la fourchette interquartile.
- **Graphiques 8 & 9** : Évolution des loyers annoncés et de la nouvelle série des chambres meublées (+102.6% depuis 2010).
- **Graphiques 10 & 11** : Focus régional européen (comparaison Région de Luxembourg vs Reste du pays).

---

## Structure du projet

- `flake.nix` & `flake.lock` : Définition de l'environnement de développement reproductible avec Nix et [rstats-on-nix](https://github.com/rstats-on-nix/nixpkgs), fournissant R (avec `readxl`, `dplyr`, `tidyr`, `stringr`, `janitor`, `jsonlite`, `knitr`, `rmarkdown`), Quarto 1.10 et Pandoc.
- `D4011.xls` : Données statistiques primaires publiées par le STATEC.
- `scripts/extract_data.R` : Pipeline R automatisé extrayant l'ensemble des tables Excel et téléchargeant les jeux de données ouverts complémentaires depuis [data.public.lu](https://data.public.lu).
- `scripts/extract_regional_focus.R` : Script d'extraction des séries temporelles des focus régionaux et des chambres meublées.
- `data/` : Jeux de données extraits au format CSV et polygones GeoJSON des communes (`communes_luxembourg.geojson`, coordonnées conformes RFC 7946).
- `index.qmd` : Document source Quarto complet avec texte intégral et cellules Observable JS.
- `.github/workflows/deploy.yml` : Workflow d'intégration et déploiement continus (CI/CD) sur GitHub Pages.
- `CITATION.cff` : Métadonnées de citation au format standard CFF.
- `codemeta.json` : Métadonnées au format CodeMeta (JSON-LD).
- `LICENSE` : Texte intégral de la Licence Publique de l'Union Européenne (EUPL v1.2 en français).

---

## Reproduction locale

### 1. Activer l'environnement Nix

Assurez-vous que [Nix](https://nixos.org/) est installé avec les Flakes activés, puis entrez dans le shell :

```bash
nix develop
```

### 2. Extraire et préparer les données

Exécutez le script d'extraction pour régénérer l'ensemble des fichiers dans `data/` :

```bash
Rscript scripts/extract_data.R
```

### 3. Compiler la publication HTML

Compilez le document Quarto interactif :

```bash
quarto render index.qmd
```

Le fichier autonome `index.html` est prêt à être ouvert dans votre navigateur web ou servi via un serveur local HTTP (`quarto preview index.qmd`).

---

## Licence & Données sources

- **Code source et document interactif** : Distribués sous les termes de la [Licence Publique de l’Union Européenne (EUPL v1.2)](LICENSE).
- **Données statistiques sources** : Produites par le [STATEC](https://statistiques.public.lu) et l'[Observatoire de l'Habitat (LISER)](https://logement.public.lu/fr/observatoire-habitat.html), mises à disposition sous licence ouverte sur [data.public.lu](https://data.public.lu).

---

## Citation

Pour citer ce travail, veuillez utiliser les métadonnées fournies dans [`CITATION.cff`](CITATION.cff) ou la référence suivante :

```bibtex
@software{rodrigues_statec_logement_2026,
  author       = {Rodrigues, Bruno},
  title        = {{STATEC — Le Logement en chiffres (Édition web interactive Quarto \& Observable JS)}},
  year         = {2026},
  url          = {https://b-rodrigues.github.io/statec-logement-chiffres/},
  repository   = {https://github.com/b-rodrigues/statec-logement-chiffres},
  license      = {EUPL-1.2}
}
```
