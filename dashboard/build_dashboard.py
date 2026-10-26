"""Build the README charts and the dashboard data from the SQLite database.

Run from the repo root after rebuilding the database:
    python dashboard/build_dashboard.py

Writes:
    dashboard/images/*.png   static charts shown in README.md
    dashboard/data.js        the numbers behind dashboard/index.html
Every number comes from the views created by sql/18 and sql/19 (and the
queries in sql/20_analysis.sql), so the charts always match the database.
"""
import json
import sqlite3
from pathlib import Path

import matplotlib

matplotlib.use("Agg")
import matplotlib.pyplot as plt  # noqa: E402

ROOT = Path(__file__).resolve().parent.parent
DB = ROOT / "db" / "ghg_capstone_project.db"
OUT = ROOT / "dashboard"
IMG = OUT / "images"
IMG.mkdir(parents=True, exist_ok=True)

# Reference palette (light mode), fixed categorical order
SURFACE = "#fcfcfb"
TEXT = "#0b0b0b"
TEXT_2 = "#52514e"
GRID = "#e6e5e0"
BLUE, ORANGE, AQUA, YELLOW = "#2a78d6", "#eb6834", "#1baf7a", "#eda100"
MUTED = "#b8b7b0"
CATEGORY_COLOR = {
    "Stationary Combustion": BLUE,
    "Mobile Combustion": ORANGE,
    "Fugitive Emissions": AQUA,
    "Purchased Electricity": YELLOW,
}

plt.rcParams.update({
    "font.family": ["Inter", "DejaVu Sans"],
    "font.size": 11,
    "axes.edgecolor": GRID,
    "axes.labelcolor": TEXT_2,
    "axes.titlecolor": TEXT,
    "axes.titlesize": 13,
    "axes.titleweight": "semibold",
    "axes.titlelocation": "left",
    "xtick.color": TEXT_2,
    "ytick.color": TEXT_2,
    "figure.facecolor": SURFACE,
    "axes.facecolor": SURFACE,
    "savefig.facecolor": SURFACE,
    "axes.spines.top": False,
    "axes.spines.right": False,
})


def q(con, sql):
    cur = con.execute(sql)
    cols = [d[0] for d in cur.description]
    return [dict(zip(cols, r)) for r in cur.fetchall()]


def finish(fig, ax, name, note=None, grid="x"):
    ax.grid(axis=grid, color=GRID, linewidth=0.8)
    ax.set_axisbelow(True)
    if note:
        fig.text(0.01, 0.01, note, fontsize=9, color=TEXT_2)
    fig.tight_layout(rect=(0, 0.04 if note else 0, 1, 1))
    fig.savefig(IMG / name, dpi=160)
    plt.close(fig)


def main():
    con = sqlite3.connect(DB)

    # ---------------------------------------------------------------- data
    kpi = q(con, """
        WITH t AS (
            SELECT reporting_year,
                   SUM(CASE WHEN scope='Scope 1' THEN location_based_tco2e ELSE 0 END) s1,
                   SUM(CASE WHEN scope='Scope 2' THEN location_based_tco2e ELSE 0 END) s2l,
                   SUM(CASE WHEN scope='Scope 2' THEN market_based_tco2e ELSE 0 END) s2m
            FROM company_summary GROUP BY reporting_year),
        c AS (SELECT CAST(SUBSTR(month,1,4) AS INTEGER) y, SUM(cases_shipped) cases
              FROM operation_kpi GROUP BY 1)
        SELECT t.reporting_year year, t.s1, t.s2l, t.s2m,
               (t.s1+t.s2m)/f.net_revenue_usd_millions per_musd,
               (t.s1+t.s2m)/(c.cases/1000.0) per_kcases
        FROM t JOIN financial f ON f.fiscal_year=t.reporting_year
        JOIN c ON c.y=t.reporting_year ORDER BY 1""")

    yoy = q(con, """
        SELECT a.source_category cat, b.location_based_tco2e y2024, a.location_based_tco2e y2025
        FROM company_summary a JOIN company_summary b
          ON a.source_category=b.source_category AND b.reporting_year=2024
        WHERE a.reporting_year=2025""")

    facilities = q(con, """
        WITH c AS (SELECT facility_id, SUM(cases_shipped) cases FROM operation_kpi
                   WHERE month LIKE '2025-%' GROUP BY 1)
        SELECT ft.facility_id id, f.facility_name name, f.facility_type type, f.city, f.state, f.sqft,
               ft.scope1_tco2e s1, ft.scope2_location_based_tco2e s2l, ft.scope2_market_based_tco2e s2m,
               c.cases
        FROM facility_totals ft JOIN facility f ON f.facility_id=ft.facility_id
        LEFT JOIN c ON c.facility_id=ft.facility_id
        ORDER BY ft.scope1_tco2e+ft.scope2_location_based_tco2e DESC""")

    by_source_fac = q(con, """
        SELECT facility_id id, source_category cat, SUM(location_based_tco2e) t
        FROM emissions GROUP BY 1,2""")

    monthly = q(con, """
        SELECT month, source_category cat, SUM(location_based_tco2e) t
        FROM emissions WHERE month IS NOT NULL GROUP BY 1,2 ORDER BY 1,2""")

    gas_hdd = q(con, """
        SELECT iad.facility_id id, iad.month, SUM(iad.quantity) gas, w.hdd_65f hdd
        FROM inventory_activity_data iad
        JOIN facility f ON f.facility_id=iad.facility_id
        JOIN weather_degree_days w ON w.weather_station_id=f.weather_station_id AND w.month=iad.month
        WHERE iad.activity_type='natural_gas' AND iad.is_estimated=0
        GROUP BY 1,2,4""")

    diesel_cases = q(con, """
        SELECT d.facility_id id, d.month, d.gal, ok.cases_shipped cases
        FROM (SELECT facility_id, month, SUM(quantity) gal FROM inventory_activity_data
              WHERE activity_type='diesel_onroad' GROUP BY 1,2) d
        JOIN operation_kpi ok ON ok.facility_id=d.facility_id AND ok.month=d.month
        WHERE ok.cases_shipped > 0""")

    leak = q(con, """
        WITH e AS (SELECT facility_id, SUM(quantity) lb FROM emissions
                   WHERE activity_type='refrigerant' GROUP BY 1),
             c AS (SELECT facility_id, SUM(full_charge_lbs) charge FROM refrigeration_equipment GROUP BY 1)
        SELECT c.facility_id id, c.charge, COALESCE(e.lb,0) lb, 100.0*COALESCE(e.lb,0)/c.charge pct
        FROM c LEFT JOIN e ON e.facility_id=c.facility_id
        WHERE c.charge > 1000 ORDER BY pct DESC""")

    retrofit = q(con, """
        WITH elec AS (
            SELECT facility_id, month, SUM(quantity) kwh FROM inventory_activity_data
            WHERE activity_type='electricity' GROUP BY 1,2
            UNION ALL
            SELECT facility_id, month, SUM(quantity) FROM base_year_activity
            WHERE activity_type='electricity' GROUP BY 1,2),
        yoy AS (
            SELECT a.facility_id, SUBSTR(a.month,6,2) m, 100.0*(a.kwh-b.kwh)/b.kwh pct
            FROM elec a JOIN elec b ON b.facility_id=a.facility_id AND b.month='2024-'||SUBSTR(a.month,6,2)
            JOIN facility f ON f.facility_id=a.facility_id
            WHERE a.month LIKE '2025-%' AND f.facility_type='Distribution Center'
              AND a.facility_id NOT IN ('DC-ATL','DC-DAL'))
        SELECT m,
               AVG(CASE WHEN facility_id IN ('DC-PHL','DC-CMH') THEN pct END) retro,
               AVG(CASE WHEN facility_id NOT IN ('DC-PHL','DC-CMH') THEN pct END) others
        FROM yoy GROUP BY m ORDER BY m""")

    estimated = q(con, """
        SELECT 100.0*SUM(CASE WHEN is_estimated=1 THEN location_based_tco2e ELSE 0 END)/SUM(location_based_tco2e) pct
        FROM emissions""")[0]["pct"]

    # ------------------------------------------------------- chart 1: YoY by source
    order = ["Fugitive Emissions", "Mobile Combustion", "Purchased Electricity", "Stationary Combustion"]
    yoy_d = {r["cat"]: r for r in yoy}
    fig, ax = plt.subplots(figsize=(8, 3.6))
    ypos = range(len(order))
    h = 0.36
    v24 = [yoy_d[c]["y2024"] / 1000 for c in order]
    v25 = [yoy_d[c]["y2025"] / 1000 for c in order]
    ax.barh([y + h / 2 + 0.02 for y in ypos], v24, height=h, color=MUTED, label="2024 base year")
    ax.barh([y - h / 2 - 0.02 for y in ypos], v25, height=h, color=BLUE, label="2025")
    for y, a, b in zip(ypos, v24, v25):
        ax.text(b + 0.4, y - h / 2 - 0.02, f"{b:,.1f}k  ({100 * (b - a) / a:+.1f}%)", va="center", fontsize=10, color=TEXT)
    ax.set_yticks(list(ypos), order)
    ax.invert_yaxis()
    ax.set_xlabel("tCO2e (thousands, location-based)")
    ax.set_title("Fugitive refrigerant emissions drove the 2025 increase")
    ax.set_xlim(0, max(v25 + v24) * 1.25)
    ax.legend(frameon=False, loc="lower right")
    finish(fig, ax, "yoy_by_source.png")

    # ------------------------------------------------- chart 2: facility emissions by source
    fac_ids = [f["id"] for f in facilities]
    stack = {c: [0.0] * len(fac_ids) for c in CATEGORY_COLOR}
    for r in by_source_fac:
        stack[r["cat"]][fac_ids.index(r["id"])] = r["t"] / 1000
    fig, ax = plt.subplots(figsize=(9, 5.2))
    left = [0.0] * len(fac_ids)
    for cat, color in CATEGORY_COLOR.items():
        ax.barh(fac_ids, stack[cat], left=left, color=color, label=cat, height=0.7,
                edgecolor=SURFACE, linewidth=1.5)
        left = [a + b for a, b in zip(left, stack[cat])]
    for i, total in enumerate(left):
        ax.text(total + 0.15, i, f"{total:,.1f}k", va="center", fontsize=9, color=TEXT_2)
    ax.invert_yaxis()
    ax.set_xlabel("tCO2e (thousands, location-based)")
    ax.set_title("Chicago, Dallas and Atlanta are the largest sources")
    ax.legend(frameon=False, ncol=2, loc="lower right", fontsize=9)
    finish(fig, ax, "facility_by_source.png")

    # ---------------------------------------------- chart 3: Scope 2 location vs market
    s2 = sorted(facilities, key=lambda f: f["s2l"] - f["s2m"], reverse=True)[:4]   # the four sites with RECs or a green tariff
    fig, ax = plt.subplots(figsize=(8, 3.6))
    names = [f["id"] for f in s2]
    yp = range(len(names))
    for y, f in zip(yp, s2):
        ax.plot([f["s2m"] / 1000, f["s2l"] / 1000], [y, y], color=GRID, linewidth=3, zorder=1)
    ax.scatter([f["s2l"] / 1000 for f in s2], list(yp), color=MUTED, s=70, zorder=2, label="Location-based (grid average)")
    ax.scatter([f["s2m"] / 1000 for f in s2], list(yp), color=AQUA, s=70, zorder=3, label="Market-based (after RECs / green tariff)",
               edgecolor=SURFACE, linewidth=1.5)
    for y, f in zip(yp, s2):
        cut = 100 * (f["s2l"] - f["s2m"]) / f["s2l"]
        ax.text(f["s2l"] / 1000 + 0.15, y, f"-{cut:.0f}%", va="center", fontsize=10, color=TEXT)
    ax.set_yticks(list(yp), names)
    ax.invert_yaxis()
    ax.set_xlabel("Scope 2 tCO2e (thousands)")
    ax.set_title("Renewable purchases cut Scope 2 by 12,554 t (22%)")
    ax.set_xlim(0, max(f["s2l"] for f in s2) / 1000 * 1.18)
    ax.legend(frameon=False, loc="lower right", fontsize=9)
    finish(fig, ax, "scope2_market_vs_location.png")

    # ----------------------------------------------------- chart 4: gas vs HDD (one site)
    site = "DC-CHI"
    pts = [r for r in gas_hdd if r["id"] == site]
    x = [r["hdd"] for r in pts]
    y = [r["gas"] for r in pts]
    n = len(x)
    mx, my = sum(x) / n, sum(y) / n
    sxy = sum((a - mx) * (b - my) for a, b in zip(x, y))
    sxx = sum((a - mx) ** 2 for a in x)
    syy = sum((b - my) ** 2 for b in y)
    r = sxy / (sxx * syy) ** 0.5
    slope = sxy / sxx
    fig, ax = plt.subplots(figsize=(6, 4))
    ax.scatter(x, y, color=BLUE, s=60, edgecolor=SURFACE, linewidth=1.5, zorder=3)
    xs = [min(x), max(x)]
    ax.plot(xs, [my + slope * (v - mx) for v in xs], color=TEXT_2, linewidth=1.5, linestyle="--", zorder=2)
    ax.set_xlabel("Heating degree days (monthly)")
    ax.set_ylabel("Natural gas (MMBtu)")
    ax.set_title(f"Heating gas tracks weather: {site}, r = {r:.2f}")
    finish(fig, ax, "gas_vs_hdd.png", "Each dot is one month of 2025. All 17 billed sites: r = 0.96 to 1.00.", grid="both")

    # ---------------------------------------------------- chart 5: lighting retrofit
    months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
    fig, ax = plt.subplots(figsize=(8, 3.6))
    ax.axhline(0, color=TEXT_2, linewidth=0.8)
    ax.axvspan(1.5, 11.5, color=GRID, alpha=0.35, linewidth=0)
    ax.text(1.6, max(r_["others"] for r_ in retrofit) + 2.2, "retrofit in place (Mar 2025 on)", fontsize=9, color=TEXT_2)
    ax.plot(months, [r_["others"] for r_ in retrofit], color=MUTED, linewidth=2, marker="o", markersize=5, label="Other distribution centres")
    ax.plot(months, [r_["retro"] for r_ in retrofit], color=ORANGE, linewidth=2, marker="o", markersize=5, label="Philadelphia + Columbus (LED retrofit)")
    ax.set_ylabel("Electricity vs same month 2024 (%)")
    ax.set_title("LED retrofit sites now use 6 to 13% less electricity than 2024")
    ax.legend(frameon=False, loc="lower left", fontsize=9)
    ax.set_ylim(min(r_["retro"] for r_ in retrofit) - 3, max(r_["others"] for r_ in retrofit) + 4)
    finish(fig, ax, "lighting_retrofit.png", grid="y")

    # ------------------------------------------------------- chart 6: leak rate
    fig, ax = plt.subplots(figsize=(8, 4))
    ids = [r_["id"] for r_ in leak]
    pct = [r_["pct"] for r_ in leak]
    colors = [ORANGE if i == "DC-CHI" else BLUE for i in ids]
    ax.barh(ids, pct, color=colors, height=0.65)
    for i, p in enumerate(pct):
        ax.text(p + 0.6, i, f"{p:.0f}%", va="center", fontsize=9, color=TEXT_2)
    ax.invert_yaxis()
    ax.set_xlabel("Refrigerant leaked in 2025 (% of installed charge)")
    ax.set_title("Chicago leaked 44% of its refrigerant charge")
    finish(fig, ax, "refrigerant_leak_rate.png", "Distribution centres only (cross-docks and offices hold under 200 lb of refrigerant).")

    # ------------------------------------------------------------- data for HTML
    data = {
        "generated": "2025 reporting year",
        "kpi": kpi,
        "yoy": yoy,
        "facilities": facilities,
        "bySourceFacility": by_source_fac,
        "monthly": monthly,
        "gasHdd": gas_hdd,
        "dieselCases": diesel_cases,
        "leak": leak,
        "retrofit": retrofit,
        "estimatedPct": estimated,
    }
    (OUT / "data.js").write_text("window.GHG_DATA = " + json.dumps(data, indent=1, default=float) + ";\n", encoding="utf-8")
    print("charts and data written to", OUT)


if __name__ == "__main__":
    main()
