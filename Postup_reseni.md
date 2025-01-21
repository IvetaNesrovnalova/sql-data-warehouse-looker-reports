---
# POSTUP ŘEŠENÍ
---

---
## Vrstva L0 (Ingestion layer)
---

Obecná charakteristika vrstvy L0:

* Zde si stahuji data přesně tak, jak jsem je dostal od zdroje. 
* S daty se nic nedělá, aby se dalo vždy zpětně zjistit, co jsem dostal od zdrojového systému. 
* Jediná výjimka je historizace.

Postup:

Na Google Drive jsme obdrželi zdrojová data [Source_data_set](https://drive.google.com/drive/folders/1nasg61l56beFwORaL4lRVYYouEmQUAT-?usp=drive_link) ze systémů accounting_system a crm ve formátu .csv a Google Sheet se 3 číselníky. Cílem bylo přenést tato data do BigQuery. 

1) Z Google Drive jsem si stáhla zdrojové .csv soubory s daty ze zdrojových systémů accounting_system a crm.

2) V Cloud Storage (součást GCP) jsem vytvořila podle zdrojových systémů 2 buckety, do kterých jsem nahrála .csv soubory: 
    accounting_system -> invoice.csv
    crm -> contracts.csv, product_purchases.csv
    
3) V BigQuery jsem vytvořila 2 datasety s názvy podle zdrojového systému (L0_crm, L0_accounting_system)

4) Nad každou tabulkou z bucketu v odpovídajícím datasetu jsem vytvořila externí tabulku. Požadavkem bylo, abychom zde měli v BigQuery automaticky navržené datové typy a abychom k tabulkám a sloupcům přidali i dokumentaci dle zadání [Požadavky na definice tabulek](https://docs.google.com/spreadsheets/d/1lnZX6YGuYmDbdjT-_SWmQHqVvUP41Q-qgKdmTvIgEYQ/edit?usp=sharing). Nejdříve jsem vyzkoušela vytvořit tabulky "klikacím způsobem", abych zjistila, které datové typy jsou automaticky navržené. Následně jsem takto založené tabulky smazala a vytvořila SQL skript, ve kterém jsem při definici tabulek použila automaticky navržené datové typy a zároveň jsem do SQL skriptu přidala i dokumnetaci k tabulkám a sloupcům. Vytvoření tabulky skriptem má výhodu v tom, že lze spouštět opakovaně a opakovaně se i k tabulkám a sloupcům přidá i dokumentace. Lze jednoduše tabulky smazat, ve skriptech něco upravit a znovu spustit a vytvoří se obměněná tabulka s minimální námahou. Zároveň lze snadno takto vytvořený skript jednoduše přidat do nástroje pro orchestraci dat. Kdežto pokud bych měla tabulky naklikané ručně, v případě smazání tabulky by se smazala i všechna ručně přidaná dokumentace a bylo by nutné vše pracně naklikávat znovu a nešlo by s tímto pracovat při orchestraci dat.

5) V BigQuery jsem vytvořila dataset L0_google_sheets, do kterého jsem vytvořila externí tabulky napojené na zdrojové google sheets (status, all_products, branch). Opět jsem postupovala tak, že jsem si externí tabulky napojenou na Google Sheet napřed ručně naklikala, abych zjistila automaticky navržené datové typy a následně jsem tabulky smazala a na vše vytvořila SQL skript i s dokumentací k tabulkám a sloupcům.

    Výsledná struktura tabulek v BigQuery:

    ![L0_tables_structure](/Resources/L0_tables_structure.PNG)

6) Pro každou tabulku jsem napsala testy:
    * Test na kontrolu unikátních záznamů primárního klíče
    * Test na kontrolu null hodnot primárního klíče
    * Test na kontrolu null hodnot dalších vybraných sloupců
    * Test na referenční integritu v příp. existence cizích klíčů v tabulce
    * Test na kontrolu, že vybrané sloupce obsahují pouze určitý výčet hodnot

7) Na základě testů jsem si pro každou tabulku napsala návrhy na tranformace pro vrstvu L1, kde se čistí data, tzn. návrhy jako:
    * Odstranění duplicitních záznamů
    * Odstranění záznamů s null hodnotami
    * Sjednocení velikost písmen
    * Přetypování sloupců
    * Přidání konvertovaných sloupců

---
## Vrstva L1 (Staging layer)
---

Obecná charakteristika vrstvy L1:

* Zde mám data, která odpovídají standardům firmy. 
* Např. se sjednocuje formát datumů nebo měn. 
* Data se organizují podle zdrojového systému.
* Testuji kvalitu dat a aplikuji pravidla, která jsou source specific.

Postup:

1) V BigQuery jsem vytvořila dataset L1_all_tables.

2) Nad každou tabulkou z vrstvy L0 jsem v datasetu L1_all_tables vytvořila view, které zahrnuje transformace L0 tabulek do L1 dle následujících pravidel:
    * Uplatňuji navržené transformace na základě testů z L0.
    * Provádím transformace dle zadání [Požadavky na definice tabulek](https://docs.google.com/spreadsheets/d/1lnZX6YGuYmDbdjT-_SWmQHqVvUP41Q-qgKdmTvIgEYQ/edit?usp=sharing).
    * Zohledňuji další požadavky, které jsou uvedeny v [L1 checklist](https://docs.google.com/document/d/1Sb9YRAM2DMfwdiAcCqD21LTrv5FzOeIc54W4xgUHQDM/edit?usp=sharing).

3) Pro každé view jsem vytvořila skripty pro doplnění dokumentace.

4) Pro každé view jsem napsala testy:
    * Test na kontrolu unikátních záznamů primárního klíče
    * Test na kontrolu null hodnot primárního klíče
    * Test na kontrolu null hodnot dalších vybraných sloupců
    * Test na referenční integritu v příp. existence cizích klíčů v tabulce
    * Test na kontrolu, že vybrané sloupce obsahují pouze určitý výčet hodnot
    * Test na kontrolu počtu záznamů ve vrstvě L0 vs. L1. 

    Pozn.: Díky tomuto testu jsem např. zjistila, že v tabulce L1_product_purchase je nutno mít přidané i transformace pro připojené tabulky product_status a product, jinak by docházelo k nekonzistencím. Do L1 transformace této tabulky jsem přidala transformace těchto tabulek přímo z L0 vrstvy. Zvažovala jsem i přístup, že bych L1_product_purchase napojila rovnou na již vytvořené L1_product a L1_product_status, ale pak by bylo nutné při orchestraci dat pohlídat, že prvně budou vytvořeny L1_product_status, a L1_product. Rozhodla jsem se, že vytvoření L1_product_purchase nechám nezávislé na L1_product_status a L1_product, proto dávám transformace L0_status, L0_product přímo jako CTE při vytvoření L1_product_purchase.

    Výsledky z testů na L0 a L1 vedly k dotazům na business stakeholdera i na zadávající datové inženýry. Zadání nebylo kompletní a bylo třeba na této úrovni několik věcí dospecifikovat.

---
## Vrstva L2 (Core layer)
---

Obecná charakteristika vrstvy L2:

* Zde tvořím pravý datový sklad - data už jsou seskupená podle businessových definic. 
* Např. zde najdu tabulku zákazníků nebo transakcí. 
* Aplikuji zde definice metrik podle celofiremních definic.

Postup:

1) V BigQuery jsem vytvořila dataset L2_all_tables.

2) Podle zadání Požadavky na definice tabulek jsem nad 4 požadovanými tabulkami z vrstvy L1 v datasetu L2_all_tables vytvořila 4 tabulky ve vrstvě L2 (L2_invoice, L2_contract, L2_product_purchase, L2_product).
Držela jsem se následujících pravidel:
    * Zpracovávám požadavky dle zadání [Požadavky na definice tabulek](https://docs.google.com/spreadsheets/d/1lnZX6YGuYmDbdjT-_SWmQHqVvUP41Q-qgKdmTvIgEYQ/edit?usp=sharing).
    * Zohledňuji další požadavky, které jsou uvedeny v [L2 checklist](https://docs.google.com/document/d/1bxdqGh7H_8Yob5oPGZ5RtzXq2C38D7JBOlYBWUmo3y0/edit?usp=sharing).

    V zadání Požadavky na definice tabulek bylo nutné probrat s business stakeholderem požadavek "Table should contain:products that has not been cancelled or disconnected. Null status should be also excluded". Rozporovala jsem tento technický požadavek vůči business požadavku "Existují ještě produkty, které nakupovali?" Na základě diskuze s business stakeholderem a zadávajícími datovými inženýry byl tento požadavek zrušen.

3) Pro každou tabulku jsem vytvořila skripty pro doplnění dokumentace, kde jsem se soustředila na zdokumentování všech transformací.

4) Pro každou tabulku jsem napsala testy:
    * Test na kontrolu unikátních záznamů primárního klíče
    * Test na kontrolu null hodnot primárního klíče
    * Test na kontrolu null hodnot dalších vybraných sloupců
    * Test na referenční integritu v příp. existence cizích klíčů v tabulce
    * Test na kontrolu, že vybrané sloupce obsahují pouze určitý výčet hodnot
    * Test na kontrolu počtu záznamů ve vrstvě L1 vs. L2. 

---
## Vrstva L3 (Serving layer)
---

Obecná charakteristika vrstvy L3:

* Tato vrstva slouží k tomu, abych mohl dělat specifické analýzy. 
* Např. když si potřebuji agregovat data nebo aplikovat nějakou transformaci pro jeden use case týkající se jediného oddělení. 

Postup:

1) V BigQuery jsem vytvořila dataset L3_all_tables.

2) Do datasetu L3_all_tables jsem vytvořila 1 hlavní FLAT tabulku L3_main_report, která spojuje tabulky L2_contract a L2_product_purchase + přidává 1 sloupec s informací o obratu na kontraktu z tabulky L2_invoice. Vzhledem k tomu, že cílem bylo odpovědět na velmi obecené business otázky, bylo v této fázi třeba mnoho věcí prodiskutovat s businessem a upřesnit si výstup, který očekává. Mým cílem bylo doplnit v rámci L3 vrstvy do hlavní tabulky takové sloupce, na které se už jednoduše napojí reporty s různými grafy.

    Příklady dopočítaných sloupců:<br>

    * contract_length_in_months: délka trvání kontraktu v měsících<br>
    * contract_length_in_months_category:  rozdělení délky trvání kontraktu měsících do kategorií<br>
    * contract_turnover_wo_vat_usd: obrat na daném kontraktu počítaný ze sumy amount_wo_vat_usd na fakturách (invoice)<br>
    * contract_turnover_wo_vat_category: rozdělení obratu na daném kontraktu do kategorií<br>
    * product_purchase_count: počet nákupů na daném kontaktu<br>
    * count_product_purchase_category: rozdělení počtu nákupů na daném kontaktu do kategorií<br>
    * turnover_weighted_product_purchase_count: obratem vážený počet nákupů - vyjadřuje počet nákupů, které musím udělat, abych měl 1 USD<br>
    * turnover_weighted_product_purchase_count_category: rozdělení obratem váženého počtu nákupů do kategorií<br>
    * lost_or_existing: ztracený zákazník (lost) nebo existující zákazník<br>
    * impact_of_product_cancellation_to_customer: kategorizace ztracených zákazníků, zda odešli z důvodu ukončení produktu nebo z jiného důvodu<br>
    * min_product_template_valid_from: odkdy začal platit daný typ produktu (bez vazby na kontrakt a nákup)<br>
    * max_product_template_valid_to: kdy skončila platnost daného typu produktu (bez vazby na kontrakt a nákup)<br>
    * is_product_finished: všechny produkty, kterým skončila platnost daného typu produktu (bez vazby na konrakt a nákup) do konce září 24 klasifikujeme jako skončené<br>
    * products_finished_leading_to_customer_left: Kategorizace ukončených produktů, zda ukončení produktu vedlo ke ztrátě zákazníka nebo nevedlo<br>
    * min_product_valid_from: minimální product_valid_from pro každý kontrakt (kdy byl nakoupen 1. produkt)<br>
    * is_last_product: flag (true/false), zda jde o poslední produkt na daném kontraktu (platnost do = maximální platnost do pro kontrakt)<br>

3) Do datasetu L3_all_tables jsem přidala ještě samostanou tabulku s údaji o zákaznících (=kontraktech) L3_main_report_cu, odvozená z hlavní FLAT tabulky, kde 1 řádek = 1 kontrakt. Narozdíl od hlavní tabulky neobsahuje detailní údaje o všech product_purchase, takže se s ní lépe pracuje při přípravě reportů, které se vážou k zákazníkovi a ne ke konkrétním nákupům.
      
---
## Looker Studio report
---

1) Do Looker Studia jsem napojila v BigQuery nachystané tabulky z vrstvy L3, tj. L3_main_report a L3_main_report_cu na základě nich jsem postavila report s údaji, grafy (s možností filtrování), který z různých úhlů pohledu zodpovídá na 3 základní business otázky, které byly v rámci přípravy L3 na základě doplňujících otázek s business stakeholderem upřesněny.

    * Kteří zákazníci a kdy odcházejí? -> Co je společným znakem pro ukončené kontrakty? Jaká je průměrná doba (median) setrvání kontraktu? Odchod zákadzníka definujeme jako zrušení kontrkatu i situaci, kdy po nějakou dobu nic nezakoupil.
    * Nakupují málo/hodně? -> Četnost nákupu, množství zakoupených produktu, četnost vážená obratem bez dph, ideálně rozšířená o vámi navrhnuté skupiny (biny) 
    * Existují ještě produkty, které nakupovali? -> konec produktů zjistíme, že už nebyla možnost si koupit, takže od nějakého datumu neměly žádného zákazníka