------------------------------------------
-- VYTVOŘENÍ TABULKY VČETNĚ DOKUMENTACE --
------------------------------------------
CREATE OR REPLACE EXTERNAL TABLE `feisty-outlet-436420-a9.l0_crm.product_purchase` (
  id_package INT64 OPTIONS (description = 'Unique identifier of purchased package'),  
  id_contract INT64 OPTIONS (description = 'Unique identifier of contract'), 
  id_package_template INT64 OPTIONS (description = 'Unique identifier of product'),
  date_insert TIMESTAMP OPTIONS (description =  'Date when the row was inserted into system'),
  start_date STRING OPTIONS (description =  'Package valid from date'),
  end_date STRING OPTIONS (description =  'Package valid to date'),
  fee FLOAT64 OPTIONS (description =  'Price without vat'),
  date_update TIMESTAMP OPTIONS (description =  'Date when the row was updated'),
  package_status INT64 OPTIONS (description =  'Id of package status'),
  measure_unit STRING OPTIONS (description =  'Unit od measure'),
  id_branch INT64 OPTIONS (description =  'Id of branch'),
  load_date DATE OPTIONS (description =  'Date of load')
) OPTIONS (
    description = 'Product purchases linked to a contract. It contains information regarding the price excluding VAT, the date of creation, the start and end dates of validity, and other details about the package, that has been purchased. One contract (id_contract) can be linked to multiple id_packages (a combination of contract and package), but each id_package is linked to only one id_contract.',
    format = 'CSV',
    uris = ['gs://source_data_crm/product_purchases.csv'],
    skip_leading_rows = 1
    );

------------
-- TESTY --
------------
-- Tabulka product_purchase: id_package
-- Test na kontrolu unikátních záznamů primárního klíče id_package :

SELECT id_package, COUNT (*) AS cnt
FROM `feisty-outlet-436420-a9.l0_crm.product_purchase`
GROUP BY id_package
HAVING cnt > 1;
-- Výsledek: OK (žádné záznamy)

-- Tabulka product_purchase: id_package
-- Test na kontrolu null hodnot primárního klíče id_package::
SELECT *
FROM `feisty-outlet-436420-a9.l0_crm.product_purchase`
WHERE id_package IS NULL;
-- Výsledek: OK (žádné záznamy)

-- Tabulka product_purchase: id_contract
-- Test na kontrolu null hodnot id_contract:
SELECT *
FROM `feisty-outlet-436420-a9.l0_crm.product_purchase`
WHERE id_contract IS NULL;
-- Výsledek: OK (žádné záznamy)

-- Tabulka product_purchase: start_date, end_date
-- Test na kontrolu null hodnot start_date, end_date:
SELECT *
FROM `feisty-outlet-436420-a9.l0_crm.product_purchase`
WHERE start_date IS NULL;
-- Výsledek: 99 177 záznamů -> ověřeno s Business stakeholderem, že mazat se tyto záznamy nebudou

SELECT *
FROM `feisty-outlet-436420-a9.l0_crm.product_purchase`
WHERE end_date IS NULL;
-- Výsledek: 99 177 záznamů -> ověřeno s Business stakeholderem, že mazat se tyto záznamy nebudou


-- Tabulka product_purchase: id_contract
-- Test na referenční integritu -> purchase bez existujících kontraktů
SELECT pu.*
FROM `feisty-outlet-436420-a9.l0_crm.product_purchase` AS pu
LEFT JOIN `feisty-outlet-436420-a9.l0_crm.contract` AS c ON pu.id_contract = c.id_contract
WHERE c.id_contract IS NULL
;
-- Výsledek: 200 667 záznamů !!! -> S Busisiness stakeholderem vyjasněno, že data jsou časově odříznutá, je to tedy OK, jsou zde product_purchase ke starým kontraktům

-- Tabulka product_purchase: id_contract
-- Test na referenční integritu -> purchase s existujícími kontrakty
SELECT pu.*
FROM `feisty-outlet-436420-a9.l0_crm.product_purchase` AS pu
LEFT JOIN `feisty-outlet-436420-a9.l0_crm.contract` AS c ON pu.id_contract = c.id_contract
WHERE c.id_contract IS NOT NULL
;
-- Výsledek: 454 579 záznamů -> OK, data product_purchase a contract jsou provázány

-- Tabulka product_purchase: id_package_template
-- Test na referenční integritu -> purchase bez existujících produktů (package_template)
SELECT pu.*
FROM `feisty-outlet-436420-a9.l0_crm.product_purchase` AS pu
LEFT JOIN `feisty-outlet-436420-a9.l0_google_sheet.product` AS pr ON pu.id_package_template = pr.id_product
WHERE pr.id_product IS NULL
;
-- Výsledek: OK (žádné záznamy)

-- Tabulka product_purchase: package_status
-- Test na referenční integritu -> purchase bez existujících package_status
SELECT pu.*
FROM `feisty-outlet-436420-a9.l0_crm.product_purchase` AS pu
LEFT JOIN `feisty-outlet-436420-a9.l0_google_sheet.status` AS st ON pu.package_status = st.id_status
WHERE st.id_status IS NULL
;
-- Výsledek: 10 záznamů !!! Všechny mají package_status null -> bude odstraněno v transformaci na L1

-- Tabulka product_purchase: id_branch
-- Test na referenční integritu -> purchase bez existujících package_status
SELECT pu.*
FROM `feisty-outlet-436420-a9.l0_crm.product_purchase` AS pu
LEFT JOIN `feisty-outlet-436420-a9.l0_google_sheet.branch` AS b ON CAST (pu.id_branch AS STRING) = b.id_branch
WHERE b.id_branch IS NULL
;
-- Výsledek: OK (žádné záznamy)

-------------------------------------
-- NÁVRHY NA TRANSFORMACE PRO L1: --
-------------------------------------
-- 1) Změna datového typu STRING->DATE pro: start_date, end_date
-- 2) Odstranění záznamů s package_status = null