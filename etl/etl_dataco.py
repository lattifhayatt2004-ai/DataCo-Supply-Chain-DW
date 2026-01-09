import pandas as pd
from pathlib import Path

BASE_DIR = Path(__file__).resolve().parent.parent
RAW_DIR = BASE_DIR/"data"/"raw"
PROCESSED_DIR = BASE_DIR/"data"/"processed"
PROCESSED_DIR.mkdir(parents=True, exist_ok=True)

def load_raw() :
    path= RAW_DIR / "DataCoSupplyChainDataset.csv"
    df = pd.read_csv(path, encoding='latin1')
    return df

def build_staging(df: pd.DataFrame) -> pd.DataFrame:
    cols_to_drop = [
        "Product Description",
        "Order Zipcode",
        "Customer Email",
        "Customer Password",
    ]
    df_stg= df.drop(columns=cols_to_drop, errors="ignore")
    
    df_stg['order_date'] = pd.to_datetime(df_stg['order date (DateOrders)'], errors='coerce', infer_datetime_format=True,)
    df_stg["shipping_date"] = pd.to_datetime(df_stg["shipping date (DateOrders)"], errors='coerce', infer_datetime_format=True,)
    return df_stg

def build_dim_customer(df_stg: pd.DataFrame) -> pd.DataFrame:
   dim_customer = (
       df_stg[[
           "Customer Id",
           "Customer Fname",
           "Customer Lname",
           "Customer Segment",
           "Customer Country",
           "Customer City",
           "Customer State",
           "Customer Street",
           "Customer Zipcode",
       ]]
       .drop_duplicates(subset=["Customer Id"])
       .rename(columns={
              "Customer Id": "customer_id",
              "Customer Fname": "fname",
              "Customer Lname": "lname",
              "Customer Segment": "segment",
              "Customer Country": "country",
              "Customer City": "city",
              "Customer State": "state",
              "Customer Street": "street",
              "Customer Zipcode": "zipcode",
       })
   )
   return dim_customer

def build_dim_product(df_stg: pd.DataFrame) -> pd.DataFrame:
    dim_product = (
        df_stg[[
            "Product Card Id",
            "Product Name",
            "Category Id",
            "Category Name",
            "Department Id",
            "Department Name",
            "Product Category Id",
            "Product Price",
        ]]
        .drop_duplicates(subset=["Product Card Id"])
        .rename(columns={
            "Product Card Id": "product_id",
            "Product Name": "product_name",
            "Category Id": "category_id",
            "Category Name": "category_name",
            "Department Id": "department_id",
            "Department Name": "department_name",
            "Product Category Id": "product_category_id",
            "Product Price": "base_price",
        })
        .reset_index(drop=True)
    )
    return dim_product

def build_dim_time(df_stg):
    # Extraire seulement la partie DATE (sans heure) mais garder en datetime
    time_order = df_stg[["order_date"]].dropna().copy()
    time_order["order_date"] = pd.to_datetime(time_order["order_date"]).dt.normalize()  # minuit
    
    # Supprimer les doublons (un seul enregistrement par date unique)
    time_order = time_order.drop_duplicates(subset=["order_date"]).sort_values("order_date")
    
    # Créer les colonnes dérivées
    time_order["date_id"] = time_order["order_date"].dt.strftime("%Y%m%d").astype(int)
    time_order["year"] = time_order["order_date"].dt.year
    time_order["month"] = time_order["order_date"].dt.month
    time_order["day"] = time_order["order_date"].dt.day
    
    # Garder seulement les colonnes finales
    dim_time = time_order[["date_id", "order_date", "year", "month", "day"]].reset_index(drop=True)
    
    return dim_time


def build_dim_location(df_stg: pd.DataFrame) -> pd.DataFrame:
    dim_location = (
        df_stg[[
            "Customer Country",
            "Customer City",
            "Order City",
            "Order Region",
            "Market",
            "Latitude",
            "Longitude",
        ]]
    .drop_duplicates()
    .reset_index(drop=True)
    )
    dim_location["location_id"]= dim_location.index + 1
    dim_location = dim_location[[
        "location_id",
        "Customer Country",
        "Customer City",
        "Order City",
        "Order Region",
        "Market",
        "Latitude",
        "Longitude",
    ]]
    return dim_location

def build_dim_shipping(df_stg):
    dim_shipping = (
        df_stg[[
            "Shipping Mode",
            "Delivery Status",
            "Late_delivery_risk",
        ]]
        .drop_duplicates()
        .reset_index(drop=True)
    )
    dim_shipping["shipping_id"] = dim_shipping.index + 1
    dim_shipping = dim_shipping[[
        "shipping_id",
        "Shipping Mode",
        "Delivery Status",
        "Late_delivery_risk",
    ]]
    return dim_shipping

def build_fact_orders(df_stg, dim_time):
    fact = df_stg[[
        "Order Item Id",
        "Order Id",
        "Order Customer Id",
        "Product Card Id",
        "order_date",
        "shipping_date",
        "Order City",
        "Order Region",
        "Market",
        "Shipping Mode",
        "Delivery Status",
        "Late_delivery_risk",
        "Order Item Quantity",
        "Order Item Product Price",
        "Order Item Discount",
        "Order Item Discount Rate",
        "Order Item Total",
        "Sales",
        "Benefit per order",
        "Order Profit Per Order",
        "Days for shipping (real)",
        "Days for shipment (scheduled)",
    ]].rename(columns={
        "Order Item Id": "order_item_id",
        "Order Id": "order_id",
        "Order Customer Id": "customer_id",
        "Product Card Id": "product_id",
        "Order City": "order_city",
        "Order Region": "order_region",
        "Market": "market",                              # ← AJOUTER
        "Shipping Mode": "shipping_mode",                # ← AJOUTER
        "Delivery Status": "delivery_status",            # ← AJOUTER
        "Late_delivery_risk": "late_delivery_risk",      # ← garder tel quel
        "Order Item Quantity": "quantity",
        "Order Item Product Price": "unit_price",
        "Order Item Discount": "discount_amount",
        "Order Item Discount Rate": "discount_rate",
        "Order Item Total": "line_total",
        "Sales": "sales",                                # ← AJOUTER
        "Benefit per order": "order_benefit",
        "Order Profit Per Order": "order_profit",
        "Days for shipping (real)": "days_shipping_real",
        "Days for shipment (scheduled)": "days_shipping_sched",
    })

    # NORMALISER order_date
    fact["order_date"] = pd.to_datetime(fact["order_date"]).dt.normalize()
    
    # join avec dim_time
    fact = fact.merge(
        dim_time[["date_id", "order_date"]],
        on="order_date",
        how="left"
    )

    # mesures dérivées
    fact["delay_days"] = fact["days_shipping_real"] - fact["days_shipping_sched"]
    fact["margin_ratio"] = fact.apply(
        lambda row: row["order_profit"] / row["sales"]
        if row["sales"] not in (0, None)
        else None,
        axis=1
    )
    
    return fact

def main():
    df = load_raw()
    df_stg = build_staging(df)

    dim_customer = build_dim_customer(df_stg)
    dim_product = build_dim_product(df_stg)
    dim_time = build_dim_time(df_stg)
    dim_location = build_dim_location(df_stg)
    dim_shipping = build_dim_shipping(df_stg)
    fact_orders = build_fact_orders(df_stg, dim_time)
    
    # === CHECKS QUALITE ===
    assert len(fact_orders) == len(df_stg)
    assert fact_orders["customer_id"].isin(dim_customer["customer_id"]).all
    assert fact_orders["product_id"].isin(dim_product["product_id"]).all()

    dim_customer.to_csv(PROCESSED_DIR / "dim_customer.csv", index=False)
    dim_product.to_csv(PROCESSED_DIR / "dim_product.csv", index=False)
    dim_time.to_csv(PROCESSED_DIR / "dim_time.csv", index=False)
    dim_location.to_csv(PROCESSED_DIR / "dim_location.csv", index=False)
    dim_shipping.to_csv(PROCESSED_DIR / "dim_shipping.csv", index=False)
    fact_orders.to_csv(PROCESSED_DIR / "fact_orders.csv", index=False)

if __name__ == "__main__":
    main()