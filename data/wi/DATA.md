# Wisconsin: how the model-ready data were made

| | |
|---|---|
| Unit | WEC reporting unit (one municipality's ward group) of the 5 November 2024 general, built from LTSB ward layers and 2020 blocks |
| Units | 3,559 in the bundle (`blocs.csv`), out of 3,603 target units. 44 zero-ballot units are excluded. 3,554 units have ballot-measure rows. |
| Years | Ballot measures 2018–2025; federal races 2016–2024 |
| Ballot measures | 10 (`votes.csv`) |
| Federal contests | 7 (`partisan.csv`): President 2016, 2020, 2024; US Senate 2016, 2018, 2022, 2024 |

Bundle: `output/atlas/overview/bundles/wi/`. Build folder: `data/wisconsin/realign_2024/` (README there, built 2026-10-19).

## Raw data

Both the ballot measures and the federal races come from the same source.

- **Returns**: Wisconsin Elections Commission (WEC) ward-by-ward canvass workbooks (`.xlsx`), `https://elections.wi.gov/sites/default/files/...`.
  - Per-file URLs are in `scripts/01_download.sh` and in the column key.
  - The link list was read once in a browser because of Cloudflare: `raw/wec/wi_wec_links_main.txt`.
  - Files: `data/wisconsin/realign_2024/raw/wec/files/` (e.g. `2018S_referendum_ward.xlsx`, `2023S_referendum.xlsx`, `2024P_referendum.xlsx`, `2025S_state_referendum.xlsx`, `2016G_president_recount.xlsx`, `2020G_president_afterrecount_ad.xlsx`, `2024G_federal_state.xlsx`).
  - 2016 President is the recount canvass; 2020 President is the after-recount workbook.
- `metadata/download_log.tsv` records URL, bytes and SHA-256 prefix.
- Parsed native returns: `data/wisconsin/realign_2024/output/native/`.

## Shapefiles

- **Ward maps**: LTSB statewide municipal ward layers, January ("Spring") and July ("Fall") submissions, 2017–2025.
  - Source: the UW–Madison Robinson Map Library archive, `https://web.s3.wisc.edu/rml-gisdata/WI_MunicipalWards_<Spring|Fall>_<year>.zip`.
  - 16 layers were used; Spring 2018 and Fall 2021 are not in the archive.
  - Stored in `data/wisconsin/realign_2024/raw/ltsb_wards/`.
- **Target**: the 3,603 November 2024 reporting units, each the union of the wards it names. It is built from whole 2020 blocks (land parts only), giving a gap-free tessellation.
  - File: `geometry/wi_precincts_target.gpkg` (EPSG:4269).
  - The registry and bundle use `geometry/wi_precincts_target_land.gpkg`, written by `scripts/06_crosswalks.R` and the later figure scripts.
- Blocks: TIGER 2020 `tl_2020_55_tabblock20` (203,059 blocks, 5,893,718 residents), in `raw/census/`.

## Alignment across years

Method: NYC 2020-block-population crosswalk, applied to reporting units (RUs). Every election other than the November 2024 general (2016G, 2018S, 2018G, 2020S, 2020G, 2022G, 2023S, 2024S, 2024P, 2025S) was moved onto the November 2024 RUs.

Scripts in `data/wisconsin/realign_2024/scripts/` (run by `run_all.R`):
- `02_parse_returns.R`: absentee and early ballots are reported inside the RU, so there are no county rows.
- `03_prepare_wards.R`: prepares the ward layers.
- `04_assign_blocks.R`: assigns every block whole, by internal point, to a ward of every layer.
- `05_ru_wards.R`: parses each RU label into a municipality and a ward list. The ward map is chosen **per municipality**: the best-matching layer dated before the election.
- `06_crosswalks.R`: builds the target and the weights, `weight = pop(RU's blocks in target) / pop(RU's blocks)`. Fallbacks are land area, then ward-polygon overlap.
- `07_align.R`: produces the fractional estimates, then integers by **largest remainder within contest × choice**. Fractional values: `output/final_datasets/wi_aligned_fractional_long.csv.gz`.
- `08_validate.R`: validation checks.

`09_bbmm_inputs.R` builds `data/bbmm_benchmarks/wisconsin_2024align.rds` from the integer columns. The bundle is made from that file by `code/atlas/overview/01_bundles.R`.

Main layer per election:

| Election | Main layer |
|---|---|
| 2016G | Spring 2017 |
| 2018S | Fall 2017 |
| 2018G | Fall 2018 |
| 2020S | Spring 2020 |
| 2020G | Fall 2020 |
| 2022G | Fall 2022 |
| 2023S | Spring 2023 |
| 2024S | Spring 2024 |
| 2024P | Fall 2024 |
| 2025S | Spring 2025 |

Full detail is in `crosswalks/election_muni_vintage.csv`.

## Summary statistics from alignment

From `data/wisconsin/realign_2024/README.md`. Detail in `metadata/validation.csv`, `validation_county.csv`, `placement_summary.csv` and `placement_nonexact.csv`.

- **Ballots placed exactly**: 99.69–100% per election. The rest are `partial` RUs (0.12–0.31%; e.g. Fort Atkinson, Menasha 2016).
- **Share of RUs moving whole into one 2024 RU**: 69–73% (2016–2020, before the 2022 ward redraw), 93% (2022–23), 95–97% (2024S, 2024P, 2025S), 100% (2024G).
- **Unallocated**: 5 votes in the whole panel (2020 President, "Village of WAUKESHA Ward 12"), 0.0002% of that contest.
- **Block assignment to the target**: 202,692 blocks go by ward; 137 blocks (2,722 residents) sit in wards named by two RUs; 181 blocks (4,038 residents) are in no 2024 RU and go to the nearest RU of the same municipality.
- **Validation (all 0 failures)**:
  - RU sums equal the WEC County Totals (4,824 rows) and Office Totals (67).
  - Nominees equal the certified totals (14).
  - Aligned + unallocated equals native (85, max 2e-9).
  - The integer version of that check also passes (85).
  - In November 2024, every unit reproduces its own return (75,663 cells).
- **Dem share correlation**: r = 0.988 (2020 vs 2024 Pres) and 0.970 (2016 vs 2024).

## What is in the model-ready files

- **Ballot measures (10, success = Yes)**:
  - `2018_04_q1`: abolish State Treasurer
  - `2020_04_q1`: Marsy's Law
  - `2023_04_q1`: conditions of release
  - `2023_04_q2`: cash bail
  - `2023_04_q3`: advisory, welfare work requirement
  - `2024_04_q1`: private election funds
  - `2024_04_q2`: election officials
  - `2024_08_q1`: delegation of appropriation power
  - `2024_08_q2`: federal funds allocation
  - `2025_04_q1`: photo ID

  All are spring or August-primary ballots.
- **Missing**: the November 2024 citizenship amendment. WEC published it only as a county PDF (`raw/wec/files/2024G_county_referendum.pdf`). The November 2014 and April 2015 questions predate the window and the ward layers.
- **Federal races (7, Dem v Rep nominees)**: President 2016, 2020, 2024; US Senate 2016, 2018, 2022, 2024.
- **Units excluded**: the 44 November 2024 RUs with no ballots. Cells with n = 0 are also absent (506 NA cells, 0.84%).

## Other datasets

- **Local (county, municipal or school) referenda: none found in the project.** WEC's statewide workbooks hold only statewide questions and offices, and no local-referendum file was downloaded. The README does not mention local measures.
- **Raw candidate contests (not aligned)**, on that election's RUs, in `data/wisconsin/realign_2024/raw/wec/files/`:
  - `2024S_all.xlsx`: April 2024 presidential primaries, Court of Appeals and circuit judges (63 sheets).
  - `2025S_state_referendum.xlsx`: April 2025 State Superintendent, Supreme Court, Court of Appeals and circuit judges, plus the photo-ID question.
  - `2026S_all_state.xlsx`: April 2026 Supreme Court and judges.
  - `2026P_all_state.xlsx`: August 2026 partisan primary (646 sheets).
  - `2024G_federal_state.xlsx`: Nov 2024 US House, state Senate and Assembly (198 sheets).
  - County-level copies: `2018S_referendum_county.xlsx`, `2020S_referendum_county.xlsx`, `2025S_county.xlsx`, `2026S_county.xlsx`, and the 2024 PDFs.
- **LTSB ward-disaggregated election data (downloaded, not used)**: `data/wisconsin/realign_2024/raw/ltsb_election_layers/*.geojson`.
  - Four layers, each in 2,000-feature pages: 2012–2018 on 2011 wards, 2012–2020 on 2020 wards, 2022 on 2022 wards, 2024 on 2025 wards.
  - They hold ward-level estimates for Governor, Secretary of State, Treasurer, President, US Senate, US House, state Senate and Assembly, plus Census race/VAP fields.
  - They are on LTSB ward maps, not the 2024 RU map.

## Known issues

- The November 2024 citizenship amendment has no ward-level file.
- All ten questions were on low-turnout ballots (0.95–2.3 million votes, against 3.4 million in November 2024), so their electorates differ from the federal races'.
- WEC RU labels can lag the ward map, so the map is chosen per municipality.
- Ward ids carry letters and ranges.
- Same-named towns are matched within county.
- Menominee County is FIPS 078.
- 2016–2020 RUs predate the 2022 ward redraw, and only about 70% move whole into one 2024 unit.
- The atlas fit pools 7 partisan races with 10 questions (README caveat; CLAUDE.md).
- CLAUDE.md lists 3,603 units, which is the target; the fit uses 3,559.
