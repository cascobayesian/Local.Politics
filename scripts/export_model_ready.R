# Writes the model-ready files in data/<place>/ from the project's per-place bundles (the same bundles behind
# the atlas and the paper's tables: output/atlas/overview/bundles/<place>/ in the Local Politics project).
#   ballot_measures.csv.gz   ballot measures:            unit_id, question_id, year, type, yes, total
#   federal_races.csv.gz     President and US Senate:    same columns; yes = Democratic votes, total = Dem + Rep
#   combined.csv.gz          the two together
#   questions.csv            one row per question or race: type, year, label (where one exists), units, votes, yes share
#   units.gpkg               unit boundaries (simplified to 10 m; EPSG:4326); zipped to units.gpkg.zip when over 25 MB
# Every count is a whole number of votes. Cells with no votes (a question not on a unit's ballot) are left out.
#     LOCAL_POLITICS_DIR=/path/to/Local.Political.Data Rscript scripts/export_model_ready.R [place ...]

suppressPackageStartupMessages({ library(tidyverse); library(sf) })
sf_use_s2(FALSE)
proj <- Sys.getenv("LOCAL_POLITICS_DIR", "/Users/jobrien/Library/CloudStorage/Dropbox/Local.Political.Data")
bundles <- file.path(proj, "output", "atlas", "overview", "bundles")
out_root <- "data"
places <- commandArgs(TRUE)
if (!length(places)) places <- list.dirs(bundles, full.names = FALSE, recursive = FALSE)

# hand-entered question labels from the paper's analysis (output/table2/<dir>/questions.csv); metro cut-outs and
# the statewide California fit share their parent's question ids
label_dir <- c(chicago = "chicago", co = "colorado", denver = "colorado", dc = "dc", la_county = "la", ca = "la",
               san_diego = "la", ma = "ma_precinct", boston = "ma_precinct", me = "maine", nyc = "nyc",
               portland = "portland", sf = "sf", south_florida = "south_florida")
labels_for <- function(p) {
  f <- file.path(proj, "output", "table2", label_dir[p], "questions.csv")
  if (is.na(label_dir[p]) || !file.exists(f)) return(tibble(question_id = character(), label = character()))
  read_csv(f, show_col_types = FALSE, col_types = cols(.default = "c")) |> select(question_id, label)
}
as_count <- function(v) { stopifnot(all(is.na(v) | v == round(v))); as.integer(round(v)) }

# South Florida's own bundle is built on an older alignment with a known weighting bug (Broward 2012 at about half
# its votes), so its files are cut from the corrected statewide Florida panel: the precincts of Miami-Dade (DAD),
# Broward (BRO) and Palm Beach (PAL).
source_of <- c(south_florida = "fl")
keep_units <- list(south_florida = function(id) sub("_.*", "", id) %in% c("DAD", "BRO", "PAL"))

for (p in places) {
  src <- if (is.na(source_of[p])) p else source_of[[p]]
  b <- file.path(bundles, src); m <- jsonlite::fromJSON(file.path(b, "meta.json"))
  keep <- keep_units[[p]] %||% function(id) TRUE
  od <- file.path(out_root, p); dir.create(od, showWarnings = FALSE, recursive = TRUE)

  v <- read_csv(file.path(b, "votes.csv"), col_types = cols(unit_id = "c", question_id = "c", .default = "d")) |>
    filter(!is.na(n), n > 0, keep(unit_id))
  if (identical(m$success_side, "no")) v <- mutate(v, success = n - success)    # South Florida stores the No count
  # the bundle takes the first 19xx/20xx run in the id as the year, which reads Washington's INITIATIVE_2066_2024 as 2066
  v <- mutate(v, year = if_else(year > 2030, as.numeric(str_extract(question_id, "(19|20)\\d\\d(?!.*(19|20)\\d\\d)")), year))
  ballot <- v |> transmute(unit_id, question_id, year = as.integer(year), type = "ballot_measure",
                           yes = as_count(success), total = as_count(n))

  fed <- read_csv(file.path(b, "partisan.csv"), col_types = cols(unit_id = "c", contest = "c", office = "c", .default = "d")) |>
    filter(!is.na(dem), !is.na(rep), dem + rep > 0, keep(unit_id)) |>
    transmute(unit_id, question_id = contest, year = as.integer(year), type = "federal",
              yes = as_count(dem), total = as_count(dem + rep))
  stopifnot(!anyDuplicated(ballot[c("unit_id", "question_id")]), !anyDuplicated(fed[c("unit_id", "question_id")]),
            all(ballot$yes <= ballot$total), all(fed$yes <= fed$total), !length(intersect(ballot$question_id, fed$question_id)))
  both <- bind_rows(ballot, fed)

  write_csv(ballot, file.path(od, "ballot_measures.csv.gz"))
  write_csv(fed, file.path(od, "federal_races.csv.gz"))
  write_csv(both, file.path(od, "combined.csv.gz"))

  q <- both |> group_by(question_id, year, type) |>
    summarise(units = n(), votes = sum(total), yes_share = round(sum(yes) / sum(total), 4), .groups = "drop") |>
    left_join(labels_for(p), by = "question_id") |> relocate(label, .after = type) |> arrange(type, year, question_id)
  write_csv(q, file.path(od, "questions.csv"), na = "")

  gb <- if (file.exists(file.path(b, "units.gpkg"))) b else file.path(bundles, m$parent)   # metro cut-outs: the parent's map
  g <- st_read(file.path(gb, "units.gpkg"), quiet = TRUE)
  idc <- intersect(c("unit_id", "id"), names(g))[1]; stopifnot(!is.na(idc))
  g <- g |> transmute(unit_id = as.character(.data[[idc]])) |> filter(unit_id %in% both$unit_id) |> st_zm()
  bad <- !st_is_valid(g); if (any(bad)) st_geometry(g)[bad] <- st_make_valid(st_geometry(g)[bad])   # repair only the few that need it
  g <- g |> st_transform(3857) |> st_simplify(preserveTopology = TRUE, dTolerance = 10) |> st_transform(4326)
  g <- g[!st_is_empty(g), ]
  if (anyDuplicated(g$unit_id)) g <- g |> group_by(unit_id) |> summarise(.groups = "drop")   # precincts split across rows
  gp <- file.path(od, "units.gpkg"); unlink(c(gp, paste0(gp, ".zip")))
  st_write(g, gp, quiet = TRUE)
  if (file.size(gp) > 25e6) { zip(paste0(gp, ".zip"), gp, flags = "-jq9"); file.remove(gp) }

  cat(sprintf("%-15s units %5d (map %5d)  measures %3d  federal %2d  cells %7d\n", p, n_distinct(both$unit_id),
              nrow(g), n_distinct(ballot$question_id), n_distinct(fed$question_id), nrow(both)))
}
