-- Clear table before inserting

DELETE FROM supplier_emission_rate;
DELETE FROM rec_retirement;

-- ===========================================================================
-- Insert data and logic
-- ===========================================================================
INSERT INTO rec_retirement (batch_id, tracking_system, resource_type, generation_location, vintage_year, mwh, retirement_date, facility_id, certification)
SELECT
	rrr.batch_id,
	rrr.tracking_system,
	rrr.resource_type,
	rrr.generation_location,
	rrr.vintage_year,
	rrr.mwh,
	rrr.retirement_date,
	rrr.applied_to_facility,
	rrr.certification 
FROM raw_rec_retirements_2025 rrr;

INSERT INTO supplier_emission_rate (utility_name, product, data_year, co2_lb_per_mwh, source_note)
SELECT
	rsser.utility_name,
	rsser.product,
	rsser."year",
	rsser.co2_lb_per_mwh,
	rsser.source_note
FROM raw_supplier_specific_emission_rates rsser;
