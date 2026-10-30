# Olist E-commerce: Business Performance Analysis

**Business question:** Revenue growth stalled in 2018. Where is the business losing value, why, and what should it fix first?

Built with PostgreSQL, Python (pandas, SciPy, statsmodels) and Power BI.
Author: Bhumika Bhoyar | [GitHub](https://github.com/bhumikabhoyar) | [LinkedIn](https://linkedin.com/in/bhumika-bhoyar07)

---

## Dashboard

| Executive summary | Why it fell |
|---|---|
| ![Executive summary](docs/page1_executive_summary.png) | ![Why it fell](docs/page2_why_it_fell.png) |

| Delivery impact | Recommendations |
|---|---|
| ![Delivery impact](docs/page3_delivery_impact.png) | ![Recommendations](docs/page4_recommendations.png) |

---

## Dataset

[Olist Brazilian E-Commerce Public Dataset](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce) (Kaggle): 9 tables, about 100k real orders from 2016 to 2018. Amounts are in Brazilian reais.

**Scope of the analysis:** delivered orders from Jan 2017 to Aug 2018 (96,211 orders, about 13.18M revenue). Revenue is defined as item price; freight is tracked separately.

---

## Method

1. **Data quality checks (SQL):** row counts, duplicate keys, orphan records, order status mix, null dates, date range, price sanity.
2. **Cleaning decisions**
   - Excluded Sep-Dec 2016 and Sep-Oct 2018: near-empty months, not real collapses.
   - Counted revenue for delivered orders only (97% of orders).
   - Kept the 547 orders with several reviews by keeping the latest review per order, so joins do not duplicate revenue.
   - Kept high-priced items (max 6,735) because they look genuine; reported median next to mean (mean 119.96, median 74.90).
3. **Analysis (SQL):** monthly KPIs, MoM growth, category volume vs price, new vs returning customers, late delivery by state.
4. **Statistics (Python):** Welch t-test and Mann-Whitney on review scores, confidence interval, Cohen's d, a within-state check for Simpson's paradox, and a two-proportion z-test on repeat purchase.
5. **Dashboard (Power BI + DAX):** star-style model with an order-level fact table and an item-level fact table.

---

## Key findings

1. **Growth stalled in 2018.** Revenue is up about 51% year over year (Aug 2018 vs Aug 2017) but has been flat or falling month to month since April 2018 (peak 978k in May 2018, 839k in Aug 2018).
2. **Black Friday distorted late 2017.** Nov 2017 had 7,289 orders, then revenue fell 26.5% in December, so demand was pulled forward.
3. **The Jun-Aug 2018 dip tracks fewer new customers.** Compared with Jan-May 2018, new customers fell about 9% (6,600 to 5,990 per month) and revenue fell about 8% (931k to 854k per month).
4. **The decline is concentrated in a few categories.** computers_accessories, sports_leisure and cool_stuff lost the most revenue, mainly through fewer orders rather than lower prices.
5. **Late deliveries hurt reviews badly.** About 8% of delivered orders arrive late (about 1.16M revenue). Late orders average 2.57 stars vs 4.29 on time (difference -1.73, 95% CI -1.77 to -1.69, Cohen's d -1.45, p < 0.001). The gap holds inside SP, MG, RJ and BA.
6. **Retention is very low.** Only about 3% of customers order again. Customers whose first order was late repeat less (3.17% vs 4.04%, p = 0.005). Repeat customers spend about 1.9x more (260 vs 138).

---

## Recommendations

1. **Win back new customers.** Review acquisition channels and campaigns for Jun-Aug 2018, starting with the three categories above. Track new customers per month and orders per category.
2. **Reduce late deliveries, starting with Rio de Janeiro.** RJ has about 12,300 orders and a 13.5% late rate. Track Late % and average review in RJ.
3. **Run a small repeat-purchase test** on first-time customers with a control group. Even one extra point of repeat rate adds under 1% to revenue, so test before scaling. Track 90-day repeat rate.

---

## Limitations

- No cost, discount or marketing data, so true profit and the reason new customers fell cannot be measured.
- Late delivery and review score are associated; other factors (distance, category, seller) may also play a part.
- Only one earlier year of data, so seasonality cannot be fully separated from trend.
- Recent months may understate late rates because slow orders may not be delivered yet.

---

## Repository structure

```
olist-ecommerce-analysis/
├── sql/          numbered scripts, 01 to 08 (quality checks, clean views, KPIs, analysis, Power BI views)
├── notebooks/    01_load_data.ipynb, 02_statistics.ipynb
├── powerbi/      dashboard.pbix
├── docs/         dashboard screenshots
└── data/         raw CSVs (not committed, download from Kaggle)
```

## How to run

1. Download the dataset from Kaggle into `data/`.
2. Create a PostgreSQL database named `olist`.
3. Set your password: `set PGPASSWORD=your_password` (Windows), or type it when prompted.
4. Run `notebooks/01_load_data.ipynb` to load the 9 tables.
5. Run the SQL scripts in `sql/` in numbered order.
6. Run `notebooks/02_statistics.ipynb`.
7. Open `powerbi/dashboard.pbix` and point it to your local PostgreSQL.
