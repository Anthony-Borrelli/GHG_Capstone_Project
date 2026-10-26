-- Create results views for reporting year 2025's GHG emissions inventory
-- Rerun a clean view each time

DROP VIEW IF EXISTS facility_totals;
DROP VIEW IF EXISTS company_summary;

-- ===========================================================================
-- Create facility totals
-- ===========================================================================
CREATE VIEW facility_totals AS

WITH facility_emissions AS (
	SELECT
		e.facility_id,
		SUM(CASE e."scope"
			WHEN 'Scope 1' THEN e.location_based_tco2e
			ELSE 0
		END) AS scope1_tco2e,
		SUM(CASE e."scope"
			WHEN 'Scope 2' THEN e.location_based_tco2e
			ELSE 0
		END) AS scope2_location_based_tco2e
	FROM emissions e
	GROUP BY e.facility_id 
)
SELECT
	fe.facility_id,
	fe.scope1_tco2e,
	fe.scope2_location_based_tco2e,
	sm.market_based_tco2e AS scope2_market_based_tco2e
FROM facility_emissions fe
LEFT JOIN scope2_market sm
	ON fe.facility_id = sm.facility_id;

-- ===========================================================================
-- Create company summary
-- ===========================================================================
CREATE VIEW company_summary AS
	
WITH location_based AS (
	SELECT
		e.reporting_year,
		e."scope",
		e.source_category,
		SUM(e.location_based_tco2e) AS location_based_tco2e
	FROM emissions e
	GROUP BY e.reporting_year, e."scope", e.source_category
),
market_based AS (
	SELECT
		2025 AS reporting_year,
		'Scope 2' AS scope,
		'Purchased Electricity' AS source_category,
		SUM(sm.market_based_tco2e) AS market_based_tco2e
	FROM scope2_market sm 
)
	SELECT
		lb.reporting_year,
		lb."scope",
		lb.source_category,
		lb.location_based_tco2e,
		CASE lb."scope" 
			WHEN 'Scope 2' THEN mb.market_based_tco2e
			ELSE lb.location_based_tco2e
		END AS market_based_tco2e
	FROM location_based lb
	CROSS JOIN market_based mb
UNION ALL
	SELECT
		2024 AS reporting_year,
		byi."scope",
		byi.source_category,
		SUM(byi.location_based_tco2e) AS location_based_tco2e,
		SUM(byi.market_based_tco2e) AS market_based_tco2e
	FROM base_year_inventory byi
	GROUP BY reporting_year, byi."scope", byi.source_category
	ORDER BY byi."scope", byi.source_category DESC;






