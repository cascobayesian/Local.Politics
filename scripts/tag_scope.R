# Adds a `scope` column to every data/<place>/questions.csv: federal, statewide, or the local level of a ballot
# measure. Most places' measures are all statewide; NYC, Chicago, Minneapolis-St. Paul, Philadelphia and Salt Lake
# County mix statewide and local questions in one panel, and Washington, DC's are District measures.
# Levels for Salt Lake County follow code/slc/01_build_inputs.R (scope_of) in the Local Politics project.
#     Rscript scripts/tag_scope.R

suppressPackageStartupMessages(library(tidyverse))
slc_county <- c("loc_2012_county_proposition_1", "loc_2014_county_proposal_no_1", "loc_2015_salt_lake_county_proposition_1",
                "loc_2016_county_proposition_a", "loc_2024_salt_lake_county_jail_bond", "loc_2024_zap_proposition_8")
slc_city <- c("loc_2011_s_salt_lake_bond", "loc_2015_herriman_hills_initiative_prp_7", "loc_2015_south_salt_lake_special_bond",
              "loc_2017_west_jordan_city_bond", "loc_2017_west_jordan_city_proposition_10", "loc_2018_holladay_proposition_14",
              "loc_2018_slc_streets_reconstruction_bond", "loc_2022_bluffdale_city_council_referendum", "loc_2022_slc_bond_proposition",
              "loc_2024_cottonwood_heights_city_bond")
nyc_state <- c("2014_ballot_02", "2014_ballot_03", "2017_ballot_01", "2017_ballot_02", "2017_ballot_03", "2021_ballot_01",
               "2021_ballot_02", "2021_ballot_03", "2021_ballot_04", "2021_ballot_05", "2022_ballot_01", "2023_ballot_01",
               "2023_ballot_02", "2024_ballot_01")
scope_of <- function(place, id, type) case_when(
  type == "federal" ~ "federal",
  place == "dc" ~ "district (DC)",
  place == "nyc" ~ if_else(id %in% nyc_state, "statewide", "city"),
  place == "chicago" ~ if_else(startsWith(id, "2015_"), "city", "statewide"),
  place == "msp" ~ case_when(str_detect(id, "_mn_") ~ "statewide", str_detect(id, "schools_") ~ "school district", TRUE ~ "city"),
  place == "philadelphia" ~ if_else(str_detect(id, "_pa_"), "statewide", "city"),
  place == "slc" ~ case_when(startsWith(id, "st_") ~ "statewide", id %in% slc_county ~ "county", id %in% slc_city ~ "city",
                             TRUE ~ "school or special district"),
  TRUE ~ "statewide")

for (p in list.dirs("data", full.names = FALSE, recursive = FALSE)) {
  f <- file.path("data", p, "questions.csv"); if (!file.exists(f)) next
  q <- read_csv(f, col_types = cols(.default = "c")) |> select(-any_of("scope"))
  q <- q |> mutate(scope = scope_of(p, question_id, type), .after = type)
  write_csv(q, f, na = "")
  s <- count(filter(q, type == "ballot_measure"), scope)
  if (nrow(s) > 1 || s$scope[1] != "statewide") cat(p, ":", paste(s$scope, s$n, collapse = ", "), "\n")
}
