-- Tables to gap fill and estimate missing data from utilities where no data was provided
-- and to estimate missing data for SO-BOS based on sqft
-- Missing days identified in 'missing_data.sql'

-- ===========================================================================
-- DC-ATL gap filling
-- ===========================================================================
WITH days_month AS (
	SELECT
	*,
	CAST(SUBSTR(date(bya."month" ||'-'|| '01', '+1 month', '-1 day'), 9, 2) AS INTEGER) AS days_in_month
	FROM base_year_activity bya
	WHERE facility_id = 'DC-ATL' AND bya.activity_type = 'electricity'
),
daily_rate_table AS (
	SELECT
		*,
		dm.quantity/dm.days_in_month AS daily_rate
	FROM days_month dm
)
INSERT INTO inventory_activity_data (reporting_year, facility_id, month, scope, source_category, activity_type, quantity, uom, is_estimated, vehicle_class, model_year, miles, refrigerant)
SELECT
	2025 AS reporting_year,
	drt.facility_id,
	CASE drt."month"
		WHEN '2024-02' THEN '2025-02'
		WHEN '2024-03' THEN '2025-03'
		WHEN '2024-04' THEN '2025-04'
	END,
	mat.scope,
	mat.source_category,
	mat.activity_type,
	CASE
		WHEN drt."month" = '2024-02' THEN daily_rate*14	-- Feb. missing 14 days
		WHEN drt."month" = '2024-03' THEN daily_rate*31	-- Mar. missing 31 days
		WHEN drt."month" = '2024-04' THEN daily_rate*12	-- Apr. missing 12 days
	END,
	'kWh' AS uom,
	1 AS is_estimated,
	NULL AS vehicle_class,
	NULL AS model_year,
	NULL AS miles,
	NULL AS refrigerant
FROM daily_rate_table drt
LEFT JOIN map_activity_type mat
	ON mat.activity_type = 'electricity'
WHERE drt."month" IN ('2024-02', '2024-03', '2024-04');

-- ===========================================================================
-- SO-BOS data estimation
-- ===========================================================================
WITH months AS (
	SELECT DISTINCT
		mcd."month"
	FROM map_calendar_day mcd
),
electricity_data AS (
	SELECT
		f.facility_id,
		m."month",
		mat."scope",
		mat.source_category,
		mat.activity_type,
		(f.sqft*rbi.kwh_per_sqft)/12.0 AS monthly_kwh,
		'kWh' AS uom
	FROM facility f
	CROSS JOIN ref_building_intensity rbi
	CROSS JOIN months m
	JOIN map_activity_type mat 
		ON mat.activity_type = 'electricity'
	WHERE f.facility_id = 'SO-BOS'
),
natural_gas_data AS (
	SELECT
		f.facility_id,
		m."month",
		mat."scope",
		mat.source_category,
		mat.activity_type,
		(f.sqft*rbi.mmbtu_per_sqft)/12.0 AS monthly_natural_gas,
		'MMBtu' AS uom
	FROM facility f
	CROSS JOIN ref_building_intensity rbi
	CROSS JOIN months m
	JOIN map_activity_type mat 
		ON mat.activity_type = 'natural_gas'
	WHERE f.facility_id = 'SO-BOS'
)

INSERT INTO inventory_activity_data (reporting_year, facility_id, month, scope, source_category, activity_type, quantity, uom, is_estimated, vehicle_class, model_year, miles, refrigerant)
	SELECT
		2025 as reporting_year,
		ed.facility_id,
		ed."month",
		ed."scope",
		ed.source_category,
		ed.activity_type,
		ed.monthly_kwh,
		ed.uom,
		1 AS is_estimated,
		NULL AS vehicle_class,
		NULL AS model_year,
		NULL AS miles,
		NULL AS refrigerant
	FROM electricity_data ed
UNION ALL
	SELECT
		2025 as reporting_year,
		ngd.facility_id,
		ngd."month",
		ngd."scope",
		ngd.source_category,
		ngd.activity_type,
		ngd.monthly_natural_gas,
		ngd.uom,
		1 AS is_estimated,
		NULL AS vehicle_class,
		NULL AS model_year,
		NULL AS miles,
		NULL AS refrigerant
	FROM natural_gas_data ngd;





