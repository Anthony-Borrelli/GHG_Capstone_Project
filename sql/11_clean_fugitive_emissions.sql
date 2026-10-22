-- Clear table before inserting

DELETE FROM polar_log;
DELETE FROM arcticair_log;
DELETE FROM refrigeration_equipment;

-- ===========================================================================
-- Insert data and logic
-- ===========================================================================
INSERT INTO refrigeration_equipment (equipment_id, facility_id, equipment_type, refrigerant, full_charge_lbs, install_year, status, retired_date)
SELECT
	rrei.equipment_id,
	rrei.facility_id,
	rrei.equipment_type,
	CASE rrei.refrigerant 
		WHEN '134A'					 THEN 'R-134a'
		WHEN '404A'					 THEN 'R-404A'
		WHEN '410a'					 THEN 'R-410A'
		WHEN 'HCFC-22'				 THEN 'R-22'
		WHEN 'HFC-404A'				 THEN 'R-404A'
		WHEN 'HFC-134a'				 THEN 'R-134a'
		WHEN 'R404A'				 THEN 'R-404A'
		WHEN 'R410A'				 THEN 'R-410A'
		WHEN 'R448A'				 THEN 'R-448A'
		WHEN 'Solstice N40 (R-448A)' THEN 'R-448A'
		ELSE rrei.refrigerant
	END,
	rrei.full_charge_lbs,
	rrei.install_year,
	rrei.status,
	NULLIF(rrei.retired_date, '')
FROM raw_refrigeration_equipment_inventory rrei;

INSERT INTO arcticair_log (work_order, service_date, equipment_id, location, job_type, refrigerant, qty_charged, qty_recovered, uom, tech_comments)
SELECT
	rarsl.work_order,
	rarsl.date,
	rarsl.asset_tag,
	rarsl.location,
	UPPER(TRIM(rarsl.job_type)),
	CASE gas_type 
		WHEN '134A'					 THEN 'R-134a'
		WHEN '404A'					 THEN 'R-404A'
		WHEN '407C'					 THEN 'R-407C'
		WHEN '410a'					 THEN 'R-410A'
		WHEN 'HCFC-22'				 THEN 'R-22'
		WHEN 'HFC-404A'				 THEN 'R-404A'
		WHEN 'HFC-134a'				 THEN 'R-134a'
		WHEN 'R404A'				 THEN 'R-404A'
		WHEN 'R410A'				 THEN 'R-410A'
		WHEN 'R448A'				 THEN 'R-448A'
		WHEN 'R22'					 THEN 'R-22'
		WHEN 'Solstice N40 (R-448A)' THEN 'R-448A'
		ELSE gas_type
	END,
	rarsl.qty_charged,
	rarsl.qty_recovered,
	rarsl.qty_uom,
	rarsl.tech_comments 
FROM raw_arcticair_refrigeration_service_log_2025 rarsl;

INSERT INTO polar_log (work_order, service_date, equipment_id, facility_id, service_type, refrigerant, qty_charged_lbs, qty_recovered_lbs, tech_comments)
SELECT
	rpmsl."WO #",
	CASE
		WHEN rpmsl."Service Date"  LIKE '__/__/____' THEN
		SUBSTR(rpmsl."Service Date" , INSTR(rpmsl."Service Date" , '/') + 4, 4) ||'-'|| 	-- Grab year and add hyphen
		SUBSTR(rpmsl."Service Date" , 1, 2)||'-'|| 											-- Search for month and add hyphen
		SUBSTR(rpmsl."Service Date" , 4, 2) 												-- Search for two-digit day
		ELSE NULL
	END,
	CASE 
		WHEN INSTR(rpmsl."Equipment ID", '-') = 0 THEN UPPER(SUBSTR(rpmsl."Equipment ID", 1, 3) || '-'|| SUBSTR(rpmsl."Equipment ID", 4))
		ELSE UPPER(rpmsl."Equipment ID")
	END,
	rpmsl.Site,
	UPPER(TRIM(rpmsl."Service Type")),
	CASE rpmsl.Refrigerant  
		WHEN '134A'					 THEN 'R-134a'
		WHEN '404A'					 THEN 'R-404A'
		WHEN '407C'					 THEN 'R-407C'
		WHEN '410a'					 THEN 'R-410A'
		WHEN 'HCFC-22'				 THEN 'R-22'
		WHEN 'HFC-404A'				 THEN 'R-404A'
		WHEN 'HFC-134a'				 THEN 'R-134a'
		WHEN 'R404A'				 THEN 'R-404A'
		WHEN 'R410A'				 THEN 'R-410A'
		WHEN 'R448A'				 THEN 'R-448A'
		WHEN 'R22'					 THEN 'R-22'
		WHEN 'Solstice N40 (R-448A)' THEN 'R-448A'
		ELSE rpmsl.Refrigerant 
	END,
	rpmsl."Lbs Added",
	rpmsl."Lbs Recovered",
	rpmsl."Technician Notes" 
FROM raw_polar_mechanical_service_log_2025 rpmsl
WHERE (
	CASE
		WHEN rpmsl."Service Date"  LIKE '__/__/____' THEN
		SUBSTR(rpmsl."Service Date" , INSTR(rpmsl."Service Date" , '/') + 4, 4) ||'-'|| 	-- Grab year and add hyphen
		SUBSTR(rpmsl."Service Date" , 1, 2)||'-'|| 											-- Search for month and add hyphen
		SUBSTR(rpmsl."Service Date" , 4, 2) 												-- Search for two-digit day
		ELSE NULL
	END
	) >= '2025-01-01';
