# Austin (Travis County): how the model-ready data were made

| | |
|---|---|
| Unit type and map | County election precinct, Texas Legislative Council (TLC) 24G map (identical to 22G). This is the map in force for every election from Nov 2022 to Dec 2025 |
| Units | 287 precincts on the map; 286 in the bundle (`TRAVIS_175` has no voters and is left out) |
| Years covered | Ballot measures: Nov 2023 and Nov 2025. Federal races: 2020 and 2024 |
| Ballot measures | 31 (14 in 2023, 17 in 2025), all Texas constitutional amendments |
| Federal contests | 4: `2020_president`, `2020_senate`, `2024_president`, `2024_senate` |

Bundle: `output/atlas/overview/bundles/austin/`, built by `code/atlas/overview/01_bundles.R`
from `data/Travis/final/data/` (`travis_ballot.csv`, `travis_ballot_column_key.csv`,
`travis_president_senate.csv`). The registry entry is in `code/atlas/build_panels.R`.
The project README is `data/Travis/final/README.txt`.

## Raw data

- **Ballot measures and 2024 federal races:** Travis County Clarity ENR precinct-detail XML
  (`results.enr.clarityelections.com/TX/Travis/`). Votes are summed over vote types. The parsed
  long file is `data/Travis/final/raw_data/clarity/travis_clarity_precinct_long.csv.gz`. The
  original download and parser are in `data/Travis/clarity/`: `raw/<EID>/detail.xml`,
  `elections.json`, `parse.py`.
- **2020 President and Senate:** OpenElections `openelections-data-tx`,
  `data/Travis/final/raw_data/openelections/20201103__tx__general__travis__precinct.csv`. The
  README records that county totals match the canvass (Biden 435,860, Trump 161,337).
- Clarity begins in Nov 2022. Earlier amendment elections (2015–2021 and May 2022) exist only
  as county PDF canvasses, so they are not included.

## Shapefiles

- Source: TLC precinct files, `data.capitol.texas.gov/dataset/precincts` (20G, 22G, 24G and
  26P). The raw zips are `data/Travis/final/raw_data/precincts/tlc_precincts{20g,22g,24g,26p}.zip`,
  and the Travis extracts are `travis_precincts_<v>.gpkg` in the same folder.
- Target: TLC 24G, 287 precincts, written to `data/Travis/final/data/travis_precincts_2025.gpkg`
  (the join key is `join_id` = `TRAVIS_<precinct>`). `01_prepare_inputs.R` checks that 22G and 24G
  are identical (287 shared labels, minimum IoU 1).
- The county's "2025 Plan" (TLC 26P, 308 precincts, in force from 1 Jan 2026) is not the target.

## Alignment across years

- **2022–2025 (every ballot measure and the 2024 races):** these are native, because they were
  reported on the target labels. No allocation is needed.
- **2020 President and Senate:** these were moved from TLC 20G (247 precincts) onto the 287
  target precincts. The 2020 map was renumbered wholesale (median same-label IoU 0).
- **Method:** 2020 Census blocks (TIGER 2020, `POP20`) are intersected with the 2020 and 2025
  precincts in EPSG:2277. Each piece carries block population × (piece area / block area). Each
  source precinct's votes are split by its population share in each target, with fallback to
  housing units and then to area.
  - This is an areal split of blocks. The skill's standard "whole block by internal point"
    method is not what was used here.
- **Rounding:** integer allocation by largest remainder within each source precinct, so every
  source total and county total is preserved.
- **Scripts:** `data/Travis/final/scripts/00_extract_precincts.R` and `01_prepare_inputs.R`
  (crosswalk and allocation). The crosswalk is
  `data/Travis/final/r_outputs/crosswalk_2020_to_2025_precincts.csv`.

## Summary statistics from alignment

- `data/Travis/final/data/pair_total_checks.csv`: 8 rows (4 contests × 2 sides). Source votes
  equal allocated votes in every row, so every difference is 0.
- `data/Travis/final/data/precinct_coverage_flags.csv`: 38 of 287 targets are exact matches to a
  single 2020 precinct. The other 249 are estimated splits or combinations
  (`logs/01_prepare_inputs.log`).
- Ten 2020 polygons have no reported votes. Together they hold 16 residents
  (`r_outputs/precincts_2020_without_returns.csv`).
- Precinct 999 (3 ballots, Dec 2025 Pflugerville runoff) is non-geographic and dropped. It
  carries no ballot measure or federal race.

## What is in the model-ready files

- **Ballot measures:** 31 Texas-wide constitutional amendments.
  - Ids: `2023_11_tx_prop_01`–`_14` and `2025_11_tx_prop_01`–`_17`.
  - success = Yes/For, n = Yes + No.
  - All are statewide; there are no local measures in the bundle.
  - Scope is set by `TX_BALLOT_SCOPE=statewide`, the default. Local measures were dropped
    because each covers only part of the county (see Other datasets).
  - Party-primary propositions are excluded.
- **Federal races:** President 2020 and 2024, US Senate 2020 and 2024. These are Democratic vs
  Republican nominees; minor candidates and write-ins are excluded. The bundle builder keeps
  contests in which each party has at least 5% of the two-party vote.
- **Units excluded:** `TRAVIS_175` (no voters, so it has no bloc assignment). The bundle also
  drops unit × question rows with n = 0.

## Other datasets

- `data/Travis/final/archive/all_measures_53_20261001/data/travis_ballot.csv` and
  `travis_ballot_column_key.csv`
  - The earlier 53-measure version, on the same 287-precinct map (native, 2022–2025).
  - It adds 22 local measures to the 31 state amendments:
    - Travis County: 3
    - City of Austin: 4 (2022 Prop A, 2023 May Props A and B, 2025 Prop Q)
    - Austin ISD: 4
    - Pflugerville ISD: 9
    - ACC District: 1
    - Travis County ESD No. 2: 1
  - A measure is kept if it appears in at least 10% of precincts.
  - 287 rows. Fits and maps are kept alongside in `archive/all_measures_53_20261001/`.
- `data/Travis/final/r_outputs/ballot_measure_inventory.csv`: an inventory of 362 ballot
  measures across all Clarity elections, with precinct coverage and a flag for whether each
  qualifies (53 do).
- `data/Travis/clarity/travis_clarity_precinct_long.csv` (808,114 rows) and
  `travis_clarity_contests.csv` (951 contests)
  - Every contest in 16 Clarity elections, Nov 2022 to May 2026. Of these, 398 are questions;
    the rest are candidate contests, including party primaries, runoffs and city and school
    races.
  - Units are native precinct labels. Elections through Dec 2025 use the target 287-precinct
    map; 2026 elections use the 26P map (308 precincts) and are not aligned.

## Known issues

- 2020 votes on the 2025 map are estimates. Uniform population within split blocks is assumed.
- Only 4 federal contests. The README notes the national fit's log-likelihood is flat from K = 9.
- Short titles for the amendments come from news and Wikipedia summaries, not the ballot
  language (README).
- Only two amendment elections (2023 and 2025) are available on Clarity.
