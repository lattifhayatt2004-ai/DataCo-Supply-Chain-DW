# DataCo – Data Dictionary & ETL Rules

## 1. Vue d’ensemble

Ce document décrit :
- les **tables finales** produites par le pipeline ETL (`etl_dataco.py`),
- le **grain**, les **colonnes**, et les **règles de transformation**,
- la cohérence entre le script ETL et le Data Warehouse.

Pipeline concerné : **ETL V1 – pandas**  
Source principale : `DataCoSupplyChainDataset.csv`

---

## 2. Zone de staging (`df_stg`)

### 2.1 Source
- Lecture brute du fichier `DataCoSupplyChainDataset.csv`
- Encodage : `latin1`

### 2.2 Colonnes supprimées

| Colonne | Raison |
|------|------|
| Product Description | 100 % valeurs manquantes |
| Order Zipcode | Trop de valeurs manquantes |
| Customer Email | Donnée sensible, non analytique |
| Customer Password | Donnée sensible, hors périmètre |

### 2.3 Colonnes ajoutées

| Colonne | Règle |
|------|------|
| order_date | Conversion de `order date (DateOrders)` en datetime |
| shipping_date | Conversion de `shipping date (DateOrders)` en datetime |

**Grain** :  
1 ligne = 1 *Order Item*

---

## 3. Dimensions

### 3.1 `dim_customer`

**Grain** : 1 ligne par client

| Colonne | Source |
|------|------|
| customer_id | Customer Id |
| fname | Customer Fname |
| lname | Customer Lname |
| segment | Customer Segment |
| country | Customer Country |
| city | Customer City |
| state | Customer State |
| street | Customer Street |
| zipcode | Customer Zipcode |

**Règle** :
- `drop_duplicates` sur `Customer Id`

---

### 3.2 `dim_product`

**Grain** : 1 ligne par produit

| Colonne | Source |
|------|------|
| product_id | Product Card Id |
| product_name | Product Name |
| category_id | Category Id |
| category_name | Category Name |
| department_id | Department Id |
| department_name | Department Name |
| product_category_id | Product Category Id |
| base_price | Product Price |

**Règle** :
- `drop_duplicates` sur `Product Card Id`

---

### 3.3 `dim_time`

**Grain** : 1 ligne par date de commande

| Colonne | Règle |
|------|------|
| date_id | `YYYYMMDD` dérivé de `order_date` |
| order_date | Date normalisée (00:00:00) |
| year | Année |
| month | Mois |
| day | Jour |

**Règle** :
- `drop_duplicates` sur `order_date`

---

### 3.4 `dim_location`

**Grain** : combinaison géographique

| Colonne | Source |
|------|------|
| location_id | Surrogate key (index + 1) |
| Customer Country | Customer Country |
| Customer City | Customer City |
| Order City | Order City |
| Order Region | Order Region |
| Market | Market |
| Latitude | Latitude |
| Longitude | Longitude |

---

### 3.5 `dim_shipping`

**Grain** : combinaison logistique

| Colonne | Source |
|------|------|
| shipping_id | Surrogate key (index + 1) |
| Shipping Mode | Shipping Mode |
| Delivery Status | Delivery Status |
| Late_delivery_risk | Late_delivery_risk |

---

## 4. Table de faits `fact_orders`

### 4.1 Grain

1 ligne = 1 *Order Item*

### 4.2 Clés

| Colonne | Source |
|------|------|
| order_item_id | Order Item Id |
| order_id | Order Id |
| customer_id | Order Customer Id |
| product_id | Product Card Id |
| order_date | order_date |
| date_id | Jointure avec `dim_time` |

---

### 4.3 Attributs descriptifs

| Colonne |
|------|
| order_city |
| order_region |
| market |
| shipping_mode |
| delivery_status |
| late_delivery_risk |

---

### 4.4 Mesures

| Colonne | Source |
|------|------|
| quantity | Order Item Quantity |
| unit_price | Order Item Product Price |
| discount_amount | Order Item Discount |
| discount_rate | Order Item Discount Rate |
| line_total | Order Item Total |
| sales | Sales |
| order_benefit | Benefit per order |
| order_profit | Order Profit Per Order |
| days_shipping_real | Days for shipping (real) |
| days_shipping_sched | Days for shipment (scheduled) |

---

### 4.5 Mesures dérivées

| Colonne | Règle |
|------|------|
| delay_days | days_shipping_real − days_shipping_sched |
| margin_ratio | order_profit / sales si sales > 0 |

---

## 5. Contrôles qualité ETL

| Check | Description |
|------|------|
| Volume | `len(fact_orders) == len(df_stg)` |
| Clients | Tous les `customer_id` existent dans `dim_customer` |
| Produits | Tous les `product_id` existent dans `dim_product` |

En cas d’échec, l’ETL s’arrête via `assert`.

---

## 6. Sorties du pipeline

Fichiers générés dans `data/processed/` :

- `dim_customer.csv`
- `dim_product.csv`
- `dim_time.csv`
- `dim_location.csv`
- `dim_shipping.csv`
- `fact_orders.csv`