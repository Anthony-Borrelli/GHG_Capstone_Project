# Rebuilding the Database

The whole database is rebuilt from scratch in one double-click, in two steps:

1. **Load** (`load/load_raw_data.sql`): creates every table, then loads each source CSV in `data/` exactly as received, with every column stored as TEXT, and loads the reference files in `data/reference/factors/`.
2. **Clean** (`load/clean_data.sql`): runs the numbered cleaning scripts in `sql/` in order, filling the clean tables from the raw ones with foreign keys enforced.

Rebuilding from the top is the reliable way to rerun anything. Rerunning one cleaning script on its own, on a database that's already full, can be blocked by foreign keys from tables filled by later scripts.

## Before you start

1. **Install the SQLite command-line tool.** Download the `sqlite-tools-win-x64` zip from the [SQLite download page](https://www.sqlite.org/download.html) ("Precompiled Binaries for Windows") and unzip it anywhere on your computer. It doesn't need to be inside this repo.
2. **Point the batch file at it.** Open `load/rebuild_database.bat` in a text editor and set the `SQLITE` line to the full path of `sqlite3.exe`, for example:

   ```
   set SQLITE="C:\Tools\sqlite\sqlite3.exe"
   ```

## Rebuilding the database

1. **Close any program that has the database open** (for example DBeaver, DB Browser for SQLite or Power BI). Database tools lock the file while it's open.
2. **Double-click `load/rebuild_database.bat`.**
3. A window opens and runs both steps. Each step prints a row count for every table it filled. Compare them with the tables below, then press any key to close the window.

If something fails, the run stops and prints `STOPPED`. In step 2, the last `Running ...` line names the cleaning script that failed, and the error message gives the line number.

That's it. The process is safe to repeat at any time: each run drops and recreates the tables first, so no data is ever loaded twice.

## What step 1 does (load)

`rebuild_database.bat` moves to the repo root and runs `load/load_raw_data.sql` with sqlite3. That file:

1. Turns on `.bail on`, so the run stops at the first error instead of continuing with incomplete data.
2. Runs `sql/01a_create_raw_tables.sql`, which drops and recreates every `raw_` table for the source data, empty and all TEXT.
3. Runs `sql/01b_create_raw_ref_tables.sql`, which drops and recreates the raw reference tables, empty and all TEXT.
4. Runs `sql/02_create_clean_tables.sql`, which drops and recreates every clean table, including the typed `ref_` tables.
5. Loads each source CSV into its `raw_` table with `.import --csv --skip 1`. The `--skip 1` skips the header row, because the tables already have their column names.
6. Loads the reference files:
   - Files that still need cleaning (`power_profiler_zipcode_tool.csv`, `green_e_residual_mix_emission_rates_2025.csv`) go into raw reference tables. A later script cleans them into `ref_zip_egrid` and `ref_residual_mix`.
   - Files that are already clean (`ref_*.csv`) go straight into the `ref_` table with the same name. Their numbers convert to REAL on import.
7. Prints the row count of every table.

Each raw table is named `raw_` plus the CSV file name, for example `facility_register.csv` loads into `raw_facility_register`. Each clean reference file is named after its table, for example `ref_gwp.csv` loads into `ref_gwp`.

## What step 2 does (clean)

If step 1 succeeds, the batch file runs `load/clean_data.sql`. That file:

1. Turns on `.bail on`, so the run stops at the first error.
2. Turns on `PRAGMA foreign_keys = ON`, so any row that points at a missing parent (an account not in `map_utility`, a unit not in `vehicle`) stops the run instead of loading silently.
3. Runs each script in `sql/` with `.read`, from `03_clean_financial.sql` upward: the cleaning scripts (03 to 14), then the merged tables (15), the activity tables (16), the estimates (17), the emissions views (18) and the results views (19). The order matters: parent tables are filled before the tables that point to them.
4. Prints the number of foreign key problems (expect 0) and the row count of every clean table.

Inside each cleaning script, the `INSERT`s run parent first and the `DELETE`s at the top run child first, the same order as the `CREATE` and `DROP` sections of `02_create_clean_tables.sql`.

> `load/load_raw_data.sql` contains sqlite3 commands (the lines starting with a dot), so it only runs with the sqlite3 command-line tool, not in a database editor. Every file in `sql/` is plain SQLite SQL and runs in any SQLite tool.

## Files that need special handling

| File | Issue | How it's handled |
| --- | --- | --- |
| `utilities/energyhub_consumption_export.csv` | 4 lines of report text above the column header | Loaded with `--skip 5` (4 report lines plus the header). If a future export has a different number of report lines, change that number. Any non-data rows that remain are filtered out in the cleaning step, not deleted here. |

Loading through sqlite3 also keeps every value exactly as it appears in the file. Leading zeros in account numbers and meter reads are preserved, which import wizards in database tools can strip by guessing a column is numeric.

## Expected row counts

| Table | Rows |
| --- | --- |
| raw_company_financials | 2 |
| raw_operations_monthly_kpis_2024_2025 | 438 |
| raw_weather_degree_days_2024_2025 | 432 |
| raw_facility_register | 20 |
| raw_fuel_card_assignments | 242 |
| raw_fuel_card_transactions_2025 | 42,039 |
| raw_leased_vehicle_mileage_claims_2025 | 60 |
| raw_telematics_monthly_mileage_2024_2025 | 5,564 |
| raw_vehicle_register | 241 |
| raw_rec_retirements_2025 | 4 |
| raw_supplier_specific_emission_rates | 3 |
| raw_arcticair_refrigeration_service_log_2025 | 135 |
| raw_polar_mechanical_service_log_2025 | 206 |
| raw_refrigeration_equipment_inventory | 89 |
| raw_emergency_generator_fuel_log_2025 | 54 |
| raw_propane_deliveries_2025 | 186 |
| raw_energyhub_consumption_export | 94 |
| raw_mesa_gas_billing_history | 42 |
| raw_midwest_gas_marketing_supply_invoices_chicago | 12 |
| raw_slc_seller_utility_bills_jan_jun_2025 | 12 |
| raw_utility_account_map | 36 |
| raw_utilitypay_bill_export_2025 | 773 |
| raw_valley_mud_annual_usage_statement_2025 | 1 |
| raw_activity_2024_clean | 732 |
| raw_inventory_2024_results | 121 |
| raw_power_profiler_zipcode_tool | 41,588 |
| raw_green_e_residual_mix_emission_rates_2025 | 27 |
| ref_gwp | 9 |
| ref_stationary_factor | 2 |
| ref_mobile_co2 | 3 |
| ref_mobile_ch4_n2o_onroad | 18 |
| ref_mobile_ch4_n2o_nonroad | 2 |
| ref_egrid_rate | 27 |
| ref_building_intensity | 1 |
| ref_unit_conversion | 13 |

## Expected clean row counts (step 2)

| Table | Rows | Note |
| --- | --- | --- |
| financial | 2 | |
| ref_zip_egrid | 41,588 | |
| ref_residual_mix | 27 | |
| map_calendar_day | 365 | |
| map_fuel_product | 18 | |
| map_vehicle_class | 4 | |
| map_activity_type | 8 | |
| map_weather_station | 18 | |
| facility | 19 | duplicate DC-PHX record removed |
| weather_degree_days | 432 | |
| operation_kpi | 438 | |
| vehicle | 241 | |
| fuel_card_assignment | 242 | |
| fuel_card_transaction | 41,777 | 250 duplicates and 12 transactions dated 2024 removed |
| mileage_claim | 60 | |
| telematics_mileage | 5,564 | |
| rec_retirement | 4 | |
| supplier_emission_rate | 3 | |
| refrigeration_equipment | 89 | |
| arcticair_log | 135 | |
| polar_log | 192 | 14 service events dated 2024 removed |
| generator_log | 54 | |
| propane_delivery | 186 | |
| map_utility | 37 | 36 from the account map, plus the Dallas dock expansion meter |
| energyhub_consumption | 93 | TOTAL row removed |
| mesa_gas_bill | 42 | |
| chi_midwest_invoice | 12 | |
| slc_utility_bill | 12 | |
| utilitypay_bill | 348 | 9 duplicates and 416 water and sewer rows removed |
| valley_consumption | 12 | one row per month |
| base_year_activity | 732 | blanks stored as NULL; "(estimated)" removed from units |
| base_year_inventory | 121 | blanks stored as NULL |
| refrigerant_service | 327 | Polar (192) and ArcticAir (135) stacked; ArcticAir converted from kg to lb |
| utility_bill | 491 | UtilityPay (344, cancelled bills removed), EnergyHub (93), Mesa (42), Valley (12); all in kWh or MMBtu |
| fleet_activity | 4,556 | one row per vehicle, month and fuel type: fuel cards (4,496) with telematics miles on on-road rows, plus leased car mileage claims (60, gallons = miles / rated MPG). Propane forklifts have no unit number and load into inventory_activity_data instead |
| inventory_activity_data | 5,233 | one table for every source: utilities (403, prorated by day, 2025 days only), fleet (4,556, one row per vehicle-month), propane (99), generators (14, annual rows with month NULL), refrigerants (134, by facility, month and gas; service events with no emissions dropped), plus 27 estimated rows from script 17 (DC-ATL bill gap 3, SO-BOS floor-area estimate 24) with is_estimated = 1 |
| emissions (view) | 5,233 | one row per inventory_activity_data row with co2_t, ch4_t, n2o_t, hfc_co2e_t, location_based_tco2e and memo_hcfc_co2e_t in metric tonnes. A view stores no data: it recalculates from the tables each time it is queried, and script 18 drops and recreates it on every rebuild |
| scope2_market (view) | 19 | one row per facility for the year: electricity MWh, MWh covered by 2025-vintage RECs (capped at the facility's use) and the Sacramento green tariff, uncovered MWh, and market-based tCO2e (supplier-specific rate where published, otherwise Green-e residual mix CO2, with eGRID CH4 and N2O). Also created by script 18 |
| facility_totals (view) | 19 | one row per facility: Scope 1, Scope 2 location-based and Scope 2 market-based tCO2e. Created by script 19 |
| company_summary (view) | 8 | 2025 and 2024 location- and market-based tCO2e by scope and source category (2024 from base_year_inventory). Created by script 19 |

## Troubleshooting

| Message or symptom | Likely cause | Fix |
| --- | --- | --- |
| `is not recognized` / `cannot find the path` | The `SQLITE` path in the batch file is wrong | Copy the path again (Shift + right-click `sqlite3.exe`, Copy as path) |
| `database is locked` | Another program has the database open | Close any database tool using the file and run again |
| `cannot open "data/..."` | A file was moved or renamed | Check the path on that `.import` line matches the file |
| `no such table` | A table name in `load_raw_data.sql` doesn't match its `CREATE TABLE` script | Make the two names match |
| `expected N columns but found M` | A CSV's columns don't match its table | Compare the CSV header with the `CREATE TABLE` columns |
| `FOREIGN KEY constraint failed` in step 2 | A row points at a parent that doesn't exist, or a parent table is filled after its child | Check the script named on the last `Running ...` line; use a `LEFT JOIN ... IS NULL` query to find the unmatched values |
| A row count differs from the table above | The source file changed, or the wrong number of lines was skipped | Open the CSV in a text editor and compare |

## Adding a new file

1. Add a `CREATE TABLE` for it (all columns TEXT) to `sql/01a_create_raw_tables.sql`, or to `sql/01b_create_raw_ref_tables.sql` for a reference file that needs cleaning. A reference file that is already clean needs no raw table: name it after its `ref_` table and import it straight into that.
2. Add an `.import` line for it to `load/load_raw_data.sql`, and add it to the row count query at the bottom.
3. Run `rebuild_database.bat` and add the new table's row count to the table above.

## Adding a new cleaning script

1. Save it in `sql/` with the next number, for example `20_...sql`.
2. Add a `.print` and a `.read` line for it to `load/clean_data.sql`, in its numbered position.
3. Add its tables to the row count query at the bottom of `load/clean_data.sql`, and their counts to the clean row count table above.
