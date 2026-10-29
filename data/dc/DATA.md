# Washington, DC: how the model-ready data were made

| | |
|---|---|
| Unit | Voting precinct, official DCGIS **2019** precinct map (the map DCBOE names for the 2020, 2022 and 2024 elections) |
| Units | 144 (all in `votes.csv` and `partisan.csv`) |
| Years | Ballot measures 2010–2024; federal races 2012–2024 |
| Ballot measures | 9 (`votes.csv`): 2010 (1), 2012 (3), 2014, 2016, 2020, 2022, 2024 (1 each) |
| Federal contests | 4 (`partisan.csv`): President 2012, 2016, 2020, 2024 (DC has no voting US Senate seat) |

Bundle: `output/atlas/overview/bundles/dc/`, a copy of `output/table2/dc/` written by `code/table2/adapt_dc.R`. Build folder: `data/DC/` (README there, completed 2026-09-22).

## Raw data

Ballot measures and federal races come from the same source.

- **Precinct returns**: DC Board of Elections results portal (`https://electionresults.dcboe.org/`), the November general-election precinct downloads for 2010–2024 (CSV; 2010 is the Excel file `PreCertified_General_Election_Results_2010.xls`). Exact download and metadata URLs: `data/DC/metadata/source_manifest.csv`. Raw files: `data/DC/raw/dc_<year>_official.csv` (+ `dc_2010_official.xls`) and the citywide API responses `data/DC/raw/dc<year>_city.json` (audit endpoint `https://electionresults.dcboe.org/cityWide/getCityWide/YYYY-General-Election`).
- Native (unallocated) returns: `data/DC/native_csv/`. Aligned returns, all contests: `data/DC/output_all_years/dc_2010_2024_all_votes_long.csv` (the adapter reads the ballot measures and presidential rows from this file).

## Shapefiles

- **Target**: official DCGIS Voting Precinct 2019 (`https://catalog.data.gov/dataset/voting-precinct-2019`; ZIP `https://opendata.dc.gov/api/download/v1/items/09f6810bb5a84ae6a07272b05bea6528/shapefile?layers=27`), 144 polygons, includes the 83/144 split. Project path `data/DC/geometry/target_2024/target_2024.shp` (original in `data/DC/shapefiles/dc_precincts_2019/`). The NYT 2024 map in `data/DC/shapefiles/dc_precincts_2024/` is **not** the target.
- **Source maps**: 2010 = official 2008 vintage (`https://catalog.data.gov/dataset/voting-precinct-2008`, 143 polygons, assumed to apply to 2010); 2012 and 2014 = historical DCGIS 2012 layer 45 (`https://maps2.dcgis.dc.gov/dcgis/rest/services/DCGIS_DATA/Administrative_Other_Boundaries_WebMercator/MapServer/45`, 143 polygons); 2016 and 2018 = VEST election-specific maps (Harvard Dataverse file ids 3866544, 3866549); 2020–2024 = the 2019 map. Details: `data/DC/shapefiles/README.md`, `data/DC/README.md`.
- **Blocks**: 2020 Census DC tabulation blocks (`https://www2.census.gov/geo/tiger/TIGER2020/TABBLOCK20/tl_2020_11_tabblock20.zip`), POP20 and internal points; `data/DC/raw/blocks2020/`.

## Alignment across years

- **Method: 2020 census-block population crosswalk** (block internal points assigned to source and target polygons in EPSG:5070; each target gets its share of the source precinct's block population). No nearest-polygon or area fallback was needed.
- **Years moved**: 2010–2018 onto the 2019 map. For 2012–2018 the only split is old precinct 83: 47.3775717% to 83 and 52.6224283% to 144 (2020 populations 6,540 and 7,264). For 2010, seven source precincts split (18, 21, 83, 87, 129, 133, 143). 2020, 2022 and 2024 use weight 1 (same map).
- **Scripts**: `data/DC/scripts/spatial_audit.R`, `data/DC/scripts/build_crosswalks.R` (→ `data/DC/crosswalks/dc_<year>_to_2024.csv`), `data/DC/scripts/build_returns.py`, `data/DC/scripts/verify_outputs.py`; the fit's paired file by `data/DC/scripts/build_winner_others.py`.
- **Rounding**: largest remainder across targets within each election × contest × option, ties by ascending precinct number; preserves every option's DC-wide total. `votes_unrounded` keeps the fractional estimate, `votes` the integer.

## Summary statistics from alignment

From `data/DC/README.md` and `data/DC/final_datasets/README.md`:

- All 628 entries in the eight DCBOE citywide APIs match the precinct downloads (after normalising the 2014 "MARJUANNA" spelling).
- All 9,386 option/statistic totals preserved exactly by alignment, including 6,063 candidate/ballot-response totals (`data/DC/metadata/total_preservation_checks.csv`).
- No unmatched reporting precinct ids, duplicate keys or negative counts; 2020–2024 aligned votes equal native votes.
- All 6,012 blocks (689,545 residents) assigned without nearest-neighbour fallback.
- Paired fit file: all 19 winner/others sums reproduce source totals (`data/DC/final_datasets/pair_total_checks.csv`).
- Bundle (`code/table2/adapt_dc.R`): the six fitted measures equal the fit input cell for cell; canary r > 0.95 on those six.

## What is in the model-ready files

- **Ballot measures**: 2010 Charter Amendment IV (elected attorney general); 2012 Charter Amendments V, VI, VII; 2014 Initiative 71 (marijuana); 2016 Advisory Referendum B (statehood); 2020 Initiative 81 (entheogenic plants); 2022 Initiative 82 (tipped minimum wage); 2024 Initiative 83 (ranked-choice voting, open primaries).
- **Success side = the citywide winning response** (as in the fit). All nine passed, so success is FOR/YES throughout.
- **Not in the fit**: the three 2012 charter amendments (`Y2012_C014`–`C016`) were dropped from the fit input by a case-sensitive `CHARTER AMENDMENT` match in `data/DC/scripts/build_winner_others.py:14`; they are in `votes.csv` but did not shape the blocs.
- **Federal races**: presidential generals 2012, 2016, 2020, 2024, DEM vs REP; shadow senator excluded. (The fit itself used 13 candidate contests — president, mayor, shadow US senator — alongside 6 measures.)
- **Units excluded**: none.

## Other datasets

- **All other November general-election contests, 2010–2024, on the 144-precinct map**: `data/DC/output_all_years/dc_2010_2024_all_votes_long.csv` (54,378 rows; 2,578 year × contest entries: 2,456 ANC contests, 9 ballot measures, 113 others — president, delegate, mayor, Council, education board, shadow senator/representative), with per-year `*_votes.csv`, `*_wide.csv`, `*_statistics.csv` in `data/DC/output_all_years/`. Same contests on reported precincts in `data/DC/native_csv/`; official-map years only (2012, 2020, 2022, 2024) in `data/DC/output_official_years/`. ANC rows carry `local_contest_warning` (ANCs often occupy part of a precinct).
- **Winner-vs-others fit inputs**: `data/DC/final_datasets/dc_all_years_winner_others.csv` (19 contests) and `dc_official_years_winner_others.csv` (10 contests), with column keys.
- **No other referendums found**: DC's precinct downloads contain only these nine general-election measures; primaries and separately held special elections were excluded from the build, so any measure held only at a primary is not in the project.

## Known issues

- 2010–2018 counts are population-allocated estimates on the 2019 map; 2020 population may poorly represent 2010.
- 2010 and 2014 map assignments are inferred; 2016/2018 rely on VEST reconstructions ("official-only" subset excludes them).
- DCGIS's catalog item labelled "Voting Precinct 2012" downloads the 2019 map; those files are quarantined in `data/DC/shapefiles/source_zips/MISLABELED_DO_NOT_USE/`.
- Only 144 units and 9 measures; the fit mixes candidate contests with measures (meta.json: `fit_input = mixed`).
