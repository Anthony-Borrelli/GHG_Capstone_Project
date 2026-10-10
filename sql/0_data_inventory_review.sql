-- Used to review each data table, identify data types, key columns/primary & foreign keys,
-- missing data, data that needs to be cleaned and formatted. In tandem with data_inventory.md

-- ------------------------------------------------------------------------------------------------
-- Company
-- ------------------------------------------------------------------------------------------------
SELECT *
FROM raw_company_financials rcf;

SELECT *
FROM raw_weather_degree_days_2024_2025 rwdd;

-- ------------------------------------------------------------------------------------------------
-- Facilities & KPI
-- ------------------------------------------------------------------------------------------------
SELECT *
FROM raw_facility_register rfr;

	WITH live_facility_register AS (
		SELECT
			facility_id,
			MAX(record_updated) AS newest_record
		FROM raw_facility_register
		GROUP BY facility_id 
	)
	
	SELECT 
		rfr.*
	FROM raw_facility_register rfr
	INNER JOIN live_facility_register lrf
		ON rfr.facility_id = lrf.facility_id
		AND rfr.record_updated = lrf.newest_record;

SELECT *
FROM raw_operations_monthly_kpis_2024_2025 romk ;

-- ------------------------------------------------------------------------------------------------
-- Fleet
-- ------------------------------------------------------------------------------------------------
SELECT *
FROM raw_fuel_card_assignments rfca;

	SELECT
		card_number,
		COUNT(card_number) AS total_cards
	FROM raw_fuel_card_assignments rfca
	GROUP BY rfca.card_number 
	ORDER BY total_cards DESC

SELECT *
FROM raw_fuel_card_transasctions_2025 rfct;

	SELECT
	COUNT(*)
	from raw_fuel_card_transasctions_2025 rfct 

	SELECT
	COUNT(DISTINCT("Transaction ID"))
	from raw_fuel_card_transasctions_2025 rfct
	
		SELECT
	COUNT("Unit Number")
	from raw_fuel_card_transasctions_2025 rfct
	
	SELECT
		COUNT(DISTINCT("Transaction ID")),
		COUNT("Card Number")
	FROM raw_fuel_card_transasctions_2025 rfct 		
	
	SELECT
		"Unit of Measure",
		COUNT("Unit of Measure")
	FROM raw_fuel_card_transasctions_2025 rfct 
	GROUP BY "Unit of Measure"
	
	SELECT
		"Product Description",
		COUNT("Product Description")
	FROM raw_fuel_card_transasctions_2025 rfct 
	GROUP BY "Product Description"

SELECT *
FROM raw_leased_vehicle_mileage_claims_2025 rlvmc;

SELECT *
FROM raw_telematics_monthly_mileage_2024_2025 rtmm;

	SELECT
		unit_number,
		COUNT(month) AS total_reporting_periods
	FROM raw_telematics_monthly_mileage_2024_2025 rtmm 
	WHERE month > '2024-12'
	GROUP BY unit_number
	ORDER BY total_reporting_periods
	
SELECT *
FROM raw_vehicle_register rvr;

-- ------------------------------------------------------------------------------------------------
-- Market Instruments
-- ------------------------------------------------------------------------------------------------
SELECT *
FROM raw_rec_retirements_2025 rrr;

SELECT *
FROM raw_supplier_specific_emission_rates rsser;

-- ------------------------------------------------------------------------------------------------
-- Refrigerants
-- ------------------------------------------------------------------------------------------------
SELECT *
FROM raw_arcticair_refrigeration_service_log_2025 rarsl;

	SELECT
		qty_charged,
		tech_comments
	FROM raw_arcticair_refrigeration_service_log_2025 rarsl
	WHERE qty_charged = 0.0;
	
	SELECT
		COUNT(DISTINCT(work_order))
	FROM raw_arcticair_refrigeration_service_log_2025 rarsl; -- equals total count
	
	SELECT
		MIN(date),
		MAX(date)
	FROM raw_arcticair_refrigeration_service_log_2025 rarsl; -- spans jan 01 - dec 21
	
	SELECT
		asset_tag,
		(qty_charged - qty_recovered) AS total_refrigerant_charged
	FROM raw_arcticair_refrigeration_service_log_2025 rarsl
	GROUP BY asset_tag
	ORDER BY total_refrigerant_charged DESC;

SELECT *
FROM raw_polar_mechanical_service_log_2025 rpmsl;

	SELECT
		COUNT(DISTINCT("WO #"))
	FROM raw_polar_mechanical_service_log_2025 rpmsl 

	SELECT
		"WO #",
		COUNT("WO #") AS total
	FROM raw_polar_mechanical_service_log_2025 rpmsl 
	GROUP BY "WO #"
	ORDER BY total DESC
	
	SELECT
		"Equipment ID",
		COUNT("Equipment ID") AS total
	FROM raw_polar_mechanical_service_log_2025 rpmsl 
	GROUP BY "Equipment ID" 
	ORDER BY total DESC
	
SELECT *
FROM raw_refrigeration_equipment_inventory rrei;

	SELECT
		facility_id,
		COUNT(facility_id)
	FROM raw_refrigeration_equipment_inventory rrei 
	GROUP BY facility_id
	
	SELECT
		rfr.facility_id,
		rrei.facility_id 
	FROM raw_facility_register rfr 
	LEFT JOIN raw_refrigeration_equipment_inventory rrei 
		ON rfr.facility_id = rrei.facility_id 
	WHERE rrei.facility_id IS NULL;

-- ------------------------------------------------------------------------------------------------
-- Stationary Sources
-- ------------------------------------------------------------------------------------------------
SELECT *
FROM raw_emergency_generator_fuel_log_2025 regfl;

	SELECT
		regfl.facility_id ,
		rfr.facility_type ,
		COUNT(DISTINCT(regfl.facility_id)),
		COUNT(DISTINCT(rfr.facility_id))
	FROM raw_emergency_generator_fuel_log_2025 regfl INNER JOIN raw_facility_register rfr ON regfl.facility_id = rfr.facility_id
	GROUP BY regfl.facility_id;
	
	SELECT
		facility_id,
		COUNT(DISTINCT(regfl.facility_id))
	FROM raw_emergency_generator_fuel_log_2025 regfl
	GROUP BY facility_id;

SELECT *
FROM raw_propane_deliveries_2025 rpd;
-- ------------------------------------------------------------------------------------------------
-- Utilities
-- ------------------------------------------------------------------------------------------------
SELECT *
FROM raw_energyhub_consumption_export rece;

	SELECT
		COUNT(DISTINCT("Acct #"))
	FROM raw_energyhub_consumption_export rece 

	SELECT
		COUNT(DISTINCT(SiteRef))
	FROM raw_energyhub_consumption_export rece 
	
	SELECT
		SiteRef,
		MIN("Start Date"),
		MAX("End Date")
	FROM raw_energyhub_consumption_export rece 
	GROUP BY SiteRef

	SELECT
		SiteRef,
		METER,
		COUNT(METER)
	FROM raw_energyhub_consumption_export rece 
	GROUP BY METER
	ORDER BY SiteRef
	
SELECT *
FROM raw_mesa_gas_billing_history rmgbh;

SELECT *
FROM raw_midwest_gas_marketing_supply_invoices_chicago rmgmsic;

SELECT *
FROM raw_slc_seller_utility_bills_jan_jun_2025 rssubjj;

SELECT *
FROM raw_utility_account_map ruam;

	SELECT
		COUNT(DISTINCT(account_number))
	FROM raw_utility_account_map ruam 
	
SELECT *
FROM raw_utilitypay_bill_export_2025 rube;

SELECT *
FROM raw_valley_mud_annual_usage_statement_2025 rvmaus;

-- ------------------------------------------------------------------------------------------------
-- Base year
-- ------------------------------------------------------------------------------------------------

PRAGMA table_info(raw_activity_2024_clean);
SELECT *
FROM raw_activity_2024_clean rac;

SELECT *
FROM raw_inventory_2024_results rir;
