# Worked example: Portland (Multnomah County), 41 Oregon statewide measures (2012-2024) in 107 precincts,
# fit with the fully Bayesian model (stepping-stone SMC) and summarised by a representative coloring.
# Run from the repository root:   Rscript examples/portland/portland_example.R
# Needs Elections.BBMM (remotes::install_github("cascobayesian/Elections.BBMM")), sf, ggplot2, patchwork, cluster, dplyr.
# Writes figures and tables to examples/portland/output/. The stepping-stone runs (4 per K) take about 40 minutes
# on 12 threads the first time and are cached in output/evidence_zeta0.8*.rds; everything else takes about a minute.

suppressPackageStartupMessages({ library(Elections.BBMM); library(ggplot2); library(patchwork) })
source("R/read_place.R")
out <- "examples/portland/output"; dir.create(out, showWarnings = FALSE, recursive = TRUE)
save_png <- function(p, f, w = 9, h = 6) ggsave(file.path(out, f), p, width = w, height = h, dpi = 150, bg = "white")
threads <- max(1L, min(12L, parallel::detectCores() - 1L))
cache <- function(f, expr) { f <- file.path(out, f); if (file.exists(f)) readRDS(f) else { x <- expr; saveRDS(x, f); x } }
ari <- adjusted_rand

## 1. Data ------------------------------------------------------------------------------------------------
d   <- read_place("portland")                    # 107 precincts x 41 measures: Yes votes and Yes + No totals
fed <- read_place("portland", "federal_races")   # President 2012-24, US Senate 2014-22: Dem votes, Dem + Rep
g   <- read_units("portland")                    # 2022 precinct map
print(d)
# Normal vote: each precinct's mean two-party Democratic share over the eight federal races (as in the paper);
# a bloc's normal vote is the plain mean over its precincts
nv <- rowMeans(fed$X / fed$M, na.rm = TRUE)[d$units]

## 2. The coarsening power zeta, by tempered EM -------------------------------------------------------------
# With only 107 precincts, the paper's usual zeta = 0.3 leaves too little information to separate more than
# three blocs; zeta = 0.8 lets the data speak a little louder. EM is fast here, so look at both.
sel <- cache("em_selection.rds", lapply(c(`0.3` = 0.3, `0.8` = 0.8), function(z)
  bbmm_em_select(d, K = 2:10, zeta = z, n_starts = 10, seed = 2026, cores = threads)))
for (z in names(sel)) { cat(sprintf("\n== tempered EM, zeta = %s\n", z)); print(sel[[z]]) }
save_png(plot_em_selection(sel[["0.3"]]) + ggtitle("Tempered EM, zeta = 0.3") |
         plot_em_selection(sel[["0.8"]]) + ggtitle("Tempered EM, zeta = 0.8"), "em_selection.png", 13, 4.5)

## 3. The posterior on the number of blocs, by stepping-stone SMC -------------------------------------------
# bbmm_evidence() runs bbmm_ss() once per K. Each run tempers from the prior (beta = 0) to the coarsened
# posterior (beta = zeta) with 200 particles; the product of the incremental weights is the evidence
# log p(x | K), and the final particles are a sample from the posterior at that K.
# One run per K first:
ev1 <- cache("evidence_zeta0.8.rds", bbmm_evidence(d, K = 2:11, zeta = 0.8, seed = 2026, n_threads = threads))
print(ev1)
# The estimate of log Z carries Monte Carlo error of tens of log units, more than the gaps between neighboring K,
# so one run per K can crown the wrong K. Three more replicates per K (about 30 minutes on 12 threads) ...
ev2 <- cache("evidence_zeta0.8_reps.rds",
             bbmm_evidence(d, K = 2:11, zeta = 0.8, n_rep = 3, seed = 2027, n_threads = threads))
# ... pooled with evidence_from_fits(): runs at the same K count as replicates, and p(K | x) uses their mean log Z
ev <- evidence_from_fits(c(ev1$fits, ev2$fits))
print(ev)
save_png(plot_evidence(ev), "evidence.png", 12, 4)
runs <- rbind(ev1$runs, ev2$runs)
cat("\nlog Z of each replicate, relative to the best run overall:\n")
print(round(xtabs(I(logZ - max(logZ)) ~ K + rep, data = transform(runs, rep = ave(K, K, FUN = seq_along))), 1))
# The same p(K | x) by hand, from the mean log Z and the default geometric(0.1) prior on K
mlz <- tapply(runs$logZ, runs$K, mean)
print(round(posterior_K(mlz, as.integer(names(mlz)), log_prior = log_prior_K_geometric(as.integer(names(mlz)))), 3))
# The paper used the single cluster run per K in paper_hpc_logZ.csv: alone, it puts everything on K = 5
hpc <- read.csv("examples/portland/paper_hpc_logZ.csv")
print(round(posterior_K(hpc$logZ, hpc$K, log_prior = log_prior_K_geometric(hpc$K)), 3))
# p(T | x): T is the number of OCCUPIED blocs. Runs at K = 8 or 9 leave components empty, so T is the quantity
# to report; it pools every particle of every run, weighted by p(K | x) x the particle weight.
print(subset(ev$posterior_T, posterior > 1e-4))
T_hat <- as.integer(ev$posterior_T$T[which.max(ev$posterior_T$posterior)])

## 4. One representative coloring --------------------------------------------------------------------------
# bloc_summary() on an evidence object pools the particles and computes the posterior similarity matrix
# psm[i, j] = p(precinct i and j share a bloc | x). Its own representative partition is Dahl's least-squares
# draw. The paper instead clusters 1 - psm with k-medoids at T = the posterior mode of occupied blocs
# (the project's "representative coloring"). We compute both and compare them.
s_dahl <- bloc_summary(ev, d, n_blocs = T_hat)
psm <- s_dahl$psm
pam <- cluster::pam(stats::as.dist(1 - psm), k = T_hat, diss = TRUE)
cat(sprintf("\nT = %d; average silhouette %.3f; ARI(k-medoids, Dahl) = %.3f\n",
            T_hat, pam$silinfo$avg.width, ari(pam$clustering, s_dahl$assignment$bloc[match(d$units, s_dahl$assignment$unit)])))

# Number the blocs by partisanship, 1 = least Democratic, as the paper does for Portland, and carry the package's
# summary (model p_kq with 90% intervals, nu_k, certainty) over to that numbering
raw <- pam$clustering[d$units]
bloc <- match(raw, order(tapply(nv, raw, mean))); names(bloc) <- d$units
dahl <- s_dahl$assignment$bloc[match(d$units, s_dahl$assignment$unit)]
to_new <- apply(table(dahl, bloc), 1, which.max)          # Dahl bloc -> paper-style number (one-to-one here)
stopifnot(!anyDuplicated(to_new))
s <- s_dahl
s$assignment$bloc <- unname(to_new[as.character(s$assignment$bloc)])
s$membership <- s$membership[, order(to_new), drop = FALSE]; colnames(s$membership) <- seq_len(T_hat)
s$questions$bloc <- unname(to_new[as.character(s$questions$bloc)])
s$questions <- s$questions[order(s$questions$bloc), ]
s$blocs$bloc <- unname(to_new[as.character(s$blocs$bloc)])
s$blocs <- s$blocs[order(s$blocs$bloc), ]
s$blocs$normal_vote <- round(100 * tapply(nv, bloc, mean), 1)
s$blocs$silhouette <- round(tapply(pam$silinfo$widths[d$units, "sil_width"], bloc, mean), 3)
print(s$blocs, digits = 3, row.names = FALSE)
certainty <- s$assignment$certainty[match(d$units, s$assignment$unit)]
cat(sprintf("Certainty: median %.3f; %d precincts >= 0.9; %d below 0.5\n",
            median(certainty), sum(certainty >= 0.9), sum(certainty < 0.5)))
assign <- data.frame(unit_id = d$units, bloc = bloc, certainty = round(certainty, 4), normal_vote = round(nv, 4),
                     silhouette = round(pam$silinfo$widths[d$units, "sil_width"], 4))
write.csv(assign, file.path(out, "blocs.csv"), row.names = FALSE)
write.csv(s$blocs, file.path(out, "bloc_table.csv"), row.names = FALSE)

save_png(plot_coclustering(s), "coclustering.png", 7, 6)

## 5. Maps: the blocs on one partisan gradient, and how sure each precinct is --------------------------------
gm <- merge(g, assign, by = "unit_id")
pal <- grDevices::colorRampPalette(c("#c9b27c", "#7a9a8a", "#2f5d7c"))(T_hat)   # least -> most Democratic
lab <- sprintf("%d  (%s%% Dem)", s$blocs$bloc, s$blocs$normal_vote)
m1 <- ggplot(gm) + geom_sf(aes(fill = factor(bloc)), colour = "white", linewidth = 0.1) +
  scale_fill_manual(values = pal, labels = lab, name = "Bloc (normal vote)") + theme_void() +
  labs(title = sprintf("Portland: %d blocs from 41 measures", T_hat), subtitle = "Stepping-stone posterior, zeta = 0.8")
m2 <- ggplot(gm) + geom_sf(aes(fill = certainty), colour = "white", linewidth = 0.1) +
  scale_fill_viridis_c(limits = c(0, 1), name = "Certainty") + theme_void() +
  labs(title = "How surely each precinct belongs", subtitle = "Mean posterior co-occupancy with its bloc")
save_png(m1 / m2, "bloc_map.png", 9, 7.5)

## 6. Every measure against bloc partisanship (the paper's Figure, panel a) -----------------------------------
# For each measure: the ballot-weighted share of each bloc taking the side chosen by the most Democratic bloc.
ys <- with(s$questions, tapply(yes_share, list(label, bloc), sum))[d$labels, ]
sup <- ys; flip <- ys[, T_hat] < ys[, 1]; sup[flip, ] <- 1 - ys[flip, ]    # orient each measure to the Democratic end
ordered <- apply(sup, 1, function(v) all(diff(v) > 0))
rho <- apply(sup, 1, function(v) cor(v, s$blocs$normal_vote, method = "spearman"))
drop <- apply(sup, 1, function(v) max(-diff(v)))                       # largest fall between adjacent blocs
spread <- apply(sup, 1, function(v) diff(range(v)))
cat(sprintf("\n%d of %d measures order the blocs exactly by partisanship; median rank correlation %.2f\n",
            sum(ordered), nrow(sup), median(rho)))
dep <- data.frame(measure = rownames(sup), drop_pts = round(100 * drop, 1), spread_pts = round(100 * spread, 1))
dep <- dep[order(-dep$drop_pts), ]; print(head(dep, 4), row.names = FALSE)
long <- data.frame(measure = rep(rownames(sup), T_hat), nv = rep(s$blocs$normal_vote, each = nrow(sup)),
                   support = 100 * as.vector(sup), departs = rep(rownames(sup) %in% head(dep$measure, 2), T_hat))
p <- ggplot(long, aes(nv, support, group = measure)) +
  geom_line(data = subset(long, !departs), colour = "grey70", linewidth = 0.4) +
  geom_line(data = subset(long, departs), colour = "#b2182b", linewidth = 0.9) +
  geom_point(data = subset(long, departs), colour = "#b2182b") +
  scale_x_continuous(breaks = s$blocs$normal_vote) + theme_minimal() +
  labs(x = "Bloc normal vote (% Democratic)", y = "Bloc support for the most Democratic bloc's side (%)",
       title = "41 Oregon measures against bloc partisanship",
       subtitle = sprintf("Red: the two with the largest fall between neighboring blocs (%s)",
                          paste(sub(":.*", "", head(dep$measure, 2)), collapse = ", ")))
save_png(p, "measures_vs_partisanship.png", 8, 6)
save_png(plot_bloc_profiles(s, questions = dep$measure[order(-dep$spread_pts)][1:15]), "bloc_profiles.png", 9, 7)

## 7. Blocs against national partisanship (the paper's Table 2 quantities) ------------------------------------
wcor <- function(x, y, w) stats::cov.wt(cbind(x, y), w, cor = TRUE)$cor[1, 2]
adj_r2 <- function(y, X, w) { dd <- data.frame(.y = y, .w = w, X); summary(lm(.y ~ . - .w, data = dd, weights = .w))$adj.r.squared }
vs_partisanship <- function(bloc) {               # one row per measure, for any partition of the precincts
  K <- length(unique(bloc))
  bins <- factor(dplyr::ntile(nv, K))           # K equal-count bins of the normal vote, as in the paper
  q <- do.call(rbind, lapply(seq_along(d$questions), function(j) {
    y <- d$X[, j] / d$M[, j]; w <- d$M[, j]
    data.frame(question = d$labels[j], r2_normal = wcor(y, nv, w)^2,
               r2_bins = adj_r2(y, data.frame(bins), w), r2_blocs = adj_r2(y, data.frame(bloc = factor(bloc)), w),
               gain = adj_r2(y, data.frame(nv, bloc = factor(bloc)), w) - adj_r2(y, data.frame(nv), w))
  }))
  q[order(-q$gain), ]
}
headline <- function(q, K) c(K = K, median_r2_bins = median(q$r2_bins), median_r2_blocs = median(q$r2_blocs),
                             blocs_win = sum(q$r2_blocs > q$r2_bins), median_gain = median(q$gain), gain_ge_025 = sum(q$gain >= 0.25))
by_q <- vs_partisanship(bloc)
write.csv(by_q, file.path(out, "questions_vs_partisanship.csv"), row.names = FALSE)
cat(sprintf("\nMedian r^2 with the normal vote %.2f; %d of %d measures below 0.25\n",
            median(by_q$r2_normal), sum(by_q$r2_normal < 0.25), nrow(by_q)))
print(round(headline(by_q, T_hat), 3))
print(head(by_q, 4), digits = 2, row.names = FALSE)
p <- ggplot(by_q, aes(r2_bins, r2_blocs)) + geom_abline(colour = "grey60") + geom_point(alpha = 0.7) +
  coord_equal(xlim = c(0, 1), ylim = c(0, 1)) + theme_minimal() +
  labs(x = sprintf("Adjusted R² from %d bins of the normal vote", T_hat), y = sprintf("Adjusted R² from %d blocs", T_hat),
       title = "Each point is one measure", subtitle = "Above the line: the blocs explain more than national partisanship")
save_png(p, "blocs_vs_partisanship.png", 6, 6)

## 8. One axis: Jensen-Shannon principal coordinates ---------------------------------------------------------
js <- js_pcoa(d)
r2pc <- function(v, x) summary(lm(v ~ x))$r.squared
cat(sprintf("\nJS principal coordinates: PC1 %.1f%%, PC2 %.1f%%; r^2 of PC1 with the normal vote %.2f, with bloc %.2f\n",
            js$pct[1], js$pct[2], r2pc(js$coords[, 1], nv[rownames(js$coords)]), r2pc(js$coords[, 1], factor(bloc[rownames(js$coords)]))))
save_png(plot_js_pca(d, s, orient = nv), "js_pca.png", 13, 5)

## 9. Against the paper's five blocs and the fast approximation ---------------------------------------------
# The paper's Portland section uses T = 5 from the single cluster run per K (paper_blocs_T5.csv, same numbering).
paper <- read.csv("examples/portland/paper_blocs_T5.csv", colClasses = c(unit_id = "character"))
paper <- setNames(paper$bloc, paper$unit_id)[d$units]
cat(sprintf("\nARI, these %d blocs vs the paper's 5: %.3f\n", T_hat, ari(bloc, paper)))
print(table(paper = paper, these = bloc))
# Forcing five blocs out of the same pooled co-occupancy recovers the paper's partition closely
pam5 <- cluster::pam(stats::as.dist(1 - psm), k = 5, diss = TRUE)$clustering[d$units]
cat(sprintf("ARI, k-medoids at k = 5 on the pooled co-occupancy vs the paper's 5: %.3f\n", ari(pam5, paper)))
cmp <- rbind(paper_T5 = headline(vs_partisanship(paper), 5), this_T = headline(by_q, T_hat))
print(round(cmp, 3)); write.csv(round(cmp, 4), file.path(out, "paper_vs_this.csv"))
em <- sel[["0.8"]]$fits[["5"]]
em_bloc <- bloc_summary(em, d)$assignment
cat(sprintf("ARI, tempered EM at zeta = 0.8, K = 5 vs the paper's 5: %.3f; vs these %d: %.3f\n",
            ari(paper, em_bloc$bloc[match(d$units, em_bloc$unit)]), T_hat, ari(bloc, em_bloc$bloc[match(d$units, em_bloc$unit)])))
