-- Clear table before inserting

DELETE FROM valley_consumption;
DELETE FROM utilitypay_bill;
DELETE FROM slc_utility_bill;
DELETE FROM chi_midwest_invoice;
DELETE FROM mesa_gas_bill;
DELETE FROM energyhub_consumption;
DELETE FROM map_utility;

-- ===========================================================================
-- Insert data and logic
-- ===========================================================================
INSERT INTO map_utility (account_number, facility_id, utility_name, commodity, meter_number, notes)
SELECT
	ruam.account_number,
	ruam.facility_id,
	ruam.utility_name,
	ruam.commodity,
	ruam.meter_number,
	ruam.notes
FROM raw_utility_account_map ruam;

INSERT INTO map_utility (account_number, facility_id, utility_name, commodity, meter_number, notes)
VALUES ('449234681', 'DC-DAL', 'Bluebonnet Energy Retail', 'Electricity', 'M4860725',
        'Added manually: Dallas dock expansion meter is in EnergyHub but missing from the account map');

INSERT INTO energyhub_consumption (site, account_number, utility, meter_number, start_date, end_date, consumption, uom, cost_usd, est)
SELECT
	rece.SiteRef,
	REPLACE(rece."Acct #", '-',''),
	rece.Utility,
	rece.Meter,
	rece."Start Date",
	rece."End Date",
	rece.Consumption,
	rece.Units,
	rece."Cost (USD)",
	rece."Est?"
FROM raw_energyhub_consumption_export rece
WHERE rece.SiteRef != 'TOTAL';

INSERT INTO mesa_gas_bill (account_number, address, prev_read_date, curr_read_date, prev_read_ccf, curr_read_ccf, therm_multiplier, amount_due)
SELECT
	rmgbh."Customer #",
	rmgbh.Premise,
	CASE
		WHEN rmgbh."Prev Read Date"  LIKE '__/__/____' THEN
		SUBSTR(rmgbh."Prev Read Date" , INSTR(rmgbh."Prev Read Date" , '/') + 4, 4) ||'-'|| 	-- Grab year and add hyphen
		SUBSTR(rmgbh."Prev Read Date" , 1, 2)||'-'|| 											-- Search for month and add hyphen
		SUBSTR(rmgbh."Prev Read Date" , 4, 2) 													-- Search for two-digit day
		ELSE NULL
	END,
	CASE
		WHEN rmgbh."Curr Read Date"   LIKE '__/__/____' THEN
		SUBSTR(rmgbh."Curr Read Date" , INSTR(rmgbh."Curr Read Date" , '/') + 4, 4) ||'-'|| 	-- Grab year and add hyphen
		SUBSTR(rmgbh."Curr Read Date" , 1, 2)||'-'|| 											-- Search for month and add hyphen
		SUBSTR(rmgbh."Curr Read Date" , 4, 2) 													-- Search for two-digit day
		ELSE NULL
	END,
	rmgbh."Prev Read (CCF)",
	rmgbh."Curr Read (CCF)",
	rmgbh."Therm Multiplier",
	rmgbh."Amount Due"
FROM raw_mesa_gas_billing_history rmgbh;

INSERT INTO chi_midwest_invoice (facility_id, month, customer, pipeline_pool, nominated_volume_dth, price_per_dth)
SELECT
	'DC-CHI',
	SUBSTR(rmgmsic."Invoice Month", INSTR(rmgmsic."Invoice Month", ' ') + 1, 4) ||'-'||	-- Search for year, add hyphen	
	CASE
		WHEN INSTR(rmgmsic."Invoice Month", 'January') > 0 THEN '01'
		WHEN INSTR(rmgmsic."Invoice Month", 'February') > 0 THEN '02'
		WHEN INSTR(rmgmsic."Invoice Month", 'March') > 0 THEN '03'
		WHEN INSTR(rmgmsic."Invoice Month", 'April') > 0 THEN '04'
		WHEN INSTR(rmgmsic."Invoice Month", 'May') > 0 THEN '05'
		WHEN INSTR(rmgmsic."Invoice Month", 'June') > 0 THEN '06'
		WHEN INSTR(rmgmsic."Invoice Month", 'July') > 0 THEN '07'
		WHEN INSTR(rmgmsic."Invoice Month", 'August') > 0 THEN '08'
		WHEN INSTR(rmgmsic."Invoice Month", 'September') > 0 THEN '09'
		WHEN INSTR(rmgmsic."Invoice Month", 'October') > 0 THEN '10'
		WHEN INSTR(rmgmsic."Invoice Month", 'November') > 0 THEN '11'
		WHEN INSTR(rmgmsic."Invoice Month", 'December') > 0 THEN '12'
		ELSE NULL
	END,																				-- Search for month, assign its associated digits
	rmgmsic.Customer,
	rmgmsic."Pipeline Pool",
	rmgmsic."Nominated Volume (Dth)",
	rmgmsic."Commodity Price ($/Dth)"
FROM raw_midwest_gas_marketing_supply_invoices_chicago rmgmsic;

INSERT INTO slc_utility_bill (customer, account_number, commodity, start_date, end_date, usage, uom)
SELECT
	rssubjj.Customer,
	rssubjj.Account,
	rssubjj.Service,
	rssubjj."From",
	rssubjj."To",
	rssubjj."Usage",
	rssubjj.Units
FROM raw_slc_seller_utility_bills_jan_jun_2025 rssubjj;

INSERT INTO utilitypay_bill (invoice_number, vendor_name, account_number, address, commodity, bill_date, service_start_date, service_end_date, usage, uom, read_type, bill_status, current_charges)
SELECT
	DISTINCT rube."Invoice Number",
	rube."Vendor Name",
	printf('%010d',rube."Account Number"), -- add leading zeros
	rube."Service Address",
	rube.Commodity,
	CASE
		WHEN rube."Bill Date" LIKE '__/__/____' THEN
		SUBSTR(rube."Bill Date" , INSTR(rube."Bill Date" , '/') + 4, 4) ||'-'|| 						-- Grab year and add hyphen
		SUBSTR(rube."Bill Date" , 1, 2)||'-'|| 															-- Search for month and add hyphen
		SUBSTR(rube."Bill Date" , 4, 2) 																-- Search for two-digit day
		ELSE NULL
	END,
	CASE
		WHEN rube."Service Period Start" LIKE '__/__/____' THEN
		SUBSTR(rube."Service Period Start" , INSTR(rube."Service Period Start" , '/') + 4, 4) ||'-'|| 	-- Grab year and add hyphen
		SUBSTR(rube."Service Period Start" , 1, 2)||'-'|| 												-- Search for month and add hyphen
		SUBSTR(rube."Service Period Start" , 4, 2) 														-- Search for two-digit day
		ELSE NULL
	END,
	CASE
		WHEN rube."Service Period End" LIKE '__/__/____' THEN
		SUBSTR(rube."Service Period End" , INSTR(rube."Service Period End" , '/') + 4, 4) ||'-'|| 		-- Grab year and add hyphen
		SUBSTR(rube."Service Period End" , 1, 2)||'-'|| 												-- Search for month and add hyphen
		SUBSTR(rube."Service Period End" , 4, 2) 														-- Search for two-digit day
		ELSE NULL
	END,
	rube."Usage",
	rube.UOM,
	rube."Read Type",
	rube."Bill Status",
	rube."Current Charges"
FROM raw_utilitypay_bill_export_2025 rube
WHERE rube.Commodity NOT IN ('Water', 'Sewer');

WITH months(month) AS (
	VALUES
		('2025-01'),
		('2025-02'), 
		('2025-03'),
		('2025-04'),
		('2025-05'),
		('2025-06'),
		('2025-07'),
		('2025-08'),
		('2025-09'),
		('2025-10'),
		('2025-11'),
		('2025-12')
)
INSERT INTO valley_consumption (account_number, meter_number, address, rate_schedule, renewable_choice_enrollment, month, consumption)
SELECT
	rvmaus.Account,
	rvmaus.Meter,
	rvmaus."Service Address",
	rvmaus."Rate Schedule",
	(REPLACE(rvmaus."Renewable Choice Enrollment", '%', '')/100.0),
	m.month,
	CASE m.month
		WHEN '2025-01' THEN REPLACE(rvmaus."Jan-2025", ',', '')
		WHEN '2025-02' THEN REPLACE(rvmaus."Feb-2025", ',', '')
		WHEN '2025-03' THEN REPLACE(rvmaus."Mar-2025", ',', '')
		WHEN '2025-04' THEN REPLACE(rvmaus."Apr-2025", ',', '')
		WHEN '2025-05' THEN REPLACE(rvmaus."May-2025", ',', '')
		WHEN '2025-06' THEN REPLACE(rvmaus."Jun-2025", ',', '')
		WHEN '2025-07' THEN REPLACE(rvmaus."Jul-2025", ',', '')
		WHEN '2025-08' THEN REPLACE(rvmaus."Aug-2025", ',', '')
		WHEN '2025-09' THEN REPLACE(rvmaus."Sep-2025", ',', '')
		WHEN '2025-10' THEN REPLACE(rvmaus."Oct-2025", ',', '')
		WHEN '2025-11' THEN REPLACE(rvmaus."Nov-2025", ',', '')
		WHEN '2025-12' THEN REPLACE(rvmaus."Dec-2025", ',', '')
	END
FROM raw_valley_mud_annual_usage_statement_2025 rvmaus
CROSS JOIN months m;
