# Read one place's model-ready data as an Elections.BBMM data set, and its unit boundaries.
#   source("R/read_place.R")
#   d <- read_place("sf")                          # ballot measures (the default)
#   d <- read_place("sf", "federal_races")         # President and US Senate (yes = Democratic votes)
#   d <- read_place("sf", "combined")              # both
#   g <- read_units("sf")                          # sf object with unit_id, for plot_bloc_map()

read_place <- function(place, what = c("ballot_measures", "federal_races", "combined"), root = "data") {
  what <- match.arg(what)
  long <- utils::read.csv(file.path(root, place, paste0(what, ".csv.gz")),
                          colClasses = c(unit_id = "character", question_id = "character"))
  q <- utils::read.csv(file.path(root, place, "questions.csv"), colClasses = "character")
  units <- sort(unique(long$unit_id))
  qs <- q$question_id[q$question_id %in% long$question_id]          # questions.csv order: measures, then races, by year
  X <- M <- matrix(NA_integer_, length(units), length(qs), dimnames = list(units, qs))
  ix <- cbind(match(long$unit_id, units), match(long$question_id, qs))
  X[ix] <- long$yes; M[ix] <- long$total
  lab <- ifelse(q$label[match(qs, q$question_id)] == "", qs, q$label[match(qs, q$question_id)])
  Elections.BBMM::bbmm_data(X, M, labels = lab)
}

read_units <- function(place, root = "data") {
  f <- file.path(root, place, "units.gpkg")
  if (!file.exists(f)) f <- paste0("/vsizip/", normalizePath(file.path(root, place, "units.gpkg.zip")), "/units.gpkg")
  sf::st_read(f, quiet = TRUE)
}
