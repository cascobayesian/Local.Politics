# Los Angeles County: how the model-ready data were made

| | |
|---|---|
| Unit type and map | 2024 general-election SR precincts (SWDB "SRPREC", g24), Los Angeles County (FIPS 06037), keyed by `SRPREC_KEY` |
| Units in the model-ready files | 2,674 (of 3,087 g24 SRPRECs; 413 with no votes excluded) |
| Years | 2012, 2014, 2016, 2018, 2020, 2022, 2024 (November generals) |
| Ballot measures | 74 statewide propositions (2012: 11, 2014: 6, 2016: 17, 2018: 11, 2020: 12, 2022: 7, 2024: 10) |
| Federal contests | 9 (President 2012/16/20/24; US Senate 2012, 2022, 2022 special, 2024, 2024 special) |
| Alignment of 2012–2022 | Census-block crosswalk weighted by registered voters (SWDB block maps) |

Bundle: `output/atlas/overview/bundles/la_county/`, a copy (by `code/atlas/overview/01_bundles.R`) of the
Table 2 bundle `output/table2/la/`, which is written by `code/table2/adapt_la.R`. Registry entry
`la_county` in `code/atlas/build_panels.R` reads that bundle.

## Raw data

- **Source:** California Statewide Database (SWDB, statewidedatabase.org), statewide statement-of-vote
  files by SR precinct, one per November general; LA rows are extracted from them. URL pattern recorded in
  `data/ca/state_g10_sov_data_by_g10_srprec/state_g10_sov_data_by_g10_srprec_readme.txt`
  (`http://statewidedatabase.org/pub/data/G10/state/…`). Download dates: Not documented.
- **Format:** wide CSV; propositions `PR_<n>_Y/N`; federal candidates `PRSDEM01`, `USSREP01`, `USPDEM01`…;
  2024 cells of 1–9 votes masked as `***`.
- **Project paths:** `data/ca/state_g12_sov_data_by_g12_srprec.csv` … `state_g24_sov_data_by_g24_srprec.csv`.
  Ballot measures and federal races come from the same files.

## Shapefiles

- SWDB 2024 SR-precinct boundaries, `data/ca/srprec_state_g24_v01_shp/` (source URL for 2024 not recorded;
  2012 equivalent recorded in `data/ca/srprec_state_g12_v01_shp/srprec_state_g12_v01_shp_readme.txt`).
- Unit file used: `data/ca/la_sf_precincts/la_sf_g24_precincts.gpkg` (layer `precincts`, filtered to
  `FIPS_CODE == "06037"`, key `SRPREC_KEY`, NAD83), extracted by `data/ca/extract_la_sf_precincts.R`.
  `units.gpkg` carries all 3,087 precincts; geometry match rate 1 (`meta.json`).

## Alignment across years

- **Target:** 2024 g24 SRPRECs; 2024 returns are observed directly.
- **Method:** `code/ca/reweight_blocks_to_2024.R` (2026-10-17). Weight from source precinct s to 2024
  precinct t: `w(s→t) = Σ_b [reg_src(s,b)/reg_src(s)] · [reg_24(t,b)/reg_24(b)]` — each source precinct's
  votes are spread over its census blocks by its registered voters there, and each block's share goes to the
  2024 precinct(s) holding that block's 2024 registrants. Inputs: SWDB `state_gYY_sr_blk_map.csv` in
  `data/ca/swdb_sr_blk_maps/` (downloaded 2026-10-17 from `https://statewidedatabase.org/pub/data/GYY/state/`).
- **Block vintages:** g12–g20 maps are on 2010 blocks; 2024 registrants are carried onto 2010 blocks with the
  Census 2010→2020 block relationship file (`data/ca/candidate_races/census/tab2010_tab2020_st06_ca.txt`) as
  a land-area share within each 2020 block. g22 and g24 are on 2020 blocks.
- **Unplaceable blocks** (no 2024 registrants) are absorbed within their source precinct by renormalising;
  source precincts with no placeable blocks fall back to the old areal crosswalk
  (`data/ca/ca_historical_on_2024/<year>_on_2024/crosswalk_to_2024.csv`).
- **Years moved:** 2012, 2014, 2016, 2018, 2020, 2022 → 2024 map. Output
  `data/ca/ca_historical_on_2024_blocks/state_gYY_sov_on_g24_srprec_rounded.csv`, copied to
  `data/ca/ca_all/state_gYY.csv`.
- **Rounding:** largest remainder within county × column, so county totals are conserved.
- **LA panel:** `data/ca/ca_all/extract_los_angeles.R` → `data/ca/ca_all/los_angeles/la_gYY.csv`;
  `combine_los_angeles_contests.R` → `los_angeles/la_contests_2012_2024_wide.csv`; `split_la_contests.R`
  → `la_referendums_wide.csv`, `la_presidential_senate_wide.csv`; fit/bundle inputs are the root copies
  `data/ca/ca_all/la_referendums_wide.csv` and `data/ca/ca_all/la_national_wide.csv` (3,087 rows).
  `output/refit_ca_blocks/README.md`: run on the archived areal inputs, the same chain reproduces the old
  panels byte for byte, "so the only change is the weighting."
- Verified here: unit `060370050003A`, 2012 Prop 30 = 268 Yes of 1,206 in the bundle and in the block
  panel (areal panel: 237 of 1,077).

## Summary statistics from alignment

From `data/ca/ca_historical_on_2024_blocks/` (`README.md`, `audit_by_year.csv`,
`conservation_by_county.csv`, `fallback_precincts.csv`, `compare_to_areal.csv`):

| | 2012 | 2014 | 2016 | 2018 | 2020 | 2022 |
|---|---|---|---|---|---|---|
| LA TOTVOTE input | 3,236,704 | 1,518,834 | 3,544,115 | 3,023,417 | 4,338,191 | 2,456,701 |
| LA TOTVOTE output | 3,236,334 | 1,518,605 | 3,542,784 | 3,023,357 | 4,338,128 | 2,456,677 |
| LA precincts on areal fallback (TOTVOTE) | 25 (55) | 11 (37) | 24 (91) | 13 (81) | 56 (216) | 28 (159) |
| Statewide votes unplaced | 0.018% | 0.012% | 0.018% | 0.008% | 0.002% | 0.002% |

- README: "Apart from those unplaced precincts, every county total of every column is conserved exactly."
- Agreement with the areal panel: proposition yes-share r = 0.995 for LA (README; precincts with ≥ 20 ballots).
- `meta.json` canary: empirical ballot-weighted bloc means vs model probabilities r = 0.9997.

## What is in the model-ready files

- **Ballot measures:** all 74 statewide November propositions 2012–2024. Success side = **Yes** for every
  measure ("the fit's x matrix equals the Yes column of la_referendums_wide.csv exactly", `meta.json`).
  None dropped. Missing cells are absent from `votes.csv` (190,333 rows; `n > 0` only).
- Labels in `output/table2/la/questions.csv` are hand-entered abbreviations of the SoS ballot titles.
- **Federal races:** party totals (summed per party) from `la_national_wide.csv`: 2012/2016/2020/2024
  President, 2012/2022/2024 US Senate, 2022/2024 US Senate special. Dropped D-vs-D top-two Senate
  generals 2016 and 2018; unit-contests with dem + rep = 0 dropped. `partisan.csv`: 22,965 rows, 2,665 units.
- **Units excluded:** 413 of 3,087 precincts with zero votes on every question (zero-registrant
  pseudo-precincts under block weighting); in `units.gpkg` only.

## Other datasets

All in the project, none in the bundle:

- **LA County RR/CC precinct statements of votes cast (raw zips):** `data/ca/candidate_races/lavote/`
  `3793_Final_Primary_SVC.zip` (2018-06-05 primary), `3861_final_svc_excel.zip` (2018-11-06 general),
  `4085_final_excelsvc.zip` (2020-03-03 primary), `4193_Final_SVC_Excel.zip` (2020-11-03 general): one .xls
  per contest, by registration precinct. Besides state measures they include **local measures**, e.g.
  county Measure R (2020-03) and Measure J (2020-11); LAUSD EE (2018-11) and RR (2020-11); city and school
  measures (Monrovia TT, Pasadena USD BB, Temple City VP, Wiseburn USD W, Hawthorne SD HSD, Inglewood USD
  ID/I, Little Lake LL, Burbank USD QS, Acton–Agua Dulce CK, Alhambra AL/G/V, Bell TT, Calabasas N, Duarte D,
  Gardena G, Hawaiian Gardens HG, Lakewood L, Norwalk P, San Fernando MJ, San Gabriel SG, Whittier W,
  Culver City B, Monterey Park JJ). Countywide totals for all contests in `summary_<id>.json` (31/79/52/69
  non-candidate contests). Not processed; registration-precinct geography, not on the g24 map (SWDB
  `c037_g18/g20/p18/p20_rg_blk_map.csv` in `data/ca/candidate_races/swdb/` would place them).
- **Primary-ballot statewide propositions, LA, not aligned:** `data/ca/candidate_races/swdb/c037_p18_sov_data_by_p18_srprec.csv`
  (Props 68–72, 4,257 rows), `c037_p20_…` (Prop 13, 3,597), `c037_p24_…` (Prop 1, 2,392); own SRPREC map
  each; SWDB block maps `c037_pYY_sr_blk_map.csv` alongside.
- **Local candidate contests (SWDB):** `data/ca/candidate_races/swdb/c037_{p22,g22,p24,g24}_sov_local_{city,county}_by_*_srprec.csv`
  (long: srprec, contest, jurisdiction, office, district, candidate, votes). I found no Yes/No measure
  contests in them.
- **Candidate outcomes on the bundle's g24 units (block method):**
  `output/la_sf/candidate_races/unit_outcomes.csv` (`code/la_sf/ca_candidate_races_blocs.R`; LA 14
  contests 2022–2024: mayor, city attorney, controller, sheriff, DA, top-two primaries; 2,617 units) and
  `output/la_sf/durable_factions/outcomes_long.csv` (`code/la_sf/durable_factions_data.R`; LA 14 contests
  2018–2024 incl. sheriff 2018 and DA 2020 from the RR/CC files; 2,625 units). Same unit map.
- **Archived areal panel:** `data/ca/ca_all/archive/areal_panels_20261017/la_referendums_wide.csv`,
  `la_national_wide.csv` (same 74 measures, superseded).

## Known issues

- 2012–2022 returns are estimates moved onto the 2024 map, not observed returns (`meta.json`).
- 2024 cells of 1–9 votes are masked and read as NA (README "Not changed").
- About 5,200 g24 SRPRECs statewide have no registrants (empty land, mail-ballot pseudo-precincts); the
  block method leaves them empty (LA: 413, previously 90 under the areal method).
- The fit is the K = 10 warm start, not the best K = 10 optimum (+268 logLik; `output/refit_ca_blocks/README.md`).
- `output/refit_ca_blocks/README.md` warns `adapt_la.R` would stop at its "fit input identical to wide file"
  assertion if run against the old paper fit; the current script reads the refit export.
