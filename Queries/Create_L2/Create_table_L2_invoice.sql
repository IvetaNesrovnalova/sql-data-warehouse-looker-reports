-----------------------
-- VYTVOŘENÍ TABULKY --
-----------------------
CREATE OR REPLACE TABLE `feisty-outlet-436420-a9.l2_all_tables.L2_invoice` as
  SELECT
    l1_invoice.invoice_id,
    l1_invoice.contract_id,
    l1_invoice.date_issue,
    l1_invoice.due_date,
    l1_invoice.paid_date,
    l1_invoice.start_date,
    l1_invoice.end_date,
    l1_invoice.amount_w_vat_usd,
    CASE
      WHEN l1_invoice.amount_w_vat_usd <= 0 then 0
      WHEN l1_invoice.amount_w_vat_usd > 0 then l1_invoice.amount_w_vat_usd / 1.2
    END AS amount_wo_vat_usd,             -- Požadavek v dokumentaci pro L2: have  column "amount without VAT" assuming that VAT = 20%
    l1_invoice.insert_date,
    l1_invoice.update_date,
    l1_invoice.branch_id,
    ROW_NUMBER() OVER (PARTITION BY l1_invoice.contract_id ORDER BY l1_invoice.date_issue ASC) AS invoice_order
                                          -- Požadavek v dokumentaci pro L2: the order of invoices on one contract (order by date_issue)
FROM `feisty-outlet-436420-a9.l1_all_tables.L1_invoice` as l1_invoice
INNER JOIN `feisty-outlet-436420-a9.l2_all_tables.L2_contract` as l2_contract ON l1_invoice.contract_id = l2_contract.contract_id 
                                          -- Požadavek v dokumentaci pro L2: Only invoices that have contracts in L2
WHERE l1_invoice.invoice_type = 'invoice' -- Požadavek v dokumentaci pro L2: L2_invoice table should have: invoices with type = "invoice"
AND l1_invoice.flag_invoice_issued        -- Požadavek v dokumentaci pro L2: invoices with flag_invoice_issued = true -> invoices have been sent
;

---------------------------
-- DOPLNĚNÍ DOKUMENTACE --
---------------------------
ALTER TABLE `feisty-outlet-436420-a9.l2_all_tables.L2_invoice`
SET OPTIONS (
  description = "Transactional table that keeps information about all invoices. Table contains only invoices with type = invoice, only invoices with flag_invoice_issued = true (means that invoices have been sent) and only invoices that have contracts in L2 layer."
);

ALTER TABLE `feisty-outlet-436420-a9.l2_all_tables.L2_invoice`
ALTER COLUMN invoice_id SET OPTIONS (description = 'PK; Source: L1_invoice; Desc: Unique id of invoice');

ALTER TABLE `feisty-outlet-436420-a9.l2_all_tables.L2_invoice`
ALTER COLUMN contract_id SET OPTIONS (description = 'FK; Source: L1_invoice; Desc: Unique id of contract');

ALTER TABLE `feisty-outlet-436420-a9.l2_all_tables.L2_invoice`
ALTER COLUMN date_issue SET OPTIONS (description = 'Source: L1_invoice; Desc: Date of issue; Format: DATE Europe/Prague');

ALTER TABLE `feisty-outlet-436420-a9.l2_all_tables.L2_invoice`
ALTER COLUMN due_date SET OPTIONS (description = 'Source: L1_invoice; Desc: Due date; Format: DATE Europe/Prague');

ALTER TABLE `feisty-outlet-436420-a9.l2_all_tables.L2_invoice`
ALTER COLUMN paid_date SET OPTIONS (description = 'Source: L1_invoice; Desc: Date of payment; Format: DATE Europe/Prague');

ALTER TABLE `feisty-outlet-436420-a9.l2_all_tables.L2_invoice`
ALTER COLUMN start_date SET OPTIONS (description = 'Source: L1_invoice; Desc: Start of the invoiced period for the invoice; Format: DATE Europe/Prague');

ALTER TABLE `feisty-outlet-436420-a9.l2_all_tables.L2_invoice`
ALTER COLUMN end_date SET OPTIONS (description = 'Source: L1_invoice; Desc: End of the invoiced period for the invoice; Format: DATE Europe/Prague');

ALTER TABLE `feisty-outlet-436420-a9.l2_all_tables.L2_invoice`
ALTER COLUMN amount_w_vat_usd SET OPTIONS (description = 'Source: L1_invoice; Desc: Amount with VAT; Format: NUMERIC');

ALTER TABLE `feisty-outlet-436420-a9.l2_all_tables.L2_invoice`
ALTER COLUMN amount_wo_vat_usd SET OPTIONS (description = 'Source: L1_invoice; Desc: Amount without VAT; Format: NUMERIC. Calculated from amount_w_vat_usd assuming VAT = 20 %');

ALTER TABLE `feisty-outlet-436420-a9.l2_all_tables.L2_invoice`
ALTER COLUMN insert_date SET OPTIONS (description = 'Source: L1_invoice; Desc: Date of insert; Format: DATE Europe/Prague');

ALTER TABLE `feisty-outlet-436420-a9.l2_all_tables.L2_invoice`
ALTER COLUMN update_date SET OPTIONS (description = 'Source: L1_invoice; Desc: Date of update; Format: DATE Europe/Prague');

ALTER TABLE `feisty-outlet-436420-a9.l2_all_tables.L2_invoice`
ALTER COLUMN branch_id SET OPTIONS (description = 'FK; Source: L1_invoice; Desc: Unique id of branch');

ALTER TABLE `feisty-outlet-436420-a9.l2_all_tables.L2_invoice`
ALTER COLUMN invoice_order SET OPTIONS (description = 'Source: L1_invoice; Desc: The order of invoices on one contract (ordered by date_issue)');

------------
-- TESTY --
------------
-- Tabulka invoice: invoice_id
-- Test na kontrolu unikátních záznamů primárního klíče invoice_id :
SELECT invoice_id, COUNT (*) AS cnt
FROM `feisty-outlet-436420-a9.l2_all_tables.L2_invoice` 
GROUP BY invoice_id
HAVING cnt > 1;
-- Výsledek: OK (žádné záznamy)

-- Tabulka invoice: invoice_id
-- Test na kontrolu null hodnot primárního klíče invoice_id:
SELECT COUNT (*) AS cnt_invoice_id_is_null
FROM `feisty-outlet-436420-a9.l2_all_tables.L2_invoice`  
WHERE invoice_id IS NULL;
-- Výsledek: OK (žádné záznamy)

-- Tabulka invoice: contract_id
-- Test na referenční integritu -> faktury bez existujících kontraktů
SELECT count (*)
FROM `feisty-outlet-436420-a9.l2_all_tables.L2_invoice`  AS inv
LEFT JOIN `feisty-outlet-436420-a9.l2_all_tables.L2_contract` AS c ON inv.contract_id = c.contract_id
WHERE c.contract_id IS NULL
;
-- Výsledek: OK (žádné záznamy)

-- Tabulka invoice: branch_id
-- Test na referenční integritu -> faktury bez existujících branch_id
SELECT inv.*
FROM `feisty-outlet-436420-a9.l2_all_tables.L2_invoice`  AS inv
LEFT JOIN `feisty-outlet-436420-a9.l1_all_tables.L1_branch` AS b ON inv.branch_id = b.branch_id
WHERE b.branch_id IS NULL;
-- Výsledek: OK (žádné záznamy)

-- Kontroly počtů záznamů L0 vs. L1
WITH count_vrstva_L2 as (
SELECT COUNT(*) as cnt_all_L2, 'L2' AS vrstva
FROM `feisty-outlet-436420-a9.l2_all_tables.L2_invoice` 
), count_vrstva_L1_odebrano as (
SELECT COUNT(*) as cnt_all_L1_odeb, 'L1_odebrano' AS vrstva
FROM `feisty-outlet-436420-a9.l1_all_tables.L1_invoice` as l1_invoice
LEFT JOIN feisty-outlet-436420-a9.l2_all_tables.L2_contract as l2_contract ON l1_invoice.contract_id = l2_contract.contract_id
WHERE l2_contract.contract_id IS NULL
OR l1_invoice.invoice_type NOT LIKE 'invoice'
OR l1_invoice.flag_invoice_issued != true
)
SELECT (cnt_all_L2 + cnt_all_L1_odeb) as cnt_all, 'L2 + L1_odebrano' as vrstva
FROM count_vrstva_L2, count_vrstva_L1_odebrano
UNION ALL
SELECT COUNT(*) as cnt_all, 'L1' AS vrstva FROM `feisty-outlet-436420-a9.l1_all_tables.L1_invoice`;
-- Výsledek: L1: 3548680, L2 + L1_odebrano: 3548680, tj. sedí


