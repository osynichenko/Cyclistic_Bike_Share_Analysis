-- =====================================================================
--  CYCLISTIC BIKE-SHARE — Cleaning and Analysis (REVISION)
--  The main goal of edits is to NOT lose valid lines where they are needed.
-- =====================================================================


-- ---------------------------------------------------------------------
-- 1) 12 MONTHS COMBINATION
-- ---------------------------------------------------------------------
CREATE OR REPLACE TABLE new_cyclistic_data.trips_combined AS
SELECT ride_id, rideable_type, started_at, ended_at, start_station_name, end_station_name, member_casual FROM new_cyclistic_data.trips_2025_01
UNION ALL SELECT ride_id, rideable_type, started_at, ended_at, start_station_name, end_station_name, member_casual FROM new_cyclistic_data.trips_2025_02
UNION ALL SELECT ride_id, rideable_type, started_at, ended_at, start_station_name, end_station_name, member_casual FROM new_cyclistic_data.trips_2025_03
UNION ALL SELECT ride_id, rideable_type, started_at, ended_at, start_station_name, end_station_name, member_casual FROM new_cyclistic_data.trips_2025_04
UNION ALL SELECT ride_id, rideable_type, started_at, ended_at, start_station_name, end_station_name, member_casual FROM new_cyclistic_data.trips_2025_05
UNION ALL SELECT ride_id, rideable_type, started_at, ended_at, start_station_name, end_station_name, member_casual FROM new_cyclistic_data.trips_2025_06
UNION ALL SELECT ride_id, rideable_type, started_at, ended_at, start_station_name, end_station_name, member_casual FROM new_cyclistic_data.trips_2025_07
UNION ALL SELECT ride_id, rideable_type, started_at, ended_at, start_station_name, end_station_name, member_casual FROM new_cyclistic_data.trips_2025_08
UNION ALL SELECT ride_id, rideable_type, started_at, ended_at, start_station_name, end_station_name, member_casual FROM new_cyclistic_data.trips_2025_09
UNION ALL SELECT ride_id, rideable_type, started_at, ended_at, start_station_name, end_station_name, member_casual FROM new_cyclistic_data.trips_2025_10
UNION ALL SELECT ride_id, rideable_type, started_at, ended_at, start_station_name, end_station_name, member_casual FROM new_cyclistic_data.trips_2025_11
UNION ALL SELECT ride_id, rideable_type, started_at, ended_at, start_station_name, end_station_name, member_casual FROM new_cyclistic_data.trips_2025_12;


-- Перевірка
SELECT COUNT(*) AS total_rows FROM new_cyclistic_data.trips_combined;


-- ---------------------------------------------------------------------
-- DATA QUALITY DIAGNOSTICS (we don't delete anything - we just count)
-- ---------------------------------------------------------------------

-- NULL for each column
SELECT
  COUNTIF(ride_id IS NULL)            AS null_ride_id,
  COUNTIF(started_at IS NULL)         AS null_started_at,
  COUNTIF(ended_at IS NULL)           AS null_ended_at,
  COUNTIF(start_station_name IS NULL) AS null_start_station,
  COUNTIF(end_station_name IS NULL)   AS null_end_station,
  COUNTIF(member_casual IS NULL)      AS null_member_casual
FROM new_cyclistic_data.trips_combined;

-- Duplicates
SELECT ride_id, COUNT(*) AS cnt
FROM new_cyclistic_data.trips_combined
GROUP BY ride_id
HAVING cnt > 1;

-- Incorrect dates
SELECT COUNT(*) AS invalid_dates
FROM new_cyclistic_data.trips_combined
WHERE ended_at < started_at;

-- Abnormal duration (< 1 min or > 24 h)
-- [FIX 2] Count in SECONDS
SELECT COUNT(*) AS outliers
FROM new_cyclistic_data.trips_combined
WHERE TIMESTAMP_DIFF(ended_at, started_at, SECOND) < 60
   OR TIMESTAMP_DIFF(ended_at, started_at, SECOND) > 86400;


-- ---------------------------------------------------------------------
-- 2) FINAL CLEANED TABLE
--
-- [FIX 3 MAIN] Removed global null station filter.
-- Previously it was:
-- AND start_station_name IS NOT NULL
-- AND end_station_name IS NOT NULL
-- These two lines were throwing away ~1.2 million VALID trips from ALL analyses,
-- although the station is only needed in 07/08. Now they are NOT here
-- we filter stations locally in 07/08 queries (see below).
--
-- [FIX 2] Duration filter converted to SECONDS to exactly match
-- the formula tour_length_min (= SECOND/60). Previously, the filter counted in
-- MINUTE, which counts the crossing of minute boundaries and gives an inaccurate boundary: a 10-second
-- trip over the minute boundary could "pass", and an honest 59-second one
-- fall out. Now the boundaries are accurate.
--
-- We leave MEANINGFUL purges (this is really broken data, not the loss of valid ones):
--  basic NOT NULL (ride_id, started_at, ended_at, member_casual)
--  ended_at > started_at (logically impossible trips)
--  1 min ... 24 h (false starts and "lost" bikes spoil the averages)
-- ---------------------------------------------------------------------
CREATE OR REPLACE TABLE new_cyclistic_data.trips_cleaned AS
SELECT
  ride_id,
  rideable_type                                    AS bike_type,
  started_at,
  ended_at,
  start_station_name,
  end_station_name,
  member_casual                                    AS customer_type,
  DATE(started_at)                                 AS date,
  FORMAT_DATE('%b_%y', DATE(started_at))           AS month,
  EXTRACT(MONTH FROM started_at)                   AS month_num,   -- convenient for sorting in 04 Seasonality by month
  FORMAT_DATE('%Y', DATE(started_at))              AS year,
  FORMAT_DATE('%A', DATE(started_at))              AS week_day,
  EXTRACT(HOUR FROM started_at)                    AS pickup_hour,
  ROUND(TIMESTAMP_DIFF(ended_at, started_at, SECOND) / 60.0, 2) AS tour_length_min
FROM new_cyclistic_data.trips_combined
WHERE
  ride_id        IS NOT NULL
  AND started_at IS NOT NULL
  AND ended_at   IS NOT NULL
  AND member_casual IS NOT NULL
  AND ended_at > started_at
  AND TIMESTAMP_DIFF(ended_at, started_at, SECOND) >= 60        -- ≥ 1 min
  AND TIMESTAMP_DIFF(ended_at, started_at, SECOND) <= 86400     -- ≤ 24 hours
  AND DATE(started_at) BETWEEN '2025-01-01' AND '2025-12-31';


-- Final check because trips were returned with an empty station
SELECT
  COUNT(*)                AS total_rows,
  COUNT(DISTINCT ride_id) AS unique_rides,
  MIN(date)               AS first_date,
  MAX(date)               AS last_date
FROM new_cyclistic_data.trips_cleaned;


-- =====================================================================
--  ANALYSIS
-- =====================================================================

-- 01 — Member vs. casual distribution
SELECT
  customer_type,
  COUNT(*) AS total_rides,
  ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 1) AS pct
FROM new_cyclistic_data.trips_cleaned
GROUP BY customer_type;

-- 02 — Duration statistics
SELECT
  customer_type,
  ROUND(AVG(tour_length_min), 2) AS avg_duration,
  ROUND(MAX(tour_length_min), 2) AS max_duration,
  APPROX_QUANTILES(tour_length_min, 2)[OFFSET(1)] AS median_duration
FROM new_cyclistic_data.trips_cleaned
GROUP BY customer_type;

-- 03 — Trips by day of the week
SELECT
  customer_type,
  week_day,
  COUNT(*) AS total_rides,
  ROUND(AVG(tour_length_min), 2) AS avg_duration
FROM new_cyclistic_data.trips_cleaned
GROUP BY customer_type, week_day
ORDER BY customer_type,
  CASE week_day
    WHEN 'Monday' THEN 1 WHEN 'Tuesday' THEN 2 WHEN 'Wednesday' THEN 3
    WHEN 'Thursday' THEN 4 WHEN 'Friday' THEN 5 WHEN 'Saturday' THEN 6
    WHEN 'Sunday' THEN 7
  END;

-- 04 — Seasonality by month
-- [FIX 2] uses month_num from the table column.
-- There is no loss of "monthless" rows here by definition: month is derived
-- directly from started_at (TIMESTAMP), so there can be no NULL month, and GROUP BY
-- does not throw away rows (an empty group would be visible, not disappeared).
SELECT
  customer_type,
  month,
  month_num,
  COUNT(*) AS total_rides,
  ROUND(AVG(tour_length_min), 2) AS avg_duration
FROM new_cyclistic_data.trips_cleaned
GROUP BY customer_type, month, month_num
ORDER BY month_num, customer_type;

-- 05 — By the hours of the day
SELECT
  customer_type,
  pickup_hour,
  COUNT(*) AS total_rides
FROM new_cyclistic_data.trips_cleaned
GROUP BY customer_type, pickup_hour
ORDER BY customer_type, pickup_hour;

-- 06 — Types of bicycles
SELECT
  customer_type,
  bike_type,
  COUNT(*) AS total_rides,
  ROUND(AVG(tour_length_min), 2) AS avg_duration,
  ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (PARTITION BY customer_type), 1) AS pct
FROM new_cyclistic_data.trips_cleaned
GROUP BY customer_type, bike_type
ORDER BY customer_type, bike_type;

-- 07 — Top 10 stations (casual)
-- [FIX 3] Station filter is now HERE, locally — not globally.
SELECT
  start_station_name,
  COUNT(*) AS total_rides
FROM new_cyclistic_data.trips_cleaned
WHERE customer_type = 'casual'
  AND start_station_name IS NOT NULL
GROUP BY start_station_name
ORDER BY total_rides DESC
LIMIT 10;

-- 08 — Top 10 stations (member)
SELECT
  start_station_name,
  COUNT(*) AS total_rides
FROM new_cyclistic_data.trips_cleaned
WHERE customer_type = 'member'
  AND start_station_name IS NOT NULL
GROUP BY start_station_name
ORDER BY total_rides DESC
LIMIT 10;

-- 09 — Summary table (all metrics)
SELECT
  customer_type,
  month,
  week_day,
  bike_type,
  pickup_hour,
  COUNT(*) AS total_rides,
  ROUND(AVG(tour_length_min), 2) AS avg_duration
FROM new_cyclistic_data.trips_cleaned
GROUP BY customer_type, month, week_day, bike_type, pickup_hour
ORDER BY
  EXTRACT(MONTH FROM MIN(started_at)),
  customer_type,
  CASE week_day
    WHEN 'Monday' THEN 1 WHEN 'Tuesday' THEN 2 WHEN 'Wednesday' THEN 3
    WHEN 'Thursday' THEN 4 WHEN 'Friday' THEN 5 WHEN 'Saturday' THEN 6
    WHEN 'Sunday' THEN 7
  END,
  pickup_hour;
