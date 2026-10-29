# Chicago: how the model-ready data were made

| | |
|---|---|
| Unit | Ward/precinct (`WW-PPP`), City of Chicago **2023–2024** precinct map |
| Units | 1,291 (all in `votes.csv` and `partisan.csv`) |
| Years | Ballot measures 2014–2022; federal races 2014–2022 (2024 President held separately) |
| Ballot measures | 8 (`votes.csv`): 2014 (2), 2015 (3), 2016 (1), 2020 (1), 2022 (1) |
| Federal contests | 6 (`partisan.csv`): US Senate 2014, 2016, 2020, 2022; President 2016, 2020 |

Bundle: `output/atlas/overview/bundles/chicago/`, a copy of `output/table2/chicago/` written by `code/table2/adapt_chicago.R`. Fit/build folder: `data/chicago/new/` (README and `Data/DEPENDENCIES_AND_PROVENANCE.md`); reallocation: `data/chicago/reprocess_2024_README.md`.

## Raw data

Ballot measures and federal races come from the same source.

- **Precinct returns**: Chicago Board of Election Commissioners data export (`https://chicagoelections.gov/en/data-export.asp?election=<n>&race=<m>&ward=&precinct=`), one `.xls` per race. Index of 535 races with URLs: `data/chicago/chicago_ids.xlsx`; downloads `data/chicago/chicago_data/data_<n>.xls` (535 files), fetched by `data/chicago/chicago_script.R`.
- Compiled long file (native precinct maps, columns `Ward, Precinct, Question, Response, Number_Votes, Election_Date`): `data/chicago/chicago_2014_2023.csv` (years 2014, 2015, 2016, 2017 [Ward 4 only], 2019, 2020, 2022, 2023; no 2012, 2018 or 2021 records); referendum subset `data/chicago/chicago_2014_2023_referendums.csv`. **How the `.xls` files were compiled into this CSV is not documented** (checked `chicago_script.R`, `process.r`, the READMEs). The `Question` strings carry an unrelated office prefix (e.g. "Attorney General, State of Illinois - Protect Right to Vote"), removed in `data/chicago/reshape_referendums_wide.R`.
- Question labels: the 2020/2022 amendments are unnamed in the source; the bundle's labels (graduated income tax; workers' rights) are from public record (`code/table2/adapt_chicago.R`).
- **President 2024** (robustness only, not in `partisan.csv`): Illinois State Board of Elections certified canvass precinct file, downloaded 2026-09-30, `data/chicago/pres_2024/isbe_2024GE_president_by_precinct.csv` (cross-checked against MEDSL, `medsl_2024_il_chicago_president.csv`); bundled as `partisan_latest_pres.csv` by `code/table2/chicago_pres2024.R`.

## Shapefiles

City of Chicago Data Portal, downloaded 2026-09-17 (`data/chicago/ward_precinct_shapefiles/README.md`):

- **Target**: Boundaries – Ward Precincts (2023–2024), `https://data.cityofchicago.org/d/6piy-vbxa`, 1,291 precincts (valid from the Feb 2023 municipal election through Nov 2024). Bundle geometry: `data/chicago/new/Shapefile/chicago_ward_precincts_2023_2024.gpkg`; original `data/chicago/ward_precinct_shapefiles/2023_2024/`.
- **Sources**: 2013–2022 map (`https://data.cityofchicago.org/d/nvke-umup`, 2,069 precincts; used for 2014–2021) in `ward_precinct_shapefiles/2013_2022/`; November 2022 map (`https://data.cityofchicago.org/d/ruvz-nczq`, 1,290 precincts) in `ward_precinct_shapefiles/2022/`.
- **Blocks**: 2020 TIGER/Line Cook County blocks and Illinois PL 94-171 (VAP = P0030001); URLs in `data/chicago/reprocess_2024_README.md`; cache `data/chicago/census_cache/`.

## Alignment across years

- **Method: 2020 census-block voting-age-population (VAP) crosswalk with areal split of blocks.** `adult_mass(s,t) = Σ_b VAP(b) × area(b ∩ s ∩ t)/area(b)`; `weight(s,t) = adult_mass(s,t)/Σ_u adult_mass(s,u)` (EPSG:26971). Fallbacks to total population, then area (none needed). Weights are renormalised over the territory covered by the target map; votes may cross ward lines.
- **Years moved**: 2014–2021 from the 2013–2022 map; 2022 by identity except Ward 24 precinct 16, split into target 16 and 20 by VAP; 2023 identity.
- **Script**: `data/chicago/reprocess_2024.R` → `data/chicago/reprocessed_2024/` (`chicago_2014_2023_2024_boundaries.csv`, `precinct_crosswalk_to_2024.csv`, `vote_conservation_audit.csv`, `geometry_coverage_*.csv`). Wide files: `data/chicago/reshape_referendums_wide.R`, `data/chicago/reshape_national_wide.R` → `reprocessed_2024/chicago_2014_2023_{referendums,national}_2024_boundaries_wide.csv`, copied to `data/chicago/new/Data/`; `data/chicago/new/Scripts/00_prepare_inputs.R` derives `chicago_referendum_precinct_counts.csv` and `chicago_candidate_precinct_counts.csv` (the adapter's inputs).
- **Rounding: not documented.** `reprocess_2024.R` keeps fractional votes ("Do not independently round rows"), but the wide files and the model inputs hold integers; `new/Data/DEPENDENCIES_AND_PROVENANCE.md` says the workflow "does not independently certify the upstream rounding/allocation process". (A spot check of 300 cells is consistent with rounding each cell to the nearest integer; this is my check, not a project record.)

## Summary statistics from alignment

From `data/chicago/reprocess_2024_README.md`:

- 626,022 output rows; all 1,678 year–contest–response groups preserved observed vote totals (max floating-point difference < 2e-9 votes); all 34,159 2023 rows unchanged. Every redistributed source precinct had positive VAP.
- 61 older source precincts had > 0.5% of area outside the target footprint; lowest adult-population coverage 97.5031% (historical Ward 48 precinct 22).
- 2022 split of Ward 24 precinct 16: 33.2436% to target 16, 66.7564% to target 20.
- One missing input value (2019, Ward 35 precinct 15) leaves five target estimates NA (Ward 35 precincts 10–14); none of the bundle's contests are affected.
- Bundle checks (`code/table2/adapt_chicago.R`): question totals reproduce the fit's `questions_used.csv` exactly; geometry match 1.0; canary r = 0.9997, max |dev| 0.0076 (meta.json).

## What is in the model-ready files

- **Ballot measures** (success = **Yes** for all; all eight passed in Chicago): 2014 IL amendments Right to vote and Crime victims' rights; 2015 Chicago citywide advisory questions Paid sick leave, Domestic abuse treatment, Campaign finance reform (the "2015 Municipal General" election in `chicago_ids.xlsx`; trial counts ~450k); 2016 IL Transportation lockbox amendment; 2020 IL amendment (graduated income tax); 2022 IL Amendment 1 (workers' rights).
- **Dropped**: 2019 ward/precinct-level questions (Rent control, Marijuana funds) appear in the reallocated data but are not among the 8 model questions; no reason is recorded beyond citywide coverage (`data/chicago/elections_90_percent_ward_coverage.md` lists contests by ward coverage).
- **Federal races**: US Senate 2014/2016/2020/2022, President 2016/2020, D and R only (third-party columns listed in `data/chicago/new/Results/excluded_third_party_columns.csv`). No 2012 returns supplied.
- **Units excluded**: none.

## Other datasets

All on the native maps in `data/chicago/chicago_2014_2023.csv` and on the 2024 map in `data/chicago/reprocessed_2024/chicago_2014_2023_2024_boundaries.csv` (fractional, VAP-allocated), unless noted:

- **Ward- and precinct-level advisory referendums**: 2015 "Elected School Board" questions in 37 wards, 2015 Ward 10 Petroleum Coke Ban, 2015 W16 P30 TIF council; 2019 Rent control (W1, W26, W45, W50 precincts), Marijuana funds (W6, W16, W17, W24, W28, W29), CBA ordinance (W5, W12, W20, W22, W25); 2023 South Shore CBA (W5 precincts), Woodlawn affordable housing (W5), Reopening Green Line station (W16). 2019 Rent control and Marijuana funds subset on 2024 map: `data/chicago/reprocessed_2024/chicago_2014_2023_referendums_2024_boundaries.csv` (21,144 rows).
- **Cook County question**: 2022 Forest Preserve District tax-limit increase (in the same long files, 2022 November map).
- **Judicial retention (Yes/No) votes** 2014, 2016, 2020, 2022 and all candidate contests (Cook County, state, municipal 2015/2019/2023) are in the same long files.
- **Raw-only referendums not in any processed file**: `data/chicago/chicago_data/` (indexed by `chicago_ids.xlsx`) also holds 2018 Cook County advisory questions (Min wage, Earned sick time, Gun dealer penalties, Marijuana revenue, Tax exemption, Ban straws) and many 2018 ward/precinct questions (Clean water, Rent control, Water hearings, ...); 2020 citywide/regional questions (Broadband, City plan, Firearms, Mental health district/tax, Police panel) and Bronzeville Senior Center precinct questions; 2022 Preserving Trees (W5); 2016 Earned sick time, Mental health district; 2014 Medical marijuana sites; 2012 IL amendment, mental health and liquor questions. On native precinct maps, not compiled or reallocated (2012, 2018, 2021 are absent from `chicago_2014_2023.csv`).
- **President 2024**: `data/chicago/pres_2024/` (see Raw data), on the 2023–2024 map.

## Known issues

- All counts before 2023 are VAP-based estimates, not original precinct returns; 2020 VAP is used for every year.
- The supplied integers come from an undocumented rounding step (above).
- Only 8 questions; three are citywide advisory, not binding measures.
- Source `Question` labels attach the wrong office names; 2017 has only Ward 4.
- Normal vote excludes 2012 and 2024; 2024 President is only in `partisan_latest_pres.csv` (meta.json).
