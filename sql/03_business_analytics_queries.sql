-- ========================================================
-- NYC Ride-Hailing Analytics - Key Business Queries
-- Database: PostgreSQL
-- ========================================================

-- Query 1: Market Share & Net Margin Comparison (Uber vs Lyft)
SELECT 
    c.company_name,
    COUNT(*) AS total_trips,
    ROUND(SUM(f.company_margin)::numeric, 2) AS total_net_margin,
    ROUND((COUNT(*) * 100.0) / SUM(COUNT(*)) OVER(), 2) AS trip_market_share_pct
FROM fact_trips f
JOIN dim_company c ON f.hvfhs_license_num = c.license_num
GROUP BY c.company_name
ORDER BY total_trips DESC;


-- Query 2: Top 5 Operational Bottlenecks (Zones with Highest Wait Times)
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


-- Query 3: Driver Pay & Tip Dynamics (Weekday vs. Weekend)
SELECT 
    CASE WHEN d.is_weekend = TRUE THEN 'Weekend' ELSE 'Weekday' END AS day_type,
    COUNT(*) AS total_trips,
    ROUND(AVG(f.driver_pay)::numeric, 2) AS avg_driver_pay,
    ROUND(AVG(f.tips)::numeric, 2) AS avg_tip_amount
FROM fact_trips f
JOIN dim_date d ON f.pickup_datetime::date = d.date_key
GROUP BY d.is_weekend;


-- Query 4: Demand & Revenue Efficiency Across Time Windows
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