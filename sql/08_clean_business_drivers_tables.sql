-- Clear table before inserting

DELETE FROM operation_kpi;
DELETE FROM weather_degree_days;

-- ===========================================================================
-- Insert data and logic
-- ===========================================================================
INSERT INTO weather_degree_days (weather_station_id, month, hdd_65f, cdd_65f)
SELECT
	station_id,
	month,
	hdd_65F,
	cdd_65F
FROM raw_weather_degree_days_2024_2025 rwdd;

INSERT INTO operation_kpi (facility_id, month, cases_shipped, avg_pallet_positions_used, headcount, operating_hours)
SELECT
	f.facility_id,
	romk.Period,
	romk."Cases Shipped",
	romk."Avg Pallet Positions Used",
	romk.Headcount,
	romk."Operating Hours" 
FROM raw_operations_monthly_kpis_2024_2025 romk
LEFT JOIN facility f 
	ON romk."Site #" = f.site_number;