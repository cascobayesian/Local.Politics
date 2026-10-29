# Dallas County: how the model-ready data were made

| | |
|---|---|
| Unit type and map | County election precinct, Texas Legislative Council (TLC) 24G map (2024; identical to 22P and 22G) |
| Units | 885 precincts on the map; 820 in the bundle (65 precincts have no votes in any fitted ballot contest) |
| Years covered | Ballot measures: Nov 2013 to Nov 2025 (8 elections). Federal races: 2012–2024 |
| Ballot measures | 74 Texas constitutional amendments |
| Federal contests | 9: President 2012, 2016, 2020, 2024; US Senate 2012, 2014, 2018, 2020, 2024 |

Bundle: `output/atlas/overview/bundles/dallas/`, built by `code/atlas/overview/01_bundles.R` from
`data/Dallas/final/data/` (`dallas_ballot.csv`, `dallas_ballot_column_key.csv`,
`dallas_president_senate.csv`). The registry entry is in `code/atlas/build_panels.R`, and the
README is `data/Dallas/final/README.txt`.

## Raw data

All returns come from Dallas County Elections, at
`https://www.dallascountyvotes.org/election-results/historical/<slug>/`. The pages are saved in
`data/Dallas/final/raw_data/pages/`, the list is in `target_pages.txt`, and the URLs are in
`raw_data/sources.txt`.

- **Clarity ENR precinct-detail XML**
  (`https://results.enr.clarityelections.com/TX/Dallas/<eid>/<ver>/reports/detailxml.zip`):
  - Covers Nov 2012, 2013, 2014, 2015, 2016, 2018, 2019, 2020, 2021, May 2022, Nov 2022, 2024
    and 2025.
  - Files: `data/Dallas/final/raw_data/clarity/<eid>(.zip)`.
- **Nov 2023:** the county's `231107 Results.xls`, a Clarity SpreadsheetML export inside
  `PctByPct.zip` (`raw_data/county_docs/november-7-2023-.../`).
- **Nov 2017:** the county canvass "PctbyPct Totals" PDF (report EL52), converted with
  Ghostscript (`raw_data/county_docs/november-7-2017-.../el52_totals.{pdf,txt}`).
- **Parsing:** `data/Dallas/final/scripts/00_parse_results.py` writes
  `data/Dallas/final/raw_data/dallas_results_long.csv.gz` (every contest, every election).
  - Votes are summed over vote types.
  - Reporting units are ballot-style splits (`1004-01`); the first four characters are the
    precinct.
- Ballot measures and federal races come from the same files.

## Shapefiles

- TLC precinct files (Dallas County, CNTY 113):
  - 12G–18G from `https://data.capitol.texas.gov/dataset/archived_vtds_2010s`.
  - 20G, 22P, 22G, 24G and 26P from `https://data.capitol.texas.gov/dataset/precincts`.
  - Raw zips: `data/Dallas/final/raw_data/precincts/tlc_precincts<v>.zip`, with extracts
    `dallas_precincts_<v>.gpkg`.
- Target: TLC 24G, 885 precincts, `data/Dallas/final/data/dallas_precincts_2024.gpkg` (the join
  key is `join_id` = `DALLAS_<precinct>`). 26P (791 precincts, used from 2026) is not the target.

## Alignment across years

- **Vintage per election** (`data/Dallas/final/r_outputs/election_vintage_match.csv`): each
  election uses the latest vintage on or before it whose labels cover every reporting precinct.
  - 2012 → 12G
  - 2013, 2014, 2015 → 14G
  - 2016, 2017 → 16G
  - 2018 → 18G
  - 2019, 2020, 2021 → 20G
  - May 2022 → 22P
  - 2023 → 22G
  - 2024, 2025 → 24G
  - Coverage is 100% in every case.
- **Native, no allocation:** May 2022, 2023, 2024 and 2025 (their vintages are identical to 24G).
- **Moved onto 24G:** 2012–2021.
  - 2020 Census blocks (TIGER 2020, `POP20`) are intersected with the source and the 2024
    precincts in EPSG:2276.
  - Each piece carries block population × (piece area / block area).
  - Each source precinct's votes are split by its population share in each 2024 precinct, with
    fallback to housing units and then to area.
  - 2020 block populations are used for 2012–2018 as well.
- **Rounding:** integer allocation by largest remainder within each source precinct, so source
  and county totals are preserved.
- **Script:** `data/Dallas/final/scripts/01_prepare_inputs.R`. The crosswalks are
  `data/Dallas/final/r_outputs/crosswalk_{12g,14g,16g,18g,20g}_to_24g.csv`.

## Summary statistics from alignment

- `data/Dallas/final/r_outputs/parse_total_checks.csv`: 2,380 checks. Every parsed choice total
  matches the source's own published total.
- County totals match the official canvasses (README): Clinton 461,080 / Trump 262,945 in 2016,
  and Biden 598,576 / Trump 307,076 in 2020.
- `data/Dallas/final/data/pair_total_checks.csv`: 166 rows (source vs allocated votes, every
  column). All differences are 0.
- `data/Dallas/final/data/precinct_coverage_flags.csv`: targets that are exact matches to one
  source precinct.

  | Vintage | Exact matches (of 885) | Estimated splits / combinations |
  |---|---|---|
  | 12G | 673 | 200 |
  | 14G, 16G, 18G | 688 | 189 / 188 / 188 |
  | 20G | 739 | 137 |

  The remaining few 2024 precincts (8–12 per vintage) lie outside that vintage's coverage and
  get 0 votes for those years.
- `data/Dallas/final/r_outputs/vintage_stability.csv`: 14G = 16G = 18G and 22P = 22G = 24G
  exactly. Only 655 of 798 2020 labels survive into 22P.

## What is in the model-ready files

- **Ballot measures:** 74 statewide constitutional amendments. success = Yes, n = Yes + No.
  - By election: Nov 2013 (9), 2015 (7), 2017 (7), 2019 (10), 2021 (8), May 2022 (2),
    Nov 2023 (14), Nov 2025 (17).
  - Ids follow `<yyyy>_<mm>_tx_prop_<nn>`. All are statewide.
  - Local city, ISD and county propositions are excluded because each covers only part of the
    county.
- **Federal races:** the 9 listed above, Democratic vs Republican nominees only. There was no US
  Senate race in 2016 or 2022, and Nov 2022 carried no statewide amendment.
- **Units excluded:** 65 precincts with no votes in any fitted ballot contest, mostly tiny and
  lettered split precincts such as `30T4` (README). These include `DALLAS_1077`, `DALLAS_1140`,
  and others. The bundle also drops unit × question rows with n = 0, so per-question coverage is
  773–805 units.

## Other datasets

- `data/Dallas/final/raw_data/dallas_results_long.csv.gz` (852,337 rows)
  - Every contest in 15 elections, Nov 2012 to Nov 2025: 1,151 contests, of which 501 are
    questions.
  - Besides the 74 amendments, it holds about 427 local or other questions, including:
    - City of Dallas propositions: 3 in 2012, 9 charter questions in 2014, 10 in 2017, 18 in
      2024, and others.
    - Suburban city propositions (Carrollton, Coppell, Richardson, and others).
    - Dallas ISD and other ISD propositions.
    - The countywide 2017 "Dallas County School Prop A".
    - Local-option elections.
  - All candidate contests too (federal, state, county, city, judicial).
  - Units are the native precinct labels of each election. The file is not aligned, but the
    crosswalks in `data/Dallas/final/r_outputs/crosswalk_*_to_24g.csv` could move pre-2022 rows;
    May 2022 to 2025 are already on the 24G labels.
- `data/Dallas/final/raw_data/county_docs/`: county canvass zips and PDFs per election (source
  documents).

## Known issues

- The README says "even-year Novembers carry no statewide amendments". However, the long file
  has a 2014-11-04 question "State Prop- State Highway Fund" in 765 precincts. It is not in the
  bundle: the amendment regex in `01_prepare_inputs.R` does not match that contest name. This was
  found while checking for this document and should be verified.
- The amendments from 2013 and May 2022 drew votes in only 94.3–94.9% of precincts (low
  turnout).
- 2020 block populations are applied to 2012–2018, and uniform population is assumed within
  split blocks.
- 17 target labels contain a letter (tiny splits with almost no voters).
- Short titles are paraphrases. The 2023 and 2025 titles are reused from the Travis workflow.
