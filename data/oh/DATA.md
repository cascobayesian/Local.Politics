# Ohio: how the model-ready data were made

| | |
|---|---|
| Unit | Precinct, November 2024 map (NYT 2024 precinct layer tied to Ohio SOS precinct codes) |
| Units | 8,878 |
| Years | Ballot measures 2017–2025; federal races 2016–2024 |
| Ballot measures | 11 (`votes.csv`) |
| Federal contests | 7 (`partisan.csv`): President 2016, 2020, 2024; US Senate 2016, 2018, 2022, 2024 |

Bundle: `output/atlas/overview/bundles/oh/`. Build folder: `data/ohio/realign_2024/` (README there, built 2026-10-18).

## Raw data

Both the ballot measures and the federal races come from the same source.

- **Returns**: Ohio Secretary of State official-canvass precinct workbooks (`.xlsx`),
  `https://publicfiles.ohiosos.gov/election-results/past-elections/<year>/<election>/...`. The files are listed in the portal's `files-index.json`; the portal page is data.ohiosos.gov/portal/past-election-results. County-canvass workbooks are used for validation.
- For the 2018 general, the `_miami` (amended Miami County) versions are used.
- The site's Cloudflare check blocks scripts, so the workbooks were fetched in a browser and unpacked with `scripts/00_unpack_sos_bundle.py`.
- Project path: `data/ohio/realign_2024/raw/sos/files/<year>/<election>/...`. `manifest.csv` there records each file's portal path, size and SHA-256.
- Parsed native returns: `data/ohio/realign_2024/output/native/oh_native_long.csv.gz`.

## Shapefiles

- **2024 target**: NYT 2024 presidential precinct map for Ohio,
  `https://int.nyt.com/newsgraphics/elections/map-data/2024/national/OH-precincts-with-results.geojson.gz`
  (github.com/nytimes/presidential-precinct-map-2024). All 8,876 features are flagged `official_boundary`. Stored at `data/ohio/realign_2024/raw/nyt2024/`.
  - Two SOS precincts that are holes in the NYT layer (GAH 2-A, Franklin; RIVERSIDE-C, Montgomery) were rebuilt from their VEST 2020 polygons.
  - Target: `data/ohio/realign_2024/geometry/oh_precincts_target.gpkg` (EPSG:4269). The registry and bundle `units.gpkg` use the land-clipped `geometry/oh_precincts_target_land.gpkg` (built by `scripts/15_blocs_vs_race_density.R`).
- **Source maps**: VEST, Harvard Dataverse, doi:10.7910/DVN/NH5S2I (`oh_2016`), UBKYRU (`oh_2018`) and K7760H (`oh_2020`), in `raw/vest/`.
- **May 2025 only**: Cuyahoga BOE and Lucas County ArcGIS layers (downloaded 2026-10-18; URLs in the README), in `raw/county_gis/`.
- Blocks: TIGER 2020 `tl_2020_39_tabblock20` (276,428 blocks, 11,799,448 residents), in `raw/census_blocks/`.

## Alignment across years

Method: NYC 2020-block-population crosswalk. Elections from 2016G through 2023G and May 2025 were moved onto the November 2024 map; 2024G maps onto itself. Scripts in `data/ohio/realign_2024/scripts/` (run by `run_all.R`):

- `01_parse_returns.R`: Ohio reports absentee, early and provisional ballots inside the voter's precinct, so there are no county-level rows to allocate.
- `02_prepare_geometry.R`: attaches SOS codes to every map.
  - NYT polygons were matched to SOS precincts by name plus identical Harris/Trump votes (6,558), by a unique vote pair (2,306), by normalised name (10) or by vote pair with a name tie-break (2).
- `03_vintage_choice.R`: chooses a map per election × county. A unit matches a map on county + SOS code + normalised name. The map with the highest share of matched ballots wins.
- `04_assign_blocks.R`, `05_build_crosswalks.R`: blocks are assigned whole by internal point. `weight = pop(unit polygons ∩ 2024 precinct) / pop(unit polygons)`, and zero-population polygons use area.
  - Unit placement rules: exact → other_map_exact → name_only → stem_group → unallocated.
- `06_align.R`: integers are a **largest-remainder rounding within contest × choice** over all 8,878 precincts. Fractional values are in `output/final_datasets/oh_aligned_fractional_long.csv.gz`.
- `07_validate.R`: validation checks.
- `08_florida_style.R` builds the fit input `data/bbmm_benchmarks/ohio_2024align.rds` from the integer columns. `code/atlas/overview/01_bundles.R` reads that file.

Maps used per election (README):

| Election | Maps used | Placed exactly |
|---|---|---|
| 2016G | vest_2016 | 100% |
| 2017G and 2018P | mostly vest_2018 | 99.99% |
| 2018G | vest_2018 | 100% |
| 2020G | vest_2020 | 100% |
| 2022G, 2023S, 2023G | mostly nyt_2024 | 99.83–99.98% |
| 2024G | nyt_2024 | 100% |
| 2025P | nyt_2024 plus the Cuyahoga and Lucas 2025 layers | 99.61% |

## Summary statistics from alignment

From `data/ohio/realign_2024/README.md`. Detail in `metadata/placement_summary.csv`, `metadata/unallocated_votes.csv`, `metadata/validation.csv` and `metadata/validation_county.csv`.

- **Unallocated votes**: only May 2025. Eleven new precincts with no polygon hold 789 Yes+No votes (0.09%). Every other contest allocates 100% of its votes.
- **Share of reporting units moving whole into one 2024 precinct**: 81.2% (2016), 82.7% (2017–18), 84.1% (2020), 93.0% (2022), 99.4–99.9% (2023), 100% (2024), 95.9% (2025).
- **Validation, all passing with max diff 0**:
  - precinct sums equal the SOS Total row (92 of 92 rows);
  - statewide totals equal the county canvass (36 of 36);
  - nominee totals equal the certified totals (10 of 10);
  - every county × choice equals the canvass;
  - aligned + unallocated equals native;
  - in 2024, every precinct's aligned votes equal its own return.
- **Franklin County** native totals are within 4 votes of `data/Columbus/bbmm_statewide`.

## What is in the model-ready files

- **Ballot measures (11, success = Yes)**:
  - 2017: `2017_11_issue1` (Marsy's Law), `2017_11_issue2` (drug prices)
  - 2018: `2018_05_issue1` (congressional redistricting), `2018_11_issue1` (drug penalties)
  - 2022: `2022_11_issue1` (bail), `2022_11_issue2` (citizens-only voting)
  - 2023: `2023_08_issue1` (60% to amend), `2023_11_issue1` (reproductive freedom), `2023_11_issue2` (marijuana)
  - 2024–2025: `2024_11_issue1` (redistricting commission), `2025_05_issue2` (infrastructure bonds)
- **Dropped**: 2012G, 2014P and 2015G (6 issues, plus the 2012 President and Senate races). No statewide map before 2016 exists, and only 50–96% of ballots match a 2016 polygon. They are parsed but not aligned (`OH_SCOPE` can re-enable them).
- **Federal races (7, Dem v Rep nominees)**: President 2016, 2020, 2024; US Senate 2016, 2018, 2022, 2024.
- **Units excluded**: none of the 8,878. Cells with n = 0 are dropped from `votes.csv` (96 cells per the README).

## Other datasets

- **Ohio SOS local-issue summaries (not precinct level, not aligned)**: `data/ohio/realign_2024/raw/sos/files/`. Each workbook has one row per local question (levies, bonds, income taxes, liquor options), with subdivision type and name, purpose, millage, outcome, and Votes For / Against. There are no precinct breakdowns. Sheet sizes in rows × columns, including header rows:
  - `2014/Primary Election May 6, 2014/issues.xlsx` (616 × 23)
  - `2016/General Election November 8, 2016/issues.xlsx` (1,798 × 24)
  - `2018/Primary Election May 8, 2018/issues.xlsx` (482 × 25)
  - `2019/General Election November 5, 2019/issues.xlsx` (1,507 × 25)
  - `2022/General Election November 8, 2022/issues-2022-11-08_general.xlsx` (1,562 × 24)
  - `2023/General Election November 7, 2023/issues.xlsx` (1,755 × 25)
  - `2025/Primary+Special Election May 6, 2025/may-6-2025-qi-summary---post-election.xlsx` (496 × 25)
  - `2025/General Election November 4, 2025/november-4-2025-qi-summary---post-election-12.5.25.xlsx` (1,538 × 22)
- **Precinct-level county candidate races (raw, not aligned)**: `data/ohio/realign_2024/raw/sos/files/2018/General Election November 6, 2018/group2/2018-11-06_CountyResults[Pp]recinct[_miami].xlsx` and `.../2020/General Election November 3, 2020/group2/CountyRaceResultsByPrecinct.xlsx`. These cover county commissioner, executive, council, sheriff and judges, with one row per precinct on that year's own map (about 8,900 rows).
- **Pre-2016 statewide issues (parsed, not aligned)**: 2012G, 2014P and 2015G rows in `data/ohio/realign_2024/output/native/oh_native_long.csv.gz`. They are on their own precinct codes, not the 2024 map.
- **Franklin County / Columbus ward panel (different unit map)**: `data/Columbus/final/columbus_ward_ballot.csv`.
  - 159 Franklin County 2024 wards × 74 measures, March 2012 to May 2026: 17 Ohio statewide, 17 Franklin County, 35 City of Columbus, 4 Columbus City Schools and 1 Columbus Metropolitan Library.
  - Contest metadata: `columbus_ballot_columns.csv`. National races: `columbus_ward_national.csv`. Geometry: `columbus_wards_2024.gpkg`.
  - Built from Franklin County BOE precinct files with an **areal** crosswalk (`data/Columbus/README.md`). It is on wards, not on this precinct map.
  - The atlas `columbus` bundle uses only its 17 statewide issues. The 57 local measures are not in any bundle.

## Known issues

- SOS precinct codes are re-lettered when precincts are added, so matching uses code plus name within one election's map.
- NYT names differ from SOS names in about a quarter of precincts. Codes were attached through vote counts (`metadata/nyt2024_code_match.csv`).
- The plain 2018G precinct workbook is about 6,000 ballots short. The `_miami` versions are used.
- Cuyahoga and Lucas redrew in early 2025. In East Cleveland, 639 residents more than 100 m from an active polygon carry no weight; votes are not lost.
- Ohio precinct files omit write-ins, which leaves the Dem/Rep and Yes/No columns unaffected.
- Pre-2024 values are estimates on 2024 precincts.
- The atlas fit pools 7 partisan races with 11 issues (README caveat; CLAUDE.md).
