---
# Finální report L3 (Serving layer)
---
Pro účely přípravy reportu pro klienta v Looker studio, na základě kterého lze zodpovědět na businessové otázky klienta, byla vytvořena vrstva L3 (Serving layer) datového skladu, kterou tvoří 2 tabulky:
* `L3_main_report.csv` - hlavní flat tabulka, která obsahuje zgrupované všechna data z tabulek contract, product_purchase, invoice, která jsou relevantní pro reporting
* `L3_main_report_cus.csv`- tabulka s údaji o zákaznících (=kontraktech), odvozená z hlavní tabulky, kde 1 řádek = 1 kontrakt. Narozdíl od hlavní tabulky neobsahuje detailní údaje o všech product_purchase, takže se sní lépe pracuje při přípravě reportů, které se vážou k zákazníkovi a ne ke konkrétním nákupům. <br>
Zde je odkaz na [Final_reporting_data_(L3)](https://drive.google.com/drive/folders/1N1WG57vw4H923iNQV5phr02dI5Us7aw0?usp=drive_link)

---
# Looker Studio report
---
Zde je odkaz na [Looker Studio report](https://lookerstudio.google.com/s/qR4a9vwV5gc), který je navázán na tabulky výše z L3 vrstvy a kde lze najít odpovědi na businessové otázky klienta.
