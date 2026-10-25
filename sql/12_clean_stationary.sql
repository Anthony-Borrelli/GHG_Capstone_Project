-- Clear table before inserting

DELETE FROM propane_delivery;
DELETE FROM generator_log;

-- ===========================================================================
-- Insert data and logic
-- ===========================================================================
INSERT INTO generator_log (facility_id, entry_date, entry_type, reading, uom, tank_capacity_gal)
SELECT
	regfl.facility_id,
	regfl.entry_date,
	regfl.entry_type,
	CASE 
		WHEN regfl.unit = '% full' THEN (regfl.value/100.0)*regfl.tank_capacity_gal
		ELSE regfl.value
	END,
	CASE 
		WHEN regfl.unit = '% full' THEN 'gal'
		ELSE regfl.unit
	END,
	regfl.tank_capacity_gal
FROM raw_emergency_generator_fuel_log_2025 regfl;

INSERT INTO propane_delivery (facility_id, delivery_date, vendor, product, quantity, uom)
SELECT
	rpd.facility_id,
	rpd.delivery_date,
	rpd.vendor,
	rpd.product,
	rpd.quantity,
	rpd.uom
FROM raw_propane_deliveries_2025 rpd;