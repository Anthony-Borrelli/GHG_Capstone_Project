-- Clear table before inserting

DELETE FROM facility;

-- ===========================================================================
-- Create CTE and insert data with logic
-- Selects the latest facility_id record based on the record_updated column (PHX duplicate)
-- ===========================================================================

WITH ranked_facility AS (
SELECT *,
ROW_NUMBER() OVER (PARTITION BY facility_id ORDER BY record_updated DESC) AS rn
FROM raw_facility_register
) 
	
INSERT INTO facility (facility_id, site_number, facility_name, facility_type, street, city, state, zip, sqft,
ownership, utilities_paid_by, acquisition_date, lease_end_date, status, weather_station_id, egrid_subregion, record_updated)
	SELECT 
		facility_id,
		site_number,
		facility_name,
		facility_type,
		street,
		city,
		CASE(UPPER(state))
			WHEN 'TEXAS' THEN 'TX'
			WHEN 'WASH.' THEN 'WA'
			ELSE UPPER(state)
		END,
		printf('%05d',rf.zip), 											-- SQLite specific, returns 5 digits with leading 0
		CAST(REPLACE(sqft, ',', '') AS INTEGER),
		ownership,
		utilities_paid_by,
		SUBSTR(acquisition_date, INSTR(acquisition_date, ',') + 2, 4) ||'-'|| 	-- Grab year and add hyphen
		CASE
			WHEN INSTR(acquisition_date, 'January') > 0 THEN '01'
			WHEN INSTR(acquisition_date, 'February') > 0 THEN '02'
			WHEN INSTR(acquisition_date, 'March') > 0 THEN '03'
			WHEN INSTR(acquisition_date, 'April') > 0 THEN '04'
			WHEN INSTR(acquisition_date, 'May') > 0 THEN '05'
			WHEN INSTR(acquisition_date, 'June') > 0 THEN '06'
			WHEN INSTR(acquisition_date, 'July') > 0 THEN '07'
			WHEN INSTR(acquisition_date, 'August') > 0 THEN '08'
			WHEN INSTR(acquisition_date, 'September') > 0 THEN '09'
			WHEN INSTR(acquisition_date, 'October') > 0 THEN '10'
			WHEN INSTR(acquisition_date, 'November') > 0 THEN '11'
			WHEN INSTR(acquisition_date, 'December') > 0 THEN '12'
			ELSE NULL
		END ||'-'||																-- Search for month, assign its associated digits, add hyphen					
		SUBSTR(acquisition_date, INSTR(acquisition_date, ' ') + 1, 2), 			-- Search for two-digit day	
		CASE
			WHEN lease_end_date LIKE '__/__/____' THEN
			SUBSTR(lease_end_date, INSTR(lease_end_date, '/') + 4, 4) ||'-'|| 	-- Grab year and add hyphen
			SUBSTR(lease_end_date, 1, 2)||'-'|| 								-- Search for month and add hyphen
			SUBSTR(lease_end_date, 4, 2) 										-- Search for two-digit day
			ELSE NULL
		END,
		status,
		nearest_weather_station,
		rze.egrid_subregion,
		record_updated
	
	FROM ranked_facility rf
	LEFT JOIN ref_zip_egrid rze 
	ON rze.zip = printf('%05d',rf.zip)
	WHERE rf.rn = 1;
