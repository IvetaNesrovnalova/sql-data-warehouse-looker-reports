--------------------
-- VYTVOŘENÍ VIEW --
--------------------
CREATE OR REPLACE VIEW `feisty-outlet-436420-a9.l1_all_tables.L1_contract` AS
(
SELECT
  id_contract AS contract_id,
  id_branch AS branch_id,
  DATE(date_contract_valid_from, "Europe/Prague") AS contract_valid_from, -- konverze data na pražský čas ve formátu DATE (požadavek pro všechna data)
  DATE(date_contract_valid_to, "Europe/Prague") AS contract_valid_to, 
  DATE(date_registered,  "Europe/Prague") AS registred_date, 
  DATE(date_signed, "Europe/Prague") AS signed_date, 
  DATE(activation_process_date, "Europe/Prague") AS activation_process_date, 
  DATE(prolongation_date, "Europe/Prague") AS prolongation_date,
  registration_end_reason,
  flag_prolongation,
  flag_send_inv_email AS  flag_send_email,
  contract_status
FROM `feisty-outlet-436420-a9.l0_crm.contract`
)
;

---------------------------
-- DOPLNĚNÍ DOKUMENTACE --
---------------------------
ALTER VIEW `feisty-outlet-436420-a9.l1_all_tables.L1_contract`
SET OPTIONS (
  description = "Table contains info about contracts."
);

ALTER VIEW `feisty-outlet-436420-a9.l1_all_tables.L1_contract`
ALTER COLUMN contract_id SET OPTIONS (description = 'PK; Source: L0_contract; Desc: Unique id of contract');

ALTER VIEW `feisty-outlet-436420-a9.l1_all_tables.L1_contract`
ALTER COLUMN branch_id SET OPTIONS (description = 'FK; Source: L0_contract; Desc: Unique id of branch');

ALTER VIEW `feisty-outlet-436420-a9.l1_all_tables.L1_contract`
ALTER COLUMN contract_valid_from SET OPTIONS (description = 'Source: L0_contract; Desc: Date from which a contract is valid; Transform to type DATE Europe/Prague');

ALTER VIEW `feisty-outlet-436420-a9.l1_all_tables.L1_contract`
ALTER COLUMN contract_valid_to SET OPTIONS (description = 'Source: L0_contract; Desc: Date to which a contract is valid; Transform to type DATE Europe/Prague');

ALTER VIEW `feisty-outlet-436420-a9.l1_all_tables.L1_contract`
ALTER COLUMN registred_date SET OPTIONS (description = 'Source: L0_contract; Desc: Date of registration; Transform to type DATE Europe/Prague');

ALTER VIEW `feisty-outlet-436420-a9.l1_all_tables.L1_contract`
ALTER COLUMN signed_date SET OPTIONS (description = 'Source: L0_contract; Desc: Date of signature; Transform to type DATE Europe/Prague');

ALTER VIEW `feisty-outlet-436420-a9.l1_all_tables.L1_contract`
ALTER COLUMN activation_process_date SET OPTIONS (description = 'Source: L0_contract; Desc: Date of activation; Transform to type DATE Europe/Prague');

ALTER VIEW `feisty-outlet-436420-a9.l1_all_tables.L1_contract`
ALTER COLUMN prolongation_date SET OPTIONS (description = 'Source: L0_contract; Desc: Date of prolongation; Transform to type DATE Europe/Prague');

ALTER VIEW `feisty-outlet-436420-a9.l1_all_tables.L1_contract`
ALTER COLUMN registration_end_reason SET OPTIONS (description = 'Source: L0_contract; Desc: Reason for the registration to be ended');

ALTER VIEW `feisty-outlet-436420-a9.l1_all_tables.L1_contract`
ALTER COLUMN flag_prolongation SET OPTIONS (description = 'Source: L0_contract; Desc: if contract was prolongued');

ALTER VIEW `feisty-outlet-436420-a9.l1_all_tables.L1_contract`
ALTER COLUMN flag_send_email SET OPTIONS (description = 'Source: L0_contract; Desc: If the invoice is sent as email. True - yes, false - other methods');

ALTER VIEW `feisty-outlet-436420-a9.l1_all_tables.L1_contract`
ALTER COLUMN contract_status SET OPTIONS (description = 'Source: L0_contract; Desc: Status of contract');

------------
-- TESTY --
------------
-- Tabulka contract: contract_id
-- Test na kontrolu unikátních záznamů primárního klíče contract_id :
SELECT contract_id, COUNT (*) AS cnt
FROM `feisty-outlet-436420-a9.l1_all_tables.L1_contract`
GROUP BY contract_id
HAVING cnt > 1;
-- Výsledek: OK (žádné záznamy)

-- Tabulka contract: contract_id
-- Test na kontrolu null hodnot primárního klíče contract_id:
SELECT *
FROM `feisty-outlet-436420-a9.l1_all_tables.L1_contract`
WHERE contract_id IS NULL;
-- Výsledek: OK (žádné záznamy)

-- Tabulka contract: branch_id
-- Test na referenční integritu -> kontrakty bez existující branch_id
SELECT c.*
FROM `feisty-outlet-436420-a9.l1_all_tables.L1_contract` AS c
LEFT JOIN `feisty-outlet-436420-a9.l1_all_tables.L1_branch` AS b ON c.branch_id = b.branch_id
WHERE b.branch_id IS NULL;
-- Výsledek: OK (žádné záznamy)

-- Kontroly počtů záznamů L0 vs. L1
SELECT COUNT(*) as cnt_all, 'L1' AS vrstva_L1 FROM `feisty-outlet-436420-a9.l1_all_tables.L1_contract`
UNION ALL
SELECT COUNT(*) as cnt_all, 'L0' AS vrstva_L0 FROM `feisty-outlet-436420-a9.l0_crm.contract` ;
-- Výsledek: OK, stejný počet záznamů
