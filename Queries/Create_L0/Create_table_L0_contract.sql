------------------------------------------
-- VYTVOŘENÍ TABULKY VČETNĚ DOKUMENTACE --
------------------------------------------
CREATE OR REPLACE EXTERNAL TABLE `feisty-outlet-436420-a9.l0_crm.contract` (
  id_contract INT64 OPTIONS (description = 'Unique id of contract'),
  id_branch INT64 OPTIONS (description = 'Unique id of branch'),
 	date_contract_valid_from TIMESTAMP OPTIONS (description = 'Date from which a contract is valid'),
  date_contract_valid_to TIMESTAMP  OPTIONS (description = 'Date to which a contract is valid'),
  date_registered TIMESTAMP OPTIONS (description = 'Date of registration'),
  date_signed TIMESTAMP OPTIONS (description = 'Date of signature'),
  activation_process_date TIMESTAMP OPTIONS (description = 'Date of activation'),
  prolongation_date TIMESTAMP OPTIONS (description = 'Date of prolongation'),
  registration_end_reason STRING OPTIONS (description = 'Reason for the registration to be ended'),
  flag_prolongation BOOL OPTIONS (description = 'if contract  was prolongued'),
  flag_send_inv_email BOOL OPTIONS (description = 'If the invoice is sent as email. True - yes, false - other methods'),
  contract_status STRING OPTIONS (description = 'Status of contract'),
  load_date DATE OPTIONS (description = 'Date of load'),
  ) OPTIONS (
    description = 'Table contains info about contracts.',
    format = 'CSV',
    uris = ['gs://source_data_crm/contracts.csv'],
    skip_leading_rows = 1
    );

------------
-- TESTY --
------------
-- Tabulka contract: id_contract
-- Test na kontrolu unikátních záznamů primárního klíče id_contract :

SELECT id_contract, COUNT (*) AS cnt
FROM `feisty-outlet-436420-a9.l0_crm.contract`
GROUP BY id_contract
HAVING cnt > 1;
-- Výsledek: OK (žádné záznamy)

-- Tabulka contract: id_contract
-- Test na kontrolu null hodnot primárního klíče id_contract:
SELECT *
FROM `feisty-outlet-436420-a9.l0_crm.contract`
WHERE id_contract IS NULL;
-- Výsledek: OK (žádné záznamy)

-- Tabulka contract: id_branch
-- Test na referenční integritu -> kontrakty bez existující id_branch
SELECT c.*
FROM `feisty-outlet-436420-a9.l0_crm.contract` AS c
LEFT JOIN `feisty-outlet-436420-a9.l0_google_sheet.branch` AS b ON CAST(c.id_branch AS STRING) = b.id_branch
WHERE b.id_branch IS NULL;
-- Výsledek: OK (žádné záznamy)

-------------------------------------
-- NÁVRHY NA TRANSFORMACE PRO L1: --
-------------------------------------
-- žádné nálezy