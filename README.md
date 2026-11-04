# Spice Villa Restaurant Analytics

**End-to-end restaurant sales analysis: Excel (data cleaning) → PostgreSQL (analytics) → Power BI (visualization)**

![Excel](https://img.shields.io/badge/Excel-Data%20Cleaning-217346?logo=microsoft-excel&logoColor=white)
![PostgreSQL](https://img.shields.io/badge/PostgreSQL-Analytics-336791?logo=postgresql&logoColor=white)
![Power BI](https://img.shields.io/badge/Power%20BI-Dashboard-F2C811?logo=powerbi&logoColor=black)

---

## 📌 Project Overview

Spice Villa is a restaurant whose sales were recorded as raw order-level data covering **two years (Jan 2022 – Dec 2023)**. This project turns that raw data into decisions: which menu categories and items drive revenue, how sales are trending month over month and year over year, which customers matter most, how customers pay, and which days of the week are busiest.

The workflow mirrors a real analyst pipeline:

| Stage | Tool | Purpose |
|-------|------|---------|
| 1. Clean & prepare | **Excel** | Standardise the raw sales data and add date-derived fields |
| 2. Analyse | **PostgreSQL** | Answer business questions with SQL (aggregations, window functions) |
| 3. Visualise | **Power BI** | Build an interactive 3-page dashboard with DAX measures |

---

## 🎯 Business Questions

1. What are the restaurant's headline KPIs (revenue, orders, items sold, customers, average order value)?
2. Which menu **categories** and **items** generate the most revenue?
3. How is revenue changing **month over month** and **year over year**?
4. Who are the **highest-value customers**?
5. How do customers **pay**, and how much data is missing for payment method?
6. Which **days of the week** are the busiest?

---

## 📂 Dataset

**File:** `spice_data.csv` | **Rows:** 15,776 | **Columns:** 13 | **Period:** 01-Jan-2022 to 31-Dec-2023

| Column | Description |
|--------|-------------|
| `Order ID` | Unique order identifier (primary key) |
| `Customer ID` | Customer identifier (100 unique customers) |
| `Category` | Menu category (Starters, Main Dishes, Side Dishes, Desserts, Drinks) |
| `Item` | Menu item (26 unique items) |
| `Price` | Unit price of the item |
| `Quantity` | Units ordered (1–5) |
| `Order Total` | Order value |
| `Order Date` | Date of order (`dd-mm-yyyy`) |
| `Payment Method` | Cash, Credit Card or Digital Wallet (524 blanks) |
| `Year`, `Month`, `Quarter`, `Day Name` | Date-derived fields |

---

## 🧹 Step 1: Data Cleaning in Excel

- Reviewed the raw file for duplicates, data types and blank values (**0 duplicate orders** found)
- Standardised column headers and formats
- Converted `Order Date` to a consistent `dd-mm-yyyy` date format
- Created the date-derived columns: **Year, Month, Day Name, Quarter**
- Checked `Payment Method`: **524 blank values (3.3%)** were kept and flagged rather than guessed, then handled explicitly in SQL (see query 7)
- Exported the cleaned sheet as `spice_data.csv` for loading into PostgreSQL

> **Data note:** In 874 rows, `Price × Quantity` differs from `Order Total` by 1–2 units (for example Coca Cola: price 3, quantity 4, total 10). This looks like the displayed unit price is rounded (about 2.5), so `Order Total` is treated as the source of truth for all revenue figures.

---

## 🗄️ Step 2: Analysis in PostgreSQL

The full script is in [`spice_villa.sql`](spice_villa.sql).

### Schema

```sql
create table spice_orders (
    order_id       varchar(20) primary key,
    customer_id    varchar(20) not null,
    category       varchar(50) not null,
    item           varchar(100) not null,
    price          numeric(10, 2) not null,
    quantity       int not null check (quantity > 0),
    order_total    numeric(10, 2) not null,
    order_date     date not null,
    payment_method varchar(50),
    year           int not null,
    month          int not null,
    day_name       varchar(15) not null,
    quarter        int not null
);
```

### Queries

| # | Analysis | SQL concepts used |
|---|----------|-------------------|
| 1 | Key business KPIs | `SUM`, `COUNT(DISTINCT)`, `AVG`, `ROUND` |
| 2 | Category-wise revenue, orders, items sold, AOV | `GROUP BY`, `ORDER BY` |
| 3 | Top 5 menu items by revenue | `GROUP BY`, `LIMIT` |
| 4 | Month-over-Month (MoM) growth | `LAG()` window function, `NULLIF` |
| 5 | Year-over-Year (YoY) growth | `LAG(…, 12)`, `NULLIF` |
| 6 | Top 10 high-value customers | Aggregation, ranking by spend |
| 7 | Payment method preference and missing-value impact | `COALESCE`, subquery for % share |
| 8 | Day-of-week peak analysis | `GROUP BY`, `AVG` |

---

## 📊 Step 3: Visualization in Power BI

The dashboard ([`spice_villa_dashboard.pbix`](spice_villa_dashboad.pbix)) has **3 pages**, with **Year** and **Month** slicers for interactive filtering and a custom Spice Villa brown/cream theme.

| Page | What it shows |
|------|---------------|
| **1. Exec Dashboard** (Revenue & Performance) | KPI cards, monthly revenue trend (column + line combo), payment method split (donut), day-by-month revenue matrix |
| **2. Menu Insights** | Revenue by category (treemap), item-level revenue vs. price (scatter), category/item breakdown table, average item price, category revenue share % |
| **3. Operations & Channel Dynamics** | Item revenue (combo chart), category revenue split (donut), payment method by category (column), order volume by day of week |

**Data model:** `spice_villa_data` (fact table) + a `Date` calendar table.

**Key DAX measures:** `Total Revenue`, `Total Orders Count`, `Total Quantity Sold`, `Average Order Value`, `Average Item Price`, `Category Revenue Share %`

### Dashboard Preview

> Add your screenshots to the `images/` folder and update the paths below.

| Exec Dashboard | Menu Insights | Operations & Channel Dynamics |
|:---:|:---:|:---:|
| ![Exec](images/exec_dashboard.png) | ![Menu](images/menu_insights.png) | ![Ops](images/operations.png) |

---

## 🔑 Key Findings

| Metric | Value |
|--------|-------|
| Total revenue | **315,007** |
| Total orders | **15,776** |
| Total items sold | **47,574** |
| Unique customers | **100** |
| Average order value | **19.97** |

**Insights**

- 🍽️ **Main Dishes are the revenue engine**, contributing about **47%** of total revenue (148,144), far ahead of Starters (17.8%), Desserts (16.7%), Side Dishes (11.8%) and Drinks (6.7%).
- 🏆 **Top 5 items by revenue:** Grilled Chicken (37,380), Pasta Alfredo (37,128), Steak (35,320), Salmon (22,608) and Vegetarian Platter (15,708). Three mains alone are close to a third of all revenue.
- 📉 **Revenue declined year over year:** 161,142 in 2022 vs 153,865 in 2023, a drop of about **4.5%**.
- 📅 **Seasonality is mild.** Q2 is the strongest quarter (81,603), Q4 the weakest (76,579). Highest month: March 2022 (14,853); lowest: February 2023 (11,475).
- 💳 **Payment mix is almost perfectly even** (Credit Card ≈ Cash ≈ Digital Wallet ≈ 32% each), and **3.3% of orders (524) have no payment method recorded**, a data-capture gap worth fixing at the POS.
- 📆 **Sunday is the top revenue day** (45,967) and Wednesday the lowest (43,706). The gap between best and worst day is only about 5%, so demand is steady across the week.
- 👥 **Customer spend is evenly spread:** the top customers (CUST_020 and CUST_093) each spent 3,811, only modestly above the average of about 3,150 per customer, so revenue is not dependent on a few big spenders.

**Recommendations**

1. Protect and promote Main Dishes, and use bundles to lift Drinks (only ~6.7% of revenue) as add-ons.
2. Investigate the 2023 decline by month and category, and run targeted campaigns in the weaker months (Feb, Nov).
3. Use a mid-week offer (Wednesday) to flatten the lowest day.
4. Make payment method a mandatory POS field to eliminate missing values.
5. Launch a loyalty programme for the whole customer base rather than a small VIP segment, since spend is evenly distributed.

---

## 🛠️ How to Run

1. **Clone the repo**
   ```bash
   git clone https://github.com/<your-username>/spice-villa-restaurant-analytics.git
   ```
2. **PostgreSQL:** create a database, open `sql/spice_villa.sql` in pgAdmin or psql, and update the `COPY` path to where `spice_data.csv` is saved on your machine:
   ```sql
   copy spice_orders(order_id, customer_id, category, item, price, quantity,
                     order_total, order_date, payment_method, year, month, day_name, quarter)
   from '<your-path>/spice_data.csv' delimiter ',' csv header;
   ```
   Then run the queries section by section. The script sets `datestyle = 'ISO, DMY'` so the `dd-mm-yyyy` dates load correctly.
3. **Power BI:** open `powerbi/spice_villa_dashboard.pbix` in Power BI Desktop. If prompted, refresh or re-point the data source to `data/spice_data.csv`.

---

## 📁 Repository Structure

```
spice-villa-restaurant-analytics/
│
├── data/
│   └── spice_data.csv
├── sql/
│   └── spice_villa.sql
├── powerbi/
│   └── spice_villa_dashboard.pbix
├── images/
│   ├── exec_dashboard.png
│   ├── menu_insights.png
│   └── operations.png
└── README.md
```

---

## 🧰 Skills Demonstrated

- **Excel:** data cleaning, validation, date-field engineering
- **SQL (PostgreSQL):** schema design with constraints, aggregations, window functions (`LAG`), `COALESCE`/`NULLIF`, subqueries
- **Power BI:** data modelling, DAX measures, interactive multi-page dashboard design, slicers, KPI cards
- **Analytics:** KPI definition, trend (MoM/YoY) analysis, customer and menu analysis, turning findings into recommendations

---

## 👤 Author

**<Your Name>**
BBA graduate (GGSIPU, 2022–25) transitioning into data analytics
🔗 [LinkedIn](https://linkedin.com/in/<your-profile>) | 💻 [GitHub](https://github.com/<your-username>)

⭐ If you found this project useful, consider giving it a star!
