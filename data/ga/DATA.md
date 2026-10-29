# Georgia: how the model-ready data were made

| | |
|---|---|
| Unit | Reporting unit ("precinct") of the November 2024 general election, drawn from the Georgia Reapportionment Office 2024 precinct layer |
| Units | 2,687 in the bundle (2,690 target units; 3 with no ballots dropped) |
| Years | 2016–2024 (ballot measures and federal races) |
| Ballot measures | 21 (`votes.csv`) |
| Federal contests | 6 (`partisan.csv`): President 2016, 2020, 2024; US Senate 2016, 2020 (regular, first round), 2022 (first round) |

Bundle: `output/atlas/overview/bundles/ga/`. Build folder: `data/georgia/realign_2024/` (README there, built 2026-10-19).

## Raw data

The source differs by election. Ballot measures and federal races come from the same file in each election.

| Election | Source | Project path |
|---|---|---|
| 2016G | OpenElections `openelections-data-ga/2016/20161108__ga__general__<county>__precinct.csv` (159 files, built from SOS Clarity XML) | `data/georgia/realign_2024/raw/openelections/2016/` |
| 2018G | MEDSL `2018-elections-official/individual_states/2018-ga-precinct-general.zip` | `raw/medsl/` |
| 2020G | MEDSL `2020-elections-official/.../2020-ga-precinct-general.zip`, git commit `ad22f37` | `raw/medsl/` |
| 2021-01 runoffs | OpenElections `2021/20210105__ga__runoff.csv`; VEST `ga_2020` R21 columns for Camden, Chattooga, Grady and Greene | `raw/openelections/other/`, `raw/vest/ga_2020/` |
| 2022G and 2022-12 runoff | MEDSL `2022-elections-official/.../2022-ga-local-precinct-general.zip` | `raw/medsl/ga22_cleaned.csv` |
| 2024G | Georgia SOS Enhanced Voting API, `https://results.sos.ga.gov/results/public/api/elections/<county>/2024NovGen/data/ballot-item/<id>` (JSON), fetched by `scripts/00_download_ev.py` | `raw/ev/2024NovGen/` (`raw/ev/manifest.csv` has SHA-256) |
| Certified county totals, all elections (validation only) | same API, county pages | `raw/ev/<election>/<county>/county.json` |

All paths after the first are relative to `data/georgia/realign_2024/`. Clarity ENR returns HTTP 403, and Enhanced Voting has precinct detail only from 2024 (README). Parsed native returns are in `data/georgia/realign_2024/output/native/`.

## Shapefiles

- **2024 target**: Georgia Legislative & Congressional Reapportionment Office,
  `https://www.legis.ga.gov/api/document/docs/default-source/reapportionment-document-library/precincts/gaprec_2024-website-shapefile.zip`
  (2,724 features), stored at `raw/legis/gaprec_2024/`.
  - Polygons were tied to the 2,690 SOS reporting units by label and through the NYT 2024 map (`raw/nyt2024/GA-precincts-with-results.geojson.gz`), which was used only as a vote-matched bridge.
  - 25 units combine 2–4 legislative precincts.
  - Target: `geometry/ga_precincts_target.gpkg` (EPSG:4269). The registry and bundle use the land-clipped `geometry/ga_precincts_target_land.gpkg` (built by `scripts/14_blocs_vs_race_density.R`).
- **Source maps**:
  - VEST (Harvard Dataverse) for 2016, 2018 and 2020: doi:10.7910/DVN/NH5S2I (`ga_2016`), UBKYRU (`ga_2018`), K7760H (`ga_2020`), in `raw/vest/`.
  - Reapportionment Office 2022 layer, `.../ga-precincts2022-shape.zip` (2,721 features), in `raw/legis/gaprec_2022/`.
- Blocks: TIGER 2020 `tl_2020_13_tabblock20` (232,717 blocks, 10,711,908 residents).

## Alignment across years

Method: NYC 2020-block-population crosswalk. The 2016, 2018 and 2020 generals, the January 2021 runoffs, and the November and December 2022 elections were moved onto the 2024 reporting units; 2024 maps onto itself.

Scripts in `data/georgia/realign_2024/scripts/` (run by `run_all.R`):
- `01_parse_returns.py`, `01b_fill_runoff_from_vest.R`: Georgia reports all vote methods by precinct, so there are no county-level absentee units to allocate.
- `03_target_layer.R`: builds the target units.
- `04_match_units.R`: places units by identical vote vector, label, pair-sum, split, approximate vector or fuzzy label. The map placing the most ballots wins per election × county.
- `05_assign_blocks.R`, `06_align.R`: blocks are assigned whole by internal point. `weight = pop(unit polygons ∩ 2024 unit) / pop(unit polygons)`; zero-population polygons use area.
- `07_validate.R`: validation checks.

Maps used:

| Election | Map |
|---|---|
| 2016G | vest_2016 |
| 2018G | vest_2018 |
| 2020G and 2021R | vest_2020 |
| 2022G and 2022R | legis_2022 (one county on vest_2020 in 2022G) |

Rounding: integers are a **largest-remainder rounding within contest × choice** over all 2,690 units (`06_align.R`, helper in `00_common.R`). Fractional values are in `output/final_datasets/ga_aligned_fractional_long.csv.gz`.

The fit input `data/bbmm_benchmarks/georgia_2024align.rds` is built by `08_florida_style.R` from the integer columns. `code/atlas/overview/01_bundles.R` reads it.

## Summary statistics from alignment

From `data/georgia/realign_2024/README.md`. Detail in `metadata/validation.csv`, `validation_county.csv`, `placement_summary.csv`, `unallocated_votes.csv` and `vintage_scores.csv`.

- **Placement (share of ballots)**:
  - 2016G: vote_exact 97.96%, pair_sum 1.90%, split 0.09%, label 0.05%
  - 2018G: vote_exact 99.70%
  - 2020G: vote_exact 99.88%
  - 2021R: 99.89%
  - 2022G: label 99.95%
  - 2022R: label 99.96%
- **Units moving whole into one 2024 unit**: 78.4% (2016), 79.5% (2018), 81.7% (2020/21), 91.8–91.9% (2022), 100% (2024).
- **Unallocated**: 0.00% of every contest, with two exceptions:
  - Emanuel County's three 2022 measures (21,290 votes held, ≤ 0.17% of a measure), because they are absent from the SOS certified results;
  - one 1-ballot unit in each of the 2022 elections.
- **Validation**:
  - Native county totals equal the SOS certified totals exactly in 24 of 31 contests. The exceptions are Emanuel 2022, and Fulton 2024, where the API precinct breakdown is 4–13 votes short per choice.
  - Aligned + unallocated = native for all 31 contests, also by county (max 8e-6).
  - In 2024, every unit reproduces its return (26,908 cells).
  - Dem share correlation: r = 0.990 (2016 vs 2020 Pres) and 0.993 (2020 vs 2024 Pres).

## What is in the model-ready files

- **Ballot measures (21, success = Yes)**:
  - 2016: amendments 1–4
  - 2018: amendments 1–5 and referendums A and B
  - 2020: amendments 1–2 and referendum A
  - 2022: amendments 1–2 and referendums A and B
  - 2024: amendments 1–2 and referendum A

  The keys are `<year>_11_amend<n>` and `<year>_11_ref<A|B>`.
- **Excluded measures**: party-only primary ballot questions. No statewide measures were on primary or special ballots, or in 2019, 2021, 2023 or 2025.
- **Federal races in the bundle (6)**: President 2016, 2020, 2024; US Senate 2016, 2020 (Ossoff v Perdue, first round) and 2022 (Warnock v Walker, first round).
- **In the atlas fit but not the bundle**: the 2021-01 Senate runoff, the 2021-01 special Senate runoff (Warnock v Loeffler) and the 2022-12 Senate runoff. `01_bundles.R` excludes runoffs.
- **Not in either**: the November 2020 special Senate first round (20 candidates). It is only in `output/aligned_2024/by_contest/2020_11_senate_special.csv`.
- **2020 President** is the count certified on 20 Nov 2020, not the 7 Dec recount.
- **Units excluded**:
  - Cherokee `269-Waleska` (no ballots, no polygon), so the target has 2,690 units.
  - 3 further units with no ballots are not in the fit, giving 2,687.
  - Emanuel's units are 0/0 for 2022 amendments 1–2 and referendum B, so those rows are absent from `votes.csv`.

## Other datasets

- **2022 county and municipal ballot questions, precinct level (raw, not aligned)**: `data/georgia/realign_2024/raw/medsl/ga22_cleaned.csv` (MEDSL 2022 "local precinct general").
  - Besides the statewide measures, it holds Yes/No rows for county and city questions: SPLOST, ESPLOST and TSPLOST sales taxes, homestead exemptions, Sunday and package alcohol sales, Roswell GO bonds, Mableton cityhood, Stockbridge annexation, and redevelopment powers.
  - Excluding office names containing "CONSTITUTIONAL AMENDMENT" or "STATEWIDE", that is 121 county × question pairs, 20,170 rows, 73 counties and 1,469 precinct labels.
  - The questions are on 2022 precinct labels, not the 2024 map.
- **2016 local Yes/No rows (raw, not aligned)**: `data/georgia/realign_2024/raw/openelections/2016/*.csv`.
  - Yes/No rows under non-statewide office names (e.g. "Advisory Referendum", "Special"): 101 county × office pairs, 4,672 rows, 70 counties.
  - Not inspected further. Some of these may be candidate specials.
- **2024 local questions, county totals only**: `data/georgia/realign_2024/raw/ev/2024NovGen/<county>/county.json` lists 92 non-statewide Yes/No items (57 counties) with county summary results, such as county ad valorem taxes and homestead exemptions. Precinct detail was downloaded only for statewide items.
- **Raw candidate contests**: `raw/openelections/other/` holds 2020G, 2021 runoff, 2022G, 2022 runoff and 2024G precinct files covering state legislature, US House, PSC and DA; the 2022 file also has the statewide constitutional officers. MEDSL 2018 and 2020 contain only statewide measures among their Yes/No rows. None of these are aligned.
- Checked: `data/georgia/` contains only `realign_2024/`. The atlas `atlanta` bundle is a cut-out of this one.

## Known issues

- Results labels are free text set by each county. Joins across years use vote links (`crosswalks/unit_links_all.csv.gz`), never labels alone.
- The NYT 2024 Georgia layer permutes some labels, so it is used only through votes.
- 27 legis_2024 rows carry their identity only in `DISTRICT`.
- Some counties report several precincts together (e.g. Muscogee: 25 units for 52 precincts).
- Fulton 2024 precinct cells are 4–13 votes short of the county totals.
- The atlas fit has K = 13, reached by only 2 of 10 starts, so it is possibly non-unique.
- The fit pools 9 partisan contests, including the runoffs (README; CLAUDE.md).
- Pre-2024 values are estimates on 2024 units.
- 2016 relies on VEST-merged units for 2% of ballots.
