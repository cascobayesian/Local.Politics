# Florida (statewide): how the model-ready data were made

| | |
|---|---|
| Unit | Precinct, 2024 map (`fl_2024`, VEST-format shapefile) |
| Units | 5,711 on the map; 5,700 in the bundle |
| Years | 2012–2024 (even-year generals) |
| Ballot measures | 45 statewide constitutional amendments |
| Federal contests | 9: President 2012, 2016, 2020, 2024; US Senate 2012, 2016, 2018, 2022, 2024 |

## Raw data

- **Source:** Florida Division of Elections, *Precinct-Level Election Results* (https://dos.fl.gov/elections/data-statistics/elections-data/precinct-level-election-results/). Tab-delimited `<CTY>_PctResults<date>.txt` files, one per county and election. They cover every contest on the ballot. Recount files cover only local contests and are ignored.
- **Project paths:** `data/florida/raw/Results_statewide/zips/` (archives) and `data/florida/raw/Results_statewide/<year>/` (extracted). For BRO/DAD/PAL these match `data/florida/raw/Results/` except for cosmetic edits.
- Ballot measures and federal races come from the same files.
- 2012 Pinellas placement uses `data/florida/raw/Results/2012GenPrecinctCrossReference.xlsx`.

## Shapefiles

- **Target:** `data/florida/raw/Shapefiles/fl_2024/fl_2024.shp` (zip alongside), 5,829 polygons. `0000` (water) polygons are dropped and split parts dissolved, giving 5,711 precincts. Unit id = `COUNTY_PRECINCT` (e.g. `ALA_01`).
- **Earlier vintages:** `data/florida/raw/Shapefiles/fl_2012`, `fl_2014`, `fl_2016`, `fl_2018`, `fl_2020`, `fl_2022`. The statewide README calls them VEST shapefiles; they embed VEST candidate columns such as `G24PRERTRU`.
- Download URL and retrieval date: not documented. Checked the README and the shapefile folders; no README or metadata file is there.

## Alignment across years

- **Method: areal overlap, not the block-population crosswalk.** For each county-year:
  - Reporting units are matched to that year's polygons by `02_resolve_ids.R`. Ids are never trusted alone: placements are verified by matching the R/D tallies VEST embedded in its shapefile, with fingerprint matching where the id fails.
  - Units sharing a polygon merge into a reporting group.
  - Countywide units (absentee, early, provisional) are spread over the groups in proportion to in-person votes for the same question and side (the VEST convention).
  - Each group's votes go to the 2024 precincts with weight = overlap ÷ the part of the group inside 2024 land.
  - Federal-only overseas units are excluded.
- **Years moved:** 2012, 2014, 2016, 2018, 2020 and 2022 (each from its own `fl_<year>` map) onto `fl_2024`. 2024 is taken directly.
- **Scripts:** `data/florida/raw/realign_2024_statewide/`, run from `data/florida/raw/`:
  - `fl_lib.R`
  - `01_amendment_check.R`
  - `02_id_audit.R`, `02_resolve_ids.R`
  - `03_align.R`
  - `04_regression_sf.R`
  - `05_sanity.R`
- **Outputs:** `realign_2024_statewide/output/florida_referendums_2024precincts.csv` and `florida_national_2024precincts.csv`. The fit input `data/bbmm_benchmarks/florida_2024align.rds` is read by `code/atlas/overview/01_bundles.R`.
- **Rounding:** each cell is rounded to the nearest integer (`round()` in `03_align.R`). This is not largest remainder, so totals can drift by a vote or so. The unrounded long form is `output/aligned_long.rds`.

## Summary statistics from alignment

From `data/florida/raw/realign_2024_statewide/README.md`; per county-year detail is in `output/alignment_audit.csv`, `resolve_audit.csv` and `amendment_totals_check.csv`.

| % of amendment votes | 2012 | 2014 | 2016 | 2018 | 2020 | 2022 | 2024 |
|---|---|---|---|---|---|---|---|
| placed on a polygon | 98.5 | 100 | 100 | 100 | 100 | 100 | 100 |
| … with tallies matching VEST exactly | 86 | 95 | 88 | 89 | 88 | 90 | 90 |
| countywide units, spread | 1.5 | 0 | 0 | 0.01 | 0.01 | 0 | 0 |
| unplaced | 0 | 0 | 0 | 0 | 0 | 0 | 0 |

- 67-county sums match certified totals: exactly for 2024, within 0.1% elsewhere. 2020 Amendment 4 differs by +0.2%, a gap between the DOS precinct files and the certified CSV.
- Totals are conserved in every county-year. Only 67 votes are lost across all years, from units with no overlap with 2024 land.
- BRO/DAD/PAL reproduce the South Florida rebuild (`data/florida/raw/realign_2024/`) within ±1 vote in all 21 county-years.
- 2.0% of precinct-years have ballots more than 4× off their county-year ratio to 2024. They are concentrated in Sumter, Osceola, Pasco, Lake and St Johns; the README attributes this to growth, not misplacement.

## What is in the model-ready files

- **Ballot measures:** 45 constitutional amendments, 2012–2024 (11, 3, 4, 12, 6, 3, 6 by year). Success = **Yes**; n = Yes + No. No amendment is dropped. 2016 Amendment 1 (solar) was utility-backed: Yes was the anti-solar-advocate side (CLAUDE.md).
- **Federal races:** 9 D-vs-R contests (above). The national file also has GOVERNOR, which the bundle rule (President + US Senate only) excludes.
- **Units excluded:** 11 precincts with no ballots (5,711 → 5,700).

## Other datasets

- **Governor (DEM, REP), 2014, 2018, 2022, on the 2024 map:** columns in `data/florida/raw/realign_2024_statewide/output/florida_national_2024precincts.csv`. Same map; not in the bundle.
- **Raw DOS precinct files** (`data/florida/raw/Results_statewide/<year>/`) also hold every state, county and judicial candidate contest and a few local questions. Found by contest-name search:
  - Palm Beach 2014: "COUNTY QUESTION - SCHOOL BOARD", "COUNTY QUESTION - CHILDREN SERVICES", "PALM BEACH GARDENS - QUESTION 1/2".
  - Polk 2016: "County Referendum".
  - Indian River 2016: "City of Sebastian Charter Amendment".
  - Seminole 2016: "OVIEDO REFERENDUM ELECTION".
  - These are on native precincts. None has been extracted or aligned.
- For Miami-Dade, Broward and Palm Beach local measures, see `south_florida/DATA.md`.
- No other statewide-level local-measure dataset found. Checked `data/florida/`.

## Known issues

- Areal weighting assumes voters are spread evenly within each old reporting group. This matters most in fast-growing counties and large rural precincts (README).
- "Not exact" VEST matches mostly reflect VEST spreading absentee or early votes into precincts (Polk; Miami-Dade 2016/18), not misplacement. In 2012, 49% of Polk's votes sit in countywide absentee, early and provisional units.
- Do not join FL results to shapefiles on `Unique` alone. Several counties (Washington, Hardee, Putnam, Monroe, Madison, Hernando 2022, Pinellas 2012) use row sequence numbers that collide with real precinct ids (CLAUDE.md, README).
- Bundle `units.gpkg` for FL has rings that break `st_make_valid` after the gpkg round trip (CLAUDE.md).
- The atlas K = 12 (3% rule, ζ = 1); `K_bic` is not defined (`meta.json`).
