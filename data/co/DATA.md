# Colorado: how the model-ready data were made

| | |
|---|---|
| Unit | Precinct, 2024 general-election map (Redistricting Data Hub) |
| Units | 3,235 precincts on the map; 3,185 with at least one ballot-measure vote (in `votes.csv`); 3,235 in `partisan.csv` |
| Years | 2011–2025 (ballot measures); 2012–2024 (federal) |
| Ballot measures | 78 statewide amendments and propositions |
| Federal contests | 8: President 2012, 2016, 2020, 2024; US Senate 2014, 2016, 2020, 2022 |

## Raw data

- **Source:** Colorado Secretary of State, historical election data portal (`https://historicalelectiondata.coloradosos.gov/contest/<id>`; downloads from `https://co.elstats.civera.com/api/download_contest/<id>_table.csv?split_party=false`). URLs per contest are in `data/colorado/colorado_statewide_november_csvs/manifest.csv`.
- **Format:** one unmodified CSV per contest (87 files: 79 ballot measures, 4 presidential, 4 US Senate). 74 files have precinct rows; 13 are county totals only. All odd-year measure files are county totals only.
- **Project path:** `data/colorado/colorado_statewide_november_csvs/csv/` (zip copy: `data/colorado/colorado_statewide_november_csvs.zip`).
- Ballot measures and federal races come from the same portal.

## Shapefiles

- **Target (units):** Redistricting Data Hub, *Colorado 2024 General Election Precinct-Level Results and Boundaries* (retrieved 01/20/25; built from a 2022 State Demography Office file with county fixes, checked against the L2 voter file). Path: `data/colorado/colorado_2024_crosswalk_project/working_shapes/2024/co_2024_gen_all_prec/co_2024_gen_all_prec.shp` (archive `source_shapes/co_2024_gen_prec.zip`). Join key `COLO_PREC`.
- **Source vintages for the crosswalk** (`data/colorado/colorado_2024_crosswalk_project/source_shapes/`, documented in `SOURCES.md`): 2016 and 2020 VEST (via Harvard Dataverse DOI 10.7910/DVN/DKH9RK); 2018 MGGG `mggg-states/CO-shapefiles`.
- Population weights: 2020 Census PL 94-171 block population and 2020 TIGER/Line blocks (fetched with `tidycensus`/`tigris`).

## Alignment across years

- **Method:** 2020 census-block population crosswalk. Each block is assigned to source and target precincts by an inside point; weights are population shares, normalised within the source county. Fallbacks: polygon-area overlap for source precincts with no populated blocks; county population share when a source precinct id is absent from the geometry. Allocations never cross county lines.
- **By year:**
  - 2016, 2018, 2020: that year's own map (VEST 2016, MGGG 2018, VEST 2020) → 2024.
  - 2012 and 2014: 2016 boundaries used as a proxy.
  - 2022: 2024 boundaries used as a proxy (matching ids assumed unchanged; flagged as estimates).
  - 2024: direct id match.
  - Odd years (2011, 2013, 2015, 2019, 2021, 2023, 2025): county totals only, spread over the county's 2024 precincts by 2020 population share. These are modelled estimates, not observed precinct returns.
- **Scripts:** `data/colorado/colorado_2024_crosswalk_project/align_returns_2024.R` and `write_aligned_csvs.py`. The package's original converter is `convert_colorado_to_2024_precincts.R`. Corrected crosswalks: `colorado_2024_crosswalk_project/crosswalks_corrected/`. Wide tables: `build_wide_csvs.py` → `data/colorado/colorado_2024_wide_csvs/`. Bundle: `code/table2/adapt_colorado.R` → `output/table2/colorado/`, copied by `code/atlas/overview/01_bundles.R`.
- **Rounding:** largest remainder, separately for each county and candidate/option, with ties broken by precinct id order. Every input county and statewide total is preserved exactly.

## Summary statistics from alignment

- `data/colorado/colorado_statewide_november_csvs_2024_precincts/validation_summary.json`: 87 contest files × 3,235 precincts; 28,444 county-column checks; 47,985 exact-2024 source rows checked; identifier sets match; county and state totals match; precinct option sums match; hashes match.
- `.../conversion_qa.csv`, county-fallback vote share by year:
  - 100% in every odd year (county totals only).
  - 2012: about 3.1% (85 of 2,935 source rows in Amendment 64).
  - 2014: 0.39%.
  - 2018: 0.04%.
  - 2022: 1.7–1.8%.
  - 2016, 2020, 2024: 0%.
  - Maximum county-total difference: 0 in every file.
- `.../county_allocated_source_rows.csv` lists the 2,137 source rows that used county allocation. `county_total_checks.csv` reconciles every county and column.
- `code/table2/adapt_colorado.R` checks that statewide yes/no totals reproduce `referendums_summary.csv`. The bundle's canary (empirical vs model bloc means, `meta.json`): r = 0.9997, max |dev| = 0.0185.
- 2018 repair (README): 2,555 `PRECID` values in the 2018 shapefile were truncated to 2147483647; matching used county FIPS + `VTDST` instead.

## What is in the model-ready files

- **Ballot measures:** 78 statewide measures, 2011–2025. Success = **Yes**; n = Yes + No. Source: `data/colorado/colorado_2024_wide_csvs/referendums_votes.csv`. Dropped: the 2016 regional Ballot Issue 4B, which covers seven counties and is not statewide.
- **Federal races:** the 8 contests above, from `colorado_2024_wide_csvs/partisan_votes.csv`. dem/rep = candidates labelled exactly `Democratic` or `Republican`, write-ins included. Mixed labels such as `Unaffiliated/Republican` are excluded.
- **Units excluded:** 50 precincts with zero trials on every measure are absent from `votes.csv`/`blocs.csv`. They remain in `partisan.csv` and `units.gpkg`.

## Other datasets

- **2016 Ballot Issue 4B** (regional; seven counties). Raw: `data/colorado/colorado_statewide_november_csvs/csv/2016_ballot_measure_2016_Nov_8_General_Ballot_Issue_4B_State_of_Colorado_4443.csv`. On the 2024 map: `data/colorado/colorado_statewide_november_csvs_2024_precincts/csv/2016_ballot_measure_2016_Nov_8_General_Ballot_Issue_4B_State_of_Colorado_4443_on_2024_precincts.csv` (3,235 rows). In the other 57 counties `source_county_present` is false and the zeros are fill, not returns.
- **Per-contest aligned files** with candidate-level columns and provenance flags (`source_level`, `allocation_method`, `is_estimated`). Path: `data/colorado/colorado_statewide_november_csvs_2024_precincts/csv/` (87 files, 3,235 rows each, same map).
- No municipal, county, school-district or special-district measures, and no non-federal candidate contests. Checked: the Colorado data folders and a `data/` search for Denver/Boulder. The download scope excluded non-statewide contests.

## Known issues

- Odd-year measures (13 of 78) carry no within-county variation beyond population. Bundle `meta.json` and the wide-CSV README: "modeled precinct estimates, not observed precinct election results."
- 2012/2014 rest on proxy 2016 boundaries and 2022 on proxy 2024 boundaries. The crosswalk README says these are "necessarily less certain".
- The crosswalk-project README says odd-year county files "are not converted by this precinct workflow". The later aligned-CSV README and the bundle do include them, as county-population estimates.
- `town` in the wide tables lists every overlapping Census place. Do not split votes by town.
- BIC picks K = 24; the fit uses K = 8 (5% rule) (`meta.json`).
