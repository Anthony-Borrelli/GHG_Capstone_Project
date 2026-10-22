-- Clear table before inserting

DELETE FROM ref_zip_egrid;

-- ===========================================================================
-- Insert data and logic
-- ===========================================================================
INSERT INTO ref_zip_egrid (zip, egrid_subregion, multiple_subregion_flag)
SELECT
	rppzt.zip,
	rppzt."Subregion 1",
	CASE
		WHEN rppzt."Subregion 2" IS NULL THEN 0
		WHEN TRIM(rppzt."Subregion 2") = '' THEN 0
		ELSE 1
	END
FROM raw_power_profiler_zipcode_tool rppzt;
