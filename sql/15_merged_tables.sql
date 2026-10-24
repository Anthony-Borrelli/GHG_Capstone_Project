-- Clear table before inserting

DELETE FROM utility_bill;
DELETE FROM refrigerant_service;

-- ===========================================================================
-- Insert data and logic
-- ===========================================================================
INSERT INTO refrigerant_service (work_order, service_Date, equipment_id, facility_id, service_type, refrigerant, 
qty_charged_lbs, qty_recovered_lbs, tech_comments, source_system)
	SELECT
		work_order,
		service_date,
		pl.equipment_id,
		re.facility_id,
		service_type,
		re.refrigerant,
		pl.qty_charged_lbs, 
		pl.qty_recovered_lbs,
		pl.tech_comments,
		'polar_log'
	FROM polar_log pl
	LEFT JOIN refrigeration_equipment re
		ON pl.equipment_id = re.equipment_id
UNION ALL
	SELECT work_order,
		service_date,
		al.equipment_id,
		re.facility_id,
		job_type,
		re.refrigerant,
		(al.qty_charged*ruc.factor), 		-- conversion to lbs
		(al.qty_recovered*ruc.factor),		-- conversion to lbs
		al.tech_comments,
		'arcticair_log'
	FROM arcticair_log al 
	LEFT JOIN refrigeration_equipment re
		ON al.equipment_id = re.equipment_id
	LEFT JOIN ref_unit_conversion ruc
		ON al.uom = ruc.from_unit 
		AND ruc.to_unit = 'lb';

INSERT INTO utility_bill (facility_id, account_number, meter_number, service_start_date, service_end_date, 
commodity, quantity, uom, is_estimated, utility_name, source_system, source_ref)
	SELECT
	mu.facility_id,
	mu.account_number,
	mu.meter_number,
	ub.service_start_date, 
	ub.service_end_date,
	ub.commodity,
	CASE ub.uom 								-- convert Mcf to MMBtu, therm to MMBtu, kWh remains
		WHEN 'Mcf'   THEN (ub.usage*ruc.factor)
		WHEN 'therm' THEN (ub.usage*ruc.factor)
		ELSE ub.usage
	END,
	CASE ub.uom									-- updated to the UOM after conversion, only kWh and MMBtu
		WHEN 'Mcf'	 THEN 'MMBtu'
		WHEN 'therm' THEN 'MMBtu'
		ELSE ub.uom
	END,
	CASE ub.read_type							-- A, Actual, and E, Estimate, to binary
		WHEN 'A' THEN 0
		WHEN 'E' THEN 1
		ELSE NULL
	END,
	ub.vendor_name,
	'utilitypay_bill',
	ub.invoice_number 
	FROM utilitypay_bill ub
	LEFT JOIN map_utility mu 
		ON ub.account_number = mu.account_number
	LEFT JOIN ref_unit_conversion ruc
		ON ub.uom = ruc.from_unit
		AND ruc.to_unit = 'MMBtu'
	WHERE ub.bill_status NOT IN ('Cancelled')
UNION ALL
	SELECT
		mu.facility_id,
		mu.account_number,
		mu.meter_number,
		ec.start_date,
		ec.end_date,
		'Electric',
		CASE ec.uom 									-- convert MWh to kWh
			WHEN 'MWh' THEN (ec.consumption*ruc.factor)
			ELSE ec.consumption
		END,
		CASE ec.uom 									-- update to converted units
			WHEN 'MWh' THEN 'kWh'
			ELSE ec.uom
		END,
		CASE ec.est 									-- N, no, Y, yes, into binary
			WHEN 'N' THEN 0
			WHEN 'Y' THEN 1
			ELSE NULL
		END,
		ec.utility,
		'energyhub_consumption',
		ec.meter_number ||' | '|| ec.start_date 		-- primary key row identifier
	FROM energyhub_consumption ec
	LEFT JOIN map_utility mu
		ON ec.account_number = mu.account_number
	LEFT JOIN ref_unit_conversion ruc
		ON ec.uom = ruc.from_unit
		AND ruc.to_unit = 'kWh'
UNION ALL
	SELECT
		mu.facility_id,
		mu.account_number,
		mu.meter_number,
		date(vc."month" ||'-'|| '01'),
		date(vc."month" ||'-'|| '01', '+1 month', '-1 day'), -- create end date for last day of month
		'Electric',
		vc.consumption,
		'kWh',												 -- unit not stated in the Valley MUD file; kWh confirmed against Sacramento's 2024 base-year electricity
		0,
		mu.utility_name,
		'valley_consumption',
		vc.meter_number ||' | '|| vc."month" 				 -- primary key row identifier
	FROM valley_consumption vc
	LEFT JOIN map_utility mu
		ON vc.account_number = mu.account_number
UNION ALL
	SELECT
		mu.facility_id,
		mu.account_number,
		mu.meter_number,
		mgb.prev_read_date,
		date(mgb.curr_read_date, '-1 day'), 				 -- shared reading day, curre_read shares prev_read day. adjust curr_read a day before so start is valid
		'Natural Gas',
		CASE 																																			-- convert from CCF to MMBtu
			WHEN mgb.prev_read_ccf > mgb.curr_read_ccf THEN (((100000.0 - mgb.prev_read_ccf) + mgb.curr_read_ccf)*mgb.therm_multiplier)*ruc.factor		-- meter rollover at 100,000. need to include both prev and current read for total bill
			ELSE ((mgb.curr_read_ccf - mgb.prev_read_ccf)*mgb.therm_multiplier)*ruc.factor
		END,
		'MMBtu',
		0,
		mu.utility_name ,
		'mesa_gas_bill',
		mu.account_number ||' | '|| mgb.curr_read_date 	-- primary key row identifier
	FROM mesa_gas_bill mgb
	LEFT JOIN map_utility mu
		ON mgb.account_number = mu.account_number
	LEFT JOIN ref_unit_conversion ruc
		ON ruc.from_unit = 'therm'
		AND ruc.to_unit = 'MMBtu';
