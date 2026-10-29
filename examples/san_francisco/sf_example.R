# Worked example: San Francisco's voting blocs from 64 California propositions (2012-2022) in 510 precincts.
# Run from the repository root:   Rscript examples/san_francisco/sf_example.R
# Needs Elections.BBMM (remotes::install_github("cascobayesian/Elections.BBMM")), sf and ggplot2.
# Writes figures and tables to examples/san_francisco/output/. About 5 minutes on 10 cores.

suppressPackageStartupMessages({ library(Elections.BBMM); library(ggplot2) })
source("R/read_place.R")
out <- "examples/san_francisco/output"; dir.create(out, showWarnings = FALSE, recursive = TRUE)
save_png <- function(p, f, w = 9, h = 6) ggsave(file.path(out, f), p, width = w, height = h, dpi = 150, bg = "white")
cores <- max(1L, min(10L, parallel::detectCores() - 1L))

## 1. Data ------------------------------------------------------------------------------------------------
d   <- read_place("sf")                    # ballot measures: Yes votes and Yes + No totals, precinct x proposition
fed <- read_place("sf", "federal_races")   # President and US Senate: Democratic votes and Dem + Rep totals
g   <- read_units("sf")                    # 2024 precinct boundaries
print(d)

## 2. Fit: tempered EM over K = 2..14 ---------------------------------------------------------------------
sel_file <- file.path(out, "em_selection.rds")             # cached: the selection is the slow step
sel <- if (file.exists(sel_file)) readRDS(sel_file) else {
  x <- bbmm_em_select(d, K = 2:14, zeta = 0.3, n_starts = 10, seed = 2026, cores = cores); saveRDS(x, sel_file); x }
print(sel)
save_png(plot_em_selection(sel), "em_selection.png", h = 4.5)
K <- sel$selected[["min_share_5%"]]
fit <- sel$fits[[as.character(K)]]
s <- bloc_summary(fit, d)
print(s)

## 3. Where the blocs are, and what they vote for ---------------------------------------------------------
# the city's precincts include the Farallon Islands, 40 km offshore: crop them out of the map, as the atlas does
sf::sf_use_s2(FALSE)                                         # a plain longitude-latitude box
g_city <- suppressWarnings(sf::st_crop(g, c(xmin = -122.53, ymin = 37.70, xmax = -122.35, ymax = 37.84)))
save_png(plot_bloc_map(s, g_city, title = sprintf("San Francisco: %d voting blocs from 64 propositions", K)), "bloc_map.png", 10, 8)
save_png(plot_js_pca(d, s), "js_pca.png", 13, 6)
dq <- distinctive_questions(s, n = 3)
print(dq)
top <- unique(unlist(lapply(split(dq$question, dq$bloc), head, 2)))
save_png(plot_bloc_profiles(s, questions = top), "bloc_profiles.png", 10, 6)

## 4. Blocs against national partisanship ----------------------------------------------------------------
# Normal vote: each precinct's mean two-party Democratic share over the presidential and Senate races.
nv <- rowMeans(fed$X / fed$M, na.rm = TRUE)
bloc <- s$assignment$bloc[match(d$units, s$assignment$unit)]
stopifnot(!anyNA(bloc))
wcor <- function(x, y, w) { ok <- !is.na(x) & !is.na(y) & !is.na(w); stats::cov.wt(cbind(x[ok], y[ok]), w[ok], cor = TRUE)$cor[1, 2] }
adj_r2 <- function(y, X, w) {                                 # ballot-weighted adjusted R^2 of y on the columns of X
  dd <- data.frame(.y = y, .w = w, X); dd <- dd[complete.cases(dd), ]
  summary(lm(.y ~ . - .w, data = dd, weights = .w))$adj.r.squared
}
bins <- cut(rank(nv, ties.method = "first"), K, labels = FALSE)          # K equal-count bins of the normal vote
by_q <- do.call(rbind, lapply(seq_along(d$questions), function(j) {
  y <- d$X[, j] / d$M[, j]; w <- d$M[, j]
  data.frame(question = d$labels[j], r2_normal = wcor(y, nv, w)^2,
             r2_bins = adj_r2(y, data.frame(bin = factor(bins)), w), r2_blocs = adj_r2(y, data.frame(bloc = factor(bloc)), w),
             gain = adj_r2(y, data.frame(nv, bloc = factor(bloc)), w) - adj_r2(y, data.frame(nv), w))
}))
by_q <- by_q[order(-by_q$gain), ]
write.csv(by_q, file.path(out, "questions_vs_partisanship.csv"), row.names = FALSE)
cat(sprintf("\nMedian r^2 with the normal vote: %.2f; %d of %d propositions below 0.25\n",
            median(by_q$r2_normal), sum(by_q$r2_normal < 0.25), nrow(by_q)))
cat(sprintf("Median adjusted R^2: %d bins of the normal vote %.2f, %d blocs %.2f; blocs explain more on %d of %d\n",
            K, median(by_q$r2_bins), K, median(by_q$r2_blocs), sum(by_q$r2_blocs > by_q$r2_bins), nrow(by_q)))
print(head(by_q, 5), digits = 2)

blocs <- data.frame(bloc = sort(unique(bloc)))
blocs$precincts <- as.vector(table(factor(bloc, blocs$bloc)))
blocs$normal_vote <- sapply(blocs$bloc, function(k) round(100 * weighted.mean(nv[bloc == k], rowSums(fed$M, na.rm = TRUE)[bloc == k]), 1))
write.csv(blocs, file.path(out, "blocs.csv"), row.names = FALSE)
print(blocs)

p <- ggplot(by_q, aes(r2_bins, r2_blocs)) + geom_abline(colour = "grey60") + geom_point(alpha = 0.7) +
  coord_equal(xlim = c(0, 1), ylim = c(0, 1)) + theme_minimal() +
  labs(x = sprintf("Adjusted R² from %d bins of the normal vote", K), y = sprintf("Adjusted R² from %d blocs", K),
       title = "Each point is one proposition", subtitle = "Above the line: the blocs explain more than national partisanship")
save_png(p, "blocs_vs_partisanship.png", 6, 6)

## 5. The same model on ballot measures and federal races together ------------------------------------------
both <- read_place("sf", "combined")
fit_both <- bbmm_em(both, K = K, zeta = 0.3, n_starts = 10, seed = 2026, cores = cores)
s_both <- bloc_summary(fit_both, both)
ari <- function(a, b) { t <- table(a, b); n <- sum(t); s2 <- function(x) sum(choose(x, 2))
  e <- s2(rowSums(t)) * s2(colSums(t)) / choose(n, 2); (s2(t) - e) / ((s2(rowSums(t)) + s2(colSums(t))) / 2 - e) }
cat(sprintf("\nAdjusted Rand index, blocs from measures only vs measures + federal races: %.2f\n",
            ari(bloc, s_both$assignment$bloc[match(d$units, s_both$assignment$unit)])))
saveRDS(list(fit = fit, summary = s, fit_combined = fit_both), file.path(out, "sf_fits.rds"))
