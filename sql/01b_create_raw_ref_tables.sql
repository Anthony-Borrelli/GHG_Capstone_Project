-- WARNING: running this script drops and recreates every raw reference table (all imported data is deleted).
-- Rerun the imports afterwards (see load/load_raw_data.sql).
-- Raw reference tables hold published source files that need cleaning, exactly as downloaded (all TEXT).
-- They are cleaned into the typed ref_ tables defined in 02_create_clean_tables.sql.
-- Reference files that are already clean (data/reference/factors/ref_*.csv) skip this step
-- and load straight into their ref_ tables.

-- ===========================================================================
-- Drop everything
-- ===========================================================================
DROP TABLE IF EXISTS raw_power_profiler_zipcode_tool;
DROP TABLE IF EXISTS raw_green_e_residual_mix_emission_rates_2025;

-- ===========================================================================
-- eGRID subregion by ZIP code
-- Source: EPA Power Profiler ZIP code tool v14.3, saved as CSV
-- File: data/reference/factors/power_profiler_zipcode_tool.csv
-- Feeds: ref_zip_egrid ("Subregion 2" is filled only when a ZIP spans two subregions)
-- ===========================================================================
CREATE TABLE raw_power_profiler_zipcode_tool (
	zip 			TEXT,
	"Subregion 1" 	TEXT,
	"Subregion 2" 	TEXT
);

-- ===========================================================================
-- Green-e residual mix (market-based Scope 2)
-- Source: 2025 Green-e Residual Mix Emission Rates (2023 data), saved as CSV
-- File: data/reference/factors/green_e_residual_mix_emission_rates_2025.csv
-- Feeds: ref_residual_mix
-- ===========================================================================
CREATE TABLE raw_green_e_residual_mix_emission_rates_2025 (
	"eGrid Subregion" 										TEXT,
	"CO2 Emissions (tons)" 									TEXT,
	"Net Generation (MWh)" 									TEXT,
	"Emission Rate (lb / MWh)" 								TEXT,
	"Voluntary RE emissions (lbs)" 							TEXT,
	"Voluntary RE (MWh) (12-month vintage)" 				TEXT,
	"Adjusted System Mix (lbs / MWh) (12-month vintage)" 	TEXT,
	"Difference (lbs / MWh) (12-month vintage)" 			TEXT,
	"% Difference (12-month vintage)" 						TEXT
);
