# Philadelphia: how the model-ready data were made

| | |
|---|---|
| Unit type and map | Election division (Philadelphia's precinct), on the City's current Political_Divisions layer (edited 2026-09), which is the map in force for 2021P–2024G |
| Units | 1,703 divisions; all 1,703 in the bundle |
| Years covered | Ballot questions: May 2014 primary to April 2024 primary. Federal races: 2008–2024 |
| Ballot measures | 56: 48 City of Philadelphia (charter and bond) questions, 8 Commonwealth of Pennsylvania questions |
| Federal contests | 11: President 2008, 2012, 2016, 2020, 2024; US Senate 2010, 2012, 2016, 2018, 2022, 2024 |

Bundle: `output/atlas/overview/bundles/philadelphia/`, built by
`code/atlas/overview/01_bundles.R` from the fit input
`data/bbmm_benchmarks/philadelphia_2024align.rds`. That file is built from
`data/PA/realign_2024/output/final_datasets/phl_dem_rep_yes_no.csv` by
`data/PA/realign_2024/scripts/06_build_party_dataset.R` and `07_fit_em_zeta03.R`. The registry
entry is in `code/atlas/build_panels.R`. The README is `data/PA/realign_2024/README.md`, which
supersedes `data/PA/README.txt` for division-level work.

## Raw data

- **Returns:** Philadelphia City Commissioners division-level result files (all vote types summed).
  - `data/PA/raw/results/`: 2014 primary to 2026 primary, from
    `vote.phila.gov/resources-data/past-election-results/archived-data-sets/` (per
    `data/PA/README.txt`).
  - `data/PA/raw/results_pre2014/`: `2008`, `2010` and `2012_General_WD.csv`, downloaded
    2026-10-17 from `vote.phila.gov/files/election-results/`. SHA-256 prefixes are in the README.
- Ballot questions and federal races come from the same files.
- Ballot wording: `data/PA/final/phl_ballot_question_labels.csv` and `data/PA/raw/ballot_question_text/`.
- **Parsing:** `data/PA/realign_2024/scripts/01_parse_returns.R`, which writes
  `realign_2024/output/native/phl_native_long.csv` (the 67 contests, all candidates and responses).

## Shapefiles

- **Target:** the City's current Political_Divisions layer (2026-09), at
  `data/PA/raw/shapefiles/current_2026-09/political_divisions.geojson`. No download URL is
  recorded.
  - Written with 2020 population to `data/PA/realign_2024/output/geometry/phl_divisions_2024.gpkg`
    (EPSG:2272).
  - Join key: `join_id` = `PHL_D<WWDD>`.
- **Source maps:**
  - OpenDataPhilly historic division layers 2008-12, 2009, 2010, 2011 and 2012-09, from
    `github.com/opendataphilly/odp-data-storage/philadelphia-wards-divisions`.
  - The 2013-02, 2016, 2018-01, 2018-08 and 2019-09 layers.
  - VEST PA 2016, 2018 and 2020 (`data/PA/raw/shapefiles/vest/`).
  - All are in `data/PA/raw/shapefiles/`.
- **Blocks:** `data/PA/raw/census_blocks/tiger2020_zip/` (`tl_2020_42_tabblock20`).

## Alignment across years

- **Method: the NYC 2020-block-population crosswalk.**
  - Every 2020 block (`POP20`; 17,554 blocks, 1,603,797 residents) is assigned whole, by its
    Census internal point, to one source division and one 2024 division. The fallbacks are
    largest overlap, then the nearest polygon within 100 m.
  - Weight = pop(source ∩ target) / pop(source). Blocks are never split by area.
  - A zero-population source falls back to area. This happens once, in 2008.
- **Source map per election** (`realign_2024/crosswalks/election_vintage.csv`):
  - 2008G → ODP 2008-12
  - 2010G and 2012G → VEST 2016, with division 26-24 restored from ODP 2012-09
  - 2014P–2017G → VEST 2016
  - 2018G and 2019P → VEST 2018
  - 2019G–2020G → VEST 2020
  - 2021P–2024G → current layer, native with no allocation
- VEST was chosen over the ODP layers by a turnout-fit test
  (`realign_2024/metadata/vintage_turnout_test.csv`).
- **Rounding:** `estimated_votes` are fractional. `integer_votes` are a largest-remainder rendering
  within each contest × choice, which preserves totals. The model-ready Dem/Rep/Yes/No file uses
  the integer columns.
- **Scripts:** `data/PA/realign_2024/scripts/02_vintage_audit.R`, `02b_vintage_turnout_test.R`,
  `03_build_crosswalks.R`, `04_align_results.R` and `05_validate.R`.
  - Crosswalks: `realign_2024/crosswalks/phl_<vintage>_to_2024.csv`.
  - Block assignments: `blocks_<vintage>_to_2024.csv`.

## Summary statistics from alignment

- `realign_2024/metadata/alignment_summary.csv`: native votes equal allocated + unallocated for
  every contest.
  - Estimated (non-exact) target divisions: 154 in 2008, 80 in 2010–2012, 79 in 2014–2017, 41 in
    2018–2019P, 8 in 2019G–2020, and 0 from 2021.
- **Unallocated** (`realign_2024/metadata/unallocated_votes.csv`): federal-only overseas and
  military pseudo-precincts with no geography. These votes are held aside, 7,639 in total:
  - 2020 President: 2,180
  - 2022 Senate: 621
  - 2024 President: 2,475
  - 2024 Senate: 2,363
- `realign_2024/metadata/alignment_checks.csv`: 161 conservation checks, all passing. Fractional
  and integer sums equal native totals.
- `realign_2024/output/final_datasets/pair_total_checks.csv`: 67 contests.
- Native files reproduce the certified totals exactly for Obama/McCain 2008, Obama/Romney 2012,
  Clinton/Trump 2016 and Biden/Trump 2020.
- County-total rows: 52 of 53 match. The exception is a blank cell in the 2021P Q5 "No" row.
- 2021–2024 identity: 100,477 cells, all exact.
- Every 2024 division has at least 100 residents in 2020.

## What is in the model-ready files

56 ballot questions, success = Yes, n = Yes + No.

**Statewide (Commonwealth of Pennsylvania), 8:**
- `2016_04_pa_amend_q2` (abolish Philadelphia Traffic Court, state constitution)
- `2016_11_pa_amend` (judicial retirement age 75)
- `2017_11_pa_amend` (homestead exemption)
- `2019_11_pa_amend` (Marsy's Law; never certified)
- `2021_05_pa_amend_q1`, `2021_05_pa_amend_q2`, `2021_05_pa_amend_q3`
- `2021_05_pa_referendum_q4`

**Local (City of Philadelphia charter and bond questions), 48:**
- 2014–2016:
  - `2014_05_phl_charter_q1`–`q3`, `2014_11_phl_bond`, `2014_11_phl_charter_q1`, `q2`
  - `2015_05_phl_charter_q1`–`q4`, `2015_11_phl_bond`, `2015_11_phl_charter_q1`, `q2`
  - `2016_04_phl_charter_q3`, `2016_11_phl_bond`
- 2017–2020:
  - `2017_05_phl_charter_q1`, `q2`, `2017_11_phl_bond`
  - `2018_11_phl_bond`
  - `2019_05_phl_charter_q1`–`q4`, `2019_11_phl_bond`, `2019_11_phl_charter`
  - `2020_06_phl_charter_q1`, `q2`, `2020_11_phl_bond_q4`, `2020_11_phl_charter_q1`–`q3`
- 2021–2024:
  - `2021_05_phl_charter_q5`, `2021_11_phl_charter_q1`–`q4`
  - `2022_05_phl_charter_q1`–`q4`, `2022_11_phl_charter_q1`, `q2`
  - `2023_05_phl_charter_q1`–`q4`, `2023_11_phl_charter_q1`
  - `2024_04_phl_charter_q1`

Jurisdictions are taken from the `jurisdiction` column of
`realign_2024/output/final_datasets/phl_dem_rep_yes_no_column_key.csv`. Primaries are included,
because most charter questions are on primary ballots.

**Not available** (`realign_2024/output/final_datasets/contest_coverage.csv`):
- The May 2018 charter questions (3): no division or ward results were published.
- April 2016 Question 1: moved to November after printing, so its votes were not counted.
- The 2008–2013 questions: citywide totals only.
- 2025–2026 questions: the build ends at 2024G.

**Federal races:** the 11 listed above, Democratic vs Republican nominees. Third parties and
write-ins are dropped. There was no PA Senate race in 2014.

**Units excluded:** none. The bundle drops unit × question rows with n = 0 (one division for
`2017_05_phl_charter_q2`).

Note: the atlas fit included the federal races as well as the questions (K = 8 by the 5% rule).
The bundle's `votes.csv` holds only the 56 questions.

## Other datasets

- `data/PA/final/divisions_current/phl_division_all_ballot_questions.csv` (+ `_column_key.csv`)
  - 1,703 divisions × 61 questions: 53 city and 8 statewide.
  - It adds 5 city charter questions not in the bundle: `2025_05_phl_charter_q1`–`q3`,
    `2026_05_phl_charter_q1` and `q2`.
  - The divisions are the same 1,703 labels (current 2026-09 layer, `phl_divisions_current.gpkg`),
    but the file comes from the superseded 2026-10-02 alignment: ODP vintages, IoU > 0.95 carried
    whole, otherwise block area-share, with 2010 and 2020 blocks mixed. Values for 2014–2020 differ
    slightly from the bundle.
  - Siblings: `phl_division_statewide_ballot.csv` (8 statewide questions) and
    `phl_division_president_senate.csv` (7 contests, 2016–2024).
- `data/PA/final/phl_ward_ballot.csv` (+ key; `phl_ward_president_senate.csv`): 66 wards × 61
  questions (2014P–2026P) and 7 federal contests, on the 2024 wards (`phl_wards_2024.gpkg`). Built
  by `data/PA/scripts/`.
- `data/PA/realign_2024/output/aligned_2024/by_contest/<contest_id>.csv`: all candidates, write-ins
  and responses for the 67 contests, on the 1,703 divisions, with fractional and integer votes.
- `data/PA/raw/results/`: the raw City Commissioners files, 2014P–2026P.
  - They also carry candidate contests that were never parsed, for example judicial races in the
    2023 primary (`2023_Primary_Results.xlsx`), plus primaries and municipal offices.
  - Native divisions, with the vintage per election documented in the README.
- `data/PA/intermediate/phl_division_long.csv`: the older parse, 79 election × contest rows
  (questions and federal), native divisions.

## Known issues

- Same division labels do not mean the same lines. ODP and VEST disagree on 95 divisions (6,949
  residents) in 2014–2017. VEST was chosen by the turnout test, but off-year elections lean
  slightly toward ODP.
- Divisions 40-30 and 40-40 were redrawn after Nov 2020. Whether this happened before Nov 2024 is
  unknown; it moves 29 residents.
- Aligned 2020+ federal totals sit slightly below the certified totals (pseudo-precincts held
  aside).
- `2019_11_pa_amend` (Marsy's Law) was voted on but never certified, and was later struck down.
- 17 of 61 ballot wordings in the labels file are faithful summaries, not verified official text
  (`data/PA/README.txt`).
- Bloc names are drafts.
