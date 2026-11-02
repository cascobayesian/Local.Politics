# Worked example: aligning seven elections of South Florida precinct returns (2012-2024) onto the 2024 precinct map
# with the block-population crosswalk, then checking what the alignment does to the data and to the blocs.
# Run from the repository root:   Rscript examples/south_florida/sfl_alignment.R
# Needs dplyr, tidyr, sf, ggplot2, patchwork and Elections.BBMM (step 8 only). Reads examples/south_florida/inputs/
# (made from the raw downloads by prepare_inputs.R) and data/south_florida/ (the areal panel, for comparison).
# Writes to examples/south_florida/output/. About 1 minute, plus about 10 minutes for the EM fits in step 8 (cached).

suppressPackageStartupMessages({ library(dplyr); library(tidyr); library(ggplot2); library(patchwork) })
source("R/read_place.R")
inp <- "examples/south_florida/inputs"
out <- "examples/south_florida/output"; dir.create(out, showWarnings = FALSE, recursive = TRUE)
chr <- c("Unique", "Precinct", "PRECINCT", "target", "block_id", "polys", paste0("p", seq(2012, 2024, 2)))
rd  <- function(f) { h <- names(read.csv(file.path(inp, f), nrows = 1))
  read.csv(file.path(inp, f), colClasses = setNames(rep("character", sum(h %in% chr)), intersect(h, chr))) }
save_png <- function(p, f, w = 9, h = 6) ggsave(file.path(out, f), p, width = w, height = h, dpi = 150, bg = "white")
YEARS <- seq(2012, 2024, by = 2); TARGET <- 2024

## 1. Native returns ----------------------------------------------------------------------------------------
# One row per reporting unit x contest x choice, as the Florida Division of Elections reports it.
native <- rd("native_votes.csv.gz") |> mutate(votes = as.numeric(votes))
native |> group_by(county, year) |> summarise(units = n_distinct(paste(Unique, Precinct)), .groups = "drop") |>
  pivot_wider(names_from = year, values_from = units) |> print()
native |> filter(grepl("^CONST", contest)) |> group_by(year) |> summarise(amendments = n_distinct(contest), votes = sum(votes)) |> print()

## 2. Which units are places? -------------------------------------------------------------------------------
# unit_map gives each unit's class and the polygon(s) it was placed on. Units missing from it carry candidate votes
# only (Miami-Dade's overseas 100.x pseudo-precincts): they are excluded and do not touch the amendments.
umap <- rd("unit_map.csv.gz")
nv <- native |> left_join(umap, by = c("county", "year", "Unique", "Precinct")) |>
  mutate(class = coalesce(class, "federal_only"))
nv |> group_by(class) |> summarise(amendment_votes = sum(votes[grepl("^CONST", contest)]), all_votes = sum(votes)) |> print()
place_by <- nv |> filter(class == "placed") |> group_by(year, method) |> summarise(v = sum(votes), .groups = "drop") |>
  group_by(year) |> mutate(pct = round(100 * v / sum(v), 1)) |> select(-v) |> pivot_wider(names_from = method, values_from = pct, values_fill = 0)
print(place_by)

## 3. Reporting groups ----------------------------------------------------------------------------------------
# A unit can cover several polygons, and a polygon several units. Units sharing a polygon are merged (union-find);
# a vote-less polygon named in a unit's member list ("1002, 1003, ...", Palm Beach 2016) joins that unit.
ids <- rd("precinct_ids.csv.gz")
canon <- function(v) { v <- toupper(gsub("\\s+", "", v)); num <- grepl("^[0-9]+(\\.[0-9]+)?$", v)
  v[num] <- sub("\\.0+$", "", sub("^0+(?=[0-9])", "", v[num], perl = TRUE)); v }
groups_for <- function(cty, yr) {
  pu <- nv |> filter(county == cty, year == yr, class == "placed") |> distinct(Unique, Precinct, polys)
  sets <- strsplit(pu$polys, ";", fixed = TRUE)
  pids <- ids$PRECINCT[ids$county == cty & ids$year == yr]
  used <- unique(unlist(sets))
  for (i in grep(",", pu$Precinct)) {
    mem <- pids[canon(pids) %in% canon(trimws(strsplit(pu$Precinct[i], ",")[[1]]))]
    sets[[i]] <- union(sets[[i]], setdiff(mem, used))
  }
  par <- seq_along(sets); find <- function(i) { while (par[i] != i) i <- par[i]; i }
  owner <- list()
  for (i in seq_along(sets)) for (p in sets[[i]]) {
    if (is.null(owner[[p]])) owner[[p]] <- i else { a <- find(owner[[p]]); b <- find(i); if (a != b) par[b] <- a }
  }
  pu$group <- paste(cty, yr, vapply(seq_along(sets), find, 1L), sep = ":")
  list(units = select(pu, Unique, Precinct, group),
       polys = distinct(bind_rows(lapply(seq_along(sets), function(i) data.frame(group = pu$group[i], PRECINCT = sets[[i]])))))
}
G <- lapply(split(distinct(nv, county, year), seq_len(nrow(distinct(nv, county, year)))), function(r) {
  g <- groups_for(r$county, r$year); g$units$county <- g$polys$county <- r$county; g$units$year <- g$polys$year <- r$year; g })
gunits <- bind_rows(lapply(G, `[[`, "units")); gpolys <- bind_rows(lapply(G, `[[`, "polys"))
stopifnot(!anyDuplicated(gpolys[c("county", "year", "PRECINCT")]))       # each polygon in exactly one group
gsize <- count(gpolys, county, year, group, name = "n_polys")
gsize |> group_by(county, year) |> summarise(groups = n(), multi = sum(n_polys > 1), .groups = "drop") |>
  pivot_wider(names_from = year, values_from = c(groups, multi)) |> print(width = 200)

## 4. Are the units on the right polygons? -------------------------------------------------------------------
# VEST built its shapefiles by joining these same DOS files, so each polygon carries the D and R votes for one
# office. A group is placed right when its own D and R tallies equal its polygons' VEST tallies.
CHECK <- c(`2012` = "PRESIDENT", `2014` = "GOVERNOR", `2016` = "PRESIDENT", `2018` = "US_SENATE", `2020` = "PRESIDENT",
           `2022` = "US_SENATE", `2024` = "PRESIDENT")
vest <- rd("polygon_tallies.csv.gz") |> inner_join(gpolys, by = c("county", "year", "PRECINCT")) |>
  group_by(county, year, group) |> summarise(vest_dem = sum(vest_dem), vest_rep = sum(vest_rep), .groups = "drop")
own <- nv |> filter(class == "placed", contest == paste(CHECK[as.character(year)], year, sep = "_")) |>
  inner_join(gunits, by = c("county", "year", "Unique", "Precinct")) |>
  group_by(county, year, group) |> summarise(dem = sum(votes[choice == "DEM"]), rep = sum(votes[choice == "REP"]), .groups = "drop")
chk <- full_join(own, vest, by = c("county", "year", "group")) |> mutate(across(c(dem, rep, vest_dem, vest_rep), ~ coalesce(.x, 0)),
  exact = dem == vest_dem & rep == vest_rep, close = abs(dem + rep - vest_dem - vest_rep) <= 0.02 * pmax(dem + rep, 1))
vest_check <- chk |> group_by(county, year) |> summarise(groups = n(), pct_votes_exact = round(100 * sum((dem + rep)[exact]) / sum(dem + rep), 1),
  pct_votes_within_2pct = round(100 * sum((dem + rep)[close]) / sum(dem + rep), 1), .groups = "drop")
print(vest_check, n = 30)
write.csv(vest_check, file.path(out, "vest_check.csv"), row.names = FALSE)

## 5. The crosswalk ------------------------------------------------------------------------------------------
# Each 2020 census block is assigned whole to one precinct of every vintage (by its internal point; else its largest
# overlap; else the nearest precinct within 100 m). A group's votes go to the 2024 precincts in proportion to the
# group's population in each:  w(g -> t) = pop(g & t) / pop(g).  Blocks are never split by area.
# Fallbacks: land area if the group's blocks have no people; area overlap if the group holds no block at all.
blocks <- rd("blocks.csv.gz")
fallback <- rd("areal_fallback.csv.gz")
crosswalk_for <- function(cty, yr) {
  b <- blocks |> filter(county == cty) |> select(block_id, pop20, aland, src = all_of(paste0("p", yr)), target = all_of(paste0("p", TARGET))) |>
    filter(!is.na(src), !is.na(target)) |>
    inner_join(filter(gpolys, county == cty, year == yr) |> select(src = PRECINCT, group), by = "src")
  w <- b |> group_by(group, target) |> summarise(pop = sum(pop20), area = sum(aland), n_blocks = n(), .groups = "drop") |>
    group_by(group) |> mutate(basis = case_when(sum(pop) > 0 ~ "population", sum(area) > 0 ~ "land area", TRUE ~ "block count"),
                              w = if (sum(pop) > 0) pop / sum(pop) else if (sum(area) > 0) area / sum(area) else n_blocks / sum(n_blocks)) |> ungroup()
  # groups holding no block: area shares of their polygons (averaged over the group's polygons)
  empty <- setdiff(gpolys$group[gpolys$county == cty & gpolys$year == yr], w$group)
  fb <- fallback |> filter(county == cty, year == yr) |> inner_join(filter(gpolys, county == cty, year == yr), by = c("county", "year", "PRECINCT")) |>
    filter(group %in% empty) |> group_by(group) |> mutate(share = share / n_distinct(PRECINCT)) |>
    group_by(group, target) |> summarise(w = sum(share), .groups = "drop") |> mutate(basis = "area overlap")
  # in the target year itself, a group holding no block stays on its own polygon(s)
  if (yr == TARGET) fb <- filter(gpolys, county == cty, year == yr, group %in% empty) |> group_by(group) |>
    transmute(target = PRECINCT, w = 1 / n(), basis = "itself") |> ungroup()
  bind_rows(select(w, group, target, w, basis), fb) |> mutate(county = cty, year = yr)
}
cw <- bind_rows(lapply(split(distinct(gpolys, county, year), seq_len(nrow(distinct(gpolys, county, year)))),
                       function(r) crosswalk_for(r$county, r$year)))
write.csv(mutate(cw, w = round(w, 6)), gzfile(file.path(out, "crosswalk.csv.gz")), row.names = FALSE)

## 6. Align ---------------------------------------------------------------------------------------------------
gv <- nv |> filter(class == "placed") |> inner_join(gunits, by = c("county", "year", "Unique", "Precinct")) |>
  group_by(county, year, group, contest, choice) |> summarise(votes = sum(votes), .groups = "drop")
# units with no place (39 votes here; absentee/early/provisional rows elsewhere in Florida) are spread over the
# county's groups in proportion to each group's votes for the same contest and choice (the VEST convention)
spread <- nv |> filter(class == "unplaced") |> group_by(county, contest, choice) |> summarise(extra = sum(votes), .groups = "drop")
gv <- gv |> left_join(spread, by = c("county", "contest", "choice")) |> group_by(county, contest, choice) |>
  mutate(votes = votes + coalesce(extra, 0) * votes / sum(votes)) |> ungroup() |> select(-extra)
aligned <- gv |> inner_join(select(cw, group, target, w), by = "group", relationship = "many-to-many") |>
  group_by(county, year, target, contest, choice) |> summarise(est = sum(votes * w), .groups = "drop")
# integers by largest remainder within county x contest x choice, so every county total is kept exactly
lr <- function(x) { n <- floor(x); r <- round(sum(x)) - sum(n); if (r > 0) { k <- order(x - n, decreasing = TRUE)[seq_len(r)]; n[k] <- n[k] + 1 }; n }
aligned <- aligned |> group_by(county, contest, choice) |> mutate(votes = lr(est)) |> ungroup()

# How much does each year move? Share of each year's amendment votes in groups that land (>= 99%) in one 2024 precinct.
intact <- cw |> group_by(county, year, group) |> summarise(top = max(w), basis = first(basis), .groups = "drop")
moves <- gv |> filter(grepl("^CONST", contest)) |> group_by(county, year, group) |> summarise(v = sum(votes), .groups = "drop") |>
  left_join(intact, by = c("county", "year", "group")) |> group_by(year) |>
  summarise(pct_votes_intact = round(100 * sum(v[top >= 0.99], na.rm = TRUE) / sum(v), 1),
            pct_votes_pop_weighted = round(100 * sum(v[basis == "population"], na.rm = TRUE) / sum(v), 2),
            pct_votes_area_fallback = round(100 * sum(v[basis != "population"], na.rm = TRUE) / sum(v), 3))
print(moves)
write.csv(moves, file.path(out, "crosswalk_summary.csv"), row.names = FALSE)

## 7. Validate ------------------------------------------------------------------------------------------------
# (a) conservation: aligned = native - federal-only units - groups with nowhere to go, per county x contest x choice
cons <- nv |> group_by(county, contest, choice) |> summarise(native = sum(votes), federal_only = sum(votes[class == "federal_only"]), .groups = "drop") |>
  left_join(gv |> filter(!group %in% cw$group) |> group_by(county, contest, choice) |> summarise(lost = sum(votes), .groups = "drop"),
            by = c("county", "contest", "choice")) |>
  left_join(aligned |> group_by(county, contest, choice) |> summarise(aligned = sum(votes), .groups = "drop"), by = c("county", "contest", "choice")) |>
  mutate(lost = coalesce(lost, 0), aligned = coalesce(aligned, 0), gap = round(native - federal_only - lost) - aligned)
cat(sprintf("Conservation: %d county x contest x choice cells, max |gap| = %g votes; %g votes lost (no block, no overlap)\n",
            nrow(cons), max(abs(cons$gap)), sum(cons$lost)))
stopifnot(all(abs(cons$gap) <= 1))      # rounding of the lost share only
write.csv(cons, file.path(out, "validation_conservation.csv"), row.names = FALSE)
# (b) identity: the target election reproduces itself, precinct by precinct, wherever a 2024 unit is one polygon
one <- gpolys |> filter(year == TARGET) |> add_count(group) |> filter(n == 1)
id24 <- gv |> filter(year == TARGET) |> inner_join(select(one, county, group, target = PRECINCT), by = c("county", "group")) |>
  inner_join(filter(aligned, year == TARGET), by = c("county", "year", "target", "contest", "choice"))
cat(sprintf("Identity: 2024 reproduces itself in %d of %d single-polygon precinct x contest x choice cells\n",
            sum(id24$votes.x == id24$votes.y), nrow(id24)))
# (c) plausibility: precinct Democratic share, President 2020 (moved) against 2024 (native)
dshare <- aligned |> filter(contest %in% c("PRESIDENT_2020", "PRESIDENT_2024")) |> group_by(county, target, contest) |>
  summarise(dem = votes[choice == "DEM"] / sum(votes), n = sum(votes), .groups = "drop") |>
  pivot_wider(names_from = contest, values_from = c(dem, n)) |> filter(n_PRESIDENT_2024 >= 50)
cat(sprintf("Plausibility: precinct Dem share 2020 vs 2024, r = %.3f (%d precincts)\n",
            cor(dshare$dem_PRESIDENT_2020, dshare$dem_PRESIDENT_2024, use = "complete.obs"), nrow(dshare)))
fa <- read.csv("data/south_florida/federal_races.csv.gz") |> filter(question_id %in% c("PRESIDENT_2020", "PRESIDENT_2024")) |>
  select(unit_id, question_id, yes, total) |> pivot_wider(names_from = question_id, values_from = c(yes, total)) |> filter(total_PRESIDENT_2024 >= 50)
cat(sprintf("              the same on the areal panel, r = %.3f\n", cor(fa$yes_PRESIDENT_2020 / fa$total_PRESIDENT_2020,
            fa$yes_PRESIDENT_2024 / fa$total_PRESIDENT_2024, use = "complete.obs")))

## 8. Block population against areal weighting --------------------------------------------------------------------
# data/south_florida/ is the same returns on the same 2024 map, moved by areal weighting (votes spread evenly over each
# old unit's land). The two differ wherever people are not spread evenly: big, half-empty precincts at the urban edge.
blk_long <- aligned |> filter(grepl("^CONST", contest)) |> mutate(unit_id = paste(county, target, sep = "_")) |>
  group_by(unit_id, question_id = contest) |> summarise(yes = sum(votes[choice == "Yes"]), total = sum(votes), .groups = "drop")
areal <- read.csv("data/south_florida/ballot_measures.csv.gz", colClasses = c(unit_id = "character"))
cmp <- inner_join(blk_long, areal, by = c("unit_id", "question_id"), suffix = c("_block", "_areal")) |>
  mutate(year = as.integer(sub(".*_", "", question_id)))
cmp_year <- cmp |> filter(total_block >= 20, total_areal >= 20) |> group_by(year) |>
  summarise(r_yes_share = round(cor(yes_block / total_block, yes_areal / total_areal), 4),
            median_abs_diff_pts = round(100 * median(abs(yes_block / total_block - yes_areal / total_areal)), 2),
            pct_cells_over_5pts = round(100 * mean(abs(yes_block / total_block - yes_areal / total_areal) > 0.05), 2),
            median_ballot_ratio = round(median(total_block / total_areal), 3),
            pct_ballots_off_25pct = round(100 * mean(abs(total_block / total_areal - 1) > 0.25), 1))
print(cmp_year)
write.csv(cmp_year, file.path(out, "block_vs_areal_by_year.csv"), row.names = FALSE)

g <- read_units("south_florida")
diff_unit <- cmp |> filter(year < TARGET) |> group_by(unit_id) |>
  summarise(ballots_block = sum(total_block), ballots_areal = sum(total_areal),
            yes_diff = 100 * weighted.mean(abs(yes_block / pmax(total_block, 1) - yes_areal / pmax(total_areal, 1)), total_block))
gd <- left_join(g, diff_unit, by = "unit_id")
p1 <- ggplot(gd) + geom_sf(aes(fill = pmin(yes_diff, 5)), colour = NA) +
  scale_fill_viridis_c("Mean |difference|\nin Yes share,\n2012-22 (points)", option = "magma", direction = -1, limits = c(0, 5),
                       na.value = "grey70") +
  theme_void() + labs(title = "Where the two weightings disagree on Yes shares",
                      caption = "Grey: no 2020 population, so no earlier votes under block weighting")
p2 <- ggplot(diff_unit, aes(pmax(ballots_areal, 1), pmax(ballots_block, 1))) + geom_abline(colour = "grey60") +
  geom_point(alpha = 0.35, size = 0.8) + scale_x_log10(labels = scales::label_comma()) + scale_y_log10(labels = scales::label_comma()) +
  theme_minimal() + labs(x = "Areal weighting", y = "Block-population weighting",
       title = "Ballots on amendments, 2012-22, per 2024 precinct", caption = "Log scales; zero drawn at 1")
save_png(p1 + p2 + plot_layout(widths = c(1.1, 1)), "block_vs_areal.png", 13, 7)

## 9. Do the blocs care? -------------------------------------------------------------------------------------------
# Fit the same tempered EM (zeta = 0.3, K = 2..12, 10 starts) to both panels; compare the 5%-rule fits.
suppressPackageStartupMessages(library(Elections.BBMM))
as_bbmm <- function(long) {
  X <- long |> select(unit_id, question_id, yes) |> pivot_wider(names_from = question_id, values_from = yes) |> arrange(unit_id)
  M <- long |> select(unit_id, question_id, total) |> pivot_wider(names_from = question_id, values_from = total) |> arrange(unit_id)
  qs <- sort(setdiff(names(X), "unit_id"))
  X <- as.matrix(X[qs]) |> `rownames<-`(X$unit_id); M <- as.matrix(M[qs]) |> `rownames<-`(M$unit_id)
  keep <- rowSums(M, na.rm = TRUE) > 0
  bbmm_data(X[keep, ], M[keep, ])
}
cores <- max(1L, min(10L, parallel::detectCores() - 1L))
fit_file <- file.path(out, "em_selection.rds")
sel <- if (file.exists(fit_file)) readRDS(fit_file) else {
  x <- list(block = bbmm_em_select(as_bbmm(blk_long), K = 2:12, zeta = 0.3, n_starts = 10, seed = 2026, cores = cores),
            areal = bbmm_em_select(as_bbmm(areal),    K = 2:12, zeta = 0.3, n_starts = 10, seed = 2026, cores = cores))
  saveRDS(x, fit_file); x }
print(sel$block); print(sel$areal)
Kb <- sel$block$selected[["min_share_5%"]]; Ka <- sel$areal$selected[["min_share_5%"]]
d_blk <- as_bbmm(blk_long); d_ar <- as_bbmm(areal)
sb <- bloc_summary(sel$block$fits[[as.character(Kb)]], d_blk)
sa <- bloc_summary(sel$areal$fits[[as.character(Ka)]], d_ar)
both <- inner_join(select(sb$assignment, unit_id = unit, bloc_block = bloc), select(sa$assignment, unit_id = unit, bloc_areal = bloc), by = "unit_id")
cat(sprintf("5%% rule: K = %d (block) and %d (areal); ARI between the two maps = %.3f\n", Kb, Ka,
            adjusted_rand(both$bloc_block, both$bloc_areal)))
print(table(block = both$bloc_block, areal = both$bloc_areal))
write.csv(both, file.path(out, "blocs_block_vs_areal.csv"), row.names = FALSE)
save_png(plot_bloc_map(sb, g, title = sprintf("Blocs on the block-population panel (K = %d)", Kb)) |
         plot_bloc_map(sa, g, title = sprintf("Blocs on the areal panel (K = %d)", Ka)), "blocs_block_vs_areal.png", 14, 8)

## 10. Write the aligned panel in the repository's format ------------------------------------------------------------
fed <- aligned |> filter(grepl("^(PRESIDENT|US_SENATE)", contest)) |> mutate(unit_id = paste(county, target, sep = "_")) |>
  group_by(unit_id, question_id = contest) |> summarise(yes = sum(votes[choice == "DEM"]), total = sum(votes), .groups = "drop")
fmt <- function(d, type) d |> mutate(year = as.integer(sub(".*_", "", question_id)), type = type) |>
  select(unit_id, question_id, year, type, yes, total) |> arrange(year, question_id, unit_id)
write.csv(fmt(blk_long, "ballot_measures"), gzfile(file.path(out, "ballot_measures.csv.gz")), row.names = FALSE)
write.csv(fmt(fed, "federal"), gzfile(file.path(out, "federal_races.csv.gz")), row.names = FALSE)
cat("wrote", n_distinct(blk_long$unit_id), "precincts x", n_distinct(blk_long$question_id), "amendments and",
    n_distinct(fed$question_id), "federal races\n")
