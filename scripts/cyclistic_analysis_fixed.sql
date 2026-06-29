-- =====================================================================
--  CYCLISTIC BIKE-SHARE — очищення та аналіз  (ВИПРАВЛЕНА ВЕРСІЯ)
--  Головна мета правок: НЕ втрачати валідні рядки там, де вони потрібні.
--  Виправлено 3 речі — кожна позначена коментарем  [FIX].
-- =====================================================================


-- ---------------------------------------------------------------------
-- 1) ОБ'ЄДНАННЯ 12 МІСЯЦІВ
-- [FIX 1] Замість SELECT * — явний список стовпців.
-- UNION ALL зіставляє колонки ЗА ПОЗИЦІЄЮ, а не за назвою. Якщо в якомусь
-- місяці порядок колонок відрізняється, SELECT * тихо переплутає дані
-- (напр. назва станції потрапить у стовпець типу велосипеда). Явний
-- список це повністю виключає. Беремо лише потрібні 7 колонок.
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
-- ДІАГНОСТИКА ЯКОСТІ ДАНИХ (нічого не видаляє — лише рахує)
-- ---------------------------------------------------------------------

-- NULL по кожному стовпцю
SELECT
  COUNTIF(ride_id IS NULL)            AS null_ride_id,
  COUNTIF(started_at IS NULL)         AS null_started_at,
  COUNTIF(ended_at IS NULL)           AS null_ended_at,
  COUNTIF(start_station_name IS NULL) AS null_start_station,
  COUNTIF(end_station_name IS NULL)   AS null_end_station,
  COUNTIF(member_casual IS NULL)      AS null_member_casual
FROM new_cyclistic_data.trips_combined;

-- Дублікати
SELECT ride_id, COUNT(*) AS cnt
FROM new_cyclistic_data.trips_combined
GROUP BY ride_id
HAVING cnt > 1;

-- Некоректні дати
SELECT COUNT(*) AS invalid_dates
FROM new_cyclistic_data.trips_combined
WHERE ended_at < started_at;

-- Аномальна тривалість (< 1 хв або > 24 год)
-- [FIX 2] Рахуємо в СЕКУНДАХ (див. пояснення у блоці trips_cleaned).
SELECT COUNT(*) AS outliers
FROM new_cyclistic_data.trips_combined
WHERE TIMESTAMP_DIFF(ended_at, started_at, SECOND) < 60
   OR TIMESTAMP_DIFF(ended_at, started_at, SECOND) > 86400;


-- ---------------------------------------------------------------------
-- 2) ФІНАЛЬНА ОЧИЩЕНА ТАБЛИЦЯ
--
-- [FIX 3 — ГОЛОВНИЙ] Прибрано глобальний фільтр null-станцій.
--    Раніше тут було:
--        AND start_station_name IS NOT NULL
--        AND end_station_name   IS NOT NULL
--    Саме ці два рядки викидали ~1.2 млн ВАЛІДНИХ поїздок з УСІХ аналізів,
--    хоча станція потрібна лише у 07/08. Тепер їх тут НЕМАЄ —
--    станції фільтруємо локально у запитах 07/08 (див. нижче).
--
-- [FIX 2] Фільтр тривалості переведено в СЕКУНДИ, щоб точно збігатися
--    з формулою tour_length_min (= SECOND/60). Раніше фільтр рахував у
--    MINUTE, що рахує перетин меж хвилин і дає неточну межу: 10-секундна
--    поїздка через межу хвилини могла «пройти», а чесна 59-секундна —
--    випасти. Тепер межі точні.
--
-- Залишаємо ОСМИСЛЕНІ чистки (це справді биті дані, а не втрата валідних):
--    • базові NOT NULL (ride_id, started_at, ended_at, member_casual)
--    • ended_at > started_at (логічно неможливі поїздки)
--    • 1 хв … 24 год (фальстарти й «загублені» велосипеди псують середні)
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
  EXTRACT(MONTH FROM started_at)                   AS month_num,   -- зручно для сортування у 04
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
  AND TIMESTAMP_DIFF(ended_at, started_at, SECOND) >= 60        -- ≥ 1 хв
  AND TIMESTAMP_DIFF(ended_at, started_at, SECOND) <= 86400     -- ≤ 24 год
  AND DATE(started_at) BETWEEN '2025-01-01' AND '2025-12-31';


-- Фінальна перевірка (тепер рядків буде БІЛЬШЕ, ніж 3 661 499 —
-- бо повернули поїздки з порожньою станцією)
SELECT
  COUNT(*)                AS total_rows,
  COUNT(DISTINCT ride_id) AS unique_rides,
  MIN(date)               AS first_date,
  MAX(date)               AS last_date
FROM new_cyclistic_data.trips_cleaned;


-- =====================================================================
--  АНАЛІЗ
-- =====================================================================

-- 01 — Розподіл member vs casual
SELECT
  customer_type,
  COUNT(*) AS total_rides,
  ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 1) AS pct
FROM new_cyclistic_data.trips_cleaned
GROUP BY customer_type;

-- 02 — Статистика тривалості
SELECT
  customer_type,
  ROUND(AVG(tour_length_min), 2) AS avg_duration,
  ROUND(MAX(tour_length_min), 2) AS max_duration,
  APPROX_QUANTILES(tour_length_min, 2)[OFFSET(1)] AS median_duration
FROM new_cyclistic_data.trips_cleaned
GROUP BY customer_type;

-- 03 — Поїздки за днями тижня
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

-- 04 — Сезонність по місяцях
-- [FIX 2] використовує month_num зі стовпця таблиці.
-- Втрати «безмісячних» рядків тут немає за визначенням: month виводиться
-- напряму з started_at (TIMESTAMP), тож NULL-місяця бути не може, а GROUP BY
-- рядків не викидає (порожня група була б видимою, а не зниклою).
SELECT
  customer_type,
  month,
  month_num,
  COUNT(*) AS total_rides,
  ROUND(AVG(tour_length_min), 2) AS avg_duration
FROM new_cyclistic_data.trips_cleaned
GROUP BY customer_type, month, month_num
ORDER BY month_num, customer_type;

-- 05 — За годинами доби
SELECT
  customer_type,
  pickup_hour,
  COUNT(*) AS total_rides
FROM new_cyclistic_data.trips_cleaned
GROUP BY customer_type, pickup_hour
ORDER BY customer_type, pickup_hour;

-- 06 — Типи велосипедів
SELECT
  customer_type,
  bike_type,
  COUNT(*) AS total_rides,
  ROUND(AVG(tour_length_min), 2) AS avg_duration,
  ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (PARTITION BY customer_type), 1) AS pct
FROM new_cyclistic_data.trips_cleaned
GROUP BY customer_type, bike_type
ORDER BY customer_type, bike_type;

-- 07 — Топ-10 станцій (casual)
-- [FIX 3] Фільтр станції тепер ТУТ, локально — а не глобально.
SELECT
  start_station_name,
  COUNT(*) AS total_rides
FROM new_cyclistic_data.trips_cleaned
WHERE customer_type = 'casual'
  AND start_station_name IS NOT NULL
GROUP BY start_station_name
ORDER BY total_rides DESC
LIMIT 10;

-- 08 — Топ-10 станцій (member)
SELECT
  start_station_name,
  COUNT(*) AS total_rides
FROM new_cyclistic_data.trips_cleaned
WHERE customer_type = 'member'
  AND start_station_name IS NOT NULL
GROUP BY start_station_name
ORDER BY total_rides DESC
LIMIT 10;

-- 09 — Зведена таблиця (усі метрики)
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
