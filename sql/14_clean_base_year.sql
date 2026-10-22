-- Clear table before inserting

DELETE FROM base_year_inventory ;
DELETE FROM base_year_activity ;

-- ===========================================================================
-- Insert data and logic
-- ===========================================================================
INSERT INTO base_year_activity (facility_id, month, scope, source_category, activity_type, quantity, uom, vehicle_class, model_year, miles, refrigerant)
SELECT
	rac.facility_code,
	rac.month,
	rac."scope",
	rac.source_category,
	rac.activity_type,
	rac.quantity,
	REPLACE(rac.unit, ' (estimated)', ''),
	NULLIF(rac.vehicle_class, ''),
	NULLIF(rac.model_year, ''),
	NULLIF(rac.miles, ''),
	NULLIF(rac.refrigerant, '')
FROM raw_activity_2024_clean rac;

INSERT INTO base_year_inventory (facility_id, scope, source_category, activity_type, co2_t, ch4_t, n2o_t, hfc_co2e_t, location_based_tco2e, market_based_tco2e, memo_hcfc_co2e_t)
SELECT
	rir.facility_code,
	rir."scope",
	rir.source_category,
	rir.activity_type,
	NULLIF(rir.co2_t, ''),
	NULLIF(rir.ch4_t, ''),
	NULLIF(rir.n2o_t, ''),
	NULLIF(rir.hfc_co2e_t, ''),
	rir.location_based_tco2e,
	rir.market_based_tco2e,
	rir.memo_hcfc_co2e_t
FROM raw_inventory_2024_results rir;