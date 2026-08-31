# 🚖 NYC Ride-Hailing Analytics (Uber vs. Lyft)
 
![PostgreSQL](https://img.shields.io/badge/PostgreSQL-4169E1?style=for-the-badge&logo=postgresql&logoColor=white)
![Power BI](https://img.shields.io/badge/Power_BI-F2C811?style=for-the-badge&logo=powerbi&logoColor=black)
![Python](https://img.shields.io/badge/Python-3776AB?style=for-the-badge&logo=python&logoColor=white)
![Data Warehouse](https://img.shields.io/badge/Star_Schema-Data_Warehouse-success?style=for-the-badge)
 
An end-to-end Data Analytics & Engineering project analyzing **20.57M+ clean ride-hailing trips** across New York City (Uber & Lyft). The project spans raw data ingestion, advanced PostgreSQL data warehousing (Star Schema), large-scale data deduplication, and an interactive 3-page executive Power BI dashboard.
 
---
 
## 📌 Executive Summary
 
1. **Market Dominance:** Uber holds a commanding **~75% net revenue market share**, driven by high volume in Manhattan core corridors and airport hubs.
2. **Data Integrity Restored:** Identified and removed **9.25M duplicate records** via SQL Window Functions, rectifying a ~45% artificial volume inflation and restoring absolute data accuracy (20.57M clean trips).
3. **Geographic Bottlenecks:** Outer boroughs experience severe supply shortages, pushing average wait times up to **7.9 minutes in Queens** (Hammels/Arverne, JFK Airport) and **7.4 minutes in Staten Island**.
4. **Economic Disparity:** Driver earnings drop significantly on weekends (**$18.51 avg pay** vs **$20.18 on weekdays**), accompanied by lower tip rates ($1.03 vs $1.20).
---
 
## 💡 Key Business Insights & Strategic Recommendations
 
### 1. Market Dynamics & Competition
- **Insight:** Uber accounts for **74.95% of Net Revenue ($130.7M)** compared to Lyft's **25.05% ($43.7M)**. Lyft is heavily dependent on core Manhattan trips and struggles to capture market share in high-margin airport corridors.
- **Recommendation:** Lyft should launch targeted promo pricing for airport rides (JFK/LaGuardia) to disrupt Uber's dominant hold on long-distance, high-fare routes.
### 2. Operational Efficiency & Supply Allocation
- **Insight:** Passengers in outer-borough zones (Queens, Staten Island, Bronx) face **30-50% longer wait times (6.7–7.9 min)** than Manhattan riders (4.2 min), despite strong demand volume (e.g., JFK Airport with 327K+ trips).
- **Recommendation:** Implement **Zone-Based Driver Re-allocation Bonuses**. Offering a $3–$5 per-trip incentive for drivers entering high-wait zones (Queens/Staten Island) will rebalance fleet distribution and reduce churn from frustrated riders.
### 3. Pricing Strategy & Revenue Optimization
- **Insight:** The **Evening window (17:00–22:00)** generates the highest total volume (**5.88M trips, $147.4M revenue**), but **Afternoon trips (12:00–17:00)** yield the highest revenue per mile (**$5.96/mi**).
- **Recommendation:** Fine-tune **Dynamic Surge Pricing** during the 12:00–17:00 window to maximize yield per mile, while optimizing dispatch algorithms during 17:00–22:00 peak hours to handle sheer trip volume efficiently.
### 4. Driver Economics & Retention
- **Insight:** Drivers earn **8.3% less per trip on weekends** ($18.51 vs $20.18) and receive **14% lower tips** ($1.03 vs $1.20), creating potential weekend supply deficits.
- **Recommendation:** Restructure weekend commission tiers by lowering company take-rates by **2-3% on Friday/Saturday nights**. This will boost net driver take-home pay and incentivize higher driver availability during peak leisure hours.
---
 
## 🏗️ Architecture & Data Pipeline Workflow
 
```text
[ Raw TLC Data ] ──► [ Python Ingestion & Cleaning ] ──► [ PostgreSQL Data Warehouse ] ──► [ Power BI Dashboard ]
                          (29.8M Records)                 (Star Schema & SQL Cleaning)           (3-Page Executive UI)
```
 
- **Extraction & Transformation (Python):** Processed TLC High-Volume For-Hire Vehicle (HVFHV) raw records.
- **Data Warehousing (PostgreSQL):** Designed a dimensional Star Schema with `fact_trips` and supporting dimension tables (`dim_company`, `dim_zones`, `dim_date`).
- **Data Integrity & Deduplication (SQL Window Functions):** Identified and eliminated 9,250,000 duplicate rows using PostgreSQL `ctid` and `ROW_NUMBER() OVER(PARTITION BY...)`, restoring true row-count to 20,569,277.
- **Data Visualization (Power BI):** Engineered an executive 3-page interactive report with custom DAX measures, dynamic time windows, NYC Shape Map spatial integration, and UX-optimized navigation.
---
 
## 🗄️ Database Schema (Star Schema)
 
```text
                  ┌─────────────────┐
                  │   dim_company   │
                  ├─────────────────┤
                  │ PK  license_num │
                  └────────┬────────┘
                           │ 1
                           │
                           │ N
┌─────────────────┐       ┌┴───────────────────────────┐       ┌─────────────────┐
│    dim_zones    │       │        fact_trips          │       │    dim_date     │
├─────────────────┤       ├─────────────────────────────┤       ├─────────────────┤
│ PK  LocationID  │1─────N│ FK  hvfhs_license_num       │N─────1│ PK  date_key    │
└─────────────────┘       │ FK  PULocationID            │       └─────────────────┘
                          │ FK  DOLocationID            │
                          │     pickup_datetime         │
                          │     trip_miles, trip_time   │
                          │     base_passenger_fare     │
                          │     driver_pay, tips        │
                          │     company_margin          │
                          │     wait_time_minutes       │
                          └──────────────────────────────┘
```
 
---
 
## 🔍 Key Business Questions & SQL Analytics
 
### Query 1: Market Share & Net Revenue Margin
```sql
SELECT 
    c.company_name,
    COUNT(*) AS total_trips,
    ROUND(SUM(f.company_margin)::numeric, 2) AS total_net_margin,
    ROUND((COUNT(*) * 100.0) / SUM(COUNT(*)) OVER(), 2) AS trip_market_share_pct
FROM fact_trips f
JOIN dim_company c ON f.hvfhs_license_num = c.license_num
GROUP BY c.company_name
ORDER BY total_trips DESC;
```
 
**Query Output:**
 
| company_name | total_trips | total_net_margin ($) | trip_market_share_pct (%) |
|---|---|---|---|
| Uber | 15,418,291 | $130,700,000.00 | 74.95% |
| Lyft | 5,150,986 | $43,700,000.00 | 25.05% |
 
📌 **Key Takeaway:** Uber dominates the NYC ride-hailing market with a 3:1 trip ratio over Lyft, capturing 74.95% ($130.7M) of net revenue. Lyft operates primarily as a secondary market player with 25.05% market share.
 
### Query 2: Operational Bottlenecks (Top Wait Time Zones)
```sql
SELECT 
    z."Borough",
    z."Zone",
    COUNT(*) AS total_trips,
    ROUND(AVG(f.wait_time_minutes)::numeric, 1) AS avg_wait_time_min
FROM fact_trips f
JOIN dim_zones z ON f."PULocationID" = z."LocationID"
GROUP BY z."Borough", z."Zone"
HAVING COUNT(*) > 10000
ORDER BY avg_wait_time_min DESC
LIMIT 5;
```
 
**Query Output:**
 
| Borough | Zone | total_trips | avg_wait_time_min |
|---|---|---|---|
| Queens | Hammels/Arverne | 33,695 | 7.9 min |
| Queens | JFK Airport | 327,686 | 7.9 min |
| Queens | Far Rockaway | 47,286 | 7.8 min |
| Queens | Rockaway Park | 13,156 | 7.5 min |
| Staten Island | Grymes Hill/Clifton | 17,404 | 7.4 min |
 
📌 **Key Takeaway:** Outer borough zones suffer from critical driver supply deficits. Passengers at JFK Airport (327K+ trips) and Queens Rockaways face peak average wait times of 7.8–7.9 minutes, nearly double the Manhattan average (4.2 min).
 
### Query 3: Driver Pay & Tip Dynamics (Weekday vs. Weekend)
```sql
SELECT 
    CASE WHEN d.is_weekend = TRUE THEN 'Weekend' ELSE 'Weekday' END AS day_type,
    COUNT(*) AS total_trips,
    ROUND(AVG(f.driver_pay)::numeric, 2) AS avg_driver_pay,
    ROUND(AVG(f.tips)::numeric, 2) AS avg_tip_amount
FROM fact_trips f
JOIN dim_date d ON f.pickup_datetime::date = d.date_key
GROUP BY d.is_weekend;
```
 
**Query Output:**
 
| day_type | total_trips | avg_driver_pay ($) | avg_tip_amount ($) |
|---|---|---|---|
| Weekday | 14,340,177 | $20.18 | $1.20 |
| Weekend | 6,229,100 | $18.51 | $1.03 |
 
📌 **Key Takeaway:** Drivers earn 8.3% less pay ($18.51 vs $20.18) and receive 14% lower tips ($1.03 vs $1.20) on weekends compared to weekdays. This indicates shorter average leisure trips and underscores the need for weekend incentives to maintain driver availability.
 
### Query 4: Revenue Efficiency by Time Window
```sql
SELECT 
    CASE 
        WHEN pickup_hour >= 6 AND pickup_hour < 12 THEN '1. Morning (06-12)'
        WHEN pickup_hour >= 12 AND pickup_hour < 17 THEN '2. Afternoon (12-17)'
        WHEN pickup_hour >= 17 AND pickup_hour < 22 THEN '3. Evening (17-22)'
        ELSE '4. Night (22-06)' 
    END AS time_window,
    COUNT(*) AS total_trips,
    ROUND(SUM(base_passenger_fare)::numeric, 2) AS total_revenue,
    ROUND(SUM(base_passenger_fare)::numeric / NULLIF(SUM(trip_miles)::numeric, 0), 2) AS revenue_per_mile
FROM fact_trips
GROUP BY 1
ORDER BY 1;
```
 
**Query Output:**
 
| time_window | total_trips | total_revenue ($) | revenue_per_mile ($/mi) |
|---|---|---|---|
| 1. Morning (06-12) | 5,178,602 | $132,686,000.00 | $5.70 |
| 2. Afternoon (12-17) | 4,957,277 | $130,007,000.00 | $5.96 |
| 3. Evening (17-22) | 5,877,483 | $147,436,000.00 | $5.77 |
| 4. Night (22-06) | 4,555,915 | $114,770,000.00 | $4.88 |
 
📌 **Key Takeaway:** The Evening window (17:00–22:00) is the primary volume driver (5.88M trips, $147.4M revenue). However, Afternoon trips (12:00–17:00) are the most monetarily efficient per unit distance ($5.96 revenue per mile).
 
---
 
## 📊 Power BI Interactive Dashboard
 
### Dashboard Pages Architecture
 
**Page 1: Overview (Financial Performance & Market Share)**
Focuses on market share breakdown between Uber and Lyft, net company profitability, and step-by-step revenue deduction via Waterfall Analysis.
- Key Visuals: Market Share Clustered Bar, Net Revenue Donut, Profitability Breakdown Waterfall Chart, Daily Revenue Trend Line.
**Page 2: Operations (Spatial Demand & Wait Times)**
Analyzes geographic concentration, airport demand, and operational bottlenecks across NYC boroughs and zones.
- Key Visuals: Custom TopoJSON NYC Shape Map, Top Active Zones Bar Chart, Service Zone Breakdown, Demand & Wait Time Combo Chart.
**Page 3: Economics (Pricing & Driver Pay Behavior)**
Examines econometric pricing drivers, distance vs. fare relationships, demand across time windows, and driver earnings stability.
- Key Visuals: Distance vs. Fare Regression Scatter Plot, Revenue by Time Window, Weekday vs. Weekend Bar Chart, Daily Driver Pay Trend.
### Dashboard UX Features
- **Custom Theme:** Dark Slate (`#1E222D`) background with signature NYC Taxi Yellow (`#FFC107`) highlights.
- **Seamless Navigation:** Custom transparent shape overlays for smooth 1-click page switching.
- **Bookmark Actions:** 1-click "Reset All Slicers" button.
- **External Links:** Embedded web actions routing directly to LinkedIn and GitHub repositories.
---
 
## 📁 Repository Structure
 
```text
nyc-ride-hailing-analytics/
│
├── assets/
│   ├── dashboard_overview.png
│   ├── dashboard_operations.png
│   ├── dashboard_economics.png
│   └── erd_diagram.png
│
├── sql/
│   ├── 01_schema_definition.sql
│   ├── 02_data_cleaning_deduplication.sql
│   └── 03_business_analytics_queries.sql
│
├── python/
│   ├── data_ingestion.py
│   └── data_cleaning.py
│
├── power_bi/
│   ├── README.md                          # Drive links & instructions
│   └── nyc_ride_hailing_dashboard.pbit    # Power BI Template File
│
├── .gitignore
├── LICENSE
└── README.md
```
 
---
 
## 💻 How to Run / Reproduce
 
**1. Clone the Repository**
```bash
git clone https://github.com/your-username/nyc-ride-hailing-analytics.git
cd nyc-ride-hailing-analytics
```
 
**2. Database Setup (PostgreSQL)**
- Execute `sql/01_schema_definition.sql` to create database tables and primary/foreign keys.
- Run your Python scripts in `python/` to ingest raw TLC CSV/Parquet files.
- Execute `sql/02_data_cleaning_deduplication.sql` to clean the 9.25M duplicate records.
- Run `sql/03_business_analytics_queries.sql` to verify numbers.
**3. Open Power BI Dashboard**
- Download the full `.pbix` file from the [Google Drive Link](#).
- Or open `power_bi/nyc_ride_hailing_dashboard.pbit` and connect it to your local PostgreSQL instance.
---

## 👤 Author

**Nihat Rzaquluzade | Junior Data Analyst**

This project was developed as a professional **Data Analytics portfolio project**, demonstrating skills in Python, PostgreSQL, ETL processes, data cleaning, SQL analysis, and Power BI data visualization.

[![GitHub](https://img.shields.io/badge/GitHub-100000?style=for-the-badge&logo=github&logoColor=white)](https://github.com/nihatrza)

[![LinkedIn](https://img.shields.io/badge/LinkedIn-0077B5?style=for-the-badge&logo=linkedin&logoColor=white)](https://www.linkedin.com/in/nihat-rzaquluzade/)

---
- 💼 LinkedIn: [Nihat Rzaquluzade](#)
- 🐙 GitHub: [nihatrza](#)
