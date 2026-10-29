# Worked example: San Francisco

San Francisco votes on the same California propositions as the rest of the state, but every one of its neighborhoods is Democratic by any national standard: the least Democratic bloc below gave Democrats 77% of the two-party vote. National partisanship therefore has little room to separate its neighborhoods, which makes it a good place to see what the voting blocs add. This example fits the model to the city's 64 propositions of 2012–2022, maps the blocs, and measures how much of each proposition they explain beyond national partisanship.

Everything below comes from [`sf_example.R`](sf_example.R), run from the repository root:

```sh
Rscript examples/san_francisco/sf_example.R     # about 5 minutes on 10 cores
```

It needs [Elections.BBMM](https://github.com/cascobayesian/Elections.BBMM) (`remotes::install_github("cascobayesian/Elections.BBMM")`), **sf** and **ggplot2**, and writes its figures and tables to `output/`.

## 1. The data

```r
source("R/read_place.R")
d   <- read_place("sf")                    # Yes votes and Yes + No totals, precinct x proposition
fed <- read_place("sf", "federal_races")   # Democratic votes and Dem + Rep totals, President and US Senate
g   <- read_units("sf")                    # the 2024 precinct map
d
#> BBMM data: 510 units x 64 questions, 22,389,096 votes; 0.1% of cells empty
#> Median votes per cell 703; pooled Yes share 0.597
```

The units are San Francisco's 510 precincts on the 2024 map; returns from 2012–2022 were moved onto it through census blocks, weighted by registered voters ([`data/sf/DATA.md`](../../data/sf/DATA.md)).

## 2. Fitting the model

The fast route is tempered EM: for each number of blocs *K*, ten random starts, keeping the best. The likelihood is tempered by ζ = 0.3 (see the main [README](../../README.md#the-model)).

```r
sel <- bbmm_em_select(d, K = 2:14, zeta = 0.3, n_starts = 10, seed = 2026, cores = 10)
#>   K   loglik occupied  min_share     BIC converged n_at_best
#>   5 -46038.3        5 0.08431373 95444.1      TRUE         8
#>   ...
#>   9 -45472.3        9 0.04313725 97014.2      TRUE         1
#>  10 -45468.2        9 0.06470588 97006.1      TRUE         1
#>  12 -45390.6       11 0.01568627 98202.0      TRUE         1
#> Selected number of blocs:
#>          BIC min_share_3% min_share_5%
#>            5            9            9
```

![EM selection](output/em_selection.png)

BIC prefers five blocs; the rule of taking the largest *K* in which every bloc holds at least 5% of precincts gives nine, as does the 3% rule. Beyond nine, extra components either stay empty (at *K* = 10 and 11, still nine occupied) or carve off blocs of a few precincts. We use nine, the number the paper reports for San Francisco. Only one of the ten starts reaches the best fit at *K* = 9, so the exact boundaries between neighboring blocs are less settled than the overall pattern; the stepping-stone sampler in Elections.BBMM (`bbmm_evidence()`) puts uncertainty on both the number of blocs and the partition.

## 3. Where the blocs are

```r
fit <- sel$fits[["9"]]
s <- bloc_summary(fit, d)
plot_bloc_map(s, g)
```

![Bloc map](output/bloc_map.png)

The blocs are spatially coherent although the model knows nothing about geography: every precinct is assigned from its votes alone. The names below are the paper's (its Appendix D), matched to these blocs by overlap; seven of the nine match one paper bloc almost one-for-one (adjusted Rand index 0.78 between the two partitions).

| Bloc | Precincts | Normal vote (% Dem) | Paper's bloc | Where |
|---|---|---|---|---|
| 1 | 34 | 84.1 | Low-Income Renters | Bayview–Hunters Point, the southeastern waterfront, the Tenderloin, Treasure Island |
| 2 | 80 | 93.8 | Progressive Renters | The Mission, Hayes Valley, Bernal Heights, the Castro, the Haight |
| 3 | 66 | 87.7 | Young Professionals | South of Market, the Inner Richmond, Nob Hill, the Western Addition |
| 4 | 51 | 93.3 | Wealthy Progressives | Noe Valley, Potrero Hill, Glen Park |
| 5 | 82 | 85.8 | Affluent Renters | Pacific Heights, Russian Hill, the Financial District, Mission Bay |
| 6 | 87 | 81.0 | Middle-Class Mixed | The Outer Richmond, Oceanview, Merced and Ingleside, the Excelsior |
| 7 | 61 | 76.6 | Asian Homeowners and Asian Immigrant Families (two blocs in the paper) | The Sunset and Parkside, Visitacion Valley, Portola |
| 8 | 27 | 79.9 | Wealthy Moderates (Marina) | The Marina, Cow Hollow, Sea Cliff |
| 9 | 22 | 78.0 | Wealthy Moderates (west of Twin Peaks) | St. Francis Wood, Forest Hill, West Portal |

The differences from the paper are one merge and one split: this fit joins the paper's two Asian-majority blocs, and divides its Wealthy Moderates into the Marina and the neighborhoods west of Twin Peaks. The paper's fit was made with different settings (see the note at the end of the main README).

## 4. What the blocs vote for

`distinctive_questions()` lists, for each bloc, the propositions on which it departs most from the city as a whole; `plot_bloc_profiles()` shows the blocs' Yes shares on a selection of them.

![Bloc profiles](output/bloc_profiles.png)

Two contrasts carry most of the structure. The first is the familiar progressive–moderate axis: repealing the death penalty, legalizing marijuana and restoring parolees' voting rights run from 82–90% in the Mission and Noe Valley blocs (2 and 4) to 55–62% in the Sunset (7). The second is class, and it cuts across the first. On the 2016 extension of the income tax on high earners (Proposition 55), the Low-Income Renters (1) voted 82% Yes and the Marina (8) 51%; on the two rent-control initiatives of 2018 and 2020, the Low-Income Renters were 22 to 32 points more supportive than the two wealthy-moderate blocs (8 and 9).

## 5. Beyond national partisanship

Each precinct's **normal vote** is its mean two-party Democratic share across the presidential and Senate races in `federal_races.csv.gz`. For every proposition we compare two ballot-weighted regressions with the same degrees of freedom: Yes share on nine equal-count bins of the normal vote, and Yes share on the nine blocs.

```r
#> Median r^2 with the normal vote: 0.54; 12 of 64 propositions below 0.25
#> Median adjusted R^2: 9 bins of the normal vote 0.58, 9 blocs 0.78; blocs explain more on 61 of 64
```

![Blocs vs partisanship](output/blocs_vs_partisanship.png)

National partisanship explains about half the variance in the typical proposition and almost none in a fifth of them. The blocs, estimated without any partisan information, explain more than the binned normal vote on 61 of the 64 propositions. The largest gains come on questions the parties barely take sides on ([`output/questions_vs_partisanship.csv`](output/questions_vs_partisanship.csv)):

| Proposition | r² with normal vote | Adjusted R², blocs | Gain from adding blocs |
|---|---|---|---|
| 2016 Prop 55: Extend income tax on high earners | 0.20 | 0.83 | 0.63 |
| 2022 Prop 29: Dialysis clinic requirements | 0.04 | 0.62 | 0.59 |
| 2018 Prop 8: Dialysis clinic revenue cap | 0.17 | 0.76 | 0.59 |
| 2020 Prop 23: Dialysis clinic requirements | 0.15 | 0.72 | 0.58 |
| 2018 Prop 3: Water bond | 0.05 | 0.59 | 0.55 |

The partisan-matched pairs make the same point. Progressive Renters (2) and Wealthy Progressives (4) have normal votes half a point apart (93.8 and 93.3), so national partisanship cannot tell them apart, yet they split by 11 and 12 points on the 2018 and 2020 rent-control initiatives. These numbers match the paper's San Francisco row (median bins 0.58, blocs 0.79, blocs ahead on 62 of 64; the same characteristic ballots).

## 6. Federal races in the model

`combined.csv.gz` adds the nine presidential and Senate races to the 64 propositions. Fitting the same model to both:

```r
both <- read_place("sf", "combined")
fit_both <- bbmm_em(both, K = 9, zeta = 0.3, n_starts = 10, seed = 2026)
#> Adjusted Rand index, blocs from measures only vs measures + federal races: 0.69
```

The partition changes noticeably (adjusted Rand index 0.69): nine candidate races among 73 contests pull the blocs toward the partisan axis. The paper's San Francisco blocs use the propositions only, so that the comparison with partisanship in section 5 is not circular.

## 7. Going further

- The fully Bayesian fit: `bbmm_evidence(d, K = 2:14, zeta = 0.3, n_threads = 10)` gives the posterior on the number of blocs by stepping-stone sampling (hours rather than minutes; see the [Elections.BBMM tutorial](https://github.com/cascobayesian/Elections.BBMM/blob/main/TUTORIAL.md)).
- `plot_js_pca(d, s)` places the precincts in Jensen–Shannon principal coordinates ([`output/js_pca.png`](output/js_pca.png)): the first coordinate (64% of the variation) is the progressive–moderate axis, and the blocs explain 94% of it.
- [`data/sf/other/candidate_contests.csv.gz`](../../data/sf/other/) holds the city's mayoral, district-attorney and other nonpartisan contests of 2018–2024 on the same precincts, which the paper uses to show that the coalitions behind candidates recur across elections.
- Every other place in [`data/`](../../data/) loads the same way: `read_place("nyc")`, `read_place("co")`, …
