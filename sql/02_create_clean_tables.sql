-- 02_create_clean_tables.sql
-- Creates the empty clean-layer, merged, mapping, reference and activity tables from the final ERD (docs/ERD.txt).
-- Every table is dropped and recreated, so this script is safe to rerun.
-- WARNING: rerunning deletes all data in these tables. Rerun the cleaning and loading scripts afterwards.
--
-- Types: TEXT for IDs, codes, names and ISO dates; REAL for quantities; INTEGER for counts, years and 1/0 flags.
-- Every primary key column is NOT NULL (SQLite allows NULL in PRIMARY KEY columns unless told otherwise).
-- Foreign keys are only enforced when a connection runs PRAGMA foreign_keys = ON.

PRAGMA foreign_keys = OFF;

-- ===========================================================================
-- Drop everything (children before parents)
-- ===========================================================================
DROP TABLE IF EXISTS inventory_activity_data;
DROP TABLE IF EXISTS fleet_activity;
DROP TABLE IF EXISTS utility_bill;
DROP TABLE IF EXISTS refrigerant_service;
DROP TABLE IF EXISTS base_year_inventory;
DROP TABLE IF EXISTS base_year_activity;
DROP TABLE IF EXISTS valley_consumption;
DROP TABLE IF EXISTS utilitypay_bill;
DROP TABLE IF EXISTS slc_utility_bill;
DROP TABLE IF EXISTS chi_midwest_invoice;
DROP TABLE IF EXISTS mesa_gas_bill;
DROP TABLE IF EXISTS energyhub_consumption;
DROP TABLE IF EXISTS map_utility;
DROP TABLE IF EXISTS propane_delivery;
DROP TABLE IF EXISTS generator_log;
DROP TABLE IF EXISTS polar_log;
DROP TABLE IF EXISTS arcticair_log;
DROP TABLE IF EXISTS refrigeration_equipment;
DROP TABLE IF EXISTS supplier_emission_rate;
DROP TABLE IF EXISTS rec_retirement;
DROP TABLE IF EXISTS telematics_mileage;
DROP TABLE IF EXISTS mileage_claim;
DROP TABLE IF EXISTS fuel_card_transaction;
DROP TABLE IF EXISTS fuel_card_assignment;
DROP TABLE IF EXISTS vehicle;
DROP TABLE IF EXISTS operation_kpi;
DROP TABLE IF EXISTS weather_degree_days;
DROP TABLE IF EXISTS facility;
DROP TABLE IF EXISTS map_weather_station;
DROP TABLE IF EXISTS map_activity_type;
DROP TABLE IF EXISTS map_vehicle_class;
DROP TABLE IF EXISTS map_fuel_product;
DROP TABLE IF EXISTS map_calendar_day;
DROP TABLE IF EXISTS ref_unit_conversion;
DROP TABLE IF EXISTS ref_building_intensity;
DROP TABLE IF EXISTS ref_residual_mix;
DROP TABLE IF EXISTS ref_zip_egrid;
DROP TABLE IF EXISTS ref_egrid_rate;
DROP TABLE IF EXISTS ref_mobile_ch4_n2o_nonroad;
DROP TABLE IF EXISTS ref_mobile_ch4_n2o_onroad;
DROP TABLE IF EXISTS ref_mobile_co2;
DROP TABLE IF EXISTS ref_stationary_factor;
DROP TABLE IF EXISTS ref_gwp;
DROP TABLE IF EXISTS financial;

-- ===========================================================================
-- Reference tables (emission factors and lookups from published sources)
-- ===========================================================================
CREATE TABLE ref_gwp (
    gas                TEXT    NOT NULL PRIMARY KEY,
    gwp                REAL    NOT NULL,
    is_scope1_included INTEGER NOT NULL,  -- 1 = Kyoto gas in Scope 1, 0 = memo only (R-22)
    source             TEXT
);

CREATE TABLE ref_stationary_factor (
    fuel_type       TEXT NOT NULL PRIMARY KEY,  -- joined via map_activity_type.fuel_type
    uom             TEXT NOT NULL,              -- MMBtu for natural gas, gal for generators
    co2_kg_per_unit REAL NOT NULL,
    ch4_g_per_unit  REAL NOT NULL,
    n2o_g_per_unit  REAL NOT NULL,
    source          TEXT
);

CREATE TABLE ref_mobile_co2 (
    fuel_type      TEXT NOT NULL PRIMARY KEY,  -- joined via map_activity_type.fuel_type
    co2_kg_per_gal REAL NOT NULL,
    source         TEXT
);

CREATE TABLE ref_mobile_ch4_n2o_onroad (
    vehicle_class    TEXT    NOT NULL,  -- Hub vehicle category; joined via map_vehicle_class.hub_vehicle_category
    fuel_type        TEXT    NOT NULL,
    model_year_start INTEGER NOT NULL,
    model_year_end   INTEGER NOT NULL,  -- join with model_year BETWEEN model_year_start AND model_year_end
    ch4_g_per_mile   REAL    NOT NULL,
    n2o_g_per_mile   REAL    NOT NULL,
    source           TEXT,
    PRIMARY KEY (vehicle_class, fuel_type, model_year_start)
);

CREATE TABLE ref_mobile_ch4_n2o_nonroad (
    equipment_type TEXT NOT NULL,  -- joined on activity type (reefer units, forklifts)
    fuel_type      TEXT NOT NULL,
    ch4_g_per_gal  REAL NOT NULL,
    n2o_g_per_gal  REAL NOT NULL,
    source         TEXT,
    PRIMARY KEY (equipment_type, fuel_type)
);

CREATE TABLE ref_egrid_rate (
    egrid_subregion TEXT    NOT NULL,  -- joined on facility.egrid_subregion
    data_year       INTEGER NOT NULL,  -- 2025 inventory uses data_year 2023 (eGRID2023, EPA Hub 2025)
    co2_lb_per_mwh  REAL    NOT NULL,
    ch4_lb_per_mwh  REAL    NOT NULL,
    n2o_lb_per_mwh  REAL    NOT NULL,
    source          TEXT,
    PRIMARY KEY (egrid_subregion, data_year)
);

CREATE TABLE ref_zip_egrid (
    zip                     TEXT    NOT NULL PRIMARY KEY,
    egrid_subregion         TEXT    NOT NULL,
    multiple_subregion_flag INTEGER NOT NULL  -- 1 = ZIP spans more than one subregion
);

CREATE TABLE ref_residual_mix (
    egrid_subregion TEXT    NOT NULL,  -- joined on facility.egrid_subregion
    data_year       INTEGER NOT NULL,  -- 2025 inventory uses data_year 2023 (Green-e 2025 residual mix)
    co2_lb_per_mwh  REAL    NOT NULL,
    source          TEXT,
    PRIMARY KEY (egrid_subregion, data_year)
);

CREATE TABLE ref_building_intensity (
    building_type  TEXT NOT NULL PRIMARY KEY,  -- joined on facility.facility_type, then multiplied by sqft
    kwh_per_sqft   REAL,
    mmbtu_per_sqft REAL,
    source         TEXT
);

CREATE TABLE ref_unit_conversion (
    from_unit TEXT NOT NULL,
    to_unit   TEXT NOT NULL,
    factor    REAL NOT NULL,
    source    TEXT,
    PRIMARY KEY (from_unit, to_unit)
);

-- ===========================================================================
-- Mapping and helper tables (built by hand)
-- ===========================================================================
CREATE TABLE map_calendar_day (
    calendar_date TEXT NOT NULL PRIMARY KEY,  -- ISO YYYY-MM-DD, every day of 2025
    month         TEXT,                       -- YYYY-MM
    year          INTEGER
);

CREATE TABLE map_fuel_product (
    product_description TEXT NOT NULL PRIMARY KEY,  -- as it appears in the fuel card file
    activity_type       TEXT                        -- diesel_onroad, gasoline_onroad, diesel_tru, or exclude
);

CREATE TABLE map_vehicle_class (
    vehicle_class        TEXT NOT NULL PRIMARY KEY,
    hub_vehicle_category TEXT NOT NULL,
    fuel_type            TEXT NOT NULL
);

CREATE TABLE map_activity_type (
    activity_type   TEXT NOT NULL PRIMARY KEY,
    fuel_type       TEXT NOT NULL,
    scope           TEXT NOT NULL,
    source_category TEXT NOT NULL
);

CREATE TABLE map_weather_station (
    weather_station_id TEXT NOT NULL PRIMARY KEY,
    city               TEXT,
    state              TEXT
);

-- ===========================================================================
-- Company, facilities, and business drivers
-- ===========================================================================
CREATE TABLE financial (
    fiscal_year              INTEGER PRIMARY KEY,
    net_revenue_usd_millions REAL,
    employees_fte            REAL
);

CREATE TABLE facility (
    facility_id        TEXT NOT NULL PRIMARY KEY,
    site_number        TEXT UNIQUE,
    facility_name      TEXT,
    facility_type      TEXT,
    street             TEXT,
    city               TEXT,
    state              TEXT NOT NULL,
    zip                TEXT NOT NULL REFERENCES ref_zip_egrid (zip),
    sqft               REAL,
    ownership          TEXT,
    utilities_paid_by  TEXT,
    acquisition_date   TEXT,
    lease_end_date     TEXT,
    status             TEXT,
    weather_station_id TEXT NOT NULL REFERENCES map_weather_station (weather_station_id),
    egrid_subregion    TEXT,
    record_updated     TEXT
);

CREATE TABLE weather_degree_days (
    weather_station_id TEXT NOT NULL REFERENCES map_weather_station (weather_station_id),
    month              TEXT NOT NULL,
    hdd_65f            REAL,
    cdd_65f            REAL,
    PRIMARY KEY (weather_station_id, month)
);

CREATE TABLE operation_kpi (
    facility_id               TEXT NOT NULL REFERENCES facility (facility_id),  -- converted from raw Site # via facility.site_number
    month                     TEXT NOT NULL,
    cases_shipped             INTEGER,
    avg_pallet_positions_used INTEGER,
    headcount                 INTEGER,
    operating_hours           INTEGER,
    PRIMARY KEY (facility_id, month)
);

-- ===========================================================================
-- Fleet
-- ===========================================================================
CREATE TABLE vehicle (
    unit_number         TEXT NOT NULL PRIMARY KEY,
    vin                 TEXT,
    vehicle_class       TEXT,
    fuel_type           TEXT,
    model_year          INTEGER,
    facility_id         TEXT NOT NULL REFERENCES facility (facility_id),
    ownership           TEXT,
    in_service_date     TEXT,
    out_of_service_date TEXT,
    current_card_number TEXT,  -- snapshot at export; use fuel_card_assignment for history
    telematics          TEXT,
    rated_mpg           REAL
);

CREATE TABLE fuel_card_assignment (
    card_number   TEXT NOT NULL,
    unit_number   TEXT NOT NULL REFERENCES vehicle (unit_number),
    assigned_from TEXT NOT NULL,
    assigned_to   TEXT,
    PRIMARY KEY (card_number, assigned_from)
);

CREATE TABLE fuel_card_transaction (
    transaction_id      TEXT NOT NULL PRIMARY KEY,
    card_number         TEXT NOT NULL,  -- unit resolved via fuel_card_assignment where transaction_date is between assigned_from and assigned_to
    unit_number         TEXT NOT NULL REFERENCES vehicle (unit_number),
    transaction_date    TEXT,
    transaction_time    TEXT,
    post_date           TEXT,
    merchant_name       TEXT,
    merchant_city       TEXT,
    merchant_state      TEXT,
    product_description TEXT,
    quantity            REAL,
    uom                 TEXT,
    unit_price_usd      REAL,
    gross_amount        REAL,
    odometer            INTEGER
);

CREATE TABLE mileage_claim (
    employee_id   TEXT,
    unit_number   TEXT NOT NULL REFERENCES vehicle (unit_number),
    month         TEXT NOT NULL,
    miles         REAL,
    rate_per_mile REAL,
    PRIMARY KEY (unit_number, month)
);

CREATE TABLE telematics_mileage (
    unit_number TEXT NOT NULL REFERENCES vehicle (unit_number),
    month       TEXT NOT NULL,
    miles       REAL,
    PRIMARY KEY (unit_number, month)
);

-- ===========================================================================
-- Market instruments
-- ===========================================================================
CREATE TABLE rec_retirement (
    batch_id            TEXT NOT NULL PRIMARY KEY,
    tracking_system     TEXT,
    resource_type       TEXT,
    generation_location TEXT,
    vintage_year        INTEGER,
    mwh                 REAL,
    retirement_date     TEXT,
    facility_id         TEXT NOT NULL REFERENCES facility (facility_id),
    certification       TEXT
);

-- Joined to map_utility on utility_name (names repeat in map_utility, so no foreign key)
CREATE TABLE supplier_emission_rate (
    utility_name   TEXT    NOT NULL,
    product        TEXT    NOT NULL,
    data_year      INTEGER NOT NULL,
    co2_lb_per_mwh REAL,
    source_note    TEXT,
    PRIMARY KEY (utility_name, product, data_year)
);

-- ===========================================================================
-- Refrigerants
-- ===========================================================================
CREATE TABLE refrigeration_equipment (
    equipment_id    TEXT NOT NULL PRIMARY KEY,
    facility_id     TEXT NOT NULL REFERENCES facility (facility_id),
    equipment_type  TEXT,
    refrigerant     TEXT NOT NULL REFERENCES ref_gwp (gas),
    full_charge_lbs REAL,
    install_year    INTEGER,
    status          TEXT,
    retired_date    TEXT
);

CREATE TABLE arcticair_log (
    work_order    TEXT NOT NULL PRIMARY KEY,
    service_date  TEXT,
    equipment_id  TEXT NOT NULL REFERENCES refrigeration_equipment (equipment_id),
    location      TEXT,
    job_type      TEXT,
    refrigerant   TEXT,
    qty_charged   REAL,
    qty_recovered REAL,
    uom           TEXT,
    tech_comments TEXT
);

CREATE TABLE polar_log (
    work_order        TEXT NOT NULL PRIMARY KEY,
    service_date      TEXT,
    equipment_id      TEXT NOT NULL REFERENCES refrigeration_equipment (equipment_id),
    facility_id       TEXT NOT NULL REFERENCES facility (facility_id),
    service_type      TEXT,
    refrigerant       TEXT,
    qty_charged_lbs   REAL,
    qty_recovered_lbs REAL,
    tech_comments     TEXT
);

-- ===========================================================================
-- Stationary sources
-- ===========================================================================
CREATE TABLE generator_log (
    facility_id       TEXT NOT NULL REFERENCES facility (facility_id),
    entry_date        TEXT NOT NULL,
    entry_type        TEXT NOT NULL,
    reading           REAL,
    uom               TEXT,
    tank_capacity_gal REAL,
    PRIMARY KEY (facility_id, entry_date, entry_type)
);

CREATE TABLE propane_delivery (
    facility_id   TEXT NOT NULL REFERENCES facility (facility_id),
    delivery_date TEXT NOT NULL,
    vendor        TEXT,
    product       TEXT,
    quantity      REAL,
    uom           TEXT,
    PRIMARY KEY (facility_id, delivery_date)
);

-- ===========================================================================
-- Utilities
-- ===========================================================================
CREATE TABLE map_utility (
    account_number TEXT NOT NULL PRIMARY KEY,
    facility_id    TEXT NOT NULL REFERENCES facility (facility_id),
    utility_name   TEXT,
    commodity      TEXT,
    meter_number   TEXT UNIQUE,
    notes          TEXT
);

CREATE TABLE energyhub_consumption (
    site           TEXT,
    account_number TEXT NOT NULL REFERENCES map_utility (account_number),
    utility        TEXT,
    meter_number   TEXT NOT NULL,
    start_date     TEXT NOT NULL,
    end_date       TEXT,
    consumption    REAL,
    uom            TEXT,
    cost_usd       REAL,
    est            TEXT,
    PRIMARY KEY (meter_number, start_date)
);

CREATE TABLE mesa_gas_bill (
    account_number   TEXT NOT NULL REFERENCES map_utility (account_number),
    address          TEXT,
    prev_read_date   TEXT,
    curr_read_date   TEXT NOT NULL,
    prev_read_ccf    REAL,
    curr_read_ccf    REAL,
    therm_multiplier REAL,
    amount_due       REAL,
    PRIMARY KEY (account_number, curr_read_date)
);

CREATE TABLE chi_midwest_invoice (
    facility_id          TEXT NOT NULL REFERENCES facility (facility_id),
    month                TEXT NOT NULL,
    customer             TEXT,
    pipeline_pool        TEXT,
    nominated_volume_dth REAL,
    price_per_dth        REAL,
    PRIMARY KEY (facility_id, month)
);

CREATE TABLE slc_utility_bill (
    customer       TEXT,
    account_number TEXT NOT NULL REFERENCES map_utility (account_number),
    commodity      TEXT,
    start_date     TEXT NOT NULL,
    end_date       TEXT,
    usage          REAL,
    uom            TEXT,
    PRIMARY KEY (account_number, start_date)
);

CREATE TABLE utilitypay_bill (
    invoice_number     TEXT NOT NULL PRIMARY KEY,
    vendor_name        TEXT,
    account_number     TEXT NOT NULL REFERENCES map_utility (account_number),
    address            TEXT,
    commodity          TEXT,
    bill_date          TEXT,
    service_start_date TEXT,
    service_end_date   TEXT,
    usage              REAL,
    uom                TEXT,
    read_type          TEXT,
    bill_status        TEXT,
    current_charges    REAL
);

CREATE TABLE valley_consumption (
    account_number              TEXT NOT NULL REFERENCES map_utility (account_number),
    meter_number                TEXT NOT NULL REFERENCES map_utility (meter_number),
    address                     TEXT,
    rate_schedule               TEXT,
    renewable_choice_enrollment REAL,
    month                       TEXT NOT NULL,
    consumption                 REAL,
    PRIMARY KEY (meter_number, month)
);

-- ===========================================================================
-- Base year (2024, already calculated)
-- ===========================================================================
CREATE TABLE base_year_activity (
    activity_id     INTEGER PRIMARY KEY,  -- numbered automatically by SQLite
    facility_id     TEXT NOT NULL REFERENCES facility (facility_id),
    month           TEXT,
    scope           TEXT,
    source_category TEXT,
    activity_type   TEXT,
    quantity        REAL,
    uom             TEXT,
    vehicle_class   TEXT,
    model_year      INTEGER,
    miles           REAL,
    refrigerant     TEXT
);

CREATE TABLE base_year_inventory (
    facility_id          TEXT NOT NULL REFERENCES facility (facility_id),
    scope                TEXT,
    source_category      TEXT,
    activity_type        TEXT NOT NULL,
    co2_t                REAL,
    ch4_t                REAL,
    n2o_t                REAL,
    hfc_co2e_t           REAL,
    location_based_tco2e REAL,
    market_based_tco2e   REAL,
    memo_hcfc_co2e_t     REAL,
    PRIMARY KEY (facility_id, activity_type)
);

-- ===========================================================================
-- Merged tables
-- ===========================================================================
CREATE TABLE refrigerant_service (
    work_order        TEXT NOT NULL,
    service_date      TEXT,
    equipment_id      TEXT NOT NULL REFERENCES refrigeration_equipment (equipment_id),
    facility_id       TEXT NOT NULL REFERENCES facility (facility_id),  -- from refrigeration_equipment via equipment_id
    service_type      TEXT,  -- Leak Repair and Recharge, Top Off, Recover and Recharge, Installation Initial Charge, Decommission, Preventive Maintenance
    refrigerant       TEXT,  -- from refrigeration_equipment
    qty_charged_lbs   REAL,  -- converted to lbs where the source used kg
    qty_recovered_lbs REAL,  -- converted to lbs where the source used kg
    tech_comments     TEXT,
    source_system     TEXT NOT NULL,
    PRIMARY KEY (source_system, work_order)
);

CREATE TABLE utility_bill (
    utility_bill_id    INTEGER PRIMARY KEY,  -- numbered automatically by SQLite
    facility_id        TEXT NOT NULL REFERENCES facility (facility_id),  -- from map_utility via account_number
    account_number     TEXT NOT NULL REFERENCES map_utility (account_number),
    meter_number       TEXT,
    service_start_date TEXT NOT NULL,
    service_end_date   TEXT NOT NULL,
    commodity          TEXT NOT NULL,
    quantity           REAL NOT NULL,
    uom                TEXT NOT NULL,  -- standard units only: kWh, MMBtu
    is_estimated       INTEGER,        -- 1 = estimated read, 0 = actual
    utility_name       TEXT,
    source_system      TEXT,
    source_ref         TEXT
);

-- ===========================================================================
-- Activity tables
-- ===========================================================================
CREATE TABLE fleet_activity (
    fleet_activity_id INTEGER PRIMARY KEY,  -- numbered automatically by SQLite
    facility_id       TEXT NOT NULL REFERENCES facility (facility_id),
    unit_number       TEXT NOT NULL REFERENCES vehicle (unit_number),
    month             TEXT NOT NULL,
    activity_type     TEXT NOT NULL REFERENCES map_activity_type (activity_type),
    quantity          REAL NOT NULL,
    uom               TEXT NOT NULL,
    miles             REAL,
    source_system     TEXT,
    UNIQUE (unit_number, month, activity_type)
);

CREATE TABLE inventory_activity_data (
    activity_id     INTEGER PRIMARY KEY,  -- numbered automatically by SQLite
    reporting_year  INTEGER NOT NULL,
    facility_id     TEXT    NOT NULL REFERENCES facility (facility_id),
    month           TEXT,               -- YYYY-MM for monthly sources, NULL for annual sources
    scope           TEXT    NOT NULL,   -- copied from map_activity_type, never typed by hand
    source_category TEXT    NOT NULL,   -- copied from map_activity_type, never typed by hand
    activity_type   TEXT    NOT NULL REFERENCES map_activity_type (activity_type),
    quantity        REAL    NOT NULL,
    uom             TEXT    NOT NULL,
    is_estimated    INTEGER NOT NULL DEFAULT 0 CHECK (is_estimated IN (0, 1)),  -- 1 = estimated after receiving the data from the client (gap fill, CBECS), 0 = as provided by the client
    vehicle_class   TEXT,
    model_year      INTEGER,
    miles           REAL,
    refrigerant     TEXT REFERENCES ref_gwp (gas)  -- NULL for non-refrigerant rows
);

PRAGMA foreign_keys = ON;
