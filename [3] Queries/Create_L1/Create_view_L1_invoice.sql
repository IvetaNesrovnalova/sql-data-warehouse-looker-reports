--------------------
-- VYTVOŘENÍ VIEW --
--------------------
CREATE OR REPLACE VIEW `feisty-outlet-436420-a9.l1_all_tables.L1_invoice` AS
(
SELECT
  id_invoice AS invoice_id,
  id_invoice_old AS invoice_previous_id,
  invoice_id_contract AS contract_id,
  DATE(date, "Europe/Prague") AS date_issue, -- konverze data na pražský čas ve formátu DATE (požadavek pro všechna data)
  DATE(scadent, "Europe/Prague") AS due_date,
  DATE(date_paid, "Europe/Prague") AS paid_date,
  DATE(start_date, "Europe/Prague") AS start_date,
  DATE(end_date, "Europe/Prague") AS end_date,
  CAST(value AS NUMERIC) AS amount_w_vat_usd,
  invoice_type AS invoice_type_id,
  CASE 
    WHEN invoice_type = 1 THEN 'invoice'
    WHEN invoice_type = 2 THEN 'return'
    WHEN invoice_type = 3 THEN 'credit_note'
    WHEN invoice_type = 4 THEN 'other'
    ELSE 'unknown' -- Požadavek v dokumentaci pro L1: konvertování ID na stringy (Invoice_type: 1 - invoice, 2 - return, 3 -  credit_note, 4 - other)
  END AS invoice_type,
  CAST(value_storno AS NUMERIC) AS return_w_vat, -- -- konverze datového typu id_branch FOLAT->NUMERIC
  DATE(date_insert, "Europe/Prague") AS insert_date,
  status AS invoice_status_id,
  IF (status <100, TRUE, FALSE) AS flag_invoice_issued, -- Požadavek v dokumentaci pro L1: Invoice status < 100  have been issued. >= 100 - not issued
  DATE(date_update) AS update_date,
  id_branch AS branch_id
FROM `feisty-outlet-436420-a9.l0_accounting_system.invoice`
)
;

---------------------------
-- DOPLNĚNÍ DOKUMENTACE --
---------------------------
ALTER VIEW `feisty-outlet-436420-a9.l1_all_tables.L1_invoice`
SET OPTIONS (
  description = "Transactional table that keeps information about all invoices."
);

ALTER VIEW `feisty-outlet-436420-a9.l1_all_tables.L1_invoice`
ALTER COLUMN invoice_id SET OPTIONS (description = 'PK; Source: L0_invoice; Desc: Unique id of invoice');

ALTER VIEW `feisty-outlet-436420-a9.l1_all_tables.L1_invoice`
ALTER COLUMN invoice_previous_id SET OPTIONS (description = 'Source: L0_invoice; Desc: Id of previous invoice. If it is not null, means that current invoice id is creadit note or return of the id_invoice_od');

ALTER VIEW `feisty-outlet-436420-a9.l1_all_tables.L1_invoice`
ALTER COLUMN contract_id SET OPTIONS (description = 'FK; Source: L0_invoice; Desc: Unique id of contract');

ALTER VIEW `feisty-outlet-436420-a9.l1_all_tables.L1_invoice`
ALTER COLUMN date_issue SET OPTIONS (description = 'Source: L0_invoice; Desc: Date of issue; Transform to type DATE Europe/Prague');

ALTER VIEW `feisty-outlet-436420-a9.l1_all_tables.L1_invoice`
ALTER COLUMN due_date SET OPTIONS (description = 'Source: L0_invoice; Desc: Due date; Transform to type DATE Europe/Prague');

ALTER VIEW `feisty-outlet-436420-a9.l1_all_tables.L1_invoice`
ALTER COLUMN paid_date SET OPTIONS (description = 'Source: L0_invoice; Desc: Date of payment; Transform to type DATE Europe/Prague');

ALTER VIEW `feisty-outlet-436420-a9.l1_all_tables.L1_invoice`
ALTER COLUMN start_date SET OPTIONS (description = 'Source: L0_invoice; Desc: Start of the invoiced period for the invoice; Transform to type DATE Europe/Prague');

ALTER VIEW `feisty-outlet-436420-a9.l1_all_tables.L1_invoice`
ALTER COLUMN end_date SET OPTIONS (description = 'Source: L0_invoice; Desc: End of the invoiced period for the invoice; Transform to type DATE Europe/Prague');

ALTER VIEW `feisty-outlet-436420-a9.l1_all_tables.L1_invoice`
ALTER COLUMN amount_w_vat_usd SET OPTIONS (description = 'Source: L0_invoice; Desc: Amount with VAT; Transform to type NUMERIC');

ALTER VIEW `feisty-outlet-436420-a9.l1_all_tables.L1_invoice`
ALTER COLUMN invoice_type_id SET OPTIONS (description = 'Source: L0_invoice; Desc: Invoice_type_id that means: 1 - invoice, 2 - return, 3 -  credit_note,  4 - other');

ALTER VIEW `feisty-outlet-436420-a9.l1_all_tables.L1_invoice`
ALTER COLUMN invoice_type SET OPTIONS (description = 'Source: L0_invoice; Desc: Invoice_type derived from mean of Invoice_type_id');

ALTER VIEW `feisty-outlet-436420-a9.l1_all_tables.L1_invoice`
ALTER COLUMN return_w_vat SET OPTIONS (description = 'Source: L0_invoice; Desc: Returned amount with VAT');

ALTER VIEW `feisty-outlet-436420-a9.l1_all_tables.L1_invoice`
ALTER COLUMN insert_date SET OPTIONS (description = 'Source: L0_invoice; Desc: Date of insert; Transform to type DATE Europe/Prague');

ALTER VIEW `feisty-outlet-436420-a9.l1_all_tables.L1_invoice`
ALTER COLUMN invoice_status_id SET OPTIONS (description = 'Source: L0_invoice; Desc: Invoice status. Invoice status < 100  have been issued. >= 100 - not issued');

ALTER VIEW `feisty-outlet-436420-a9.l1_all_tables.L1_invoice`
ALTER COLUMN flag_invoice_issued SET OPTIONS (description = 'Source: L0_invoice; Desc: Boolean value derived from invoice_status_id by rule "status < 100" -> TRUE, "status >=100 " -> FASE');

ALTER VIEW `feisty-outlet-436420-a9.l1_all_tables.L1_invoice`
ALTER COLUMN update_date SET OPTIONS (description = 'Source: L0_invoice; Desc: Date of update; Transform to type DATE Europe/Prague');

ALTER VIEW `feisty-outlet-436420-a9.l1_all_tables.L1_invoice`
ALTER COLUMN branch_id SET OPTIONS (description = 'FK; Source: L0_invoice; Desc: Unique id of branch');

------------
-- TESTY --
------------
-- Tabulka invoice: invoice_id
-- Test na kontrolu unikátních záznamů primárního klíče invoice_id :
SELECT invoice_id, COUNT (*) AS cnt
FROM `feisty-outlet-436420-a9.l1_all_tables.L1_invoice` 
GROUP BY invoice_id
HAVING cnt > 1;
-- Výsledek: OK (žádné záznamy)

-- Tabulka invoice: invoice_id
-- Test na kontrolu null hodnot primárního klíče invoice_id:
SELECT *
FROM `feisty-outlet-436420-a9.l1_all_tables.L1_invoice` 
WHERE invoice_id IS NULL;
-- Výsledek: OK (žádné záznamy)

-- Tabulka invoice: invoice_previous_id
-- Test na kontrolu null hodnot sloupce invoice_previous_id:
SELECT count (*)
FROM `feisty-outlet-436420-a9.l1_all_tables.L1_invoice` 
WHERE invoice_previous_id IS NULL;
-- Výsledek: 3 472 479 záznamů, ale to je dle dokumentace v pořádku, faktura nemusí mít předchozí fakturu.

-- Zobrazení duplicitních záznamů
SELECT
  invoice_previous_id,
  count(*) AS pocet
FROM `feisty-outlet-436420-a9.l1_all_tables.L1_invoice` 
GROUP BY invoice_previous_id
HAVING pocet > 1
ORDER BY pocet DESC
;
-- Výsledek: mnoho id_invoice_old je tam 4x, 3x, 2x
-- Položen dotaz na business stakeholdera: Co tato situace byznysově znamená? A je to v pořádku? 
-- Odpověď od business stakaholdera: Duplicity id_invoice_old jsou v pořádku. 
---- Tam je logika navic {# pokud je doklad typu faktura (1) a zaroven je id_invoice_old vyssi nez id_invoice, "id_invoice_old' = dobropis #} 

-- Tabulka invoice: contract_id
-- Test na referenční integritu -> faktury bez existujících kontraktů
SELECT count (*)
FROM `feisty-outlet-436420-a9.l1_all_tables.L1_invoice` AS inv
LEFT JOIN `feisty-outlet-436420-a9.l1_all_tables.L1_contract` AS c ON inv.contract_id = c.contract_id
WHERE c.contract_id IS NULL
;
-- Výsledek:  2 934 152 záznamů !!! -> S Busisiness stakeholderem vyjasněno, že data jsou časově odříznutá, je to tedy OK, jsou zde faktury ke starým kontraktům

-- Test na referenční integritu -> faktury s existujícími kontrakty
SELECT count (*)
FROM `feisty-outlet-436420-a9.l1_all_tables.L1_invoice` AS inv
LEFT JOIN `feisty-outlet-436420-a9.l1_all_tables.L1_contract` AS c ON inv.contract_id = c.contract_id
WHERE c.contract_id IS NOT NULL
;
-- Výsledek:  614 528 záznamů -> OK, data invoice a contract jsou provázány

-- Tabulka invoice: branch_id
-- Test na referenční integritu -> faktury bez existujících branch_id
SELECT inv.*
FROM `feisty-outlet-436420-a9.l1_all_tables.L1_invoice` AS inv
LEFT JOIN `feisty-outlet-436420-a9.l1_all_tables.L1_branch` AS b ON inv.branch_id = b.branch_id
WHERE b.branch_id IS NULL;
-- Výsledek: OK (žádné záznamy)

-- Tabulka invoice: invoice_type
-- Kontrola, že tento sloupec obsahuje pouze hodnoty 1,2,3,4
SELECT DISTINCT invoice_type_id
FROM `feisty-outlet-436420-a9.l1_all_tables.L1_invoice`
WHERE invoice_type_id NOT IN (1,2,3,4)
;
-- Výsledek: OK (žádné záznamy), obsahuje pouze 1,2,3,4

-- Kontroly počtů záznamů L0 vs. L1
SELECT COUNT(*) as cnt_all, 'L1' AS vrstva_L1 FROM `feisty-outlet-436420-a9.l1_all_tables.L1_invoice` 
UNION ALL
SELECT COUNT(*) as cnt_all, 'L0' AS vrstva_L0 FROM `feisty-outlet-436420-a9.l0_accounting_system.invoice`;
-- Výsledek: OK, stejný počet záznamů
