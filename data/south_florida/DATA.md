# South Florida (Miami-Dade, Broward, Palm Beach): how the model-ready data were made

> **Read first: where these files come from.** The files in this folder are **not** the South Florida bundle behind the atlas and the paper's K = 7 fit. That bundle is built on an older aligned file with a weighting bug: every year before 2024 is inflated or deflated, and Broward 2012 keeps about 54% of its true votes (details below). The files here are instead cut from the statewide Florida panel (`../fl/`). They are the precincts of Miami-Dade (`DAD_`), Broward (`BRO_`) and Palm Beach (`PAL_`), on the same 2024 map, with the same 45 amendments and 9 federal races. That panel conserves county totals (see `../fl/DATA.md`). Unit ids are the statewide panel's (`DAD_001`, …), not the old bundle's (`DAD_001.0`). The rest of this file documents the old bundle and its corrected tri-county rebuild, for anyone reproducing the paper.

| | |
|---|---|
| Unit | Precinct, 2024 map (`fl_2024`, split parts dissolved by `COUNTY_PRECINCT`); counties BRO, DAD (Miami-Dade, never `MIA`), PAL |
| Units | 1,908 in these files (cut from the statewide panel); 1,910 in the paper's bundle |
| Years | 2012–2024 (even-year generals) |
| Ballot measures | 45 statewide constitutional amendments |
| Federal contests | 9: President 2012, 2016, 2020, 2024; US Senate 2012, 2016, 2018, 2022, 2024 |

## Raw data

- **Source:** Florida Division of Elections precinct-level results, `<CTY>_PctResults<year>Gen.txt` (tab-delimited, every contest). Read by `get.results()` in `data/florida/raw/funcs.r`.
- **Project path:** `data/florida/raw/Results/` (BRO, DAD, PAL, 2012–2024).
- The source URL is recorded only in the statewide README: https://dos.fl.gov/elections/data-statistics/elections-data/precinct-level-election-results/.
- Federal races come from the same files, through the old pipeline's `out` object: `data/florida/raw/national.r` → `south_florida_national.csv` → `data/florida/raw/BBMM/south_florida_national_to_wide.R` → `data/florida/raw/BBMM/south_florida_national_wide.csv`.

## Shapefiles

- **Units:** `data/florida/raw/BBMM/fl_2024/fl_2024.shp`, split parts dissolved by `COUNTY_PRECINCT`; `PAL_0000` polygons dropped. `south_florida_precinct_demographics.gpkg` carries identical polygons and ids.
- **Earlier vintages used by the alignment:** `data/florida/raw/Shapefiles/fl_<year>/fl_<year>.shp`, 2012–2022 (VEST-format; see `fl/DATA.md`). The Miami-Dade official 2012–14 map is at `data/florida/raw/Shapefiles/miami-dade-shapefile-1-8-12-through-6-19-14`.
- Download URLs: not documented.

## Alignment across years

- **Bundle data (old pipeline):** `data/florida/raw/create.final.r` + `funcs.r` (`calc.overlap`, `pair.year`).
  - Areal overlay of each year's precincts (2012–2022) onto 2024 precincts.
  - The bug: weight = overlap ÷ area of the *2024* precinct, where the correct denominator is the area of the *old* precinct.
  - `0000` water polygons were overlay targets. `PAL_0000` absorbed 617k ballots in 2012, later thrown away.
  - Miami-Dade 2020 sub-precincts (`862.1`, …) were dropped.
  - Palm Beach 2016 consolidated units were placed on the lead polygon only.
  - Votes are rounded per cell (`round(sum(Votes_weighted))`).
  - Source: `data/florida/raw/realign_2024/README.md`.
- **Corrected rebuild, not used by the bundle:** `data/florida/raw/realign_2024/`.
  - Scripts: `read_results.R`, `01_id_audit.R`, `02_old_totals_check.R`, `03_validate_2012_geometry.R`, `04_align.R`, `05_compare.R`, `06_refit_K7.R`.
  - Method: areal weighting with weight = overlap ÷ old-precinct area; water excluded; duplicate ids dissolved; sub-precincts fall back to parent; 2024 taken directly.
  - Totals conserved exactly. Cells rounded with `round()`.
- **Bundle:** `code/table2/adapt_south_florida.R` → `output/table2/south_florida/`, copied by `code/atlas/overview/01_bundles.R`.

## Summary statistics from alignment

- **Old file vs raw DOS totals**, as old/raw ballot ratios (`data/florida/raw/realign_2024/output/compare_old_new_by_county_year.csv`, `old_vs_raw_county_totals.csv`):

| | 2012 | 2014 | 2016 | 2018 | 2020 | 2022 | 2024 |
|---|---|---|---|---|---|---|---|
| BRO | 0.542 | 0.708 | 0.717 | 0.720 | 0.725 | 1.040 | 1.000 |
| DAD | 1.030 | 1.112 | 1.035 | 1.039 | 1.040 | 0.879 | 1.000 |
| PAL | 1.134 | 1.126 | 1.098 | 1.051 | 1.095 | 1.006 | 1.000 |

  Corrected rebuild: new/raw = 1 in every county-year.
- In the bundle, Broward 2012 Amendment 1 has n = 321,257. The raw DOS total is 592,887 (360,135 No + 232,752 Yes; computed here from `votes.csv` and `old_vs_raw_county_totals.csv`).
- **Old vs corrected, effect on shares** (`realign_2024/README.md`):
  - Precinct yes-share correlation ≥ 0.994 in every county-year.
  - Median absolute difference ≤ 0.25 points.
  - ≤ 1% of precincts move > 5 points (PAL 2016: 2.6%).
  - The K = 7 refit on the corrected data: ARI 0.885; 88 of 1,906 precincts (4.6%) change bloc.
- **Partisan match rates** (`meta.json`): 0.966–0.993 of modelled units by contest. 2024 President agrees with official `fl_2024.shp` returns (unit-level cor 0.997, tri-county totals within 0.3%).
- Canary (`meta.json`): r = 0.9996, max |dev| = 0.0164.

## What is in the model-ready files

- **These files:** 45 amendments and 9 federal races, from the statewide panel restricted to the three counties. `yes` is the Yes count throughout. The rest of this section describes the paper's bundle.

- **Ballot measures:** 45 constitutional amendments, 2012–2024. **`success` is the No count** (`success_side: "no"`). The old pipeline fits the odd columns of the referendum matrix, which are `*_No`, so the yes-share is `1 − success/n`. The newer refit models Yes, but the bundle still stores No (`meta.json`). No amendment is dropped. 2016 Amendment 1 (solar) was utility-backed: Yes was the anti-solar-advocate side.
- **Federal races:** 9 contests from `south_florida_national_wide.csv`. The file has winner/opponent columns; party is assigned by candidate name. Unit-contests with zero D+R votes are dropped.
- **Units excluded:**
  - `BRO_0000` and `PAL_0000` (county aggregate rows).
  - `DAD_NA` and `PAL_NA` (all-zero placeholders).
  - The fit drops 6 units with no referendum votes.
  - 66 modelled units have no 2024 votes.

## Other datasets

- **Corrected South Florida realignment (same 45 amendments + federal):**
  - `data/florida/raw/realign_2024/output/south_florida_referendums_2024precincts.csv` (drop-in replacement; no `_0000`/`_NA` rows; same 2024 map).
  - `.../south_florida_national_2024precincts.csv` (President and Senate, DEM and REP).
  - `.../aligned_long.csv` (unrounded).
- **County and municipal ballot questions, native precincts, not aligned:** `data/florida/florida_2012_2022.csv`. Long form (`precinct, contest, yes, no, elec, county`), 97,406 rows. Statewide amendments plus county charter and referendum questions and city questions (e.g. "Coconut Creek Question 15", "Bal Harbour Referendum", "County Charter Question 3 Broward County Affordable Housing Trust Fund").
  - Miami-Dade: G2008–G2022.
  - Broward and Palm Beach: G2012–G2022.
  - 490 county × election × contest combinations, statewide amendments included. No 2024. The script that writes it is not documented: no file in `data/florida/` writes it, and `combine.r`, `process.florida.r` and others only read it. There is no README.
- **Underlying county-supplied files** (every contest, native precincts): `data/florida/G2008_Miami.csv` … `G2022_Miami.csv`, `G2018_2016_2014_2012_Broward.csv`, `G2020_Broward.csv`, `G2022_Broward.csv`, `G2012/14/16/18_PalmBeach.xls`, `G2020_PalmBeach.csv`, `G2022_PalmBeach.csv`. Contest-name walk: `data/florida/broward_miami_palmbeach_contestname_walk.csv`.
- **DOS raw:** `data/florida/raw/Results/PAL_PctResults2014Gen.txt` also holds Palm Beach 2014 "COUNTY QUESTION - SCHOOL BOARD", "COUNTY QUESTION - CHILDREN SERVICES" and "PALM BEACH GARDENS - QUESTION 1/2". Candidate contests for all offices are in the same files.

## Known issues

- The weighting bug above (CLAUDE.md, Florida trap). Ballot counts are badly off in non-2024 years. Shares are much less affected.
- Old-format files: rows `BRO_0000`/`PAL_0000` are county aggregates. Join on precinct id, never on position.
- The panel is keyed by precinct label; geometry is the 2024 map. Whether a label kept its boundary across years is unverified (`meta.json`).
- Areal weighting (old or new) assumes uniform voter density. The rebuild README says a block-population crosswalk would be better, mainly for Broward 2012, which went from 778 reporting precincts to 358.
- `find.diffs.r` has the wrong bloc names; `run.miami.r` does not run (CLAUDE.md).
- No model-selection file exists; `K_bic` is null (`meta.json`).
