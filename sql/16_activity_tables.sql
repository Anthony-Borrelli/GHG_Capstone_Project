-- Clear table before inserting
-- NOTE: propane forklifts included at facility level, loaded into inventory_activity_data rather than fleet_activity

DELETE FROM inventory_activity_data;
DELETE FROM fleet_activity; 

-- ===========================================================================
-- Insert data and logic
-- ===========================================================================
WITH fuel_transaction AS (
	SELECT
		v.facility_id,
		v.unit_number,
		SUBSTR(fct.transaction_date, 1, 7) AS "month",
		mfp.activity_type,
		SUM(fct.quantity) AS monthly_quantity,
		fct.uom
	FROM fuel_card_transaction fct
	LEFT JOIN vehicle v
		ON fct.unit_number = v.unit_number
	LEFT JOIN map_fuel_product mfp 
		ON fct.product_description = mfp.product_description
	WHERE mfp.activity_type != 'exclude'
	GROUP BY v.facility_id, v.unit_number, SUBSTR(fct.transaction_date, 1, 7), mfp.activity_type, fct.uom
)
INSERT INTO fleet_activity (facility_id, unit_number, month, activity_type, quantity, uom, miles, source_system)
	SELECT
		tf.facility_id,
		tf.unit_number,
		tf."month",
		tf.activity_type,
		tf.monthly_quantity,
		tf.uom,
		CASE 
			WHEN tf.activity_type = 'diesel_onroad'   THEN tm.miles
			WHEN tf.activity_type = 'gasoline_onroad' THEN tm.miles
			ELSE NULL
		END AS miles,
		'fuel_card_transaction'
	FROM fuel_transaction tf
	LEFT JOIN telematics_mileage tm
		ON tf.unit_number = tm.unit_number
		AND tf.month = tm.month
UNION ALL
	SELECT
		v.facility_id,
		mc.unit_number,
		mc."month",
		'gasoline_onroad', 		-- verified all leased vehicles are gasoline via vehicle table
		SUM(mc.miles/v.rated_mpg),
		'gal',
		SUM(mc.miles),
		'mileage_claim'
	FROM mileage_claim mc
	LEFT JOIN vehicle v
		ON mc.unit_number = v.unit_number
	GROUP BY v.facility_id, mc.unit_number, mc.month;	-- if a leased vehicle every had multiple claims per month

-- ===========================================================================
-- inventory_activity_data
-- ===========================================================================
WITH prorated_utility AS (
	SELECT
		ub.facility_id,
		mcd."year",
		mcd.month,
		CASE ub.commodity
			WHEN 'Natural Gas'  THEN 'natural_gas'
			WHEN 'Electric' 	THEN 'electricity'
			ELSE NULL
		END AS commodity,
		SUM(ub.quantity / (JULIANDAY(ub.service_end_date)-JULIANDAY(ub.service_start_date)+ 1)) AS quantity, -- Date inclusive, both start and end date belong to the bill so add a day, as this day is missed when subtracting.
		ub.uom
	FROM utility_bill ub
	INNER JOIN map_calendar_day mcd 															-- edge case fix, drops bills outside of reporting year 2025. Split by days first so days from bills that crossed into 2025 still included.
		ON mcd.calendar_date BETWEEN ub.service_start_date AND ub.service_end_date 
	GROUP BY ub.facility_id, mcd."year", mcd."month", commodity, ub.uom
)
INSERT INTO inventory_activity_data (reporting_year, facility_id, month, scope, source_category, activity_type, quantity, uom, is_estimated, vehicle_class, model_year, miles, refrigerant)
	SELECT
		pu."year",
		pu.facility_id,
		pu."month",
		mat."scope",
		mat.source_category,
		mat.activity_type,
		pu.quantity ,
		pu.uom ,
		0 AS is_estimated,
		NULL AS vehicle_class,
		NULL AS model_year,
		NULL AS miles,
		NULL AS refrigerant
	FROM prorated_utility pu
	LEFT JOIN map_activity_type mat
		ON pu.commodity = mat.activity_type;

INSERT INTO inventory_activity_data (reporting_year, facility_id, month, scope, source_category, activity_type, quantity, uom, is_estimated, vehicle_class, model_year, miles, refrigerant)
SELECT
	CAST(SUBSTR(fa."month", 1, 4) AS INTEGER) AS reporting_year,
	fa.facility_id,
	fa."month",
	mat.scope,
	mat.source_category,
	mat.activity_type,
	fa.quantity,
	fa.uom,
	0 AS is_estimated,
	v.vehicle_class,
	v.model_year,
	fa.miles,
	NULL AS refrigerant
FROM fleet_activity fa
LEFT JOIN map_activity_type mat
	ON fa.activity_type = mat.activity_type
LEFT JOIN vehicle v
	ON fa.unit_number = v.unit_number;

WITH propane AS (
	SELECT
		CAST(SUBSTR(pd.delivery_date, 1, 4) AS INTEGER) AS reporting_year,
		pd.facility_id,
		SUBSTR(pd.delivery_date, 1, 7) as month,
		CASE pd.product
			WHEN 'Forklift cylinder exchange (33.5 lb)' THEN 'propane_forklift'
			WHEN 'Propane - bulk tank fill' 			THEN 'propane_forklift'
			ELSE NULL
		END AS activity_type,
		pd.quantity,
		CASE pd.uom
			WHEN 'EA'  THEN 'cylinder_33_5lb'
			WHEN 'GAL' THEN 'gal'
			ELSE NULL
		END AS uom
	FROM propane_delivery pd
)
INSERT INTO inventory_activity_data (reporting_year, facility_id, month, scope, source_category, activity_type, quantity, uom, is_estimated, vehicle_class, model_year, miles, refrigerant)
SELECT
	p.reporting_year,
	p.facility_id,
	p.month,
	mat.scope,
	mat.source_category,
	mat.activity_type,
	SUM(CASE p.uom
		WHEN 'cylinder_33_5lb' THEN p.quantity*ruc.factor
		ELSE p.quantity
	END),
	'gal',
	0 AS is_estimated,
	NULL AS vehicle_class,
	NULL AS model_year,
	NULL AS miles,
	NULL AS refrigerant
FROM propane p
LEFT JOIN map_activity_type mat
	ON p.activity_type = mat.activity_type
LEFT JOIN ref_unit_conversion ruc
	ON p.uom = ruc.from_unit
	AND ruc.to_unit = 'gal'
GROUP BY p.reporting_year, p.facility_id, p."month", mat."scope", mat.source_category, mat.activity_type;

WITH reading_dates AS (
	SELECT
		gl.facility_id,
		MIN(gl.entry_date) AS first_reading_date,
		MAX(gl.entry_date) AS last_reading_date
	FROM generator_log gl 
	WHERE gl.entry_type = 'Tank Reading'
	GROUP BY gl.facility_id
)
INSERT INTO inventory_activity_data (reporting_year, facility_id, month, scope, source_category, activity_type, quantity, uom, is_estimated, vehicle_class, model_year, miles, refrigerant)
SELECT
	2025 AS reporting_year,
	gl.facility_id,
	NULL as month, 		-- generator data as annual values
	mat."scope",
	mat.source_category,
	mat.activity_type,
	SUM(CASE
			WHEN gl.entry_type = 'Tank Reading' AND gl.entry_date = rd.first_reading_date   THEN gl.reading  -- starting tank reading
			WHEN gl.entry_type = 'Tank Reading' AND gl.entry_date = rd.last_reading_date 	THEN -gl.reading -- ending tank reading, subtract from start
			WHEN gl.entry_type = 'Delivery'													THEN gl.reading  -- fuel added
			ELSE 0
	END) AS quantity,
	'gal' AS uom,
	0 AS is_estimated,
	NULL AS vehicle_class,
	NULL AS model_year,
	NULL AS miles,
	NULL AS refrigerant
FROM generator_log gl
INNER JOIN reading_dates rd
	ON gl.facility_id = rd.facility_id
LEFT JOIN map_activity_type mat
	ON mat.activity_type = 'diesel_generator'
GROUP BY gl.facility_id, mat."scope", mat.source_category, mat.activity_type;
	
INSERT INTO inventory_activity_data (reporting_year, facility_id, month, scope, source_category, activity_type, quantity, uom, is_estimated, vehicle_class, model_year, miles, refrigerant)
SELECT
	CAST(SUBSTR(rs.service_date, 1, 4) AS INTEGER) AS reporting_year,
	rs.facility_id,
	SUBSTR(rs.service_date, 1, 7) AS month,
	mat."scope",
	mat.source_category,
	mat.activity_type,
	SUM(CASE service_type
		WHEN 'LEAK REPAIR AND RECHARGE' 	THEN rs.qty_charged_lbs
		WHEN 'TOP OFF' 						THEN rs.qty_charged_lbs
		WHEN 'RECOVER AND RECHARGE'			THEN rs.qty_charged_lbs - rs.qty_recovered_lbs
		WHEN 'DECOMMISSION' 				THEN re.full_charge_lbs - rs.qty_recovered_lbs 
		WHEN 'INSTALLATION INITIAL CHARGE' 	THEN 0 											-- not an emission, not included
		WHEN 'PREVENTIVE MAINTENANCE'		THEN 0											-- no charge, not an emission, not included
		ELSE NULL
	END) AS quantity,
	'lb' AS uom,
	0 AS is_estimated,
	NULL AS vehicle_class,
	NULL AS model_year,
	NULL AS miles,
	re.refrigerant
FROM refrigerant_service rs
LEFT JOIN map_activity_type mat
	ON mat.activity_type = 'refrigerant'
LEFT JOIN refrigeration_equipment re 
	ON rs.equipment_id = re.equipment_id 
GROUP BY SUBSTR(rs.service_date, 1, 4), rs.facility_id, SUBSTR(rs.service_date, 1, 7), mat."scope", mat.source_category, mat.activity_type, re.refrigerant
HAVING quantity != 0;
