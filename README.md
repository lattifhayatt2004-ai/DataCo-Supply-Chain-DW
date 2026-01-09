# DataCo Supply Chain – Data Warehouse & Business Intelligence

## 📋 Contexte

Projet de système décisionnel complet basé sur le dataset **DataCo Supply Chain** (e-commerce international multi-marchés).

**Objectif** : Construire un Data Warehouse en étoile + pipeline ETL + dashboards Power BI pour analyser :
- Ventes et rentabilité  
- Clients et segments  
- Produits et catégories  
- Performance logistique (délais, retards)  
- Analyse temporelle (tendances, saisonnalité)

---

## 🏗️ Architecture du projet

```
dataco-supply-chain-dw/
├── data/
│   ├── raw/                  # Fichiers sources (CSV Kaggle)
│   └── processed/            # Dimensions et fact table prêtes pour le DW
├── notebooks/
│   └── 01_etl_dataco_exploration.ipynb  # EDA + construction ETL pas à pas
├── etl/
│   └── etl_dataco.py         # Pipeline ETL rejouable (pandas)
├── sql/
│   ├── create_tables_dw.sql  # Création des tables (schéma en étoile)
│   └── load_tables_examples.sql # Chargement des CSV dans PostgreSQL
├── docs/
│   └── data_dictionary_etl_rules.md # Dictionnaire + règles ETL
├── reports/
│   └── dataco_powerbi.pbix   # Dashboards Power BI
├── README.md
└── requirements.txt
```

---

## 📊 Modèle de données (schéma en étoile)

### Table de faits
- **`fact_orders`** : grain = ligne de commande (Order Item)
  - Clés : `order_item_id`, `order_id`, `customer_id`, `product_id`, `date_id`
  - Mesures : `quantity`, `sales`, `order_profit`, `delay_days`, `margin_ratio`, etc.

### Dimensions
- **`dim_time`** : 1 127 dates (année, mois, jour)  
- **`dim_customer`** : 20 652 clients (segment, pays, ville)  
- **`dim_product`** : 118 produits (catégorie, département, prix)  
- **`dim_location`** : 64 867 localisations (pays, région, marché, coordonnées)  
- **`dim_shipping`** : 12 modes d'expédition (mode, statut, risque de retard)

**Nombre total de lignes** : 180 519 commandes (fact table)

---

## 🚀 Installation et utilisation

### 1. Cloner le projet
```bash
git clone https://github.com/lattifhayatt2004-ai/dataco-supply-chain-dw.git
cd dataco-supply-chain-dw
```

### 2. Installer les dépendances Python
```bash
python -m venv .venv
source .venv/bin/activate      # Windows : .venv\Scripts\activate
pip install -r requirements.txt
```

### 3. Placer les fichiers sources
Télécharger depuis Kaggle **DataCo Supply Chain Dataset** et placer dans `data/raw/` :

- `DataCoSupplyChainDataset.csv`
- `DescriptionDataCoSupplyChain.csv`

### 4. Exécuter le pipeline ETL
```bash
python etl/etl_dataco.py
```

### 5. Créer le Data Warehouse dans PostgreSQL

```bash
psql -U postgres
CREATE DATABASE dataco_dw;
\q
```

---

## 📄 Licence

Ce projet est réalisé dans un cadre académique.
