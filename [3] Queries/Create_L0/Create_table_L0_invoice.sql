------------------------------------------
-- VYTVOŘENÍ TABULKY VČETNĚ DOKUMENTACE --
------------------------------------------
CREATE OR REPLACE EXTERNAL TABLE `feisty-outlet-436420-a9.l0_accounting_system.invoice` (
  id_invoice INT64 OPTIONS (description = 'Unique id of invoice'),
  id_invoice_old INT64 OPTIONS (description = 'Id of previous invoice. If it is not null, means that current invoice id is creadit note or return of the id_invoice_od'),
  invoice_id_contract INT64 OPTIONS (description = 'Unique id of contract'),
 	`date` TIMESTAMP OPTIONS (description = 'Date of issue'),
  scadent TIMESTAMP OPTIONS (description = ' Due date'),
  date_paid  TIMESTAMP OPTIONS (description = 'Date of payment'),
 	start_date  TIMESTAMP OPTIONS (description = 'Start of the invoiced period for the invoice'),
  end_date TIMESTAMP OPTIONS (description = 'End of the invoiced period for the invoice'),
  value FLOAT64 OPTIONS (description = 'value_w_vat'),
  number STRING OPTIONS (description = 'invoice_number'),
  invoice_type INT64 OPTIONS (description = 'Invoice_type: 1 - invoice, 3 -  credit_note, 2 - return, 4 - other'),
  flag_paid_currier BOOL OPTIONS (description = 'Flag if  paid to courier'),
  payed FLOAT64 OPTIONS (description = 'Paid amount with VAT'),
  value_storno FLOAT64 OPTIONS (description = 'Returned amount with VAT'),
  date_insert TIMESTAMP OPTIONS (description = 'Date of insert'),
  status INT64 OPTIONS (description = 'Invoice status. Invoice status < 100  have been issued. >= 100 - not issued'),
  date_update TIMESTAMP OPTIONS (description = 'Date of update'),
  id_branch INT64 OPTIONS (description = 'Id branch')
  -- load_date date OPTIONS (description = 'Date of load')
) OPTIONS (
    description = 'Transactional table that keeps information about all invoices.',
    format = 'CSV',
    uris = ['gs://source_data_accounting_system/invoice.csv'],
    skip_leading_rows = 1
    );

------------
-- TESTY --
------------
-- Tabulka invoice: id_invoice
-- Test na kontrolu unikátních záznamů primárního klíče id_invoice :

SELECT id_invoice, COUNT (*) AS cnt
FROM `feisty-outlet-436420-a9.l0_accounting_system.invoice` 
GROUP BY id_invoice
HAVING cnt > 1;
-- Výsledek: OK (žádné záznamy)

-- Tabulka invoice: id_invoice
-- Test na kontrolu null hodnot primárního klíče id_invoice:
SELECT *
FROM `feisty-outlet-436420-a9.l0_accounting_system.invoice` 
WHERE id_invoice IS NULL;
-- Výsledek: OK (žádné záznamy)

-- Tabulka invoice: id_invoice_old
-- Test na kontrolu null hodnot sloupce id_invoice_old:
SELECT *
FROM `feisty-outlet-436420-a9.l0_accounting_system.invoice` 
WHERE id_invoice_old IS NULL;
-- Výsledek: 3 472 479 záznamů, null hodnoty jsou v tomto případě v pořádku a mají byznysový význam: 
-- "Id_invoice_old: Id of previous invoice. if it's not null, means that current invoice id is credit note or return of the id_invoice_old"

-- Tabulka invoice: id_invoice_old
-- Test na duplicity
SELECT
  id_invoice_old,
  count(*) AS pocet
FROM `feisty-outlet-436420-a9.l0_accounting_system.invoice` 
GROUP BY id_invoice_old
HAVING pocet > 1
ORDER BY pocet DESC
;
-- Výsledek: mnoho id_invoice_old je tam 4x, 3x, 2x
-- Položen dotaz na business stakeholdera: Co tato situace byznysově znamená? A je to v pořádku? 
---- Například id_invoice_old = 38533752 má v tabulce invoice 4 záznamy pro 4 různá id_invoice, váže se k jednomu kontraktu, liší se date, value, payed.
-- Odpověď od business stakaholdera: Duplicity id_invoice_old jsou v pořádku. 
---- Tam je logika navic {# pokud je doklad typu faktura (1) a zaroven je id_invoice_old vyssi nez id_invoice, "id_invoice_old' = dobropis #} 

-- Tabulka invoice: invoice_id_contract
-- Test na referenční integritu -> faktury bez existujících kontraktů
SELECT *
FROM `feisty-outlet-436420-a9.l0_accounting_system.invoice` AS inv
LEFT JOIN `feisty-outlet-436420-a9.l0_crm.contract` AS c ON inv.invoice_id_contract = c.id_contract
WHERE c.id_contract IS NULL
ORDER BY inv.invoice_id_contract DESC
;
-- Výsledek:  2 934 152 záznamů -> S Busisiness stakeholderem vyjasněno, že data jsou časově odříznutá, je to tedy OK, jsou zde faktury ke starým kontraktům

-- Test na referenční integritu -> faktury s existujícími kontrakty
SELECT *
FROM `feisty-outlet-436420-a9.l0_accounting_system.invoice` AS inv
LEFT JOIN `feisty-outlet-436420-a9.l0_crm.contract` AS c ON inv.invoice_id_contract = c.id_contract
WHERE c.id_contract IS NOT NULL
ORDER BY inv.invoice_id_contract DESC
;
-- Výsledek:  614 528 záznamů -> OK, data invoice a contract jsou provázány

-- Tabulka invoice: id_branch
-- Test na referenční integritu -> faktury bez existujících id_branch
SELECT inv.*
FROM `feisty-outlet-436420-a9.l0_accounting_system.invoice` AS inv
LEFT JOIN `feisty-outlet-436420-a9.l0_google_sheet.branch` AS b ON CAST (inv.id_branch AS STRING) = b.id_branch
WHERE b.id_branch IS NULL;
-- Výsledek: OK (žádné záznamy)

-- Tabulka invoice: invoice_type
-- Kontrola, že tento sloupec obsahuje pouze hodnoty 1,2,3,4
SELECT DISTINCT invoice_type
FROM `feisty-outlet-436420-a9.l0_accounting_system.invoice`;
-- Výsledek: OK, obsahuje pouze 1,2,3,4

-------------------------------------
-- NÁVRHY NA TRANSFORMACE PRO L1: --
-------------------------------------
-- 1) Změna datového typu TIMESTAMP->DATE pro: date, scadent,  date_paid,  start_date,  end_date,  date_insert, date_update
-- 2) Změna datového typu FLOAT->NUMERIC pro: value, value_storno 
-- 3) Přidání konvertovaného sloupce invoice_type typu STRING
-- 4) Přidání konvertovaného sloupce status typu BOOLEAN
-- 5) Dotaz na Business stakeholdera: Test na referenční integritu tabulky invoice vs. contract, tj. cizího klíče invoice_id_contract (tab. invoice) vs. primárního klíče id_contract (tab. contract) ukázal
-- že existuje 2 934 152 záznamů v tabulce invoice, které nevedou na žádný contract (příklady: invoice_id_contract = 584697, 584696, 2). 
-- Pouze 614 528 záznamů má spárován id_contract (příklady: invoice_id_contract = 946160, 946158, 584699). Řadila jsem dle invoice_id_contract. 
-- Zdá se, že chybí v contracts záznamy s ID 584698 a menší. Jak se k tomu postavit? 
-- Odpověď od Business stakeholdera: Data jsou časově odříznutá, je to tedy OK, jsou zde faktury ke starým kontraktům.
-- 6) Dotaz na zadávající Data engineera: rozpor v dokumentaci L0 vs. doporučení na Discordu u sloupce invoice_type
-- V dokumentaci: Invice_type: 1 - invoice, 3 -  credit_note, 2 - return, 4 - other
-- Na Discordu: 1 = invoice, 2 = credit_note, 3 = return, 4 = other
-- Předpokládám správně, že platí, co je na Discordu a v dokumentaci vrstvy L0 si máme podle toho upravit?
-- Odpověď od Data engineera: Platí textace z dokumentace.
