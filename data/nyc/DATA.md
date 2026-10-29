# New York City (election districts): how the model-ready data were made

| | |
|---|---|
| Unit | Election district (ED), NYC Department of City Planning **2024** ED map (release `nyed_24c1`, August 2024) |
| Units | 4,345 EDs on the map; 4,152 in `votes.csv` (193 with zero valid votes on all 30 measures excluded); 4,158 in `partisan.csv` |
| Years | Ballot measures 2014–2024; federal races 2012–2024 |
| Ballot measures | 30 (`votes.csv`): 2014 (2), 2017 (3), 2018 (3), 2019 (5), 2021 (5), 2022 (4), 2023 (2), 2024 (6) |
| Federal contests | 9 (`partisan.csv`): President 2012, 2016, 2020, 2024; US Senate 2012, 2016, 2018, 2022, 2024 |

Bundle: `output/atlas/overview/bundles/nyc/`, a copy of `output/table2/nyc/` written by `code/table2/adapt_nyc.R`. Build folder: `data/NYC/` (README there, created 2026-09-24).

## Raw data

Ballot measures and federal races come from the same sources.

- **Primary source**: NYC Board of Elections annual results pages (`https://vote.nyc/page/election-results-summary`), general-election citywide ED-level CSVs plus recap controls. Exact URLs, sizes and SHA-256 hashes: `data/NYC/metadata/source_manifest.csv`. Raw files: `data/NYC/raw/returns/` (recap controls in `data/NYC/raw/controls/`).
- **2012**: OpenElections NY (`https://github.com/openelections/openelections-data-ny`) and its archived NYC source workbooks (`https://github.com/openelections/openelections-sources-ny/tree/master/2012`); workbook `2012nyc.xls` supplies Brooklyn presidential votes and replaces Staten Island presidential returns.
- **2017 Proposal 2** (pension forfeiture): BOE download broken; replaced by OpenElections' five county files.
- Normalised native (unallocated) returns: `data/NYC/native_csv/` (`all_votes.csv`, `party_line_votes.csv`, `all_statistics.csv`, one CSV per contest). Contest/option metadata: `data/NYC/metadata/contests.csv`, `options.csv`, `coverage.csv`. Fusion party lines are summed to the candidate.

## Shapefiles

- **Target**: NYC Department of City Planning archived ED shapefile `nyed_24c1` (4,345 EDs), `data/NYC/geometry/target_2024/nyc_ed_2024.shp` (EPSG:2263; join on `join_id`, e.g. `NYC_23001`). Original DCP ZIPs in `data/NYC/raw/boundaries/`.
- **Source maps** (one DCP vintage per returns year): 2012 `12c`, 2014 `14d`, 2016 `16d`, 2017 `17d`, 2018 `18d`, 2019 `19d`, 2020 `20c`, 2021 `21d`, 2022 `22c`, 2023 `23c`, 2024 `24c1`; cleaned copies in `data/NYC/geometry/native_<year>/`; vintage checks in `data/NYC/metadata/boundary_match_audit.csv`.
- **Blocks**: 2020 Census tabulation blocks with `POP20` (`https://www2.census.gov/geo/tiger/TIGER2020/TABBLOCK20/tl_2020_36_tabblock20.zip`; 37,984 NYC blocks, 8,804,190 residents), in `data/NYC/raw/blocks2020/`.

## Alignment across years

- **Method: 2020 census-block population crosswalk** (the project's "NYC method"). Each block's internal point is assigned to a historical ED and a 2024 ED; weight = population of the source/target pair ÷ population of the source reporting group. BOE "COMBINED INTO" relationships are honoured by grouping member EDs first (not available for 2012). Fallbacks: greatest block-polygon overlap, nearest polygon within 100 m (1,000 m for an all-water block), polygon area for zero-population groups; all flagged.
- **Years moved**: every year 2012–2023 onto the 2024 map; 2024 is matched by ID (some jointly reported 2024 EDs are disaggregated the same way).
- **Scripts**: `data/NYC/scripts/build_crosswalks.R` (weights → `data/NYC/crosswalks/nyc_<year>_to_2024.csv`, plus block assignments), `data/NYC/scripts/align_results.py` (allocation), `data/NYC/scripts/verify_outputs.py`, `data/NYC/scripts/build_paired_data.py` (paired files in `data/NYC/final_datasets/`).
- **Rounding**: `integer_votes` = largest remainder — floor the fractional estimates, then give remaining votes to the largest remainders within each contest × county × choice, ties broken by ED id. Integers preserve allocated totals. The bundle uses `integer_votes` (`data/NYC/final_datasets/nyc_ballot.csv`; federal from `data/NYC/aligned_2024/presidential.csv` and `senate.csv`). Fractional `estimated_votes` are kept in `data/NYC/aligned_2024/`.

## Summary statistics from alignment

From `data/NYC/README.md` and `data/NYC/final_datasets/README.md`:

- 606 passing county and citywide comparisons against official recap controls (`data/NYC/metadata/official_recap_checks.csv`).
- 515 passing conservation checks: fractional and integer allocated totals plus unallocated votes equal native county/choice totals (`data/NYC/metadata/alignment_checks.csv`; contest totals in `alignment_summary.csv`).
- One vote unallocated: a 2020 Biden vote in Queens ED 35056, which has a return but no polygon (`data/NYC/metadata/unallocated_votes.csv`).
- 89 2012 source polygons have no return rows (3,487 people under the 2020 proxy; touch 173 target EDs); flagged `source_coverage=unreported_source_geometry_overlaps`.
- Paired files: all 195 contest/county totals reconcile exactly (`data/NYC/final_datasets/pair_total_checks.csv`).
- Bundle (`code/table2/adapt_nyc.R`): ballot totals reproduce the column key exactly; canary of empirical bloc Yes share vs Jack's `cluster_profiles.csv` r > 0.95 required.

## What is in the model-ready files

- **Ballot measures**: 30 proposals 2014–2024, a mix of New York State constitutional amendments/bond acts and New York City charter proposals (titles in `data/NYC/final_datasets/nyc_ballot_column_key.csv`; the files do not flag which is state and which is city). Success = **Yes** for every measure (pairs are always Yes then No), including those that failed (e.g. 2017 Constitutional Convention, 21.6% Yes in the bundle).
- **Dropped / unavailable**: seven measures have no ED-level returns and are absent — all six 2013 proposals and 2014 Proposal 1 (2013 page gives only recap PDFs; 2014 ED links return 404). Borough totals were not substituted.
- **Federal races**: President 2012–2024, US Senate 2012/2016/2018/2022/2024; dem/rep sum fusion lines; ED-contests with dem + rep = 0 dropped. (`final_datasets/nyc_president_senate.csv` is instead winner-vs-others; the bundle does not use it.)
- **Units excluded**: 193 EDs with zero valid votes on all 30 measures (in `units.gpkg` only).

## Other datasets

- **2025 Democratic primary (RCV), ED level, 2024 ED map assumed**: `data/NYC/raw/2025_primary/nyc_mayor_2025_ed.csv`, `nyc_comptroller_2025_ed.csv`, `nyc_public_advocate_2025_ed.csv` (4,036 ED rows each; first-choice counts by candidate, final-round counts, ballots), tabulated from BOE cast-vote records (`2025_Primary_CVR_2025-07-17.zip`) by `code/nyc_primary_2025_cvr.py` (mayor) and `code/nyc_primary_cvr_citywide.py` (all three offices, 2021 and 2025); RCV round checks `rcv_rounds_*_2025.csv`. CLAUDE.md: the mayoral file was once overwritten and restored; `code/nyc_primary_2025_blocs.R` reproduces outputs.
- **2021 Democratic primary (RCV)**: native 2021 EDs `data/NYC/raw/2021_primary/nyc_{mayor,comptroller,public_advocate}_2021_ed.csv` (5,623 rows for mayor; built by `code/nyc_primary_cvr_citywide.py` 2021) and moved onto the 2024 map `nyc_<office>_2021_on2024.csv` (4,198 rows, fractional) by `code/nyc_primary_2021_allocate.R` with the same 2020-block weights (`primary_2021_crosswalk.csv`; audit `allocation_audit_2021.csv`: 41 of 942,031 mayoral ballots unallocated, 3 unmatched EDs).
- **2025 mayoral general**: `data/NYC/raw/2025_general/nyc_mayor_general_2025_ed.csv` (4,117 ED rows; Mamdani, Cuomo, Sliwa, Adams, other), from the BOE ED-level CSV, by `code/nyc_general_2025_ed.py`; on reported 2025 ED ids (not re-aligned).
- No local (non-citywide) referendum data found beyond the 30 measures.

## Known issues

- 2012–2023 counts are population-based estimates on 2024 EDs, not observed returns; 2020 residential population, not voters. Blocks are not split.
- 2012 allocations ignore combined-ED relationships (not in archived sources); 2012 has unreported source geometry.
- A zero can mean no allocated votes rather than an observed zero (`data/NYC/final_datasets/precinct_coverage_flags.csv`).
- `2024_president_winner` in `final_datasets/nyc_president_senate.csv` is the national winner (Trump); `_others` is Harris + write-ins (CLAUDE.md). The bundle's `partisan.csv` is D vs R.
- The 2025 primary is assumed to use the 2024 ED map (CLAUDE.md).
- K_bic = 25 is the upper edge of the searched range; K = 9 is the project's choice.
