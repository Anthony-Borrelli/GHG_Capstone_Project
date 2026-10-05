# 2024 Base Year (already calculated)

A prior consultant prepared this inventory. It is clean and final, so there's no need to redo it.

- `activity_2024_clean.csv`: electricity (kWh) and natural gas (MMBtu) by facility and calendar month. All other sources (generators, forklift propane, fleet by vehicle, reefer fuel, refrigerant lb emitted by gas type) are given as 2024 annual totals.
- `inventory_2024_results.csv`: tCO2e by facility, scope and source, location- and market-based. `memo_hcfc_co2e_t` holds R-22 emissions, which are reported outside Scope 1.

Boundary: operational control. XD-SLC wasn't owned in 2024, so it isn't included. SO-BOS is estimated from floor area because the landlord pays its utilities.
Factors: EPA GHG Emission Factors Hub 2025 (eGRID2023), Green-e 2025 residual mix, IPCC AR5 GWPs. The base year was restated with this factor set so it's comparable with 2025.
Market instruments used in 2024: 20,000 MWh of 2024-vintage RECs applied to DC-DAL, 10,000 MWh applied to DC-CHI, and the 50% Sacramento green tariff.
