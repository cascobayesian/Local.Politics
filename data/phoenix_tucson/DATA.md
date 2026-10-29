# Phoenix and Tucson (Maricopa and Pima Counties): how the model-ready data were made

| | |
|---|---|
| Unit type and map | Precinct, 2024 vintage. Maricopa uses the county's official 2022–2025 layer (935 precincts); Pima uses the county's official layer after the 2023 consolidation (265) |
| Units | 1,200 on the map (935 Maricopa, 265 Pima); 1,177 in the bundle (23 zero-population precincts carry no votes) |
| Years covered | Ballot measures: Nov 2012 to Nov 2024 general elections. Federal races: 2012–2024 |
| Ballot measures | 44 statewide propositions |
| Federal contests | 10: President 2012, 2016, 2020, 2024; US Senate 2012, 2016, 2018, 2020, 2022, 2024 |

The two counties are fitted jointly as one place. Bundle: `output/atlas/overview/bundles/phoenix_tucson/`,
built by `code/atlas/overview/01_bundles.R` from `data/az/final_maricopa_pima/data/` (`az_ballot.csv`,
`az_ballot_column_key.csv`, `az_national.csv`). The registry entry is in `code/atlas/build_panels.R`.

READMEs:
- `data/az/README.md`: raw sources and precinct change.
- `data/az/wide/README.md`: wide tables and the 2024 panel.
- `data/az/final_maricopa_pima/README.txt`: fit inputs.

## Raw data

Ballot measures and federal races come from the same county precinct files.

- **2012–2016 generals:** AZ Secretary of State county precinct files, fetched via the Wayback
  Machine because azsos.gov returns 403 to scripts.
  - Files: `data/az/raw/sos/<year>/`; manifest `raw/sos/manifest_2010_2018.csv`.
  - Parsed to `data/az/sos_precinct_long.csv` by `code/az/parse_sos_county.py`.
- **2018–2024 generals:** OpenElections county precinct files,
  `data/az/raw/openelections/<year>/<date>__az__general__{maricopa,pima}__precinct.csv`.
  - The 2018 Maricopa and Pima SOS captures are truncated, so OpenElections is used.
- **2024 Maricopa:** the county's own export,
  `data/az/raw/oe_sources/2024/2024 Maricopa County, AZ precinct-level results.txt`. The
  OpenElections file dropped the propositions.
- **Gap-fill:** `data/az/wide/gapfill/<year>/<County>.csv` (2020 and 2022 props parsed from county
  canvass PDFs) applies to other counties. In 2022, Maricopa props are from OpenElections and Pima
  props are from gap-fill (the README table lists "OpenElections (Maricopa) + gapfill (the other
  14)").
- **Tidy and wide builds:** `code/az/build_wide_long.py` and `build_wide.py` write
  `data/az/wide/az_precinct_referendums.csv` and `az_precinct_national.csv`. One row is a precinct
  as it existed in that election.

## Shapefiles

- **2024 target.** Catalogued in `data/az/geo/manifest.csv`:
  - Maricopa: county Elections layer `Maricopa_County_Voting_Precincts_(2022-)`, at
    `https://services.arcgis.com/ykpntM6e3tHvzKRJ/arcgis/rest/services/Maricopa_County_Voting_Precincts_(2022-)/FeatureServer/0`
    (vintage 2022–2025).
  - Pima: Pima County GIS Open Data DISTVOTE, at
    `https://gisdata.pima.gov/arcgis1/rest/services/GISOpenData/Boundaries/MapServer/8` (265
    precincts after the consolidation approved 9/19/2023).
- **Files:** `data/az/wide/geo/`, frozen in `data/az/final_maricopa_pima/raw_data/precincts_2024/`;
  model file `data/az/final_maricopa_pima/data/az_precincts_2024.gpkg` (join key `join_id`, for
  example `2024|Maricopa|0001 ACACIA`).
- **Source vintages, one shapefile per election:** `data/az/wide/geo/az_precincts_<election>.shp`.
  - Maricopa official layers 2012–2017, 2018–2021 and 2022–2025.
  - Pima layers 2012 (CEN2010V) and 2020.
  - VEST 2016/2018 and others.
  - All are listed in `geo/manifest.csv`.

## Alignment across years

- **Method: block-population crosswalk with whole blocks assigned by interior point**
  (`code/az/build_panel_crosswalk.R`, then `code/az/build_panel.py`).
  - Each census block's interior point is placed in one precinct of the source election and one
    2024 precinct, within its own county.
  - A source precinct's votes are split in proportion to the population of the blocks they share.
    Housing units are used where a precinct has no population, and area where it has neither.
  - 2012–2018 elections use 2010 blocks (`POP10`); 2020–2024 use 2020 blocks (`POP20`).
- **Moved:** every election from 2012 to 2022 is moved onto the 2024 precincts. 2024 is copied, not
  reallocated. 2010 is excluded.
- **Output:** `data/az/wide/panel_2024/az_panel2024_{referendums,national,match}.csv`, which is
  statewide (1,735 precincts, 46 props). The Maricopa and Pima rows are frozen in
  `data/az/final_maricopa_pima/raw_data/`.
- **Rounding:** the panel is fractional (two decimals).
  `data/az/final_maricopa_pima/scripts/01_prepare_inputs.R` rounds each Yes/No and D/R cell to the
  nearest integer with plain `round()`, not largest remainder.

## Summary statistics from alignment

These are statewide figures from `data/az/wide/README.md`; no Maricopa/Pima-only figures were
recorded.

- Each panel column sums to its source total to within 0.15 votes.
- `data/az/wide/panel_2024/panel_summary.csv` gives votes not carried because the source precinct
  has no boundary:
  - 0 for 2016–2024
  - 0.6% for 2012 and 0.4% for 2014
  - 99% for the 2016 special, which is excluded
- `az_panel2024_match.csv`: population IoU between each 2024 precinct and its largest contributing
  source precinct.
  - 2012–2020: median 1.0; 60–66% of precincts at 0.95 or above, and 18–22% below 0.5.
  - 2022: 95% at 0.95 or above, and 3% below 0.5.
  - Per-precinct values for this place are in
    `data/az/final_maricopa_pima/r_outputs/panel_match_quality.csv`.
- All 909 Maricopa precincts with population come back identical from 2022 (same layer).
- The correlation of Democratic share with Harris 2024 falls with time: 0.99 for 2022, 0.98 for
  2020, 0.95 for 2016–2018, and 0.90 for 2012.
- `data/az/wide/official_check.csv`: 127 of 139 statewide measures match the SOS canvass to the
  vote. The 2024 mismatches (President, Senate, CD7 and Props 133, 313 and 315; 3 to 61 votes) are
  attributed to small errors in the Navajo, Santa Cruz and Pima OpenElections files.
- `data/az/wide/geo_vote_check.csv`: 3,265 of 3,265 boundary matches agree with layer vote totals.
- `data/az/final_maricopa_pima/r_outputs/workflow_validation.csv`: 98 checks, all passing.

## What is in the model-ready files

- **Ballot measures:** 44 statewide general-election propositions. success = Yes, n = Yes + No.
  - Ids `<year>_Prop<n>`. All are statewide; there are no local measures in the bundle.
  - 2012 (9): 114–121 and 204
  - 2014 (3): 122, 303, 304
  - 2016 (2): 205, 206
  - 2018 (5): 125–127, 305, 306
  - 2020 (2): 207, 208
  - 2022 (10): 128–132, 209, 211, 308–310
  - 2024 (13): 133–140 and 311–315
- **Dropped:** the May 2016 special (Props 123 and 124). Those counties voted in consolidated units
  with no boundaries.
- **Federal races:** the 10 listed above, Democratic vs Republican nominees. US House is omitted.
- **Units excluded:** 23 zero-population 2024 precincts with no votes. Per-question coverage is
  1,162–1,173 units, because some 2024 precincts receive no votes for older elections.

## Other datasets

None of these are aligned to the 2024 map.

- **Local (county, city, school, special-district) questions and candidate contests, raw:**
  - `data/az/sos_precinct_long.csv` (2010–2016, all 15 counties): Maricopa and Pima rows include
    local questions. Proposition- or question-like contests number 69 in 2010, 78 in 2012, 57 in
    2014 and 51 in 2016, for example "CITY OF AVONDALE PROPOSITION 406" and "CITY OF MESA -
    QUESTION 1". They sit alongside every candidate contest. Native precincts.
  - `data/az/raw/openelections/{2016,2018,2020,2022}/..._maricopa__precinct.csv` and
    `{2016,2018,2020,2024}/..._pima__precinct.csv`: county files with local questions.
    - Maricopa: 37 (2016), 36 (2018), 47 (2020) and 38 (2022) non-statewide question contests,
      such as school-district questions and city propositions ("Avondale-PROPOSITION 443").
    - Pima: 12, 11, 6 and 11. These are county or district "PROPOSITION 4xx", such as Prop 481
      (Pima Community College).
    - All candidate contests, native precincts.
    - The 2022 Pima and 2024 Maricopa OpenElections files have no questions.
  - `data/az/raw/oe_sources/2024/2024 Maricopa County, AZ precinct-level results.txt`: 265 contests,
    121 of type "Measure" (13 statewide, the rest local, such as "Buckeye-PROPOSITION 494"). On
    the 2024 precincts, so the same map.
  - `data/az/raw/oe_sources/2024/2024 Pima County, AZ precinct-level results.csv`: the county's own
    2024 export.
  - Counts are from a keyword scan of contest names done for this note. No project file tallies
    them.
- `data/az/wide/az_precinct_referendums.csv` / `az_precinct_national.csv` and `wide/by_election/`:
  - Statewide propositions 2010–2024, including the 2010 and 2016 specials.
  - US House by district, in addition to President and Senate.
  - All 15 counties, each election on its own precincts.
- `data/az/wide/panel_2024/`: the statewide 2024-precinct panel (1,735 precincts). It includes
  Props 123 and 124 (2016 special) and US House columns.

## Known issues

- Votes before 2024 are block-population estimates. Rows with a low match score are blends of
  several older precincts.
- 2010 → 2012 and 2020 → 2022 are major re-precinctings. Pima consolidated from 278 to 265 between
  2022 and 2024.
- Maricopa numbers precincts alphabetically and renumbers at every redraw, so match on name, not
  number (`data/az/README.md`).
- Small 2024 OpenElections errors (3–61 votes statewide on President, Senate, and Props 133, 313
  and 315) are attributed partly to the Pima file.
- Plain rounding of fractional votes (see Alignment).
- The counties are not contiguous (Pinal lies between them).
