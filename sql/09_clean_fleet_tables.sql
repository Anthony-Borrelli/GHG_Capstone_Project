-- Clear table before inserting

DELETE FROM vehicle;
DELETE FROM fuel_card_assignment;
DELETE FROM fuel_card_transaction;
DELETE FROM mileage_claim;
DELETE FROM telematics_mileage;

-- ===========================================================================
-- Insert data and logic
-- ===========================================================================

INSERT INTO vehicle (unit_number, vin, vehicle_class, fuel_type, model_year, facility_id, ownership, in_service_date, out_of_service_date, current_card_number, telematics, rated_mpg)
SELECT
	rvr.unit_number,
	rvr.vin,
	rvr.vehicle_class,
	rvr.fuel_type,
	rvr.model_year,
	rvr.home_facility_id,
	rvr.ownership,
	rvr.in_service_date,
	rvr.out_of_service_date,
	rvr.fuel_card,
	rvr.telematics,
	rvr.rated_mpg
FROM raw_vehicle_register rvr;

INSERT INTO fuel_card_assignment (card_number, unit_number, assigned_from, assigned_to)
SELECT
	rfca.card_number,
	rfca.unit_number,
	rfca.assigned_from,
	rfca.assigned_to
FROM raw_fuel_card_assignments rfca;

INSERT INTO fuel_card_transaction (transaction_id, card_number, unit_number, transaction_date, transaction_time, post_date, merchant_name, merchant_city, merchant_state, product_description, quantity, uom, unit_price_usd, gross_amount, odometer)
SELECT
	DISTINCT rfct."Transaction ID",
	rfct."Card Number",
	-- ADD in fix
	rfct."Transaction Date",
	rfct."Transaction Time",
	rfct."Post Date",
	rfct."Merchant Name",
	rfct."Merchant City",
	rfct."Merchant State",
	rfct."Product Description",
	rfct.Quantity,
	rfct."Unit of Measure",
	rfct."Unit Price",
	rfct."Gross Amount",
	rfct.Odometer
FROM raw_fuel_card_transactions_2025 rfct
LEFT JOIN raw_fuel_card_assignments rfca
	ON rfct."Card Number" = rfca.card_number
WHERE rfct."Transaction Date" >= rfca.assigned_from AND rfct."Transaction Date" <= rfca.assigned_to 
;

-- [TEMPORARY] Testing start, DELETE AFTER DONE TESTING --------------------------------------

	SELECT COUNT(*)
	FROM (
		SELECT *
		FROM raw_fuel_card_transactions_2025 rfct
		LEFT JOIN raw_fuel_card_assignments rfca 
		ON rfct."Card Number" = rfca.card_number
		AND rfct."Transaction Date" >= rfca.assigned_from 
		AND (rfca.assigned_to = '' OR rfct."Transaction Date" < rfca.assigned_to)
		WHERE rfca.card_number IS NULL
	);
	



-- Testing end -------------------------------------------------------------------------------

INSERT INTO mileage_claim (employee_id, unit_number, month, miles, rate_per_mile)
SELECT
	rlvmc."Employee ID",
	rlvmc."Leased Vehicle Unit",
	rlvmc."Expense Month",
	rlvmc."Business Miles Claimed",
	rlvmc."Reimbursement Rate ($/mi)" 
FROM raw_leased_vehicle_mileage_claims_2025 rlvmc;

INSERT INTO telematics_mileage (unit_number, "month", miles)
SELECT
	rtmm.unit_number,
	rtmm."month",
	rtmm.miles_driven
FROM raw_telematics_monthly_mileage_2024_2025 rtmm;




