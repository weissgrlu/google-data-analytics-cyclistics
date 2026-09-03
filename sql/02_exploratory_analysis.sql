-- ========================================================================================================================================
-- CYCLISTIC PROJECT - ANALYSE
-- Lukáš Weissgráb
-- Google BigQuery
-- 4. ANALYSE
-- Tento skript slouží jako podklad pro analýzu datového souboru cyclistic_cleaned, který vznikl úpravou původních dat (soubor je očištěn).
-- Analýzu provádíme stejně jako čištění v SQL pomocí BigQuery, soubor je členěn pro přehlednost do několika logických částí (6).
-- =========================================================================================================================================

-- -----------------------------------------------------------------------------
-- ČÁST 1: CELKOVÝ OBJEM VÝPŮJČEK Z HLEDISKA TYPU PROVOZU A DOBA TRVÁNÍ VÝPŮJČEK
-- -----------------------------------------------------------------------------

-- zjistíme tržní podíl jízd casual a member členů, vypočítáme pro ně také statistické parametry jako jsou průměr, medián, minimum a maximum
SELECT 
  member_casual,
  COUNT(*) AS total_trips,
  ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) AS percentage_of_total,
  ROUND(AVG(ride_length_min), 2) AS avg_ride_length_min,
  ROUND(APPROX_QUANTILES(ride_length_min, 100)[OFFSET(50)], 2) AS median_ride_length_min,
  ROUND(MIN(ride_length_min), 2) AS min_ride_length_min,
  ROUND(MAX(ride_length_min), 2) AS max_ride_length_min
FROM 
  `alert-basis-504812-j0.cyclistic_projekt.cyclistic_cleaned`
GROUP BY 
  member_casual;

/*
---------------------------------------------------------------------------------------------------------------------------------------------
Výsledky daného scriptu
---------------------------------------------------------------------------------------------------------------------------------------------
member_casual | total_trips | percentage_of_total | avg_ride_length_min | median_ride_length_min | min_ride_length_min | max_ride_length_min
---------------------------------------------------------------------------------------------------------------------------------------------
casual        | 2 069 377   | 35.23 %             | 18.92 min           | 11.47 min              | 0.02 min            | 1439.97 min
member        | 3 805 281   | 64.77 %             | 12.25 min           |  8.73 min              | 0.02 min            | 1439.90 min

Pozorování:
1. Objem: Roční členové (members) tvoří téměř dvě třetiny veškerého provozu (64,77 %), takže tvoří stabilní členskou základnu.
2. Trvání (Průměry a mediány):
   - Jízdy casual uživatelů jsou v průměru o 54 % delší (18,92 min vs. 12,25 min).
   - Medián odhaluje typickou jízdu bez vlivu extrémů: členové jezdí typicky 8,73 minuty, zatímco casual zákazníci 11,47 minuty.
   - U obou skupin je průměr vyšší než medián, tj. že delší vyjížďky táhnou průměr výrazněji nahoru.
---------------------------------------------------------------------------------------------------------------------------------------------
*/

-- -----------------------------------------------------------------------------
-- ČÁST 2: KLÍČOVÉ METRIKY A JEJICH PROMĚNA V PRŮBĚHU TÝDNE
-- -----------------------------------------------------------------------------

-- V této části bude naším úkolem hned několik věcí. První otázkou bude, zda-li nějaká skupina member/casual preferuje určité dny v týdnu před
-- jinými. Hypotéza je, že casual zákazníci budou více preferovat víkendy (výlety apod.), member zákazníci všední dny (dojíždění do práce, školy).
-- Dalším ukazatelem by pro nás mohl být výpočet průměrné doby jízdy/medián v závislosti na dnu v týdnu a porovnání těchto výsledků v kontextu
-- member vs casual. Posledním ukazatelem pro nás bude podíl zákazníků (member/casual) v závislosti na dnu v týdnu. Tato otázka souvisí s otázku 1 výše.
SELECT 
  day_of_week,
  day_of_week_name,
  member_casual,
  COUNT(*) AS total_trips,
  ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(PARTITION BY member_casual), 2) AS pct_of_group_total,
  ROUND(AVG(ride_length_min), 2) AS avg_ride_length_min,
  ROUND(APPROX_QUANTILES(ride_length_min, 100)[OFFSET(50)], 2) AS median_ride_length_min
FROM 
  `alert-basis-504812-j0.cyclistic_projekt.cyclistic_cleaned`
GROUP BY 
  day_of_week,
  day_of_week_name,
  member_casual
ORDER BY 
  member_casual,
  day_of_week;
/*
---------------------------------------------------------------------------------------------------------------------------------
Výsledky daného scriptu.
---------------------------------------------------------------------------------------------------------------------------------
day_of_week | day_of_week_name | member_casual | total_trips | pct_of_group_total | avg_ride_length_min | median_ride_length_min
---------------------------------------------------------------------------------------------------------------------------------
1           | Sunday           | casual        |   342 525   | 16.55 %            | 22.05 min           | 13.35 min
2           | Monday           | casual        |   235 233   | 11.37 %            | 18.94 min           | 11.10 min
3           | Tuesday          | casual        |   229 875   | 11.11 %            | 16.23 min           | 10.05 min
4           | Wednesday        | casual        |   237 508   | 11.48 %            | 15.69 min           |  9.90 min
5           | Thursday         | casual        |   258 330   | 12.48 %            | 16.39 min           | 10.10 min
6           | Friday           | casual        |   327 152   | 15.81 %            | 18.38 min           | 11.20 min
7           | Saturday         | casual        |   438 754   | 21.20 %            | 21.53 min           | 13.47 min
---------------------------------------------------------------------------------------------------------------------------------
1           | Sunday           | member        |   406 399   | 10.68 %            | 13.43 min           |  9.32 min
2           | Monday           | member        |   527 644   | 13.87 %            | 11.92 min           |  8.43 min
3           | Tuesday          | member        |   601 753   | 15.81 %            | 11.79 min           |  8.53 min
4           | Wednesday        | member        |   610 431   | 16.04 %            | 11.74 min           |  8.57 min
5           | Thursday         | member        |   606 460   | 15.94 %            | 11.79 min           |  8.57 min
6           | Friday           | member        |   569 452   | 14.96 %            | 12.16 min           |  8.60 min
7           | Saturday         | member        |   483 142   | 12.70 %            | 13.51 min           |  9.60 min
---------------------------------------------------------------------------------------------------------------------------------
Pozorování:
1. Rozložení poptávky:
   - Members: Aktivita je silně koncentrována v pracovních dnech (Po-Pá) tvoří 
     téměř 76 % všech jejich cest s vrcholem ve středu – 610 431 jízd). O víkendu aktivita 
     výrazně klesá (neděle tvoří pouze 10,68 % jejich jízd, což je v porovnání s ostatními dny útlum).
   - Casual: Poptávka po jízdách dle předpokladu vzrůstá směrem k víkendu. Samotná sobota a neděle tvoří 
     37,75 % všech casual výpůjček (jejich špičku tvoří sobota – 438 754 jízd, 21,20 %).
2. Délka jízdy:
   - Casual jezdci dosahují maxima o víkendu (průměr přes 21–22 min, medián 13,4 min), 
     zatímco uprostřed týdne jízdy zkracují na ~16 min. 
   - Members si drží stabilní tempo: v pracovní dny je medián konstantně 8,5 minuty 
     (nejspíše použití na dojíždění), o víkendu se lehce protahuje jen na 9,5 minuty.
-------------------------------------------------------------------------------
*/

-- -----------------------------------------------------------------------------
-- ČÁST 3: HODINOVÝ PROFIL JÍZD A ČASOVÉ ŠPIČKY V HODINÁCH
-- -----------------------------------------------------------------------------

-- Další část analýzy bude věnována využití kol v kontextu hodin v průběhu dne. Bude nás zajímat zejména to,
-- v jaké denní doby si zákazníci kola půjčují, znovu budeme porovnávat tyto metriky pro skupiny member/casual.
-- Očekáváme, že member zákazníci budou preferovat zejména ranní hodiny, u casual zákazníku to budou zase spíše 
-- hodiny odpolední. Na zjištění těchto ukazatelů budeme pracovat hlavně s nově vytvořenými sloupci start_hour.
SELECT 
  start_hour,
  member_casual,
  COUNT(*) AS total_trips,
  ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(PARTITION BY member_casual), 2) AS pct_of_group_total,
  ROUND(AVG(ride_length_min), 2) AS avg_ride_length_min
FROM 
  `alert-basis-504812-j0.cyclistic_projekt.cyclistic_cleaned`
GROUP BY 
  start_hour,
  member_casual
ORDER BY 
  member_casual,
  start_hour;
/*
-------------------------------------------------------------------------------
Výsledky daného scriptu.
-------------------------------------------------------------------------------
1. Members a jejich dojíždění do práce/školy:
   - Members vykazují dva výrazné špičkové časy:
     * Ranní špička: 08:00 (277 896 jízd; 7,30 % objemu)
     * Odpolední špička: 17:00 (410 084 jízd; 10,78 % objemu)
   - Odpolední pásmo 16:00–18:00 tvoří téměř 29 % veškerého denního provozu členů.

2. Casual jezdci a jejich volný čas/rekreace:
   - Ranní špička prakticky neexistuje (v 08:00 pouze 3,56 % jejich jízd).
   - Aktivita plynule roste od dopoledne až k jedinému vrcholu v 17:00 (195 899 jízd; 9,47 %).

3. Doba trvání během dne:
   - Casual jezdci jezdí nejdéle mezi 10:00 a 14:00 (průměr 22–23 minut).
   - U členů zůstává průměrná délka stabilní po celý den (10–13 minut).
-------------------------------------------------------------------------------
*/

-- -----------------------------------------------------------------------------
-- ČÁST 4: SÉZONNOST A VLIV ROČNÍHO OBDOBÍ NA VÝPUJČKY
-- -----------------------------------------------------------------------------

-- V tomto scriptu plynule navážeme na předchozí analýzu vlivu průběhu dne na výpůjčky kol, budeme
-- totiž zkoumat vliv měsíců, tj. i ročních období na výpůjčky kol a srovnání těchto vlivů znovu v
-- kontextu member vs. casual. Hypotéza je znovu taková, že members budou mít stabilnější půjčování
-- v průběhu celého roku. Script je tedy velmi podobný předchozímu, jen pracuje s měsíci.
SELECT 
  month,
  month_name,
  member_casual,
  COUNT(*) AS total_trips,
  ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(PARTITION BY member_casual), 2) AS pct_of_group_total,
  ROUND(AVG(ride_length_min), 2) AS avg_ride_length_min
FROM 
  `alert-basis-504812-j0.cyclistic_projekt.cyclistic_cleaned`
GROUP BY 
  month,
  month_name,
  member_casual
ORDER BY 
  member_casual,
  month;
/*
-------------------------------------------------------------------------------
Výsledky daného scriptu.
-------------------------------------------------------------------------------
1. Extrémní sezónní závislost u casual jezdců:
   - Letní vrchol (prázdniny): Červenec a srpen tvoří dohromady téměř 31 % veškerého ročního objemu 
     casual výpůjček (červenec: 326 215 jízd; 15,76 %, srpen: 308 072 jízd; 14,89 %).
   - Zimní propad: V lednu aktivita klesá na absolutní minimum (18 647 jízd; 0,90 %).
   - Rozdíl mezi létem a zimou představuje u casual zákazníků propad o více než 94 %.

2. Větší stabilita členské základny (Members):
   - Ačkoliv letní měsíce představují vrchol i pro členy (srpen: 479 663 jízd; 12,61 %), 
     členové vykazují mnohem vyrovnanější křivku po celý rok.
   - V lednu členové realizují 132 108 jízd (3,47 %), což je 7× více než casual jezdci.
   - Pokles v zimních měsících je též znatelný, members si ale udržují systém pro dojíždění i v zimě.

3. Konzistence doby jízdy:
   - Casual jezdci prodlužují své vyjížďky na jaře a v létě (květen–červenec: průměrně 19,5–20,3 min), 
     zatímco v zimě se jejich jízdy zkracují k 14–15 minutám.
   - U členů zůstává průměrná délka stabilní napříč všemi 12 měsíci (mezi 10,7 a 13,0 min), což potvrzuje
     využívání k dojíždění do práce či školy.
*/

-- -----------------------------------------------------------------------------
-- ČÁST 5: PREFERENCE DRUHŮ KOL V NEJVYTÍŽENĚJŠÍ STANICE VÝPŮJČKY
-- -----------------------------------------------------------------------------

-- Poslední čistě analytická část tohoto souboru je věnována analýze druhu kol (elektric/classic), které jednotlivé
-- skupiny pro své výpůjčky využívají. Závěrem též získáme přehled nejvytíženějších stanic z hlediska využití zákazníky.
-- Na tuto část navazuje i otázka, jestli někteří zákazníci více preferují tzv. okružní cesty (stejná startovní i konečná
-- stanice).

-- preference typů kol a okružní cesty
SELECT 
  member_casual,
  rideable_type,
  COUNT(*) AS total_trips,
  ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(PARTITION BY member_casual), 2) AS pct_of_group_total,
  COUNTIF(is_round_trip) AS round_trip_count,
  ROUND(COUNTIF(is_round_trip) * 100.0 / COUNT(*), 2) AS pct_round_trip,
  ROUND(AVG(ride_length_min), 2) AS avg_ride_length_min
FROM 
  `alert-basis-504812-j0.cyclistic_projekt.cyclistic_cleaned`
GROUP BY 
  member_casual,
  rideable_type
ORDER BY 
  member_casual,
  total_trips DESC;
-- nejvytíženější stanice
WITH ranked_stations AS (
  SELECT 
    member_casual,
    start_station_name,
    COUNT(*) AS trip_count,
    ROUND(AVG(ride_length_min), 2) AS avg_ride_length_min,
    ROW_NUMBER() OVER (PARTITION BY member_casual 
      ORDER BY COUNT(*) DESC) AS station_rank
  FROM 
    `alert-basis-504812-j0.cyclistic_projekt.cyclistic_cleaned`
  WHERE 
    start_station_name IS NOT NULL
  GROUP BY 
    member_casual,
    start_station_name
)
SELECT 
  station_rank,
  member_casual,
  start_station_name,
  trip_count,
  avg_ride_length_min
FROM 
  ranked_stations
WHERE 
  station_rank <= 10
ORDER BY 
  member_casual,
  station_rank;

/*
-------------------------------------------------------------------------------
Výsledky daných skriptů.
-------------------------------------------------------------------------------
1. Dominance elektrokol (electric_bike):
   - Elektrokola tvoří většinu jízd u obou skupin: 70,62 % u casual jezdců 
     (1 461 411 jízd) a 66,42 % u členů (2 527 375 jízd).
   - Klasická kola (classic_bike) představují pouze 29,38 % u casual a 33,58 % u members.
2. Trvání jízdy podle typu kola:
   - Klasická kola u casual jezdců slouží pro výrazně delší vyjížďky 
     (průměr 29,01 min) oproti elektrokolům (14,72 min).
   - U členů je rozdíl v délce minimální (classic: 13,90 min vs. electric: 11,42 min), což opět
     ukazuje spíše na účelový přesun.
3. Výrazný kontrast v okružních jízdách (is_round_trip):
   - U casual jezdců končí na stejné stanici 10,28 % všech jízd na klasických kolech 
     (62 496 jízd), což potvrzuje rekreační charakter a vyjížďky „tam a zpět“.
   - U členů tvoří okružní jízdy pouhých 1,03 % na elektrokolech a 2,47 % na klasických 
     kolech – drtivá většina (přes 98 %) jejich cest je čistě bod A -> bod B. Což odpovídá
     našemu původnímu předpokladu, že kola využívají na dojíždění do práce či školy.
4. Casual cyklisté a geografie:
   - Masivní koncentrace kolem jezera Michigan v čele s Navy Pier (53 883 jízd)
     a DuSable Lake Shore Dr & Monroe St (31 891 jízd).
   - Průměrná délka výpůjčky se u top stanic pohybuje mezi 25 až 33 minutami,
     což jednoznačně potvrzuje turistický a rekreační charakter jízd.
5. Members cyklisté a geografie:
   - Dominance terminálů u nádraží a obchodního centra (The Loop) v čele 
     s Canal St & Madison St (22 703 jízd) u Ogilvie Transportation Center 
     a Clinton St & Jackson Blvd (19 392 jízd) u Union Station.
   - Průměrná délka je u všech klíčových stanic vysoce stabilní (10–11 minut),
     což reprezentuje využití při pravidelném dojíždění do zaměstnání.
-------------------------------------------------------------------------------
*/
