# California (statewide): how the model-ready data were made

| | |
|---|---|
| Unit type and map | 2024 general-election SR precincts (SWDB "SRPREC", g24), keyed by `SRPREC_KEY` |
| Units in the model-ready files | 23,006 (of 25,245 g24 SRPRECs; 2,239 with no proposition votes are excluded) |
| Years | 2012, 2014, 2016, 2018, 2020, 2022, 2024 (November generals) |
| Ballot measures | 74 statewide propositions (2012: 11, 2014: 6, 2016: 17, 2018: 11, 2020: 12, 2022: 7, 2024: 10) |
| Federal contests | 9 (President 2012/16/20/24; US Senate 2012, 2022, 2022 special, 2024, 2024 special) |
| Alignment of 2012–2022 | **Area overlap** onto the 2024 map (not the block method used for LA and SF; see Known issues) |

Bundle: `output/atlas/overview/bundles/ca/` (`votes.csv`, `partisan.csv`, `meta.json`), written by
`code/atlas/overview/01_bundles.R` (reader `src_fun$ca`), with units taken from the atlas registry entry
`ca` in `code/atlas/build_panels.R` (fit folder `data/ca/ca_all/em_bic_california_referendums_results/`).

## Raw data

- **Source:** California Statewide Database (SWDB, statewidedatabase.org), statement-of-vote data by SR
  precinct, one CSV per general election. The URL pattern is recorded in
  `data/ca/state_g10_sov_data_by_g10_srprec/state_g10_sov_data_by_g10_srprec_readme.txt`
  (`http://statewidedatabase.org/pub/data/G10/state/state_g10_sov_data_by_g10_srprec.zip`). Download
  dates for the 2012–2024 files are not documented.
- **Format:** wide CSV, one row per SR precinct of that election; propositions as `PR_<n>_Y` / `PR_<n>_N`,
  federal candidates as `PRSDEM01`, `PRSREP01`, `USSDEM01`, `USPDEM01` etc.; 2024 masks cells of 1–9
  votes as `***` (CLAUDE.md).
- **Project paths:** `data/ca/state_g12_sov_data_by_g12_srprec.csv` … `data/ca/state_g24_sov_data_by_g24_srprec.csv`
  (2012–2024). Ballot measures and federal races come from the same files.

## Shapefiles

- SWDB SR-precinct boundary files, `data/ca/srprec_state_gYY_v01_shp/` (2012–2024), from
  `statewidedatabase.org/pub/data/GYY/state/` (URL recorded for 2012 in
  `data/ca/srprec_state_g12_v01_shp/srprec_state_g12_v01_shp_readme.txt`; not recorded for other years).
- Unit map: 2024 file `data/ca/ca_all/srprec_state_g24_v01_shp/srprec_state_g24_v01_shp.shp` (identical
  folder also at `data/ca/srprec_state_g24_v01_shp/`). The bundle geometry is the cached
  `data/ca/ca_all/em_bic_california_referendums_results/map_geometry.rds`, built from that shapefile by
  `data/ca/ca_all/map_california_precinct_clusters.R`. Geometry match rate 0.99987 (`meta.json`).

## Alignment across years

- **Target:** 2024 SRPRECs. 2024 returns are used as observed (`data/ca/ca_all/state_g24.csv` is
  byte-identical to the raw 2024 SOV file).
- **Method used for this bundle: areal interpolation.** `data/ca/reweight_all_years_to_2024.R` intersects
  each source-year SRPREC with the 2024 SRPRECs of the same county (California Albers, EPSG:3310) and gives
  each 2024 precinct the share `area(source ∩ target) / area(source)` of the source's counts. Uncovered
  source area is left unallocated; source coverage above 100% is scaled down proportionally (allowed up to
  5% excess; 2020 needed a rerun at 10%, per `data/ca/ca_historical_on_2024/batch_status.csv` and the
  script header). Any masked/missing contributor makes the target cell NA.
- **Years moved:** 2012, 2014, 2016, 2018, 2020, 2022 → 2024 map. Outputs:
  `data/ca/ca_historical_on_2024/state_gYY_sov_on_g24_srprec_rounded.csv` plus per-year audit folders
  `data/ca/ca_historical_on_2024/<year>_on_2024/`.
- **Rounding:** each cell independently, `floor(x + 0.5)`; totals can drift (audited as `rounding_change`).
- **Panel build:** `data/ca/ca_all/build_california_contests.R` (run 2026-10-07, while
  `data/ca/ca_all/state_gYY.csv` were still the areal files) → `data/ca/ca_all/california/`
  (`ca_referendums_wide.csv`, `ca_presidential_senate_wide.csv`), then
  `data/ca/ca_all/run_em_california_k30.R` → `data/ca/ca_all/california/referendums_bbmm_prepared.rds`,
  which `01_bundles.R` reads. Verified here: unit `06001200100`, 2012 Prop 30 in the bundle is
  1,801 Yes of 2,074, equal to the areal file (block file: 2,426 Yes).
- The block/registration method (`code/ca/reweight_blocks_to_2024.R`) exists statewide but was **not**
  used for this bundle (see Other datasets).

## Summary statistics from alignment

From `data/ca/ca_historical_on_2024/<year>_on_2024/count_allocation_audit.csv`, row `TOTVOTE` (share of
statewide votes left unallocated = computed as `unallocated_known_total / input_known_total`):

| Year | TOTVOTE in | unallocated | after rounding | source SRPRECs without geometry |
|---|---|---|---|---|
| 2012 | 13,202,156 | 0.786% | 13,098,263 | 2,264 |
| 2014 | 7,513,971 | 0.383% | 7,485,094 | 1,989 |
| 2016 | 14,610,518 | 0.526% | 14,533,532 | 2,284 |
| 2018 | 12,712,542 | 0.283% | 12,676,568 | 2,339 |
| 2020 | 17,785,667 | 0.274% | 17,736,960 | 1,295 |
| 2022 | 11,146,560 | 0.189% | 11,125,512 | 1,957 |

- 1,043 g24 SRPRECs have no geometry (`<year>_on_2024/2024_rows_without_geometry.csv`), so they receive no
  historical votes. Source rows without geometry counted from `source_rows_without_geometry.csv`.
- The block-method README (`data/ca/ca_historical_on_2024_blocks/README.md`) reports, for comparison,
  a *median* areal-method loss of 0.79% / 0.34% / 0.53% / 0.26% / 0.28% / 0.16% (g12–g22).
- No county-total validation against official results is recorded for the areal files.

## What is in the model-ready files

- **Ballot measures:** 74 statewide propositions on the November ballots 2012–2024 (counts per year in
  the table above). Success side = **Yes** for every measure (`x = Yes`, `n = Yes + No` in
  `run_em_california_k30.R`; `meta.json` `success_side: yes`). No proposition dropped. Primary-ballot
  propositions (e.g. June 2018, March 2020, March 2024) are not in the panel: only `state_gYY` files are read.
- `votes.csv`: 1,567,533 unit × measure rows; cells with missing or zero ballots dropped (`n > 0`).
- **Federal races:** party totals (all candidates of a party summed) for PRESIDENT_2012/2016/2020/2024,
  US_SENATE_2012/2022/2024, US_SENATE_SPECIAL_2022/2024. Dropped: US Senate 2016 and 2018 (Dem-vs-Dem
  top-two; removed by the rule "each party ≥ 5% of the statewide two-party vote" in `01_bundles.R`).
  `partisan.csv`: 201,564 rows; 2024 contests cover 21,260 units (2024 masked cells are NA).
- **Units excluded:** 2,239 g24 SRPRECs with zero proposition votes in all years (flag `zero_total_votes`
  in `em_K30_assignments.csv`).

## Other datasets

- **Block-reweighted statewide panel (same 74 measures, better alignment):**
  `data/ca/ca_all/bbmm_zeta0.3/output/panel_blocks/` (`ca_referendums_wide.csv`,
  `ca_presidential_senate_wide.csv`, `ca_contests_2012_2024_wide.csv`; 25,245 g24 SRPRECs), built by
  `data/ca/ca_all/bbmm_zeta0.3/scripts/00_build_panel_blocks.R`; fit input
  `data/bbmm_benchmarks/california_ballot_2024align.rds` (20,248 × 74). Same unit map (g24 SRPREC).
- **Block-reweighted SOV files, all columns:** `data/ca/ca_historical_on_2024_blocks/state_gYY_sov_on_g24_srprec_rounded.csv`
  (2012–2022 on g24; also includes state legislative and congressional candidates). Same unit map.
- **Earlier statewide generals, not aligned:** SWDB SOV zips `data/ca/state_g02_…`, `state_g04_…`,
  `state_g06_…`, `state_g08_…`, `state_g10_sov_data_by_gYY_srprec.zip` (DBF format; 2002–2010 propositions),
  with shapefile zips `data/ca/srprec_g04/g06/g08/g10_state_shp.zip`, `srprec_state_g02_v01_shp.zip`.
  Own SRPREC map each year; number of propositions not tabulated.
- No statewide municipal, county or district ballot-measure data were found for California as a whole.
  (County-level local data exist only for LA and SF; see their DATA.md.)

## Known issues

- **This bundle is still on the areal panel.** CLAUDE.md: "Block-reweighted files:
  `data/ca/ca_historical_on_2024_blocks/`; areal ones in `data/ca/ca_historical_on_2024/` are
  superseded. `ca_all/california/` is still areal." `output/refit_ca_blocks/README.md`: "Not rebuilt:
  `california/` (statewide), which is still area-overlap." Note that `data/ca/ca_all/state_gYY.csv` now
  hold the block files (copied 2026-10-17), so rerunning `build_california_contests.R` would not
  reproduce `data/ca/ca_all/california/`.
- Areal interpolation assumes voters are spread evenly over each precinct's land; SRPRECs are redrawn every
  election (CLAUDE.md).
- 2024 cells of 1–9 votes are masked (`***`) and read as NA.
- About a quarter of precincts average fewer than 15 votes per measure (`data/ca/ca_all/california/README.md`).
- 2012–2022 counts are estimates, not observed returns.
- `meta.json`: `fit_input = "atlas fit"`, K = 30 fit on these data; `data/mprec_state_g20_v01_shp.*` is a
  California precinct file with no results (CLAUDE.md) and is not used.
