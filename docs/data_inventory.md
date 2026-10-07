## raw_arcticair_refrigeration_service_log_2025
- **Source:** likely operations team or accounts payable
- **Grain:** each row is a work order for one unit
- **Rows:** 135, matches rawdata
- **Key columns:** asset_tag = refrigeration_equipment_inventory.equipment_id
- **Quantities and units:** refrigerant type and quantity used in kg. CAST qty_charged & recovered as REAL
- **Dates:** YYYY-MM-DD, spans 2025-01-01 to 2025-12-21
- **Links to:** refrigeration_equipment_inventory.equipment_id
- **Issues noticed:** gas_type inconsistent formating (R404A, R-404A, 404A, 410a), also includes HFC so cant make blanket format, Solstice N40 rather than R-448A. Use fugitive emissions reference source to determine formatting. Confirmed where qty_charged = 0 tech notes state no leak/refrigerant added. 

## raw_company_financials
- **Source:** Finance
- **Grain:** one fiscal years net revenue and full time equivalent employee count
- **Rows:** 2, matches
- **Key columns:** net_revenue..., employees_fte
- **Quantities and units:** cast net_revenue..., employees_fte as REAL
- **Dates:** YYYY
- **Links to:** none
- **Issues noticed:** none

## raw_emergency_generator_fuel_log_2025
- **Source:** Ops
- **Grain:** each row is either a tank reading or a fuel delivery for each facility. one reading beginning of year one reading end of year. total fuel used can be calculated using start, end, and deliveries.
- **Rows:** 54
- **Key columns:** facility_id 
- **Quantities and units:** CAST value as REAL, tank_capcity_gal as REAL, value is both gal and % full - use tank capacity to calc actual_gal, then calc total fuel used.
- **Dates:** YYYY-MM-DD
- **Links to:** facility_register
- **Issues noticed:** none
- **Initial analysis:** 14 unique facilities, but 13 unique facilities when joined with facility_reg, I had initially thought they were all distribution centers. turns out 13 distribution centers + HQ location.

## raw_energyhub_consumption_export
- **Source:** Utility providers, Fiance
- **Grain:** each row is a month of utility for each meter, mutltiple meters for some locations.
- **Rows:** 94
- **Key columns:** Meter - connects to utility_account_map
- **Quantities and units:** consumption AS REAL, cost AS REAL. all MWh
- **Dates:** YYYY-MM-DD
- **Links to:** utility_account_map
- **Issues noticed:** column names not snake_case, 
- **Initial analysis:** 7 unique locations out of 19 from facility_register. will need to ensure other locations electricity is covered by other bills. Dallas and Chicago have 2 different meters. Dallas is because of their doc replacement in April.

## raw_facility_register
- **Source:** Accounting
- **Grain:** each row represents a facility + its information based on when the record was updated. This means potential duplicates can appear as old records are not replaced with new updates. Most up-to-date record, record_updated, should be referenced only to get 19 unique facilities as of EOY 2025.
- **Rows:** 20
- **Key columns:** facility_id
- **Quantities and units:** sqft as INT
- **Dates:** date()
- **Links to:** primary key
- **Issues noticed:** DC-PHX duplicate, state formatting UPPER WASH., TEXAS, zip not 5 digits lost leading 0, sqft replace , with " ", uniform both dates to date() format.
- **Initial analysis:** none

## raw_fuel_card_assignments
- **Source:** Finance
- **Grain:** each row represents the active card in use from the date it was assigned to the date it was closed
- **Rows:** 242, 236 unique card numbers
- **Key columns:** card_number
- **Quantities and units:** card and unit number AS INT
- **Dates:** date() format
- **Links to:** fuel_card_transactions, vehicle_register, 
- **Issues noticed:** none
- **Initial analysis:** card_number and unit_number are not always the same across time. once cards get closed they get assigned a new unit number. this means only active cards should be looked at similar to facility_register to know which card in current with which unit number. ex. Unit 4228 & 4229 swap based on timing closed and reopened.

## raw_fuel_card_transasctions_2025
- **Source:** finance
- **Grain:** each row represents a card transaction by date and time
- **Rows:**
- **Key columns:** transaction ID, card number, unit number, 
- **Quantities and units:** quantity, unit price, gross amount AS REAL. transaction ID, card number, unit number odometer AS INT
- **Dates:** date() format, time is seperate.
- **Links to:** fuel_card_assignments, vehicle_register
- **Issues noticed:** columns to snake_case, 
- **Initial analysis:** Units of measure are not consistent, will need conversions from references. product description is not consistent - will need to format. %X%. 18 different types of product, not all is fuel.

## raw_leased_vehicle_mileage_claims_2025
- **Source:** Finance
- **Grain:** each row represents monthly employee expense reports by date. ID's submit multiple reports
- **Rows:** 
- **Key columns:** employee ID, leased vehicle unit
- **Quantities and units:** Leased vehicle unit as INT, business miles claimed as INT, reimbursement rate as INT
- **Dates:** YYYY-MM
- **Links to:** vehicle_register
- **Issues noticed:** snake_case columns, date format
- **Initial analysis:**

## raw_mesa_gas_billing_history
- **Source:** Finance
- **Grain:** each row represents a monthly utility bill. same ID multiple times.
- **Rows:**
- **Key columns:** customer #, Premise
- **Quantities and units:** customer # as INT, prev read curr read therm mult amount as REAL
- **Dates:** MM-DD-YYYY, need to reformat
- **Links to:** facility_register
- **Issues noticed:** snake_case columns, date format, Premise will need to be substr'd to seperate address from facility_register.
- **Initial analysis:** facility id to be joined from other tables

## raw_midwest_gas_marketing_supply_invoices_chicago
- **Source:** finance
- **Grain:** each row reprents a unique month of utility bills
- **Rows:**
- **Key columns:** Customer for facility_id
- **Quantities and units:** nominated volume, commodity price AS REAL
- **Dates:** listed as month year text, should convert
- **Links to:** facility id
- **Issues noticed:** customer need substr to get city to get facility ID, snake_case columns, date
- **Initial analysis:** from one location, 12 months 12 rows

## raw_operations_monthly_kpis_2024_2025
- **Source:** Ops
- **Grain:** each row represents site information for a given period, output/headcount/hours. multiple rows per site #
- **Rows:**
- **Key columns:** Site # as facility_id
- **Quantities and units:** site # as INT, cases/pallet/headcount/hours AS REAL
- **Dates:** YYYY-MM
- **Links to:** facility_id
- **Issues noticed:** snake_case columns, date format, 
- **Initial analysis:**

## raw_polar_mechanical_service_log_2025
- **Source:** Ops
- **Grain:** each row represents a unique work order with its location info for refrigerant added
- **Rows:** 206
- **Key columns:** Site to link ID
- **Quantities and units:** lbs added recovered as REAL, convert to kg needed, 
- **Dates:**
- **Links to:** facility_register, refrigeration_equipment_inventory
- **Issues noticed:** same issue with refrigerant type naming scheme, snake_case columns, equipment ID not consistent. CASE, CONCAT SUBSTR for equip ID.
- **Initial analysis:**


## raw_propane_deliveries_2025
- **Source:** Ops/finance
- **Grain:** each row represents a delivery order of propane, multiple rows per facility_id.
- **Rows:**
- **Key columns:** facility_id
- **Quantities and units:** Quantity as REAL
- **Dates:** YYYY-MM-DD
- **Links to:** facility_register
- **Issues noticed:** none
- **Initial analysis:** two different units of measure, will need to convert.

## raw_rec_retirements_2025
- **Source:** finance/ops
- **Grain:** each row represents rec applied to a unique facility
- **Rows:**
- **Key columns:** applied_to_facility
- **Quantities and units:** mwh as REAL
- **Dates:** YYYY-MM-DD
- **Links to:** facility_register
- **Issues noticed:** none
- **Initial analysis:**

## raw_refrigeration_equipment_inventory
- **Source:** finance
- **Grain:** each row represents a unique id and its info
- **Rows:**
- **Key columns:** facility_id, equipment_id
- **Quantities and units:** refrigerant is consistent with workout docs still need to convert to emission factors references, full charge AS REAL convert to kg
- **Dates:** YYYY
- **Links to:** polar_mechanics, arcticair, facility ID
- **Issues noticed:** refrigerant type to EF reference?
- **Initial analysis:** SO-BOS does not have refrigeration equipment (not in inventory)

## raw_slc_seller_utility_bills_jan_jun_2025
- **Source:** Finance
- **Grain:** each row represents a month of utility bills
- **Rows:** 12
- **Key columns:** Account
- **Quantities and units:** usage AS REAL
- **Dates:** YYYY-MM-DD
- **Links to:** utility_acccount_map
- **Issues noticed:** rename columns to be more specific and get rid of from and to
- **Initial analysis:**

## raw_supplier_specific_emission_rates
- **Source:**
- **Grain:** each row is the suppliers specific emissions intensities
- **Rows:** 3
- **Key columns:** utility_name
- **Quantities and units:** co2... as REAL
- **Dates:** YYYY
- **Links to:** 
- **Issues noticed:** none
- **Initial analysis:** na

## raw_telematics_monthly_mileage_2024_2025
- **Source:** ops
- **Grain:** each row represents a month of miles driven per unit number. multiple rows per unit numebr
- **Rows:**
- **Key columns:** unit_number
- **Quantities and units:** miles_driven as REAL
- **Dates:** YYYY-MM
- **Links to:** vehicle_register
- **Issues noticed:** none
- **Initial analysis:** 10 units are not reporting 12 months of data

## raw_utility_account_map
- **Source:** 
- **Grain:** maps each facility_id to its account_number, meter_number, and utility type
- **Rows:**
- **Key columns:** facility_id, account_number, meter_number
- **Quantities and units:** 
- **Dates:**
- **Links to:**
- **Issues noticed:** account number to be kept as text, includes a location with alpha-numeric code also looks like there may be a potenial loss of leading 0's, will need to verify.
- **Initial analysis:**

## raw_utilitypay_bill_export_2025
- **Source:**
- **Grain:** each row represents a monthly utility bill for each location, multiple rows for each location
- **Rows:**
- **Key columns:** account number, 
- **Quantities and units:** usage, current charges AS REAL, invoice number as INT
- **Dates:** MM-DD-YYYY, need to reformat
- **Links to:** facility_register, utility_account_map
- **Issues noticed:** address will need to substr, snake_case columns, dates
- **Initial analysis:** conversion needed for UOM

## raw_valley_mud_annual_usage_statement_2025
- **Source:**
- **Grain:** 1 row includes 12 months of utility usage for one location
- **Rows:** 1
- **Key columns:** Meter
- **Quantities and units:** once transposed, units as REAL
- **Dates:** written month-year
- **Links to:** utility_account_map
- **Issues noticed:** transpose table to long form, snake_case columns
- **Initial analysis:**

## raw_vehicle_register
- **Source:**
- **Grain:** each row represents all the information for each vehicle and its unit number
- **Rows:**
- **Key columns:** unit_number, home_facility_id, fuel_card
- **Quantities and units:**
- **Dates:** YYYY-DD-MM, reformat
- **Links to:** facility_register, fuel_card_assignment, fuel_card_transactions
- **Issues noticed:** dates
- **Initial analysis:**

## raw_weather_degree_days_2024_2025
- **Source:**
- **Grain:** each row provides heating degree days and cooling degree days based on location
- **Rows:**
- **Key columns:** station_id maps to nearest_weather_station from facility_register
- **Quantities and units:** hdd and cdd as REAL
- **Dates:** YYYY-MM
- **Links to:** facility_register
- **Issues noticed:** none
- **Initial analysis:** na
