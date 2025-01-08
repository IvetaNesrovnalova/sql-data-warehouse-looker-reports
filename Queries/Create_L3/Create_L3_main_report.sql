------------------------------
-- VYTVOŘENÍ HLAVNÍ TABULKY --
------------------------------
CREATE OR REPLACE TABLE `feisty-outlet-436420-a9.l3_all_tables.L3_main_report` AS
(
WITH customers_products_purchases as (
  SELECT
    co.contract_id,
    co.branch_id,
    co.contract_valid_from, 
    co.contract_valid_to,
    co.registration_end_reason,
    co.flag_prolongation,
    co.flag_send_email,
    co.contract_status,
    pp.product_purchase_id,
    pp.product_id,
    pp.product_name,
    pp.product_type,
    pp.product_valid_from,
    pp.product_valid_to,
    MIN(pp.product_valid_from) OVER (PARTITION BY co.contract_id) AS min_product_valid_from, -- minimální product_valid_from pro každý kontrakt (kdy byl nakoupen 1. produkt)
    MAX(pp.product_valid_to) OVER (PARTITION BY co.contract_id) AS max_product_valid_to,     -- maximální product_valid_to pro každý kontrakt (dokdy byl platný poslední produkt)
    pp.price_wo_vat_usd,
    pp.price_w_vat_usd,
    pp.flag_unlimited_product,
FROM `feisty-outlet-436420-a9.l2_all_tables.L2_contract` as co
INNER JOIN `feisty-outlet-436420-a9.l2_all_tables.L2_product_purchase` as pp ON co.contract_id = pp.contract_id -- pouze kontrakty, které mají nějaký záznam v product_purchase
),
clean_valid_from_valid_to as (
  SELECT
    cus.contract_id,
    CASE WHEN cus.contract_valid_from IS NULL AND cus.min_product_valid_from IS NOT NULL
         THEN cus.min_product_valid_from
         ELSE cus.contract_valid_from END
    as contract_valid_from,    -- pokud contract_valid_from ==NULL a pokud máme informaci, kdy byl nakoupen 1. produkt, 
                               -- tj. min_product_valid_from, doplňujeme tuto hodnoty též do hodnoty contract_valid_from místo NULL
    CASE WHEN cus.min_product_valid_from IS NULL AND cus.contract_valid_from IS NOT NULL
         THEN cus.contract_valid_from
         ELSE cus.min_product_valid_from END
    as min_product_valid_from, -- pokud nemáme informaci o začátku platnosti žádného z produktů, doplňujeme jako nákup 1. produktu datum contract_valid_from
    CASE WHEN cus.max_product_valid_to IS NULL AND cus.contract_valid_to IS NOT NULL
         THEN cus.contract_valid_to
         ELSE cus.max_product_valid_to END
    as max_product_valid_to    -- pokud nemáme informaci o konci platnosti žádného z produktů a zároveň máme contract_valid_to, doplňujeme jako konec platnosti produktů contract_valid_to
FROM customers_products_purchases as cus
),
customers_products_purchases_add_basic_metrics as (
SELECT
    DISTINCT
    cu.contract_id,
 -  cu.branch_id,
    cvl.contract_valid_from,
    cu.contract_valid_to,
    DATE_DIFF(cu.contract_valid_to, cu.contract_valid_from, MONTH) AS contract_length_in_months, -- délka trvání kontraktu v měsících
      ( SELECT 
          SUM(inv.amount_wo_vat_usd)
        FROM `feisty-outlet-436420-a9.l2_all_tables.L2_invoice` as inv
        WHERE
          cu.contract_id = inv.contract_id )
    as contract_turnover_wo_vat_usd,      -- obrat na daném kontraktu počítaný ze sumy amount_wo_vat_usd na fakturách (invoice)
    cu.registration_end_reason,
    cu.flag_prolongation,
    cu.flag_send_email,
    cu.contract_status,
    COUNT(DISTINCT cu.product_purchase_id) OVER (PARTITION BY cu.contract_id) as product_purchase_count, -- počet nákupů na daném kontaktu
    cu.product_purchase_id,
    cu.product_id,
    MIN(cu.product_valid_to) OVER (PARTITION BY cu.product_id) AS min_product_template_valid_from, -- odkdy začal platit daný typ produktu (bez vazby na kontrakt a nákup)
    MAX(cu.product_valid_to) OVER (PARTITION BY cu.product_id) AS max_product_template_valid_to,   -- kdy skončila plastnost daného typu produktu (bez vazby na kontrakt a nákup)
    cu.product_name,
    cu.product_type,
    cu.product_valid_from,
    cu.product_valid_to,
    cvl.min_product_valid_from, -- minimální product_valid_from pro každý kontrakt (kdy byl nakoupen 1. produkt)
    cvl.max_product_valid_to,   -- maximální product_valid_to pro každý kontrakt (dokdy byl platný poslední produkt)
    CASE 
     WHEN cvl.max_product_valid_to >= DATE('2035-01-01') 
      THEN 150
    ELSE DATE_DIFF( 
                cvl.max_product_valid_to,
                cvl.min_product_valid_from,
                MONTH
            ) 
    END AS product_purchase_length_in_months, -- délka trvání nakoupených produktů v měsících (od prvního nakoupeného produktu do konce platnosti posledního produktu)
    cu.price_wo_vat_usd,
    cu.price_w_vat_usd,
    cu.flag_unlimited_product,
FROM customers_products_purchases as cu
INNER JOIN clean_valid_from_valid_to as cvl ON cu.contract_id = cvl.contract_id
),
product_purchase_count_turnover_weighted AS (
  SELECT 
    cus.contract_id,
    CASE WHEN cus.contract_turnover_wo_vat_usd > 0 THEN
              ROUND((cus.product_purchase_count / cus.contract_turnover_wo_vat_usd) * 1000,2)
         ELSE NULL END
              AS turnover_weighted_product_purchase_count, -- obratem vážený počet nákupů - vyjadřuje počet nákupů, které musím udělat, abych měl 1 USD
  FROM customers_products_purchases_add_basic_metrics as cus
),
lost_or_existing AS (
  SELECT
    cus.contract_id,
    CASE WHEN cus.contract_valid_to IS NOT NULL AND cus.contract_valid_to < DATE ('2024-10-01')
              OR max_product_valid_to < DATE('2024-07-01')
              THEN "lost"
        ELSE "existing" END 
      as lost_or_existing -- ztracený zákazník (lost) je kontrakt, který má contract_valid_to < 2024-10-01 A/NEBO kontrakt, k němuž existuje product_purchase s MAX(product_valid_to) < 2024-07-01
  FROM customers_products_purchases_add_basic_metrics as cus
),
customers_products_purchases_all_metrics as (
SELECT
    DISTINCT
    cu.contract_id,
    cu.branch_id,
    cu.contract_valid_from,
    cu.contract_valid_to,   
    cu.contract_length_in_months,    -- délka trvání kontraktu v měsících
    cu.registration_end_reason,
    cu.flag_prolongation,
    cu.flag_send_email,
    cu.contract_status,
    cu.contract_turnover_wo_vat_usd, -- obrat na daném kontraktu počítaný ze sumy amount_wo_vat_usd na fakturách (invoice)
    cu.product_purchase_count,       -- počet nákupů na daném kontaktu
    pctw.turnover_weighted_product_purchase_count, -- obratem vážený počet nákupů - vyjadřuje počet nákupů, které musím udělat, abych měl 1 USD
    le.lost_or_existing,             -- ztracený zákazník (lost) nebo existující zákazník
    cu.product_purchase_id,
    cu.product_id,
    cu.min_product_template_valid_from, -- odkdy začal platit daný typ produktu (bez vazby na kontrakt a nákup)
    cu.max_product_template_valid_to,   -- kdy skončila plastnost daného typu produktu (bez vazby na kontrakt a nákup)
    CASE WHEN cu.max_product_template_valid_to < DATE ('2024-10-01')
         THEN true 
         ELSE false END
    as is_product_finished, -- všechny produkty, kterým skončila platnost daného typu produktu (bez vazby na konrakt a nákup) do konce září 24 klasifikujeme jako skončené
    cu.product_name,
    cu.product_type,
    cu.product_valid_from,
    cu.product_valid_to,
    cu.min_product_valid_from, -- minimální product_valid_from pro každý kontrakt (kdy byl nakoupen 1. produkt)
    cu.max_product_valid_to,   -- maximální product_valid_to pro každý kontrakt (dokdy byl platný poslední produkt)
    CASE 
      WHEN cu.product_valid_to = cu.max_product_valid_to THEN true
      ELSE false END
    as is_last_product, -- flag (true/false), zda jde o poslední produkt na daném kontraktu (platnost do = maximální platnost do pro kontrakt)
    cu.product_purchase_length_in_months, -- délka trvání nakoupených produktů v měsících (od prvního nakoupeného produktu do konce platnosti posledního produktu)
    cu.price_wo_vat_usd,
    cu.price_w_vat_usd,
    cu.flag_unlimited_product,
     CASE 
            WHEN cu.contract_length_in_months IS NULL THEN NULL
            WHEN cu.contract_length_in_months <= 3 THEN "a. 0-3 months"
            WHEN cu.contract_length_in_months > 3 AND cu.contract_length_in_months <= 6 THEN "b. 4-6 months"
            WHEN cu.contract_length_in_months > 6 AND cu.contract_length_in_months <= 12 THEN "c. 7-12 months"
            WHEN cu.contract_length_in_months > 12 AND cu.contract_length_in_months <= 24 THEN "d. 1-2 years"
            WHEN cu.contract_length_in_months > 24 AND cu.contract_length_in_months < 150 THEN "e. more than 2 years"
            WHEN cu.contract_length_in_months = 150 THEN "f. unlimited"
            ELSE "g. unkown" END
            as contract_length_in_months_category, -- rozdělení délky trvání kontraktu měsících do kategorií
      CASE 
            WHEN cu.product_purchase_length_in_months IS NULL THEN NULL
            WHEN cu.product_purchase_length_in_months <= 3 THEN "a. 0-3 months"
            WHEN cu.product_purchase_length_in_months > 3 AND cu.product_purchase_length_in_months <= 6 THEN "b. 4-6 months"
            WHEN cu.product_purchase_length_in_months > 6 AND cu.product_purchase_length_in_months <= 12 THEN "c. 7-12 months"
            WHEN cu.product_purchase_length_in_months > 12 AND cu.product_purchase_length_in_months <= 24 THEN "d. 1-2 years"
            WHEN cu.product_purchase_length_in_months > 24 AND cu.product_purchase_length_in_months < 150 THEN "e. more than 2 years"
            WHEN cu.product_purchase_length_in_months = 150 THEN "f. unlimited"
            ELSE "g. unkown" END
            as product_purchase_length_category, -- rozdělení délky trvání nakoupených produktů v měsících do kategorií
        CASE
            WHEN cu.product_purchase_count IS NULL THEN NULL
            WHEN cu.product_purchase_count = 1 THEN "a. 1 product"
            WHEN cu.product_purchase_count > 1 AND cu.product_purchase_count <= 5 THEN "b. 2-5 products"
            WHEN cu.product_purchase_count > 5 AND cu.product_purchase_count <= 10 THEN "c. 6-10 products"
            WHEN cu.product_purchase_count > 10 AND cu.product_purchase_count <= 15 THEN "d. 11-15 products"
            WHEN cu.product_purchase_count > 15 THEN "e. more than 15 products"
            ELSE "f. unknown" END
            as count_product_purchase_category, -- rozdělení počtu nákupů na daném kontaktu do kategorií
        CASE
            WHEN cu.contract_turnover_wo_vat_usd IS NULL THEN NULL
            WHEN cu.contract_turnover_wo_vat_usd = 0 THEN "a. 0.00 usd"
            WHEN cu.contract_turnover_wo_vat_usd > 0 AND cu.contract_turnover_wo_vat_usd <= 4000 THEN "b. 0.01 to 4000.00 usd"
            WHEN cu.contract_turnover_wo_vat_usd > 4000 AND cu.contract_turnover_wo_vat_usd <= 8000 THEN "c. 4000.01 to 8000.00 usd"
            WHEN cu.contract_turnover_wo_vat_usd > 8000 AND cu.contract_turnover_wo_vat_usd <= 12000 THEN "d. 8000.01 to 12000.00 usd"
            WHEN cu.contract_turnover_wo_vat_usd > 12000 AND cu.contract_turnover_wo_vat_usd <= 16000 THEN "e. 12001.00 to 16000.00 usd"
            WHEN cu.contract_turnover_wo_vat_usd > 16000 THEN "f. more than 16001.00 usd"
            ELSE "g. unknown" END
            as contract_turnover_wo_vat_category, -- rozdělení obratu na daném kontraktu do kategorií
        CASE 
            WHEN pctw.turnover_weighted_product_purchase_count IS NULL THEN NULL
            WHEN pctw.turnover_weighted_product_purchase_count > 0 AND pctw.turnover_weighted_product_purchase_count <= 1 THEN "a. financial benefit 0-1 (the best)"
            WHEN pctw.turnover_weighted_product_purchase_count > 1 AND pctw.turnover_weighted_product_purchase_count <= 5 THEN "b. financial benefit 1-5"
            WHEN pctw.turnover_weighted_product_purchase_count > 5 AND pctw.turnover_weighted_product_purchase_count <= 10 THEN "c. financial benefit 5-10"
            WHEN pctw.turnover_weighted_product_purchase_count > 10 AND pctw.turnover_weighted_product_purchase_count <= 50 THEN "d. financial benefit 10-50"
            WHEN pctw.turnover_weighted_product_purchase_count > 50 AND pctw.turnover_weighted_product_purchase_count <= 100 THEN "e. financial benefit 50-100"
            WHEN pctw.turnover_weighted_product_purchase_count > 100 THEN "f. financial benefit > 100 (the worst)"
            ELSE "g. unknown" END
            as turnover_weighted_product_purchase_count_category -- rozdělení obratem váženého počtu nákupů do kategorií
FROM customers_products_purchases_add_basic_metrics as cu
LEFT JOIN product_purchase_count_turnover_weighted as pctw ON cu.contract_id = pctw.contract_id
LEFT JOIN lost_or_existing as le ON cu.contract_id = le.contract_id
),
impact_of_product_cancellation_to_customer AS (
  SELECT
    cu.contract_id,
    CASE WHEN     cu.lost_or_existing = "lost"
              AND cu.is_product_finished = TRUE
              AND cu.is_last_product = TRUE
         THEN "left due to product cancellation"
         WHEN     cu.lost_or_existing = "lost"
              AND cu.is_product_finished = FALSE
              AND cu.is_last_product = TRUE
         THEN "left for another reason"
         ELSE NULL END
    as impact_of_product_cancellation_to_customer -- Kategorizace ztracených zákazníků, zda odešli z důvodu ukončení produktu nebo z jiného důvodu:
                                                  --- Pokud byl posledním nakoupeným produktem na kontraktu produkt, jehož prodej je ukončen, je důvodem odchodu zákazníka zrušení produktu.
                                                  --- Pokud byl posledním nakoupeným produktem na kontraktu produkt, jehož prodej není ukončen, jedná se o jiný odchodu než zrušení produktu.
    FROM customers_products_purchases_all_metrics as cu
),
products_finished_leading_to_customer_left AS (
  SELECT
    cu.contract_id,
    cu.product_purchase_id,
    CASE WHEN     cu.is_product_finished = TRUE
              AND cu.lost_or_existing = "lost"
              AND cu.is_last_product = TRUE
         THEN "leading to customer_left"
         WHEN      cu.is_product_finished = TRUE
              AND cu.is_last_product = FALSE
         THEN "not leading to customer left"
         ELSE NULL END
    as products_finished_leading_to_customer_left -- Kategorizace ukončených produktů, zda ukončení produktu vedlo ke ztrátě zákazníka nebo nevedlo:
                                                  --- Pokud byl skončený produkt posledním produktem u zákazníka, kterého jsme ztratili, jedná se o produkt, jehož skončení vedlo k odchodu zákazníka.
                                                  --- Pokud nebyl skončený produkt posledním produktem u zákazníka, jedná se o produkt, jeho skončení nevedlo k odchodu zákazníka.
    FROM customers_products_purchases_all_metrics as cu
),
customers_products_purchases_all_metrics_with_product_cancellation_impact as (
  SELECT
      DISTINCT
      cu.contract_id,
      cu.branch_id,
      cu.contract_valid_from,
      cu.contract_valid_to,           
      cu.contract_length_in_months,          -- délka trvání kontraktu v měsících
      cu.registration_end_reason,
      cu.flag_prolongation,
      cu.flag_send_email,
      cu.contract_status,
      cu.contract_turnover_wo_vat_usd,       -- obrat na daném kontraktu počítaný ze sumy amount_wo_vat_usd na fakturách (invoice)
      cu.product_purchase_count,             -- počet nákupů na daném kontaktu
      cu.turnover_weighted_product_purchase_count,  -- obratem vážený počet nákupů - vyjadřuje počet nákupů, které musím udělat, abych měl 1 USD
      cu.lost_or_existing,                   -- ztracený zákazník (lost) nebo existující zákazník
      MAX (ic.impact_of_product_cancellation_to_customer) OVER (PARTITION BY cu.contract_id) AS impact_of_product_cancellation_to_customer, 
                                             -- Kategorizace ztracených zákazníků, zda odešli z důvodu ukončení produktu nebo z jiného důvodu
      cu.product_purchase_id,
      cu.product_id,
      cu.min_product_template_valid_from,    -- odkdy začal platit daný typ produktu (bez vazby na kontrakt a nákup)
      cu.max_product_template_valid_to,      -- kdy skončila plastnost daného typu produktu (bez vazby na kontrakt a nákup)
      cu.is_product_finished,                -- všechny produkty, kterým skončila platnost daného typu produktu (bez vazby na konrakt a nákup) do konce září 24 klasifikujeme jako skončené
      pfc.products_finished_leading_to_customer_left,
                                             -- Kategorizace ukončených produktů, zda ukončení produktu vedlo ke ztrátě zákazníka nebo nevedlo
      cu.product_name,
      cu.product_type,
      cu.product_valid_from,
      cu.product_valid_to,
      cu.min_product_valid_from,            -- minimální product_valid_from pro každý kontrakt (kdy byl nakoupen 1. produkt)
      cu.max_product_valid_to,              -- maximální product_valid_to pro každý kontrakt (dokdy byl platný poslední produkt)
      cu.is_last_product,                   -- flag (true/false), zda jde o poslední produkt na daném kontraktu (platnost do = maximální platnost do pro kontrakt)
      cu.product_purchase_length_in_months, -- délka trvání nakoupených produktů v měsících
      cu.price_wo_vat_usd,
      cu.price_w_vat_usd,
      cu.flag_unlimited_product,
      cu.product_purchase_length_category,   -- rozdělení délky trvání nakoupených produktů v měsících do kategorií
      cu.contract_length_in_months_category, -- rozdělení délky trvání kontraktu měsících do kategorií
      cu.count_product_purchase_category,    -- rozdělení počtu nákupů na daném kontaktu do kategorií
      cu.contract_turnover_wo_vat_category,  -- rozdělení obratu na daném kontraktu do kategorií
      cu. turnover_weighted_product_purchase_count_category -- rozdělení obratem váženého počtu nákupů do kategorií
FROM customers_products_purchases_all_metrics AS cu
LEFT JOIN impact_of_product_cancellation_to_customer AS ic ON cu.contract_id = ic.contract_id
LEFT JOIN products_finished_leading_to_customer_left as pfc ON cu.product_purchase_id = pfc.product_purchase_id AND pfc.contract_id=cu.contract_id
)
SELECT *
FROM customers_products_purchases_all_metrics_with_product_cancellation_impact
);

-------------------------------------------------------------
-- VYTVOŘENÍ HLAVNÍ TABULKY ZÁKAZNÍKŮ (BEZ DETAILŮ NÁKUPŮ) --
-------------------------------------------------------------
CREATE OR REPLACE TABLE `feisty-outlet-436420-a9.l3_all_tables.L3_main_report_cu` as (
  SELECT
      DISTINCT
      cu.contract_id,
      cu.branch_id,
      cu.contract_valid_from,
      cu.contract_valid_to,
      cu.contract_length_in_months,      
      cu.registration_end_reason,
      cu.flag_prolongation,
      cu.flag_send_email,
      cu.contract_status,
      cu.contract_turnover_wo_vat_usd,
      cu.product_purchase_count,
      cu.turnover_weighted_product_purchase_count,
      cu.lost_or_existing,
      cu.impact_of_product_cancellation_to_customer,
      cu.min_product_valid_from,
      cu.max_product_valid_to,
      cu.product_purchase_length_in_months, 
      cu.product_purchase_length_category,
      cu.contract_length_in_months_category,
      cu.count_product_purchase_category,
      cu.contract_turnover_wo_vat_category,
      cu.turnover_weighted_product_purchase_count_category
FROM `feisty-outlet-436420-a9.l3_all_tables.L3_main_report` AS cu
);


