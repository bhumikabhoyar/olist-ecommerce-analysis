"""Rebuild the Olist analysis database end to end.
 
Steps: drop views -> load 9 CSVs -> build views -> run data checks -> write KPI table.
 
Usage (from the project root, with the CSVs in data/):
    set PGPASSWORD=your_password      (Windows; or type it when prompted)
    python run_pipeline.py
"""
import logging
import os
import sys
from getpass import getpass
from urllib.parse import quote_plus
 
import pandas as pd
from sqlalchemy import create_engine, text
 
logging.basicConfig(level=logging.INFO, format="%(asctime)s %(levelname)s %(message)s")
log = logging.getLogger("olist")
 
DATA_DIR = "data"
SQL_DIR = "sql"
 
# Dependents first, so DROP works even when views depend on each other.
VIEWS = ["order_distance", "fact_items", "fact_orders", "fact_sales",
         "reviews_dedup", "orders_clean", "geo_zip"]
 
EXPECTED_ROWS = {"orders": 99441, "customers": 99441, "order_items": 112650,
                 "order_reviews": 99224, "sellers": 3095, "products": 32951}
 
CHECKS = {
    "order_id is unique": "SELECT COUNT(*) = COUNT(DISTINCT order_id) FROM orders",
    "no orphan order items": """
        SELECT COUNT(*) = 0 FROM order_items oi
        LEFT JOIN orders o ON o.order_id = oi.order_id
        WHERE o.order_id IS NULL""",
    "orders_clean is not empty": "SELECT COUNT(*) > 0 FROM orders_clean",
    "one review per order": "SELECT COUNT(*) = COUNT(DISTINCT order_id) FROM reviews_dedup",
    "total revenue is 13.18M": "SELECT ROUND((SUM(price) / 1000000.0)::numeric, 2) = 13.18 FROM fact_sales",
}
 
 
def get_engine():
    password = quote_plus(os.environ.get("PGPASSWORD") or getpass("Postgres password: "))
    return create_engine(f"postgresql+psycopg2://postgres:{password}@localhost:5432/olist")
 
 
def load_tables(engine):
    with engine.begin() as con:
        for view in VIEWS:
            con.execute(text(f"DROP VIEW IF EXISTS {view} CASCADE"))
    for name in sorted(os.listdir(DATA_DIR)):
        if not name.endswith(".csv"):
            continue
        table = name.replace("olist_", "").replace("_dataset", "").replace(".csv", "")
        df = pd.read_csv(os.path.join(DATA_DIR, name))
        if table in EXPECTED_ROWS and len(df) != EXPECTED_ROWS[table]:
            raise ValueError(f"{table}: expected {EXPECTED_ROWS[table]} rows, got {len(df)}")
        df.to_sql(table, engine, if_exists="replace", index=False, chunksize=10000)
        log.info("loaded %s: %d rows", table, len(df))
 
 
def build_views(engine):
    path = os.path.join(SQL_DIR, "build_views.sql")
    with open(path, encoding="utf-8") as fh:
        sql = fh.read()
    with engine.begin() as con:
        con.exec_driver_sql(sql)
    log.info("views built from %s", path)
 
 
def run_checks(engine):
    failed = []
    with engine.connect() as con:
        for label, query in CHECKS.items():
            ok = con.execute(text(query)).scalar()
            log.info("check %-28s %s", label, "PASS" if ok else "FAIL")
            if not ok:
                failed.append(label)
    if failed:
        raise RuntimeError(f"data checks failed: {failed}")
 
 
def build_kpi_table(engine):
    with engine.begin() as con:
        con.execute(text("DROP TABLE IF EXISTS kpi_monthly"))
        con.execute(text("""
            CREATE TABLE kpi_monthly AS
            SELECT DATE_TRUNC('month', purchased_at)::date AS month,
                   COUNT(DISTINCT order_id) AS orders,
                   ROUND(SUM(price)::numeric, 0) AS revenue,
                   ROUND((SUM(price) / COUNT(DISTINCT order_id))::numeric, 2) AS aov,
                   ROUND((100 * SUM(freight_value) / SUM(price))::numeric, 1) AS freight_pct
            FROM fact_sales
            GROUP BY 1
            ORDER BY 1
        """))
    log.info("kpi_monthly table written")
 
 
def main():
    engine = get_engine()
    load_tables(engine)
    build_views(engine)
    run_checks(engine)
    build_kpi_table(engine)
    log.info("pipeline finished OK")
 
 
if __name__ == "__main__":
    try:
        main()
    except Exception:
        log.exception("pipeline failed")
        sys.exit(1)
 