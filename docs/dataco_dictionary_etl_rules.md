# Fiche technique – Pipeline ETL DataCo

## 1. Sources utilisées

- `DataCoSupplyChainDataset.csv`  
  - Fichier transactionnel principal (commandes, clients, produits, livraisons, ventes, profits).
- `DescriptionDataCoSupplyChain.csv`  
  - Dictionnaire de données descriptif, utilisé pour comprendre le sens des colonnes.
- `tokenized_access_logs.csv`  
  - Logs techniques de navigation, **hors périmètre V1** (non utilisés dans l’ETL).

---

## 2. Staging – DataFrame `df_stg`

Point de départ : `df` = lecture brute de `DataCoSupplyChainDataset.csv`.

### 2.1 Nettoyage / colonnes ignorées

Colonnes supprimées dans la zone de staging (pas chargées dans le DW) :

- `Product Description` : 100 % de valeurs manquantes. 
- `Order Zipcode` : trop de valeurs manquantes pour être exploitable en V1.
- `Customer Email` : non nécessaire pour l’analyse décisionnelle.
- `Customer Password` : sensible, hors périmètre décisionnel.

### 2.2 Conversions de types

Ajout de deux colonnes datetime :

- `order_date`  
  - Conversion de `order date (DateOrders)` via `pd.to_datetime(..., infer_datetime_format=True)`.
- `shipping_date`  
  - Conversion de `shipping date (DateOrders)` avec la même méthode.

Grain conservé :  
> **1 ligne de `df_stg` = 1 ligne de commande (Order Item Id)**.

---

## 3. Dimensions construites

### 3.1 `dim_customer`

- **Grain** : 1 ligne par client (`Customer Id`).  
- **Construction** : `drop_duplicates` sur `Customer Id`.  
- **Colonnes** :
  - `customer_id` ← `Customer Id`
  - `fname` ← `Customer Fname`
  - `lname` ← `Customer Lname`
  - `segment` ← `Customer Segment`
  - `country` ← `Customer Country`
  - `city` ← `Customer City`
  - `state` ← `Customer State`
  - `street` ← `Customer Street`
  - `zipcode` ← `Customer Zipcode`

**Usage** : analyses par client, segment, pays, ville (chiffre d’affaires, profit, volume…).

---

### 3.2 `dim_product`

- **Grain** : 1 ligne par produit (`Product Card Id`).  
- **Construction** : `drop_duplicates` sur `Product Card Id`.  
- **Colonnes** :
  - `product_id` ← `Product Card Id`
  - `product_name` ← `Product Name`
  - `category_id` ← `Category Id`
  - `category_name` ← `Category Name`
  - `department_id` ← `Department Id`
  - `department_name` ← `Department Name`
  - `product_category_id` ← `Product Category Id`
  - `base_price` ← `Product Price`

**Usage** : analyses par produit, catégorie, département (top sellers, produits rentables ou non).

---

### 3.3 `dim_time`

- **Grain** : 1 ligne par date de commande.  
- **Construction** : `drop_duplicates` sur `order_date`.  
- **Colonnes** :
  - `date_id` = format `YYYYMMDD` dérivé de `order_date`
  - `order_date`
  - `year`
  - `month`
  - `day`

**Usage** : analyses temporelles (année, mois, jour, tendances, saisonnalité).

---

### 3.4 `dim_location`

- **Grain** : combinaison de localisation.  
- **Construction** : `drop_duplicates` sur les colonnes de localisation.  
- **Colonnes** :
  - `location_id` = index + 1 (surrogate key)
  - `Customer Country`
  - `Customer City`
  - `Order City`
  - `Order Region`
  - `Market`
  - `Latitude`
  - `Longitude`

**Usage** : analyses géographiques (pays, ville, région, marché, cartographie).

---

### 3.5 `dim_shipping`

- **Grain** : combinaison mode/statut/risque.  
- **Construction** : `drop_duplicates` sur `Shipping Mode`, `Delivery Status`, `Late_delivery_risk`.  
- **Colonnes** :
  - `shipping_id` = index + 1
  - `Shipping Mode`
  - `Delivery Status`
  - `Late_delivery_risk`

**Usage** : analyses logistiques (taux de retard par mode d’expédition et statut).

---

## 4. Table de faits `fact_orders`

### 4.1 Grain et clés

- **Grain** : 1 ligne par **Order Item**.  
- **Clés** :
  - `order_item_id` ← `Order Item Id`
  - `order_id` ← `Order Id`
  - `customer_id` ← `Order Customer Id` (lien vers `dim_customer.customer_id`)
  - `product_id` ← `Product Card Id` (lien vers `dim_product.product_id`)
  - `order_date` ← `order_date`
  - `date_id` ← joint avec `dim_time` sur `order_date`

Les informations de localisation (`order_city`, `order_region`, `Market`) et de shipping (`Shipping Mode`, `Delivery Status`, `Late_delivery_risk`) sont incluses pour permettre les joins logiques avec `dim_location` et `dim_shipping`.

### 4.2 Mesures de base

Colonnes quantitatives conservées dans `fact_orders` :

- `quantity` ← `Order Item Quantity`
- `unit_price` ← `Order Item Product Price`
- `discount_amount` ← `Order Item Discount`
- `discount_rate` ← `Order Item Discount Rate`
- `line_total` ← `Order Item Total`
- `Sales`
- `order_benefit` ← `Benefit per order`
- `order_profit` ← `Order Profit Per Order`
- `days_shipping_real` ← `Days for shipping (real)`
- `days_shipping_sched` ← `Days for shipment (scheduled)`

### 4.3 Mesures dérivées

- `delay_days`  
  - Formule :  
    - `delay_days = days_shipping_real − days_shipping_sched`  
  - Interprétation :  
    - > 0 : retard  
    - = 0 : à l’heure  
    - < 0 : livré en avance

- `margin_ratio`  
  - Formule :  
    - `margin_ratio = order_profit / Sales` si `Sales > 0`, sinon `NULL`.  
  - Interprétation :  
    - Indicateur de rentabilité relative par ligne de commande.

---

## 5. Contrôles qualité intégrés

Dans le script `etl_dataco.py`, avant export des CSV :

- **Check 1 – Volume**  
  - `len(fact_orders) == len(df_stg)`  
  - Vérifie qu’aucune ligne n’a été perdue lors de la construction de la fact table.

- **Check 2 – Intégrité clients**  
  - Tous les `customer_id` de `fact_orders` existent dans `dim_customer.customer_id`.

- **Check 3 – Intégrité produits**  
  - Tous les `product_id` de `fact_orders` existent dans `dim_product.product_id`.

Si un check échoue, le script ETL s’arrête (assertion) afin de ne pas produire des tables incohérentes.

---