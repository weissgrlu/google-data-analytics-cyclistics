-- ========================================================================================================================================
-- CYCLISTIC PROJECT - ANALYSE
-- Lukáš Weissgráb
-- Google BigQuery
-- 4. ANALYSE
-- V této části jsou vloženy skripty pro tvorbu výsledných tabulek v .csv, které použijeme pro vizualizaci dat v prostředí Tableau.
-- =========================================================================================================================================

-- -----------------------------------------------------------------------------
-- EXPORT 1: Časové trendy, denní rytmus a typy kol (cyclistic_tableau_trends)
-- -----------------------------------------------------------------------------

SELECT 
  month,
  month_name,
  day_of_week,
  day_of_week_name,
  start_hour,
  member_casual,
  rideable_type,
  COUNT(*) AS total_trips,
  ROUND(AVG(ride_length_min), 2) AS avg_ride_length_min,
  ROUND(APPROX_QUANTILES(ride_length_min, 100)[OFFSET(50)], 2) AS median_ride_length_min
FROM 
  `alert-basis-504812-j0.cyclistic_projekt.cyclistic_cleaned`
GROUP BY 
  month,
  month_name,
  day_of_week,
  day_of_week_name,
  start_hour,
  member_casual,
  rideable_type
ORDER BY 
  month,
  day_of_week,
  start_hour,
  member_casual;

-- -----------------------------------------------------------------------------
-- EXPORT 2: Geografické rozložení a mapa stanic (cyclistic_tableau_stations)
-- -----------------------------------------------------------------------------
SELECT 
  member_casual,
  start_station_name,
  ROUND(AVG(start_lat), 6) AS station_lat,
  ROUND(AVG(start_lng), 6) AS station_lng,
  COUNT(*) AS total_trips,
  ROUND(AVG(ride_length_min), 2) AS avg_ride_length_min,
  COUNTIF(is_round_trip) AS round_trips_count
FROM 
  `alert-basis-504812-j0.cyclistic_projekt.cyclistic_cleaned`
WHERE 
  start_station_name IS NOT NULL
GROUP BY 
  member_casual,
  start_station_name
HAVING 
  COUNT(*) >= 100
ORDER BY 
  member_casual,
  total_trips DESC;
