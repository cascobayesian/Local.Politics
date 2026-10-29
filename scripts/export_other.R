# Writes data/<place>/other/: datasets beyond the statewide model-ready files, on the same units as the
# place's main files (unit_id matches ballot_measures.csv.gz). Local referenda share one layout:
#   local_measures.csv.gz   unit_id, question_id, year, scope, yes, total
#   local_questions.csv     question_id, year, scope, title, units, votes, yes_share
# Candidate contests used in the paper are copied in their own layouts (see data/<place>/other/README.md).
#     LOCAL_POLITICS_DIR=/path/to/Local.Political.Data Rscript scripts/export_other.R

suppressPackageStartupMessages(library(tidyverse))
proj <- Sys.getenv("LOCAL_POLITICS_DIR", "/Users/jobrien/Library/CloudStorage/Dropbox/Local.Political.Data")
P <- function(...) file.path(proj, ...)
main_units <- function(p) unique(read_csv(file.path("data", p, "ballot_measures.csv.gz"), col_types = cols(unit_id = "c"))$unit_id)
odir <- function(p) { d <- file.path("data", p, "other"); dir.create(d, showWarnings = FALSE, recursive = TRUE); d }
# fractional allocations (areal or population crosswalks) rounded to whole votes by largest remainder within question
lr_round <- function(x, g) {
  tibble(x, g, i = seq_along(x)) |> group_by(g) |>
    mutate(f = floor(x), r = x - f, add = rank(-r, ties.method = "first") <= round(sum(x)) - sum(f), v = f + add) |>
    ungroup() |> arrange(i) |> pull(v) |> as.integer()
}
write_local <- function(p, d, titles) {
  u <- main_units(p)
  d <- d |> filter(total > 0)
  cat(sprintf("%-14s local: %d questions, %d units (%d on the main map), %d cells\n", p, n_distinct(d$question_id),
              n_distinct(d$unit_id), length(intersect(unique(d$unit_id), u)), nrow(d)))
  stopifnot(all(d$yes <= d$total), !anyDuplicated(d[c("unit_id", "question_id")]))
  write_csv(d |> select(unit_id, question_id, year, scope, yes, total), file.path(odir(p), "local_measures.csv.gz"))
  q <- d |> group_by(question_id, year, scope) |>
    summarise(units = n(), votes = sum(total), yes_share = round(sum(yes) / sum(total), 4), .groups = "drop") |>
    left_join(titles, by = "question_id") |> relocate(title, .after = scope) |> arrange(year, scope, question_id)
  write_csv(q, file.path(odir(p), "local_questions.csv"), na = "")
}

## Massachusetts: the paper's local questions (Appendix "Massachusetts local ballot questions"), 2012-2024, on the
## 2022 precincts. 2022-24 as reported; 2012-20 allocated by the statewide panel's areal crosswalks
## (output/ma_case/local_2012_2020_on_2022.csv), kept where at least half the precinct's area voted on it.
norm_town <- function(x) toupper(x) |> str_replace("^E\\. ", "EAST ") |> str_replace("^W\\. ", "WEST ") |>
  str_replace("^N\\. ", "NORTH ") |> str_replace("^S\\. ", "SOUTH ") |>
  str_replace("^MANCHESTER-BY-THE-SEA$", "MANCHESTER") |> str_remove_all("[^A-Z]")
scope_ma <- function(d) if_else(str_detect(d, "District Question"), "district", "municipal")
q <- read_csv(P("data/ma_precinct/ma_questions_precinct.csv"), show_col_types = FALSE, guess_max = 1e5,
              col_types = cols(ward = "c", pct = "c"))
ma_2224 <- q |> filter(year >= 2022, !str_detect(description, "^Statewide"), yes + no > 0, locality != "TOTALS") |>
  transmute(unit_id = paste(norm_town(locality), replace_na(ward, ""), pct, sep = "|"), question_id = as.character(question_id),
            year, scope = scope_ma(description), title = description, yes = as.integer(yes), total = as.integer(yes + no))
ma_1220 <- read_csv(P("output/ma_case/local_2012_2020_on_2022.csv"), col_types = cols(question_id = "c", unit_id = "c")) |>
  filter(yes + no > 0, coverage >= 0.5) |>
  mutate(t = lr_round(yes + no, question_id)) |>
  transmute(unit_id, question_id, year, scope = scope_ma(description), title = description,
            yes = pmin(as.integer(round(yes)), t), total = t)
ma <- bind_rows(ma_1220, ma_2224) |> group_by(unit_id, question_id, year, scope, title) |>
  summarise(yes = sum(yes), total = sum(total), .groups = "drop")
write_local("ma", ma, distinct(ma, question_id, title))
file.copy(P("output/ma_case/local_questions_coded_2012_2024.csv"), file.path(odir("ma"), "local_questions_coded.csv"), overwrite = TRUE)

## Portland (Multnomah County): 179 county, city, school and special-district measures, 2012-2026, on the 2022 map
pk <- read_csv(P("data/pdx/Redo/Final/local_measures/output/local_measures_column_key.csv"), show_col_types = FALSE)
pw <- read_csv(P("data/pdx/Redo/Final/local_measures_2012_2026_on_2022_precincts_wide.csv"), col_types = cols(PRECINCT = "c"))
pdx <- pw |> pivot_longer(-PRECINCT, names_to = c("question_id", "side"), names_pattern = "(.*)_(Yes|No)$", values_to = "v") |>
  pivot_wider(names_from = side, values_from = v) |> filter(!is.na(Yes), !is.na(No)) |>
  transmute(unit_id = PRECINCT, question_id, year = as.integer(str_extract(question_id, "(19|20)\\d\\d$")),
            yes = as.integer(Yes), total = as.integer(Yes + No))
pk_t <- pk |> transmute(question_id = sub("_Yes$", "", yes_column), title = contest_raw,
                        scope = str_to_title(str_remove(contest_raw, "^\\S+\\s+"))) |> distinct(question_id, .keep_all = TRUE)
pdx <- pdx |> left_join(select(pk_t, question_id, scope), by = "question_id") |> mutate(scope = coalesce(scope, "local"))
write_local("portland", pdx, select(pk_t, question_id, title))

## Columbus: 57 Franklin County, City of Columbus, Columbus City Schools and library measures on the same 159 wards
ck <- read_csv(P("data/Columbus/final/columbus_ballot_columns.csv"), show_col_types = FALSE) |> filter(scope != "Ohio statewide")
cw <- read_csv(P("data/Columbus/final/columbus_ward_ballot.csv"), col_types = cols(ward_id = "c"))
cbus <- map_dfr(seq_len(nrow(ck)), \(i) tibble(unit_id = paste0("W", cw$ward_id), question_id = ck$column_stub[i],
  year = as.integer(substr(ck$date[i], 1, 4)), scope = ck$scope[i],
  yes = as.integer(round(cw[[ck$yes_column[i]]])), total = as.integer(round(cw[[ck$yes_column[i]]] + cw[[ck$no_column[i]]])))) |>
  filter(!is.na(total))
write_local("columbus", cbus, transmute(ck, question_id = column_stub, title = contest_title))

## Austin (Travis County): 22 county, city, school and college-district measures, 2022-2025, on the same precincts
tk <- read_csv(P("data/Travis/final/archive/all_measures_53_20261001/data/travis_ballot_column_key.csv"), show_col_types = FALSE) |>
  filter(!str_detect(jurisdiction, regex("^(state|texas)", ignore_case = TRUE)))
tw <- read_csv(P("data/Travis/final/archive/all_measures_53_20261001/data/travis_ballot.csv"), col_types = cols(join_id = "c"))
aus <- map_dfr(seq_len(nrow(tk)), \(i) tibble(unit_id = tw$join_id, question_id = tk$contest_id[i], year = as.integer(tk$year[i]),
  scope = tk$jurisdiction[i], yes = as.integer(tw[[tk$first_column[i]]]),
  total = as.integer(tw[[tk$first_column[i]]] + tw[[tk$second_column[i]]]))) |> filter(!is.na(total))
write_local("austin", aus, transmute(tk, question_id = contest_id, title = contest_title))

## Louisiana: 8,150 parish, municipal and special-district propositions, 2000-2024, on the same 2024 precincts
lm <- read_csv(P("data/louisiana/final/aligned_2024/local_measures.csv.gz"), show_col_types = FALSE,
               col_types = cols(contest_id = "c", join_id = "c")) |> filter(choice %in% c("YES", "NO"))
la <- lm |> group_by(join_id, contest_id, choice) |> summarise(v = sum(integer_votes), .groups = "drop") |>
  pivot_wider(names_from = choice, values_from = v, values_fill = 0) |>
  transmute(unit_id = join_id, question_id = contest_id, year = as.integer(substr(contest_id, 1, 4)), scope = "local",
            yes = as.integer(YES), total = as.integer(YES + NO))
la_t <- lm |> distinct(question_id = contest_id, title = paste0(title, " (", parish, ")")) |> distinct(question_id, .keep_all = TRUE)
write_local("la", la, la_t)

## Candidate contests the paper uses to test whether blocs and coalitions recur (copied as built)
cp <- function(from, p, to) { ok <- file.copy(P(from), file.path(odir(p), to), overwrite = TRUE); stopifnot(ok) }
for (f in c("mayor", "comptroller", "public_advocate")) {
  cp(sprintf("data/NYC/raw/2025_primary/nyc_%s_2025_ed.csv", f), "nyc", sprintf("primary_2025_%s.csv", f))
  cp(sprintf("data/NYC/raw/2021_primary/nyc_%s_2021_on2024.csv", f), "nyc", sprintf("primary_2021_%s.csv", f))
}
cp("data/NYC/raw/2025_general/nyc_mayor_general_2025_ed.csv", "nyc", "general_2025_mayor.csv")
write_csv(read_csv(P("output/ma_case/primaries_unit_shares.csv"), show_col_types = FALSE) |> select(-bloc, -N),
          file.path(odir("ma"), "primaries_2022_2024.csv.gz"))
oc <- read_csv(P("output/la_sf/durable_factions/outcomes_long.csv"), show_col_types = FALSE, col_types = cols(unit_id = "c"))
for (k in c("sf", "la_county")) {
  write_csv(filter(oc, place == if (k == "sf") "sf" else "la") |> select(-place), file.path(odir(k), "candidate_contests.csv.gz"))
}
