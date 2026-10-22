-- Runs every cleaning script in order, filling the clean tables from the raw and reference tables.
-- Run with the sqlite3 command-line tool, not in a database editor (lines starting with a dot are sqlite3 commands).
-- Easiest: double-click load/rebuild_database.bat, which runs load_raw_data.sql first and then this file.
-- Paths are relative to the repo root.
--
-- Order matters: each script fills parent tables before the tables that point to them,
-- so the scripts must run top to bottom. A new cleaning script gets a new .read line below,
-- in its numbered position, and its tables get added to the row counts at the bottom.

.bail on

-- Enforce every foreign key while the clean tables are filled.
-- A row that points at a missing parent stops the run here, instead of loading silently.
PRAGMA foreign_keys = ON;

.print Running 03_clean_financial.sql
.read sql/03_clean_financial.sql
.print Running 04_clean_ref_zip_egrid.sql
.read sql/04_clean_ref_zip_egrid.sql
.print Running 05_clean_ref_residual_mix.sql
.read sql/05_clean_ref_residual_mix.sql
.print Running 06_clean_map_tables.sql
.read sql/06_clean_map_tables.sql
.print Running 07_clean_facility.sql
.read sql/07_clean_facility.sql
.print Running 08_clean_business_drivers_tables.sql
.read sql/08_clean_business_drivers_tables.sql
.print Running 09_clean_fleet_tables.sql
.read sql/09_clean_fleet_tables.sql
.print Running 10_clean_market_instruments.sql
.read sql/10_clean_market_instruments.sql
.print Running 11_clean_fugitive_emissions.sql
.read sql/11_clean_fugitive_emissions.sql
.print Running 12_clean_stationary.sql
.read sql/12_clean_stationary.sql
.print Running 13_clean_utilities.sql
.read sql/13_clean_utilities.sql
.print Running 14_clean_base_year.sql
.read sql/14_clean_base_year.sql

.mode column
.headers on

-- Final check: every row that breaks a foreign key. Expect 0.
SELECT COUNT(*) AS foreign_key_problems FROM pragma_foreign_key_check;

-- Row counts, to compare against docs/loading_raw_data.md
SELECT 'financial' AS table_name, COUNT(*) AS row_count FROM financial
UNION ALL
SELECT 'ref_zip_egrid' AS table_name, COUNT(*) AS row_count FROM ref_zip_egrid
UNION ALL
SELECT 'ref_residual_mix' AS table_name, COUNT(*) AS row_count FROM ref_residual_mix
UNION ALL
SELECT 'map_calendar_day' AS table_name, COUNT(*) AS row_count FROM map_calendar_day
UNION ALL
SELECT 'map_fuel_product' AS table_name, COUNT(*) AS row_count FROM map_fuel_product
UNION ALL
SELECT 'map_vehicle_class' AS table_name, COUNT(*) AS row_count FROM map_vehicle_class
UNION ALL
SELECT 'map_activity_type' AS table_name, COUNT(*) AS row_count FROM map_activity_type
UNION ALL
SELECT 'map_weather_station' AS table_name, COUNT(*) AS row_count FROM map_weather_station
UNION ALL
SELECT 'facility' AS table_name, COUNT(*) AS row_count FROM facility
UNION ALL
SELECT 'weather_degree_days' AS table_name, COUNT(*) AS row_count FROM weather_degree_days
UNION ALL
SELECT 'operation_kpi' AS table_name, COUNT(*) AS row_count FROM operation_kpi
UNION ALL
SELECT 'vehicle' AS table_name, COUNT(*) AS row_count FROM vehicle
UNION ALL
SELECT 'fuel_card_assignment' AS table_name, COUNT(*) AS row_count FROM fuel_card_assignment
UNION ALL
SELECT 'fuel_card_transaction' AS table_name, COUNT(*) AS row_count FROM fuel_card_transaction
UNION ALL
SELECT 'mileage_claim' AS table_name, COUNT(*) AS row_count FROM mileage_claim
UNION ALL
SELECT 'telematics_mileage' AS table_name, COUNT(*) AS row_count FROM telematics_mileage
UNION ALL
SELECT 'rec_retirement' AS table_name, COUNT(*) AS row_count FROM rec_retirement
UNION ALL
SELECT 'supplier_emission_rate' AS table_name, COUNT(*) AS row_count FROM supplier_emission_rate
UNION ALL
SELECT 'refrigeration_equipment' AS table_name, COUNT(*) AS row_count FROM refrigeration_equipment
UNION ALL
SELECT 'arcticair_log' AS table_name, COUNT(*) AS row_count FROM arcticair_log
UNION ALL
SELECT 'polar_log' AS table_name, COUNT(*) AS row_count FROM polar_log
UNION ALL
SELECT 'generator_log' AS table_name, COUNT(*) AS row_count FROM generator_log
UNION ALL
SELECT 'propane_delivery' AS table_name, COUNT(*) AS row_count FROM propane_delivery
UNION ALL
SELECT 'map_utility' AS table_name, COUNT(*) AS row_count FROM map_utility
UNION ALL
SELECT 'energyhub_consumption' AS table_name, COUNT(*) AS row_count FROM energyhub_consumption
UNION ALL
SELECT 'mesa_gas_bill' AS table_name, COUNT(*) AS row_count FROM mesa_gas_bill
UNION ALL
SELECT 'chi_midwest_invoice' AS table_name, COUNT(*) AS row_count FROM chi_midwest_invoice
UNION ALL
SELECT 'slc_utility_bill' AS table_name, COUNT(*) AS row_count FROM slc_utility_bill
UNION ALL
SELECT 'utilitypay_bill' AS table_name, COUNT(*) AS row_count FROM utilitypay_bill
UNION ALL
SELECT 'valley_consumption' AS table_name, COUNT(*) AS row_count FROM valley_consumption
UNION ALL
SELECT 'base_year_activity' AS table_name, COUNT(*) AS row_count FROM base_year_activity
UNION ALL
SELECT 'base_year_inventory' AS table_name, COUNT(*) AS row_count FROM base_year_inventory;
