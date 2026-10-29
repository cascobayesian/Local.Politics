# Massachusetts (precincts): how the model-ready data were made

| | |
|---|---|
| Unit | Precinct (town \| ward \| precinct), **2022** precinct plan; polygons from MassGIS Wards and Precincts 2022 |
| Units | 2,392 in `votes.csv` (of 2,404 rows in the source panel; 12 zero-vote precincts dropped); 2,391 in `partisan.csv` |
| Years | Ballot measures 2012–2024; federal races 2012–2024 |
| Ballot measures | 25 statewide questions (`votes.csv`): 3 in 2012, 4 in 2014, 4 in 2016, 3 in 2018, 2 in 2020, 4 in 2022, 5 in 2024 |
| Federal contests | 10 (`partisan.csv`): President 2012, 2016, 2020, 2024; US Senate 2012, 2013 special, 2014, 2018, 2020, 2024 |

Bundle: `output/atlas/overview/bundles/ma/` (a copy of `output/table2/ma_precinct/`, written by `code/table2/adapt_ma_precinct.R`; copied by `code/atlas/overview/01_bundles.R`).

## Raw data

Ballot measures and federal races come from the same source.

- **Precinct returns**: Massachusetts Secretary of the Commonwealth, PD43+ / ElectionStats (`https://electionstats.state.ma.us`), one CSV per question or race with `Locality/City/Town, Ward, Pct, <choices>, Blanks, Total Votes Cast` columns (precinct detail from 2002). Scraped by `code/scrape_ma_precincts.py` (download URL pattern `/ballot_questions/download/<id>/precincts_include:1/` and `/elections/download/<id>/precincts_include:1/`; see CLAUDE.md traps: the site's wide-range search silently truncates, files carry `PD43+__`, `ElectionStats__` or `Virginia_Elections_Database__` prefixes).
- Project paths: `data/ma_precinct/questions/` (1,201 question CSVs, statewide and local) and `data/ma_precinct/elections/` (7,623 race CSVs). The 25 statewide question files used are listed in `data/ma_precinct/statewide_ballot_files_2012_2024.txt`; the federal files in `data/ma_precinct/statewide_federal_elections_2012_2024_manifest.csv`.
- Question metadata (titles, summaries, ElectionStats links): `data/ma_precinct/new/Data/statewide_ballot_measure_metadata_2012_2024.csv`.
- Federal races keep only the statewide top-two candidates (one D, one R) ranked by original statewide totals; e.g. the 2020 Senate R column is O'Connor only, not Ayyadurai (`data/ma_precinct/experiments/README_federal_elections.md`).

## Shapefiles

- **Target (2022)**: MassGIS Wards and Precincts 2022 (`WARDSPRECINCTS2022_POLY.shp`, copied at `data/ma_precinct/experiments/wardsprecincts2022_poly/`); the MassGIS FeatureServer URL is recorded in `code/fetch_precinct_shapefiles.py` (`https://arcgisserver.digital.mass.gov/arcgisserver/rest/services/AGOL/WardsPrecincts2022/FeatureServer`). Bundle geometry is `data/ma_precinct/new/Shapefile/ma_precincts_2022.gpkg` (2,256 polygons).
- **Source maps for the crosswalks**: MassGIS 2012 (`data/ma_precinct/experiments/wardsprecincts2012_poly/WARDSPRECINCTS_POLY.shp`) and VEST `ma_2016`, `ma_2018`, `ma_2020` shapefiles (`data/ma_precinct/experiments/ma_20{16,18,20}/`; identified as VEST in `data/ma_precinct/realign_2024_ne/README.md`). Standardised copies: `data/ma_precinct/experiments/ma_<year>_standardized.gpkg`.

## Alignment across years

- **Method: areal overlap, not population.** Each earlier precinct's votes are multiplied by `frac_from_in_to` (share of the old precinct's *area* lying in each 2022 precinct, computed within town) and summed by 2022 precinct. No renormalisation; no population weighting (`data/ma_precinct/experiments/README_federal_elections.md`; manuscript Appendix `app:geo`).
- **Years moved**: 2012 and 2014 (and the 2013 Senate special) use the 2012→2022 crosswalk; 2016, 2018 and 2020 use their own year→2022 crosswalks. 2022 and 2024 are left as reported (2024 rows are the observed 2024 precincts).
- **Scripts**: `data/ma_precinct/experiments/01_standardize_all_ma_precincts.R` (labels), `data/ma_precinct/experiments/02_ma_precinct_overlap_all_years.R` (crosswalks → `data/ma_precinct/experiments/ma_precinct_overlap_<year>_to_2022.csv`), `data/ma_precinct/aggregate_all_statewide_ballot_questions_to_2022.R` (questions), `data/ma_precinct/experiments/aggregate_statewide_federal_elections_to_2022.R` + `create_federal_elections_wide.R` (federal), `data/ma_precinct/create.final.r` (wide files).
- **Unmatched source precincts are dropped**, not reassigned.
- **Rounding**: fractional allocations are rounded independently per cell with `round()` after aggregation (`..._on_2022_geography_rounded.csv`); the Yes and No columns are rounded separately. Missing precinct/question combinations become zero in the wide file.
- Model input: `data/ma_precinct/ma_ballot_questions_by_2022_precinct_wide.csv` and `data/ma_precinct/ma_federal_elections_by_2022_precinct_wide.csv` (identical copies in `data/ma_precinct/new/Data/` and `data/florida/raw/BBMM/`; the adapter reads the latter for questions).

## Summary statistics from alignment

- Unmatched source precincts dropped: 24 per election in 2012–2014 and 1 (Newburyport ward 1 precinct P) per election in 2016–2020; none in 2024 (`data/ma_precinct/experiments/README_federal_elections.md`; ballot-question lists in `data/ma_precinct/unmatched_ballot_precincts_<year>.csv`).
- Federal votes for the two selected candidates lost as unmatched: 10,683 (2012 President), 10,829 (2012 Senate), 5,003 (2013), 7,805 (2014), 470 (2016), 417 (2018), 506 (each 2020 contest). Per-candidate area-weight losses and rounding differences: `data/ma_precinct/ma_statewide_federal_election_total_check.csv` (e.g. Obama 2012: source 1,921,290, rounded output 1,912,106, of which 6,331 unmatched and −2,885.5 from incomplete area coverage).
- Ballot-question weighted totals after allocation: `data/ma_precinct/ma_statewide_ballot_question_total_check.csv` (Yes/No/Total per question; 2022–2024 equal the reported totals).
- Bundle checks (`code/table2/adapt_ma_precinct.R`): statewide 2024 Harris two-party share within 0.01 of 0.630; canary (empirical bloc Yes share vs fit means) r > 0.95 required.
- Precinct-shape stability (CLAUDE.md, manuscript `app:geo`): median IoU 0.939 for same-label precincts 2012 vs 2022; 24.6% > 0.99, 13.7% < 0.50. `data/ma_precinct/harmonisation_key.csv` flags stable precincts.

## What is in the model-ready files

- **Ballot measures**: 25 statewide questions 2012–2024; success = **Yes** for every question (the fit takes the odd `_Yes` columns). Several questions failed (e.g. 2014 Q2, 2016 Q1–Q2, 2018 Q1, 2024 Q4–Q5), but Yes is still the success side. None dropped.
- **Federal races**: President 2012/2016/2020/2024; US Senate 2012/2013 special/2014/2018/2020/2024; D and R nominee only.
- **Units excluded**: 12 precincts with zero valid votes on every question (dropped by the fit; absent from `votes.csv` and `blocs.csv`); rows with dem + rep = 0 dropped from `partisan.csv`. Zero Yes+No pairs are dropped from `votes.csv` ("not observed").
- **Geometry**: 136 modelled lettered sub-precincts (e.g. `ACTON||6A`) have no polygon in `units.gpkg` (geometry match 0.9431); listed in `output/table2/ma_precinct/unmatched_units.csv`.

## Other datasets

- **Local ballot questions (district and municipal), precinct level, 2002–2024**: `data/ma_precinct/ma_questions_precinct.csv` (+ `.parquet`), built by `code/assemble_ma_precincts.py`; 109,815 rows (`question_id, year, description, locality, ward, pct, yes, no, blanks, precinct_level`), 1,200 question ids of which 843 have precinct detail (from 2002). 79 statewide + 1,121 local question ids; 378 local in 2012–2024. On *reported* precinct labels of each year (not a common map). Raw files in `data/ma_precinct/questions/`.
- **Local questions 2012–2020 moved onto the 2022 map**: `output/ma_case/local_2012_2020_on_2022.csv` (4,955 rows; 274 questions × 2022 units, fractional `yes/no/blanks`, `coverage`, `stable_share`), built by `code/ma_case/ma_local_allocate_2012_2020.R` with the same areal crosswalks. Checks: `output/ma_case/local_2012_2020_allocation_check.csv` (allocated ballots 99.7% of raw, manuscript `app:ma_local`), `output/ma_case/local_2012_2020_unmatched.csv` (23 rows). 2022–2024 local questions are already on the 2022 plan (read from `ma_questions_precinct.csv`).
- **Analysis set of local questions**: `output/ma_case/local_questions_coded_2012_2024.csv` (263 questions with ≥ 10 precincts: 239 district, 24 municipal; 201 from 2012–20, 62 from 2022–24; with topic codes) and full texts `output/ma_case/local_question_text_2012_2024.csv`.
- **Candidate races incl. primaries, 2002–2026**: `data/ma_precinct/ma_elections_precinct.parquet` (PD43+ scrape, 7,623 races, raw files in `data/ma_precinct/elections/`), on reported labels. Primary shares on the 2022 units: `output/ma_case/primaries_unit_shares.csv` (60,314 rows; 13 contests — 2022 D AG/Auditor/Governor/Lt Gov/Secretary, 2022 R Governor/Lt Gov, 2024 D and R President, 2024 R US Senate, 2022 R US House MA-8/MA-9, 2024 R US House MA-8), built by `code/ma_case/ma_primaries_blocs.R`.
- **Alternative block-population panel (not used in the bundle)**: `data/ma_precinct/realign_2024_ne/` (built 2026-10-27 with the NYC 2020-block-population method onto the NYT 2024 precinct map, 2,375 units): `output/final_datasets/ma_combined.csv`, `ma_column_key.csv`, `ma_aligned_long_fractional.csv.gz`; 77 contests = the same 25 statewide questions + President, US Senate, Governor 2014/2018/2022 and 39 US House races. Different unit map from the bundle.

## Known issues

- **Input inconsistency** (meta.json): 2012–2020 counts exist only for the 2,256 polygon precincts (reallocated onto 2022 polygons), while 2022–2024 are on reported labels with lettered sub-precincts split out. A parent precinct includes its sub-precinct's voters before 2022 and excludes them after; the 148 sub-precinct units are observed only on the 9 questions of 2022–2024 and the 2024 federal contests.
- Areal weighting assumes voters are spread evenly within each piece of an old precinct; precinct lines changed substantially in 2021–22 (CLAUDE.md: never pool precinct eras without a crosswalk; a crosswalk should be block-based, not areal).
- Wide-file zeros can mean missing geographic coverage, not an observed zero.
- Rounded Yes and No are rounded separately, so they need not sum to the rounded ballots.
