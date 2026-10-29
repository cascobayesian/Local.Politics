# Washington (statewide): how the model-ready data were made

| | |
|---|---|
| Unit | Precinct, Washington Secretary of State (SOS) 2024 general-election map, consolidated layer (`Statewide_Precincts_2024General_OK_Consol`, 7,932 precincts) |
| Units in the bundle | 7,847 (85 precincts with no ballots dropped); 7,846 of them have ballot-measure rows |
| Years | November generals 2012–2024 (no 2023: no statewide measure or federal race) |
| Ballot measures | 73 (initiatives, referenda, constitutional amendments, advisory votes) |
| Federal contests | 9 (President 2012, 2016, 2020, 2024; US Senate 2012, 2016, 2018, 2022, 2024) |

Bundle: `output/atlas/overview/bundles/wa/` (built by `code/atlas/overview/01_bundles.R` from the fit input `data/bbmm_benchmarks/washington_2024align.rds`). Build folder: `data/seattle/wa/` (README: `data/seattle/wa/README.md`).

## Raw data

Ballot measures and federal races come from the same sources:

- **WA SOS precinct exports**, `results.vote.wa.gov/results/YYYYMMDD/export.html` → `*_AllStatePrecincts*.csv`. Used for every county except King, every year except 2019. Files: `data/seattle/wa/raw/state_results/` (also the `AllCounties`, `AllState` and `Measures` files of each election). The SOS precinct export starts with the August 2012 primary; earlier years are county-level only.
- **OpenElections** `openelections-data-wa/2019/20191105__wa__general__precinct.csv` for 2019 (SOS published no 2019 precinct export): `data/seattle/wa/raw/openelections/`.
- **King County Elections final precinct reports**, every year: `data/seattle/wa/raw/king/` (2012–2014 from data.kingcounty.gov (Socrata); 2015–2022 copies of the files in `data/seattle/`; 2024 the county's `final-results-report.csv`, saved as `king_202411_final.csv`).
- **WA SOS `AllCounties` exports** as county control totals: `data/seattle/wa/native_csv/county_controls.csv`.

Format: CSV. Parsed, unallocated precinct returns: `data/seattle/wa/native_csv/all_votes.csv` (the 82 contests only). Parser: `data/seattle/wa/scripts/01_parse_returns.py`.

## Shapefiles

- Source: WA SOS precinct shapefiles (sos.wa.gov/node/177), one statewide layer per year 2012–2024 (no statewide 2015 layer), zips and extracted copies in `data/seattle/wa/raw/shapefiles/` (download URLs in `zip_urls.txt`).
- Target (the units): SOS 2024 general, consolidated to match how results were reported, 7,932 precincts. Project file: `data/seattle/wa/geometry/target_2024/wa_precincts_2024.shp` (EPSG:5070), joined on `join_id` = SOS `St_Code` (e.g. `AD00000111`). Non-spatial index with 2020 population: `data/seattle/wa/geometry/target_2024_index.csv`.
- Population weights: Census TIGER/Line 2020 blocks `tl_2020_53_tabblock20` (158,093 blocks, 7,705,281 residents), `data/seattle/wa/raw/blocks2020/`.

## Alignment across years

- **Method:** the NYC 2020-block-population crosswalk. Each 2020 block's internal point is assigned to a source polygon and to a 2024 polygon within its own county (fallbacks: greatest overlap, then nearest; nearest beyond 100 m is flagged). Weight = population of the source/target pair ÷ population of the source polygon; zero-population source polygons use area overlap.
- **Which years moved:** 2012–2022 onto the 2024 map; 2024 is kept as reported (identity), except that King's `ELECTIONS OFFICE` votes are added to `KI00002582` by design.
- **Source map per county-year** (`scripts/03_match_ids.R`): every SOS layer 2012–2024 (plus King's own 2015 file) is scored by the share of votes whose reporting unit finds a polygon, by code and by name; the same-year layer is kept unless another covers ≥ 0.5 points more votes; `_Consol` preferred. 2015 uses the 2014 or 2016 layer per county. Choices and scores: `metadata/vintage_choice.csv`, `metadata/vintage_scores.csv`. Units with no polygon in their layer borrow the uniquely named polygon from the nearest other layer (e.g. Kitsap 2020 `166 CP9`, 5,148 votes).
- **Scripts** (`data/seattle/wa/scripts/`): `01_parse_returns.py` → `02_load_geometry.R` → `03_match_ids.R` → `04_build_crosswalks.R` (ported from `NYC/scripts/build_crosswalks.R`) → `05_align.py` → `06_validate.py`; `run_all.sh` runs all. `07_florida_style.R` writes the fit input.
- **Rounding:** fractional `estimated_votes` are rendered as `integer_votes` by largest remainder within county × contest × choice (preserves county totals). The fit input and bundle use these balanced integers. Crosswalks: `crosswalks/blocks_YYYY_to_2024.csv.gz`, `crosswalks/wa_YYYY_to_2024.csv`.

## Summary statistics from alignment

From `data/seattle/wa/README.md` and `metadata/`:

- **Conservation:** 7,644 county/contest/choice checks pass (allocated fractional and integer totals + unallocated = native), plus 3,198 paired-file total checks (`metadata/alignment_checks.csv`, `final_datasets/validation.json`).
- **Unallocated votes:** 173 of 207.9 million contest-votes (30 in 2012, 143 in 2017, King `RED 45-1112`), `metadata/unallocated_votes.csv`. Summing `metadata/alignment_summary.csv` gives 207,898,139 native vs 207,897,966 allocated.
- **Statewide totals vs SOS canvass:** 99.03–100% for every choice over 10,000 votes; the low end is entirely 2019 (`metadata/validation_statewide.csv`).
- **Votes missing from precinct files (privacy-suppressed precincts), share of certified vote:** 2012 0.09%, 2013 0.11%, 2014 0.09%, 2015 0.15%, 2016 0.08%, 2017 0.22%, 2018 0.09%, 2019 0.88%, 2020 0, 2021 0, 2022 0.02%, 2024 0.12% (`metadata/canvass_gap.csv`).
- **Code/name match:** a code-matched unit's name agrees with its polygon's in ≥ 96% of cases in every county-year.
- **Nearest-beyond-100 m block assignments:** 16 residents in 2012–2018, none after. Unreported-source-geometry overlap peaks in 2015 at 27,009 residents.
- **Continuity** (precinct correlation of Dem two-party share with Harris 2024, `metadata/validation_continuity.csv`): 2022 Senate 0.985, 2020 Pres 0.983, 2018 Senate 0.962, 2016 Pres 0.968, 2012 Pres 0.904.

## What is in the model-ready files

- **Ballot measures (`votes.csv`):** 73 measures, 2012–2024: advisory votes 1–40, 25 initiatives, referenda 74, 88, 90, and SJR 8200, 8210, 8212, 8221, 8223. `success` = Yes, **Approved** (referenda, constitutional amendments) or **Repealed** (advisory votes); `n` = the two-option total. None of the 73 is dropped. Clark County's 2013 local advisory votes 3–6, which reuse the statewide numbers, are excluded at the parse stage.
- **Year 2066:** `meta.json` gives `years: [2012, 2066]` and `votes.csv` carries `year = 2066` for `INITIATIVE_2066_2024`. This is a parsing bug in the bundle builder, not a data value. `year_of()` in `code/atlas/overview/01_bundles.R` takes the *first* match of `(19|20)\d\d` in the question id, and for `INITIATIVE_2066_2024` that is the initiative number 2066. The true year is 2024, and the model-ready files in this folder carry 2024 (`scripts/export_model_ready.R` corrects it). No other WA id is affected: the other initiative numbers (e.g. 2109, 2117, 2124) do not begin with 19 or 20.
- **Federal races (`partisan.csv`):** President 2012/16/20/24 and US Senate 2012/16/18/22/24; `dem` and `rep` are the Democratic and Republican two-party votes. The bundle keeps only President and US Senate contests in which each party has 5–95% of the statewide two-party vote (all 9 pass). Note that the atlas fit for Washington *includes* these 9 federal races, as well as the 73 measures.
- **Units excluded:** 85 precincts with no ballots (7,932 → 7,847). Bundle votes drop cells with `n = 0` or missing.

## Other datasets

- `data/seattle/YYYYMM.csv` (2015-04 to 2024-11; `202108.xlsx`, `202204.xlsx`): King County Elections precinct reports, every race on each ballot (candidates and measures, long form with `CounterType`), on each election's own King precincts. **Not aligned.** `data/seattle/202411.csv` holds only ~68% of the certified 2024 King vote.
- `data/seattle/SEA_2015_2024.csv` (built by `data/scripts/sea_15_24.R` from the files above): 42,831 rows, 64 measure × election combinations on 19 election dates, 2015–2024, 3,153 distinct precinct names. Columns: Precinct, Race, Approved, Registered Voters, Rejected, elec. Only measures counted as Approved/Rejected are kept. Covers King County propositions, Sound Transit Prop 1 (2016), city measures (Bellevue, Bothell, Duvall, Snoqualmie, Kirkland, Shoreline, Newcastle, Des Moines), school districts (Auburn, Enumclaw, Highline, Kent, Federal Way, Renton, Issaquah, Fife), fire, park, hospital and library districts, and the state measures SJR 8210, R-88, SJR 8200, ESJR 8212 and R-90. Native precincts; **not on the 2024 map**.
- `data/seattle/seattle_2015_2024_cleaned.csv` (built by `data/seattle/process.seattle.r`): wide Y/N, 2,500 precincts × 15 measures (measures < 40% missing, precincts ≤ 20% missing). Native precincts.
- `data/seattle/Voting_Districts_of_King_County___votdst_area.shp`: a King County voting-district shapefile (vintage not documented).
- `data/seattle/wa/raw/king/king_YYYY11.csv` (2012–2024): King final precinct reports, all races (e.g. 107 races in 2018). Native precincts.
- `data/seattle/wa/raw/state_results/*AllStatePrecincts*.csv`: SOS precinct exports for 2012–2024 (no 2019 file). Per the README they also contain US House, governor and local measures, which were not extracted. Native precincts.
- `data/seattle/wa/raw/openelections/20191105__wa__general__precinct.csv`: 2019, all contests in that file.
- The atlas "Seattle" bundle (`output/atlas/overview/bundles/seattle/`) is a cut-out of this statewide bundle, not a separate dataset.

## Known issues

- Earlier-year values are estimates from 2020 residential population, not voters or election-year population. Blocks are not split.
- Privacy-suppressed precincts (`NAME(*)`, all zeros) carry zero votes. County totals are not substituted. The 2024 precincts they feed are flagged `suppressed_source_precinct` in `final_datasets/precinct_coverage_flags.csv`.
- 2019 is the weakest year (OpenElections file appears to predate final certification in several small counties: Columbia 20% short, Wahkiakum 17%, Douglas 11%, Walla Walla 10%).
- `data/seattle/202411.csv` is not the final King count (CLAUDE.md, README).
- The SOS canvass omits write-ins before 2020; King reports them.
- Bundle year bug for `INITIATIVE_2066_2024` (above).
- CLAUDE.md: the WA atlas fit includes federal races, which flatters blocs in the overview figure's partisan panels. Bloc names are drafts.
