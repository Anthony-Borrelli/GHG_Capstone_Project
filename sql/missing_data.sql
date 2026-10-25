-- ===========================================================================
-- Find days in 2025 that no utility bill covers, for every meter
-- Result: one row per meter per month with missing days
-- ===========================================================================
WITH meters AS (                                    -- every meter that has at least one bill
	SELECT DISTINCT
		ub.facility_id,
		ub.account_number,
		ub.meter_number,
		ub.commodity
	FROM utility_bill ub
),
meter_days AS (                                     -- every meter paired with every day of 2025
	SELECT
		m.facility_id,
		m.account_number,
		m.meter_number,
		m.commodity,
		mcd.calendar_date,
		mcd."month"
	FROM meters m
	CROSS JOIN map_calendar_day mcd
),
missing_days AS (                                   -- keep the days no bill covers
	SELECT
		md.*
	FROM meter_days md
	LEFT JOIN utility_bill ub
		ON  ub.account_number = md.account_number
		AND ub.meter_number   = md.meter_number
		AND ub.commodity      = md.commodity
		AND md.calendar_date BETWEEN ub.service_start_date AND ub.service_end_date
	WHERE ub.utility_bill_id IS NULL
)
SELECT
	facility_id,
	account_number,
	meter_number,
	commodity,
	"month",
	MIN(calendar_date) AS first_missing_day,
	MAX(calendar_date) AS last_missing_day,
	COUNT(*)           AS missing_days
FROM missing_days
GROUP BY facility_id, account_number, meter_number, commodity, "month"
ORDER BY facility_id, commodity, meter_number, "month";