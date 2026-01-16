-- Création des tables du Data Warehouse DataCo (schéma en étoile)

-- Dimension Temps
CREATE TABLE dim_time (
    date_id     INT PRIMARY KEY,
    order_date  DATE NOT NULL,
    year        INT,
    month       INT,
    day         INT
);

-- Dimension Client
CREATE TABLE dim_customer (
    customer_id INT PRIMARY KEY,
    fname       VARCHAR(100),
    lname       VARCHAR(100),
    segment     VARCHAR(100),
    country     VARCHAR(100),
    city        VARCHAR(100),
    state       VARCHAR(100),
    street      VARCHAR(255),
    zipcode     VARCHAR(20)
);

-- Dimension Produit
CREATE TABLE dim_product (
    product_id          INT PRIMARY KEY,
    product_name        VARCHAR(255),
    category_id         INT,
    category_name       VARCHAR(100),
    department_id       INT,
    department_name     VARCHAR(100),
    product_category_id INT,
    base_price          NUMERIC(10, 2)
);

-- Dimension Localisation (côté commande)
CREATE TABLE dim_location (
    location_id   INT PRIMARY KEY,
    order_city    VARCHAR(100),
    order_region  VARCHAR(100),
    market        VARCHAR(100),
    latitude      NUMERIC(10, 6),
    longitude     NUMERIC(10, 6)
);

-- Dimension Expédition
CREATE TABLE dim_shipping (
    shipping_id        INT PRIMARY KEY,
    shipping_mode      VARCHAR(100),
    delivery_status    VARCHAR(100),
    late_delivery_risk INT
);

-- Table de faits Orders
CREATE TABLE fact_orders (
    order_item_id       INT PRIMARY KEY,
    order_id            INT,
    customer_id         INT,
    product_id          INT,
    order_date          TIMESTAMP,
    shipping_date       TIMESTAMP,
    order_city          VARCHAR(100),
    order_region        VARCHAR(100),
    market              VARCHAR(100),
    shipping_mode       VARCHAR(100),
    delivery_status     VARCHAR(100),
    late_delivery_risk  INT,
    quantity            INT,
    unit_price          NUMERIC(10,2),
    discount_amount     NUMERIC(10,2),
    discount_rate       NUMERIC(5,2),
    line_total          NUMERIC(12,2),
    sales               NUMERIC(12,2),
    order_benefit       NUMERIC(12,2),
    order_profit        NUMERIC(12,2),
    days_shipping_real  INT,
    days_shipping_sched INT,
    date_id             INT,
    delay_days          INT,
    margin_ratio        NUMERIC(5,4),

    -- Clés étrangères principales
    CONSTRAINT fk_fact_customer
        FOREIGN KEY (customer_id) REFERENCES dim_customer(customer_id),
    CONSTRAINT fk_fact_product
        FOREIGN KEY (product_id) REFERENCES dim_product(product_id),
    CONSTRAINT fk_fact_time
        FOREIGN KEY (date_id) REFERENCES dim_time(date_id)
);
