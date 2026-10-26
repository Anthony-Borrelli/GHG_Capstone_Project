-- Create views for reporting year 2025's GHG emissions inventory
-- Rerun a clean view each time

DROP VIEW IF EXISTS emissions;
DROP VIEW IF EXISTS scope2_market;

-- ===========================================================================
-- Create emissions view
-- ===========================================================================
CREATE VIEW emissions AS

WITH natural_gas AS (
	SELECT
		iad.activity_id,
		iad.reporting_year,
		iad.facility_id,
		iad."month",
		iad."scope",
		iad.source_category,
		iad.activity_type,
		iad.quantity,
		iad.uom,
		iad.is_estimated,
		iad.vehicle_class,
		iad.model_year,
		iad.miles,
		iad.refrigerant,
		iad.quantity*rsf.co2_kg_per_unit*0.001 AS co2_t,
		iad.quantity*rsf.ch4_g_per_unit*0.000001 AS ch4_t,
		iad.quantity*rsf.n2o_g_per_unit*0.000001 AS n2o_t,
		0 AS hfc_co2e_t,
		(iad.quantity*rsf.co2_kg_per_unit*0.001)+((iad.quantity*rsf.ch4_g_per_unit*0.000001)*28)+((iad.quantity*rsf.n2o_g_per_unit*0.000001)*265) AS location_based_tco2e,
		0 AS memo_hcfc_co2e_t
	FROM inventory_activity_data iad
	LEFT JOIN map_activity_type mat
		ON iad.activity_type = mat.activity_type
	LEFT JOIN ref_stationary_factor rsf
		ON mat.fuel_type = rsf.fuel_type
	WHERE iad.activity_type = 'natural_gas'
),
generator AS (
	SELECT
		iad.activity_id,
		iad.reporting_year,
		iad.facility_id,
		iad."month",
		iad."scope",
		iad.source_category,
		iad.activity_type,
		iad.quantity,
		iad.uom,
		iad.is_estimated,
		iad.vehicle_class,
		iad.model_year,
		iad.miles,
		iad.refrigerant,
		iad.quantity*rsf.co2_kg_per_unit*0.001 AS co2_t,
		iad.quantity*rsf.ch4_g_per_unit*0.000001 AS ch4_t,
		iad.quantity*rsf.n2o_g_per_unit*0.000001 AS n2o_t,
		0 AS hfc_co2e_t,
		(iad.quantity*rsf.co2_kg_per_unit*0.001)+((iad.quantity*rsf.ch4_g_per_unit*0.000001)*28)+((iad.quantity*rsf.n2o_g_per_unit*0.000001)*265) AS location_based_tco2e,
		0 AS memo_hcfc_co2e_t
	FROM inventory_activity_data iad
	LEFT JOIN map_activity_type mat
		ON iad.activity_type = mat.activity_type
	LEFT JOIN ref_stationary_factor rsf
		ON mat.fuel_type = rsf.fuel_type
	WHERE iad.activity_type = 'diesel_generator'
),
on_road AS(
	SELECT
		iad.activity_id,
		iad.reporting_year,
		iad.facility_id,
		iad."month",
		iad."scope",
		iad.source_category,
		iad.activity_type,
		iad.quantity,
		iad.uom,
		iad.is_estimated,
		iad.vehicle_class,
		iad.model_year,
		iad.miles,
		iad.refrigerant,
		iad.quantity*rmc.co2_kg_per_gal*0.001 AS co2_t,
		iad.miles*rmcnoo.ch4_g_per_mile*0.000001 AS ch4_t,
		iad.miles*rmcnoo.n2o_g_per_mile*0.000001 AS n2o_t,
		0 AS hfc_co2e_t,
		(iad.quantity*rmc.co2_kg_per_gal*0.001)+((iad.miles*rmcnoo.ch4_g_per_mile*0.000001)*28)+((iad.miles*rmcnoo.n2o_g_per_mile*0.000001)*265) AS location_based_tco2e,
		0 AS memo_hcfc_co2e_t
	FROM inventory_activity_data iad
	LEFT JOIN map_activity_type mat
		ON iad.activity_type = mat.activity_type
	LEFT JOIN ref_mobile_co2 rmc 
		ON mat.fuel_type = rmc.fuel_type
	LEFT JOIN map_vehicle_class mvc
		ON iad.vehicle_class = mvc.vehicle_class
	LEFT JOIN ref_mobile_ch4_n2o_onroad rmcnoo
		ON mvc.hub_vehicle_category = rmcnoo.vehicle_class
		AND iad.model_year BETWEEN rmcnoo.model_year_start AND rmcnoo.model_year_end 
	WHERE iad.activity_type IN ('diesel_onroad', 'gasoline_onroad')
),
non_road AS (
	SELECT
		iad.activity_id,
		iad.reporting_year,
		iad.facility_id,
		iad."month",
		iad."scope",
		iad.source_category,
		iad.activity_type,
		iad.quantity,
		iad.uom,
		iad.is_estimated,
		iad.vehicle_class,
		iad.model_year,
		iad.miles,
		iad.refrigerant,
		iad.quantity*rmc.co2_kg_per_gal*0.001 AS co2_t,
		iad.quantity*rmcnon.ch4_g_per_gal*0.000001 AS ch4_t,
		iad.quantity*rmcnon.n2o_g_per_gal*0.000001 AS n2o_t,
		0 AS hfc_co2e_t,
		(iad.quantity*rmc.co2_kg_per_gal*0.001)+((iad.quantity*rmcnon.ch4_g_per_gal*0.000001)*28)+((iad.quantity*rmcnon.n2o_g_per_gal*0.000001)*265) AS location_based_tco2e,
		0 AS memo_hcfc_co2e_t
	FROM inventory_activity_data iad
	LEFT JOIN map_activity_type mat
		ON iad.activity_type = mat.activity_type
	LEFT JOIN ref_mobile_co2 rmc 
		ON mat.fuel_type = rmc.fuel_type
	LEFT JOIN ref_mobile_ch4_n2o_nonroad rmcnon
		ON mat.activity_type = rmcnon.equipment_type
	WHERE iad.activity_type IN ('diesel_tru', 'propane_forklift')
),
refrigerant AS (
	SELECT
		iad.activity_id,
		iad.reporting_year,
		iad.facility_id,
		iad."month",
		iad."scope",
		iad.source_category,
		iad.activity_type,
		iad.quantity,
		iad.uom,
		iad.is_estimated,
		iad.vehicle_class,
		iad.model_year,
		iad.miles,
		iad.refrigerant,
		0 AS co2_t,
		0 AS ch4_t,
		0 AS n2o_t,
		CASE rg.is_scope1_included
			WHEN 1 THEN iad.quantity*ruc.factor*rg.gwp
			ELSE 0
		END AS hfc_co2e_t,
		CASE rg.is_scope1_included
			WHEN 1 THEN iad.quantity*ruc.factor*rg.gwp
			ELSE 0
		END AS location_based_tco2e,
		CASE rg.is_scope1_included
			WHEN 0 THEN iad.quantity*ruc.factor*rg.gwp
			ELSE 0
		END AS memo_hcfc_co2e_t
	FROM inventory_activity_data iad
	LEFT JOIN ref_unit_conversion ruc
		ON iad.uom = ruc.from_unit
		AND ruc.to_unit = 'metric_ton'
	LEFT JOIN ref_gwp rg
		ON iad.refrigerant = rg.gas
	WHERE iad.activity_type = 'refrigerant'
),
electricity AS (
	SELECT
		iad.activity_id,
		iad.reporting_year,
		iad.facility_id,
		iad."month",
		iad."scope",
		iad.source_category,
		iad.activity_type,
		iad.quantity,
		iad.uom,
		iad.is_estimated,
		iad.vehicle_class,
		iad.model_year,
		iad.miles,
		iad.refrigerant,
		iad.quantity*0.001*rer.co2_lb_per_mwh*ruc.factor AS co2_t,
		iad.quantity*0.001*rer.ch4_lb_per_mwh*ruc.factor AS ch4_t,
		iad.quantity*0.001*rer.n2o_lb_per_mwh*ruc.factor AS n2o_t,
		0 AS hfc_co2e_t,
		(iad.quantity*0.001*rer.co2_lb_per_mwh*ruc.factor)+((iad.quantity*0.001*rer.ch4_lb_per_mwh*ruc.factor)*28)+((iad.quantity*0.001*rer.n2o_lb_per_mwh*ruc.factor)*265) AS location_based_tco2e,
		0 AS memo_hcfc_co2e_t
	FROM inventory_activity_data iad
	LEFT JOIN facility f
		ON iad.facility_id = f.facility_id
	LEFT JOIN ref_egrid_rate rer
		ON f.egrid_subregion = rer.egrid_subregion
	LEFT JOIN ref_unit_conversion ruc
		ON ruc.from_unit = 'lb'
		AND ruc.to_unit = 'metric_ton'
	WHERE iad.activity_type = 'electricity'
)
SELECT * FROM natural_gas
UNION ALL
SELECT * FROM generator 
UNION ALL
SELECT * FROM on_road
UNION ALL
SELECT * FROM non_road
UNION ALL
SELECT * FROM refrigerant
UNION ALL
SELECT * FROM electricity;

-- ===========================================================================
-- Create market based emissions view
-- ===========================================================================
CREATE VIEW scope2_market AS

WITH mwh_per_facility AS (
	SELECT
		iad.facility_id,
		SUM(iad.quantity*0.001) AS quantity_mwh
	FROM inventory_activity_data iad
	WHERE iad.activity_type = 'electricity'
	GROUP BY iad.facility_id 
),
rec_per_facility AS (
	SELECT
		rr.facility_id,
		SUM(rr.mwh) AS rec_mwh
	FROM rec_retirement rr 
	WHERE rr.vintage_year = 2025
	GROUP BY rr.facility_id
),
green_tariff_per_facility AS (
	SELECT
		mu.facility_id,
		MAX(vc.renewable_choice_enrollment) as enrollment -- all values are the same, used to group by
	FROM valley_consumption vc
	JOIN map_utility mu
		ON vc.account_number = mu.account_number
	GROUP BY mu.facility_id 
),
coverage AS (
	SELECT
		mpf.facility_id,
		mpf.quantity_mwh,
		COALESCE(rpf.rec_mwh, 0) AS rec_mwh,
		COALESCE(gpf.enrollment, 0) AS enrollment
	FROM mwh_per_facility mpf
	LEFT JOIN rec_per_facility rpf
		ON mpf.facility_id = rpf.facility_id
	LEFT JOIN green_tariff_per_facility gpf
		ON mpf.facility_id = gpf.facility_id
),
coverage_calc AS (
	SELECT
		c.facility_id,
		c.quantity_mwh,
		MIN(c.rec_mwh, c.quantity_mwh) AS rec_mwh_capped, -- facility cannot claim more RECs than MWh used
		c.quantity_mwh*c.enrollment AS green_tariff_mwh,
		c.quantity_mwh - MIN(c.rec_mwh, c.quantity_mwh) - (c.quantity_mwh*c.enrollment) AS uncovered_mwh
	FROM coverage c
),
supplier_rate AS (
	SELECT DISTINCT
		mu.facility_id,
		ser.co2_lb_per_mwh
	FROM map_utility mu
	JOIN supplier_emission_rate ser
		ON mu.utility_name = ser.utility_name
		AND ser.product = 'Standard Service Mix' 		-- tariffs renewable product is already counted as zero in green_tariff_mwh
	WHERE mu.commodity = 'Electricity'
),
market_emissions AS (
	SELECT
		cc.facility_id,
		cc.quantity_mwh,
		cc.rec_mwh_capped,
		cc.green_tariff_mwh,
		cc.uncovered_mwh,
		COALESCE(sr.co2_lb_per_mwh, rrm.co2_lb_per_mwh) AS co2_rate_lb_per_mwh, -- supplier rate if published otherwise residual mix
		cc.uncovered_mwh*COALESCE(sr.co2_lb_per_mwh, rrm.co2_lb_per_mwh)*ruc.factor AS co2_t,
		cc.uncovered_mwh*rer.ch4_lb_per_mwh*ruc.factor AS ch4_t,				-- residual mix is co2 only, ch4 and n2o use egrid
		cc.uncovered_mwh*rer.n2o_lb_per_mwh*ruc.factor AS n2o_t
	FROM coverage_calc cc
	JOIN facility f
		ON cc.facility_id = f.facility_id 
	LEFT JOIN supplier_rate sr
		ON cc.facility_id = sr.facility_id
	LEFT JOIN ref_residual_mix rrm
		ON f.egrid_subregion = rrm.egrid_subregion
	LEFT JOIN ref_egrid_rate rer
		ON f.egrid_subregion = rer.egrid_subregion
	LEFT JOIN ref_unit_conversion ruc
		ON ruc.from_unit = 'lb'
		AND ruc.to_unit = 'metric_ton'
)
SELECT
	me.*,
	me.co2_t + (me.ch4_t*28) + (me.n2o_t*265) AS market_based_tco2e
FROM market_emissions me;
