# Maine (towns): how the model-ready data were made

| | |
|---|---|
| Unit | Referendum reporting area: 462 fixed areas built from Maine's 489 municipalities (22 groups combine towns/plantations that report jointly) |
| Units | 462 (all in `votes.csv` and `partisan.csv`) |
| Years | Ballot measures 2008–2025; federal races 2008–2024 |
| Ballot measures | 72 November statewide questions (`votes.csv`) |
| Federal contests | 4 (`partisan.csv`): President 2008, 2012, 2016, 2024 |

Bundle: `output/atlas/overview/bundles/me/`, a copy of `output/table2/maine/` (written by `code/table2/adapt_maine.R`), with `partisan.csv` cut to presidential rows by `code/atlas/overview/01_bundles.R`. Build folder: `data/maine/final/` (README there).

## Raw data

- **Ballot measures**: Maine Secretary of State election archive (`https://www.maine.gov/sos/elections-voting/election-results-data/previous-election-results`), downloaded 2026-09-15; Excel/text municipal result files, 2010–2025. Raw files: `data/maine/new/maine_election_results/` (URLs and SHA-256 in `manifest.json`). 2008 and 2009 come from user-provided text files `data/maine/new/maine_election_results/2008_raw.txt` and `2009_raw.txt` (notes: `processed/early_referendums_notes.txt`). Per-question CSVs: `data/maine/new/maine_election_results/processed/statewide/`; compiled matrix `data/maine/new/maine_referendum_2008_2025.csv` (copied to `data/maine/final/Data/maine_referendum_2008_2025.csv`); column key `data/maine/new/maine_referendum_2008_2025_column_key.csv`.
- Question subjects and published statewide results: `data/maine/final/Data/maine_ballot_measures_november_2008_2025.csv`; sources (Maine SOS and Maine Legislature PDFs) in `data/maine/new/maine_ballot_measures_november_2008_2025_sources.json`.
- **Federal races 2008–2016**: same SOS archive, downloaded 2026-09-15, by municipality (489 rows): `data/maine/final/Data/maine_statewide_candidates_2008_2022.csv`; provenance in `data/maine/final/Data/Supporting/candidate_source_README.md` (build folder `data/maine/new/statewide_candidate_races/`, with `manifest.json`, `download_sources.py`, `process_results.py`). Ranked-choice-era races (Senate 2018/2020/2024, President 2020/2024) are excluded from that file.
- **President 2024**: SOS corrected workbook `https://www.maine.gov/sos/sites/maine.gov.sos/files/inline-files/President%20and%20Vice%20President%20FINAL-Corrected%2020241205.xlsx` (`data/maine/final/Data/Supporting/president_2024_official.xlsx`), aggregated to reporting areas in `data/maine/final/Results/trump_2024_reporting_areas.csv` (validation `data/maine/final/Data/Supporting/presidential_validation.json`).

## Shapefiles

- `data/maine/final/Shapefile/Maine_Town_Polygons.gpkg` (municipality polygons; `LAND == 'y'` parts used, dissolved to reporting areas by `code/table2/adapt_maine.R`). The final README says it was already present; its source and vintage are not recorded there. A shapefile of the same layer name, `data/maine/early/Maine_Town_and_Townships_Boundary_Polygons_Feature.shp`, has metadata naming MEGIS (Maine Office of GIS), "Maine Town and Township Boundary Polygons", publication dated 2021-08-02. Whether the gpkg is derived from it is **not documented**.

## Alignment across years

- **None needed / none performed**: municipal boundaries are treated as stable. `data/maine/new/maine_referendum_2008_2025_notes.txt`: "No geographic reallocation was performed."
- Instead, every year is put on one fixed set of 462 reporting areas: 22 groups of municipalities whose township reporting cannot be separated consistently are combined in every year, and associated unorganised-township votes are added to their host area (absent township rows assumed already included). Scripts: `data/maine/new/maine_election_results/processed/merge_reporting_areas.py`, `harmonize_townships.py`, `compile_referendums_2008_2025.py`. Membership: `data/maine/final/Data/Supporting/reporting_area_members.csv`, `town_reporting_area_crosswalk.csv` (489 towns → 462 areas).
- Federal 2008–2016 town counts are summed to reporting areas in `code/table2/adapt_maine.R` (missing town cells treated as zero within a combined area).
- No fractional allocation, so no rounding.

## Summary statistics from alignment

- `data/maine/new/maine_election_results/processed/reporting_area_validation.json`: all 83 per-question files for 2008–2025 (77 statewide, 6 county) reconcile (`reconciles: true`) to source totals as output + unallocated + withheld. Summed over the 72 November statewide questions in the bundle (my computation from that file): source Yes+No 37,418,155; on reporting areas 37,279,962 (99.6%); unallocated 138,193 (e.g. 2008 Q1: 793 Yes and 449 No unallocated).
- `data/maine/new/maine_referendum_2008_2025_validation.json`: every saved cell matches its source; all 70 earlier question pairs unchanged.
- President 2024: statewide Harris 435,652 / Trump 377,977; allocated 429,749 / 376,518; unallocated 5,903 / 1,459 (UOCAVA etc.; `presidential_validation.json`).
- Bundle canary: empirical bloc YES share vs fit means r = 0.9962, max |dev| 0.078 (meta.json). `code/table2/adapt_maine.R` also checks statewide two-party shares (Obama 2008 0.588, 2012 0.579, Clinton 0.515, Harris 0.535, within 0.015).

## What is in the model-ready files

- **Ballot measures**: 72 November statewide questions, 2008–2025 (none in 2020 or 2022); success = **YES** throughout, trials = YES + NO. Non-November statewide questions and county-only questions are excluded. Incomplete pairs (one side NA) are treated as zero trials, as in the fit.
- **Federal races**: President 2008, 2012, 2016, 2024 (D vs R nominee). `output/table2/maine/partisan.csv` also has US Senate 2008/2012/2014, which `01_bundles.R` removes from the atlas bundle (presidential only). No 2020 President. Governor 2022 dropped.
- **Units excluded**: none; all 462 reporting areas are modelled.

## Other datasets

- **Non-November statewide questions on the same 462 areas**: `data/maine/new/maine_election_results/processed/statewide/` holds 77 question CSVs for 2008–2025 (72 November + 5 specials: 2017-06-13 Q1, 2018-06-12 Q1, 2020-03-03 Q1, 2020-07-14 Q1–Q2) plus 1998–2001 files; same reporting-area map for 2008–2025.
- **County ballot questions**: `data/maine/new/maine_election_results/processed/county/` — 6 files: Cumberland Q4 and Somerset Q1 (2010-11-02), Androscoggin Q1 and Piscataquis Q1 (2015-11-03), Penobscot and Piscataquis unnumbered (2020-07-14).
- **Earlier statewide referendums on 489 municipalities** (different unit set from the bundle): `data/maine/new/maine_referendum_1995_2001.csv` (29 questions: 1995, 1999, 2000, 2001; notes `maine_referendum_1995_2001_notes.txt`) and `data/maine/new/maine_referendum_1998_2001.csv` (23 questions, 1998–2001).
- **Combined matrix**: `data/maine/new/maine_combined_elections_1995_2024.csv` (462 areas, 106 binary contests: 7 candidate pairs, 70 questions 2008–2024, 29 questions 1995–2001; README `data/maine/new/combined_elections/README.md`).
- **Candidate races on municipalities**: `data/maine/final/Data/maine_statewide_candidates_2008_2022.csv` (489 towns; President 2008/2012/2016, US Senate 2008/2012/2014, Governor 2022). Raw primaries (US Senate 2012/2014/2018/2020/2024, President 2020/2024, by party) are in `data/maine/new/maine_election_results/` as downloaded Excel files, not processed.
- **Alternative 2012–2024 panel (not used in the bundle)**: `data/maine/realign_2024_ne/output/final_datasets/me_combined.csv` (+ `me_column_key.csv`, `me_long_all_choices.csv`): 484 units, 84 contests incl. 58 statewide questions (with the June/March/July specials), President, US Senate, Governor, US House; different unit set (README there).
- `data/maine/cannabis/maine_cannabis_measures.csv`: 462 rows of derived yes-shares on three cannabis questions (1999, 2009, 2016) with cluster and Trump share — an analysis file, not raw counts.

## Known issues

- Reporting areas combine municipalities; 108 associated township/tribal members that vote with an area are not in the geometry (meta.json).
- 2012 US Senate was won by independent Angus King; the D/R pair (Dill/Summers) is a weak partisan measure (meta.json; not in the atlas bundle).
- Bloc numbers are the fit's own; K = 7 is the project choice (BIC picks 8).
- 2008 and 2009 rest on user-provided text files rather than the SOS archive (which starts in 2010).
