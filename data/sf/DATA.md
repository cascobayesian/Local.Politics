# San Francisco: how the model-ready data were made

| | |
|---|---|
| Unit type and map | 2024 general-election SR precincts (SWDB "SRPREC", g24), San Francisco (FIPS 06075), keyed by `SRPREC_KEY` |
| Units in the model-ready files | 510 (of 514 g24 SRPRECs; 4 zero-registrant pseudo-precincts 9901–9904 excluded) |
| Years | Ballot measures 2012, 2014, 2016, 2018, 2020, 2022; federal contests 2012–2024 |
| Ballot measures | 64 statewide propositions (2012: 11, 2014: 6, 2016: 17, 2018: 11, 2020: 12, 2022: 7) |
| Federal contests | 9 (President 2012/16/20/24; US Senate 2012, 2022, 2022 special, 2024, 2024 special) |
| Alignment of 2012–2022 | Census-block crosswalk weighted by registered voters (SWDB block maps) |

Bundle: `output/atlas/overview/bundles/sf/`, a copy (by `code/atlas/overview/01_bundles.R`) of the Table 2
bundle `output/table2/sf/`, written by `code/table2/adapt_sf.R`. Registry entry `sf` in
`code/atlas/build_panels.R` reads that bundle (map cropped to exclude the Farallon Islands).

## Raw data

- **Source:** California Statewide Database (SWDB, statewidedatabase.org), statewide statement-of-vote files
  by SR precinct, one per November general; SF rows extracted. URL pattern recorded in
  `data/ca/state_g10_sov_data_by_g10_srprec/state_g10_sov_data_by_g10_srprec_readme.txt`
  (`http://statewidedatabase.org/pub/data/G10/state/…`). Download dates: Not documented.
- **Format:** wide CSV; propositions `PR_<n>_Y/N`; federal candidates `PRSDEM01`, `USSREP01`, `USPDEM01`…;
  2024 cells of 1–9 votes masked as `***`.
- **Project paths:** `data/ca/state_g12_sov_data_by_g12_srprec.csv` … `state_g24_sov_data_by_g24_srprec.csv`.
  Ballot measures and federal races come from the same files.

## Shapefiles

- SWDB 2024 SR-precinct boundaries, `data/ca/srprec_state_g24_v01_shp/` (2024 URL not recorded; 2012
  equivalent recorded in `data/ca/srprec_state_g12_v01_shp/srprec_state_g12_v01_shp_readme.txt`).
- Unit file used: `data/ca/la_sf_precincts/la_sf_g24_precincts.gpkg` (layer `precincts`, `FIPS_CODE == "06075"`,
  key `SRPREC_KEY`, NAD83), extracted by `data/ca/extract_la_sf_precincts.R`. Geometry match rate 1.

## Alignment across years

- **Target:** 2024 g24 SRPRECs; 2024 returns observed directly.
- **Method:** `code/ca/reweight_blocks_to_2024.R` (2026-10-17): `w(s→t) = Σ_b [reg_src(s,b)/reg_src(s)] ·
  [reg_24(t,b)/reg_24(b)]` — each source precinct's votes spread over its census blocks by its registered
  voters, each block's share sent to the 2024 precinct(s) holding its 2024 registrants. Inputs: SWDB
  `state_gYY_sr_blk_map.csv` in `data/ca/swdb_sr_blk_maps/` (downloaded 2026-10-17 from
  `https://statewidedatabase.org/pub/data/GYY/state/`).
- **Block vintages:** g12–g20 maps are on 2010 blocks, bridged to the 2024 (2020-block) registrants with the
  Census 2010→2020 block relationship file (`data/ca/candidate_races/census/tab2010_tab2020_st06_ca.txt`),
  as a land-area share within each 2020 block. g22 uses 2020 blocks.
- **Unplaceable blocks** are absorbed within their source precinct by renormalising; precincts with no
  placeable blocks fall back to the areal crosswalk (`data/ca/ca_historical_on_2024/<year>_on_2024/crosswalk_to_2024.csv`).
- **Years moved:** 2012–2022 → 2024 map. Output `data/ca/ca_historical_on_2024_blocks/state_gYY_sov_on_g24_srprec_rounded.csv`,
  copied to `data/ca/ca_all/state_gYY.csv`.
- **Rounding:** largest remainder within county × column (county totals conserved).
- **SF panel:** `data/ca/ca_all/extract_san_francisco.R` → `data/ca/ca_all/san_francisco/sf_gYY.csv`;
  `combine_san_francisco_contests.R` → `san_francisco/sf_contests_2012_2024_wide.csv`; `split_sf_contests.R`
  → `sf_referendums_wide.csv`, `sf_presidential_senate_wide.csv`. Bundle inputs: `data/ca/ca_all/sf_referendums_wide.csv`
  and `data/ca/ca_all/sf_national_wide.csv` (514 rows). Per `output/refit_ca_blocks/README.md`, the same
  chain run on the archived areal inputs reproduces the old panels byte for byte.

## Summary statistics from alignment

From `data/ca/ca_historical_on_2024_blocks/` (`README.md`, `conservation_by_county.csv`,
`fallback_precincts.csv`, `audit_by_year.csv`):

| | 2012 | 2014 | 2016 | 2018 | 2020 | 2022 |
|---|---|---|---|---|---|---|
| SF TOTVOTE input | 364,875 | 231,214 | 414,528 | 372,848 | 449,866 | 310,071 |
| SF TOTVOTE output | 364,871 | 231,212 | 414,524 | 372,845 | 449,861 | 310,071 |
| Statewide votes unplaced | 0.018% | 0.012% | 0.018% | 0.008% | 0.002% | 0.002% |

- SF precincts on the areal fallback: one, in 2018 (1 vote).
- README: every county total of every column is conserved exactly apart from unplaced precincts;
  proposition yes-share agreement with the areal panel r = 0.993 for SF (precincts with ≥ 20 ballots).
- `meta.json` canary: empirical ballot-weighted bloc means vs model probabilities r = 0.9999.

## What is in the model-ready files

- **Ballot measures:** 64 statewide November propositions, 2012–2022. Success side = **Yes** for every
  measure ("the fit's x matrix equals the Yes column exactly", `meta.json`).
- **Dropped:** the 10 propositions of 2024 (74 → 64). Reason given: "64 of 74 California props, as in the
  earlier fit (precinct 7636 has no 2024 returns)" (`meta.json`, `code/table2/adapt_sf.R`).
- `votes.csv`: 32,597 rows (`n > 0` only).
- **Federal races:** party totals from `sf_national_wide.csv`: President 2012/2016/2020/2024, US Senate
  2012/2022/2024, US Senate special 2022/2024. Dropped D-vs-D top-two Senate generals 2016 and 2018;
  unit-contests with dem + rep = 0 dropped. `partisan.csv`: 4,584 rows, 510 units.
- **Units excluded:** precincts 9901–9904 (zero-registrant pseudo-precincts, no votes under block weighting).

## Other datasets

All in the project, none in the bundle. **SF local propositions exist at precinct level for 1996–2024.**

- **SF Department of Elections statements of vote (raw):** `data/sf/SOV*.xls[x]`, 50 elections from
  `SOV960326` (1996-03-26) to `SOV241105` (2024-11-05), plus `*_neighborhood.xlsx` summaries. One sheet per
  contest, by DoE precinct; include local propositions (e.g. Nov 2024 Measures A–O). DoE as source is
  inferred from the sheet headers ("City and County of San Francisco"); no README or URL recorded.
- **Processed SF tables (no README; precinct ids are DoE precinct numbers of each election, not crosswalked
  to the g24 map):**
  - `data/sf/sf_1996_2013.csv` — wide, 2,932 rows (2,905 `PCT nnnn` precinct rows + neighbourhood rows) ×
    434 Yes/No pairs, 1996–2013: 184 state and 250 local/other measure columns (some duplicated `.x/.y`).
  - `data/sf/sf_2014_2022.csv` — long (precinct, registered, yesvotes, novotes, issue, elec), 94,605 rows,
    12 elections 2014-11 to 2022-02: 64 "Local Measure", 40 state, 47 other (school/district/regional) issues.
  - `data/sf/sf_2016_2024.csv` — long, every contest incl. candidates (registered, total, issue, elec,
    position, votes, precinct), 1,307,122 rows, 13 elections 2016-11 to 2024-11, 392 contests.
  - `data/sf/sf_2016_2024_ref_cleaned.csv` — wide, 633 precincts × 157 measures (62 state, 95
    local/regional/district), 8 elections 2016-11 to 2024-11; 510 of the 633 ids equal g24 SRPREC numbers.
  - Parsing scripts: `data/sf/sf_14_24.R`, `data/sf/sf_org.r`, `data/sf/reorder.votes.r`.
- **SF precinct shapes:** `data/sf/SF_DOE_PREC_2022_07_18_pg.shp` (DoE 2022 precincts); `data/sf/sf.2/`
  (SWDB `c075_g22/g24_sov_data_by_*_svprec.csv`, `mprec_075_g22_v01_shp/`, `mprec_075_g24_v01.gpkg`).
- **DoE files used for candidate work:** `data/ca/candidate_races/sf_doe_2018_2019/` (`20180627_sov.xlsx`:
  June 2018 incl. Local Measures A–I and Regional Measure 3; `20191125_sov.xlsx`: Nov 2019 incl. Props A–F;
  ballot images/CVR), `sf_doe_2020/20201201_sov.xlsx` (Nov 2020 incl. Props A–L and RR; CVR),
  `sf_doe_2024/sov.xlsx` (Nov 2024 incl. Measures A–O; CVR). Only the mayor/DA RCV results were processed
  (`sf_mayor_2018_precinct.csv`, `sf_mayor_2019_precinct.csv`, `sf_da_2019_precinct.csv`, `sf_mayor_2024_precinct.csv`).
- **SWDB SF files:** `data/ca/candidate_races/swdb/c075_p22_sov_local_county_by_p22_srprec.csv` (Boudin
  recall, Yes/No, 612 p22 precincts); `c075_{g22,g24,p22}_sov_local_*` (local candidate contests);
  primary-ballot state propositions `c075_p18_…` (Props 68–72, 605 rows), `c075_p20_…` (Prop 13, 610),
  `c075_p24_…` (Prop 1, 515) — own SRPREC maps, with block maps `c075_pYY_sr_blk_map.csv`.
- **Candidate outcomes on the bundle's g24 units:** `output/la_sf/candidate_races/unit_outcomes.csv`
  (SF 11 contests 2022–2024, 510 units) and `output/la_sf/durable_factions/outcomes_long.csv` (SF 13
  contests 2018–2024 incl. the 2022 Boudin recall, 510 units). Same unit map.
- **Archived areal panel:** `data/ca/ca_all/archive/areal_panels_20261017/sf_referendums_wide.csv`, `sf_national_wide.csv`.

## Known issues

- 2012–2022 returns are estimates moved onto the 2024 map, not observed returns (`meta.json`).
- 2024 masked cells (1–9 votes) are read as NA; the 2024 propositions are not used at all.
- `data/ca/ca_all/em_bic_sf_national_results/` is mislabelled (it is an LA fit) and was not used (`meta.json`).
- The fit includes the Farallon Islands precinct, 40 km offshore (`code/atlas/build_panels.R`).
- Question labels are hand-entered abbreviations of SoS ballot titles, not machine-verified.
- `data/sf/SOV160607.xls` and `SOV160624.xls` have identical sizes (possible duplicate; not checked).
