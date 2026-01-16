-- 1. Vider les tables existantes (fact avant dims)
TRUNCATE TABLE fact_orders CASCADE;
TRUNCATE TABLE dim_time, dim_customer, dim_product, dim_location, dim_shipping CASCADE;

-- 2. Charger les dimensions

\copy dim_time(date_id, order_date, year, month, day)
  FROM 'dim_time.csv' DELIMITER ',' CSV HEADER;

\copy dim_customer(customer_id, fname, lname, segment, country, city, state, street, zipcode)
  FROM 'dim_customer.csv' DELIMITER ',' CSV HEADER;

\copy dim_product(product_id, product_name, category_id, category_name, department_id, department_name, product_category_id, base_price)
  FROM 'dim_product.csv' DELIMITER ',' CSV HEADER;

\copy dim_location(location_id, customer_country, customer_city, order_city, order_region, market, latitude, longitude)
  FROM 'dim_location.csv' DELIMITER ',' CSV HEADER;

\copy dim_shipping(shipping_id, shipping_mode, delivery_status, late_delivery_risk)
  FROM 'dim_shipping.csv' DELIMITER ',' CSV HEADER;

-- 3. Charger la fact

\copy fact_orders(
    order_item_id, order_id, customer_id, product_id,
    order_date, shipping_date,
    order_city, order_region, market,
    shipping_mode, delivery_status, late_delivery_risk,
    quantity, unit_price, discount_amount, discount_rate, line_total,
    sales, order_benefit, order_profit,
    days_shipping_real, days_shipping_sched,
    date_id, delay_days, margin_ratio
) FROM 'fact_orders.csv' DELIMITER ',' CSV HEADER;

-- 4. Vérification des chargements

SELECT 'dim_time' AS table_name, COUNT(*) AS row_count FROM dim_time
UNION ALL
SELECT 'dim_customer', COUNT(*) FROM dim_customer
UNION ALL
SELECT 'dim_product', COUNT(*) FROM dim_product
UNION ALL
SELECT 'dim_location', COUNT(*) FROM dim_location
UNION ALL
SELECT 'dim_shipping', COUNT(*) FROM dim_shipping
UNION ALL
SELECT 'fact_orders', COUNT(*) FROM fact_orders;
-- Fin du script de chargement des tables du Data Warehouse