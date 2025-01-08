-----------------------
-- VYTVOŘENÍ TABULKY --
-----------------------
CREATE OR REPLACE TABLE `feisty-outlet-436420-a9.l2_all_tables.L2_contract` as
  SELECT
    contract_id,
    branch_id,
     CASE 
      WHEN contract_valid_from IS NOT NULL THEN contract_valid_from
      WHEN registred_date IS NOT NULL THEN registred_date
      WHEN signed_date IS NOT NULL THEN signed_date
      ELSE activation_process_date
    END AS contract_valid_from, -- Ve sloupci contract_valid_from je mnoho NULL hodnot. Dle dohody s business stakeholderem zapracováno ošetření: 
                                -- pokud je contract_valid_from == NULL, poté contract_valid_from = registred_date, 
                                -- pokud je i registred_date == NULL, tak contract_valid_from = signed_date, 
                                -- pokud je i signed_date == NULL, tak contract_valid_from = activation_process_date
    contract_valid_to,
    registred_date,
    signed_date,
    activation_process_date,
    prolongation_date,
    registration_end_reason,
    flag_prolongation,
    flag_send_email,
    contract_status
FROM `feisty-outlet-436420-a9.l1_all_tables.L1_contract`
WHERE registred_date IS NOT NULL; -- Požadavek v dokumentaci pro L2: L2_contract should contain only registered contracts ( which means that date of registration is not null, not by status!)
                                  -- status can change, but not null registration date means that a contract has been registered

---------------------------
-- DOPLNĚNÍ DOKUMENTACE --
---------------------------
ALTER TABLE `feisty-outlet-436420-a9.l2_all_tables.L2_contract`
SET OPTIONS (
  description = "Table contains info about contracts. Table contains only registered contracts (which means that date of registration is not null)."
);

ALTER TABLE `feisty-outlet-436420-a9.l2_all_tables.L2_contract`
ALTER COLUMN contract_id SET OPTIONS (description = 'PK; Source: L1_contract; Desc: Unique id of contract');

ALTER TABLE `feisty-outlet-436420-a9.l2_all_tables.L2_contract`
ALTER COLUMN branch_id SET OPTIONS (description = 'FK; Source: L1_contract; Desc: Unique id of branch');

ALTER TABLE `feisty-outlet-436420-a9.l2_all_tables.L2_contract`
ALTER COLUMN contract_valid_from SET OPTIONS (description = 'Source: L1_contract; Desc: Date from which a contract is valid; Format: DATE Europe/Prague');

ALTER TABLE `feisty-outlet-436420-a9.l2_all_tables.L2_contract`
ALTER COLUMN contract_valid_to SET OPTIONS (description = 'Source: L1_contract; Desc: Date to which a contract is valid; Format: DATE Europe/Prague');

ALTER TABLE `feisty-outlet-436420-a9.l2_all_tables.L2_contract`
ALTER COLUMN registred_date SET OPTIONS (description = 'Source: L1_contract; Desc: Date of registration; Format: DATE Europe/Prague');

ALTER TABLE `feisty-outlet-436420-a9.l2_all_tables.L2_contract`
ALTER COLUMN signed_date SET OPTIONS (description = 'Source: L1_contract; Desc: Date of signature; Format: DATE Europe/Prague');

ALTER TABLE `feisty-outlet-436420-a9.l2_all_tables.L2_contract`
ALTER COLUMN activation_process_date SET OPTIONS (description = 'Source: L1_contract; Desc: Date of activation; Format: DATE Europe/Prague');

ALTER TABLE `feisty-outlet-436420-a9.l2_all_tables.L2_contract`
ALTER COLUMN prolongation_date SET OPTIONS (description = 'Source: L1_contract; Desc: Date of prolongation; Format: DATE Europe/Prague');

ALTER TABLE `feisty-outlet-436420-a9.l2_all_tables.L2_contract`
ALTER COLUMN registration_end_reason SET OPTIONS (description = 'Source: L1_contract; Desc: Reason for the registration to be ended');

ALTER TABLE `feisty-outlet-436420-a9.l2_all_tables.L2_contract`
ALTER COLUMN flag_prolongation SET OPTIONS (description = 'Source: L1_contract; Desc: if contract was prolongued');

ALTER TABLE `feisty-outlet-436420-a9.l2_all_tables.L2_contract`
ALTER COLUMN flag_send_email SET OPTIONS (description = 'Source: L1_contract; Desc: If the invoice is sent as email. True - yes, false - other methods');

ALTER TABLE `feisty-outlet-436420-a9.l2_all_tables.L2_contract`
ALTER COLUMN contract_status SET OPTIONS (description = 'Source: L1_contract; Desc: Status of contract');

------------
-- TESTY --
------------
-- Tabulka contract: contract_id
-- Test na kontrolu unikátních záznamů primárního klíče contract_id :
SELECT contract_id, COUNT (*) AS cnt
FROM `feisty-outlet-436420-a9.l2_all_tables.L2_contract`
GROUP BY contract_id
HAVING cnt > 1;
-- Výsledek: OK (žádné záznamy)

-- Tabulka contract: contract_id
-- Test na kontrolu null hodnot primárního klíče contract_id:
SELECT *
FROM `feisty-outlet-436420-a9.l2_all_tables.L2_contract`
WHERE contract_id IS NULL;
-- Výsledek: OK (žádné záznamy)

-- Tabulka contract: branch_id
-- Test na referenční integritu -> kontrakty bez existující branch_id
SELECT c.*
FROM `feisty-outlet-436420-a9.l2_all_tables.L2_contract` AS c
LEFT JOIN `feisty-outlet-436420-a9.l1_all_tables.L1_branch` AS b ON c.branch_id = b.branch_id
WHERE b.branch_id IS NULL;
-- Výsledek: OK (žádné záznamy)

-- Kontroly počtů záznamů L0 vs. L1
SELECT COUNT(*) as cnt_all, 'L2' AS vrstva FROM `feisty-outlet-436420-a9.l2_all_tables.L2_contract`
UNION ALL
SELECT COUNT(*) as cnt_all, 'L1' AS vrstva FROM `feisty-outlet-436420-a9.l1_all_tables.L1_contract` ;
-- Výsledek: OK, stejný počet záznamů





