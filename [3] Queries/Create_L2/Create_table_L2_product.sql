-----------------------
-- VYTVOŘENÍ TABULKY --
-----------------------
CREATE OR REPLACE TABLE `feisty-outlet-436420-a9.l2_all_tables.L2_product` as
  SELECT
    product_id,
    product_name,
    product_type,
    product_category
  FROM `feisty-outlet-436420-a9.l1_all_tables. L1_product`
  WHERE product_category IN ('rent', 'product'); -- Požadavek v dokumentaci pro L2: Table should contain only chosen product category (rent, product)

---------------------------
-- DOPLNĚNÍ DOKUMENTACE --
---------------------------
ALTER TABLE `feisty-outlet-436420-a9.l2_all_tables.L2_product`
SET OPTIONS (
  description = "Dim table, that contains information about products that are offered, including name, type, category. Table contains only chosen product category (rent, product)."
);

ALTER TABLE `feisty-outlet-436420-a9.l2_all_tables.L2_product`
ALTER COLUMN product_id SET OPTIONS (description = 'PK; Source: L1_product; Desc: Unique id of product');

ALTER TABLE `feisty-outlet-436420-a9.l2_all_tables.L2_product`
ALTER COLUMN product_name SET OPTIONS (description = 'Source: L1_product; Desc: Name of product');

ALTER TABLE `feisty-outlet-436420-a9.l2_all_tables.L2_product`
ALTER COLUMN product_type SET OPTIONS (description = 'Source: L1_product; Desc: Type of product');

ALTER TABLE `feisty-outlet-436420-a9.l2_all_tables.L2_product`
ALTER COLUMN product_category SET OPTIONS (description = 'Source: L1_product; Desc: Name of category');

------------
-- TESTY --
------------
-- Tabulka product: product_id
-- Test na kontrolu unikátních záznamů primárního klíče product_id:
SELECT product_id, COUNT (*) AS cnt
FROM `feisty-outlet-436420-a9.l2_all_tables.L2_product`
GROUP BY product_id
HAVING cnt > 1;
-- Výsledek: OK (žádný záznam)

-- Tabulka product: id_product
-- Test na kontrolu null hodnot primárního klíče product_id:
SELECT *
FROM `feisty-outlet-436420-a9.l2_all_tables.L2_product`
WHERE product_id IS NULL;
-- Výsledek: OK (žádný záznam)

-- Tabulka product: product_name
-- Test na kontrolu null hodnot sloupce product_name:
SELECT *
FROM `feisty-outlet-436420-a9.l2_all_tables.L2_product`
WHERE product_name IS NULL;
-- Výsledek: OK (žádný záznam)

-- Tabulka product: product_type
-- Test na kontrolu null hodnot sloupce product_type:
SELECT *
FROM `feisty-outlet-436420-a9.l2_all_tables.L2_product`
WHERE product_type IS NULL;
-- Výsledek: OK (žádný záznam)

-- Tabulka product: product_category
-- Test na kontrolu null hodnot sloupce product_category:
SELECT *
FROM `feisty-outlet-436420-a9.l2_all_tables.L2_product`
WHERE product_category IS NULL;
-- Výsledek: OK (žádný záznam)

-- Kontroly počtů záznamů L1 vs. L2
WITH count_vrstva_L2 AS (
SELECT COUNT(*) as cnt_all_L2, 'L2' AS vrstva FROM `feisty-outlet-436420-a9.l2_all_tables.L2_product`
), count_vrstva_L1_odebrano AS (
SELECT COUNT(*) as cnt_all_L1_odeb, 'L1 - odebrano' AS vrstva FROM `feisty-outlet-436420-a9.l1_all_tables. L1_product`
WHERE product_category NOT IN ('rent', 'product')
)
SELECT (cnt_all_L2 + cnt_all_L1_odeb) as cnt_all, 'L2 + L1_odebrano' as vrstva
FROM count_vrstva_L2, count_vrstva_L1_odebrano
UNION ALL
SELECT COUNT(*) as cnt_all, 'L1' AS vrstva FROM `feisty-outlet-436420-a9.l1_all_tables. L1_product`;
-- Výsledek: L1: 230, L2 + L1_odebrano: 230, tj. sedí



