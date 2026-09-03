# google-data-analytics-cyclistics
Tento projekt slouží jako komplexní případová studie pro portfolio datového analytika. Sleduje proces analýzy dat od A do Z (podle frameworku Google Data Analytics: Ask, Prepare, Process, Analyze, Share, Act) pro fiktivní společnost.

## Odkazy:

## 1. FÁZE: ASK
### Byznysový kontext a cíl projektu
Fiktivní splečnost **Cyclistic** provozuje v Chicagu bike-share program s přibližně 5 800 koly a téměř 700 stanicemi. Zákazníci, na které společnost cílí, se řadí do dvou skupin:
* **Casual riders:** Zákazníci využívající jednorázové nebo celodenní jízdenky.
* **Cyclistic members:** Zákazníci s ročním členstvím.
Finanční analýza společnosti ukázala, že zákazníci s **ročním členstvím** jsou pro společnost z hlediska profitu mnohem zajímavější.

### Klíčový úkol (business task)
* ,,Jak se liší chování zákazníků s ročním členstvím od zákazníku s jednorázovým/celodenním jízdným?''

Cílem této analýzy je tedy identifikovat rozdíly v chování těchto zákazníků a poskytnout marketingovému týmu podklady pro tvorbu cílených kampaní.

## 2. FÁZE: PREPARE
### Zdroje dat, organizace
Pro tuto analýzu byla stažena a připravena historická data o jízdách fiktivní společnosti Cyclistic za posledních 12 měsíců (období **srpen 2025 až červenec 2026**).
* Data byla poskytnuta společností *Motivate International Inc.* Data jsou veřejně přístupná na základě licenčního ujednání [Divvy Data License Agreement](https://divvybikes.com/data-license-agreement). Licence umožňuje data volně analyzovat a prezentovat výsledky za předpokladu dodržení podmínek ochrany soukromí (zákaz de-anonymizace uživatelů a komerčního přeprodeje surových dat).
* Každý měsíc je uložen jako jeden zazipovaný soubor, který obsahuje data za daný měsíc ve formátu 'csv'.
* Datové soubory popisují každou jízdu (ID jízdy, typ kola, čas zahájení/ukončení, stanice a jejich ID, GPS souřadnice a typ uživatele: member vs. casual).
### Ověření důvěryhodnosti dat
* **Spolehlivá**: Velké množství anonymizovaných logovaných dat (data jsou sbírána přímo pomocí jednotlivých kol).
* **Originální**: Data jsou přímo od oficiálního provozovatele systému, Motivate International Inc..
* **Komplexní**: Soubory obsahují všechna potřebná data pro zodpovězení úkolu, tj. časy zahájení/ukončení, typy kol atd..
* **Aktuální**: Datový soubor je pravidelně aktualizován (každý měsíc jsou přidána nová data), pracujeme tedy s aktuálními informacemi.
* **Citovaná**: Víme, kdo daný datový soubor vydal a pod jakou byl vydán licencí (viz výše).

### Rozsah datového souboru
* Celkový objem dat představuje 12 měsíčních souborů, přibližně 28 MB v zazipovaném stavu (jeden soubor)  a celkově zhruba 6 milionu řádků záznamů o jízdách.

## 3. FÁZE: PROCESS
### Výběr nástroje
Jakožto pracovní nástroj na zpracování takto rozsáhlého datového souboru jsme zvolili SQL, konkrétně BigQuery. Takovouto volbu jsme provedli hlavně z důvodu efektivnější práce s velkým množstvím řádků, klasický tabulkový procesor by byl značně neefektivní.

### Kontrola kvality dat
Před samotnou tvorbou nové vyčištěné tabulky jsme provedli analýzu integrity dat a snažili se objevit nepřesnosti a chyby.
* **Duplicity v primárním klíči (`ride_id`):** Identifikováno 35 duplicitních ID. Po aplikaci časových filtrů zůstalo v datech 14 párů.
* **Časové anomálie (`ended_at <= started_at`):** Odhaleno celkem 6 řádků (1 systémový paradox, kdy jízda skončila dříve, než začala, a 5 jízd trvajících méně než 1 celou sekundu, zaokrouhlených na 0 s).
* **Příliš krátká odemknutí kola (< 60 s, stejná stanice):** Nalezeno cca 40 000 záznamů, kdy uživatel kolo vrátil do minuty do stejného stanice (rozmyslel si výpůjčku, technická chyba).
* **Příliš dlouhé odemknutí kola (> 24 hodin):** Našli jsme cca 5 300 odlehlých jízd trvajících více než den (možná zapomenutá nebo ukradená kola).
* **Servisní záznamy:** Jedna jízda byla testovací, tj. proběhla z testovací stanice. (`TEST`)
* **Proměnné obsahující omezený počet možností:** Sloupce `member_casual` a `rideable_type` byly 100%  bez překlepů.
* **Chybějící hodnoty (NULL):** Zjištěno ~1,27 mil. chybějících názvů startovních stanic a ~1,34 mil. cílových stanic. Tyto záznamy **nebyly smazány**, jelikož to jsou jízdy, které jsou relevantní pro analýzu (kolo nemuselo být například vráceno/půjčeno ve stanici). Smazání by citelně zmenšilo zkoumaný soubor.

### Tvorba nových metrik
* `ride_length_sec` a `ride_length_min`: Doba trvání výpůjčky v sekundách a zaokrouhlených minutách přes `TIMESTAMP_DIFF`.
* `day_of_week`: Den v týdnu jako celé číslo (1 = Neděle, 7 = Sobota).
* `day_of_week_name`: Textový název dne (`FORMAT_TIMESTAMP('%A', ...)`) pro přímé použití v Tableau.
* `start_hour`: Hodina začátku jízdy (0–23) pro identifikaci denních špiček.
* `month` & `month_name`: Číselné i textové vyjádření měsíce pro analýzu sezónnosti.
* `is_round_trip`: Klasikace jízd podle toho, jestli jsou okružní nebo nejsou.

### Bilance čištění a tvorba nové tabulky
Čištění dat a vytvoření nových metrik bylo provedeny v jediném SQL skriptu, který je k nalezení v `sql/01_data_cleaning.sql`
| Metrika | Surová data (`cyclistic_combined`) | Čistá data (`cyclistic_cleaned`) | Rozdíl / Úbytek |
| :--- | :--- | :--- | :--- |
| **Celkový počet řádků** | ~5 920 000 | **5 874 677** | -45 323 (-0,77 %) |
| **Duplicity (`ride_id`)** | 35 | **0** | Vyřešeno |
| **Minimální délka jízdy** | <= 0 s | **1 s** | Očištěno |
| **Maximální délka jízdy** | > 24 h | **86 398 s** (< 24 h) | Očištěno |
| **Nevalidní délky (<= 0)** | 6 | **0** | 100% integrita |
| **Testovací stanice** | 1 | **0** | Odfiltrováno |

Celková integrita datového souboru byla zachována z **99,23 %**.

## 4. FÁZE: ANALYSE
V této fázi jsme provedli analýzu dat nad vyčištěnou tabulkou `cyclistic_cleaned` v prostředí Google BigQuery. Cílem této analýzy bylo odpovědět na hlavní otázku, položenou v úvodní části: **V čem přesně se liší chování ročních členů (`member`) a jednorázových uživatelů (`casual`)?**

Kompletní analytické dotazy a metriky jsou zdokumentovány ve skriptu `sql/02_exploratory_analysis.sql`.

### 1. Celkový objem výpůjček a doba jejich trvání
Základní provedená statistika odhalila výrazný nepoměr mezi počtem realizovaných jízd a dobou strávenou na kole:
| Uživatelský segment | Počet jízd (`total_trips`) | Podíl na trhu (`%`) | Průměrná délka (`avg_min`) | Medián délky (`median_min`) |
| :--- | :--- | :--- | :--- | :--- |
| **Casual** | 2 069 377 | 35,23 % | **18,92 min** | **11,47 min** |
| **Member** | 3 805 281 | **64,77 %** | 12,25 min | 8,73 min |

* **Klíčové zjištění:** Předplatitelé (members) tvoří stabilní část provozu (téměř dvě třetiny všech výpůjček). Nicméně jízdy rekreačních `casual` jezdců jsou v průměru o **54 % delší**. 

### 2. Týdenní přehled: Dojíždění vs. rekreace 
Statistika, kterou jsme provedli, odhalila zřejmě zásadně odlišnou motivaci pro používání sítě výpůjčky kol.
| Den v týdnu | Počet jízd (Casual) | Podíl týdne (Casual) | Počet jízd (Member) | Podíl týdne (Member) |
| :--- | :--- | :--- | :--- | :--- |
| **Pondělí** | 235 233 | 11,37 % | 527 644 | 13,87 % |
| **Úterý** | 229 875 | 11,11 % | 601 753 | 15,81 % |
| **Středa** | 237 508 | 11,48 % | **610 431** | **16,04 %** |
| **Čtvrtek** | 258 330 | 12,48 % | 606 460 | 15,94 % |
| **Pátek** | 327 152 | 15,81 % | 569 452 | 14,96 % |
| **Sobota** | **438 754** | **21,20 %** | 483 142 | 12,70 % |
| **Neděle** | 342 525 | 16,55 % | 406 399 | 10,68 % |

* **Members (práce, škola):** Aktivita předplatitelů je nejvyšší v období od úterý do čtvrtka (Út–Čt tvoří téměř 48 % jejich celkového objemu). O víkendech dochází k výraznému útlumu (neděle tvoří pouze 10,68 %).
* **Casual (odpočinek):** Poptávka jednorázových uživatelů strmě roste od pátku a vrcholí v sobotu (21,20 %). Samotný víkend (So–Ne) představuje **37,75 % veškerých jejich výpůjček**, přičemž průměrná délka víkendové jízdy dosahuje **21,5 až 22 minut** (oproti ~16 min v týdnu).

### 3. Denní dopravní špičky (vliv denní doby)
Analýza nejvytíženějších hodin zřejmě potvrzuje zjištění v předchozí části, tj. různou motivaci pro využití.
* **Dvě špičky u members:** Členská základna vykazuje dva výrazné špičkové časy odpovídající začátku a konci pracovní doby:
  * **Ranní špička:** 08:00 (277 896 jízd; 7,30 % objemu).
  * **Odpolední špička:** 17:00 (410 084 jízd; 10,78 % objemu).
  * Časové okno mezi 16:00 a 18:00 vykazuje téměř 29 % veškerého denního provozu členů.
* **Preference odpoledne u casual:** Rekreační zákazníci ranní dopravní špičku nemají (v 08:00 realizují pouze 3,56 % svých cest). Aktivita plynule roste od dopoledne a dosahuje vrcholu v 17:00 (195 899 jízd; 9,47 %), přičemž nejdelší průměrné jízdy (22–23 minut) probíhají v poledních hodinách (10:00–14:00).

### 4. Sezónnost a vliv počasí (roční období)
Vliv měsíců je zřejmě vidět i u rozdílného rozložení poptávky členů a casual cyklistů.
* **Letní sezónní vrchol u casual zákazníků:** Poptávka je nejvyšší v červenci (326 215 jízd) a srpnu (308 072 jízd), které dohromady tvoří téměř 31 % jejich celoročního objemu. V lednu naopak klesá na absolutní minimum (18 647 jízd; 0,90 %), což představuje **meziroční sezónní propad o více než 94 %**.
* **Větší odolnost členské základny (members):** Členové si udržují stabilnější bázi po celý rok pro účely každodenní dopravy. V lednu členové realizovali 132 108 jízd, což je **7× více než casual jezdci** ve stejném období. I u nich je ale logický propad v zimních měsících.

### 5. Preference vybavení a geografický vliv
Z analýzy typů kol, okružních tras a nejvytíženějších stanic vyplynuly tyto zajímavé ukazatele:
* **Typy kol:** Obě skupiny preferují elektrokola – tvoří **70,62 %** jízd u casual a **66,42 %** u předplatitelů. Klasická kola u casual jezdců slouží pro nejdelší vyjížďky s průměrnou délkou **29,01 minuty**.
* **Okružní jízdy:** U casual jezdců končí na stejné výchozí stanici **10,28 %** všech jízd na klasických kolech. Naproti tomu u členů končí na stejné stanici pouze **1–2 %** jízd – přes 98 % tras členů představuje přímou jednosměrnou dopravu z bodu A do bodu B.
* **Top stanice:**
  * **Casual (Turismus & Pobřeží):** Žebříčku dominují rekreační zóny podél jezera Michigan – *Streeter Dr & Grand Ave (Navy Pier)* (53 883 jízd), *DuSable Lake Shore Dr* a *Millennium Park* s průměrnou dobou jízdy **25–33 minut**.
  * **Members (Doprava & Business):** Žebříček vedou terminály v těsné blízkosti vlakových nádraží a obchodního centra (The Loop) – *Canal St & Madison St* (22 703 jízd) u Ogilvie Transportation Center či *Clinton St & Jackson Blvd* u Union Station s konzistentním trváním **10–11 minut** (typické pro účelové dojíždění).
 
 ### Shrnutí analýzy

| Dimenze chování | Roční člen (`Member`) | Jednorázový uživatel (`Casual`) |
| :--- | :--- | :--- |
| **Hlavní motivace** | Každodenní dojíždění do zaměstnání / školy.| Víkendový relax, fitness, turistika. |
| **Typická délka jízdy** | Krátká a efektivní (medián 8,7 min). | Dlouhá a vyhlídková (medián 11,5–13,5 min). |
| **Vrchol týdne** | Úterý až čtvrtek (pracovní dny). | Pátek až neděle (víkendový nárůst). |
| **Denní profil** | Dvě špičky (ranní špička 08:00, odpolední 17:00).| Jedna špička (plynulý odpolední nárůst k 17:00).|
| **Sezónní chování** | Celoročně stabilní (dojíždění i v zimě). | Silně závislé na počasí (útlum v zimě). |
| **Typické lokality** | Nádraží, přestupní uzly MHD, kancelářské zóny.| Pobřeží jezera, parky, turistické atrakce. |

## 5. FÁZE: SHARE
Pro vizuální komunikaci výsledků a data storytelling byl zvolen nástroj **Tableau Public**. Data použitá pro analýzu byla získána pomocí BigQuery na základě scriptů z `03_summary_for_tableau.sql`.

### Klíčové vizuální výstupy
1. **Executive Dashboard (1366 × 768 px):** Jednostránkový manažerský přehled obsahující horní souhrnné KPI karty (celkový objem jízd, tržní podíl členů vs. casual a průměrné trvání jedné jízdy) a mřížku 2x2 klíčových grafů:
   * *Denní dopravní špičky:* Ukazuje dvě křivky členů (špičky v 8:00 a 17:00) vs.  odpolední špičku casual cyklistů.
   * *Týdenní přehled:* Demonstruje dominanci členů od úterý do čtvrtka a silný víkendový nárůst u casual uživatelů (So–Ne tvoří téměř 38 % jejich objemu).
   * *Sezónní křivka:* Vizualizuje celoroční stabilitu předplatitelů a 94% letní vrchol/zimní propad u jednorázových jezdců.
   * *Struktura typů kol:* Porovnání obliby elektrokol (~66–70 %).
2. **Geografický přehled (Mapa Chicaga):** Interaktivní bodová mapa znázorňující prostorovou koncentraci casual cyklistů podél pobřeží jezera Michigan a u turistických atrakcí (Navy Pier, Millennium Park) oproti rovnoměrnému pokrytí dopravních uzlů a rezidenčních čtvrtí členy.

**Živá interaktivní vizualizace na Tableau Public:**  
*[(https://public.tableau.com/views/google-data-analytics-cyclistics/CyclisticExecutiveDashboard?:language=en-US&:sid=&:redirect=auth&:display_count=n&:origin=viz_share_link)](https://public.tableau.com/views/google-data-analytics-cyclistics/CyclisticExecutiveDashboard?:language=en-US&:sid=&:redirect=auth&:display_count=n&:origin=viz_share_link)*

## 6. FÁZE: ACT
---

## 6. Fáze: ACT (Závěr a strategická doporučení)
Hlavním cílem této případové studie bylo zodpovědět otázku, týkající se využití kol různými skupinami zákazníků: **Jak se liší vzorce chování předplatitelů (members) a příležitostných jezdců (casual), a jak tato data využít k efektivní konverzi casual uživatelů na roční členy?**

Na základě analýzy 5 874 677 vyčištěných jízd a geografického i časového modelování formulujeme **Top 3 konkrétní byznysová doporučení**:

### 1. Zavedení nového produktu: Víkendové a letní sezónní členství
* **Datový podklad:** Příležitostní jezdci vykazují extrémní nárazovost poptávky – víkendy (sobota a neděle) tvoří téměř **38 % jejich celkového objemu jízd** a letní sezóna představuje vrchol jejich aktivity, zatímco v zimních měsících jejich využívání služby prakticky zamrzá. Plné členství je ale pro ně zbytečné, protože využívají kolo pouze pro rekreaci a nikoliv dojíždění do práce.
* **Doporučení pro marketing:** Vytvořit mezistupeň v cenové politice – např. **Weekend Pass** (neomezené víkendové jízdy) nebo **Summer Membership** (květen–září). Tento produkt zachytí rekreační uživatele a umožní vznik mezistupně mezi klasickým členstvím a úplným nečlenstvím.

### 2. Cílené notifikace vázané na polohu poblíž jezera Michigan
* **Datový podklad:** Geografická analýza potvrdila, že poptávka casual jezdců je silná podél pobřeží jezera Michigan (stanice *Streeter Dr & Grand Ave*, *Navy Pier*, *Millennium Park* a *Lakefront Trail*). Navíc jejich aktivita kulminuje v pátek odpoledne a o víkendech od 13:00 do 17:00.
* **Doporučení pro marketing:** Spouštět automatizované mobilní kampaně vázané na geolokaci a čas. Pokud si casual jezdec odemkne kolo v pátek odpoledne nebo o víkendu u pobřežních stanic, aplikace mu nabídne okamžitou promo akci na registraci členství. Zároveň tyto klíčové pobřežní uzly představují ideální lokace pro fyzickou promotion a testovací stánky během letních měsíců.

### 3. Komunikační kampaň: Personalizovaná kalkulačka finanční úspory
* **Datový podklad:** Příležitostní jezdci tráví na kole výrazně více času na jednu výpůjčku než členové (průměrná délka výpůjčky casual jezdců dosahuje téměř **19 minut**, zatímco členové jezdí efektivně kolem 12 minut). Při platbách za jednotlivé odemčení a minutové sazby casual jezdci při pravidelnějším víkendovém ježdění přeplácejí cenu ročního předplatného.
* **Doporučení pro marketing:** Využít e-mailový marketing a transakční obrazovky v aplikaci po skončení jízdy. Prezentovat uživateli srovnání nákladů na reálném příkladu: *„Tento měsíc jste za víkendové vyjížďky utratili $X. S ročním členstvím by vás stejný počet jízd vyšel na polovinu a ušetřili byste $Y.“* Transparentní komunikace úspory prokazatelně funguje na rekreační jezdce s vyšší frekvencí výpůjček.


## O autorovi
* **Autor:** Lukáš Weissgráb
* **Nástroje projektu:** Google BigQuery (SQL), Tableau Public, Git / GitHub
* **Portfolio & Odkazy:** [LinkedIn](www.linkedin.com/in/lukáš-weissgráb-3ba51428a) | [Tableau Public](https://public.tableau.com/app/profile/lukas.weissgrab/vizzes)
