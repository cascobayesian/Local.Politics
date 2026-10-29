# Local.Politics: the structure of local politics across the United States

Data, documentation and a worked example for **"The Structure of Local Politics"** (Aaron R. Kaufman and John D. O'Brien, working paper), and for the *Atlas of US Voting Blocs*.

## The paper in brief

American politics is said to be nationalized: one partisan dimension, red against blue, everywhere. But most of what voters decide never carries a party label. They vote on ballot measures, and in primaries and nonpartisan local races where every candidate shares a party. What organizes those choices is largely unknown. Surveys ask about only a handful of local issues, and one-dimensional scaling assumes the answer in advance.

We take a different route. We assembled an original compilation of **precinct-level election returns across 38 US places**:
- **16 states, and 14 cities, counties and metropolitan areas**, plus eight metropolitan areas carved out of the statewide data;
- **about 88,000 precincts and other small voting units**, each with returns from every year moved onto a single recent map;
- **about 1,100 distinct statewide and local ballot questions**, and nearly **8,800 more local referenda** for places where we have them;
- **more than 2.5 billion votes** on ballot measures, from 2000 to 2025;
- the **presidential and US Senate** results on the same units.

To this we apply the **beta-binomial mixture model (BBMM)**, borrowed from population genetics. The model finds **voting blocs**: groups of precincts that vote alike across dozens of ballot questions, with no demographic information and no partisan information. Then we ask three questions.

1. **How national is local politics?** Less than the conventional wisdom holds. In the ten places studied in depth:
   - National partisanship leaves more than a third of the variation in the median referendum unexplained in six of them.
   - Between a tenth and a third of each place's referenda are nearly unrelated to partisanship.
2. **What structures the rest?** Voting blocs that partisanship cannot see.
   - Blocs estimated without partisan information explain more of the vote than an equally flexible function of national partisanship on most questions everywhere but Portland.
   - Pairs of blocs with identical partisanship split by up to 39 points on a single question.
   - The biggest gains come on questions the parties take no position on: pension forfeiture, end-of-life care, drug policy, daylight saving time, taxes on high earners.
   - The blocs are durable. In New York City's 2025 Democratic mayoral primary, held after the referenda used to estimate them, the blocs explain 59% of the variation in the winner's vote share across election districts, against 14% for national partisanship.
   - The coalitions behind one candidate reappear behind different candidates in later elections.
3. **Who belongs to which bloc?**
   - Race predicts bloc membership best in the large multiracial cities.
   - Education predicts it best elsewhere.
   - The urban–rural divide that organizes national politics is conspicuously absent.

This repository makes the data behind that work public, in a form ready for the model, with a record of how each place's data were made. The model itself is in the R package [**Elections.BBMM**](https://github.com/cascobayesian/Elections.BBMM).

## The places

**Statewide**

| Place | Units | Years | Ballot measures | Federal races | Votes on measures (millions) | Blocs (K)\* | Also |
|---|---|---|---|---|---|---|---|
| [Alabama](data/al/) | 1,946 precincts | 2016–24 | 40 | 7 | 54.7 | 10 |  |
| [California](data/ca/) | 23,006 precincts | 2012–24 | 74 | 9 | 962.3 | 30 |  |
| [Colorado](data/co/) | 3,185 precincts | 2011–25 | 78 | 8 | 192.5 | 8 |  |
| [Florida](data/fl/) | 5,700 precincts | 2012–24 | 45 | 9 | 374.8 | 12 |  |
| [Georgia](data/ga/) | 2,687 precincts | 2016–24 | 21 | 6 | 85.8 | 13 |  |
| [Louisiana](data/la/) | 3,646 precincts | 2000–24 | 168 | 18 | 188.4 | 10 | 8,133 local propositions |
| [Massachusetts](data/ma/) | 2,392 precincts | 2012–24 | 25 | 10 | 71.1 | 6 | 378 local questions; 13 primaries |
| [Maryland](data/md/) | 1,969 precincts | 2012–24 | 20 | 9 | 44.9 | 9 |  |
| [Maine](data/me/) | 462 towns | 2008–25 | 72 | 4 | 37.3 | 7 |  |
| [Michigan](data/mi/) | 4,340 precincts | 2014–22 | 10 | 7 | 41.2 | 6 |  |
| [North Carolina](data/nc/) | 2,659 precincts | 2012–24 | 10 | 8 | 34.2 | 11 |  |
| [New Mexico](data/nm/) | 2,169 precincts | 2014–24 | 38 | 7 | 25.1 | 7 |  |
| [Ohio](data/oh/) | 8,878 precincts | 2017–25 | 11 | 7 | 35.9 | 7 |  |
| [Utah](data/ut/) | 2,683 precincts | 2016–22 | 18 | 4 | 20.9 | 12 |  |
| [Washington](data/wa/) | 7,846 precincts | 2012–24 | 73 | 9 | 177.3 | 14 |  |
| [Wisconsin](data/wi/) | 3,554 precincts | 2018–25 | 10 | 7 | 14.8 | 7 |  |

**Cities, counties and metropolitan areas**

| Place | Units | Years | Ballot measures | Federal races | Votes on measures (millions) | Blocs (K)\* | Also |
|---|---|---|---|---|---|---|---|
| [Austin (Travis County)](data/austin/) | 286 precincts | 2023–25 | 31 | 4 | 5.7 | 7 | 22 local measures |
| [Chicago](data/chicago/) | 1,291 precincts | 2014–22 | 8 | 6 | 5.0 | 8 | 3 of the 8 are city advisory questions |
| [Columbus (Franklin County)](data/columbus/) | 159 wards | 2012–25 | 17 | 9 | 5.7 | 8 | 57 local measures |
| [Dallas County](data/dallas/) | 820 precincts | 2013–25 | 74 | 9 | 10.3 | 9 |  |
| [Washington, DC](data/dc/) | 144 precincts | 2010–24 | 9 | 4 | 2.1 | 5 | District measures |
| [Los Angeles County](data/la_county/) | 2,674 precincts | 2012–24 | 74 | 9 | 225.8 | 10 | Candidate contests, 2018–24 |
| [Minneapolis–St. Paul](data/msp/) | 223 precincts | 2012–24 | 25 | 10 | 4.2 | 6 | 21 of the 25 are city or school questions |
| [New York City](data/nyc/) | 4,152 election districts | 2014–24 | 30 | 9 | 38.1 | 9 | 16 of the 30 are city proposals; 2021 and 2025 primaries |
| [Philadelphia](data/philadelphia/) | 1,703 divisions | 2014–24 | 56 | 11 | 14.0 | 8 | 48 of the 56 are city questions |
| [Phoenix and Tucson (Maricopa and Pima)](data/phoenix_tucson/) | 1,177 precincts | 2012–24 | 44 | 10 | 82.3 | 11 |  |
| [Portland (Multnomah County)](data/portland/) | 107 precincts | 2012–24 | 41 | 8 | 14.7 | 5 | 179 local measures |
| [San Francisco](data/sf/) | 510 precincts | 2012–22 | 64 | 9 | 22.4 | 9 | Candidate contests, 2018–24 |
| [Salt Lake County](data/slc/) | 803 precincts | 2011–24 | 55 | 4 | 12.7 | 8 | 30 of the 55 are county, city or district questions |
| [South Florida](data/south_florida/) | 1,908 precincts | 2012–24 | 45 | 9 | 93.5 | 7 |  |

**Metro cut-outs of the statewide data** (the parent's precincts in the metro area; [details](data/README.md#metro-cut-outs))

| Place | Units | Years | Ballot measures | Federal races | Votes on measures (millions) | Blocs (K)\* | Also |
|---|---|---|---|---|---|---|---|
| [Greater Atlanta](data/atlanta/) | 1,203 precincts | 2016–24 | 21 | 6 | 41.2 | 13 |  |
| [Greater Boston](data/boston/) | 1,190 precincts | 2012–24 | 25 | 10 | 35.0 | 6 |  |
| [Greater Charlotte](data/charlotte/) | 459 precincts | 2012–24 | 10 | 8 | 7.1 | 11 |  |
| [Greater Denver](data/denver/) | 1,728 precincts | 2011–25 | 78 | 8 | 107.9 | 8 |  |
| [Greater Detroit](data/detroit/) | 1,970 precincts | 2014–22 | 10 | 7 | 19.5 | 6 |  |
| [Greater New Orleans](data/new_orleans/) | 928 precincts | 2000–24 | 168 | 18 | 51.7 | 8 |  |
| [San Diego County](data/san_diego/) | 1,859 precincts | 2012–24 | 74 | 9 | 88.8 | 26 |  |
| [Seattle (King County)](data/seattle/) | 2,744 precincts | 2012–24 | 73 | 9 | 54.0 | 13 |  |

\* *K* is the number of blocs in the atlas fit for each place (for the metro cut-outs, the number of the parent's blocs present). See the [note on K](#a-note-on-the-number-of-blocs) below.

*Units* are the units in the ballot-measure file; *Votes on measures* counts Yes + No votes summed over every unit and question. Federal races are the presidential and US Senate general elections in the same years, as Democratic and Republican votes. *Also* lists local questions inside the main panel and further data sets in the place's `other/` folder. Every place's [`DATA.md`](data/sf/DATA.md) records:
- where the raw returns and boundary files came from;
- how earlier years were moved onto the common map;
- the checks made along the way;
- data the project holds but has not aligned.

## What is in each place's folder

| File | Contents |
|---|---|
| `ballot_measures.csv.gz` | Ballot measures: `unit_id, question_id, year, type, yes, total` |
| `federal_races.csv.gz` | President and US Senate: `yes` = Democratic votes, `total` = Democratic + Republican |
| `combined.csv.gz` | Both together |
| `questions.csv` | Each question or race: scope (statewide, city, …), label, units, votes, overall Yes share |
| `units.gpkg` | Unit boundaries |
| `DATA.md` | How the data were made |
| `other/` | Local referenda and candidate contests on the same units, where they exist |

[`data/README.md`](data/README.md) describes the files in detail. [`R/read_place.R`](R/read_place.R) loads any place as the model's input:

```r
source("R/read_place.R")
d <- read_place("nyc")                  # or "federal_races", "combined"
fit <- Elections.BBMM::bbmm_em(d, K = 9, zeta = 0.3)
```

## The model

Each unit *i* (a precinct, town or election district) belongs to one of *K* blocs, *z<sub>i</sub>* = *k* with probability π<sub>*k*</sub>. Given its bloc, the Yes votes *x<sub>iq</sub>* out of *n<sub>iq</sub>* cast on question *q* follow a beta-binomial distribution:

*x<sub>iq</sub>* | *z<sub>i</sub>* = *k* ~ BetaBinomial(*n<sub>iq</sub>*, μ<sub>*kq*</sub>, ν<sub>*k*</sub>)

Here μ<sub>*kq*</sub> is bloc *k*'s expected Yes share on question *q* and ν<sub>*k*</sub> how tightly its units cluster around it. The model estimates three things:
- the number of blocs and their sizes;
- each unit's probability of belonging to each bloc;
- each bloc's profile across every question, which shows the questions that separate any two blocs.

As in genetic models of population structure, the blocs are not points on an ideological axis. Two blocs can vote identically in partisan contests and differently on referenda. Demographics play no part in the estimation, so any relationship between demography and blocs is found, not assumed.

With hundreds of votes per unit, the ordinary likelihood treats every small, persistent difference as decisive. The model therefore uses a coarsened (tempered) posterior, which raises the likelihood to a power ζ = 0.3. The number of blocs comes from the posterior on *K*, computed by stepping-stone sequential Monte Carlo; tempered EM gives a fast approximation.

**The full model, code and tutorial:** [**github.com/cascobayesian/Elections.BBMM**](https://github.com/cascobayesian/Elections.BBMM). The model was developed for Maine's referendums in O'Brien (2026), *Political Science Research and Methods* ([doi:10.1017/psrm.2025.10050](https://doi.org/10.1017/psrm.2025.10050)).

## Example: San Francisco

[`examples/san_francisco/`](examples/san_francisco/) fits the model to San Francisco's 64 California propositions of 2012–2022 in 510 precincts. Every precinct in the city is Democratic by national standards: the least Democratic bloc gives Democrats 77% of the two-party vote. Even so, the blocs find a structure that partisanship misses.

<p align="center"><img src="examples/san_francisco/output/bloc_map.png" width="70%" alt="Map of San Francisco's nine voting blocs"></p>

- **Nine blocs**, by the rule that every bloc holds at least 5% of precincts, as in the paper. They are spatially coherent although the model never sees a map.
- **Partisanship explains little.** It explains a median 54% of the variance in a proposition, and under 25% for 12 of the 64.
- **The blocs explain more on 61 of the 64.** The median adjusted R² is 0.78 for the blocs against 0.58 for nine bins of the normal vote.
- **The gains come on class.** The largest are on the 2016 tax on high earners (0.63) and three dialysis-clinic initiatives. Two blocs half a point apart in partisanship split by 11–12 points on rent control.

The walkthrough runs in about five minutes: [`examples/san_francisco/README.md`](examples/san_francisco/README.md).

## Repository layout

```
data/<place>/            model-ready data, boundaries and DATA.md for each of the 38 places
data/<place>/other/      local referenda and candidate contests on the same units
data/README.md           file formats; metro cut-outs; places that mix statewide and local questions
R/read_place.R           load a place as an Elections.BBMM data set
examples/san_francisco/  worked example
scripts/                 how the files in data/ were written from the project's working files (a record; needs the full project)
```

## Citation

Aaron R. Kaufman and John D. O'Brien. "The Structure of Local Politics." Working paper.

John D. O'Brien. 2026. "A Bayesian Mixture Model Captures Temporal and Spatial Structure of Voting Blocs within Longitudinal Referendum Data." *Political Science Research and Methods*, 1–22. https://doi.org/10.1017/psrm.2025.10050

## A note on the number of blocs

\* **The bloc fits are temporary.** The *K* column and the atlas blocs it describes come from a mix of methods for choosing the number of blocs and the best clustering:
- tempered EM with a 3% or 5% minimum-bloc-size rule for most places;
- BIC, or a project choice, for some;
- a 1% rule for a few.

We are now rerunning every place on a computing cluster with one consistent scheme: the stepping-stone sampler in Elections.BBMM, giving the posterior on the number of occupied blocs. The *K* values here, and any bloc assignments derived from them, will be replaced when those runs finish. The data in `data/` do not depend on the fits.
