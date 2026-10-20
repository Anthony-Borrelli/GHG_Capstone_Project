-- WARNING: running this script drops and recreates every raw table (all imported data is deleted).
-- Rerun the imports afterwards (see docs/loading_raw_data.md).

PRAGMA foreign_keys = OFF;

-- ===========================================================================
-- Drop everything (children before parents)
-- ===========================================================================
DROP TABLE IF EXISTS raw_company_financials;
DROP TABLE IF EXISTS raw_operations_monthly_kpis_2024_2025;
DROP TABLE IF EXISTS raw_weather_degree_days_2024_2025;
DROP TABLE IF EXISTS raw_facility_register;
DROP TABLE IF EXISTS raw_fuel_card_assignments;
DROP TABLE IF EXISTS raw_fuel_card_transactions_2025;
DROP TABLE IF EXISTS raw_leased_vehicle_mileage_claims_2025;
DROP TABLE IF EXISTS raw_telematics_monthly_mileage_2024_2025;
DROP TABLE IF EXISTS raw_vehicle_register;
DROP TABLE IF EXISTS raw_rec_retirements_2025;
DROP TABLE IF EXISTS raw_supplier_specific_emission_rates;
DROP TABLE IF EXISTS raw_arcticair_refrigeration_service_log_2025;
DROP TABLE IF EXISTS raw_polar_mechanical_service_log_2025;
DROP TABLE IF EXISTS raw_refrigeration_equipment_inventory;
DROP TABLE IF EXISTS raw_emergency_generator_fuel_log_2025;
DROP TABLE IF EXISTS raw_propane_deliveries_2025;
DROP TABLE IF EXISTS raw_energyhub_consumption_export;
DROP TABLE IF EXISTS raw_mesa_gas_billing_history;
DROP TABLE IF EXISTS raw_midwest_gas_marketing_supply_invoices_chicago;
DROP TABLE IF EXISTS raw_slc_seller_utility_bills_jan_jun_2025;
DROP TABLE IF EXISTS raw_utility_account_map;
DROP TABLE IF EXISTS raw_utilitypay_bill_export_2025;
DROP TABLE IF EXISTS raw_valley_mud_annual_usage_statement_2025;
DROP TABLE IF EXISTS raw_activity_2024_clean;
DROP TABLE IF EXISTS raw_inventory_2024_results;

-- ===========================================================================
-- Company, facilities, and business drivers
-- ===========================================================================
CREATE TABLE raw_company_financials (
	fiscal_year 			 TEXT,
	net_revenue_usd_millions TEXT,
	employees_fte 			 TEXT
);

CREATE TABLE raw_operations_monthly_kpis_2024_2025 (
	"Site #" 					TEXT,
	Period 						TEXT,
	"Cases Shipped" 			TEXT,
	"Avg Pallet Positions Used" TEXT,
	"Headcount" 				TEXT,
	"Operating Hours" 			TEXT
);

CREATE TABLE raw_weather_degree_days_2024_2025 (
	station_id 	TEXT,
	city 		TEXT,
	state 		TEXT,
	month 		TEXT,
	hdd_65F 	TEXT,
	cdd_65F 	TEXT
);

CREATE TABLE raw_facility_register (
	facility_id 			TEXT,
	site_number 			TEXT,
	facility_name 			TEXT,
	facility_type 			TEXT,
	street 					TEXT,
	city 					TEXT,
	state 					TEXT,
	zip 					TEXT,
	sqft 					TEXT,
	ownership 				TEXT,
	utilities_paid_by 		TEXT,
	acquisition_date 		TEXT,
	lease_end_date 			TEXT,
	status 					TEXT,
	nearest_weather_station TEXT,
	record_updated 			TEXT
);

-- ===========================================================================
-- Fleet
-- ===========================================================================
CREATE TABLE raw_fuel_card_assignments (
	card_number 	TEXT,
	unit_number		TEXT,
	assigned_from	TEXT,
	assigned_to 	TEXT
);

CREATE TABLE raw_fuel_card_transactions_2025 (
	"Transaction ID" 	  TEXT,
	"Card Number" 		  TEXT,
	"Unit Number" 		  TEXT,
	"Transaction Date"	  TEXT,
	"Transaction Time"	  TEXT,
	"Post Date"			  TEXT,
	"Merchant Name"		  TEXT,
	"Merchant City"		  TEXT,
	"Merchant State"	  TEXT,
	"Product Description" TEXT,
	Quantity 			  TEXT,
	"Unit of Measure"	  TEXT,
	"Unit Price" 		  TEXT,
	"Gross Amount"		  TEXT,
	Odometer  			  TEXT
);

CREATE TABLE raw_leased_vehicle_mileage_claims_2025 (
	"Employee ID" 				TEXT,
	"Leased Vehicle Unit" 		TEXT,
	"Expense Month" 		 	TEXT,
	"Business Miles Claimed" 	TEXT,
	"Reimbursement Rate ($/mi)" TEXT
);

CREATE TABLE raw_telematics_monthly_mileage_2024_2025 (
	unit_number  TEXT,
	month 		 TEXT,
	miles_driven TEXT
);

CREATE TABLE raw_vehicle_register (
	unit_number 		TEXT,
	vin 				TEXT,
	vehicle_class 		TEXT,
	fuel_type 			TEXT,
	model_year 			TEXT,
	home_facility_id 	TEXT,
	ownership 			TEXT,
	in_service_date 	TEXT,
	out_of_service_date TEXT,
	fuel_card 			TEXT,
	telematics 			TEXT,
	rated_mpg 			TEXT
);

-- ===========================================================================
-- Market instruments
-- ===========================================================================
CREATE TABLE raw_rec_retirements_2025 (
	batch_id 			TEXT,
	tracking_system 	TEXT,
	resource_type 		TEXT,
	generation_location TEXT,
	vintage_year 		TEXT,
	mwh 				TEXT,
	retirement_date 	TEXT,
	applied_to_facility TEXT,
	certification 		TEXT
);

CREATE TABLE raw_supplier_specific_emission_rates (
	utility_name 	TEXT,
	product 		TEXT,
	year 			TEXT,
	co2_lb_per_mwh  TEXT,
	source_note 	TEXT
);

-- ===========================================================================
-- Refrigerants
-- ===========================================================================
CREATE TABLE raw_arcticair_refrigeration_service_log_2025 (
	work_order 		TEXT,
	date 			TEXT,
	asset_tag 		TEXT,
	location 		TEXT,
	job_type 		TEXT,
	gas_type 		TEXT,
	qty_charged 	TEXT,
	qty_recovered 	TEXT,
	qty_uom 		TEXT,
	tech_comments 	TEXT
);

CREATE TABLE raw_polar_mechanical_service_log_2025 (
	"WO #" 				TEXT,
	"Service Date" 		TEXT,
	"Equipment ID" 		TEXT,
	Site 				TEXT,
	"Service Type" 		TEXT,
	Refrigerant 		TEXT,
	"Lbs Added" 		TEXT,
	"Lbs Recovered" 	TEXT,
	"Technician Notes" 	TEXT
);

CREATE TABLE raw_refrigeration_equipment_inventory (
	equipment_id 	TEXT,
	facility_id 	TEXT,
	equipment_type 	TEXT,
	refrigerant 	TEXT,
	full_charge_lbs TEXT,
	install_year 	TEXT,
	status 			TEXT,
	retired_date 	TEXT
);

-- ===========================================================================
-- Stationary sources
-- ===========================================================================
CREATE TABLE raw_emergency_generator_fuel_log_2025 (
	facility_id 		TEXT,
	entry_date 			TEXT,
	entry_type 			TEXT,
	value 				TEXT,
	unit 				TEXT,
	tank_capacity_gal 	TEXT
);

CREATE TABLE raw_propane_deliveries_2025 (
	facility_id 	TEXT,
	delivery_date 	TEXT,
	vendor 			TEXT,
	product 		TEXT,
	quantity 		TEXT,
	uom 			TEXT
);

-- ===========================================================================
-- Utilities
-- ===========================================================================
CREATE TABLE raw_energyhub_consumption_export (
	SiteRef 		TEXT,
	"Acct #" 		TEXT,
	Utility 		TEXT,
	Meter 			TEXT,
	"Start Date" 	TEXT,
	"End Date" 		TEXT,
	Consumption 	TEXT,
	Units 			TEXT,
	"Cost (USD)" 	TEXT,
	"Est?" 			TEXT
);

CREATE TABLE raw_mesa_gas_billing_history (
	"Customer #" 		TEXT,
	Premise 			TEXT,
	"Prev Read Date" 	TEXT,
	"Curr Read Date" 	TEXT,
	"Prev Read (CCF)" 	TEXT,
	"Curr Read (CCF)" 	TEXT,
	"Therm Multiplier" 	TEXT,
	"Amount Due" 		TEXT
);

CREATE TABLE raw_midwest_gas_marketing_supply_invoices_chicago (
	"Invoice Month" 			TEXT,
	Customer 					TEXT,
	"Pipeline Pool" 			TEXT,
	"Nominated Volume (Dth)" 	TEXT,
	"Commodity Price ($/Dth)" 	TEXT
);

CREATE TABLE raw_slc_seller_utility_bills_jan_jun_2025 (
	Customer 	TEXT,
	Account 	TEXT,
	Service 	TEXT,
	"From" 		TEXT,
	"To" 		TEXT,
	Usage 		TEXT,
	Units 		TEXT
);

CREATE TABLE raw_utility_account_map (
	facility_id 	TEXT,
	utility_name 	TEXT,
	commodity 		TEXT,
	account_number 	TEXT,
	meter_number 	TEXT,
	notes 			TEXT
);

CREATE TABLE raw_utilitypay_bill_export_2025 (
	"Vendor Name" 			TEXT,
	"Account Number" 		TEXT,
	"Service Address" 		TEXT,
	Commodity 				TEXT,
	"Bill Date" 			TEXT,
	"Service Period Start" 	TEXT,
	"Service Period End" 	TEXT,
	Usage 					TEXT,
	UOM 					TEXT,
	"Read Type" 			TEXT,
	"Bill Status" 			TEXT,
	"Current Charges" 		TEXT,
	"Invoice Number" 		TEXT
);

CREATE TABLE raw_valley_mud_annual_usage_statement_2025 (
	Account 						TEXT,
	Meter 							TEXT,
	"Service Address" 				TEXT,
	"Rate Schedule" 				TEXT,
	"Renewable Choice Enrollment" 	TEXT,
	"Jan-2025" 						TEXT,
	"Feb-2025" 						TEXT,
	"Mar-2025" 						TEXT,
	"Apr-2025" 						TEXT,
	"May-2025" 						TEXT,
	"Jun-2025" 						TEXT,
	"Jul-2025" 						TEXT,
	"Aug-2025" 						TEXT,
	"Sep-2025" 						TEXT,
	"Oct-2025" 						TEXT,
	"Nov-2025" 						TEXT,
	"Dec-2025" 						TEXT
);

-- ===========================================================================
-- Base year (2024, already calculated)
-- ===========================================================================
CREATE TABLE raw_activity_2024_clean (
	facility_code 	TEXT,
	month 			TEXT,
	scope 			TEXT,
	source_category TEXT,
	activity_type 	TEXT,
	quantity 		TEXT,
	unit 			TEXT,
	vehicle_class 	TEXT,
	model_year 		TEXT,
	miles 			TEXT,
	refrigerant 	TEXT
);


CREATE TABLE raw_inventory_2024_results (
	facility_code 			TEXT,
	scope 					TEXT,
	source_category 		TEXT,
	activity_type 			TEXT,
	co2_t 					TEXT,
	ch4_t 					TEXT,
	n2o_t 					TEXT,
	hfc_co2e_t 				TEXT,
	location_based_tco2e 	TEXT,
	market_based_tco2e 		TEXT,
	memo_hcfc_co2e_t 		TEXT
);

PRAGMA foreign_keys = ON;
