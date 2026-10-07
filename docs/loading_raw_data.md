# Loading the Raw Data

The raw layer of the database is rebuilt from scratch by one script. It creates every `raw_` table, then loads each CSV in `data/` exactly as received, with every column stored as TEXT. All type conversion and cleaning happens later, in the numbered scripts in `sql/`.

## Before you start

1. **Install the SQLite command-line tool.** Download the `sqlite-tools-win-x64` zip from the [SQLite download page](https://www.sqlite.org/download.html) ("Precompiled Binaries for Windows") and unzip it anywhere on your computer. It doesn't need to be inside this repo.
2. **Point the batch file at it.** Open `load/rebuild_database.bat` in a text editor and set the `SQLITE` line to the full path of `sqlite3.exe`, for example:

   ```
   set SQLITE="C:\Tools\sqlite\sqlite3.exe"
   ```

## Rebuilding the database

1. **Close any program that has the database open** (for example DBeaver, DB Browser for SQLite or Power BI). Database tools lock the file while it's open.
2. **Double-click `load/rebuild_database.bat`.**
3. A window opens, runs the load, and prints a row count for every table. Compare them with the table below, then press any key to close the window.

That's it. The process is safe to repeat at any time: each run drops and recreates the tables first, so no data is ever loaded twice.

## What the script does

`rebuild_database.bat` moves to the repo root and runs `load/load_raw_data.sql` with sqlite3. That file:

1. Turns on `.bail on`, so the run stops at the first error instead of continuing with incomplete data.
2. Runs `sql/01_create_raw_tables.sql`, which drops and recreates every `raw_` table, empty and all TEXT.
3. Loads each CSV into its table with `.import --csv --skip 1`. The `--skip 1` skips the header row, because the tables already have their column names.
4. Prints the row count of every table.

Each table is named `raw_` plus the CSV file name, for example `facility_register.csv` loads into `raw_facility_register`.

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

## Troubleshooting

| Message or symptom | Likely cause | Fix |
| --- | --- | --- |
| `is not recognized` / `cannot find the path` | The `SQLITE` path in the batch file is wrong | Copy the path again (Shift + right-click `sqlite3.exe`, Copy as path) |
| `database is locked` | Another program has the database open | Close any database tool using the file and run again |
| `cannot open "data/..."` | A file was moved or renamed | Check the path on that `.import` line matches the file |
| `no such table` | A table name in `load_raw_data.sql` doesn't match `01_create_raw_tables.sql` | Make the two names match |
| A row count differs from the table above | The source file changed, or the wrong number of lines was skipped | Open the CSV in a text editor and compare |

## Adding a new file

1. Add a `CREATE TABLE` for it (all columns TEXT) to `sql/01_create_raw_tables.sql`.
2. Add an `.import` line for it to `load/load_raw_data.sql`, and add it to the row count query at the bottom.
3. Run `rebuild_database.bat` and add the new table's row count to the table above.
