-- Clear table before inserting

DELETE FROM ref_residual_mix;

-- ===========================================================================
-- Insert data and logic
-- ===========================================================================

INSERT INTO ref_residual_mix (egrid_subregion, data_year, co2_lb_per_mwh, source)
SELECT
	rgermer."eGrid Subregion",
	2023,
	CAST(REPLACE(rgermer."Adjusted System Mix (lbs / MWh) (12-month vintage)", ',','') AS REAL),
	'2025 Green-e Residual Mix Emission Rates (2023 Data)'
FROM raw_green_e_residual_mix_emission_rates_2025 rgermer;