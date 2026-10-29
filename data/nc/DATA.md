# North Carolina: how the model-ready data were made

| | |
|---|---|
| Unit | Precinct, NCSBE statewide precinct map of 2024-07-23 (November 2024 map) |
| Units | 2,659 |
| Years | 2012–2024 (ballot measures and federal races) |
| Ballot measures | 10 (`votes.csv`) |
| Federal contests | 8 (`partisan.csv`): President 2012, 2016, 2020, 2024; US Senate 2014, 2016, 2020, 2022 |

Bundle: `output/atlas/overview/bundles/nc/`. Build folder: `data/north_carolina/realign_2024/` (README there, built 2026-10-19).

## Raw data

All returns come from the NC State Board of Elections (NCSBE) public S3 bucket, as tab-delimited text in zips or per-county files. Ballot measures and federal races come from the same files.

| Election(s) | Source | Notes |
|---|---|---|
| 2016G–2024G | precinct-sorted results, `https://s3.amazonaws.com/dl.ncsbe.gov/ENRS/<yyyy_mm_dd>/results_precinct_sort/<COUNTY>_PRECINCT_SORT.txt` (2018: `<county_id>_prec_sort.txt`) | One-stop, absentee and provisional ballots are assigned to the voter's precinct. |
| 2012–2014 | `ENRS/<date>/results_sort_<yyyymmdd>.zip` | Sorted to Census 2010 VTDs. |
| March 2016 primary | `ENRS/2016_03_15/results_pct_20160315.zip` | The sorted file is empty, so one-stop, absentee and provisional units are spread within county. |
| All (validation only) | `ENRS/<date>/results_pct_<yyyymmdd>.zip` | Official totals. |

- Project path: `data/north_carolina/realign_2024/raw/ncsbe/results/<yyyy_mm_dd>/`. `raw/manifest.csv` records path, size and SHA-256.
- Downloader: `scripts/01_download.py`.

## Shapefiles

- **NCSBE statewide precinct shapefiles**: `https://s3.amazonaws.com/dl.ncsbe.gov/ShapeFiles/Precinct/SBE_PRECINCTS_<yyyymmdd>.zip`.
  - Vintages: 2012-09-01, 2014-10-03, 2015-09-18, 2016-08-26, 2016-10-04, 2017-05-19, 2019-05-07, 2020-01-27, 2020-10-18, 2022-08-31, 2023-12-20, 2024-07-23. The 2025-02-25 vintage was checked and not used.
  - Stored in `raw/ncsbe/shapes/`.
- **2012–2014 units**: Census TIGER 2010 VTDs, `https://www2.census.gov/geo/tiger/TIGER2010/VTD/2010/tl_2010_37<ccc>_vtd10.zip`, in `raw/tiger/vtd10/`.
- **Target**: the NCSBE 2024-07-23 map in all 100 counties. Three units reported in 2024 but folded away on that map (Henderson CV, Wake 01-07A, Wake 07-07A) were rebuilt from the 2019-05-07 map.
  - Target files: `geometry/nc_precincts_target.gpkg` (EPSG:32119) and `nc_precincts_target_4269.gpkg`.
  - The registry and bundle use `geometry/nc_precincts_target_land.gpkg`.
- Blocks: TIGER 2020 `tl_2020_37_tabblock20` (236,638 blocks, 10,439,388 residents).

## Alignment across years

Method: NYC 2020-block-population crosswalk. These elections were moved onto the 2024-07-23 map: May 2012, Nov 2012, Nov 2014, Mar 2016, Nov 2016, Nov 2018, Nov 2020 and Nov 2022. 2024 maps onto itself.

Scripts in `data/north_carolina/realign_2024/scripts/` (run by `run_all.R`):
- `03_parse_returns.R`: handles two tabulation formats. Non-geographic one-stop, absentee and provisional units are spread within county over each contest × choice's precinct votes (kept as `estimated_from_county_level`).
- `05_build_target.R`: builds the target layer.
- `06_crosswalks.R` (with `choose_vintage()` in `00_common.R`): chooses a map per election × county using the Maryland rule. The criteria, in order, are:
  1. the highest share of votes in keyed units;
  2. then turnout fit;
  3. then the fewest empty polygons;
  4. then the nearest date.
- `04_assign_blocks.R`: blocks are assigned whole by internal point. `weight = pop(unit polygons ∩ t) / pop(unit polygons)`, with area as the fallback.
- `07_align.R`: integers are a **largest-remainder rounding within contest × county × choice**, which preserves county and state totals. Fractional values: `output/final_datasets/nc_aligned_fractional_long.csv.gz`.
- `08_validate.R`: validation checks.

`09_bbmm_inputs.R` builds `data/bbmm_benchmarks/north_carolina_2024align.rds` from the integer columns, and `code/atlas/overview/01_bundles.R` reads it. Maps chosen per election: `crosswalks/election_county_vintage.csv`.

## Summary statistics from alignment

From `data/north_carolina/realign_2024/README.md`. Detail in `metadata/validation*.csv`, `placement_summary.csv`, `nongeo_allocation.csv`, `noise_effect_*.csv` and `plausibility.csv`.

**Votes spread from non-geographic units:**

| Election | Share of votes |
|---|---|
| March 2016 | 13.4% |
| 2012–2014 | 0.2–0.5% |
| 2016G–2024G | 0.01–0.15% |

**Placement.** Every vote is placed exactly except these, all placed by key on another map. Nothing is held or reallocated:

| Election | Votes not placed exactly |
|---|---|
| May 2012 | 2,821 (Henderson KM 1–4) |
| 2016G | 327 |
| 2022G | 609 |

**Units moving whole into one 2024 precinct:**

| Years | Share |
|---|---|
| 2012–2018 | 86% |
| 2020 | 95% |
| 2022 | 98% |
| 2024 | 100% |

**Validation:**

| Check | Result |
|---|---|
| A. Sorted vs official county totals | 2,070 of 3,600 exact; max 779 votes |
| B. Official vs certified statewide | 17 of 18 exact; max 2 votes |
| C. Aligned + held = native | 5,927 of 5,927, max 1e-10 |
| D. 2024 own-return reproduction | 29,249 of 29,249 cells |
| E. Dem share correlation | r = 0.992 (2020 vs 2024 Pres); 0.973 (2016 vs 2024); 0.907 (2012 vs 2024) |

**Sorted vs official totals.** These differences come from precinct sorting and NCSBE's statutory statistical noise. Σ|diff| as a share of official votes:

| Election | Σ\|diff\| / official |
|---|---|
| 2012–2016P | 0 |
| 2016G | 0.016% |
| 2018G | 0.077% |
| 2020G | 0.022% |
| 2022G | 0.031% |
| 2024G | 0.043% |

**Block assignment.** 13–17 populated blocks per vintage are unassigned (≤ 205 residents; `metadata/block_assignment_qa.csv`).

## What is in the model-ready files

**Ballot measures (10, success = Yes / For):**

| Key | Measure |
|---|---|
| `2012_05_marriage` | Amendment One (May primary) |
| `2014_11_jurywaiver` | Jury-trial waiver |
| `2016_03_connectnc` | Connect NC bonds (March primary) |
| `2018_11_huntfish` | Right to hunt and fish |
| `2018_11_victims` | Victims' rights |
| `2018_11_taxcap` | Income-tax cap |
| `2018_11_voterid` | Photo ID |
| `2018_11_judicial` | Judicial vacancies |
| `2018_11_ethics` | Ethics and elections board |
| `2024_11_citizenship` | Citizens-only voting |

- No statewide measures were on the ballot in 2020 or 2022.
- **Not included:** the 2010 felon-officeholding amendment and earlier measures, which have no precinct map before 2012.

**Federal races (8, Dem v Rep nominees):**
- President 2012, 2016, 2020, 2024
- US Senate 2014, 2016, 2020, 2022

There was no Senate race in 2012 or 2018.

**Units excluded:** none of the 2,659. Durham precinct 48 has no 2024 returns, so its 2024 cells are 0/0 and absent from the bundle rows.

## Other datasets

- **County and municipal ballot measures, precinct level (raw; inventoried, not aligned)**.
  - **Inventory:** `data/north_carolina/realign_2024/metadata/local_measures_inventory.csv`, written by `scripts/03b_local_measures.R`. It has 476 rows with the columns election, county, contest, reporting_units and votes, and covers bonds, sales tax, malt beverage and wine, and charter questions. Rows per election:

    | Election | Rows | Counties |
    |---|---|---|
    | 2012-05 | 40 | 11 |
    | 2012-11 | 24 | 15 |
    | 2014-11 | 84 | 34 |
    | 2016-03 | 22 | 11 |
    | 2016-11 | 75 | 36 |
    | 2018-11 | 74 | 36 |
    | 2020-11 | 35 | 17 |
    | 2022-11 | 51 | 24 |
    | 2024-11 | 71 | 28 |

  - **Precinct returns:** the NCSBE files in `data/north_carolina/realign_2024/raw/ncsbe/results/<yyyy_mm_dd>/`. Each folder holds `results_pct_<yyyymmdd>/`, plus `results_sort_<yyyymmdd>/` for 2012–2014 or `precinct_sort/` for 2016G and later. All are tab-delimited, with the columns County, Precinct, Contest Name, Choice, vote methods and Total Votes.
  - **Map:** these are on each election's own precinct or VTD units, not the 2024 map. The alignment machinery and crosswalks (`crosswalks/`) could carry them, but this has not been done.
- **Candidate contests (raw, not aligned):** the same NCSBE files contain every contest on the ballot, including state, legislative, judicial and local candidate races. For example, the 2024 `results_pct` file includes the City of Asheville City Council.
- **Checked:** `data/north_carolina/` contains only `realign_2024/`. The atlas `charlotte` bundle is a cut-out of this one.

## Known issues

- **County ids:** NCSBE county ids are not in FIPS order for Macon, Madison, Martin and McDowell (ids 56–59 = FIPS 113, 115, 117, 111). An earlier build lost 124,816 residents to this; `00_common.R` now asserts it.
- **Two file formats:** 2016 throughout and six counties in 2018 use a second format. `STATEWIDE_PRECINCT_SORT.txt` (2020, 2024) duplicates the county files, and some files contain NUL bytes.
- **2012–2014 units:** these "sorted" units are 2010 VTDs, not NCSBE precincts.
- **Statistical noise:** NCSBE has added noise to small cells of the sorted files since 2019 (GS 163-132.5G), so aligned totals differ slightly from the canvass.
- **Hoke 2024:** in the citizenship question, about 600–800 votes moved from Yes to No against the canvass.
- **Bladen 2024:** 5–6% short of the canvass. Both Hoke and Bladen are documented, not patched.
- **Primary ballots:** two measures (May 2012, March 2016) were on primary ballots, and March 2016 relies 13% on within-county spreading.
- **Estimates:** pre-2024 values are estimates on 2024 precincts.
- **Partisan dominance:** the atlas fit pools 8 partisan races with 10 measures (README caveat; CLAUDE.md).
