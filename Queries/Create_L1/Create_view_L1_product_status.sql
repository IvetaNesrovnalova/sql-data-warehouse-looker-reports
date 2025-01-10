--------------------
-- VYTVOŘENÍ VIEW --
--------------------
CREATE OR REPLACE VIEW `feisty-outlet-436420-a9.l1_all_tables. L1_product_status` AS(
SELECT
id_status AS  product_status_id,
LOWER(name) AS  product_status_name -- převedení hodnot ve sloupci name na malá písmena
FROM `feisty-outlet-436420-a9.l0_google_sheet.status`
WHERE id_status IS NOT NULL -- odstranění záznnamů s id_status = NULL
AND name IS NOT NULL -- odstranění záznamů s name = NULL
QUALIFY ROW_NUMBER() OVER (PARTITION BY id_status) = 1 -- odstranění duplicitních záznamů pro id_status
);

---------------------------
-- DOPLNĚNÍ DOKUMENTACE --
---------------------------
ALTER VIEW `feisty-outlet-436420-a9.l1_all_tables. L1_product_status`
SET OPTIONS (
  description = "Status names of sold products"
);

ALTER VIEW `feisty-outlet-436420-a9.l1_all_tables. L1_product_status`
ALTER COLUMN product_status_id SET OPTIONS (description = 'PK; Source: L0_status; Desc: Unique id of status');

ALTER VIEW `feisty-outlet-436420-a9.l1_all_tables. L1_product_status`
ALTER COLUMN product_status_name SET OPTIONS (description = 'Source: L0_status; Desc: Name of status');

------------
-- TESTY --
------------
-- Tabulka product_status: product_status_id
-- Test na kontrolu unikátních záznamů primárního klíče product_status_id :

SELECT product_status_id, COUNT (*) AS cnt
FROM `feisty-outlet-436420-a9.l1_all_tables. L1_product_status`
GROUP BY product_status_id
HAVING cnt > 1;
-- Výsledek: OK (žádné záznamy)

-- Tabulka status: product_status_id
-- Test na kontrolu null hodnot primárního klíče product_status_id:
SELECT COUNT (*)
FROM `feisty-outlet-436420-a9.l1_all_tables. L1_product_status`
WHERE product_status_id IS NULL;
-- Výsledek: OK (žádné záznamy)

-- Tabulka status: product_status_name
-- Test na kontrolu null hodnot sloupce name:
SELECT COUNT (*)
FROM `feisty-outlet-436420-a9.l1_all_tables. L1_product_status`
WHERE product_status_name IS NULL;
-- Výsledek: OK (žádné záznamy)

-- Kontroly počtů záznamů L0 vs. L1
SELECT COUNT(*) as cnt_all, 'L1' AS vrstva_L1 FROM `feisty-outlet-436420-a9.l0_google_sheet.status`
UNION ALL
SELECT COUNT(*) as cnt_all, 'L0' AS vrstva_L0 FROM `feisty-outlet-436420-a9.l1_all_tables. L1_product_status`;
-- Výsledek: L0:74; L1:71 různý počet záznamů, ale to je v pořádku, protože byly odebrány NULL a duplicitní záznamy

