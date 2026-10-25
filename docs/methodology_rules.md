# Inventory Methodology Rules

The GHG accounting decisions for the Cobalt Creek Provisions 2025 inventory (GHG Protocol Corporate Standard, operational control, AR5 GWPs). The SQL applies these rules; the reasoning lives here.

## Boundary

| Situation | Rule |
| --- | --- |
| XD-SLC acquired 2025-07-01 | Include only activity from 2025-07-01 onward. The seller's January to June bills are outside the boundary; use them only for the base-year significance test. |
| XD-ALB lease ended 2025-10-31 | Include activity up to and including 2025-10-31. |
| SO-BOS gross lease (no bills) | Include. Estimate electricity and heating from floor area x a CBECS office energy intensity. Document the intensity and source. |
| Base-year recalculation | Recalculate 2024 only if a structural change shifts base-year emissions by 5% or more. SLC is well under 5%, so no recalculation; show the test. |

## Utilities (Scope 1 natural gas, Scope 2 electricity)

| Situation | Rule |
| --- | --- |
| Bills that don't match calendar months | Prorate each bill evenly by day; keep only the days that fall in 2025. |
| Estimated reads | Keep them. The next actual read trues up the total. |
| Cancelled bill with a corrected rebill | Use the rebill, drop the cancelled bill. |
| Water and sewer | Not energy. Exclude. |
| Gas supply invoices (Midwest Gas Marketing) | Exclude from the inventory. Chicago's metered gas is already on the delivery utility's bill; counting both double counts. Use the invoices only as a cross-check. |
| A gap in a facility's bills | Estimate the missing days from the 2024 base-year average daily usage for the same calendar month. Document which facility, which dates, and the estimate. |
| Natural gas units | Convert to MMBtu: 1 therm = 0.1 MMBtu; 1 Dth = 1 MMBtu; 1 Mcf = 1.026 MMBtu (EPA Hub heat content); CCF x therm multiplier = therms. |

## Scope 2 market-based

| Situation | Rule |
| --- | --- |
| Hierarchy | 1) RECs and green tariff MWh at zero emissions; 2) supplier-specific rate where published; 3) Green-e residual mix for the rest. |
| REC vintage | Only RECs with a vintage matching the reporting year are eligible. A 2023-vintage batch cannot be claimed for 2025. |
| Green tariff (Valley MUD, 50% enrolled) | 50% of that facility's MWh at zero; the other 50% at the utility's supplier-specific rate. |
| CH4 and N2O | Residual mix publishes CO2 only. Apply eGRID CH4 and N2O rates to MWh not covered by instruments. |

## Mobile combustion (Scope 1)

| Situation | Rule |
| --- | --- |
| Which transactions count | Transaction date in 2025 (not post date). |
| Diesel exhaust fluid (DEF), car washes, motor oil | Not fuel. Exclude. |
| Charges with a matching reversal | They net to zero. Keep both or drop both. |
| Reefer (transport refrigeration unit) fuel | Scope 1 mobile combustion, non-road diesel. Separate activity type from road diesel. |
| Forklift propane | Scope 1 mobile combustion, non-road LPG. One 33.5 lb cylinder = 33.5 / 4.24 = 7.90 gal. |
| CO2 | Gallons x CO2 factor per gallon. |
| CH4 and N2O, on-road | Telematics miles x per-mile factors by vehicle type and model year. Model years after the latest Hub row use the latest row. |
| Leased cars with mileage claims only | Gallons = claimed miles / rated mpg; then gasoline factors. Miles go to CH4 and N2O. |

## Stationary combustion (Scope 1)

| Situation | Rule |
| --- | --- |
| Generator diesel | Fuel used = starting tank reading + deliveries - ending reading. Convert "% full" readings with tank capacity. Distillate No. 2 stationary factors. |

## Fugitive emissions: refrigerants (Scope 1)

Simplified material balance, per service event. Emissions in lb, then x 0.45359237 to kg, then x GWP.

| Service type | Emissions (lb) |
| --- | --- |
| Leak Repair and Recharge | lbs added |
| Top Off | lbs added |
| Recover and Recharge | lbs added - lbs recovered |
| Installation Initial Charge | 0 (charging new equipment is not an emission) |
| Decommission | equipment full charge - lbs recovered |
| Preventive Maintenance | 0 |

| Gas | Treatment |
| --- | --- |
| R-404A, R-448A, R-410A, R-134a, R-407C | HFCs: included in Scope 1 |
| R-22 (HCFC-22) | Montreal Protocol gas: excluded from Scope 1, reported separately as a memo item |

Take each unit's refrigerant from the equipment inventory, not the contractor logs.

## Estimated activity

| Situation | Rule |
| --- | --- |
| Data provided by the client | Treated as actual data (`is_estimated = 0`), including bills the utility marked as estimated reads. |
| Activity estimated after receiving the data (bill gap fill, SO-BOS CBECS estimate) | Flagged `is_estimated = 1` in `inventory_activity_data`, so the estimated share of the inventory can be reported. |

## Factors

EPA GHG Emission Factors Hub 2025 (eGRID2023), Green-e 2025 Residual Mix, IPCC AR5 100-year GWPs (CH4 28, N2O 265). Apply the same factor set to 2024 and 2025 so the years are comparable.
