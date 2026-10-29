# Salt Lake County: how the model-ready data were made

| | |
|---|---|
| Unit | Precinct, 2022 map (VEST 2022 v1.1, Salt Lake County = FIPS 49035) |
| Units | 835 on the map; 803 in `votes.csv`; 795 in `partisan.csv` |
| Years | 2011–2024 |
| Ballot measures | 55: 25 statewide + 30 local (6 county, 10 city, 14 sub-county) |
| Federal contests | 4: President 2016, 2020; US Senate 2016, 2018 |

## Raw data

- **18 statewide measures, 2016–2022:** the Utah statewide build (`ut/DATA.md`). These are county canvass reports from the OpenElections mirror and county sites, in `data/Utah/raw/county_canvass/<year>/`.
- **The other 7 statewide questions and all 30 local questions:** the Salt Lake County Clerk's precinct-level Statement of Votes Cast (SOVC) workbooks for every November election 2011–2025. Path: `data/Utah/raw/slco_sovc/`. Landing page: https://www.saltlakecounty.gov/clerk/elections/election-results/ (`data/Utah/slco_local/README.md`). The 7 statewide questions are 2012 Amendments A and B, 2014 A–C, and 2024 B and C.
- **Federal races:** VEST precinct returns on the 2022 map (`data/Utah/final/data/ut_national.csv`; sources in `ut/DATA.md`).

## Shapefiles

- **Units:** `data/Utah/final/data/ut_precincts_2022.gpkg` filtered to `county_fips == "49035"` (VEST 2022 v1.1).
- **Source vintages for the local file** (`data/Utah/raw/slco_precincts/`, fetched by `data/Utah/scripts/slco/00_fetch_slco_precincts.py`):
  - 2011: UGRC VistaBallotAreas 2011 archive.
  - 2012: SLCo web map layer "2012Precincts".
  - 2013–14: SLCo "2013 Precincts".
  - 2015–16: VEST 2016.
  - 2017: SLCo 2017PrimaryPrecinct.
  - 2018: VEST 2018.
  - 2019–20: VEST 2020.
  - 2022: identity.
  - 2024: SLCo Precincts2023_20230228.
  - 2025: SLCo Precincts_2025_Lookup.
  - Each vintage was chosen by precinct-code match to that year's SOVC.

## Alignment across years

- **Statewide 2016–2022** (`ut_ballot.csv`): 2020 census-block population crosswalk with inside points, area fallback, and county-preserving largest-remainder rounding (`data/Utah/scripts/align_utah.R`; see `ut/DATA.md`).
- **Local file** (`slco_local`): 2020 census-block population reallocation within Salt Lake County, with area-overlap fallback for unpopulated source precincts.
  - Each year's vintage above is moved onto the 2022 VEST map.
  - City-only contests are restricted to 2022 precincts coded `SLC*`.
  - Scripts: `data/Utah/scripts/slco/01_parse_slco_sovc.R`, `02_crosswalks_to_2022.R`, `03_select_and_align.R`. Crosswalks: `data/Utah/slco_local/crosswalks/slco_<year>_to_2022.csv`.
  - The output counts are **fractional**.
- **Rounding:** `code/slc/01_build_inputs.R` rounds the fractional `slco_local` counts by largest remainder within each contest, separately for Yes and No. Countywide totals equal the rounded fractional totals. For the 18 measures in both sources, the integer `ut_ballot.csv` copy is kept.
- **Bundle:** `code/slc/01_build_inputs.R` → `output/slc/bundle/` (blocs from `03_select_k.R`), copied by `code/atlas/overview/01_bundles.R`.

## Summary statistics from alignment

From `output/slc/inputs/build_log.txt`, `rounding_audit.csv` and `overlap_comparison.csv`:

- 801 of 835 precincts have a vote on some statewide measure.
- The 18 measures present in both sources agree: precinct share correlation min 0.861, median 0.992; median |share difference| 0.0002; countywide totals identical.
- Rounding: max precinct share change 0.470 overall and 0.023 among precincts with ≥ 20 votes. 46 precinct cells go from fractional > 0 to 0.
- 803 of 835 precincts vote on a retained question; 795 of those have a normal vote. 59.3% of the unit × question cells are observed.

From `data/Utah/slco_local/output/measure_dictionary.csv`:

- Share of native votes landing on the 2022 map is ≥ 0.999 for statewide questions.
- For local referenda the minimum is 0.949 (2018 Brighton Incorporation, dropped) and 0.953 (2015 Magna Metro Township).
- Across all referendum and statewide-question votes, 99.99% are kept.
- Unmatched native precincts are listed in `output/unmatched_native_precincts.csv` (22 contest rows).

## What is in the model-ready files

- **Ballot measures:** 55 questions, 2011–2024. Success = **Yes/FOR** (checked: every option is FOR/AGAINST or YES/NO).
- **Statewide (25):**
  - `st_2012_constitutional_amendment_a`, `st_2012_constitutional_amendment_b`
  - `st_2014_constitutional_amendment_a`, `_b`, `_c`
  - `st_2016_amendment_a`, `_b`, `_c`
  - `st_2018_amendment_a`, `_b`, `_c`, `st_2018_question_1`, `st_2018_proposition_2`, `_3`, `_4`
  - `st_2020_amendment_a` … `st_2020_amendment_g`
  - `st_2022_amendment_a`
  - `st_2024_constitutional_amendment_b`, `_c`
- **County (6):**
  - `loc_2012_county_proposition_1`
  - `loc_2014_county_proposal_no_1`
  - `loc_2015_salt_lake_county_proposition_1`
  - `loc_2016_county_proposition_a`
  - `loc_2024_salt_lake_county_jail_bond`
  - `loc_2024_zap_proposition_8`
- **City (10):**
  - `loc_2011_s_salt_lake_bond`
  - `loc_2015_herriman_hills_initiative_prp_7`
  - `loc_2015_south_salt_lake_special_bond`
  - `loc_2017_west_jordan_city_bond`
  - `loc_2017_west_jordan_city_proposition_10`
  - `loc_2018_holladay_proposition_14`
  - `loc_2018_slc_streets_reconstruction_bond`
  - `loc_2022_bluffdale_city_council_referendum`
  - `loc_2022_slc_bond_proposition`
  - `loc_2024_cottonwood_heights_city_bond`
- **Sub-county (14):** school districts, metro townships, service areas.
  - `loc_2012_incorporation_of_millcreek`
  - `loc_2012_millcreek_council_s`
  - `loc_2013_jordan_school_bond`
  - `loc_2013_unified_fire_service_area_annex`
  - `loc_2014_murray_cty_school_tax_levy`
  - `loc_2015_kearns_msd`, `loc_2015_magna_msd`, `loc_2015_millcreek_msd`
  - `loc_2016_jordan_school_bond_elect`
  - `loc_2016_magna_water_special_bond_elect`
  - `loc_2017_canyons_school_bond`, `loc_2017_granite_school_bond`
  - `loc_2024_murray_city_school_bond`
  - `loc_2024_slc_school_bond`
- Scope labels are hand-assigned in `01_build_inputs.R` (`scope_of`) and listed in `output/slc/bundle/questions.csv`.
- **Dropped:** questions on fewer than 10 precincts. These are 2015 Copperton, Emigration Canyon and White City Metro Townships, 2016 King Benjamin SSD Tax Levy, and 2018 Brighton Incorporation.
- **Federal races:** 4 D-vs-R contests. 2022 Senate is excluded: no Democrat ran.
- **Units excluded:** 32 of 835 precincts with no vote on any retained question.

## Other datasets

- **Salt Lake County candidate contests, 2011–2024, on the 2022 map:** `data/Utah/slco_local/output/slco_local_on_2022_long.csv` (73,470 rows: measure × precinct, `support`, `total`, `prop`; fractional) and `slco_local_on_2022_wide.csv` (835 rows).
  - 147 candidate contests. Support = winner's share.
  - By office: State house 44, County council 24, County office 23, State office 18, SLC council 16, State senate 15, County mayor 4, SLC mayor 3.
  - The same files carry the 35 referenda and 25 statewide questions.
  - Dictionary: `measure_dictionary.csv` (207 rows). The README says 144; the file has 207.
  - Native-precinct version: `slco_local_native_long.csv` (74,422 rows). Dropped uncontested races: `dropped_uncontested.csv`.
- **The five dropped tiny local questions** are in the same `slco_local` files.
- **Raw SOVC workbooks**, every contest, 2011–2025, including RCV-year SLC races not processed: `data/Utah/raw/slco_sovc/`, parsed long at `data/Utah/slco_local/work/slco_sovc_long_all.csv`.
- **State-office contests on the 2022 map:** `data/Utah/final/data/ut_statewide.csv` (see `ut/DATA.md`).

## Known issues

- `slco_local` vintages are matched by precinct-code label only. A precinct that kept its code while its boundary moved goes undetected (README).
- The README says "at least 98.4% of every contest's votes land on the 2022 map". The dictionary shows two referenda below that: Brighton 0.949, Magna MSD 0.953.
- Statewide questions come from two sources with two rounding steps: integer `ut_ballot` for 2016–2022, and rounded-fractional `slco_local` for 2012, 2014 and 2024.
- The 2014 County Proposal 1 label ("ZAP tax renewal?") is inferred and unconfirmed (`01_build_inputs.R`).
- BIC picks K = 7; the fit uses K = 8 (5% rule) (`meta.json`).
