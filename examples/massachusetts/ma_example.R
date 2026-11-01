# Worked example: Massachusetts, the paper's "alternative account".
#
#   Rscript examples/massachusetts/ma_example.R            # from the repository root, about a minute
#   MA_RUN_EM=1 Rscript examples/massachusetts/ma_example.R # also refit tempered EM for K = 2..12 (see README for timing)
#
# Reproduces the Massachusetts blocs of the paper from the public data in data/ma/ and two files in this folder:
#   ss_evidence.csv        stepping-stone log marginal likelihoods for K = 4..13 (zeta = 0.25), one run per K on a cluster
#   ss_particles_K08.rds   the final weighted particles of the K = 8 run (bloc assignments for 2,392 precincts)
# and then repeats the paper's analysis: blocs against national partisanship, the partisan-matched pairs, and two
# out-of-sample tests (the 2022 Democratic primary for governor and the local district questions).
# Needs Elections.BBMM, cluster, sf, ggplot2 and patchwork. Writes figures and tables to examples/massachusetts/output/.

suppressPackageStartupMessages({
  library(Elections.BBMM); library(cluster); library(sf); library(ggplot2); library(patchwork)
})
source("R/read_place.R")
ex  <- "examples/massachusetts"
out <- file.path(ex, "output"); dir.create(out, showWarnings = FALSE)
say <- function(...) cat(sprintf(...), "\n", sep = "")

# ---- 1. Data -----------------------------------------------------------------------------------------------
d   <- read_place("ma")                    # 2,392 precincts x 25 statewide ballot questions, 2012-2024
fed <- read_place("ma", "federal_races")   # President and US Senate: yes = Democratic, total = Dem + Rep
g   <- read_units("ma")                    # the 2022 precinct map
print(d)

# Normal vote: each precinct's mean two-party Democratic share over the ten federal races
sh <- fed$X / fed$M; sh[!is.finite(sh)] <- NA
N  <- unname(rowMeans(sh, na.rm = TRUE)[d$units])          # NA for the few precincts with no federal votes

# ---- 2. Optional: the fast route, tempered EM -------------------------------------------------------------
if (Sys.getenv("MA_RUN_EM") == "1") {
  t0 <- Sys.time()
  sel <- bbmm_em_select(d, K = 2:12, zeta = 0.25, n_starts = 10, seed = 2026, cores = parallel::detectCores() - 1)
  say("EM, K = 2..12, 10 starts each: %.1f minutes", as.numeric(difftime(Sys.time(), t0, units = "mins")))
  print(sel$selected)
  ggsave(file.path(out, "em_selection.png"), plot_em_selection(sel), width = 7, height = 4, dpi = 150)
}

# ---- 3. The number of blocs: stepping-stone evidence ----------------------------------------------------
# Each row is one bbmm_ss(d, K, zeta = 0.25) run on a cluster (3-4 hours per K; see README).
ev <- read.csv(file.path(ex, "ss_evidence.csv"))
pK <- posterior_K(ev$logZ, ev$K, log_prior_K_geometric(ev$K))
ev$posterior <- round(as.numeric(pK), 3)
ev$logZ_minus_best <- round(ev$logZ - max(ev$logZ), 1)
print(ev[, c("K", "logZ_minus_best", "posterior", "hours")])
p_ev <- ggplot(ev, aes(K, logZ_minus_best)) + geom_line(colour = "grey60") + geom_point(size = 2.5) +
  geom_point(data = ev[which.max(ev$logZ), ], colour = "#B2182B", size = 4) +
  scale_x_continuous(breaks = ev$K) +
  labs(x = "Number of mixture components, K", y = "log marginal likelihood\nminus the best K",
       title = "Massachusetts: stepping-stone evidence by K (zeta = 0.25)",
       subtitle = sprintf("Posterior p(K = %d) = %.2f under a geometric prior on K", ev$K[which.max(pK)], max(pK))) +
  theme_minimal(base_size = 11)
ggsave(file.path(out, "ss_evidence.png"), p_ev, width = 7, height = 4, dpi = 150)

# ---- 4. One representative partition from the particles ---------------------------------------------------
pt <- readRDS(file.path(ex, "ss_particles_K08.rds"))
stopifnot(identical(pt$units, d$units), identical(pt$questions, d$questions))
w  <- pt$weights / sum(pt$weights)
occupied <- apply(pt$z, 1, function(z) length(unique(z)))
T_post <- tapply(w, occupied, sum)
say("Posterior on the number of occupied blocs: %s", paste(sprintf("T = %s: %.3f", names(T_post), T_post), collapse = ", "))
T_hat <- as.integer(names(which.max(T_post)))

# Co-occupancy S[i, j]: the posterior probability that precincts i and j sit in the same bloc
n_u <- length(d$units); S <- matrix(0, n_u, n_u)
for (r in seq_len(nrow(pt$z))) S <- S + w[r] * outer(pt$z[r, ], pt$z[r, ], "==")
pm  <- pam(as.dist(1 - S), k = T_hat, diss = TRUE, pamonce = 5)     # k-medoids on 1 - S
z8  <- pm$clustering
sil <- silhouette(pm)
own <- vapply(seq_len(n_u), function(i) mean(S[i, z8 == z8[i] & seq_len(n_u) != i]), 1)  # certainty
b8  <- data.frame(component = seq_len(T_hat), precincts = tabulate(z8, T_hat),
                  normal_vote = round(100 * tapply(N, z8, mean, na.rm = TRUE), 1),
                  silhouette = round(summary(sil)$clus.avg.widths, 2),
                  certainty = round(tapply(own, z8, median), 2))
print(b8[order(-b8$normal_vote), ], row.names = FALSE)

# ---- 5. Fold the blocs that are not coalitions ----------------------------------------------------------------
# Two of the eight have no coherence: one holds 4 precincts, one is scattered across the state with a negative
# silhouette (its precincts sit closer to other blocs than to each other). Each is folded into the remaining bloc
# nearest it in partisanship. The paper does the same (methods appendix).
fold <- b8$component[b8$precincts < 0.01 * n_u | b8$silhouette < 0]
keep <- setdiff(b8$component, fold)
to   <- vapply(fold, function(k) keep[which.min(abs(b8$normal_vote[keep] - b8$normal_vote[k]))], 1L)
z6   <- z8; for (i in seq_along(fold)) z6[z8 == fold[i]] <- to[i]
say("Folded %d small or incoherent bloc(s) (%d precincts) into the bloc nearest in normal vote",
    length(fold), sum(z8 %in% fold))

# ---- 6. Names ---------------------------------------------------------------------------------------------------
# Named for the places they contain (README section 4). Matched here by partisanship, most Democratic first.
by_nv <- names(sort(tapply(N, z6, mean, na.rm = TRUE), decreasing = TRUE))
nm <- c("Collegevilles", "Immigrant urban cores", "Affluent inner ring", "Post-industrial cities",
        "Professional suburbs", "New Englandtown")
paper_no <- c("Immigrant urban cores" = 1, "Collegevilles" = 2, "Post-industrial cities" = 3,
              "Affluent inner ring" = 4, "Professional suburbs" = 5, "New Englandtown" = 6)
bloc_name <- unname(setNames(nm, by_nv)[as.character(z6)])
bloc <- unname(paper_no[bloc_name])                                 # the paper's numbering, 1-6
pal <- c("Immigrant urban cores" = "#A50F15", "Collegevilles" = "#6A3D9A", "Post-industrial cities" = "#2171B5",
         "Affluent inner ring" = "#33A02C", "Professional suburbs" = "#FDBF6F", "New Englandtown" = "#D9D9D9")
blocs <- data.frame(unit_id = d$units, bloc = bloc, name = bloc_name, certainty = round(own, 3), normal_vote = round(N, 4))
write.csv(blocs, file.path(out, "blocs.csv"), row.names = FALSE)
tab <- data.frame(bloc = 1:6, name = names(paper_no), precincts = tabulate(bloc, 6),
                  normal_vote = round(100 * as.vector(tapply(N, bloc, mean, na.rm = TRUE)), 1))
print(tab, row.names = FALSE)
stopifnot(identical(tab$precincts, c(230L, 113L, 332L, 295L, 503L, 919L)))   # the paper's six blocs

# ---- 7. Map, with Greater Boston enlarged ----------------------------------------------------------------------
g <- g[match(d$units, g$unit_id), ]; g$name <- factor(bloc_name, levels = names(pal))
g <- st_transform(g, 26986)                                         # Massachusetts State Plane, metres
town <- sub("[|].*", "", g$unit_id)
inner <- c("BOSTON", "CAMBRIDGE", "SOMERVILLE", "BROOKLINE", "NEWTON", "WATERTOWN", "BELMONT", "ARLINGTON", "MEDFORD",
           "EVERETT", "CHELSEA", "REVERE", "MALDEN", "WINTHROP", "QUINCY", "MILTON", "DEDHAM", "NEEDHAM")
bb <- st_bbox(g[town %in% inner, ])
map_one <- function(x, lw) ggplot(x) + geom_sf(aes(fill = name), colour = "white", linewidth = lw) +
  scale_fill_manual(values = pal, name = NULL, drop = FALSE) + theme_void(base_size = 10)
p_state  <- map_one(g, 0.03) + geom_sf(data = st_as_sfc(bb), fill = NA, colour = "black", linewidth = 0.4) +
  theme(legend.position = "bottom") + guides(fill = guide_legend(nrow = 2))
p_boston <- map_one(g, 0.08) + coord_sf(xlim = bb[c(1, 3)], ylim = bb[c(2, 4)], expand = FALSE) +
  theme(legend.position = "none", panel.border = element_rect(fill = NA, colour = "black")) +
  labs(subtitle = "Greater Boston")
ggsave(file.path(out, "bloc_map.png"), p_state + p_boston + plot_layout(widths = c(2.2, 1)),
       width = 11, height = 5, dpi = 150, bg = "white")

# ---- 8. Blocs against national partisanship ---------------------------------------------------------------------
# For each question, ballot-weighted across precincts: r^2 with the normal vote; adjusted R^2 from six equal-count
# bins of the normal vote and from the six blocs (the same degrees of freedom); and the gain in adjusted R^2 from
# adding the blocs to a linear regression on the normal vote. As in Table 2 of the paper.
adj <- function(f, x) summary(lm(f, data = x, weights = n))$adj.r.squared
wcor <- function(x, y, w) { w <- w / sum(w); mx <- sum(w * x); my <- sum(w * y)
  sum(w * (x - mx) * (y - my)) / sqrt(sum(w * (x - mx)^2) * sum(w * (y - my)^2)) }
perq <- do.call(rbind, lapply(seq_along(d$questions), function(q) {
  x <- data.frame(y = d$X[, q] / d$M[, q], n = d$M[, q], N = N, bloc = factor(bloc))
  x <- x[!is.na(x$y) & x$n > 0 & !is.na(x$N), ]
  x$bin <- factor(dplyr::ntile(x$N, 6))
  data.frame(question = d$labels[q], r2 = wcor(x$y, x$N, x$n)^2, r2_bins = adj(y ~ bin, x),
             r2_blocs = adj(y ~ bloc, x), gain = adj(y ~ N + bloc, x) - adj(y ~ N, x))
}))
write.csv(transform(perq, r2 = round(r2, 3), r2_bins = round(r2_bins, 3), r2_blocs = round(r2_blocs, 3), gain = round(gain, 3)),
          file.path(out, "questions_vs_partisanship.csv"), row.names = FALSE)
say("Median |r| with the normal vote %.2f; %d of %d questions have r^2 < 0.25",
    median(sqrt(perq$r2)), sum(perq$r2 < 0.25), nrow(perq))
say("Median adjusted R^2: 6 bins of the normal vote %.2f, 6 blocs %.2f; blocs explain more on %d of %d",
    median(perq$r2_bins), median(perq$r2_blocs), sum(perq$r2_blocs > perq$r2_bins), nrow(perq))
say("Median gain from adding the blocs to the normal vote: %.2f", median(perq$gain))
print(head(perq[order(-perq$gain), c("question", "r2", "r2_blocs", "gain")], 3), digits = 2, row.names = FALSE)
p_q <- ggplot(perq, aes(r2_bins, r2_blocs)) + geom_abline(linetype = 2, colour = "grey50") +
  geom_point(aes(size = gain), colour = "#2171B5", alpha = 0.7) +
  geom_text(data = perq[perq$gain > 0.3, ], aes(label = sub("^\\d{4} Q\\d: ", "", question)), hjust = -0.12, size = 3) +
  coord_equal(xlim = c(0, 1), ylim = c(0, 1)) + scale_size_continuous(name = "Gain from\nadding blocs") +
  labs(x = "Adjusted R², six bins of the normal vote", y = "Adjusted R², six blocs",
       title = "Each of the 25 questions: blocs against partisanship") + theme_minimal(base_size = 11)
ggsave(file.path(out, "blocs_vs_partisanship.png"), p_q, width = 7, height = 6, dpi = 150, bg = "white")

# ---- 9. Partisan-matched pairs ------------------------------------------------------------------------------------
# Two blocs are partisan-matched when their mean normal votes are within five points: national partisanship
# cannot tell them apart.
bn <- tapply(N, bloc, mean, na.rm = TRUE)
yes <- sapply(1:6, function(k) colSums(d$X[bloc == k, ], na.rm = TRUE) / colSums(d$M[bloc == k, ], na.rm = TRUE))
pair_gaps <- function(a, b) { gp <- 100 * (yes[, a] - yes[, b]); o <- order(-abs(gp))
  data.frame(pair = sprintf("%s (%.0f) vs %s (%.0f)", names(paper_no)[a], 100 * bn[a], names(paper_no)[b], 100 * bn[b]),
             question = d$labels[o], gap = round(gp[o], 1)) }
pairs <- subset(expand.grid(a = 1:6, b = 1:6), a < b & abs(bn[a] - bn[b]) <= 0.05)
say("Partisan-matched pairs (normal votes within 5 points): %s",
    paste(sprintf("%s / %s", names(paper_no)[pairs$a], names(paper_no)[pairs$b]), collapse = "; "))
iuc_coll <- pair_gaps(1, 2)                                         # six points apart: just outside the rule
iuc_coll$pair <- paste0(iuc_coll$pair, ", not matched")
gaps <- do.call(rbind, c(Map(pair_gaps, pairs$a, pairs$b), list(iuc_coll)))
write.csv(gaps, file.path(out, "pair_gaps.csv"), row.names = FALSE)
for (p in unique(gaps$pair)) { x <- gaps[gaps$pair == p, ]
  say("%s: mean gap %.1f points, more than 10 on %d of 25; largest: %s", p, mean(abs(x$gap)), sum(abs(x$gap) > 10),
      paste(sprintf("%s %+.0f", sub("^\\d{4} Q\\d: ", "", x$question[1:3]), x$gap[1:3]), collapse = "; ")) }
pg <- gaps; pg$question <- factor(sub("^(\\d{4}) Q\\d: (.*)$", "\\2 (\\1)", pg$question),
                                  levels = rev(unique(sub("^(\\d{4}) Q\\d: (.*)$", "\\2 (\\1)", gaps$question[gaps$pair == gaps$pair[1]]))))
p_pairs <- ggplot(pg, aes(gap, question)) + geom_vline(xintercept = 0, colour = "grey60") +
  geom_segment(aes(x = 0, xend = gap, yend = question), colour = "grey70") + geom_point(colour = "#A50F15") +
  facet_wrap(~ pair, nrow = 1) + labs(x = "Difference in Yes share (points), first bloc minus second", y = NULL) +
  theme_minimal(base_size = 10)
ggsave(file.path(out, "pair_gaps.png"), p_pairs, width = 12, height = 6.5, dpi = 150, bg = "white")

# ---- 10. Out of sample (i): the 2022 Democratic primary for governor ------------------------------------------
pr <- read.csv("data/ma/other/primaries_2022_2024.csv.gz", colClasses = c(unit_id = "character"))
gov <- pr[pr$contest == "2022 D Governor" & grepl("Chang", pr$candidate), ]
gov <- merge(gov, blocs[, c("unit_id", "bloc", "name", "normal_vote")], by = "unit_id")
gov$bloc <- factor(gov$bloc); gov$bin <- factor(dplyr::ntile(gov$normal_vote, 6))
say("2022 Democratic primary for governor, %d precincts: r^2 with the normal vote %.2f; adjusted R^2, 6 bins %.2f, 6 blocs %.2f",
    nrow(gov), wcor(gov$y, gov$normal_vote, gov$n)^2, adj(y ~ bin, gov), adj(y ~ bloc, gov))
cd <- aggregate(cbind(votes, cand_votes) ~ name, gov, sum); cd$chang_diaz <- round(100 * cd$votes / cd$cand_votes, 1)
print(cd[order(-cd$chang_diaz), c("name", "chang_diaz")], row.names = FALSE)

# ---- 11. Out of sample (ii): local district questions ---------------------------------------------------------
lm_ <- read.csv("data/ma/other/local_measures.csv.gz", colClasses = c(unit_id = "character", question_id = "character"))
cq  <- read.csv("data/ma/other/local_questions_coded.csv", colClasses = c(question_id = "character"))
lm_ <- merge(lm_[lm_$question_id %in% cq$question_id & lm_$total > 0, ], blocs[, c("unit_id", "bloc", "normal_vote")])
lm_$y <- lm_$yes / lm_$total; lm_$n <- lm_$total; lm_$N <- lm_$normal_vote
loc <- do.call(rbind, lapply(split(lm_, lm_$question_id), function(x) {
  if (length(unique(x$bloc)) < 2) return(NULL); x$bloc <- factor(x$bloc)
  data.frame(question_id = x$question_id[1], gain = adj(y ~ N + bloc, x) - adj(y ~ N, x)) }))
loc <- merge(loc, cq[, c("question_id", "group")])
lg <- aggregate(gain ~ group, loc, function(v) c(questions = length(v), median_gain = round(100 * median(v), 1)))
lg <- do.call(data.frame, lg); names(lg) <- c("group", "questions", "median_gain_points"); print(lg[order(-lg$median_gain_points), ], row.names = FALSE)
write.csv(lg, file.path(out, "local_questions_bloc_gain.csv"), row.names = FALSE)
