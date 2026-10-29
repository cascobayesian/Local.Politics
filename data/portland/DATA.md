# Portland (Multnomah County): how the model-ready data were made

| | |
|---|---|
| Unit | Precinct, Multnomah County 2022 election-precinct map (196 split polygons dissolved to 107 precinct ids) |
| Units | 107 |
| Years | 2012–2024 (even-year November generals) |
| Ballot measures | 41 Oregon statewide measures (Measures 77–119) |
| Federal contests | 8: President 2012, 2016, 2020, 2024; US Senate 2014, 2016, 2020, 2022 |

## Raw data

- **Source:** Multnomah County Elections precinct results (index https://multco.us/info/results-and-history-multnomah-county-elections, per `data/pdx/Redo/Final/local_election_sources.md`). Ballot measures and federal races come from the same county files.
- **Format:**
  - 2012 and 2014: the county's HTML "web version" of the precinct abstract (fixed-width text). Saved as `data/pdx/Redo/Results/Election2012.html` and `Election2014.html`, parsed by `parse_multnomah_2012_html.R` / `parse_multnomah_2014_html.R`.
  - 2016: `Election2016.csv`, converted by `convert_election2016_to_sovc2.R`.
  - 2018–2024: county "SOVC2" precinct CSVs.
  - All are standardised to one schema by `data/pdx/Redo/Results/standardize_multnomah_sovc_files.R` → `data/pdx/Redo/Results/standardized_sovc/SOVC2_election<year>.csv`.
- **Project paths:** `data/pdx/Redo/Results/` (SOVC2_election2012–2024.csv and the HTML/CSV originals); `data/pdx/pdx_YYYYMMDD.csv` (county SOVC files, 2016–2024, all elections).

## Shapefiles

- **Target:** `data/pdx/Redo/Final/GIS_2022/Elections_Precinct_2022.shp` (also in `data/pdx/Redo/GIS_2022/`), dissolved by `PRECINCT`; CRS WGS 84. Source: Multnomah County Elections GIS. The metadata (`Multnomah_Elections_Precinct_Split_2022.shp.xml`) points to an internal county network share, dated 2022-02-10. No public URL is recorded. The `Multnomah_Elections_Precinct_Split_2022.shp` in the same folder is a 0-byte file.
- **Source vintages:**
  - `data/pdx/Redo/GIS_2012/multcoprecincts2012.shp`
  - `data/pdx/Redo/GIS_2013/precinct.shp`
  - `data/pdx/Redo/GIS_2016/Precincts_2016.shp`
  - `data/pdx/Redo/GIS precinct data (shape files) - updated 2-2016.zip`
  - `data/pdx/Redo/GIS_2011/edited_mc_precincts.shp` (2000–2010 data only)
  - Provenance of these files: not documented. Checked the folders and the shapefile XML.

## Alignment across years

- **Method:** 2020 census-block population crosswalk (`tigris::blocks`, Multnomah County). This is not the inside-point variant: each block's population is split across source∩target pieces in proportion to area. Weight = estimated population in the piece ÷ source-precinct population. Source precincts with zero population fall back to area.
- **Years moved onto the 2022 map** (control file `data/pdx/Redo/pair_file.csv`):
  - 2012 from GIS_2012.
  - 2014 from GIS_2013.
  - 2016, 2018, 2020 from GIS_2016 (2018 and 2020 reuse the 2016 crosswalk).
  - 2022 and 2024 are already on the 2022 map (identity).
- **Script:** `data/pdx/Redo/batch_reweight_all_elections_to_2022.R`. Crosswalks are in `data/pdx/Redo/Results/standardized_sovc_2022_geography/crosswalks/crosswalk_<year>_to_2022_population_weighted.csv`. Wide files: `combine_state_measures_wide.R`, `combine_president_senate_party_totals_wide.R`, `combine_all_binary_contests_wide.R` → `data/pdx/Redo/Final/`. Bundle: `code/table2/adapt_portland.R` → `output/table2/portland/`, copied by `code/atlas/overview/01_bundles.R`.
- **Rounding:** `round_preserve_sum` (largest remainder) within each contest × choice group, so every county total is preserved. Fractional versions are kept (`*_fractional.csv`).

## Summary statistics from alignment

- `data/pdx/Redo/Results/standardized_sovc_2022_geography/reweighting_total_checks_all_years.csv`: for every year 2012–2024, original, fractional and rounded totals of `Votes` agree. Rounded difference is 0 (e.g. 2012: 8,394,863; 2016: 11,198,379; 2024: 9,696,800).
- `.../batch_reweighting_summary.csv`, source precincts → 107 target precincts: 2012 132; 2014 132; 2016–2020 113; 2022–2024 107.
- `data/pdx/Redo/combined_2000_2024_outputs/precinct_id_match_summary.csv`: the 2012–2024 returns match the 2022 precincts 107/107 (100%).
- Bundle canary on the 41 measures (`meta.json`): r = 0.9991, max |dev| = 0.0390. `adapt_portland.R` rebuilds `votes.csv` from the fit input and asserts that the two are identical.

## What is in the model-ready files

- **Ballot measures:** 41 Oregon state measures, 2012–2024 (9, 7, 7, 5, 4, 4, 5 by year), from `data/pdx/Redo/Final/state_measures_2012_2024_on_2022_precincts_wide.csv`. Success = **Yes**; n = Yes + No. No state measure in that window is dropped. `MULTNOMAH_COUNTY_AUDITOR_2018` and every candidate race are excluded from the votes file (`adapt_portland.R`).
- **Federal races:** 8 D-vs-R contests, from `data/pdx/Redo/Final/president_senate_party_totals_2012_2024_on_2022_precincts_wide.csv`. Before 2022 these are allocated onto the 2022 map, not observed.
- **Units excluded:** none (107 of 107).

## Other datasets

- **Multnomah local ballot measures, 2012–2026, on the 2022 map:** `data/pdx/Redo/Final/local_measures_2012_2026_on_2022_precincts_wide.csv`.
  - 107 rows × 358 vote columns: 179 county, city, school-district and special-district measures from 30 elections, May 2012 – May 2026, including joint-district measures numbered 3- (Clackamas), 5- (Columbia) and 34- (Washington).
  - A blank cell means the precinct did not vote on the measure.
  - Pipeline, README and diagnostics: `data/pdx/Redo/Final/local_measures/` (`README.md`, `scripts/01–04`, `output/local_measures_column_key.csv`, `output/local_measures_coverage_on_2022_precincts.csv`, `output/local_measures_long_on_2022_precincts_fractional.csv`, `output/local_measures_total_checks.csv`).
  - Same population crosswalks and rounding as the state file.
  - 143 of 179 measures match an official county total exactly.
  - CLAUDE.md still lists "Portland local measures" as waiting on Jack.
- **All contests, November generals 2012–2024, on the 2022 map, long form:** `data/pdx/Redo/Results/standardized_sovc_2022_geography/all_elections_2012_2024_on_2022_precincts_rounded.csv` (+ `_fractional.csv`). 64,846 rows; 589 year×contest combinations covering every candidate race and measure on the ballot, local ones included.
- **Binary-contest panel used by Jack's superseded K = 4 fit:** `data/pdx/Redo/Final/all_binary_contests_2012_2024_wide.csv`. 107 rows; 192 contests = the 41 state measures + 151 candidate races (federal, state, local; first option REPUBLICAN). Same map.
- **Oregon state measures 2000–2010 on the 2011 map:** `data/pdx/Redo/Final/pdx_state_measures_2000_2010.csv`. 147 precinct rows (125 complete); 54 measures. It is not on the 2022 map.
- **The same measures moved to the 2022 map:** `data/pdx/Redo/Final/referenda_2000_2024_on_2022_precincts.csv`, from `combine_referenda_2000_2024_on_2022_precincts.R` with the 2011→2022 crosswalk in `data/pdx/Redo/combined_2000_2024_outputs/`.
  - 107 rows; 95 measures, 2000–2024.
  - Only 89.2% of 2000–2010 source votes survive (`historical_vote_total_diagnostics.csv`).
  - 17 of 147 old precinct names are unmatched (`precinct_id_match_summary.csv`).
- **Raw, unaligned:**
  - `data/pdx/pdx_YYYYMMDD.csv`: county SOVC, every contest including local candidates, all elections 2016–2024.
  - `data/pdx/multnomah.xlsx`: 1993–2022 local measures. The local-measures README says its Yes column is unreliable for 45 measures.
  - `data/pdx/pdx_2000_2006.xlsx` … `pdx_20101102.xlsx`.

## Known issues

- Pre-2022 returns (measures and federal) are crosswalk estimates. 2018 and 2020 are moved from 2016 boundaries.
- For partial-county local measures from 2012–2021, the crosswalk spreads votes into neighbouring 2022 precincts. In the coverage file, 1,376 of 8,256 cells have coverage < 0.999 (local-measures README).
- `questions.csv` labels are hand-entered abbreviations, not machine-verified (`meta.json`).
- The superseded fit's `em_input_summary.csv` and `em_questions_used.csv` are stale (`meta.json`).
- The 2000–2010 BDMCMC fit (125 units on the 2011 map) cannot be joined to the 2022 map (`adapt_portland.R`).
