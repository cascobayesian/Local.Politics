# South Florida alignment walkthrough, step 0: turn the raw downloads into the small files in inputs/.
#
# You do not need to run this: its outputs are in examples/south_florida/inputs/. It needs about 1 GB of
# raw files, laid out as below under SFL_RAW (default: the project's data/florida/raw):
#   Results_statewide/<year>/<CTY>_PctResults<year>*.txt   Florida Division of Elections precinct-level results,
#                                                          https://dos.fl.gov/elections/data-statistics/elections-data/precinct-level-election-results/
#   Shapefiles/fl_<year>/fl_<year>.shp                     VEST precinct shapefiles, 2012-2024 (Harvard Dataverse, "Voting and
#                                                          Election Science Team"); they embed the candidate votes used in step 3
#   tl_2020_12_tabblock20.shp (SFL_BLOCKS)                 2020 TIGER/Line blocks for Florida, with POP20
#   realign_2024_statewide/output/unit_map.rds             reporting unit -> polygon(s), from the statewide build's 02_resolve_ids.R
#
#   SFL_RAW=/path/to/data/florida/raw SFL_BLOCKS=/path/to/tl_2020_12_tabblock20.shp Rscript examples/south_florida/prepare_inputs.R
#
# Writes (inputs/):
#   native_votes.csv.gz     every reporting unit's votes on the 45 amendments and on President / US Senate / Governor (DEM, REP)
#   unit_map.csv.gz         how each reporting unit was placed on that year's polygons
#   polygon_tallies.csv.gz  VEST's embedded D and R votes per polygon, for the year's check office
#   blocks.csv.gz           every 2020 block: population, land area, and the precinct holding it in each map vintage
#   areal_fallback.csv.gz   polygons that hold no block: their area shares of the 2024 precincts
#   precinct_ids.csv.gz     every precinct id in every vintage (after dropping water, 0000)
suppressPackageStartupMessages({ library(dplyr); library(stringr); library(sf); library(tidyr) })
sf_use_s2(FALSE)

RAW    <- Sys.getenv("SFL_RAW", file.path(Sys.getenv("LOCAL_POLITICS_DIR", "~/Library/CloudStorage/Dropbox/Local.Political.Data"), "data/florida/raw"))
BLOCKS <- Sys.getenv("SFL_BLOCKS", "~/Library/Caches/tigris/tl_2020_12_tabblock20.shp")
OUT    <- "examples/south_florida/inputs"; dir.create(OUT, showWarnings = FALSE, recursive = TRUE)
COUNTIES <- c(BRO = "011", DAD = "086", PAL = "099")       # Broward, Miami-Dade, Palm Beach (county FIPS)
YEARS    <- seq(2012, 2024, by = 2)
CRS      <- 3087                                             # Florida GDL Albers, metres

## ---- DOS results -----------------------------------------------------------------------------------------
COLS <- c("County.Code","County","Election.Num","Election.Date","Election.Name","Unique","Precinct","Total.Voters",
          "Rep","Dem","Other","Election","District","Contest","Cast","Party","Reg.ID","DOE.Num","Votes")
read_results <- function(county, year) {
  f <- list.files(file.path(RAW, "Results_statewide", year), full.names = TRUE,
                  pattern = sprintf("^%s_PctResults%d[0-9]*(GEN|Gen)?\\.txt$", county, year))
  f <- f[!grepl("recount", f, ignore.case = TRUE)]; stopifnot(length(f) == 1)
  raw <- readBin(f, "raw", file.info(f)$size); raw <- raw[raw != as.raw(0)]      # some files carry NUL bytes
  lines <- strsplit(iconv(rawToChar(raw), "latin1", "UTF-8"), "\r?\n")[[1]]       # latin1; no quote parsing (names carry apostrophes)
  m <- do.call(rbind, lapply(strsplit(lines[nzchar(trimws(lines))], "\t", fixed = TRUE), `length<-`, 19))
  x <- as.data.frame(m, stringsAsFactors = FALSE); names(x) <- COLS
  x[] <- lapply(x, function(v) trimws(gsub('"', "", sub("^﻿|^ï»¿", "", v))))
  x$Votes <- suppressWarnings(as.numeric(x$Votes))
  x <- x[x$County.Code == county, ]; stopifnot(!anyNA(x$Votes))
  x
}
## statewide constitutional amendments only (county and municipal questions are dropped)
amendments <- function(x) {
  lab <- paste(x$Election, x$District)
  num <- str_match(lab, regex("Amendment(?: No\\.)?\\s*(\\d{1,2})\\b", ignore_case = TRUE))[, 2]
  local <- str_detect(lab, regex("\\b(county|charter|city|town|village|municipal|question|referendum|key biscayne|keybisc|aventura|opa-?locka)\\b", TRUE))
  x[!is.na(num) & !local, ] |>
    mutate(contest = sprintf("CONSTITUTIONAL_AMENDMENT_%s_%s", num[!is.na(num) & !local], year),
           choice = case_when(str_detect(Cast, regex("^yes", TRUE)) ~ "Yes", str_detect(Cast, regex("^no", TRUE)) ~ "No")) |>
    filter(!is.na(choice))
}
candidates <- function(x) {
  x |> filter(str_detect(Election, regex("^President|^United States Senator|^Governor", TRUE)), Party %in% c("DEM", "REP")) |>
    mutate(contest = paste(case_when(str_detect(Election, regex("^President", TRUE)) ~ "PRESIDENT",
                                     str_detect(Election, regex("^United States", TRUE)) ~ "US_SENATE", TRUE ~ "GOVERNOR"), year, sep = "_"),
           choice = Party)
}
native <- list()
for (cty in names(COUNTIES)) for (year in YEARS) {
  x <- read_results(cty, year)
  native[[paste(cty, year)]] <- bind_rows(amendments(x), candidates(x)) |>
    group_by(county = cty, year = year, Unique, Precinct, contest, choice) |> summarise(votes = sum(Votes), .groups = "drop")
}
native <- bind_rows(native)
write.csv(native, gzfile(file.path(OUT, "native_votes.csv.gz")), row.names = FALSE)

## ---- unit -> polygon placement (statewide resolver) ------------------------------------------------------
umap <- readRDS(file.path(RAW, "realign_2024_statewide/output/unit_map.rds")) |>
  filter(County %in% names(COUNTIES)) |> select(county = County, year = Year, Unique, Precinct, class, method, polys)
write.csv(umap, gzfile(file.path(OUT, "unit_map.csv.gz")), row.names = FALSE)

## ---- precinct maps -------------------------------------------------------------------------------------------
read_map <- function(cty, year) {
  st_read(file.path(RAW, sprintf("Shapefiles/fl_%d/fl_%d.shp", year, year)), quiet = TRUE) |>
    filter(COUNTY == cty) |> st_zm() |> st_transform(CRS) |> st_make_valid()
}
CHECK <- c(`2012` = "PRE", `2014` = "GOV", `2016` = "PRE", `2018` = "USS", `2020` = "PRE", `2022` = "USS", `2024` = "PRE")

blk_all <- st_read(path.expand(BLOCKS), quiet = TRUE) |> filter(COUNTYFP20 %in% COUNTIES)
blk_poly <- st_transform(blk_all, CRS)
blk <- st_drop_geometry(blk_all) |>
  transmute(block_id = GEOID20, county = names(COUNTIES)[match(COUNTYFP20, COUNTIES)], pop20 = POP20, aland = ALAND20,
            lon = as.numeric(INTPTLON20), lat = as.numeric(INTPTLAT20))
for (y in YEARS) blk[[paste0("p", y)]] <- NA_character_
pts <- st_as_sf(blk, coords = c("lon", "lat"), crs = 4269) |> st_transform(CRS)

tallies <- list(); ids <- list(); fallback <- list(); how <- list()
for (cty in names(COUNTIES)) {
  ib <- which(blk$county == cty)
  maps <- lapply(setNames(YEARS, YEARS), function(y) {
    m <- read_map(cty, y)
    off <- CHECK[[as.character(y)]]; yy <- substr(y, 3, 4)
    dcol <- grep(sprintf("^G%s%sD", yy, off), names(m), value = TRUE); rcol <- grep(sprintf("^G%s%sR", yy, off), names(m), value = TRUE)
    stopifnot(length(dcol) == 1, length(rcol) == 1)
    tallies[[paste(cty, y)]] <<- st_drop_geometry(m) |> group_by(PRECINCT) |>
      summarise(vest_dem = sum(.data[[dcol]]), vest_rep = sum(.data[[rcol]]), .groups = "drop") |>
      mutate(county = cty, year = y, office = off, .before = 1)
    m |> filter(PRECINCT != "0000") |> group_by(PRECINCT) |> summarise(.groups = "drop")   # 0000 = water; dissolve split parts
  })
  for (y in YEARS) {
    m <- maps[[as.character(y)]]
    ids[[paste(cty, y)]] <- data.frame(county = cty, year = y, PRECINCT = m$PRECINCT)
    ## 1. internal point in polygon
    hit <- st_intersects(pts[ib, ], m)
    a <- vapply(hit, function(h) if (length(h)) m$PRECINCT[h[1]] else NA_character_, "")
    method <- ifelse(is.na(a), NA, "point")
    ## 2. block polygon's largest overlap
    miss <- which(is.na(a))
    if (length(miss)) {
      ov <- suppressWarnings(st_intersection(select(blk_poly[ib[miss], ], GEOID20), m))
      if (nrow(ov)) {
        ov$a <- as.numeric(st_area(ov))
        best <- st_drop_geometry(ov) |> group_by(GEOID20) |> slice_max(a, n = 1, with_ties = FALSE)
        k <- match(blk$block_id[ib[miss]], best$GEOID20)
        a[miss] <- best$PRECINCT[k]; method[miss[!is.na(k)]] <- "overlap"
      }
    }
    ## 3. nearest polygon within 100 m
    miss <- which(is.na(a))
    if (length(miss)) {
      nn <- st_nearest_feature(pts[ib[miss], ], m)
      d <- as.numeric(st_distance(pts[ib[miss], ], m[nn, ], by_element = TRUE))
      ok <- d <= 100
      a[miss[ok]] <- m$PRECINCT[nn[ok]]; method[miss[ok]] <- "nearest"
    }
    blk[[paste0("p", y)]][ib] <- a
    how[[paste(cty, y)]] <- data.frame(county = cty, year = y, method = coalesce(method, "none"), pop = blk$pop20[ib]) |>
      group_by(county, year, method) |> summarise(blocks = n(), pop = sum(pop), .groups = "drop")
    ## polygons holding no block at all: area shares of the 2024 precincts
    empty <- setdiff(m$PRECINCT, a)
    if (length(empty) && y != 2024) {
      ov <- suppressWarnings(st_intersection(filter(m, PRECINCT %in% empty), select(maps[["2024"]], target = PRECINCT)))
      ov$a <- as.numeric(st_area(ov))
      fallback[[paste(cty, y)]] <- st_drop_geometry(ov) |> group_by(PRECINCT) |> mutate(share = a / sum(a)) |>
        filter(share > 1e-6) |> ungroup() |> transmute(county = cty, year = y, PRECINCT, target, share = round(share, 6))
    }
  }
}
blk <- blk |> select(-lon, -lat)
write.csv(blk, gzfile(file.path(OUT, "blocks.csv.gz")), row.names = FALSE)
write.csv(bind_rows(tallies), gzfile(file.path(OUT, "polygon_tallies.csv.gz")), row.names = FALSE)
write.csv(bind_rows(ids), gzfile(file.path(OUT, "precinct_ids.csv.gz")), row.names = FALSE)
write.csv(bind_rows(fallback), gzfile(file.path(OUT, "areal_fallback.csv.gz")), row.names = FALSE)
how <- bind_rows(how); print(as.data.frame(how))
write.csv(how, file.path(OUT, "block_assignment_methods.csv"), row.names = FALSE)
