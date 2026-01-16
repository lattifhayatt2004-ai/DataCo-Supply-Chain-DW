# DataCo Supply Chain -- Data Warehouse & Business Intelligence

## 📋 Contexte

Projet de système décisionnel complet basé sur le dataset **DataCo Supply Chain** (e-commerce international multi-marchés). \

**Lien vers le dataset** :\
https://www.kaggle.com/datasets/saicharankomati/dataco-supply-chain-dataset\

**Objectif** : Construire un Data Warehouse en étoile + pipeline ETL + dashboards Power BI pour analyser : 
- Ventes et rentabilité\
- Clients et segments\
- Produits et catégories\
- Performance logistique (délais, retards)\
- Analyse temporelle (tendances, saisonnalité)

------------------------------------------------------------------------

## 🏗️ Architecture du projet

``` text
Supply_Chain_ETL_DW_Power_BI/
├── data/
│   ├── raw/                       # Fichiers sources (CSV Kaggle, non versionnés)
│   └── processed/                 # Dimensions & fact générées par l’ETL
├── notebooks/
│   └── 01_etl_dataco_exploration.ipynb   # EDA + construction ETL pas à pas
├── etl/
│   └── etl_dataco.py              # Pipeline ETL rejouable (pandas)
├── sql/
│   └── create_tables_dw.sql       # Création des tables DW (schéma en étoile)
├── docs/
│   └── data_dictionary_etl_rules.md   # Dictionnaire + règles ETL / mapping
├── reports/
│   └── dataco_powerbi.pbix        # Dashboards Power BI (exemple de rapport)
├── README.md
└── requirements.txt
```

Les fichiers CSV bruts de Kaggle sont attendus dans **data/raw/** mais ne
sont pas obligatoirement dans le repo GitHub (à télécharger depuis
Kaggle). \

Les CSV de **data/processed/** sont générés par le script ETL et servent de
source au Data Warehouse PostgreSQL. \

## 📊 Modèle de données (schéma en étoile)

### Table de faits

**fact_orders**

Grain : ligne de commande (order item). \

**Clés** : 
- **order_item_id** (PK technique) 
- **order_id (commande)** 
- **customer_id** (FK → dim_customer) 
- **product_id** (FK → dim_product) 
- **date_id** (FK → dim_time)

**Mesures principales** : 
- **quantity**, **unit_price**, **line_total**, **sales** - **order_benefit**, **order_profit** 
- **days_shipping_real**, **days_shipping_sched**, **delay_days** 
- **margin_ratio**

### Dimensions

Les volumes ci-dessous sont donnés à titre indicatif pour ce dataset
DataCo. \

**dim_time** 
- Clé : **date_id** (format AAAAMMJJ) 
- Attributs : **order_date**, **year**, **month, day**

**dim_customer** 
- Clé : **customer_id** 
- Attributs : **fname**, **lname**, **segment**, **country**, **city**, **state**, **street**, **zipcode**

**dim_product** 
- Clé : **product_id** 
- Attributs : **product_name**, **category_id**, **category_name**, **department_id**, **department_name**, **product_category_id**, **base_price**

**dim_location** 
- Clé : **location_id** 
- Attributs (côté commande) : **order_city**, **order_region**, **market**, **latitude**, **longitude**

**dim_shipping** 
- Clé : **shipping_id**
- Attributs : **shipping_mode**,  **delivery_status**, **late_delivery_risk**

## 🚀 Installation et utilisation

### 1. Cloner le projet

``` bash
git clone https://github.com/lattifhayatt2004-ai/dataco-supply-chain-dw.git
cd dataco-supply-chain-dw
```

### 2. Installer les dépendances Python

``` bash
python -m venv .venv
# Linux / macOS
source .venv/bin/activate
# Windows
# .venv\Scripts\activate

pip install -r requirements.txt
```

### 3. Télécharger et placer les fichiers sources

#### 3.1. Télécharger depuis Kaggle :
 **DataCo Supply Chain Dataset**. \

#### 3.2 Placer les fichiers dans **data/raw/** : 
- **DataCoSupplyChainDataset.csv**
- **DescriptionDataCoSupplyChain.csv** (optionnel, utilisé pour la documentation)

### 4. Exécuter le pipeline ETL

Depuis la racine du projet :

``` bash
python etl/etl_dataco.py
```

Cela génère les fichiers suivants dans data/processed/ :
- **dim_customer.csv** 
- **dim_product.csv** 
- **dim_time.csv** 
- **dim_location.csv** 
- **dim_shipping.csv** 
- **fact_orders.csv**

### 5. Créer le Data Warehouse PostgreSQL

#### 5.1 Créer la base : 

``` sql
CREATE DATABASE dataco_dw;
```

#### 5.2 Exécuter le script de création du schéma (tables DW) :

``` sql
\i sql/create_tables_dw.sql
```

#### 5.3 Importer les CSV data/processed/ dans les tables correspondantes :
viapgAdmin : Import/Export Data sur chaque table, en mode CSV, séparateur ',', header activé. \

#### Remarque : 
un script d'exemple de chargement via **`\copy `** peut être ajouté ultérieurement, mais l'utilisation de l'outil d'import pgAdmin est la méthode recommandée dans ce projet.

### 6. Utiliser les dashboards Power BI

- Ouvrir **reports/dataco_powerbi.pbix** dans **Power BI Desktop**.\

- Ou créer un nouveau rapport en se connectant à PostgreSQL : 
- - Get Data → PostgreSQL database
- - Server : **localhost** (ou ton serveur)\
- - Database : **dataco_dw**
- - Sélectionner : **dim_time**, **dim_customer**, **dim_product**, **dim_location**, **dim_shipping**, **fact_orders**
- - Vérifier les relations (notamment les FK sur **customer_id**, **product_id**, **date_id**). \

### 📈 Visualisation Power BI
Le rapport Power BI Desktop est disponible dans **reports/dataco_powerbi.pbix**. Il se connecte soit directement à la base PostgreSQL **dataco_dw**, soit aux fichiers CSV de **data/processed/**.

Le rapport contient plusieurs pages thématiques :

#### 1. Ventes & profit
**KPI** : ***chiffre d'affaires total**, **profit total**, **taux de marge**.

**Graphiques** :

- Ventes dans le temps (année / mois).
- Ventes & profit par segment client.
- Ventes par catégorie produit.
- Profit total par marché.

**Filtres** : **année**, **catégorie**, **marché**, **mode d’expédition**.

#### 2. Livraison & délais
**KPI** : **% de commandes en retard**, **délai moyen (jours)**, **durée d’expédition réelle**.

**Graphiques** :

- Durée d’expédition réelle vs prévue par année.
- Taux de retard par marché.
- Taux de retard par mode d’expédition.
- Nombre de commandes par statut de livraison.

**Filtres** : année, marché, mode d’expédition.

#### 3. Clients & segments
**KPI** : **nombre de clients**, **CA moyen par client**, **profit moyen par client**.

**Graphiques** :
- Ventes & profit par segment client.
- Ventes par pays client.
- Top 10 clients par chiffre d’affaires (nom & prénom concaténés).

**Filtres** : année, segment client, pays.

#### 4. Produits & catégories
**KPI** : **nombre de produits**, **CA moyen par produit**, **profit moyen par produit**.

**Graphiques** :
- Ventes & profit par catégorie produit.
- Ventes par département.
- Top 10 produits par chiffre d’affaires.

**Filtres** : année, catégorie, département.

Pour ouvrir le rapport :

- Lancer Power BI Desktop.

- Ouvrir reports/dataco_powerbi.pbix.

- Vérifier au besoin la source de données via Transformer les données → Paramètres de la source de données.

## 📄 Licence

Ce projet est réalisé dans un cadre académique (projet d'apprentissage /
portfolio). Toute réutilisation du dataset doit respecter les conditions
d'utilisation de Kaggle et de la source d'origine. \