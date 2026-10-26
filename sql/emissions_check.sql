SELECT
	e.facility_id,
	SUM(e.memo_hcfc_co2e_t) AS r22_memo_tco2e
FROM emissions e
WHERE e.memo_hcfc_co2e_t > 0
GROUP BY e.facility_id;

-- SLC base year significance test: is SLC's full-year footprint 5% or more of the 2024 base year?
WITH slc_jan_jun AS (										-- seller's bills, before CCP owned the site (test only, not in the inventory)
	SELECT
		SUM(CASE sub.commodity
			WHEN 'Natural Gas' THEN (sub."usage"*0.1*rsf.co2_kg_per_unit*0.001)+((sub."usage"*0.1*rsf.ch4_g_per_unit*0.000001)*28)+((sub."usage"*0.1*rsf.n2o_g_per_unit*0.000001)*265)
			ELSE (sub."usage"*0.001*rer.co2_lb_per_mwh*0.00045359237)+((sub."usage"*0.001*rer.ch4_lb_per_mwh*0.00045359237)*28)+((sub."usage"*0.001*rer.n2o_lb_per_mwh*0.00045359237)*265)
		END) AS tco2e
	FROM slc_utility_bill sub
	JOIN ref_stationary_factor rsf
		ON rsf.fuel_type = 'natural_gas'
	JOIN ref_egrid_rate rer
		ON rer.egrid_subregion = 'NWPP'
),
slc_jul_dec AS (											-- CCP-owned months, from the inventory
	SELECT
		ft.scope1_tco2e + ft.scope2_location_based_tco2e AS tco2e
	FROM facility_totals ft
	WHERE ft.facility_id = 'XD-SLC'
),
base_year AS (
	SELECT
		SUM(byi.location_based_tco2e) AS tco2e
	FROM base_year_inventory byi
)
SELECT
	ROUND(jj.tco2e, 1) AS slc_jan_jun_tco2e,
	ROUND(jd.tco2e, 1) AS slc_jul_dec_tco2e,
	ROUND(jj.tco2e + jd.tco2e, 1) AS slc_full_year_tco2e,
	ROUND(b.tco2e, 1) AS base_year_2024_tco2e,
	ROUND(100.0*(jj.tco2e + jd.tco2e)/b.tco2e, 2) AS pct_of_base_year,
	CASE
		WHEN (jj.tco2e + jd.tco2e)/b.tco2e >= 0.05 THEN 'Recalculate base year'
		ELSE 'Below 5% threshold: no recalculation'
	END AS result
FROM slc_jan_jun jj
CROSS JOIN slc_jul_dec jd
CROSS JOIN base_year b;