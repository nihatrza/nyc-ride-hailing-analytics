-- ========================================================
-- NYC Ride-Hailing Analytics - Data Cleaning & Deduplication
-- Description: Removes 9.25M duplicate records using Window Functions & CTID
-- ========================================================

BEGIN;

WITH ranked_duplicates AS (
    SELECT
        ctid,
        ROW_NUMBER() OVER (
            PARTITION BY
                "hvfhs_license_num",
                "pickup_datetime",
                "PULocationID",
                "DOLocationID",
                "trip_miles",
                "trip_time",
                "base_passenger_fare",
                "tips",
                "driver_pay",
                "cbd_congestion_fee",
                "wait_time_minutes",
                "company_margin",
                "pickup_hour"
            ORDER BY ctid
        ) AS row_num
    FROM fact_trips
)
DELETE FROM fact_trips
WHERE ctid IN (
    SELECT ctid
    FROM ranked_duplicates
    WHERE row_num > 1
);

COMMIT;

-- Verify final clean row count (~20.56M expected)
SELECT COUNT(*) AS total_clean_rows FROM fact_trips;