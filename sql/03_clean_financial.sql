-- Clear table before inserting

DELETE FROM financial;

-- ===========================================================================
-- Insert data and logic
-- ===========================================================================

INSERT INTO financial (fiscal_year, net_revenue_usd_millions, employees_fte)
SELECT
	CAST(rcf.fiscal_year AS INTEGER),
	CAST(rcf.net_revenue_usd_millions AS REAL),
	CAST(rcf.employees_fte AS REAL)
FROM raw_company_financials rcf;
