# Alabama: how the model-ready data were made

| | |
|---|---|
| Unit | Precinct (polling place), November 2024 map from the New York Times / Redistricting Data Hub 2024 layer, plus one gap-fill polygon: 1,946 precincts |
| Units in the bundle | 1,946 (none dropped) |
| Years | 2016–2024 (primaries, generals and the December 2017 special) |
| Ballot measures | 40 statewide measures (amendments and the 2022 Constitution ratification) |
| Federal contests | 7 (President 2016, 2020, 2024; US Senate 2016, Dec 2017 special, 2020, 2022) |

Bundle: `output/atlas/overview/bundles/al/`, built by `code/atlas/overview/01_bundles.R` from `data/bbmm_benchmarks/alabama_2024align.rds`. Build folder: `data/alabama/realign_2024/` (README: `data/alabama/realign_2024/README.md`).

## Raw data

Ballot measures and federal races come from the same source:

- **Alabama Secretary of State** precinct-level workbooks, one per county per election, from https://www.sos.alabama.gov/alabama-votes/voter/election-data.
  - The zip URLs are in `data/alabama/realign_2024/scripts/00_common.R`, and the zips are in `data/alabama/realign_2024/raw/sos/`.
  - Each workbook has one row per contest × choice and one column per precinct, plus county-level `ABSENTEE` and `PROVISIONAL` columns.
  - Format: Excel (.xls/.xlsx) inside zips.
- **Official totals:** SOS certified canvass PDFs in `raw/official/`. `metadata/official_totals.csv` was transcribed by hand from them, with a source page per figure. The March 2016 amendment has no certified statewide total; the sum of the county precinct files is used instead.
- **Ballot wording:** `metadata/measure_wording.csv`, from the SOS ballot-language certifications. The 2022 Constitution wording comes from HJR52.

## Shapefiles

- **Target (the units):** the New York Times 2024 precinct map, AL file. It was downloaded from https://int.nyt.com/newsgraphics/elections/map-data/2024/national/AL-precincts-with-results.geojson.gz (from github.com/nytimes/presidential-precinct-map-2024) and saved in `raw/nyt_2024/`. Its boundaries are the Redistricting Data Hub's 2024 general-election precincts.
  - One polygon is added: Cullman's Fairview, which has no polygon in the NYT/RDH layer. It is built as VEST 2020 polygon 01043000281 minus the NYT polygons, 2,414 residents. That is why there are 1,946 precincts, not 1,945.
  - Project file: `data/alabama/realign_2024/geometry/al_precincts_target.gpkg` (EPSG:5070), with `join_id` = `AL_<county FIPS>_<4-digit sequence>`. The atlas/bundle geometry is the land-only version, `geometry/al_precincts_target_land.gpkg`.
- **Source maps:** VEST `al_2016`, `al_2018`, `al_2020` from Harvard Dataverse (doi:10.7910/DVN/NH5S2I, UBKYRU, K7760H), in `raw/vest/`. Cleaned copies are in `geometry/vintages/`. There is no 2022 shapefile.
- **Weights:** TIGER/Line 2020 blocks `tl_2020_01_tabblock20` (185,976 blocks, 5,024,279 residents), in `raw/census_blocks/`.

## Alignment across years

1. **Parse** (`01_parse_returns.R`). Ballot-style sub-columns (Mobile 2016–18, Montgomery 2016) are summed to the polling place.
2. **Match units to polygons** (`04_match_units.R`, `match_lib.R`). Alabama names precincts by polling place, and the names drift between elections.
   - **Stage R** matches each map to its own election (2016G/VEST 2016, 2018G/VEST 2018, 2020G/VEST 2020, 2024G/NYT). The rules run in this order: exact vote vectors, normalised names, 2→1 and 1→2 sums, approximate vote vectors, fuzzy names.
   - **Stage X** matches each election's units to each reference election's units in the same county, by raw name, normalised name, precinct number, then fuzzy name.
3. **Choosing the map** per election × county: the reference that places the largest share of election-day ballots wins. Ties go to the nearest date, and an election's own map gets a 2-point preference (`metadata/vintage_choice.csv`, `vintage_scores.csv`).
   - Example: the 2022 general uses VEST 2020 in 27 counties and NYT/RDH 2024 in 39.
   - The 2024 general uses the 2024 map in all 67 counties (identity).
   - Every other election is moved onto the 2024 map.
4. **Absentee and provisional votes** (`06_align.R`) are reported only as county columns: 2–6% of the vote in most years, 13.6% in 2020. Within each contest × county × choice they are spread in proportion to election-day votes. Jefferson is spread countywide.
5. **Weights** (`03_assign_blocks.R`, `05_build_weights.R`) use the NYC method. Each 2020 block is assigned whole, by internal point, within its county. Weight = pop(group's blocks ∩ 2024 precinct) / pop(group's blocks). The area fallback is never used.

- Scripts: `data/alabama/realign_2024/scripts/01`–`08`, run by `run_all.R`. `10_bbmm_input.R` writes the fit input. Crosswalks are in `crosswalks/al_<vintage>_to_2024.csv`, `unit_groups.csv.gz` and `group_weights.csv.gz`.
- **Rounding:** `integer_votes` is a largest-remainder rounding within contest × choice, which preserves totals. The fit input uses these integers.

## Summary statistics from alignment

From the README and `metadata/validation_summary.csv`:

| Check | Rows | Passed |
|---|---|---|
| A. Native statewide total = certified, within max(2, 0.05%) | 108 | 59 |
| B. Native county totals = VEST county totals (2016/2020 Pres & Sen), within 0.1% | 536 | 496 |
| C. Conservation: aligned + unallocated = native | 108 | 108 (max gap 3e-9) |
| D. 2024 President identity in one-to-one precincts | 11,520 | 11,520 |
| E. Stage-R groups vs VEST polygon votes, within 5% | 11,786 | 11,773 (99.88% of votes) |

- **Stage-R linked share of election-day ballots:** 2016 99.85%, 2018 99.83%, 2020 99.62%, 2024 100% (`metadata/match_rates_stageR.csv`).
- **Unallocated share** (held, not spread; `metadata/unallocated_votes.csv`): 2016_03_amend1 1.76% (33 units); 2022 general 0.43–0.46%; 2017 Senate 0.29%; 2024_03_amend1 0.25%; 2020 and 2022 primaries 0.19–0.22%; 2018 amendments 0.09–0.10%; 2016G, 2020G and 2024G 0. `metadata/unplaced_units.csv` lists 66 unit rows.
- **Block fallbacks in the target layer:** 99 blocks (856 residents) go to largest overlap, and 115 go to nearest polygon (mostly Mobile Bay water blocks).
- **Check A failures are source shortfalls.** The 2016G, 2017S and 2018G SOS precinct files are 0.07–0.23% below the certified canvass (worst: Clinton −1,678). The March 2024 amendment files are 0.29–0.30% above certified. Both are left as published.

## What is in the model-ready files

- **Ballot measures (`votes.csv`):** 40, `success` = Yes and `n` = Yes + No:
  - 2016-03 A1; 2016-11 A1–14; 2018-11 A1–4
  - 2020-03 A1; 2020-11 A1–6
  - 2022-05 A1; 2022-11 A1–10 plus `2022_11_constitution`
  - 2024-03 A1; 2024-11 A1
  - Some 2016 "statewide" amendments concern one county but were voted on statewide; they are kept. None are dropped. The June 2018 primary had no statewide measure.
- **Federal races (`partisan.csv`):** President 2016, 2020, 2024; US Senate 2016, 2017-12 special general, 2020, 2022. `dem`/`rep` are the Democratic and Republican nominees only. The atlas fit for Alabama includes these 7 races alongside the 40 measures.
- **Units excluded:** none (1,946 × 47, 99.52% of cells observed). Missing cells come from unallocated units: 35 precincts for the March 2016 amendment and 25 for each 2022 contest.

## Other datasets

- `data/alabama/realign_2024/metadata/local_measures.csv`: local (single-county) constitutional amendments, 69 county × contest rows across 39 counties (2020G 26, 2020P 3, 2022G 19, 2024P 1, 2024G 20). It holds **county-level Yes/No totals only**, not precinct level, and is not in the main datasets.
- `data/alabama/realign_2024/output/native/native_long.csv.gz`: every contest in the parsed SOS workbooks at native polling-place units. **Not aligned.** That covers candidate races at all levels, local amendments and local referendums.
  - 4,077,581 rows, 11 elections: 2016P, 2016G, 2017S, 2018P, 2018G, 2020P, 2020G, 2022P, 2022G, 2024P, 2024G.
  - Distinct contest names per election: 350, 944, 21, 498, 831, 294, 950, 499, 737, 226, 1,052. These are counted across counties and include party primaries.
  - A keyword search (LOCAL, REFERENDUM, PROPOSITION, QUESTION, TAX, BOND…, excluding "STATEWIDE") finds about 215 election × county × contest combinations that look like local measures. This is a rough count, not curated.
- `data/alabama/realign_2024/output/native/contest_native.csv.gz`: the native rows of the 47 study contests.
- `data/alabama/realign_2024/raw/sos/2014General-precinctLevel.zip`: 2014 general, not parsed (several layouts, no 2014-era map).

## Known issues

- Precinct names drift, so matching is vote-vector-first. Unmatched (renamed or abolished) polling places are held, not spread.
- Source shortfalls in 2016G, 2017S and 2018G, and an unexplained surplus in the March 2024 amendment, are left as published (above). VEST patched 18 counties in 2016 and 8 in 2018 from county canvasses; this build does not.
- 2016 Amendments 9 and 12 passed statewide but failed in their own counties, so they were not adopted.
- Absentee and provisional votes are county-level and allocated by election-day share.
- Fairview (Cullman) is a gap-fill polygon.
- CLAUDE.md: the AL atlas fit includes federal races. Bloc names are drafts.
