# DataCo Supply Chain – Data Warehouse & BI

## 1. Contexte

Projet de système décisionnel basé sur le dataset **DataCo Supply Chain** (e‑commerce multi‑marchés).  
Objectif : construire un **Data Warehouse en étoile** + **pipeline ETL** + **tableaux de bord Power BI** pour analyser :

- ventes et rentabilité
- clients et segments
- produits et catégories
- performance logistique (délais, retards)
- analyse temporelle (tendances, saisonnalité)

---

## 2. Architecture du projet

```text
dataco-supply-chain-dw/
├── data/
│   ├── raw/          # fichiers sources bruts (CSV de Kaggle)
│   └── processed/    # dimensions et fact table prêtes pour le DW
├── notebooks/
│   └── 01_etl_dataco_exploration.ipynb   # EDA + ETL pas à pas
├── etl/
│   └── etl_dataco.py # pipeline ETL rejouable (Extract → Transform → Load)
├── sql/
│   ├── create_tables_dw.sql              # création tables dim_* et fact_orders
│   └── load_tables_examples.sql          # exemples de chargement (COPY / INSERT)
├── reports/
│   ├── dataco_powerbi.pbix               # rapports Power BI (si version desktop)
│   └── model_star_schema.png             # schéma en étoile
├── docs/
│   └── data_dictionary_etl_rules.md      # dictionnaire + règles ETL
├── README.md
└── requirements.txt
