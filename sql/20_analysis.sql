-- Read-only: every query is a SELECT on the views from scripts 18 and 19, so this
-- file is not part of the rebuild (load/clean_data.sql). Run any query on its own.
-- Results are summarised in README.md and drawn in dashboard/.

-- ===========================================================================
-- A. Headline KPIs: totals and intensity, 2025 vs 2024
-- ===========================================================================
WITH totals AS (
	SELECT
		reporting_year,
		SUM(CASE WHEN "scope" = 'Scope 1' THEN location_based_tco2e ELSE 0 END) AS scope1_tco2e,
		SUM(CASE WHEN "scope" = 'Scope 2' THEN location_based_tco2e ELSE 0 END) AS scope2_location_tco2e,
		SUM(CASE WHEN "scope" = 'Scope 2' THEN market_based_tco2e ELSE 0 END) AS scope2_market_tco2e
	FROM company_summary
	GROUP BY reporting_year
),
cases AS (
	SELECT
		CAST(SUBSTR("month", 1, 4) AS INTEGER) AS reporting_year,
		SUM(cases_shipped) AS cases_shipped
	FROM operation_kpi
	GROUP BY 1
)
SELECT
	t.reporting_year,
	ROUND(t.scope1_tco2e, 0) AS scope1_tco2e,
	ROUND(t.scope2_location_tco2e, 0) AS scope2_location_tco2e,
	ROUND(t.scope2_market_tco2e, 0) AS scope2_market_tco2e,
	ROUND(t.scope1_tco2e + t.scope2_market_tco2e, 0) AS scope1_2_market_tco2e,
	ROUND((t.scope1_tco2e + t.scope2_market_tco2e) / f.net_revenue_usd_millions, 2) AS tco2e_per_usd_million,
	ROUND((t.scope1_tco2e + t.scope2_market_tco2e) / (c.cases_shipped / 1000.0), 3) AS tco2e_per_1000_cases
FROM totals t
JOIN financial f
	ON t.reporting_year = f.fiscal_year
JOIN cases c
	ON t.reporting_year = c.reporting_year
ORDER BY t.reporting_year;

-- ===========================================================================
-- B. Year-over-year change by source (location-based)
-- ===========================================================================
SELECT
	cs25.source_category,
	ROUND(cs24.location_based_tco2e, 0) AS tco2e_2024,
	ROUND(cs25.location_based_tco2e, 0) AS tco2e_2025,
	ROUND(cs25.location_based_tco2e - cs24.location_based_tco2e, 0) AS change_tco2e,
	ROUND(100.0 * (cs25.location_based_tco2e - cs24.location_based_tco2e) / cs24.location_based_tco2e, 1) AS change_pct
FROM company_summary cs25
JOIN company_summary cs24
	ON cs25.source_category = cs24.source_category
	AND cs24.reporting_year = 2024
WHERE cs25.reporting_year = 2025
ORDER BY change_tco2e DESC;

-- ===========================================================================
-- C. Facility ranking: total emissions and intensity (per sq ft, per 1,000 cases)
-- ===========================================================================
WITH cases_2025 AS (
	SELECT facility_id, SUM(cases_shipped) AS cases_shipped
	FROM operation_kpi
	WHERE "month" LIKE '2025-%'
	GROUP BY facility_id
)
SELECT
	ft.facility_id,
	f.facility_type,
	ROUND(ft.scope1_tco2e + ft.scope2_location_based_tco2e, 0) AS total_location_tco2e,
	ROUND(ft.scope1_tco2e + ft.scope2_market_based_tco2e, 0) AS total_market_tco2e,
	ROUND(1000.0 * (ft.scope1_tco2e + ft.scope2_location_based_tco2e) / f.sqft, 2) AS kgco2e_per_sqft,
	CASE WHEN c.cases_shipped > 0
		THEN ROUND((ft.scope1_tco2e + ft.scope2_location_based_tco2e) / (c.cases_shipped / 1000.0), 3)
	END AS tco2e_per_1000_cases
FROM facility_totals ft
JOIN facility f
	ON ft.facility_id = f.facility_id
LEFT JOIN cases_2025 c
	ON ft.facility_id = c.facility_id
ORDER BY total_location_tco2e DESC;

-- ===========================================================================
-- D. Monthly trend 2025 by source category (month NULL = annual generator rows, left out)
-- ===========================================================================
SELECT
	"month",
	source_category,
	ROUND(SUM(location_based_tco2e), 1) AS tco2e
FROM emissions
WHERE "month" IS NOT NULL
GROUP BY "month", source_category
ORDER BY "month", source_category;

-- ===========================================================================
-- E. Correlation 1: natural gas vs heating degree days (HDD), 2025, by facility
--    Pearson r = covariance / (std dev x * std dev y), built from AVG.
-- ===========================================================================
WITH gas_month AS (
	SELECT
		iad.facility_id,
		iad."month",
		SUM(iad.quantity) AS gas_mmbtu,
		wdd.hdd_65f
	FROM inventory_activity_data iad
	JOIN facility f
		ON iad.facility_id = f.facility_id
	JOIN weather_degree_days wdd
		ON f.weather_station_id = wdd.weather_station_id
		AND iad."month" = wdd."month"
	WHERE iad.activity_type = 'natural_gas'
		AND iad.is_estimated = 0
	GROUP BY iad.facility_id, iad."month", wdd.hdd_65f
),
stats AS (
	SELECT
		facility_id,
		COUNT(*) AS months,
		AVG(gas_mmbtu) AS avg_x,
		AVG(hdd_65f) AS avg_y,
		AVG(gas_mmbtu * hdd_65f) AS avg_xy,
		AVG(gas_mmbtu * gas_mmbtu) AS avg_xx,
		AVG(hdd_65f * hdd_65f) AS avg_yy
	FROM gas_month
	GROUP BY facility_id
	HAVING COUNT(*) >= 6
)
SELECT
	facility_id,
	months,
	ROUND((avg_xy - avg_x * avg_y) / (SQRT(avg_xx - avg_x * avg_x) * SQRT(avg_yy - avg_y * avg_y)), 3) AS pearson_r
FROM stats
ORDER BY pearson_r DESC;

-- ===========================================================================
-- F. Correlation 2: on-road diesel vs cases shipped, 2025, by facility
-- ===========================================================================
WITH diesel_month AS (
	SELECT
		iad.facility_id,
		iad."month",
		SUM(iad.quantity) AS diesel_gal
	FROM inventory_activity_data iad
	WHERE iad.activity_type = 'diesel_onroad'
	GROUP BY iad.facility_id, iad."month"
),
paired AS (
	SELECT
		dm.facility_id,
		dm.diesel_gal,
		ok.cases_shipped
	FROM diesel_month dm
	JOIN operation_kpi ok
		ON dm.facility_id = ok.facility_id
		AND dm."month" = ok."month"
	WHERE ok.cases_shipped > 0
),
stats AS (
	SELECT
		facility_id,
		COUNT(*) AS months,
		AVG(diesel_gal) AS avg_x,
		AVG(cases_shipped) AS avg_y,
		AVG(diesel_gal * cases_shipped) AS avg_xy,
		AVG(diesel_gal * diesel_gal) AS avg_xx,
		AVG(cases_shipped * 1.0 * cases_shipped) AS avg_yy
	FROM paired
	GROUP BY facility_id
	HAVING COUNT(*) >= 6
)
SELECT
	facility_id,
	months,
	ROUND((avg_xy - avg_x * avg_y) / (SQRT(avg_xx - avg_x * avg_x) * SQRT(avg_yy - avg_y * avg_y)), 3) AS pearson_r
FROM stats
ORDER BY pearson_r DESC;

-- ===========================================================================
-- G. Refrigerant leak rate by facility (lb emitted / installed charge) and its drivers
-- ===========================================================================
WITH emitted AS (
	SELECT
		facility_id,
		SUM(quantity) AS lb_emitted,
		SUM(hfc_co2e_t + memo_hcfc_co2e_t) AS tco2e
	FROM emissions
	WHERE activity_type = 'refrigerant'
	GROUP BY facility_id
),
charge AS (
	SELECT
		facility_id,
		SUM(full_charge_lbs) AS installed_charge_lb,
		ROUND(AVG(2025 - install_year), 1) AS avg_equipment_age_yrs
	FROM refrigeration_equipment
	GROUP BY facility_id
)
SELECT
	c.facility_id,
	ROUND(c.installed_charge_lb, 0) AS installed_charge_lb,
	ROUND(COALESCE(e.lb_emitted, 0), 1) AS lb_emitted,
	ROUND(100.0 * COALESCE(e.lb_emitted, 0) / c.installed_charge_lb, 1) AS leak_rate_pct,
	c.avg_equipment_age_yrs,
	ROUND(COALESCE(e.tco2e, 0), 0) AS tco2e
FROM charge c
LEFT JOIN emitted e
	ON c.facility_id = e.facility_id
ORDER BY leak_rate_pct DESC;

-- Largest single refrigerant months (finds the Chicago July event)
SELECT
	facility_id,
	"month",
	refrigerant,
	ROUND(quantity, 1) AS lb_emitted,
	ROUND(hfc_co2e_t, 0) AS tco2e
FROM emissions
WHERE activity_type = 'refrigerant'
ORDER BY tco2e DESC
LIMIT 5;

-- ===========================================================================
-- H. Market-based vs location-based Scope 2 by facility (effect of RECs and green tariff)
-- ===========================================================================
SELECT
	sm.facility_id,
	ROUND(sm.quantity_mwh, 0) AS mwh,
	ROUND(sm.rec_mwh_capped + sm.green_tariff_mwh, 0) AS zero_emission_mwh,
	ROUND(ft.scope2_location_based_tco2e, 0) AS location_tco2e,
	ROUND(ft.scope2_market_based_tco2e, 0) AS market_tco2e,
	ROUND(ft.scope2_market_based_tco2e - ft.scope2_location_based_tco2e, 0) AS difference_tco2e
FROM scope2_market sm
JOIN facility_totals ft
	ON sm.facility_id = ft.facility_id
ORDER BY difference_tco2e;

-- ===========================================================================
-- I. Lighting retrofit check: PHL and CMH electricity 2025 vs 2024 by month,
--    against the average change at the other distribution centres
-- ===========================================================================
WITH elec AS (
	SELECT facility_id, "month", SUM(quantity) AS kwh
	FROM inventory_activity_data
	WHERE activity_type = 'electricity'
	GROUP BY facility_id, "month"
	UNION ALL
	SELECT facility_id, "month", SUM(quantity)
	FROM base_year_activity
	WHERE activity_type = 'electricity'
	GROUP BY facility_id, "month"
),
yoy AS (
	SELECT
		e25.facility_id,
		SUBSTR(e25."month", 6, 2) AS month_num,
		100.0 * (e25.kwh - e24.kwh) / e24.kwh AS change_pct
	FROM elec e25
	JOIN elec e24
		ON e25.facility_id = e24.facility_id
		AND e24."month" = '2024-' || SUBSTR(e25."month", 6, 2)
	JOIN facility f
		ON e25.facility_id = f.facility_id
	WHERE e25."month" LIKE '2025-%'
		AND f.facility_type = 'Distribution Center'
		AND e25.facility_id NOT IN ('DC-ATL', 'DC-DAL')		-- ATL gap estimate and DAL dock expansion distort the comparison
)
SELECT
	month_num,
	ROUND(AVG(CASE WHEN facility_id IN ('DC-PHL', 'DC-CMH') THEN change_pct END), 1) AS retrofit_sites_change_pct,
	ROUND(AVG(CASE WHEN facility_id NOT IN ('DC-PHL', 'DC-CMH') THEN change_pct END), 1) AS other_dcs_change_pct
FROM yoy
GROUP BY month_num
ORDER BY month_num;

-- ===========================================================================
-- J. Data quality: share of the inventory that is estimated
-- ===========================================================================
SELECT
	ROUND(SUM(CASE WHEN is_estimated = 1 THEN location_based_tco2e ELSE 0 END), 1) AS estimated_tco2e,
	ROUND(SUM(location_based_tco2e), 1) AS total_tco2e,
	ROUND(100.0 * SUM(CASE WHEN is_estimated = 1 THEN location_based_tco2e ELSE 0 END) / SUM(location_based_tco2e), 2) AS estimated_pct
FROM emissions;
