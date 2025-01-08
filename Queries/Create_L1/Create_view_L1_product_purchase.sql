--------------------
-- VYTVOŘENÍ VIEW --
--------------------
CREATE OR REPLACE VIEW feisty-outlet-436420-a9.l1_all_tables.L1_product_purchase AS (
  WITH 
  product_status AS(
    SELECT
    id_status AS product_status_id,
    LOWER(name) AS product_status_name
    FROM `feisty-outlet-436420-a9.l0_google_sheet.status`
    WHERE id_status IS NOT NULL
    AND name IS NOT NULL
    QUALIFY ROW_NUMBER() OVER (PARTITION BY id_status) = 1 -- odstranění duplicitních záznamů pro id_status
  ), 
  product AS (
  SELECT 
    id_product AS product_id,
    name AS product_name,
    type AS product_type,
    category AS product_category
    FROM `feisty-outlet-436420-a9.l0_google_sheet.product`
    WHERE id_product IS NOT NULL
    QUALIFY ROW_NUMBER() OVER (PARTITION BY id_product) = 1 -- odstranění duplicitních záznamů pro id_product
  )
SELECT
  pp.id_package AS product_purchase_id,	
  pp.id_contract AS contract_id,
  pp.id_package_template AS product_id,
  DATE(pp.date_insert, "Europe/Prague") AS create_date,
  DATE(TIMESTAMP(SUBSTR(pp.start_date, 1, 19), "Europe/Prague")) AS product_valid_from, -- konverze data na pražský čas ve formátu DATE (požadavek pro všechna data)
  DATE(TIMESTAMP(SUBSTR(pp.end_date, 1, 19), "Europe/Prague")) AS product_valid_to,
  CAST(pp.fee AS NUMERIC) AS price_wo_vat_usd, -- konverze datového typu fee FLOAT->NUMERIC
  DATE(pp.date_update, "Europe/Prague") AS date_update,
  pp.package_status AS product_status_id,
  ps.product_status_name AS product_status, -- -- Požadavek v dokumentaci pro L1: připojení sloupce z tabulky product_status
  pr.product_name AS product_name, --  -- Požadavek v dokumentaci pro L1: připojení sloupců z tabulky product
  pr.product_type AS product_type,
  pr.product_category AS product_category
FROM feisty-outlet-436420-a9.l0_crm.product_purchase AS pp
LEFT JOIN product_status AS ps ON pp.package_status = ps.product_status_id
LEFT JOIN product AS pr ON pp.id_package_template = pr.product_id
);

---------------------------
-- DOPLNĚNÍ DOKUMENTACE --
---------------------------
ALTER VIEW `feisty-outlet-436420-a9.l1_all_tables.L1_product_purchase`
SET OPTIONS (
  description = "Product packages purchases linked to a contract. It contains information regarding the price excluding VAT, the date of creation, the start and end dates of validity, and other details about the package, that has been purchased. One contract (id_contract) can be linked to multiple id_packages (a combination of contract and package), but each id_package is linked to only one id_contract."
);

ALTER VIEW `feisty-outlet-436420-a9.l1_all_tables.L1_product_purchase`
ALTER COLUMN product_purchase_id SET OPTIONS (description = 'PK; Source: L0_product_purchase; Desc: Unique identifier of purchased package');

ALTER VIEW `feisty-outlet-436420-a9.l1_all_tables.L1_product_purchase`
ALTER COLUMN contract_id SET OPTIONS (description = 'FK; Source: L0_product_purchase; Desc: Unique identifier of contract');

ALTER VIEW `feisty-outlet-436420-a9.l1_all_tables.L1_product_purchase`
ALTER COLUMN product_id SET OPTIONS (description = 'FK; Source: L0_product_purchase; Desc: Unique identifier of product');

ALTER VIEW `feisty-outlet-436420-a9.l1_all_tables.L1_product_purchase`
ALTER COLUMN create_date SET OPTIONS (description = 'Source: L0_product_purchase; Desc: Date when the row was inserted into system; Transform to type DATE Europe/Prague');

ALTER VIEW `feisty-outlet-436420-a9.l1_all_tables.L1_product_purchase`
ALTER COLUMN product_valid_from SET OPTIONS (description = 'Source: L0_product_purchase; Desc: Start of the invoiced period for the invoice; Transform to type DATE Europe/Prague');

ALTER VIEW `feisty-outlet-436420-a9.l1_all_tables.L1_product_purchase`
ALTER COLUMN product_valid_to SET OPTIONS (description = 'Source: L0_product_purchase; Desc: End of the invoiced period for the invoice; Transform to type DATE Europe/Prague');

ALTER VIEW `feisty-outlet-436420-a9.l1_all_tables.L1_product_purchase`
ALTER COLUMN price_wo_vat_usd SET OPTIONS (description = 'Source: L0_product_purchase; Desc: Price without vat; Transform to type NUMERIC');

ALTER VIEW `feisty-outlet-436420-a9.l1_all_tables.L1_product_purchase`
ALTER COLUMN date_update SET OPTIONS (description = 'Source: L0_product_purchase; Desc: Date when the row was updated; Transform to type DATE Europe/Prague');

ALTER VIEW `feisty-outlet-436420-a9.l1_all_tables.L1_product_purchase`
ALTER COLUMN product_status_id SET OPTIONS (description = 'FK; Source: L0_product_purchase; Desc: Id of package (product) status');

ALTER VIEW `feisty-outlet-436420-a9.l1_all_tables.L1_product_purchase`
ALTER COLUMN product_status SET OPTIONS (description = 'Source: L0_status; Desc: Name of package (product) status');

ALTER VIEW `feisty-outlet-436420-a9.l1_all_tables.L1_product_purchase`
ALTER COLUMN product_name SET OPTIONS (description = 'Source: L0_product; Desc: Name of product');

ALTER VIEW `feisty-outlet-436420-a9.l1_all_tables.L1_product_purchase`
ALTER COLUMN product_type SET OPTIONS (description = 'Source: L0_product; Desc: Type of product');

ALTER VIEW `feisty-outlet-436420-a9.l1_all_tables.L1_product_purchase`
ALTER COLUMN product_category SET OPTIONS (description = 'Source: L0_product; Desc: Name of category');

------------
-- TESTY --
------------
-- Tabulka product_purchase: product_purchase_id
-- Test na kontrolu unikátních záznamů primárního klíče product_purchase_id :

SELECT product_purchase_id, COUNT (*) AS cnt
FROM `feisty-outlet-436420-a9.l1_all_tables.L1_product_purchase`
GROUP BY product_purchase_id
HAVING cnt > 1;
-- Výsledek: OK (žádné záznamy)

-- Tabulka product_purchase: product_purchase_id
-- Test na kontrolu null hodnot primárního klíče product_purchase_id:
SELECT COUNT (*)
FROM `feisty-outlet-436420-a9.l1_all_tables.L1_product_purchase`
WHERE product_purchase_id IS NULL;
-- Výsledek: OK (žádné záznamy)

-- Tabulka product_purchase: contract_id
-- Test na kontrolu null hodnot contract_id:
SELECT COUNT (*)
FROM `feisty-outlet-436420-a9.l1_all_tables.L1_product_purchase`
WHERE contract_id IS NULL;
-- Výsledek: OK (žádné záznamy)

-- Tabulka product_purchase: product_valid_from, product_valid_to
-- Test na kontrolu null hodnot product_valid_from, product_valid_to:
SELECT COUNT (*)
FROM `feisty-outlet-436420-a9.l1_all_tables.L1_product_purchase`
WHERE product_valid_from IS NULL;
-- Výsledek: 99 177 záznamů -> ověřeno s Business stakeholderem, že mazat se tyto záznamy nebudou

SELECT COUNT (*)
FROM `feisty-outlet-436420-a9.l1_all_tables.L1_product_purchase`
WHERE product_valid_to IS NULL;
-- Výsledek: 99 177 záznamů -> ověřeno s Business stakeholderem, že mazat se tyto záznamy nebudou
-- Tabulka product_purchase: contract_id
-- Test na referenční integritu -> purchase bez existujících kontraktů
SELECT COUNT (*)
FROM `feisty-outlet-436420-a9.l1_all_tables.L1_product_purchase` AS pu
LEFT JOIN `feisty-outlet-436420-a9.l1_all_tables.L1_contract` AS c ON pu.contract_id = c.contract_id
WHERE c.contract_id IS NULL
;
-- Výsledek: 200 667 záznamů !!!  -> S Busisiness stakeholderem vyjasněno, že data jsou časově odříznutá, je to tedy OK, jsou zde product_purchase ke starým kontraktům

-- Tabulka product_purchase: contract_id
-- Test na referenční integritu -> purchase s existujícími kontrakty
SELECT COUNT (*)
FROM `feisty-outlet-436420-a9.l1_all_tables.L1_product_purchase` AS pu
LEFT JOIN `feisty-outlet-436420-a9.l1_all_tables.L1_contract` AS c ON pu.contract_id = c.contract_id
WHERE c.contract_id IS NOT NULL
;
-- Výsledek: 454 579 záznamů -> OK, data product_purchase a contract jsou provázány

-- Tabulka product_purchase: product_id
-- Test na referenční integritu -> purchase bez existujících produktů (package_template)
SELECT COUNT (*)
FROM `feisty-outlet-436420-a9.l1_all_tables.L1_product_purchase` AS pu
LEFT JOIN `feisty-outlet-436420-a9.l1_all_tables. L1_product` AS pr ON pu.product_id = pr.product_id
WHERE pr.product_id IS NULL
;
-- Výsledek: OK (žádné záznamy)

-- Tabulka product_purchase: product_status_id
-- Test na referenční integritu -> purchase bez existujících package_status
SELECT COUNT(*)
FROM `feisty-outlet-436420-a9.l1_all_tables.L1_product_purchase` AS pu
LEFT JOIN `feisty-outlet-436420-a9.l1_all_tables. L1_product_status` AS st ON pu.product_status_id = st.product_status_id
WHERE st.product_status_id IS NULL
;
-- Výsledek: OK (žádné záznamy)

-- Kontroly počtů záznamů L0 vs. L1
SELECT COUNT(*) as cnt_all, 'L1' AS vrstva_L1 FROM `feisty-outlet-436420-a9.l1_all_tables.L1_product_purchase`
UNION ALL
SELECT COUNT(*) as cnt_all, 'L0' AS vrstva_L0 FROM `feisty-outlet-436420-a9.l0_crm.product_purchase`;
-- Výsledek: OK, stejný počet záznamů

