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
			WHEN tf.activity_type = 'diesel_onroad' THEN tm.miles
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


/*-- Date inclusive, both start and end date belong to the bill so add a day, as this day is missed when subtracting.
SELECT	
	ub.invoice_number,
	ub.service_start_date,
	ub.service_end_date,
	mcd.month,
	julianday(ub.service_end_date) - julianday(ub.service_start_date) + 1 AS days_per_bill,
	COUNT(*) AS days_in_month,
	SUM(ub."usage"/ (julianday(ub.service_end_date) - julianday(ub.service_start_date) + 1))
FROM utilitypay_bill ub
INNER JOIN map_calendar_day mcd
	ON mcd.calendar_date BETWEEN ub.service_start_date AND ub.service_end_date
GROUP BY invoice_number, service_start_date, service_end_date, mcd.month;



SELECT
	SUM(ub."usage"/ (julianday(ub.service_end_date) - julianday(ub.service_start_date) + 1)),
	CASE ub.uom 								-- convert Mcf to MMBtu, therm to MMBtu, kWh remains
		WHEN 'Mcf'   THEN ((SUM(ub."usage"/ (julianday(ub.service_end_date) - julianday(ub.service_start_date) + 1)))*mcf_gas.factor)
		WHEN 'therm' THEN ((SUM(ub."usage"/ (julianday(ub.service_end_date) - julianday(ub.service_start_date) + 1)))*therm_gas.factor)
		ELSE SUM(ub."usage"/ (julianday(ub.service_end_date) - julianday(ub.service_start_date) + 1))
	END
FROM utilitypay_bill ub
INNER JOIN map_calendar_day mcd
	ON mcd.calendar_date BETWEEN ub.service_start_date AND ub.service_end_date
LEFT JOIN map_utility mu
	ON ub.account_number = mu.account_number
LEFT JOIN ref_unit_conversion mcf_gas
	ON ub.uom = mcf_gas.from_unit
	AND mcf_gas.to_unit = 'MMBtu'
LEFT JOIN ref_unit_conversion therm_gas
	ON ub.uom = therm_gas.from_unit
	AND therm_gas.to_unit = 'MMBtu'
GROUP BY mu.facility_id, service_start_date, service_end_date, mcd.month;
	