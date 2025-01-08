--------------------
-- VYTVOŘENÍ VIEW --
--------------------
CREATE OR REPLACE VIEW `feisty-outlet-436420-a9.l1_all_tables. L1_product` AS(
SELECT 
  id_product AS product_id,
  name AS product_name,
  type AS product_type,
  category AS product_category
FROM `feisty-outlet-436420-a9.l0_google_sheet.product`
WHERE id_product IS NOT NULL -- odstranění NULL záznamů
QUALIFY ROW_NUMBER() OVER (PARTITION BY id_product) = 1 -- odstranění duplicitních záznamů pro id_product
);

---------------------------
-- DOPLNĚNÍ DOKUMENTACE --
---------------------------
ALTER VIEW `feisty-outlet-436420-a9.l1_all_tables. L1_product`
SET OPTIONS (
  description = "Dim table, that conrains information about products that are offered, including name, type. VAT"
);

ALTER VIEW `feisty-outlet-436420-a9.l1_all_tables. L1_product`
ALTER COLUMN product_id SET OPTIONS (description = 'PK; Source: L0_product; Desc: Unique id of product');

ALTER VIEW `feisty-outlet-436420-a9.l1_all_tables. L1_product`
ALTER COLUMN product_name SET OPTIONS (description = 'Source: L0_product; Desc: Name of product');

ALTER VIEW `feisty-outlet-436420-a9.l1_all_tables. L1_product`
ALTER COLUMN product_type SET OPTIONS (description = 'Source: L0_product; Desc: Type of product');

ALTER VIEW `feisty-outlet-436420-a9.l1_all_tables. L1_product`
ALTER COLUMN product_category SET OPTIONS (description = 'Source: L0_product; Desc: Name of category');

------------
-- TESTY --
------------
-- Tabulka product: product_id
-- Test na kontrolu unikátních záznamů primárního klíče product_id:

SELECT product_id, COUNT (*) AS cnt
FROM `feisty-outlet-436420-a9.l1_all_tables. L1_product`
GROUP BY product_id
HAVING cnt > 1;
-- Výsledek: OK (žádný záznam)

-- Tabulka product: id_product
-- Test na kontrolu null hodnot primárního klíče product_id:
SELECT *
FROM `feisty-outlet-436420-a9.l1_all_tables. L1_product`
WHERE product_id IS NULL;
-- Výsledek: OK (žádný záznam)

-- Tabulka product: product_name
-- Test na kontrolu null hodnot sloupce product_name:
SELECT *
FROM `feisty-outlet-436420-a9.l1_all_tables. L1_product`
WHERE product_name IS NULL;
-- Výsledek: OK (žádný záznam)

-- Tabulka product: product_type
-- Test na kontrolu null hodnot sloupce product_type:
SELECT *
FROM `feisty-outlet-436420-a9.l1_all_tables. L1_product`
WHERE product_type IS NULL;
-- Výsledek: OK (žádný záznam)

-- Tabulka product: product_category
-- Test na kontrolu null hodnot sloupce product_category:
SELECT *
FROM `feisty-outlet-436420-a9.l1_all_tables. L1_product`
WHERE product_category IS NULL;
-- Výsledek: OK (žádný záznam)


-- Kontroly počtů záznamů L0 vs. L1
SELECT COUNT(*) as cnt_all, 'L1' AS vrstva_L1 FROM `feisty-outlet-436420-a9.l1_all_tables. L1_product`
UNION ALL
SELECT COUNT(*) as cnt_all, 'L0' AS vrstva_L0 FROM `feisty-outlet-436420-a9.l0_google_sheet.product`;
-- Výsledek: L0:246; L1:230 různý počet záznamů, ale to je v pořádku, protože bylo odebráno 15 duplicitních záznamů a 1 null záznam



