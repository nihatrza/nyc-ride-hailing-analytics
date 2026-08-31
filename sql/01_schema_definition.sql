-- ========================================================
-- NYC Ride-Hailing Analytics - Schema Definition
-- Database: PostgreSQL
-- ========================================================

-- 1. Create Dimension: dim_company
CREATE TABLE IF NOT EXISTS dim_company (
    license_num TEXT PRIMARY KEY,
    company_name TEXT NOT NULL
);

-- 2. Create Dimension: dim_zones
CREATE TABLE IF NOT EXISTS dim_zones (
    "LocationID" BIGINT PRIMARY KEY,
    "Borough" TEXT,
    "Zone" TEXT,
    service_zone TEXT
);

-- 3. Create Dimension: dim_date
CREATE TABLE IF NOT EXISTS dim_date (
    date_key DATE PRIMARY KEY,
    year INTEGER,
    month INTEGER,
    day INTEGER,
    day_name TEXT,
    is_weekend BOOLEAN
);

-- 4. Create Fact Table: fact_trips
CREATE TABLE IF NOT EXISTS fact_trips (
    hvfhs_license_num TEXT REFERENCES dim_company(license_num),
    pickup_datetime TIMESTAMP WITHOUT TIME ZONE,
    "PULocationID" INTEGER REFERENCES dim_zones("LocationID"),
    "DOLocationID" INTEGER REFERENCES dim_zones("LocationID"),
    trip_miles REAL,
    trip_time INTEGER,
    base_passenger_fare REAL,
    tips REAL,
    driver_pay REAL,
    cbd_congestion_fee REAL,
    wait_time_minutes REAL,
    company_margin REAL,
    pickup_hour SMALLINT
);

-- Add Index for Query Performance
CREATE INDEX IF NOT EXISTS idx_fact_trips_pickup_datetime ON fact_trips(pickup_datetime);
CREATE INDEX IF NOT EXISTS idx_fact_trips_pulocation ON fact_trips("PULocationID");
CREATE INDEX IF NOT EXISTS idx_fact_trips_license ON fact_trips(hvfhs_license_num);