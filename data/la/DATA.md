# Louisiana (statewide): how the model-ready data were made

| | |
|---|---|
| Unit | Precinct, Louisiana Legislature fall-2024 precinct map (3,656 precincts; vintage file "2024 Precinct Shapefiles (12-31-2024)", as-of 2024-06-27 in `geometry/vintages.csv`) |
| Units in the bundle | 3,646 (10 precincts with no ballots dropped) |
| Years | 2000–2024 (2000–2001 partial) |
| Ballot measures | 168 statewide constitutional amendments on 29 election dates |
| Federal contests | 18 (President 2000–2024 ×7; US Senate ×11, including December runoffs) |

Bundle: `output/atlas/overview/bundles/la/`, built by `code/atlas/overview/01_bundles.R` from `data/bbmm_benchmarks/louisiana_2024align.rds` (measures) and `data/louisiana/final/output/louisiana_national_2024precincts.csv` (federal). Build folder: `data/louisiana/final/` (README: `data/louisiana/final/README.md`).

## Raw data

Ballot measures and federal races come from the same source:

- **Louisiana Secretary of State** results feed behind voterportal.sos.la.gov/graphical. Base URL is `https://voterportal.sos.la.gov/ElectionResults/ElectionResults/Data?blob=`:
  - `ElectionDates.htm` lists the elections.
  - `YYYYMMDD/ElectionRaces.htm` lists the races on each date.
  - `YYYYMMDD/csv/ByPrecinct_<RaceID>.csv` gives one race by precinct.
  - `ByParish_<RaceID>.csv` gives the official parish totals, used as controls.
- Format: CSV per race; about 8,500 ByPrecinct files. All downloads are in `data/louisiana/final/raw/sos/`. Download scripts: `scripts/01_download_race_lists.py`, `02_download_precinct_returns.py` and `02b_download_parish_controls.py`. Logs and race lists: `metadata/download_log.txt`, `metadata/all_races.csv`, `metadata/selected_races.csv`.
- Early and provisional votes are published only as one parish-level row each.

## Shapefiles

- Source: Louisiana Legislature, https://redist.legis.la.gov/default_ShapeFiles2020. There are 26 statewide precinct vintages from 1999 to January 2025, in `data/louisiana/final/raw/boundaries/`, listed in `data/louisiana/final/geometry/vintages.csv`.
- Target (the units): the fall-2024 map, 3,656 precincts, `data/louisiana/final/geometry/target_2024.shp` (NAD83) and `.gpkg` (EPSG:5070), joined on `join_id` (`LA_<parish FIPS>_<canonical key>`). A land-only drawing version, `geometry/target_2024_land.gpkg`, is for maps only.
- Weights: TIGER/Line 2020 blocks `tl_2020_22_tabblock20` (142,874 blocks, 4,657,757 residents), `raw/blocks2020/`.

## Alignment across years

1. **Early/provisional votes** (about 45% of the 2020 presidential vote) are spread within contest × parish × choice over the parish's precincts in proportion to each precinct's election-day votes for that choice (VEST convention). If the choice had no election-day votes in the parish, the precinct's total election-day vote is used. `eday_votes` and `early_votes` are kept separate.
2. **Vintage per election date × parish** (4,851 cells), not per year. Units are matched to polygons on a canonical key (`scripts/keys.R`) by exact, parent (reporting split) or children (one unit, several polygons) rules. Vintages are ranked by matched share of election-day votes, then exact-match share, then the latest vintage on or before the election. All 64 parishes resolve to the fall-2024 map for 2024-11-05 (`metadata/vintage_choice.csv`).
3. **Reporting groups:** units and polygons linked by any match form a group, and the group's votes are spread over all its polygons (`crosswalks/unit_groups.csv.gz`, `group_polygons.csv.gz`).
4. **Weights (NYC method):** each block's internal point is placed in a polygon of its own parish in each vintage and in the 2024 map (fallbacks: max overlap, nearest within 100 m, nearest zero-population polygon). Weight = 2020 population in blocks in both ÷ 2020 population in the group's blocks. 188 zero-population polygon sets use overlap area (`crosswalks/group_weights.csv.gz`, `crosswalks/la_<vintage>_to_2024.csv`).

- Every election 2000–2024 is moved onto the 2024 map. The 2024 general is on that map by construction.
- Scripts (`data/louisiana/final/scripts/`): `03_prepare_geometry.R`, `04_assign_blocks.R`, `05_build_native_returns.R`, `06_match_units.R`, `07_build_weights.R`, `08_align.R` and `09_verify.R` (run by `run_all.R`). `10_florida_style_datasets.R` writes the fit input and the national file.
- **Rounding:** `integer_votes` is a largest-remainder rounding within contest × parish × choice. The fit input and the national file use these integers.

## Summary statistics from alignment

From `data/louisiana/final/README.md` and `metadata/verification_summary.csv`:

| Check | Rows | Passed |
|---|---|---|
| Native precinct + early + provisional = official SOS parish totals (federal + amendments) | 45,746 | 45,746 |
| Conservation, fractional (aligned + unallocated = native) | 62,492 | 62,492 |
| Conservation, integer (±1) | 62,492 | 62,492 |
| 2024 President: election-day votes in whole, unsplit precincts = reported | 33,750 | 33,750 |

- **Unallocated share of all votes** (`metadata/unallocated_votes.csv`): 2000 7.7%, 2001 5.5%, 2002 0.20%, 2003–2024 0.01–0.15% each year. 2000 gaps reach 8% of statewide votes for President and the four amendments. Every non-local contest from 2002 on loses under 1.5%, and nearly all lose under 0.1%.
- 1,133 early votes in parishes with no election-day votes could not be placed.
- `metadata/unmatched_units.csv` has 1,646 unmatched unit × election rows (count from the file). `metadata/unallocatable_groups.csv` is empty.

## What is in the model-ready files

- **Ballot measures (`votes.csv`):** 168 statewide constitutional amendments, 2000–2024, ids `CONSTITUTIONAL_AMENDMENT_<n>_<YYYYMMDD>`, on 29 election dates (several per year; October, November and December ballots included). `success` = Yes (older ballots' FOR is written Yes), `n` = Yes + No. No amendment is dropped from the bundle. The atlas fit for Louisiana uses the amendments only.
- **Federal races (`partisan.csv`):** `dem`/`rep` = the sum of all Democratic and all Republican candidates' votes (Louisiana Senate contests are open primaries with several candidates per party).
  - President: 2000, 2004, 2008, 2012, 2016, 2020, 2024. 2000 covers 3,421 units.
  - US Senate, all 11 contests in the `us_senate` category (which the README says covers "open primaries, generals and December runoffs"): 2002-11-05, **2002-12-07**, 2004-11-02, 2008-11-04, 2010-11-02, 2014-11-04, **2014-12-06**, 2016-11-08, **2016-12-10**, 2020-11-03, 2022-11-08. The three December contests are runoffs and the November contests of 2002, 2014 and 2016 are the open primaries that preceded them. Both are included.
  - The builder's header comment says "no runoffs". It excludes only contests whose name contains "runoff", and Louisiana's ids are date-coded, so the runoffs pass through.
  - Closed party primaries (2008–2010) and presidential preference primaries are not included.
- **Units excluded:** 10 precincts with no ballots (3,656 → 3,646). Four water-only precincts (`…_Z-Z-Z-Z-Z-Z`) have no land. Cells with no ballots are NA/dropped.

## Other datasets

- `data/louisiana/final/aligned_2024/local_measures.csv.gz`: **local ballot measures on the same 2024 unit map** (same `join_id`). It holds parish, municipal and special-district propositions: millages, sales taxes, bonds, charters and liquor options. That is 8,150 contests, 2000–2024 (roughly 270–425 a year), in 1,294,130 rows. It is long form: `contest_id`, `election_date`, `category`, `title` (SOS ballot title, beginning with the parish), `join_id`, `GEOID20`, `parish`, `choice`, `eday_votes`, `early_votes`, `estimated_votes`, `integer_votes` and `allocation`. Rows exist only for parishes where the measure was held. Of the 8,210 local measures, 60 have no allocated votes and no rows (42 of them 2000–2001). Contest metadata: `metadata/contests.csv`.
- `data/louisiana/final/aligned_2024/federal.csv.gz`: candidate contests on the same map, 1,423,844 rows. It has President 7, US Senate 11, US House 95, presidential preference primaries 14, US House party primaries 20 and US Senate party primaries 3. Wide per-contest files for all non-local contests (318): `aligned_2024/by_contest/`.
- `data/louisiana/final/aligned_2024/constitutional_amendments.csv.gz`: the long-form source of the bundle's measures (all candidates/responses, fractional and integer).
- Superseded (CLAUDE.md, README): the 2023 Selenium scrape, `data/louisiana/csvs/` (14,634 files), `data/louisiana/csvs_ballot/` (8,025 local/ballot files, e.g. 2011–2012 propositions) and `data/louisiana/louisiana_2012_2023.csv` / `_v2.csv`. These are native precincts, missing De Soto, LaSalle, St. John the Baptist and Vermilion in 2012–2021, with no early votes and nothing before 2012. Not recommended.
- Recall elections (SOS level 990, 13 races) are not included anywhere.

## Known issues

- 2000–2001 are incomplete: Calcasieu and Rapides renumbered precincts before the 1999/2000 maps, so their reporting units match no shapefile (431k and 285k votes in 2000). There are smaller gaps elsewhere. Treat 2000–2001 as partial.
- Early/provisional votes are parish-level and allocated by within-parish election-day share (CLAUDE.md).
- St. Bernard's combined polygon `32-33` (2000–2002 maps) does not match reporting unit `33`.
- Weights use 2020 residential population. Blocks are assigned whole.
- `data/louisiana/shp/shp_bdry_admin_boundary_data.zip` is Ramsey County, MN, not Louisiana (CLAUDE.md).
- Bloc names are drafts.
