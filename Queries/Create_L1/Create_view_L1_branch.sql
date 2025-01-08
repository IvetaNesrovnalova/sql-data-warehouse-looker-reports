--------------------
-- VYTVOŘENÍ VIEW --
--------------------
CREATE OR REPLACE VIEW `feisty-outlet-436420-a9.l1_all_tables.L1_branch` AS
(
  SELECT
    CAST(NULLIF(id_branch, 'NULL') AS INT64) AS branch_id, -- konverze datového typu id_branch STRING->INT64
    branch_name
  FROM `feisty-outlet-436420-a9.l0_google_sheet.branch`
  WHERE NULLIF(id_branch, 'NULL') IS NOT NULL AND id_branch NOT LIKE '0' -- odstranění záznamů s id_branch = "NULL", NULL, 0
);

---------------------------
-- DOPLNĚNÍ DOKUMENTACE --
---------------------------
ALTER VIEW `feisty-outlet-436420-a9.l1_all_tables.L1_branch`
SET OPTIONS (
  description = "Dim table that contains information about branches"
);

ALTER VIEW `feisty-outlet-436420-a9.l1_all_tables.L1_branch`
ALTER COLUMN branch_id SET OPTIONS (description = 'PK; Source: L0_branch; Desc: Unique id of branch');

ALTER VIEW `feisty-outlet-436420-a9.l1_all_tables.L1_branch`
ALTER COLUMN branch_name SET OPTIONS (description = 'Source: L0_branch; Desc: Name of branch');

------------
-- TESTY --
------------
-- Tabulka branch: id_branch
-- Test na kontrolu unikátních záznamů primárního klíče branch_id :

SELECT branch_id, COUNT (*) AS cnt
FROM `feisty-outlet-436420-a9.l1_all_tables.L1_branch`
GROUP BY branch_id
HAVING cnt > 1;
-- Výsledek: OK (žádné záznamy)

-- Tabulka branch: id_branch
-- Test na kontrolu null hodnot primárního klíče branch_id:
SELECT *
FROM `feisty-outlet-436420-a9.l1_all_tables.L1_branch`
WHERE branch_id IS NULL;
-- Výsledek: OK (žádné záznamy)

-- Tabulka branch: branch_name
-- Test na kontrolu null hodnot sloupce branch_name:
SELECT *
FROM `feisty-outlet-436420-a9.l1_all_tables.L1_branch`
WHERE branch_name IS NULL;
-- Výsledek: OK (žádné záznamy)

-- Kontroly počtů záznamů L0 vs. L1
SELECT COUNT(*) as cnt_all, 'L1' AS vrstva_L1 FROM `feisty-outlet-436420-a9.l1_all_tables.L1_branch` 
UNION ALL
SELECT COUNT(*) as cnt_all, 'L0' AS vrstva_L0 FROM `feisty-outlet-436420-a9.l0_google_sheet.branch`;
-- Výsledek: L0:6; L1:4; různý počet záznamů, ale to je v pořádku, protože v L1 byly odebrány 2 nevalidní záznamy oproti L0

