------------------------------------------
-- VYTVOŘENÍ TABULKY VČETNĚ DOKUMENTACE --
------------------------------------------
CREATE OR REPLACE EXTERNAL TABLE `feisty-outlet-436420-a9.l0_google_sheet.branch`(
   	id_branch STRING OPTIONS (description = 'Unique id pf branch'),
    branch_name STRING OPTIONS (description = 'Name of branch'),
 	  date_update date OPTIONS (description = 'Date of last change')
) OPTIONS (
  description = 'Dim table that contains information about branches',
  format = 'GOOGLE_SHEETS',
  skip_leading_rows = 1,
  sheet_range = "'branch'!A:Z",
  uris = ['https://docs.google.com/spreadsheets/d/1Sy_5BZZ_rDGq79v1N0PcDXVLmK2RuOik_RgrdH16_ns/edit?gid=1710515388#gid=1710515388']
);

------------
-- TESTY --
------------
-- Tabulka branch: id_branch
-- Test na kontrolu unikátních záznamů primárního klíče id_branch :

SELECT id_branch, COUNT (*) AS cnt
FROM `feisty-outlet-436420-a9.l0_google_sheet.branch`
GROUP BY id_branch
HAVING cnt > 1;
-- Výsledek: OK (žádné záznamy)

-- Tabulka branch: id_branch
-- Test na kontrolu null hodnot primárního klíče id_branch:
SELECT *
FROM `feisty-outlet-436420-a9.l0_google_sheet.branch`
WHERE id_branch IS NULL;
-- Výsledek: OK (žádné záznamy)

-- Tabulka branch: branch_name
-- Test na kontrolu null hodnot sloupce branch_name:
SELECT *
FROM `feisty-outlet-436420-a9.l0_google_sheet.branch`
WHERE branch_name IS NULL;
-- Výsledek: OK (žádné záznamy)

-------------------------------------
-- NÁVRHY NA TRANSFORMACE PRO L1: --
-------------------------------------
-- 1) id_branch přetypovat ze STRING na INT
-- 2) Odstranit záznam, kde je v id_branch = "NULL"
-- 3) Odstranit záznam, kde je id_branch = 0 a name = "unknown" - bylo zkontrolováno, že id_branch = 0 se nevyskytuje v tabulkách product_purchase, contract, invoice.