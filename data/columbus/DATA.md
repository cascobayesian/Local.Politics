# Columbus (Franklin County): how the model-ready data were made

| | |
|---|---|
| Unit type and map | Franklin County Board of Elections (BOE) ward, 2024 boundaries. Ward code = 3-digit subdivision + 2-digit ward; a township or village without wards is one unit |
| Units | 159 wards, all of Franklin County (87 in the City of Columbus); all 159 in the bundle |
| Years covered | Ballot measures: Nov 2012 to May 2025. Federal races: 2012–2024 |
| Ballot measures | 17 Ohio statewide issues |
| Federal contests | 9: President 2012, 2016, 2020, 2024; US Senate 2012, 2016, 2018, 2022, 2024 |

Bundle: `output/atlas/overview/bundles/columbus/`, built by `code/atlas/overview/01_bundles.R`
from `data/Columbus/bbmm_statewide/data/` (`columbus_statewide_ballot.csv`,
`columbus_statewide_ballot_column_key.csv`, `columbus_statewide_national.csv`). The registry entry
is in `code/atlas/build_panels.R`. READMEs: `data/Columbus/README.md` (data build and alignment),
`data/Columbus/bbmm/README.txt` and `data/Columbus/bbmm_statewide/README.txt` (fit workflows).

## Raw data

- **Source:** Franklin County BOE precinct result spreadsheets, 2012–2026. These are every
  non-PDF result file the BOE posts, plus two PDFs for the Aug 2023 special.
  - Files: `data/Columbus/raw/results/<year>/` (for example
    `2024/Official-Results-by-Precinct.xlsx`).
  - The BOE site is `https://vote.franklincountyohio.gov/` (from the saved page
    `raw/shapefiles/gis_page.html`). No download URL for the result files is recorded.
- **Parsing:** `data/Columbus/scripts/01_parse_results.R`, `01b_parse_aug2023_pdf.py` (Aug 2023
  PDF) and `02_precinct_keys.R`. Precincts are matched on a constructed six-character code, not
  on names.
- Ballot measures and federal races come from the same BOE files. US House is parsed but not
  used.

## Shapefiles

- **Source:** the Franklin County BOE "GIS Shape Files" page (`/maps-and-data/gis-shape-files` on
  `vote.franklincountyohio.gov`).
  - Precinct vintages 2012, 2013, 2014, 2015 (partial), 2017, 2019, 2022, 2023 and 2025 are in
    `data/Columbus/raw/shapefiles/<year>/`; the original zips are in `zips/`.
- **Target:** no 2024 shapefile is posted. The 2025 `VotingPrecinct` layer matches the Nov 2024
  precinct list exactly (888 of 888). Its one extra precinct, OBETZ-D, lies inside a single-ward
  village, so the 2025 wards are the 2024 wards.
  - The wards are the 2025 precincts dissolved by `WARDCODE`
    (`data/Columbus/scripts/03_crosswalk.R`).
  - Output: `data/Columbus/final/columbus_wards_2024.gpkg`, with a copy at
    `data/Columbus/bbmm_statewide/data/columbus_statewide_wards_2024.gpkg`.
  - The join key is `join_id` = `W` + ward code, for example `W01001`.

## Alignment across years

- **Method: areal, not block-population.** Each election's precincts are intersected with the
  2024 wards.
  - Weight = area(precinct ∩ ward) / area(source precinct).
  - Slivers under 1% of a precinct are dropped and the rest renormalised.
- **Vintage per election:** `VINTAGE_OF` in `data/Columbus/scripts/04_build_final.R`.
  - 2012 → 2012 map
  - 2013 → 2013 map
  - 2014 to May 2017 → 2014 map
  - Nov 2017 to 2018 → 2017 map
  - 2019 to May 2022 → 2019 map
  - Nov 2022 → 2022 map
  - Aug 2023 to May 2026 → 2025 map
  - A precinct code missing from its vintage takes its geometry from the nearest vintage that
    has it (5 precincts).
- Precincts lying wholly inside one ward carry their votes whole. Every precinct of the 2025
  vintage nests in one ward (diagnostics below), so Aug 2023 to May 2026 are in effect native.
- **Rounding:** the ward totals are fractional and are rounded to integers with `round()` in
  `04_build_final.R` (plain rounding, not largest remainder). Bundle totals can therefore differ
  from county totals by about 1 vote. For example, Issue 1 of 2012 gets 179,181 Yes in the bundle
  vs 179,180 in `bbmm_statewide/raw_data/columbus_ballot_measure_metadata.csv`.
- **Scripts:** `data/Columbus/scripts/03_crosswalk.R` and `04_build_final.R` (run by
  `scripts/run_all.sh`). The statewide subset is built by
  `data/Columbus/bbmm_statewide/scripts/` (from frozen copies in `bbmm_statewide/raw_data/`).

## Summary statistics from alignment

- `data/Columbus/intermediate/vintage_match.csv`: every election matches its vintage on at least
  99.9% of precinct codes (README).
- `data/Columbus/intermediate/crosswalk_diagnostics.csv`: share of precincts lying 99% or more
  inside one ward, and share split more than 10%, by vintage.

  | Vintage | Nested ≥ 99% | Split > 10% |
  |---|---|---|
  | 2012 | 89.0% | 6.2% |
  | 2014 | 92.6% | 4.0% |
  | 2017 | 94.2% | 2.9% |
  | 2019 | 94.5% | 2.1% |
  | 2023 | 98.0% | 0.2% |
  | 2025 | 100% | 0% |

- Ward totals equal precinct totals for every column (README).
- `data/Columbus/intermediate/county_total_check.csv`: precinct sums equal the file's own COUNTY
  TOTAL row for every statewide, countywide and federal contest.
- County federal totals match official results (Obama 346,373 in 2012; Biden 409,144;
  Harris 380,518).
- City of Columbus measures leak into up to 5 non-Columbus wards because of annexations, carrying
  under 0.1% of their votes.
- `data/Columbus/bbmm_statewide/r_outputs/workflow_validation.csv`: 101 checks, all passing.

## What is in the model-ready files

- **Ballot measures:** 17 Ohio statewide issues. success = Yes. Every ward voted on every one.
  - `2012_11_Q1` constitutional convention, `2012_11_Q2` redistricting commission
  - `2014_05_Q1` infrastructure bonds
  - `2015_11_Q1` legislative redistricting, `2015_11_Q2` anti-monopoly, `2015_11_Q3` marijuana
  - `2017_11_Q1` victims' rights, `2017_11_Q2` drug prices
  - `2018_05_Q1` congressional redistricting, `2018_11_Q1` drug/sentencing reform
  - `2022_11_Q1` bail, `2022_11_Q2` citizenship to vote
  - `2023_08_Q1` 60% threshold, `2023_11_Q1` abortion rights, `2023_11_Q2` marijuana
  - `2024_11_Q1` redistricting commission, `2025_05_Q1` infrastructure bonds

  Titles are from `bbmm_statewide/raw_data/columbus_ballot_measure_metadata.csv`.
- **Measures dropped:** the 57 county, city, school and library measures in the full build (see
  Other datasets). They are left out of this variant on purpose (`ballot_scopes` in
  `bbmm_statewide/scripts/common.R`).
- **Federal races:** the 9 listed above, Democratic vs Republican nominees.
- **Units excluded:** none. Columbus wards in Delaware and Fairfield Counties are not part of the
  unit set.

## Other datasets

- `data/Columbus/final/columbus_ward_ballot.csv` (159 wards) and `columbus_ballot_columns.csv`
  (74 rows)
  - All 74 Yes/No measures on the ballot in at least 25% of county precincts, Mar 2012 to
    May 2026. By scope:
    - 17 Ohio statewide
    - 17 Franklin County
    - 35 City of Columbus
    - 4 Columbus City School District
    - 1 Columbus Metropolitan Library District
  - Same 159-ward map. A measure not on a ward's ballot is 0/0.
- `data/Columbus/bbmm/data/columbus_ballot.csv` (+ `_column_key.csv`, `columbus_combined.csv`)
  - The same 74 measures in fit-input layout: ids `<year>_<month>_Q<i>`, `join_id` `W…`.
  - 159 wards on the same map. This is the input to the all-measures fit (K = 6) in
    `data/Columbus/bbmm/`.
- `data/Columbus/intermediate/precinct_results_long.csv.gz` (about 2.58 million rows) and
  `precinct_results.csv.gz`
  - Every contest parsed from the BOE files: 28 elections, Mar 2012 to May 2026, 2,970
    election × contest combinations.
  - Includes all local questions (also those under 25% coverage, such as local-option and
    suburban school levies) and every candidate contest.
  - Units are native precincts, not aligned. `intermediate/crosswalk.csv` maps each precinct
    vintage to the 2024 wards.
- `data/Columbus/intermediate/aug2023_special_long.csv`: the Aug 2023 special, parsed from PDF.

## Known issues

- Areal weights assume voters are spread evenly over a precinct.
- Votes are areal estimates wherever a precinct crossed a 2024 ward line: 2–6% of precincts per
  vintage (`data/Columbus/bbmm/README.txt`).
- Units cover all of Franklin County, not only the city. Columbus-wide measures come out about 3%
  below the BOE citywide totals because the Delaware and Fairfield parts are missing (README).
- Parsing traps (README):
  - 2012 lists precincts twice.
  - 2013 and 2014 interleave subtotals.
  - 2019 and 2020 have five sub-columns (only TOTAL is used).
  - 2021 and later have four rows per precinct (summed).
  - The 2022+ party field says "Non" for every candidate.
- Not available: the May 2023 primary (PDF only, no statewide issue) and the May 2021 primary.
- 159 units is small. The log-likelihood stops rising above about K = 12.
