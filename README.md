---
# SQL_DATA_WAREHOUSE_LOOKER_REPORTS
---
Projekt k zakončení kurzu Czechitas - Datové inženýrství v praxi. Od expertů na data z firmy Revolt BI jsme obdrželi jako vstup anonymizovaná reálná data. Hlavním cílem projektu bylo vytvořit datový sklad a připravit pro klienta report v Looker Studiu, na základě kterého lze zodpovědět businessové otázky klienta.

---
## Technologie a nástroje
---
* SQL
* Google Cloud Platform 
  * BigQuery - datový sklad
  * Cloud Storage - ukládání dat
  * Looker Studio - vizualizace a dashboardy
  * Pozn.: V rámci kurzu jsme se též v rámci jiného (menšího) projektu krátce seznámili s nástrojem Cloud Composer pro orchestraci dat.
* Drawio - modelování (Business Data model, DAG model, atd.)

---
## Zadání projektu
---
Tvým úkolem v průběhu kurzu je vytvořit datový sklad a připravit pro klienta report v Looker Studiu, na základě kterého zodpovíš businessové otázky klienta. Své závěry následně krátce odprezentuješ ostatním účastnicím a lektorovi.<br>

**BUSINESSOVÉ ZADÁNÍ:**<br>
Kdo je tvůj klient?<br>
Oslovil tě klient poskytující digitální služby. Z důvodu lepšího zacílení marketingových kampaní v následujícím období potřebuje analyzovat chování svých zákazníků a na základě poskytnutých dat zodpovědět otázky: 

1) Kteří zákazníci a kdy odcházejí?<br>
2) Nakupují málo/hodně?<br>
3) Existují ještě produkty, které nakupovali?<br>

Nápověda: Zadání nemusí obsahovat všechny informace, které potřebuješ. Neboj se tedy doptávat klienta.<br>
Nápověda: Kdyby náš klient věděl, co mu z jeho dat vyplývá a jak je řídit, nepotřeboval by vaši konzultaci. Z tohoto důvodu jsme pro potřeby kurzu vytvořili klienta, který tak trochu neví, co by měl chtít, aby vám to dalo prostor pro přemýšlení. Není jediná správná cesta, jak na data pohlížet.<br>

Zde je odkaz na [Zadání projektu](https://docs.google.com/presentation/d/1iGh9jPBaf_gQeIXWkeGfsr5ytwCyadcTPqpacSL1nLw/edit?usp=sharing)

Kromě businessového zadání jsme obdrželi následující **TECHNICKÉ PODKLADY**:
* Požadavky na definice tabulek
    * Google sheet s definicí tabulek obsahuje záložky L0, L1, L2, ve kterých jsou uvedeny detailní požadavky pro tabulky v jednotlivých vrstvách datového skladu L0, L1, L2. U každé tabulky jsou požadavky na název tabulky, popis tabulky pro účely dokumentace, názvy sloupců, datové typy sloupců, popisy sloupců a příp. další logiku, kterou má tabulka či jednotlivé sloupce splňovat.<br>
    * Zde je odkaz na [Požadavky na definice tabulek](https://docs.google.com/spreadsheets/d/1lnZX6YGuYmDbdjT-_SWmQHqVvUP41Q-qgKdmTvIgEYQ/edit?usp=sharing)<br>
* Zadání pro tvorbu vrstev L0, L1, L2
    * V souborech se zadáním pro tvorbu vrstev je popsáno, jakým způsobem ke tvorbě jednotlivých vrstvev přistupovat. U vrstev L1 a L2 je součástí i checklist požadavků, které mají být při tvorbě vrstvy splněny. Pro vrstvu L3 zadání zadání nebylo a vytvářeli jsme si ji dle vlastního uvážení, abychom dokázali na základě dat zodpovědět businessové otázky.<br>
    * Zde je odkaz na [Zadání pro tvorbu L0](https://docs.google.com/document/d/1Sb9YRAM2DMfwdiAcCqD21LTrv5FzOeIc54W4xgUHQDM/edit?usp=sharing)<br>
    * Zde je odkaz na [Zadání pro tvorbu L1](https://docs.google.com/document/d/1ScjtT8NpM__pvcLD2Wo-N4aS47OrngccOtTZzTT_-jA/edit?usp=sharing)<br>
    * Zde je odkaz na [Zadání pro tvorbu L2](https://docs.google.com/document/d/1bxdqGh7H_8Yob5oPGZ5RtzXq2C38D7JBOlYBWUmo3y0/edit?usp=sharing)<br>

---
## Datová sada
---

V rámci projektu jsme jako vstup od firmy Revolt BI obdrželi anonymizovaná reálná "dirty" data, která bylo nutné vyčistit a transformovat skrze jednotlivé vrstvy datového skladu až do podoby výsledného reportu, který zodpovídá businessové otázky klienta.

Zdrojová data jsme obdrželi ve formě
1) rozsáhlých .csv souborů pocházejících ze systémů: CRM; Accounting_system<br>
2) Google Sheet s číselníky<br>

Zde je odkaz na složku se zdrojovou datovou sadou: [Source_data_set](https://drive.google.com/drive/folders/1nasg61l56beFwORaL4lRVYYouEmQUAT-?usp=drive_link)

---
## Výstup projektu
---

1) Datový sklad v BigQuery. SQL dotazy z procesu tvorby datového skladu viz [Queries](/Queries/).<br>
   Na obrázku níže jsem znázornila model vytvořeného datového skladu.

    ![DWH_model](/Resources/DWH_model.drawio.png)

2) Looker Studio report, který je napojen na tabulky L3 vrstvy (Serving layer) datového skladu a kde lze najít odpovědi na businessové otázky klienta.
    
    Zde je odkaz na [Looker Studio report](https://lookerstudio.google.com/s/qR4a9vwV5gc)
    
    Podkladem pro Looker Studio report je vrstva L3 (Serving layer) datového skladu, kterou tvoří následující 2 tabulky:
    * `L3_main_report` - hlavní flat tabulka, která obsahuje zgrupované všechna data z tabulek contract, product_purchase, invoice, která jsou relevantní pro reporting
    * `L3_main_report_cu` - tabulka s údaji o zákaznících (=kontraktech), odvozená z hlavní tabulky, kde 1 řádek = 1 kontrakt. Narozdíl od hlavní tabulky neobsahuje detailní údaje o všech product_purchase, takže se s ní lépe pracuje při přípravě reportů, které se vážou k zákazníkovi a ne ke konkrétním nákupům.<br>
    Zde je odkaz na [Final_reporting_data_(L3)](https://drive.google.com/drive/folders/1N1WG57vw4H923iNQV5phr02dI5Us7aw0?usp=drive_link)
    
    Pozn.: Během projektu byl Looker Studio report napojen přímo na tabulky v BigQuery v rámci 3-měsíčního trialu. Před vypršením BigQuery trialu jsem výsledné L3 tabulky převedla do souborů .csv a napojila jsem Looker Studio report na .csv soubory. Vykreslování některých stran reportu je v důsledku napojení na .csv soubory pomalejší, než při napojení na BigQuery.
    
[Postup řešení](Postup_reseni.md)
