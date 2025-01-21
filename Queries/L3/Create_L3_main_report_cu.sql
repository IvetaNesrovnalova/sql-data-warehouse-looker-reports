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
