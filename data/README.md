# Data

One folder per atlas place (38 in all). Every place has the same files, ready for the beta-binomial mixture model in [Elections.BBMM](https://github.com/cascobayesian/Elections.BBMM).

| File | Contents |
|---|---|
| `ballot_measures.csv.gz` | Ballot measures, one row per unit and question: `unit_id, question_id, year, type, yes, total` |
| `federal_races.csv.gz` | President and US Senate general elections, in the same layout: `yes` = Democratic votes, `total` = Democratic + Republican votes |
| `combined.csv.gz` | The two together |
| `questions.csv` | One row per question or race: `type`, `scope` (statewide, city, county, …, or federal), a short `label` where one exists, units, votes, overall yes share |
| `units.gpkg` | Unit boundaries, EPSG:4326, simplified to 10 m (California: `units.gpkg.zip`) |
| `DATA.md` | How the data were made: raw sources, shapefiles, how returns from earlier years were moved onto one map, alignment checks, known issues |
| `other/` | Where it exists: local referenda and candidate contests on the same units (see below) |

**Units.** A unit is a precinct on one recent map (usually 2024): every earlier election's returns have been moved onto that map, so a row for 2012 and a row for 2024 with the same `unit_id` describe the same area. The exceptions are Maine (towns, which do not change), New York City (election districts), Philadelphia (divisions), Columbus (wards) and Chicago (ward precincts). `DATA.md` says how each place was aligned.

**Counts.** `yes` and `total` are whole numbers of votes, `0 <= yes <= total`, with blank ballots left out. Where returns were moved between maps, the allocated counts are estimates, rounded to whole votes. A question that was not on a unit's ballot has no row.

**Reading a place into R.** [`R/read_place.R`](../R/read_place.R) turns a folder into the model's input:

```r
source("R/read_place.R")
d   <- read_place("sf")                     # ballot measures
fed <- read_place("sf", "federal_races")    # President and US Senate
all <- read_place("sf", "combined")
g   <- read_units("sf")                     # boundaries, for Elections.BBMM::plot_bloc_map()
```

Or without the helper:

```r
x <- read.csv("data/sf/ballot_measures.csv.gz", colClasses = c(unit_id = "character"))
yes   <- tapply(x$yes,   list(x$unit_id, x$question_id), sum)
total <- tapply(x$total, list(x$unit_id, x$question_id), sum)
d <- Elections.BBMM::bbmm_data(yes, total)
```

**Metro cut-outs.** Eight places are the precincts of a metro area inside a statewide data set: Seattle (Washington), San Diego (California), Greater New Orleans (Louisiana), Greater Boston (Massachusetts), Greater Atlanta (Georgia), Greater Denver (Colorado), Greater Detroit (Michigan) and Greater Charlotte (North Carolina). Their files are the parent's, restricted to those units; their `DATA.md` gives the boundary and points to the parent.

**Places that mix levels.** In New York City, Chicago, Minneapolis–St. Paul, Philadelphia and Salt Lake County, the ballot-measure panel combines statewide and local questions; `questions.csv` marks each one's `scope`. Washington, DC's measures are District charter amendments, initiatives and referendums.

## Other datasets (`other/`)

| Place | File | Contents |
|---|---|---|
| Massachusetts | `local_measures.csv.gz`, `local_questions.csv`, `local_questions_coded.csv` | 378 district and municipal questions, 2012–2024, on the 2022 precincts (2012–20 allocated with the statewide crosswalks, kept where at least half the precinct's area voted on the question); the coded file has the topic codes and texts of the 263 the paper analyses |
| Massachusetts | `primaries_2022_2024.csv.gz` | Candidate shares in 13 contested statewide primaries, 2022–2024 |
| Portland (Multnomah County) | `local_measures.csv.gz`, `local_questions.csv` | 179 county, city, school and special-district measures, 2012–2026, on the 2022 precincts |
| Columbus (Franklin County) | `local_measures.csv.gz`, `local_questions.csv` | 57 Franklin County, City of Columbus, Columbus City Schools and library measures, 2012–2026, on the same wards |
| Austin (Travis County) | `local_measures.csv.gz`, `local_questions.csv` | 22 county, city, school-district and college-district measures, 2022–2025 |
| Louisiana | `local_measures.csv.gz`, `local_questions.csv` | 8,133 parish, municipal and special-district propositions (millages, taxes, bonds, charters, liquor options), 2000–2024, on the 2024 precincts |
| New York City | `primary_2021_*.csv`, `primary_2025_*.csv`, `general_2025_mayor.csv` | Democratic primaries for mayor, comptroller and public advocate, 2021 (moved onto the 2024 districts; fractional) and 2025 (from the cast-vote records), with first-choice and final-round counts; the 2025 mayoral general |
| San Francisco, Los Angeles County | `candidate_contests.csv.gz` | Nonpartisan and top-two candidate contests, 2018–2024 (mayor, district attorney, sheriff and others), as used in the paper's test of recurring coalitions |

Local referenda share one layout (`unit_id, question_id, year, scope, yes, total`), so `bbmm_data()` takes them the same way. Each place's `DATA.md` lists further data the project holds but has not aligned to a common map.

## How these files were made

`scripts/export_model_ready.R` writes the main files from the project's per-place bundles (the data behind the atlas); `scripts/export_other.R` writes `other/`; `scripts/tag_scope.R` adds the `scope` column. They need the full Local Politics project folder and are here as a record. South Florida's files are cut from the statewide Florida panel rather than from its own bundle, which predates a fix to its alignment (see `south_florida/DATA.md`).
