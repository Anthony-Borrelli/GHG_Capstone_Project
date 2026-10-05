# Cobalt Creek Provisions: 2025 GHG Inventory Dataset

> **Synthetic data.** Cobalt Creek Provisions, Inc. is a fictional company. All facilities, utilities, vendors, accounts and figures were generated for a learning and portfolio project. The emission factors you'll apply come from real public sources (listed below). The data is modelled on real Scope 1 and 2 inventory engagements, but none of it comes from a real client.

## 1. Client brief

Cobalt Creek Provisions, Inc. (CCP) is a US foodservice distributor with $3.05B in net revenue for FY2025. It runs refrigerated distribution centers, smaller ambient cross-docks, a corporate head office and one sales office. Its private fleet of tractors, box trucks and vans delivers to restaurants, hospitals and schools.

CCP's sustainability team wants its **FY2025 (calendar year) Scope 1 and Scope 2 GHG inventory**, prepared under the GHG Protocol Corporate Standard, at both facility and company level. Scope 2 should be reported both location-based and market-based. The team also wants performance KPIs and recommendations for the leadership team.

A prior consultant already completed the **2024 base year**. It is provided clean and fully calculated in `base_year_2024/`. It doesn't need to be redone. Use it for year-over-year comparison, KPI trends and anything else it helps with.

### Things the client told you at kickoff

- **Organizational boundary:** operational control.
- **Salt Lake City cross-dock (XD-SLC):** acquired from Beehive Logistics LLC on July 1, 2025. The seller sent over its January to June 2025 utility bills.
- **Albany cross-dock (XD-ALB):** operations wound down in September 2025. The lease ended October 31, 2025.
- **Boston sales office (SO-BOS):** gross lease, so the landlord pays utilities and CCP never sees a bill.
- **Base year recalculation policy:** recalculate the base year if a structural change shifts base-year emissions by 5% or more.
- **Dallas DC:** replaced its oldest refrigeration rack in August 2025, and added a dock expansion with its own electric service in April 2025.
- **Chicago DC:** had a major refrigeration leak in July 2025 and ran on its emergency generator during a storm outage the same month.
- **Market-based Scope 2:** CCP retired unbundled RECs for several sites and is enrolled in a utility green tariff in Sacramento.
- **CO2e:** the company reports with IPCC AR5 100-year GWPs.
- **Data sources:** the data comes from several systems (a bill-payment service, an energy management platform, a fuel card provider, two refrigeration contractors and others). It hasn't been reviewed for quality.

## 2. Folder contents

```
base_year_2024/              Clean, already calculated. Do not rework.
  activity_2024_clean.csv        Monthly electricity and gas by facility; annual totals for all other sources
  inventory_2024_results.csv     2024 results by facility and source (location and market based)

raw_2025/                    Raw exports as received. Expect to clean these.
  facilities/
    facility_register.csv                       Real estate team's facility list
  utilities/
    utility_account_map.csv                     Accounts and meters to facilities (maintained by AP)
    utilitypay_bill_export_2025.csv             Bill-payment service export (many utilities, several commodities)
    energyhub_consumption_export.csv            Energy management platform export (5 sites)
    valley_mud_annual_usage_statement_2025.csv  Sacramento electric utility annual statement
    mesa_gas_billing_history.csv                Gas utility billing history (3 sites)
    midwest_gas_marketing_supply_invoices_chicago.csv   Chicago gas supply invoices from marketer
    slc_seller_utility_bills_jan_jun_2025.csv   Bills supplied by the seller of the SLC site
  fleet/
    vehicle_register.csv
    fuel_card_assignments.csv
    fuel_card_transactions_2025.csv
    telematics_monthly_mileage_2024_2025.csv
    leased_vehicle_mileage_claims_2025.csv
  refrigerants/
    refrigeration_equipment_inventory.csv
    polar_mechanical_service_log_2025.csv
    arcticair_refrigeration_service_log_2025.csv
  stationary/
    emergency_generator_fuel_log_2025.csv
    propane_deliveries_2025.csv                 Forklift propane
  market_instruments/
    rec_retirements_2025.csv
    supplier_specific_emission_rates.csv
  business_drivers/
    weather_degree_days_2024_2025.csv           Monthly HDD/CDD by weather station (synthetic)
    operations_monthly_kpis_2024_2025.csv       Cases shipped, pallets, headcount, hours by site number
    company_financials.csv

answer_key/                  Expected results. Read the README in there before opening anything else.
```

## 3. Reference data you source yourself

These are real public datasets. Download them, load them as tables and cite them in your repo.

| Need | Source |
|---|---|
| Stationary and mobile combustion factors, eGRID rates, GWPs | EPA GHG Emission Factors Hub (2025 edition) |
| ZIP code to eGRID subregion lookup | EPA Power Profiler ZIP code lookup file (eGRID2023) |
| Market-based residual mix | Green-e Residual Mix Emissions Rates (2025, 2023 data) |
| Estimating an unbilled office | EIA Commercial Buildings Energy Consumption Survey (CBECS 2018) |
| Method guidance | GHG Protocol Corporate Standard and Scope 2 Guidance |

The 2024 base year was restated using the **2025 Hub factor set (eGRID2023, AR5)**, so both years are comparable if you use the same set.

## 4. Data dictionary notes

- All files are UTF-8 CSV. Not every file starts with the header on line 1.
- Facility identifiers aren't consistent across systems. Files may use a facility ID, a site number, an account number, a site name or an address.
- Quantities appear in the units each source system uses: kWh, MWh, therms, Mcf, CCF, Dth, gallons, cylinders, lb, kg and "% full".
- Weather and operations data cover 2024 and 2025, so you can compare years and fit regressions.
- `telematics_monthly_mileage` covers company-owned vehicles only.

## 5. Suggested deliverables

1. A cleaned, normalized SQLite database with an ERD
2. SQL that calculates facility and company Scope 1 and 2 totals (location- and market-based)
3. Year-over-year comparison against the 2024 base year
4. KPIs (for example tCO2e per $M revenue, per 1,000 cases shipped, per sq ft; refrigerant leak rate; fleet mpg)
5. A dashboard and recommendations
