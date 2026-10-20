-- Clear table before inserting

DELETE FROM map_weather_station;
DELETE FROM map_activity_type;
DELETE FROM map_vehicle_class;
DELETE FROM map_fuel_product;
DELETE FROM map_calendar_day;

-- ===========================================================================
-- Insert data and logic
-- ===========================================================================

INSERT INTO map_weather_station (weather_station_id, city, state)
SELECT
	DISTINCT rwdd.station_id,
	rwdd.city ,
	rwdd.state 
FROM raw_weather_degree_days_2024_2025 rwdd;

INSERT INTO map_activity_type (activity_type, fuel_type, scope, source_category)
SELECT
	DISTINCT activity_type,
	CASE activity_type
		WHEN 'natural_gas' 		THEN 'natural_gas'
		WHEN 'diesel_generator' THEN 'distillate_fuel_oil_no2'
		WHEN 'propane_forklift' THEN 'lpg'
		WHEN 'diesel_onroad' 	THEN 'diesel'
		WHEN 'gasoline_onroad' 	THEN 'gasoline'
		WHEN 'diesel_tru' 		THEN 'diesel'
		ELSE activity_type
	END,
	rac.scope,
	rac.source_category 
FROM raw_activity_2024_clean rac
WHERE scope IN ('Scope 1', 'Scope 2'); -- Excludes the R-22 memo rows, R-22 is handled by ref_gwp.is_scope1_included

INSERT INTO map_vehicle_class (vehicle_class, hub_vehicle_category, fuel_type)
SELECT
	DISTINCT vehicle_class,
	CASE vehicle_class
		WHEN 'Sales Car' 		THEN 'Gasoline Passenger Cars'
		WHEN 'Class 8 Tractor' 	THEN 'Medium- and Heavy-Duty Vehicles'
		WHEN 'Box Truck' 		THEN 'Medium- and Heavy-Duty Vehicles'
		WHEN 'Cargo Van' 		THEN 'Gasoline Light-Duty Trucks'
	END,
	LOWER(rvr.fuel_type)
FROM raw_vehicle_register rvr;

INSERT INTO map_fuel_product (product_description, activity_type)
SELECT
	DISTINCT rfct."Product Description" ,
	CASE "Product Description"
		WHEN 'ULSD' 					THEN 'diesel_onroad'
		WHEN 'Diesel Clear' 			THEN 'diesel_onroad'
		WHEN 'REEFER' 					THEN 'diesel_tru'
		WHEN '#2 DIESEL' 				THEN 'diesel_onroad'
		WHEN 'Reefer Dyed' 				THEN 'diesel_tru'
		WHEN 'DSL' 						THEN 'diesel_onroad'
		WHEN 'UNLEADED' 				THEN 'gasoline_onroad'
		WHEN 'Unl Plus' 				THEN 'gasoline_onroad'
		WHEN 'UNL' 						THEN 'gasoline_onroad'
		WHEN 'REG 87' 					THEN 'gasoline_onroad'
		WHEN 'RFR DSL' 					THEN 'diesel_tru'
		WHEN 'ULSD REVERSAL' 			THEN 'diesel_onroad'
		WHEN '#2 DIESEL REVERSAL' 		THEN 'diesel_onroad'
		WHEN 'Diesel Clear REVERSAL' 	THEN 'diesel_onroad'
		WHEN 'DSL REVERSAL' 			THEN 'diesel_onroad'
		WHEN 'DEF'						THEN 'exclude'
		WHEN 'CARWASH'					THEN 'exclude'
		WHEN 'MOTOR OIL'				THEN 'exclude'
		ELSE NULL
	END
FROM raw_fuel_card_transactions_2025 rfct;

INSERT INTO map_calendar_day (calendar_date, month, year)
WITH RECURSIVE calendar(calendar_date) AS (
	SELECT '2025-01-01'
	UNION ALL
	SELECT date(calendar_date, '+1 day')
	FROM calendar
	WHERE calendar_date < '2025-12-31'
)
SELECT
	calendar_date,
	SUBSTR(calendar_date, 1, 7),
	SUBSTR(calendar_date, 1, 4)
FROM calendar;
	
