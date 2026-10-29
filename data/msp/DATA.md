# Minneapolis–St. Paul: how the model-ready data were made

| | |
|---|---|
| Unit type and map | Precinct, Minnesota Secretary of State (SOS) precinct layer for the 5 Nov 2024 general election |
| Units | 223 (Minneapolis 137, St. Paul 86); all 223 in the bundle |
| Years covered | Ballot questions: 2012–2024. Federal races: 2012–2024 |
| Ballot measures | 25 in total: 4 statewide amendments, 21 city or school-district questions |
| Federal contests | 10: President 2012, 2016, 2020, 2024; US Senate 2012, 2014, 2018 regular, 2018 special, 2020, 2024 |

Bundle: `output/atlas/overview/bundles/msp/`, built by `code/atlas/overview/01_bundles.R` from
`data/msp/bbmm/data/` (`msp_ballot.csv`, `msp_ballot_column_key.csv`,
`msp_president_senate.csv`). These are copies of `data/msp/final/msp_precinct_*.csv`. The registry
entry is in `code/atlas/build_panels.R`. READMEs: `data/msp/README.txt` (data and alignment) and
`data/msp/bbmm/README.txt` (fit).

## Raw data

- **Federal races and statewide amendments (even years):** attribute tables of the MN SOS
  precinct GIS layers.
  - Source: `enterprise.gisdata.mn.gov/aghost/rest/services/us_mn_state_sos`, layers
    `bdry_electionresults_2012_2020` and `_2022_2030`.
  - Files: `data/msp/raw/sos_gis/mn_<year>.geojson`, converted to
    `data/msp/raw/shapefiles/mn_precincts_<year>/`.
  - Cross-checked against SOS precinct text files (`raw/sos_media/ConstAmendPct_*.txt` and
    others) where downloadable.
- **City and school questions, 2016–2024:** SOS "Municipal and School District Races and
  Questions by Precinct" (`localPrct.txt`) from `https://electionresultsfiles.sos.mn.gov`.
  Files: `data/msp/raw/sos_media/local_<date>.txt`, with ballot wording in `bq_<date>.txt`.
- **2012–2014 city and school questions:** the SOS results archive
  (`electionresults.sos.mn.gov/Results/MediaFile_Archive`, mediafileid 9).
  - The archive sits behind a bot wall, so it was read in a browser on 2026-10-02 and
    transcribed.
  - Files: `data/msp/raw/sos_media/browser_extract_2012_2014.txt` (SHA-256 checked) and
    `ballot_questions_2012_2014_browser.txt`.
- `data/msp/raw/msp_question_metadata.csv`: question metadata.
- **Scripts:** `data/msp/scripts/00_download.sh` and `01_parse_results.R`.

## Shapefiles

- MN SOS precinct GIS layers, one per even-year general election, 2012–2024 (source as above).
  Hennepin and Ramsey cuts are made by `data/msp/scripts/00_make_geography.R`.
- Target: the 2024 layer, restricted to Minneapolis and St. Paul.
  - Output: `data/msp/final/msp_precincts_2024.gpkg` (EPSG:26915), with a copy at
    `data/msp/bbmm/data/msp_precincts_2024.gpkg`.
  - Join key: `join_id` = `MSP_<county fips>_<precinct code>`.

## Alignment across years

- **Vintage per election:** even years use their own SOS layer. Odd years have no layer; each
  takes the vintage whose labels match exactly (`data/msp/intermediate/vintage_label_match.csv`).
  - 2013 → 2012
  - 2019 → 2018
  - 2021 → 2020
  - 2023 → 2022 (a tie with 2024)
- **Method:** census-block population overlay onto the 2024 precincts (`ALLOC_METHOD=population`,
  the default).
  - Blocks are intersected with each source precinct and the 2024 precincts. Each piece carries
    block population × (piece area / block area).
  - Weight = pop(source ∩ target) / pop(source).
  - 2010 blocks (`POP10`) are used for the 2012 and 2014 maps, and 2020 blocks (`POP20`) from
    2016 on.
  - Every precinct has residents, so the area fallback is never used.
- **Moved:** every election from 2012 to 2023 is moved onto the 2024 map. 2024 needs no
  allocation, and 2023 is nearly native.
- **Rounding:** pieces under 0.5% of a precinct are dropped and the rest renormalised. Votes are
  then rounded by largest remainder, so every source precinct total and city total is preserved.
- **Scripts:** `data/msp/scripts/02_match_vintages.R`, `03_crosswalk_to_2024_precincts.R` and
  `04_build_final.R`, plus helpers in `msp_geo_funcs.R`.
- **Crosswalks:** `data/msp/intermediate/msp_precinct2024_crosswalk_population.csv` (used),
  `_area.csv` and `msp_precinct2024_crosswalk.csv`.

## Summary statistics from alignment

- `data/msp/final/msp_total_checks.csv`: 126 checks (election × contest × choice). The 2024
  precinct sums equal the source precinct files in every check (all differences 0).
- `data/msp/intermediate/gis_vs_sos_check.csv`: the GIS attributes match the SOS text files for
  every precinct.
- `data/msp/intermediate/msp_votes_reassigned_by_election.csv`: share of votes in a source precinct
  that the 2024 map splits. It is 49–60% in every pre-2022 election (for example 2012: 57.3%,
  2020: 52.0%), 3.0% in 2023, and 0 in 2024.
- `data/msp/intermediate/msp_alloc_method_comparison.csv`: area vs population weighting moves 4–6%
  of each election's votes, up to about 1,100 votes in a single 2024 precinct (README).
- **Sanity check (README):** adjacent-election two-party DFL correlations across the 223 precincts
  are high (2016 Pres vs 2018 Senate 0.96; 2020 vs 2024 Pres 0.90) and decay with time (2012 vs
  2024 Pres 0.32).

## What is in the model-ready files

25 ballot questions, success = Yes, n = Yes + No. Blank ballots are recorded in the column key,
not in n.

**Statewide** (constitutional amendments, on the ballot in all 223 precincts):

| question_id | Subject |
|---|---|
| `2012_11_mn_amend_q1` | Define marriage as one man and one woman |
| `2012_11_mn_amend_q2` | Require photo ID to vote |
| `2016_11_mn_amend_q1` | Independent council sets legislator pay |
| `2024_11_mn_amend_q1` | Renew lottery proceeds to environment trust fund |

**Local, Minneapolis only** (137 precincts), 14 questions:

- City charter: `2013_11_mpls_charter_q1`, `2013_11_mpls_charter_q2`,
  `2014_11_mpls_charter_q1`, `2014_11_mpls_charter_q2`, `2018_11_mpls_charter_q1`,
  `2020_11_mpls_charter_q1`, `2020_11_mpls_charter_q2`, `2021_11_mpls_charter_q1` (executive
  mayor), `2021_11_mpls_charter_q2` (Department of Public Safety), `2021_11_mpls_charter_q3`
  (rent control).
- Minneapolis Public Schools (SSD 1): `2016_11_mplsschools_levy_q1`,
  `2018_11_mplsschools_levy_q1`, `2018_11_mplsschools_levy_q2`, `2024_11_mplsschools_levy_q1`.

**Local, St. Paul only** (86 precincts), 7 questions:

- City: `2019_11_stp_referendum_q1` (organized trash collection), `2021_11_stp_ordinance_q1`
  (rent stabilization), `2023_11_stp_tax_q1` (sales tax), `2024_11_stp_levy_q1` (early
  childhood levy), `2024_11_stp_charter_q2` (even-year elections).
- St. Paul Public Schools (ISD 625): `2012_11_stpschools_levy_q1`, `2018_11_stpschools_levy_q1`.

Notes on scope and coverage:

- Both school districts are coterminous with their city. A city question's cells for the other
  city are empty, so they are absent from `votes.csv`. 3,412 of 5,575 precinct × question cells
  are observed.
- Within the joint fit, Minneapolis and St. Paul precincts are linked only through the 4
  statewide amendments (`data/msp/bbmm/README.txt`).
- There were no Hennepin or Ramsey county questions from 2012 to 2024. No primary carried a
  Minneapolis or St. Paul question, and 2015, 2017 and 2022 had no questions.
- **Federal races:** the 10 listed above, DFL vs Republican nominees. 2022 had no federal
  statewide race.
- **Units excluded:** none.

## Other datasets

- `data/msp/raw/sos_media/local_<date>.txt` for 20161108, 20171107, 20181106, 20191105, 20201103,
  20211102, 20221108, 20231107 and 20241105
  - The SOS statewide files of municipal and school-district races and questions by precinct
    (about 6,700–52,000 lines each).
  - Besides the questions used, they carry every city and school-board candidate contest, for
    example St. Paul council and school board.
  - Minneapolis ranked-choice city offices are noted in the README as not in the panel.
  - Native SOS precincts, not aligned. They also cover the rest of the state.
- `data/msp/raw/sos_gis/mn_<year>.geojson` (2012–2024 even years): SOS precinct layers whose
  attributes also hold other candidate results. The 2018 layer, for example, has US House,
  state senate and house, governor, secretary of state, auditor and attorney general. Native
  precincts, one layer per election, not aligned.
- `data/msp/hennepin_ramsey_2013_2021.csv` (65,598 rows; columns Precinct, Question, Response,
  Number_Votes, Election_Date)
  - Odd-year municipal and school results for 2013, 2015, 2017, 2019 and 2021, across 345
    precincts and 432 contests.
  - Despite the name it has no St. Paul or Ramsey rows. It covers Minneapolis (136 precincts,
    203 contests including ranked-choice mayor, council and Board of Estimate rounds, and the
    2013 and 2021 city questions) and Hennepin suburbs (Bloomington, Minnetonka, St. Louis Park,
    and others), plus suburban school-district questions.
  - Native precinct labels, not aligned.
  - Its provenance is not documented: no README or script references it, and the file is dated
    Sep 2023, before this build.

## Known issues

- Precinct labels are not places. Codes were reused for different land (same-label IoU 0). Across
  the 2020 → 2022 redistricting, 94% of the 125 Minneapolis labels present in both maps have
  IoU < 0.5.
- 2023 uses the 2022 map. Four St. Paul precincts were adjusted between 2022 and 2024, and the
  date of that change is not known. This puts 3.0% of 2023 votes through a split.
- 2010 blocks do not nest in the 2024 lines, so 2012–2014 lean more on the uniform-density
  assumption.
- Older layers run up to 3% outside the 2024 city boundary (digitising); renormalisation keeps
  those votes.
- In Minnesota a blank amendment ballot counts as No for passage. Blanks are not in n.
- The wordings of the 2012 amendments come from secondary sources (`text_is_official = FALSE`).
