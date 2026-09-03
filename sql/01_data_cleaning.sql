-- ========================================================================================================================================
-- CYCLISTIC PROJECT - CLEANING
-- Lukáš Weissgráb
-- Google BigQuery
-- 3. PROCESS
-- Tento skript je rozdělen na dvě části, první část slouží k průzkumným dotazům, kde se detailněji seznamujeme se souborem, jeho velikostí
-- a snažíme se pomocí něj odhalit chyby v souboru. Druhá část skriptu bude již samotný klíčový tzv. ,,čistící'' skript, který bude klíčovou
-- prerekvizitou vzniku finální clean_data tabulky.
-- =========================================================================================================================================

-- -----------------------------------------------------------------------------
-- ČÁST 1: SEZNÁMENÍ SE SE SOUBOREM (Ověření kvality a vyhledání chyb)
-- -----------------------------------------------------------------------------

-- zjištění celkové velikosti souboru, využijeme k popisu souboru v readme.md
SELECT 
  COUNT(*) AS total_rows
FROM `alert-basis-504812-j0.cyclistic_projekt.cyclistic_combined`
-- total_rows=6037968

-- kontrola typů jednotlivých sloupců, ověření, že import proběhl tak, jak měl (import proběhl z Google Cloudu tak, že spojil všech 12 souborů do tabulky
SELECT
  column_name,
  data_type,
  is_nullable
FROM `alert-basis-504812-j0.cyclistic_projekt.INFORMATION_SCHEMA.COLUMNS`
WHERE
  table_name='cyclistic_combined'
-- import nezpůsobil problémy, typ sloupců zůstal zachována

-- ověříme unikátnost primárního klíče, kterým je v našem případě ride_id
SELECT 
  ride_id,
  COUNT(*) AS duplice_count
FROM 
  `alert-basis-504812-j0.cyclistic_projekt.cyclistic_combined`
GROUP BY 
  ride_id
HAVING 
  COUNT(*) > 1;
-- výsledný dotaz odhalil 35 duplikátních klíčů ride_id

-- důležité pro nás budou délky jízd, ověříme nyní, že jsou jízdy reálné, tj. že netrvaly 0 s nebo že čas dojezdu není menší, než čas příjezdu
SELECT
  COUNT(*) AS invalid_trip
FROM `alert-basis-504812-j0.cyclistic_projekt.cyclistic_combined`
WHERE
  ended_at >= started_at
-- nalezena jedna defektní jízda

-- podíváme se nyní na extrémy, tj. jízdy, které jsou příliš krátké (trvali méně než 60 s - mohlo dojít pouze k odemknutí a pak zas uzamknutí kola)
-- a také najízdy příliš dlouhé (trvali déle než 24 h, nejspíše se kolo ztratilo, nebo někdo jízdu neukončil)
SELECT
  COUNTIF(TIMESTAMP_DIFF(ended_at, started_at, SECOND)<60 AND start_station_name=end_station_name) AS too_low_rides,
  COUNTIF(TIMESTAMP_DIFF(ended_at, started_at, SECOND)>86400) AS too_high_rides
FROM `alert-basis-504812-j0.cyclistic_projekt.cyclistic_combined`
WHERE
  ended_at > started_at
-- příliš krátké = 40 228, příliš dlouhé 5341

-- v kategoriích rideable_type a member_casual ověříme, že tam nejsou kategorie, které tam nepatří (kontrola překlepů)
SELECT
  rideable_type,
  member_casual,
  COUNT(*) AS distinct_type
FROM `alert-basis-504812-j0.cyclistic_projekt.cyclistic_combined`
GROUP BY
  rideable_type,
  member_casual
ORDER BY
  rideable_type,
  distinct_type DESC
-- žádné překlepy nenalezeny

-- u jízd bychom mohli očekávat i nějaké testovací jízdy, tyto jízdy by měly mít jako startovací stanici nějakou testovací, prověříme počet testovacích jízd
SELECT 
  start_station_name,
  COUNT(*) AS trip_count
FROM 
  `alert-basis-504812-j0.cyclistic_projekt.cyclistic_combined`
WHERE 
  start_station_name LIKE '%TEST%' 
  OR start_station_name LIKE '%Test%'
  OR start_station_name LIKE '%test%'
GROUP BY 
  start_station_name;
-- v datovém souboru odhalena jedna testovací jízda

-- na závěr zjistíme počet nulových hodnot u startovních, koncových stanic a jejich souřadnic
SELECT 
  COUNTIF(start_station_name IS NULL) AS missing_start_station,
  COUNTIF(end_station_name IS NULL) AS missing_end_station,
  COUNTIF(start_lat IS NULL OR start_lng IS NULL) AS missing_start_coords,
  COUNTIF(end_lat IS NULL OR end_lng IS NULL) AS missing_end_coords
FROM 
  `alert-basis-504812-j0.cyclistic_projekt.cyclistic_combined`;
-- zjistili jsme, že počet stanic, kterým chybí start je 1 273 200, konec 1 336 777, souřadnice startu jsou všude, souřadnice konce nejsou 5436 jízd

-- -----------------------------------------------------------------------------
-- ČÁST 2: NOVÉ METRIKY A VYČIŠTĚNÁ TABULKA
-- -----------------------------------------------------------------------------

-- nyní vytvoříme novou tabulku, která bude vyčištěná o odhalená nesprávná data v předchozí části analýzy
-- budou v ní také vytvořené nové metriky, které detailněji popíšeme níže
CREATE OR REPLACE TABLE `alert-basis-504812-j0.cyclistic_projekt.cyclistic_cleaned` AS

SELECT 
  ride_id,
  rideable_type,
  started_at,
  ended_at,
  -- nové metriky, vypočítáme délky jízd v sekundách a minutách
  TIMESTAMP_DIFF(ended_at, started_at, SECOND) AS ride_length_sec,
  ROUND(TIMESTAMP_DIFF(ended_at, started_at, SECOND) / 60.0, 2) AS ride_length_min,
  -- nové metriky, z údajů o výpůjčce zjistíme, o které dny v týdnu šlo a v kterém měsíci k výpůjčce došlo
  EXTRACT(DAYOFWEEK FROM started_at) AS day_of_week,
  FORMAT_TIMESTAMP('%A', started_at) AS day_of_week_name,
  EXTRACT(HOUR FROM started_at) AS start_hour,
  EXTRACT(MONTH FROM started_at) AS month,
  FORMAT_TIMESTAMP('%B', started_at) AS month_name,
  --nová metrika, určuje, zda-li se jednalo o okružní jízdu nebo klasickou dopravu z A do B
  IF(start_station_name = end_station_name, TRUE, FALSE) AS is_round_trip,
  start_station_name,
  start_station_id,
  end_station_name,
  end_station_id,
  start_lat,
  start_lng,
  end_lat,
  end_lng,
  member_casual

  FROM `alert-basis-504812-j0.cyclistic_projekt.cyclistic_combined`

-- v této části vyfiltrujeme odhalená špatná data v předchozí části
  WHERE
    --odstraníme záporné a nulové časy
    TIMESTAMP_DIFF(ended_at, started_at, SECOND) > 0
    --odstraníme příliš malé a příliš velké časy výpujčky (odlehlé hodnoty)
    AND TIMESTAMP_DIFF(ended_at, started_at, SECOND) <= 86400
    AND NOT (
    TIMESTAMP_DIFF(ended_at, started_at, SECOND) < 60 
    AND start_station_name = end_station_name)
    --odstranění testovacích stanic
    AND (start_station_name NOT LIKE '%TEST%' OR start_station_name IS NULL)
    AND (end_station_name NOT LIKE '%TEST%' OR end_station_name IS NULL);

-- po vyčištění původní tabulky nám zůstalo celkem 5 874 686 řádků

-- poslední rychlá kontrola, že nová tabulka má všechny vlastnosti, které od ní požadujeme
SELECT 
  MIN(ride_length_sec) AS min_duration_sec,
  MAX(ride_length_sec) AS max_duration_sec,
  COUNTIF(ride_length_sec <= 0) AS invalid_durations,
  COUNTIF(start_station_name LIKE '%TEST%') AS test_stations_remaining
FROM 
  `alert-basis-504812-j0.cyclistic_projekt.cyclistic_cleaned`;

-- žádné chyby, s touto tabulkou tedy budeme pracovat
