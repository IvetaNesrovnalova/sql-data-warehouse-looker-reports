------------------------------------------
-- VYTVOŘENÍ TABULKY VČETNĚ DOKUMENTACE --
------------------------------------------
CREATE OR REPLACE EXTERNAL TABLE `feisty-outlet-436420-a9.l0_google_sheet.product`(
   	id_product INT64 OPTIONS (description = 'Unique id of product'),
    name STRING OPTIONS (description = 'Name of product'),
    is_vat_applicable BOOL OPTIONS(description = 'If VAT is applicable: true if yes, false is no'),
    type STRING OPTIONS (description = 'Type of product'),
    category STRING OPTIONS (description = 'Name of category'),
 	  date_update date OPTIONS (description = 'Date of last change'),
) OPTIONS (
  description = 'Dim table, that conrains information about products that are offered, including name, type. VAT',
  format = 'GOOGLE_SHEETS',
  skip_leading_rows = 1,
  sheet_range = "'all_products'!A:Z",
  uris = ['https://docs.google.com/spreadsheets/d/1Sy_5BZZ_rDGq79v1N0PcDXVLmK2RuOik_RgrdH16_ns/edit?gid=1174952767#gid=1174952767']
);

------------
-- TESTY --
------------
-- Tabulka product: id_product
-- Test na kontrolu unikátních záznamů primárního klíče id_product :

SELECT id_product, COUNT (*) AS cnt
FROM `feisty-outlet-436420-a9.l0_google_sheet.product`
GROUP BY id_product
HAVING cnt > 1;
-- Výsledek: 15 záznamů je duplicitních !!! -> K odstranění

-- Tabulka product
-- Kompletní výpis duplicitních záznamů pro celkovou kontrolu obsahu
WITH id_product_unique_check AS (
SELECT id_product, COUNT (*) AS cnt
FROM `feisty-outlet-436420-a9.l0_google_sheet.product`
GROUP BY id_product
HAVING cnt > 1)
SELECT product_all.*
FROM `feisty-outlet-436420-a9.l0_google_sheet.product` AS product_all
JOIN id_product_unique_check ON product_all.id_product = id_product_unique_check.id_product
ORDER BY product_all.id_product
;

-- Tabulka product: id_product
-- Test na kontrolu null hodnot primárního klíče id_product:
SELECT *
FROM `feisty-outlet-436420-a9.l0_google_sheet.product`
WHERE id_product IS NULL;
-- Výsledek: 1 záznam má v ID hodnotu null !!! -> K odstranění

-- Test na kontrolu null hodnot sloupce name:
SELECT *
FROM `feisty-outlet-436420-a9.l0_google_sheet.product`
WHERE name IS NULL;
-- Výsledek: OK (žádný záznam)

-- Test na kontrolu null hodnot sloupce type:
SELECT *
FROM `feisty-outlet-436420-a9.l0_google_sheet.product`
WHERE type IS NULL;
-- Výsledek: OK (žádný záznam)

-- Test na kontrolu null hodnot sloupce category:
SELECT *
FROM `feisty-outlet-436420-a9.l0_google_sheet.product`
WHERE category IS NULL;
-- Výsledek: OK (žádný záznam)

-------------------------------------
-- NÁVRHY NA TRANSFORMACE PRO L1: --
-------------------------------------
-- 1) Odstranění duplicitních záznamů pro id_product
-- 2) Odstranění null záznamu ve sloupci id_product