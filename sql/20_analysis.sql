-- ===========================================================================
-- Headline KPIs, totals and intensity 2025 vs 2024
-- ===========================================================================
WITH company_emissions AS (
SELECT
	cs.reporting_year,
	SUM(CASE cs."scope" 
		WHEN 'Scope 1' THEN cs.location_based_tco2e 
	END) AS scope1_tco2e,
	SUM(CASE cs."scope"
		WHEN 'Scope 2' THEN cs.location_based_tco2e
	END) AS scope2_location_tco2e,
	SUM(CASE cs."scope" 
		WHEN 'Scope 2' THEN cs.market_based_tco2e
	END) AS scope2_market_tco2e
FROM company_summary cs
GROUP BY cs.reporting_year
),
cases AS (
	SELECT
		CAST(SUBSTR(ok."month", 1, 4) AS INTEGER) AS reporting_year,
		SUM(ok.cases_shipped) AS cases_shipped
	FROM operation_kpi ok
	GROUP BY reporting_year
)
SELECT
	ce.reporting_year,
	ROUND(ce.scope1_tco2e, 0) AS scope1_tco2e,
	ROUND(ce.scope2_location_tco2e, 0) AS scope2_location_tco2e,
	ROUND(ce.scope2_market_tco2e, 0) AS scope2_market_tco2e,
	ROUND(ce.scope1_tco2e + ce.scope2_location_tco2e) AS scope1_2_location_tco2e,
	ROUND(ce.scope1_tco2e + ce.scope2_market_tco2e, 0) AS scope1_2_market_tco2e,
	ROUND((ce.scope1_tco2e + ce.scope2_location_tco2e)/f.net_revenue_usd_millions, 2) AS location_tco2e_per_usd_millions,
	ROUND((ce.scope1_tco2e + ce.scope2_market_tco2e)/f.net_revenue_usd_millions, 2) AS market_tco2e_per_usd_millions,
	ROUND((ce.scope1_tco2e + ce.scope2_location_tco2e)/(c.cases_shipped/1000.0), 3) AS location_tco2e_per_1000_cases,
	ROUND((ce.scope1_tco2e + ce.scope2_market_tco2e)/(c.cases_shipped/1000.0), 3) AS market_tco2e_per_1000_cases
FROM company_emissions ce
LEFT JOIN financial f
	ON ce.reporting_year = f.fiscal_year
LEFT JOIN cases c
	ON ce.reporting_year = c.reporting_year;

-- ===========================================================================
-- Year-over-year change by source (location-based)
-- ===========================================================================
SELECT
	cs25.source_category,
	ROUND(cs24.location_based_tco2e, 0) AS tco2e_2024,
	ROUND(cs25.location_based_tco2e, 0) AS tco2e_2025,
	ROUND(cs25.location_based_tco2e - cs24.location_based_tco2e, 0) AS change_tco2e,
	ROUND(((cs25.location_based_tco2e - cs24.location_based_tco2e)/cs24.location_based_tco2e)*100.0, 1) AS change_pct
FROM company_summary cs25
JOIN company_summary cs24
	ON cs25.source_category = cs24.source_category
	AND cs24.reporting_year = 2024
WHERE cs25.reporting_year = 2025
ORDER BY change_tco2e DESC;

-- ===========================================================================
-- Facility ranking, total emissions and intensity (per sqft, per 1000 cases)
-- ===========================================================================
WITH cases_2025 AS (
	SELECT
		ok.facility_id,
		SUM(ok.cases_shipped) AS cases_shipped
	FROM operation_kpi ok 
	WHERE ok."month" LIKE '2025-%'
	GROUP BY facility_id
)
SELECT
	ft.facility_id,
	f.facility_type,
	ROUND(ft.scope1_tco2e + ft.scope2_location_based_tco2e, 0) AS total_location_tco2e,
	ROUND(ft.scope1_tco2e + ft.scope2_market_based_tco2e, 0) AS total_market_tco2e,
	ROUND(((ft.scope1_tco2e + ft.scope2_location_based_tco2e)/f.sqft)*1000.0, 2) AS kgco2e_per_sqft,
	CASE 
		WHEN c.cases_shipped > 0 THEN ROUND((ft.scope1_tco2e + ft.scope2_location_based_tco2e)/(c.cases_shipped/1000.0), 3)
	END AS tco2e_per_1000_cases
FROM facility_totals ft 
JOIN facility f 
	ON ft.facility_id = f.facility_id
LEFT JOIN cases_2025 c
	ON ft.facility_id = c.facility_id
ORDER BY total_location_tco2e DESC;

-- ===========================================================================
-- Monthly trend by source category 2025 (does not include generators as it is annual)
-- ===========================================================================
SELECT
	e."month",
	e.source_category,
	ROUND(SUM(e.location_based_tco2e), 1) AS tco2e
FROM emissions e 
WHERE e."month" IS NOT NULL
GROUP BY e."month", e.source_category
ORDER BY e."month";

-- ===========================================================================
-- Correlation natural gas vs heating degree days (HDD) by facility 2025
-- Pearson r = covariance / (std dev x * std dev y) built from AVG
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
		gm.facility_id,
		COUNT(*) AS months,
		AVG(gm.gas_mmbtu) AS avg_x,
		AVG(gm.hdd_65f) AS avg_y,
		AVG(gm.gas_mmbtu * gm.hdd_65f) AS avg_xy,
		AVG(gm.gas_mmbtu * gm.gas_mmbtu) AS avg_xx,
		AVG(gm.hdd_65f * gm.hdd_65f) AS avg_yy
	FROM gas_month gm
	GROUP BY gm.facility_id
	HAVING COUNT(*) >= 6 							-- ensure there are enough data points for valuable correlation
)
SELECT
	s.facility_id,
	s.months,
	ROUND((s.avg_xy - s.avg_x * s.avg_y)/(SQRT(s.avg_xx -s.avg_x * s.avg_x)*SQRT(s.avg_yy - s.avg_y * s.avg_y)), 3) AS pearson_r
FROM stats s
ORDER BY pearson_r DESC;

-- ===========================================================================
-- Correlation on-road diesel vs cases shipped by facility 2025
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
		p.facility_id,
		COUNT(*) AS months,
		AVG(p.diesel_gal) AS avg_x,
		AVG(p.cases_shipped) AS avg_y,
		AVG(p.diesel_gal * p.cases_shipped) AS avg_xy,
		AVG(p.diesel_gal * p.diesel_gal) AS avg_xx,
		AVG(p.cases_shipped *1.0* p.cases_shipped) AS avg_yy	-- cases_shipped are integers so 1.0 added for decimal arithmetics
	FROM paired p
	GROUP BY p.facility_id
	HAVING COUNT(*) >= 6 							-- ensure there are enough data points for valuable correlation
)
SELECT
	s.facility_id,
	s.months,
	ROUND((s.avg_xy - s.avg_x * s.avg_y)/(SQRT(s.avg_xx -s.avg_x * s.avg_x)*SQRT(s.avg_yy - s.avg_y * s.avg_y)), 3) AS pearson_r
FROM stats s
ORDER BY pearson_r DESC;

-- ===========================================================================
-- Correlation electricity vs cooling degree days (CDD) by facility 2025
-- ===========================================================================
WITH electricity_month AS (
	SELECT
		iad.facility_id,
		iad."month",
		SUM(iad.quantity) AS electricity_kwh,
		wdd.cdd_65f 
	FROM inventory_activity_data iad
	JOIN facility f
		ON iad.facility_id = f.facility_id
	JOIN weather_degree_days wdd
		ON f.weather_station_id = wdd.weather_station_id
		AND iad."month" = wdd."month"
	WHERE iad.activity_type = 'electricity'
		AND iad.facility_id NOT IN ('SO-BOS')			-- Boston electricity estimated with identical months so 0 correlation
	GROUP BY iad.facility_id, iad."month", wdd.cdd_65f 
),
stats AS (
	SELECT
		em.facility_id,
		COUNT(*) AS months,
		AVG(em.electricity_kwh) AS avg_x,
		AVG(em.cdd_65f) AS avg_y,
		AVG(em.electricity_kwh * em.cdd_65f) AS avg_xy,
		AVG(em.electricity_kwh * em.electricity_kwh) AS avg_xx,
		AVG(em.cdd_65f * em.cdd_65f) AS avg_yy
	FROM electricity_month em
	GROUP BY em.facility_id
	HAVING COUNT(*) >= 6 							-- ensure there are enough data points for valuable correlation
)
SELECT
	s.facility_id,
	s.months,
	ROUND((s.avg_xy - s.avg_x * s.avg_y)/(SQRT(s.avg_xx -s.avg_x * s.avg_x)*SQRT(s.avg_yy - s.avg_y * s.avg_y)), 3) AS pearson_r
FROM stats s
ORDER BY pearson_r DESC;

-- ===========================================================================
-- Correlation electricity vs cases shipped by facility 2025
-- ===========================================================================
WITH electricity_month AS (
	SELECT
		iad.facility_id,
		iad."month",
		SUM(iad.quantity) AS electricity_kwh
	FROM inventory_activity_data iad 
	WHERE iad.activity_type = 'electricity'
		AND iad.facility_id NOT IN ('SO-BOS')			-- Boston electricity estimated with identical months so 0 correlation
	GROUP BY iad.facility_id, iad."month" 
),
paired AS (
	SELECT
		em.facility_id,
		em.electricity_kwh,
		ok.cases_shipped 
	FROM electricity_month em
	JOIN operation_kpi ok
		ON em.facility_id = ok.facility_id 
		AND em."month" = ok."month" 
	WHERE ok.cases_shipped > 0
),
stats AS (
	SELECT
		p.facility_id,
		COUNT(*) AS months,
		AVG(p.electricity_kwh) AS avg_x,
		AVG(p.cases_shipped) AS avg_y,
		AVG(p.electricity_kwh * p.cases_shipped) AS avg_xy,
		AVG(p.electricity_kwh * p.electricity_kwh) AS avg_xx,
		AVG(p.cases_shipped *1.0* p.cases_shipped) AS avg_yy	-- cases_shipped are integers so 1.0 added for decimal arithmetics
	FROM paired p
	GROUP BY p.facility_id
	HAVING COUNT(*) >= 6 							-- ensure there are enough data points for valuable correlation
)
SELECT
	s.facility_id,
	s.months,
	ROUND((s.avg_xy - s.avg_x * s.avg_y)/(SQRT(s.avg_xx -s.avg_x * s.avg_x)*SQRT(s.avg_yy - s.avg_y * s.avg_y)), 3) AS pearson_r
FROM stats s
ORDER BY pearson_r DESC;

-- ===========================================================================
-- Regression: electricity explained by cooling degree days (CDD) and cases shipped, by facility 2025
-- electricity = b0 + b1 * CDD + b2 * cases
-- ===========================================================================
WITH electricity_month AS (
	SELECT
		iad.facility_id,
		iad."month",
		SUM(iad.quantity) AS y_kwh,							-- y: what we are explaining
		wdd.cdd_65f AS x1_cdd,								-- x1: weather
		ok.cases_shipped * 1.0 AS x2_cases					-- x2: business volume (1.0 for decimal arithmetic)
	FROM inventory_activity_data iad
	JOIN facility f
		ON iad.facility_id = f.facility_id
	JOIN weather_degree_days wdd
		ON f.weather_station_id = wdd.weather_station_id
		AND iad."month" = wdd."month"
	JOIN operation_kpi ok
		ON iad.facility_id = ok.facility_id
		AND iad."month" = ok."month"
	WHERE iad.activity_type = 'electricity'
		AND ok.cases_shipped > 0							-- also drops HQ and SO-BOS, which ship no cases
	GROUP BY iad.facility_id, iad."month", wdd.cdd_65f, ok.cases_shipped
),
stats AS (												-- covariances: AVG(a*b) - AVG(a)*AVG(b)
	SELECT
		em.facility_id,
		COUNT(*) AS months,
		AVG(em.x1_cdd * em.x1_cdd)     - AVG(em.x1_cdd)   * AVG(em.x1_cdd)   AS s11,
		AVG(em.x2_cases * em.x2_cases) - AVG(em.x2_cases) * AVG(em.x2_cases) AS s22,
		AVG(em.x1_cdd * em.x2_cases)   - AVG(em.x1_cdd)   * AVG(em.x2_cases) AS s12,
		AVG(em.x1_cdd * em.y_kwh)      - AVG(em.x1_cdd)   * AVG(em.y_kwh)    AS s1y,
		AVG(em.x2_cases * em.y_kwh)    - AVG(em.x2_cases) * AVG(em.y_kwh)    AS s2y,
		AVG(em.y_kwh * em.y_kwh)       - AVG(em.y_kwh)    * AVG(em.y_kwh)    AS syy
	FROM electricity_month em
	GROUP BY em.facility_id
	HAVING COUNT(*) >= 6								-- enough months for a meaningful fit
),
coefficients AS (
	SELECT
		s.*,
		(s.s1y * s.s22 - s.s2y * s.s12) / (s.s11 * s.s22 - s.s12 * s.s12) AS b1_kwh_per_cdd,
		(s.s2y * s.s11 - s.s1y * s.s12) / (s.s11 * s.s22 - s.s12 * s.s12) AS b2_kwh_per_case
	FROM stats s
)
SELECT
	c.facility_id,
	c.months,
	ROUND(c.b1_kwh_per_cdd, 0) AS kwh_per_cdd,
	ROUND(c.b2_kwh_per_case, 3) AS kwh_per_case,
	ROUND((c.b1_kwh_per_cdd * c.s1y + c.b2_kwh_per_case * c.s2y) / c.syy, 3) AS r_squared_both,
	ROUND((c.s1y * c.s1y) / (c.s11 * c.syy), 3) AS r_squared_cdd_only,
	ROUND(c.s12 / SQRT(c.s11 * c.s22), 2) AS r_cdd_vs_cases		-- check the two drivers are not tangled
FROM coefficients c
ORDER BY r_squared_both DESC;

-- ===========================================================================
-- Refrigerant leak rate by facility (lb emitted / installed charge)
-- ===========================================================================
WITH emitted AS (
	SELECT
		e.facility_id,
		SUM(e.quantity) AS lb_emitted,
		SUM(e.hfc_co2e_t + e.memo_hcfc_co2e_t) AS tco2e
	FROM emissions e 
	WHERE e.activity_type = 'refrigerant'
	GROUP BY e.facility_id
),
charge AS (
	SELECT
		re.facility_id,
		SUM(re.full_charge_lbs) AS installed_charge_lb,
		ROUND(AVG(2025 - re.install_year), 1) AS avg_equipment_age_yrs
	FROM refrigeration_equipment re 
	GROUP BY re.facility_id 
)
SELECT
	c.facility_id,
	ROUND(c.installed_charge_lb, 0) AS installed_charge_lb,
	ROUND(COALESCE(e.lb_emitted, 0), 1) AS lb_emitted,
	ROUND((COALESCE(e.lb_emitted, 0) / c.installed_charge_lb)*100.0, 1) AS leak_rate_pct,
	c.avg_equipment_age_yrs,
	ROUND(COALESCE(e.tco2e, 0), 0) AS tco2e
FROM charge c
LEFT JOIN emitted e
	ON c.facility_id = e.facility_id 
ORDER BY leak_rate_pct DESC;

-- Find largest single refrigerant month (Chicago July refrigeration leak event)
SELECT
	e.facility_id,
	e."month",
	e.refrigerant,
	ROUND(e.quantity, 1) AS lb_emitted,
	ROUND(e.hfc_co2e_t, 0) AS tco2e
FROM emissions e
WHERE e.activity_type = 'refrigerant'
ORDER BY tco2e DESC
LIMIT 5;

-- ===========================================================================
-- Market-based vs location-based scope 2 by facility (effects of REC and green tariff)
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
-- Lighting retrofit check, PHL and CMH electricity by month 2025 vs 2024
-- against the average change at the other distribution centres
-- ===========================================================================
WITH elec AS (
		SELECT
			iad.facility_id,
			iad."month",
			SUM(iad.quantity) AS kwh
		FROM inventory_activity_data iad
		WHERE iad.activity_type = 'electricity'
		GROUP BY iad.facility_id , iad."month" 
	UNION ALL
		SELECT
			bya.facility_id,
			bya."month",
			SUM(bya.quantity) AS kwh
		FROM base_year_activity bya 
		WHERE bya.activity_type = 'electricity'
		GROUP BY bya.facility_id, bya."month"
),
yoy AS (
	SELECT
		e25.facility_id,
		SUBSTR(e25."month", 6, 2) AS month_num,
		(((e25.kwh - e24.kwh)/e24.kwh)*100.0) AS change_pct
	FROM elec e25
	JOIN elec e24
		ON e25.facility_id = e24.facility_id
		AND e24."month" = '2024-' || SUBSTR(e25."month", 6, 2)
	JOIN facility f
		ON e25.facility_id = f.facility_id
	WHERE e25."month" LIKE '2025-%'
		AND f.facility_type = 'Distribution Center'
		AND e25.facility_id NOT IN ('DC-ATL', 'DC-DAL')					-- ATL gap estimate and DAL dock expansion distort comparison
)
SELECT
	y.month_num,
	ROUND(AVG(CASE
		WHEN y.facility_id IN ('DC-PHL', 'DC-CMH') 		THEN y.change_pct  
	END), 1) AS retrofit_sites_change_pct,
	ROUND(AVG(CASE
		WHEN y.facility_id NOT IN ('DC-PHL', 'DC-CMH') 	THEN y.change_pct  
	END), 1) AS other_dcs_change_pct
FROM yoy y
GROUP BY y.month_num
ORDER BY y.month_num;

-- ===========================================================================
-- Data quality, share of the inventory that is estimated
-- ===========================================================================
SELECT
	ROUND(SUM(CASE
		WHEN e.is_estimated = 1 THEN e.location_based_tco2e 
		ELSE 0
	END), 1) AS estimated_tco2e,
	ROUND(SUM(e.location_based_tco2e), 1) AS total_tco2e,
	ROUND((SUM(CASE
		WHEN e.is_estimated = 1 THEN e.location_based_tco2e 
		ELSE 0
	END)/SUM(e.location_based_tco2e))*100.0, 2) AS estimated_pct
FROM emissions e;











