-- ========================================
-- Script de chargement des données DataCo
-- depuis les CSV processed vers PostgreSQL
-- ========================================

-- IMPORTANT : À exécuter depuis psql en ligne de commande
-- cd C:\Users\HP\Documents\Projets\Supply_Chain_ETL_DW_Power_BI\data\processed
-- psql -U postgres -d dataco_dw

-- 1. Vider les tables existantes (ordre : fact avant dims à cause des FK)
TRUNCATE TABLE fact_orders CASCADE;
TRUNCATE TABLE dim_time, dim_customer, dim_product, dim_location, dim_shipping CASCADE;

-- 2. Charger les dimensions (ordre important)

\copy dim_time(date_id, order_date, year, month, day) FROM 'dim_time.csv' DELIMITER ',' CSV HEADER;

\copy dim_customer(customer_id, fname, lname, segment, country, city, state, street, zipcode) FROM 'dim_customer.csv' DELIMITER ',' CSV HEADER;

\copy dim_product(product_id, product_name, category_id, category_name, department_id, department_name, product_category_id, base_price) FROM 'dim_product.csv' DELIMITER ',' CSV HEADER;

\copy dim_location(location_id, customer_country, customer_city, order_city, order_region, market, latitude, longitude) FROM 'dim_location.csv' DELIMITER ',' CSV HEADER;

\copy dim_shipping(shipping_id, shipping_mode, delivery_status, late_delivery_risk) FROM 'dim_shipping.csv' DELIMITER ',' CSV HEADER;

-- 3. Charger la table de faits (en dernier)

\copy fact_orders(order_item_id, order_id, customer_id, product_id, order_date, shipping_date, order_city, order_region, market, 
                  shipping_mode, delivery_status, late_delivery_risk, quantity, unit_price, discount_amount, discount_rate, line_total, 
                  sales, order_benefit, order_profit, days_shipping_real, days_shipping_sched, date_id, delay_days, margin_ratio) 
                  FROM 'fact_orders.csv' DELIMITER ',' CSV HEADER;

-- 4. Vérification des chargements

SELECT 'dim_time' AS table_name, COUNT(*) AS row_count FROM dim_time
UNION ALL
SELECT 'dim_client', COUNT(*) FROM dim_client
UNION ALL
SELECT 'dim_produit', COUNT(*) FROM dim_produit
UNION ALL
SELECT 'dim_localisation', COUNT(*) FROM dim_localisation
UNION ALL
SELECT 'dim_shipping', COUNT(*) FROM dim_shipping
UNION ALL
SELECT 'fact_orders', COUNT(*) FROM fact_orders;

-- 5. Test des relations (optionnel)

SELECT 
    f.order_item_id,
    t.order_date,
    t.year,
    t.month,
    f.sales,
    f.order_profit,
    f.delay_days
FROM fact_orders f
JOIN dim_time t ON f.date_id = t.date_id
LIMIT 10;
