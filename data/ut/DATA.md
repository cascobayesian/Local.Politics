# Utah (statewide): how the model-ready data were made

| | |
|---|---|
| Unit | Precinct, 2022 map (VEST 2022 v1.1) |
| Units | 2,869 on the map (all 29 counties); 2,683 in the bundle |
| Years | 2016–2022 (even-year generals) |
| Ballot measures | 18 statewide measures |
| Federal contests | 4: President 2016, 2020; US Senate 2016, 2018 |

## Raw data

- **Ballot measures:** county canvass reports, parsed to precincts as printed. Two sources, both under `data/Utah/raw/county_canvass/<year>/` (`data/Utah/ballot_measures/README.md`):
  - The OpenElections mirror (github.com/openelections/openelections-sources-ut).
  - Where that mirror's copy was missing, empty or image-only, the county's own website. These copies are saved in `extra/` with their URLs.
  - Formats: PDF, XLSX, XLS and scanned images. 9–12 counties per year needed OCR (macOS Vision) or hand transcription.
  - Official statewide canvass for checks: Lt. Governor, `data/Utah/raw/ltgov/` (2016, 2018, 2020 XLSX; 2022 PDF).
- **Federal races:** VEST precinct shapefiles with embedded returns. Paths `data/Utah/raw/ut_<year>.zip` and `data/Utah/raw/ut_<year>/` (`data/Utah/README.md`):
  - 2016: https://doi.org/10.7910/DVN/NH5S2I
  - 2018: https://doi.org/10.7910/DVN/UBKYRU
  - 2020: https://doi.org/10.7910/DVN/K7760H
  - 2022 v1.1: UF Election Lab, https://election.lab.ufl.edu/dataset/fl-2022-precinct-level-election-results/ (the URL says fl; the file is Utah)
  - Hashes: `data/Utah/metadata/downloads.json`.

## Shapefiles

- **Target:** VEST 2022 v1.1 Utah precincts (source above). Paths: `data/Utah/raw/ut_2022/`; copies at `data/Utah/final/raw_data/ut_2022` and `data/Utah/final/data/ut_precincts_2022.gpkg`. Join key `join_id` / `precinct_key` (constructed, not a Census GEOID).
- **Why 2022 and not 2024:** no public 2024 Utah precinct shapefile was available (the UF product is subscription-only; RDH needs a login). The NYT 2024 GeoJSON (`data/Utah/raw/nyt_ut_2024.geojson.gz`) is presidential only and is not used.
- Blocks: `data/Utah/raw/tl_2020_49_tabblock20.zip` (https://www2.census.gov/geo/tiger/TIGER2020/TABBLOCK20/tl_2020_49_tabblock20.zip).

## Alignment across years

- **Method:** 2020 census-block population crosswalk (the Colorado approach):
  - Positive-population blocks are assigned by inside point to historical and target precincts, within county.
  - Block population gives normalised source → target weights.
  - Source precincts with no populated block point use polygon-area overlap.
  - There is no countywide fallback: a missing assignment stops the run.
- **Years moved:** VEST 2016, 2018 and 2020 precincts onto the 2022 map. 2022 is identity.
- Ballot measures go one step further. Canvass precincts are first mapped to that year's VEST precincts, then moved with the same crosswalks.
- **Scripts:**
  - `data/Utah/scripts/align_utah.R` (crosswalks `data/Utah/crosswalks/ut_<year>_to_2022.csv`)
  - `data/Utah/scripts/verify_outputs.py`
  - Ballot measures: `data/Utah/scripts/ballot/` (`00_state_canvass_totals.R`; per-year parse and match scripts; `assemble_ballot_2022.R`)
  - Fit inputs: `data/Utah/final/scripts/01_prepare_inputs.R` → `data/Utah/final/data/ut_ballot.csv`, `ut_national.csv`
  - Bundle: `code/atlas/overview/01_bundles.R` (`final_layout`)
- **Rounding:** largest remainder, preserving each county × candidate (or county × measure side) total.

## Summary statistics from alignment

| Year | Source precincts | Population-weighted | Area-weighted |
|---|---:|---:|---:|
| 2016 | 2,296 | 2,203 | 93 |
| 2018 | 2,337 | 2,244 | 93 |
| 2020 | 2,423 | 2,273 | 150 |
| 2022 | 2,869 | identity | 0 |

(`data/Utah/README.md`; Census input: 71,207 blocks, population 3,271,616.)

- `data/Utah/output_2022/validation.json`: status passed, 2,869 precincts, 29 counties, 1,856 county × candidate totals conserved. Also checked: within-county allocation and crosswalk weights summing to one.
- **Ballot measures** (`data/Utah/ballot_measures/qa/county_total_checks.csv`): 1,021 of 1,030 county × measure cells match the official canvass exactly; the other nine differ by 1–3 votes.
- **Canvass-to-VEST matching** on the partisan race in the same file:
  - 2016 and 2020: all 29 counties match exactly in 100% of precincts.
  - 2018: 26 counties exact; Emery and Weber r ≥ 0.9999.
  - 2022: 25 counties exact; r ≥ 0.9998.
  - Per-year detail: `data/Utah/ballot_measures/work/<year>/qa_<year>_match_summary.csv`.
- `data/Utah/final/r_outputs/input_audit.csv`: ballot file 2,869 rows, 18 contests, 20,925,316 votes. The bundle's `votes.csv` sums to the same 20,925,316.

## What is in the model-ready files

- **Ballot measures:** 18 statewide measures. Success = **Yes (FOR)**; n = Yes + No.
  - 2016: Amendments A–C.
  - 2018: Amendments A–C, Nonbinding Opinion Question 1, Propositions 2–4.
  - 2020: Amendments A–G.
  - 2022: Amendment A.
  - None dropped.
- **Federal races:** 4 D-vs-R contests. 2022 US Senate is not included: there was no Democratic nominee (McMullin ran unaffiliated).
- **Units excluded:** 186 precincts with zero votes on every measure (`data/Utah/final/r_outputs/ballot/zero_information_precincts.csv`).

## Other datasets

- **State-office candidate contests on the same map:** `data/Utah/final/data/ut_statewide.csv` (2,869 rows; key `ut_statewide_column_key.csv`). 9 contests, Republican vs Other: Governor, Attorney General, State Auditor, State Treasurer 2016 and 2020; State Treasurer 2022.
- **Every VEST candidate field, by year, on the 2022 map:** `data/Utah/output_2022/ut_<year>_on_2022_precincts.csv` (2016–2022). 2022 includes US Senate (Lee, McMullin and others) and State Treasurer.
- **Federal panel incl. 2022 Senate:** `data/Utah/output_2022/utah_president_senate_2016_2022.csv` (2,869 rows, 10 vote columns).
- **Salt Lake County local measures and candidate races, 2011–2024, on the 2022 map:** `data/Utah/slco_local/output/` (see `slc/DATA.md`). Only Salt Lake County.
- **Raw, unprocessed:**
  - County canvasses in `data/Utah/raw/county_canvass/<year>/` presumably also contain other counties' local contests. Not checked or extracted.
  - `data/Utah/raw/medsl/2022-ut-local-precinct-general/UT-cleaned.csv`: MEDSL 2022 Utah local precinct returns, 119,815 long rows, native precincts. It includes some local ballot questions (e.g. "PROPOSITION #6 - TOOELE CITY QUESTION 1", "PROPOSITION #7 - GRANTSVILLE CITY QUESTION 1", "CITY OF HARRISVILLE BOND", "SALT LAKE CITY BOND PROPOSITION", "BLUFFDALE CITY COUNCIL REFERENDUM") and local candidate races. Not processed and not documented; it is not on the 2022 VEST map.
- 2024 statewide measures exist only for Salt Lake County (`slco_local`).

## Known issues

- **Wayne County 2018:** all seven measures are blank. No precinct canvass exists, so 2018 statewide sums fall short of official totals.
- County-level rows (e.g. Emery's "Canvas") are prorated across precincts by measure votes. Privacy-suppressed results (Weber, Wasatch) are filled from the county residual, split by VEST votes.
- In OCR'd counties, values swapped between two precincts within one measure would pass every check.
- 2016–2020 values are spatial estimates that assume the 2020 population distribution. Inside points approximate split blocks.
- VEST `COUNTYID` codes are ordinal, not FIPS; `align_utah.R` remaps them.
- Atlas K = 12; `K_bic` not defined (`meta.json`). Bloc names are drafts.
