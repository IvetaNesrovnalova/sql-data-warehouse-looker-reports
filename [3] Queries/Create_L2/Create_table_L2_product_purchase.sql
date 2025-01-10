-----------------------
-- VYTVOŘENÍ TABULKY --
-----------------------
CREATE OR REPLACE TABLE `feisty-outlet-436420-a9.l2_all_tables.L2_product_purchase` AS
  SELECT
    product_purchase_id,
    contract_id,
    product_id,
    create_date,
    product_valid_from,
    CASE 
      WHEN product_valid_from IS NOT NULL AND product_valid_to IS NULL THEN DATE '2035-12-31'
      ELSE product_valid_to
    END AS product_valid_to, -- Nahrazení NULL hodnoty ve sloupci product_valid_to v příp., kdy product_valid_from je vyplněno
    price_wo_vat_usd,
    CASE
      WHEN price_wo_vat_usd IS NULL THEN NULL
      ELSE price_wo_vat_usd * 1.2
    END AS price_w_vat_usd, -- Požadavek v dokumentaci pro L2: OPTIONAL; calculate price_w_vat, assuming, that vat is 20%
    date_update,
    product_name,
    product_type,
    -- Výpočet flagu založený na výsledné hodnotě product_valid_to
    CASE 
      WHEN EXTRACT(YEAR FROM 
        CASE 
          WHEN product_valid_from IS NOT NULL AND product_valid_to IS NULL THEN DATE '2035-12-31'
          ELSE product_valid_to
        END
      ) >= 2035 THEN TRUE
      ELSE FALSE
    END AS flag_unlimited_product               -- Požadavek v dokumentaci pro L2: flag if product is for unlimited period (if product_valid_to >= 2035, true, false)
  FROM `feisty-outlet-436420-a9.l1_all_tables.L1_product_purchase`
  WHERE product_category IN ('rent', 'product') -- Požadavek v dokumentaci pro L2: chosen product_category: product, rent.
  
  /* Pozn.:  Po dohodě s business stakeholderem není relevantní Požadvek v dokumnetaci pro L2: 
  Table should contain:products that has not been cancelled or disconnected. Null status should be also excluded */
;

---------------------------
-- DOPLNĚNÍ DOKUMENTACE --
---------------------------
ALTER TABLE `feisty-outlet-436420-a9.l2_all_tables.L2_product_purchase`
SET OPTIONS (
  description = "Product packages purchases linked to a contract. It contains information regarding the price excluding VAT, the date of creation, the start and end dates of validity, and other details about the package, that has been purchased. One contract (id_contract) can be linked to multiple id_packages (a combination of contract and package), but each id_package is linked to only one id_contract. There are chosen only product_category ('rent', 'product'). There are excluded product_status ('disconnected', 'canceled registration', 'canceled') and product_status = null. "
);


ALTER TABLE `feisty-outlet-436420-a9.l2_all_tables.L2_product_purchase`
ALTER COLUMN product_purchase_id SET OPTIONS (description = 'PK; Source: L1_product_purchase; Desc: Unique identifier of purchased package');

ALTER TABLE `feisty-outlet-436420-a9.l2_all_tables.L2_product_purchase`
ALTER COLUMN contract_id SET OPTIONS (description = 'FK; Source: L1_product_purchase; Desc: Unique identifier of contract');

ALTER TABLE `feisty-outlet-436420-a9.l2_all_tables.L2_product_purchase`
ALTER COLUMN product_id SET OPTIONS (description = 'FK; Source: L1_product_purchase; Desc: Unique identifier of product');

ALTER TABLE `feisty-outlet-436420-a9.l2_all_tables.L2_product_purchase`
ALTER COLUMN create_date SET OPTIONS (description = 'Source: L1_product_purchase; Desc: Date when the row was inserted into system; Format: DATE Europe/Prague');

ALTER TABLE `feisty-outlet-436420-a9.l2_all_tables.L2_product_purchase`
ALTER COLUMN product_valid_from SET OPTIONS (description = 'Source: L1_product_purchase; Desc: Start of the invoiced period for the invoice; Format: DATE Europe/Prague');

ALTER TABLE `feisty-outlet-436420-a9.l2_all_tables.L2_product_purchase`
ALTER COLUMN product_valid_to SET OPTIONS (description = 'Source: L1_product_purchase; Desc: End of the invoiced period for the invoice. In case product_valid_from IS NOT NULL and product_valid_to IS NULL, NULL value is replaced by DATE 2035-12-31; Format: DATE Europe/Prague');

ALTER TABLE `feisty-outlet-436420-a9.l2_all_tables.L2_product_purchase`
ALTER COLUMN price_wo_vat_usd SET OPTIONS (description = 'Source: L1_product_purchase; Desc: Price without vat; Format: NUMERIC');

ALTER TABLE `feisty-outlet-436420-a9.l2_all_tables.L2_product_purchase`
ALTER COLUMN price_w_vat_usd SET OPTIONS (description = 'Source: L1_product_purchase; Desc: Price with vat; Calculate from price_wo_vat_usd, assuming, that vat is 20%');

ALTER TABLE `feisty-outlet-436420-a9.l2_all_tables.L2_product_purchase`
ALTER COLUMN date_update SET OPTIONS (description = 'Source: L1_product_purchase; Desc: Date when the row was updated; Format: DATE Europe/Prague');

ALTER TABLE `feisty-outlet-436420-a9.l2_all_tables.L2_product_purchase`
ALTER COLUMN product_name SET OPTIONS (description = 'Source: L1_product; Desc: Name of product');

ALTER TABLE `feisty-outlet-436420-a9.l2_all_tables.L2_product_purchase`
ALTER COLUMN product_type SET OPTIONS (description = 'Source: L1_product; Desc: Type of product');

ALTER TABLE `feisty-outlet-436420-a9.l2_all_tables.L2_product_purchase`
ALTER COLUMN product_type SET OPTIONS (description = 'Source: L1_product; Desc: Type of product');

ALTER TABLE `feisty-outlet-436420-a9.l2_all_tables.L2_product_purchase`
ALTER COLUMN flag_unlimited_product SET OPTIONS (description = 'Source: L1_product; Desc: Flag if product is for unlimited period. Derived from product_valid_to: if product_valid_to >= 2035 ->TRUE, in other case ->FALSE');

------------
-- TESTY --
------------
-- Tabulka product_purchase: product_purchase_id
-- Test na kontrolu unikátních záznamů primárního klíče product_purchase_id :
SELECT product_purchase_id, COUNT (*) AS cnt
FROM `feisty-outlet-436420-a9.l2_all_tables.L2_product_purchase`
GROUP BY product_purchase_id
HAVING cnt > 1;
-- Výsledek: OK (žádné záznamy)

-- Tabulka product_purchase: product_purchase_id
-- Test na kontrolu null hodnot primárního klíče product_purchase_id:
SELECT COUNT (*)
FROM `feisty-outlet-436420-a9.l2_all_tables.L2_product_purchase`
WHERE product_purchase_id IS NULL;
-- Výsledek: OK (žádné záznamy)

-- Tabulka product_purchase: contract_id
-- Test na kontrolu null hodnot contract_id:
SELECT COUNT (*)
FROM `feisty-outlet-436420-a9.l2_all_tables.L2_product_purchase`
WHERE contract_id IS NULL;
-- Výsledek: OK (žádné záznamy)

-- Tabulka product_purchase: contract_id
-- Test na referenční integritu -> purchase bez existujících kontraktů
SELECT COUNT (*)
FROM `feisty-outlet-436420-a9.l2_all_tables.L2_product_purchase` AS pu
LEFT JOIN `feisty-outlet-436420-a9.l2_all_tables.L2_contract` AS c ON pu.contract_id = c.contract_id
WHERE c.contract_id IS NULL
;
-- Výsledek: 90 210 záznamů. To až tak nevadí, budeme se řídit podle kontraktů. V L3 se hlavní report vytváří přes contracts - tato tabulka bude provázána přes INNER JOIN, takže tyto záznamy navíc odpadnou.

-- Zjištění, které contract_id v tabulce product_purchase nemají provazbu na contract_id v tabulce contract
SELECT *
FROM `feisty-outlet-436420-a9.l2_all_tables.L2_product_purchase` AS pu
LEFT JOIN `feisty-outlet-436420-a9.l2_all_tables.L2_contract` AS c ON pu.contract_id = c.contract_id
WHERE c.contract_id IS NULL
ORDER BY pu.contract_id DESC
;
-- nejvyšší contract_id v tabulce product_purchase, které nemá protějšek v tabulce contract je: 584697

SELECT *
FROM `feisty-outlet-436420-a9.l2_all_tables.L2_contract`
ORDER BY contract_id
LIMIT 10;
-- nejnižšší contract_id v tabulce contract je: 584698

-- Tabulka product_purchase: contract_id
-- Test na referenční integritu -> purchase s existujícími kontrakty
SELECT COUNT (*)
FROM `feisty-outlet-436420-a9.l2_all_tables.L2_product_purchase`AS pu
LEFT JOIN `feisty-outlet-436420-a9.l2_all_tables.L2_contract`AS c ON pu.contract_id = c.contract_id
WHERE c.contract_id IS NOT NULL
;
-- Výsledek: 314 870 záznamů -> OK, je důležité, že existující fungující provázání mezi data product_purchase a contract

-- Tabulka product_purchase: product_id
-- Test na referenční integritu -> purchase bez existujících produktů (package_template)
SELECT COUNT (*)
FROM `feisty-outlet-436420-a9.l2_all_tables.L2_product_purchase` AS pu
LEFT JOIN `feisty-outlet-436420-a9.l2_all_tables.L2_product` AS pr ON pu.product_id = pr.product_id
WHERE pr.product_id IS NULL
;
-- Výsledek: OK (žádné záznamy)

-- Kontroly počtů záznamů L1 vs. L2
WITH count_vrstva_L2 as (
  SELECT COUNT(*) as cnt_all_L2, 'L2' AS vrstva 
  FROM `feisty-outlet-436420-a9.l2_all_tables.L2_product_purchase`
), count_vrstva_L1_odebrano as (
  SELECT COUNT(*) as cnt_all_L1_odeb, 'L1_odebrano' AS vrstva
  FROM `feisty-outlet-436420-a9.l1_all_tables.L1_product_purchase`
  WHERE product_category NOT IN ('rent', 'product')
    OR product_status IN ('disconnected', 'canceled registration', 'canceled')
    OR product_status_id IS NULL  
)
SELECT (cnt_all_L2 + cnt_all_L1_odeb) as cnt_all, 'L2 + L1_odebrano' as vrstva
FROM count_vrstva_L2, count_vrstva_L1_odebrano
UNION ALL
SELECT COUNT(*) as cnt_all, 'L1' AS vrstva 
FROM `feisty-outlet-436420-a9.l1_all_tables.L1_product_purchase`;
-- Výsledek: L1: 655246, L2 + L1_odebrano: 655246, tj. sedí