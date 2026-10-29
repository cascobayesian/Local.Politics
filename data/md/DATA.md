# Maryland: how the model-ready data were made

| | |
|---|---|
| Unit | Precinct. The 2024 general-election map was assembled county by county from Maryland Dept. of Planning (MDP) layers: 2,019 precincts |
| Units in the bundle | 1,969 (50 "ghost" precincts with no ballots dropped) |
| Years | November generals 2012, 2014, 2016, 2018, 2020, 2022, 2024 |
| Ballot measures | 20 statewide questions |
| Federal contests | 9 (President 2012, 2016, 2020, 2024; US Senate 2012, 2016, 2018, 2022, 2024) |

Bundle: `output/atlas/overview/bundles/md/`, built by `code/atlas/overview/01_bundles.R` from `data/bbmm_benchmarks/maryland_2024align.rds`. Build folder: `data/maryland/realign_2024/` (README: `data/maryland/realign_2024/README.md`).

## Raw data

Ballot measures and federal races come from the same source:

- **Maryland State Board of Elections (SBE)**, `https://elections.maryland.gov/elections/archive/<year>/election_data/`. The `archive/` path is required; the URL without it returns a 404 page with HTTP 200. Format: CSV.
  - **Precinct returns:** `All_By_Precinct_<y>_General.csv` and `All_Questions_Precinct_<y>.csv` (2012–2020), and `GG22_AllPrecincts*.csv` and `PG24_AllPrecincts*.csv` (2022, 2024). Files are in `data/maryland/realign_2024/raw/sbe/`.
  - **Official county totals** (certified canvass by county and vote type): `<County>_County_<y>_General.csv`, `<County>_Questions_County_<y>.csv`, and the GG22/PG24 county files, in `raw/sbe/county/`.
  - **Independent statewide check:** the SBE congressional-district breakdown files.
  - **Ballot wording:** `raw/sbe/ballot_questions/`.
- In 2012–2018 the SBE precinct files contain only election-day votes. Early, absentee and provisional votes are county totals only.
- Downloads: `scripts/01_download.py`. URLs and SHA-256 prefixes are in `metadata/download_log.tsv`.

## Shapefiles

- **Target (the units):** no statewide layer of the 5 November 2024 precincts is published (the Redistricting Data Hub file needs a login). The target is assembled by `scripts/06_build_target.R`:
  - MDP 2025 for 21 counties.
  - MDP 2022 for Baltimore County and Wicomico.
  - MDP 2026 for Howard.
  - Repairs for Calvert (`03-002`/`03-008` alias) and Harford (06-004/06-005 rebuilt from the 2022 layer).
  - Result: 2,019 precincts. All 1,958 reporting units of 2024 match a polygon; 61 polygons had no 2024 returns.
  - Project file: `data/maryland/realign_2024/geometry/md_precincts_target.gpkg` (EPSG:26985; NAD83 copy `md_precincts_target_4269.shp`), with `join_id` = `MD_<county FIPS>_<DD-PPP>`. The atlas/bundle geometry is the land-only version, `geometry/md_precincts_target_land.gpkg`.
- **MDP sources:**
  - **2022:** "Maryland Election Boundaries – Precincts 2022" (ArcGIS item e2d183719fe345c8abfffc9cc4196390), recovered from the Wayback Machine because the live service now holds the 2026 layer.
  - **2025:** `services.arcgis.com/njFNhDsUCentVYJW/ArcGIS/rest/services/Precincts_2025/FeatureServer/0`.
  - **2026:** `mdgeodata.md.gov/imap/rest/services/Boundaries/MD_ElectionBoundaries/FeatureServer/2`.
  - Files are in `raw/mdp/`.
- **Source maps for earlier years:**
  - VEST 2016, 2018 and 2020 (Harvard Dataverse doi:10.7910/DVN/NH5S2I, UBKYRU, K7760H), in `raw/vest/`.
  - TIGER/Line 2010 and 2020 VTDs, in `raw/census_vtd/`.
  - Cleaned copies are in `geometry/vintages/`.
- **Weights:** TIGER/Line 2020 blocks `tl_2020_24_tabblock20` (83,827 blocks, 6,177,224 residents), in `raw/census_blocks/`.

## Alignment across years

1. **County-level votes, 2012–2018.** Early, absentee and provisional county totals (36–40% of all votes in 2016 and 2018) are spread within contest × county × choice in proportion to election-day votes. If a choice had none, the precinct's total election-day vote is used. `estimated_from_county_level` keeps this component. 2020–2024 report every vote type by precinct.
2. **Map per election × county** (`scripts/07_crosswalks.R`, `choose_vintage()` in `00_common.R`). Units are matched by exact `DDD-PPP` key against eight vintages (TIGER 2010, VEST 2016/2018/2020, TIGER 2020, MDP 2022/2025/2026) and the target. The rules, in order:
   1. Highest share of votes matched.
   2. Turnout fit: median |log(vote share ÷ 2020-population share)|, within 0.01 of the best.
   3. Fewest polygons with no returns.
   4. Nearest date.

   | Election | Maps used |
   |---|---|
   | 2012 | TIGER 2010 VTDs (12 counties), VEST 2016 (7), VEST 2018 (2), TIGER 2020 (3) |
   | 2014 | VEST 2016 (18), VEST 2018 (2), TIGER 2020 (3), TIGER 2010 (1) |
   | 2016 | VEST 2016 (21), TIGER 2020 (3) |
   | 2018 | VEST 2018 (20), TIGER 2020 (3), VEST 2016 (1) |
   | 2020 | VEST 2020 (22), TIGER 2020 (2) |
   | 2022 | MDP 2022 (23), target (Prince George's) |
   | 2024 | target (identity) |

   Every election 2012–2022 is moved onto the 2024 map. Fit statistics: `metadata/vintage_fit_all.csv`; label matches: `metadata/vintage_label_match.csv`.
3. **Weights (NYC method).** Each 2020 block is assigned whole, by internal point, within its county. Fallbacks: largest overlap, then nearest within 100 m. Weight = pop(source ∩ target) / pop(source). Source polygons with no residents (7–49 per vintage) use overlap area. Crosswalks: `crosswalks/md_<vintage>_to_2024.csv`, `crosswalks/unit_map.csv`.
4. **Precincts with no polygon.** If unmatched precincts hold > 0.5% of a county's votes, they are reallocated within the county in proportion to matched precincts' votes (`metadata/reallocated_units.csv`: Frederick 2012/2014; Washington 2012 and 2014). Otherwise they are held (`metadata/unallocated_votes.csv`).

- **Scripts** (`data/maryland/realign_2024/scripts/`): `02_parse_returns.R`, `03_prepare_geometry.R`, `04_vintage_audit.R`, `05_assign_blocks.R`, `06_build_target.R`, `07_crosswalks.R`, `08_align.R` and `09_validate.R`, run by `run_all.R`. `10_bbmm_inputs.R` writes the fit input.
- **Rounding:** largest remainder within contest × county × choice, which preserves county and state totals. The fit input uses these balanced integers.

## Summary statistics from alignment

From the README and `metadata/validation_summary.csv`:

| Check | Rows | Failed | Max diff |
|---|---|---|---|
| Native = SBE official county totals (contest × county × choice) | 5,784 | 2 | 2 votes (write-in rows) |
| Same, Dem/Rep nominees and Yes/No only | 1,392 | 0 | 0 |
| Native statewide = official statewide | 241 | 2 | 2 |
| Native statewide = SBE congressional-district files | 241 | 0 | 0 |
| Aligned = native − held, fractional / integer | 5,784 | 0 | 3.5e-10 / 0 |
| Final pair columns = long-file integers | 58 | 0 | 0 |

- **Unallocated:** the largest share for any contest is 0.054% (2012). 2014–2020 and 2024 are fully allocated. 2022 holds 55–64 votes per contest (Montgomery 09-047), ≤ 0.0035%. 12,637 votes are held in total.
- **Reallocated within county:** 2.0% (Frederick) and 3.1% (Washington) of county votes in 2012; 2% of Frederick and Washington in 2014.
- Allocated precinct totals agree with VEST's own precinct totals to within 0.03–0.09% of votes; 2020 is exact (`metadata/validation_vest.csv`).
- Certified statewide figures reproduce exactly, e.g. Harris 1,902,577 / Trump 1,035,550 (2024).
- **Target layer:** 61 ghost polygons (576 residents). County turnout fit 0.04–0.36 (`metadata/target_fit_final.csv`).

## What is in the model-ready files

- **Ballot measures (`votes.csv`):** all 20 statewide questions on general ballots 2012–2024: 2012 Q1–Q7, 2014 Q1–Q2, 2016 Q1, 2018 Q1–Q2, 2020 Q1–Q2, 2022 Q1–Q5, 2024 Q1. Maryland has no statewide questions in primaries or odd years. `success` = For (Yes), `n` = For + Against. None dropped.
- **Federal races (`partisan.csv`):** President 2012/16/20/24 and US Senate 2012/16/18/22/24 (no Senate race in 2014 or 2020). Democratic and Republican nominees only. Nominees are picked by name, because write-ins carry party codes. The atlas fit for Maryland includes these 9 races alongside the 20 questions.
- **Units excluded:** 50 ghost precincts with no ballots in any contest (2,019 → 1,969). 0/0 cells are NA (1.96% of cells; about 99 precincts in each 2012 contest).

## Other datasets

- **Local ballot questions, precinct level, not aligned.** They are in the same SBE question files:
  - `data/maryland/realign_2024/raw/sbe/<y>_All_Questions_Precinct_<y>.csv` (2012–2020), `GG22_AllPrecinctsQuestions.csv` and `PG24_AllPrecinctsQuestions.csv`.
  - Use the rows with "How it Runs?" = `County`; 2022 also has one `Ed` question. These are county charter and bond questions and Baltimore City questions.
  - County-level early/absentee/provisional totals for 2012–2018 are in `raw/sbe/county/<y>_<County>_Questions_County_<y>.csv`. As with the statewide questions, 2012–2018 precinct rows are election-day only.
  - Inventory: `data/maryland/realign_2024/metadata/local_questions_inventory.csv`, 417 question × county rows (416 `County`, 1 `Ed`): 2012 67, 2014 71, 2016 65, 2018 49, 2020 49, 2022 65, 2024 51.
  - Baltimore City alone has 8–13 a year (13, 10, 10, 9, 11, 11, 8 for 2012–2024).
  - These are on native SBE precincts, **not on the 2024 unit map**. The README notes the same allocation would apply.
- **Candidate contests, precinct level, not aligned:** `raw/sbe/<y>_All_By_Precinct_<y>_General.csv` (2012–2020), `GG22_AllPrecincts.csv` and `PG24_AllPrecincts.csv`. Every office on the general ballot (e.g. 2018: Governor, Comptroller, Attorney General, US House, State Senate, House of Delegates, County Executive/Council/Commissioners, Board of Education, Sheriff, State's Attorney, judges, Mayor/Council of Cumberland). Native precincts; 2012–2018 election-day only.

## Known issues

- 2012–2018 precinct shares include county-level early/absentee/provisional votes spread by election-day share (36–40% of votes in 2016/2018). This pulls precincts toward their county mean.
- 2012 is the coarsest year: its precincts predate renumbering in several counties, so 2010 VTDs and later VEST maps stand in.
- The 2024 target is a reconstruction. Harford reused labels between 2022 and 2025; Calvert has the `03-002`/`03-008` swap; Howard's 2025 entry is its 2022 map. The MDP 2022 layer is gone from the live service.
- `#NULL#` vote cells (2014–2018) are read as 0.
- Many questions are near-consensus (85–93% For).
- CLAUDE.md: the MD atlas fit includes federal races. CLAUDE.md's table says 2,019 units (the map); the fit and bundle use 1,969. Bloc names are drafts.
