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


