# New Mexico: how the model-ready data were made

| | |
|---|---|
| Unit | Precinct, NM SOS / UNM-EDAC Voting Precinct layer = 2024 general-election map (2,169 precincts) |
| Units in the bundle | 2,169 (none dropped) |
| Years | November generals 2014, 2016, 2018, 2020, 2022, 2024 |
| Ballot measures | 38 (17 constitutional amendments, 21 general-obligation bond questions) |
| Federal contests | 7 (President 2016, 2020, 2024; US Senate 2014, 2018, 2020, 2024) |

Bundle: `output/atlas/overview/bundles/nm/`, built by `code/atlas/overview/01_bundles.R` from `data/bbmm_benchmarks/new_mexico_2024align.rds`. Build folder: `data/new_mexico/realign_2024/` (README: `data/new_mexico/realign_2024/README.md`).

## Raw data

Ballot measures and federal races come from the same source:

- **New Mexico Secretary of State results site**, `https://electionresults.sos.nm.gov`. Election ids: eid 2 = 2014, 84 = 2016, 2698 = 2018, 2782 = 2020, 2838 = 2022, 2882 = 2024.
  - On each `resultsSW.aspx?type=FED|SW&map=CTY&eid=…` page, every race has a "Precinct" export and a "County" export.
  - The Precinct export is an ASP.NET postback returning .xlsx, one sheet per county and one row per precinct.
  - The County export is the official county canvass, with absentee, early and election-day sheets.
- Files are in `data/new_mexico/realign_2024/raw/sos/<eid>/`, downloaded by `scripts/01_download_sos.py` (helper `sos_lib.py`).
- 2014 ballot wording is not on the SOS site. Short titles come from the LWV NM 2014 voter guide (lwvnm.org/VGuide2014/), in `scripts/contest_titles.csv`.
- 2012 and earlier exist only as statewide PDFs and are not included.

## Shapefiles

- Target (the units): NM SOS / UNM-EDAC Voting Precinct layer, `https://edacarcweb.unm.edu/arcgis/rest/services/SOS/NMSOS_Political/MapServer/0` (2,177 rows → 2,169 precincts after unioning multi-part rows). Raw: `raw/edac/`.
  - Project file: `data/new_mexico/realign_2024/geometry/nm_precincts_target.gpkg` (EPSG:26913), joined on `join_id` (`NM_<county FIPS>_<4-digit precinct>`).
  - The atlas/bundle geometry is the land-only version `geometry/nm_precincts_target_land.gpkg`.
  - The layer agrees with the NYT 2024 precinct map at IoU ≥ 0.989 on all 2,165 shared precincts (`metadata/geometry_target_vs_nyt.csv`; NYT file in `raw/nyt/`).
- Source maps for earlier years: VEST 2016, 2018, 2020 from Harvard Dataverse (doi:10.7910/DVN/NH5S2I, UBKYRU, K7760H), in `raw/vest/`. Cleaned copies: `geometry/native_vest2016.gpkg`, `native_vest2018.gpkg` and `native_vest2020.gpkg`.
- Weights: TIGER/Line 2020 blocks `tl_2020_35_tabblock20` (107,215 blocks, 2,117,522 residents), `raw/blocks2020/`.

## Alignment across years

- **Method:** the NYC 2020-block-population method. Every 2020 block is assigned whole, by internal point, to one polygon of each map within its county (fallbacks: max overlap, nearest). Weight = pop20(group ∩ 2024 precinct) / pop20(group). Ten zero-population groups use overlap area.
- **Map per election × county** (`metadata/vintage_choice.csv`, `vintage_scores.csv`):
  - 2014 and 2016 → VEST 2016. Five 2016-only split polygons in McKinley and Santa Fe are merged back to their 2014 parents (`scripts/merge_rules.csv`).
  - 2018 → VEST 2018.
  - 2020 → VEST 2020 (Taos also uses VEST 2020; 8 new near-empty units are held aside).
  - 2022 → the 2024 map, except Hidalgo, which uses VEST 2020.
  - 2024 = target (identity).
  - A map is usable if its units carry ≥ 99.9% of the county's votes and polygons with no reporting unit hold < 1% of its population.
- **Masked cells:** the SOS masks cells of 1–5 votes as `*`. For each contest × county × choice, the residual (official county total − visible precinct votes) is spread equally over the masked cells. That is 32,959 votes, never more than 5 per cell (`metadata/suppressed_fill.csv`).
- Absentee and early votes are already included in the SOS precinct rows, so no county-level allocation is needed.
- **Scripts** (`data/new_mexico/realign_2024/scripts/`): `03_prepare_geometry.R`, `04_assign_blocks.R`, `05_parse_returns.R`, `06_prepare_native.R`, `07_align.R`, `08_validate.R` and `09_build_datasets.R` (`run_all.R`). `10_bbmm_input.R` writes the fit input. Crosswalks: `crosswalks/nm_<vintage>_to_2024.csv`, `crosswalks/unit_groups.csv`.
- **Rounding:** `integer_votes` is a largest-remainder rendering within contest × choice, which preserves totals. The fit input uses the integer columns of `output/final_datasets/nm_combined.csv`.

## Summary statistics from alignment

From the README and `metadata/validation_summary.csv`:

| Check | Result |
|---|---|
| Statewide official vs native precinct rows, 107 contest × choice | 0 differ |
| Certified federal figures (14) vs official export | all exact |
| County official vs native rows, 3,531 cells | 0 differ |
| Conservation: aligned = official − held | exact (max 7e-10); max held share 0.2814% |
| Identity on the 2024 map (2022/2024 contests), 80,109 cells | exact |
| Populated 2024 precincts with zero votes in a contest | 9 cells, all `NM_023_0003` (Hidalgo 3) |

- **Held aside:** 63 votes in all (0.0002% of all votes), the 2020 Taos masked cells. The Dem/Rep and Yes/No columns lose at most 0.002% (`metadata/unallocated_votes.csv`).
- 48 blocks (102 people) needed max-overlap assignment on the VEST 2016/2018 maps.
- Only 613 of 2,169 2024 precincts take a whole pre-2020 precinct.
- **Smoothness** (median absolute deviation of log turnout relative to 2024 President): 0.24 (2014), 0.15 (2016), 0.17 (2018), 0.09 (2020), 0.13 (2022), ≤ 0.05 (2024).

## What is in the model-ready files

- **Ballot measures (`votes.csv`):** 38 statewide measures:

  | Year | Amendments | Bonds |
  |---|---|---|
  | 2014 | 5 | A–C |
  | 2016 | 1 | A–D |
  | 2018 | 2 | A–D |
  | 2020 | 2 | A–C |
  | 2022 | 3 | 1–3 |
  | 2024 | 4 | 1–4 |

  `success` = Yes (bond "For" = yes), `n` = Yes + No. None dropped.
  - The README's header says "35 ballot measures" and "10 national contests", but its own table and its BBMM section give 38 measures and 7 federal races. The bundle has 38 and 7.
- **Federal races (`partisan.csv`):** President 2016, 2020, 2024; US Senate 2014, 2018, 2020, 2024 (none in 2016 or 2022). Democratic and Republican nominees only. The atlas fit for New Mexico includes these 7 races, alongside the 38 measures.
- **Units excluded:** none. 51 precinct-contest cells with no two-option votes are NA (`NM_023_0003` Hidalgo 3, `NM_043_0051` Sandoval 51).

## Other datasets

- **Local measures are not downloaded at precinct level.** The SOS site carries county, municipal, college-district and soil-and-water questions (`type=CTY|MUX|CLX|SWX`), e.g. Bernalillo County bonds, Albuquerque charter amendments and AMAFCA flood bonds. The README says these were not downloaded or included.
- `data/new_mexico/realign_2024/raw/sos/<eid>/cty_all.csv` (eids 2, 84, 2698, 2782, 2838, 2882): the SOS "CTY" CSV export. It holds county-type races, both county ballot questions and bonds and county offices, as totals per race × candidate/response with no precinct breakdown. Rows / distinct races: 2014 321/198, 2016 258/168, 2018 278/186, 2020 224/153, 2022 283/192, 2024 36/18. **County level only; not on the unit map.**
- `data/new_mexico/realign_2024/raw/openelections/` holds OpenElections precinct files for 2016, 2018, 2020, 2022 and 2024, and county files for 2016, 2022 and 2024. They contain candidate contests: President, US Senate, US House, statewide and legislative offices. The 2022/2024 files also have judicial retentions, and 2024 has the statewide amendments and bonds. Native precincts; not used by the build scripts.
- `data/new_mexico/realign_2024/raw/sos/<eid>/state_all.csv` is the SOS "STATE" CSV export (`resultsCSV.aspx?text=All&type=STATE`), with totals per race × candidate/response and no precinct breakdown. Rows / distinct races: 2014 781/479, 2016 507/334, 2018 590/388, 2020 693/407, 2022 602/400, 2024 152/76. It mixes statewide, judicial, county and municipal races and questions (e.g. AMAFCA, city affordable-housing bonds). The README warns that for 2024 it lacks the federal races and statewide measures. **Aggregate only; not on the unit map.**

## Known issues

- Same precinct numbers ≠ same lines across eras: VEST 2016/2018 (1,492 precincts) → VEST 2020 (1,917) → 2024 (2,169).
- 2014 amendment 1 won a majority but **failed** (an elective-franchise amendment needs 3/4 statewide and 2/3 in every county). `passed` is hard-coded FALSE in `nm_column_key.csv`.
- Masked `*` cells must not be read as zero or missing.
- The FED page does not list the 2024 Senate race; it is on the SW page.
- Ballot wording on the SOS site truncates at ~500 characters (`wording_truncated`).
- CLAUDE.md: the NM atlas fit includes federal races. Bloc names are drafts.
