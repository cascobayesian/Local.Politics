# Michigan: how the model-ready data were made

| | |
|---|---|
| Unit | Precinct, Michigan Bureau of Elections / State of Michigan GIS **2024** precinct layer |
| Units | 4,340 (all with ballot-measure and federal votes in the bundle) |
| Years | Ballot measures 2014–2022; federal races 2014–2024 |
| Ballot measures | 10 (`votes.csv`) |
| Federal contests | 7 (`partisan.csv`): US Senate 2014, 2018, 2020, 2024; President 2016, 2020, 2024 |

Bundle: `output/atlas/overview/bundles/mi/`. Build folder: `data/michigan/realign_2024/` (README there, built 2026-10-18).

## Raw data

Both the ballot measures and the federal races come from the same source.

- **Precinct returns, 2014–2024 November generals**: Michigan Bureau of Elections (Secretary of State),
  `https://mvic.sos.state.mi.us/VoteHistory/GetPrecinctResultsFile?electionId=` 662 / 670 / 676 / 683 / 691 / 699.
  Tab-delimited `vote/name/offc/city/county` text files in zips (layout in each zip's `readme.txt`). The site sits behind a Cloudflare check, so
  the files were fetched in a browser on 2026-10-18. Project path: `data/michigan/realign_2024/raw/sos_precinct_results/<YYYY>GEN.zip`
  (README gives SHA-256 prefixes).
- **Official county canvass** (used only for validation): same site, `GetElectionResultFile?electionId=...` →
  `data/michigan/realign_2024/raw/sos_county_results/<YYYY>STATE_GENERAL_MI_CENR_BY_COUNTY.txt`.
- Ballot wording: Ballotpedia measure pages (URLs in `data/michigan/realign_2024/metadata/proposal_wording.csv`). The README says the wording was not checked against the SOS PDFs.
- Parsed native returns: `data/michigan/realign_2024/output/native/`.

## Shapefiles

- **Target (2024) and source layers**: State of Michigan open-data precinct layers,
  `https://gisagocss.state.mi.us/arcgis/rest/services/OpenData/boundaries/MapServer`, layers 0, 1, 2, 6, 7, 9, one per general-election year
  (2014, 2016, 2018, 2020, 2022, 2024). Downloaded by `data/michigan/realign_2024/scripts/01_download_precinct_layers.py` to
  `data/michigan/realign_2024/raw/state_gis_precincts/mi_precincts_<YYYY>.geojson`.
- Target layer: `data/michigan/realign_2024/geometry/mi_precincts_target.gpkg` (EPSG:3078; `join_id`, 2020 population, 2024 registered voters).
  The atlas registry (`code/atlas/build_panels.R`) and the bundle's `units.gpkg` use the land-clipped copy
  `data/michigan/realign_2024/geometry/mi_precincts_target_land.gpkg` (written by `scripts/16_blocs_vs_race_density.R`).
- Census: TIGER 2020 blocks `tl_2020_26_tabblock20` (`raw/census/tabblock20/`, 254,730 blocks, 10,077,331 residents) and county subdivisions `tl_2020_26_cousub` (`raw/census/cousub20/`).

## Alignment across years

Method: the project's NYC 2020-block-population crosswalk (skill `precinct-alignment-bbmm`). 2014, 2016, 2018, 2020 and 2022 returns were moved onto the 2024 layer; 2024 maps onto itself. Steps (scripts in `data/michigan/realign_2024/scripts/`, run by `run_all.R`):

1. `02_parse_returns.R`: keep offices 1 (President), 5 (US Senate) and 90 (statewide proposals). Units are precincts, Detroit absent-voter counting boards (AVCBs) and county "{Statistical Adjustments}" rows.
2. `03_jurisdiction_crosswalk.R`: match SOS jurisdictions to Census MCDs by name within county, with 17 manual fixes. SOS city codes were renumbered in 2024.
3. `04_prepare_geometry.R`: dissolve each layer to county–MCD–ward–precinct–letter.
4. `05_match_units.R`: match SOS units to polygons on all six layers with rules r1 exact through r5 positional. Each election uses its own year's layer unless another layer matches at least 1 pp more of a jurisdiction's votes (`metadata/vintage_choice_by_jurisdiction.csv`, `crosswalks/unit_to_polygon.csv`).
5. `06_build_crosswalks.R`: each 2020 block goes whole to one polygon per layer by internal point. `weight = pop(src ∩ tgt) / pop(src)`; zero-population polygons use area overlap.
6. `07_align.R`: Detroit AVCB votes are spread over Detroit's matched precincts in proportion to each precinct's own votes for that choice. Unmatched precinct units are spread over the jurisdiction's unmatched polygons by 2020 population. Statistical-adjustment rows and three small cross-county fragments are held out (`metadata/unallocated_votes.csv`).
7. `07_align.R` / `09_build_final_datasets.R` (helper in `00_common.R`): integers are a **largest-remainder rounding within contest × choice**, so every column sums to the statewide aligned total. Fractional values: `output/final_datasets/mi_fractional_long.csv.gz`.

The fit input `data/bbmm_benchmarks/michigan_2024align.rds` is built by `scripts/10_florida_style.R` from the integer columns of `mi_combined.csv`. `code/atlas/overview/01_bundles.R` reads that `.rds` to make the bundle.

## Summary statistics from alignment

From `data/michigan/realign_2024/README.md` and `metadata/`:
- Jurisdictions: 9,206 of 9,221 jurisdiction-years matched to MCDs. The 15 that did not match have no votes.
- Layer choice: 98.2–99.95% of matched precinct votes use the election's own-year layer.
- Share of 2020 population changing precinct relative to 2024: 32% (2014 layer), 31%, 28%, 26%, 12% (2022 layer).
- AVCBs hold 1.4–3.1% of the statewide vote but 30–70% of Detroit's. Unmatched precinct units are 0.03–0.13% of votes per year.
- Held (unallocated): statistical-adjustment rows, with a net of −1,220 and an absolute total of 19,706 across all 17 contests, plus 369 votes in cross-county fragments.
- Conservation: 90 of 90 contest × choice checks pass (aligned + unallocated = native, to 1e-6). Detail in `metadata/alignment_checks.csv`.
- Precinct file vs county canvass: exact for 2014, 2016, 2018 and 2024. 2020 is 0.06% below the canvass (negative adjustment rows). In 2022, proposals 22-1 and 22-3 are 0.04–0.07% below, and 22-2 is 0.66% below because Ionia County is missing.
- Largest aligned-vs-certified gaps: 2024 Rogers −392 and Trump −298; 2020 Biden −17 and Trump −23.
- Plausibility: precinct Dem two-party share correlates 0.969 between 2020 and 2024, and 0.954 between 2016 and 2024.
- Files: `metadata/validation_statewide.csv`, `validation_county.csv`, `validation_summary.csv`, `unit_match_summary.csv`, `spatial_qa.csv`.

## What is in the model-ready files

- **Ballot measures (10, success = Yes)**: `PROP_14_1_2014`, `PROP_14_2_2014` (wolf-hunting referendums); `PROP_18_1_2018` (marijuana), `PROP_18_2_2018` (redistricting commission), `PROP_18_3_2018` (Promote the Vote); `PROP_20_1_2020` (natural-resources trust fund), `PROP_20_2_2020` (electronic-data warrants); `PROP_22_1_2022` (term limits/disclosure), `PROP_22_2_2022` (Promote the Vote 2022), `PROP_22_3_2022` (reproductive freedom).
- No statewide proposals were on the November 2016 or 2024 ballots, or on any primary or special ballot from 2016 to 2024.
- **Dropped**: the May 2015 special (Proposal 15-1, roads/sales tax). The SOS publishes no precinct file for it.
- **Federal races (7, Dem v Rep nominees)**: US Senate 2014, 2018, 2020, 2024; President 2016, 2020, 2024.
- **Units excluded**: none from the 4,340. Bundle rows with n = 0 are dropped by `01_bundles.R`, so `PROP_22_2_2022` covers 4,312 units (Ionia County's 27 precincts are missing). A few other contests cover 4,331–4,339 units.

## Other datasets

- **Local (county/municipal/school) measures: none in the project.** The README says the SOS statewide precinct files contain no local proposals, and that Michigan's local measures are published only by counties.
- **Precinct candidate contests (raw, not aligned)**: the same SOS zips (`data/michigan/realign_2024/raw/sos_precinct_results/<YYYY>GEN/`) also hold state offices, legislative, education-board and Supreme Court races for 2014–2024. Only offices 1, 5 and 90 were parsed.
- **Unparsed**: `data/michigan/realign_2024/raw/openelections_sources_ionia_2022/Ionia_MI_Results_2022.pdf` is a scanned Ionia County canvass that would fill the 22-2 gap. It has not been parsed.
- Checked: `data/michigan/` contains only `realign_2024/`. The atlas `detroit` bundle is a cut-out of this one (same units and contests).

## Known issues

- Ionia County is missing from the SOS 2022 precinct file for Proposal 22-2. Its precincts are 0/0, which means missing, not zero.
- SOS city codes changed in 2024, so jurisdictions should never be joined across years on code.
- The US Senate office code is 5 in the precinct files but 7 in the 2024 county canvass.
- `{Statistical Adjustments}` rows can be negative. They are held out, not allocated.
- Detroit AVCB allocation assumes absentee voters split like election-day voters in their precinct, within each choice.
- Pre-2024 values are estimates on 2024 boundaries.
- The atlas fit pools 7 federal races with 10 measures, so the blocs are mostly a partisan ladder (README; CLAUDE.md notes this flatters the federal-race panels).
