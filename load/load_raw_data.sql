-- Rebuilds the raw and reference layers of the database from the CSV files in data/.
-- Run with the sqlite3 command-line tool, not in a database editor (lines starting with a dot are sqlite3 commands).
-- Easiest: double-click load/rebuild_database.bat, which runs this from the repo root.
-- Paths are relative to the repo root.
--
-- Order matters: tables are created first (steps 1 to 3), then filled (steps 4 to 6).
-- Step 3 drops and recreates every clean table, including the ref_ tables,
-- so rerun the cleaning scripts in sql/ after a rebuild.

.bail on

-- 1. Drop and recreate every raw table (empty, all TEXT)
.read sql/01a_create_raw_tables.sql

-- 2. Drop and recreate the raw reference tables (empty, all TEXT)
.read sql/01b_create_raw_ref_tables.sql

-- 3. Drop and recreate every clean table, including the ref_ tables (empty, typed)
.read sql/02_create_clean_tables.sql

-- 4. Load the source data. --skip 1 skips the header row, because the tables already have column names.
.import --csv --skip 1 data/raw_2025/business_drivers/company_financials.csv raw_company_financials
.import --csv --skip 1 data/raw_2025/business_drivers/operations_monthly_kpis_2024_2025.csv raw_operations_monthly_kpis_2024_2025
.import --csv --skip 1 data/raw_2025/business_drivers/weather_degree_days_2024_2025.csv raw_weather_degree_days_2024_2025
.import --csv --skip 1 data/raw_2025/facilities/facility_register.csv raw_facility_register
.import --csv --skip 1 data/raw_2025/fleet/fuel_card_assignments.csv raw_fuel_card_assignments
.import --csv --skip 1 data/raw_2025/fleet/fuel_card_transactions_2025.csv raw_fuel_card_transactions_2025
.import --csv --skip 1 data/raw_2025/fleet/leased_vehicle_mileage_claims_2025.csv raw_leased_vehicle_mileage_claims_2025
.import --csv --skip 1 data/raw_2025/fleet/telematics_monthly_mileage_2024_2025.csv raw_telematics_monthly_mileage_2024_2025
.import --csv --skip 1 data/raw_2025/fleet/vehicle_register.csv raw_vehicle_register
.import --csv --skip 1 data/raw_2025/market_instruments/rec_retirements_2025.csv raw_rec_retirements_2025
.import --csv --skip 1 data/raw_2025/market_instruments/supplier_specific_emission_rates.csv raw_supplier_specific_emission_rates
.import --csv --skip 1 data/raw_2025/refrigerants/arcticair_refrigeration_service_log_2025.csv raw_arcticair_refrigeration_service_log_2025
.import --csv --skip 1 data/raw_2025/refrigerants/polar_mechanical_service_log_2025.csv raw_polar_mechanical_service_log_2025
.import --csv --skip 1 data/raw_2025/refrigerants/refrigeration_equipment_inventory.csv raw_refrigeration_equipment_inventory
.import --csv --skip 1 data/raw_2025/stationary/emergency_generator_fuel_log_2025.csv raw_emergency_generator_fuel_log_2025
.import --csv --skip 1 data/raw_2025/stationary/propane_deliveries_2025.csv raw_propane_deliveries_2025
-- EnergyHub: 4 report lines above the header, so skip 5
.import --csv --skip 5 data/raw_2025/utilities/energyhub_consumption_export.csv raw_energyhub_consumption_export
.import --csv --skip 1 data/raw_2025/utilities/mesa_gas_billing_history.csv raw_mesa_gas_billing_history
.import --csv --skip 1 data/raw_2025/utilities/midwest_gas_marketing_supply_invoices_chicago.csv raw_midwest_gas_marketing_supply_invoices_chicago
.import --csv --skip 1 data/raw_2025/utilities/slc_seller_utility_bills_jan_jun_2025.csv raw_slc_seller_utility_bills_jan_jun_2025
.import --csv --skip 1 data/raw_2025/utilities/utility_account_map.csv raw_utility_account_map
.import --csv --skip 1 data/raw_2025/utilities/utilitypay_bill_export_2025.csv raw_utilitypay_bill_export_2025
.import --csv --skip 1 data/raw_2025/utilities/valley_mud_annual_usage_statement_2025.csv raw_valley_mud_annual_usage_statement_2025
.import --csv --skip 1 data/base_year_2024/activity_2024_clean.csv raw_activity_2024_clean
.import --csv --skip 1 data/base_year_2024/inventory_2024_results.csv raw_inventory_2024_results

-- 5. Load the raw reference files (cleaned into ref_zip_egrid and ref_residual_mix by a later script)
.import --csv --skip 1 data/reference/factors/power_profiler_zipcode_tool.csv raw_power_profiler_zipcode_tool
.import --csv --skip 1 data/reference/factors/green_e_residual_mix_emission_rates_2025.csv raw_green_e_residual_mix_emission_rates_2025

-- 6. Load the clean reference files straight into their ref_ tables (numbers convert to REAL on import)
.import --csv --skip 1 data/reference/factors/ref_gwp.csv ref_gwp
.import --csv --skip 1 data/reference/factors/ref_stationary_factor.csv ref_stationary_factor
.import --csv --skip 1 data/reference/factors/ref_mobile_co2.csv ref_mobile_co2
.import --csv --skip 1 data/reference/factors/ref_mobile_ch4_n2o_onroad.csv ref_mobile_ch4_n2o_onroad
.import --csv --skip 1 data/reference/factors/ref_mobile_ch4_n2o_nonroad.csv ref_mobile_ch4_n2o_nonroad
.import --csv --skip 1 data/reference/factors/ref_egrid_rate.csv ref_egrid_rate
.import --csv --skip 1 data/reference/factors/ref_building_intensity.csv ref_building_intensity
.import --csv --skip 1 data/reference/factors/ref_unit_conversion.csv ref_unit_conversion

-- 7. Row counts, to compare against docs/loading_raw_data.md
.mode column
.headers on
SELECT 'raw_company_financials' AS table_name, COUNT(*) AS row_count FROM raw_company_financials
UNION ALL
SELECT 'raw_operations_monthly_kpis_2024_2025' AS table_name, COUNT(*) AS row_count FROM raw_operations_monthly_kpis_2024_2025
UNION ALL
SELECT 'raw_weather_degree_days_2024_2025' AS table_name, COUNT(*) AS row_count FROM raw_weather_degree_days_2024_2025
UNION ALL
SELECT 'raw_facility_register' AS table_name, COUNT(*) AS row_count FROM raw_facility_register
UNION ALL
SELECT 'raw_fuel_card_assignments' AS table_name, COUNT(*) AS row_count FROM raw_fuel_card_assignments
UNION ALL
SELECT 'raw_fuel_card_transactions_2025' AS table_name, COUNT(*) AS row_count FROM raw_fuel_card_transactions_2025
UNION ALL
SELECT 'raw_leased_vehicle_mileage_claims_2025' AS table_name, COUNT(*) AS row_count FROM raw_leased_vehicle_mileage_claims_2025
UNION ALL
SELECT 'raw_telematics_monthly_mileage_2024_2025' AS table_name, COUNT(*) AS row_count FROM raw_telematics_monthly_mileage_2024_2025
UNION ALL
SELECT 'raw_vehicle_register' AS table_name, COUNT(*) AS row_count FROM raw_vehicle_register
UNION ALL
SELECT 'raw_rec_retirements_2025' AS table_name, COUNT(*) AS row_count FROM raw_rec_retirements_2025
UNION ALL
SELECT 'raw_supplier_specific_emission_rates' AS table_name, COUNT(*) AS row_count FROM raw_supplier_specific_emission_rates
UNION ALL
SELECT 'raw_arcticair_refrigeration_service_log_2025' AS table_name, COUNT(*) AS row_count FROM raw_arcticair_refrigeration_service_log_2025
UNION ALL
SELECT 'raw_polar_mechanical_service_log_2025' AS table_name, COUNT(*) AS row_count FROM raw_polar_mechanical_service_log_2025
UNION ALL
SELECT 'raw_refrigeration_equipment_inventory' AS table_name, COUNT(*) AS row_count FROM raw_refrigeration_equipment_inventory
UNION ALL
SELECT 'raw_emergency_generator_fuel_log_2025' AS table_name, COUNT(*) AS row_count FROM raw_emergency_generator_fuel_log_2025
UNION ALL
SELECT 'raw_propane_deliveries_2025' AS table_name, COUNT(*) AS row_count FROM raw_propane_deliveries_2025
UNION ALL
SELECT 'raw_energyhub_consumption_export' AS table_name, COUNT(*) AS row_count FROM raw_energyhub_consumption_export
UNION ALL
SELECT 'raw_mesa_gas_billing_history' AS table_name, COUNT(*) AS row_count FROM raw_mesa_gas_billing_history
UNION ALL
SELECT 'raw_midwest_gas_marketing_supply_invoices_chicago' AS table_name, COUNT(*) AS row_count FROM raw_midwest_gas_marketing_supply_invoices_chicago
UNION ALL
SELECT 'raw_slc_seller_utility_bills_jan_jun_2025' AS table_name, COUNT(*) AS row_count FROM raw_slc_seller_utility_bills_jan_jun_2025
UNION ALL
SELECT 'raw_utility_account_map' AS table_name, COUNT(*) AS row_count FROM raw_utility_account_map
UNION ALL
SELECT 'raw_utilitypay_bill_export_2025' AS table_name, COUNT(*) AS row_count FROM raw_utilitypay_bill_export_2025
UNION ALL
SELECT 'raw_valley_mud_annual_usage_statement_2025' AS table_name, COUNT(*) AS row_count FROM raw_valley_mud_annual_usage_statement_2025
UNION ALL
SELECT 'raw_activity_2024_clean' AS table_name, COUNT(*) AS row_count FROM raw_activity_2024_clean
UNION ALL
SELECT 'raw_inventory_2024_results' AS table_name, COUNT(*) AS row_count FROM raw_inventory_2024_results
UNION ALL
SELECT 'raw_power_profiler_zipcode_tool' AS table_name, COUNT(*) AS row_count FROM raw_power_profiler_zipcode_tool
UNION ALL
SELECT 'raw_green_e_residual_mix_emission_rates_2025' AS table_name, COUNT(*) AS row_count FROM raw_green_e_residual_mix_emission_rates_2025
UNION ALL
SELECT 'ref_gwp' AS table_name, COUNT(*) AS row_count FROM ref_gwp
UNION ALL
SELECT 'ref_stationary_factor' AS table_name, COUNT(*) AS row_count FROM ref_stationary_factor
UNION ALL
SELECT 'ref_mobile_co2' AS table_name, COUNT(*) AS row_count FROM ref_mobile_co2
UNION ALL
SELECT 'ref_mobile_ch4_n2o_onroad' AS table_name, COUNT(*) AS row_count FROM ref_mobile_ch4_n2o_onroad
UNION ALL
SELECT 'ref_mobile_ch4_n2o_nonroad' AS table_name, COUNT(*) AS row_count FROM ref_mobile_ch4_n2o_nonroad
UNION ALL
SELECT 'ref_egrid_rate' AS table_name, COUNT(*) AS row_count FROM ref_egrid_rate
UNION ALL
SELECT 'ref_building_intensity' AS table_name, COUNT(*) AS row_count FROM ref_building_intensity
UNION ALL
SELECT 'ref_unit_conversion' AS table_name, COUNT(*) AS row_count FROM ref_unit_conversion;
