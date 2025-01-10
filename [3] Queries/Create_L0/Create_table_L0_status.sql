------------------------------------------
-- VYTVOŘENÍ TABULKY VČETNĚ DOKUMENTACE --
------------------------------------------
CREATE OR REPLACE EXTERNAL TABLE `feisty-outlet-436420-a9.l0_google_sheet.status`(
   	id_status INT64 OPTIONS (description = 'Unique id of contract'),
    name STRING OPTIONS (description = 'Name of status'),
 	  date_update date OPTIONS (description = 'Date of last change'),
) OPTIONS (
  description = 'Status names of sold products',
  format = 'GOOGLE_SHEETS',
  skip_leading_rows = 1,
  sheet_range = "'status'!A:Z",
  uris = ['https://docs.google.com/spreadsheets/d/1Sy_5BZZ_rDGq79v1N0PcDXVLmK2RuOik_RgrdH16_ns/edit?gid=0#gid=0']
);

------------
-- TESTY --
------------
-- Tabulka status: id_status
-- Test na kontrolu unikátních záznamů primárního klíče id_status :
SELECT id_status, COUNT (*) AS cnt
FROM `feisty-outlet-436420-a9.l0_google_sheet.status`
GROUP BY id_status
HAVING cnt > 1;
-- Výsledek: 2 duplicitní záznamy !!! -> k odstranění v transformaci na L1

-- Tabulka status
-- Kompletní výpis duplicitních záznamů pro celkovou kontrolu obsahu
WITH id_status_unique_check AS (
SELECT id_status, COUNT (*) AS cnt
FROM `feisty-outlet-436420-a9.l0_google_sheet.status`
GROUP BY id_status
HAVING cnt > 1)
SELECT status_all.*
FROM `feisty-outlet-436420-a9.l0_google_sheet.status` AS status_all
JOIN id_status_unique_check ON status_all.id_status = id_status_unique_check.id_status
ORDER BY status_all.id_status
;

-- Tabulka status: id_status
-- Test na kontrolu null hodnot primárního klíče id_status:
SELECT *
FROM `feisty-outlet-436420-a9.l0_google_sheet.status`
WHERE id_status IS NULL;
-- Výsledek: 1 záznam !!! -> k odstranění v transformaci na L1

-- Tabulka status: name
-- Test na kontrolu null hodnot sloupce name:
SELECT *
FROM `feisty-outlet-436420-a9.l0_google_sheet.status`
WHERE name IS NULL;
-- Výsledek: 1 záznam !!! -> k odstranění v transformaci na L1

-------------------------------------
-- NÁVRHY NA TRANSFORMACE PRO L1: --
-------------------------------------
-- 1) Odstranění duplicitních záznamů 
-------id_status = 0  a name = null
-------id_status = 68
-- 2) Odstranění záznamu s id_status = null
-- 3) viz 1, první bod - odstranění záznamu s hodnotou null ve sloupci name
-- 4) Sjednocení velikosti písmen ve sloupci name -> převod na malá písmena