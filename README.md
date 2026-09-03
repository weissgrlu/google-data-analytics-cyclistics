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
