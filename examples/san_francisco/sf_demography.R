# Who is in San Francisco's blocs: names, two bloc portraits, and the Jensen-Shannon principal coordinates
# coloured by bloc, race and education.
# Run from the repository root after sf_example.R (it reads output/sf_fits.rds):
#   Rscript examples/san_francisco/sf_demography.R
# Needs Elections.BBMM, sf, ggplot2, patchwork and ragg. Demographics are the 2020-2024 ACS five-year estimates,
# allocated to the 510 precincts by 2020 census-block population (sf_demographics.csv.gz). About a minute.

suppressPackageStartupMessages({ library(Elections.BBMM); library(ggplot2); library(patchwork); library(grid) })
source("R/read_place.R")
ex <- "examples/san_francisco"; out <- file.path(ex, "output")
set.seed(2026)
sf::sf_use_s2(FALSE)

d   <- read_place("sf")
fed <- read_place("sf", "federal_races")
fits <- readRDS(file.path(out, "sf_fits.rds"))
s <- fits$summary
K <- nrow(s$blocs)
bloc <- s$assignment$bloc[match(d$units, s$assignment$unit)]
demo <- read.csv(file.path(ex, "sf_demographics.csv.gz"), colClasses = c(unit_id = "character"))
demo <- demo[match(d$units, demo$unit_id), ]
stopifnot(!anyNA(bloc), identical(demo$unit_id, d$units))
pal <- setNames(bloc_colours(K), seq_len(K))

## 1. Names --------------------------------------------------------------------------------------------------
# Each name says who lives in the bloc, from the profile table below (output/bloc_profiles.csv) and the
# neighbourhoods each bloc holds (README, section 3). README section 3 matches them to the paper's names.
bloc_names <- c(
  "1" = "Multiracial Low-Income Renters",       # 29% Asian, 29% Latino, 18% Black; median income $48k; 18% own
  "2" = "Latino and White Progressive Renters",  # the Mission: 48% white, 23% Latino; two-thirds graduates
  "3" = "Young Professional Renters",            # SoMa and the Inner Richmond: white and Asian, three-quarters rent
  "4" = "Graduate-Degree Progressives",          # Noe Valley: 57% white, 43% with graduate degrees
  "5" = "Affluent Professional Renters",         # Pacific Heights, Russian Hill: $169k, two-thirds rent
  "6" = "Asian-Plurality Middle Class",          # the Outer Richmond, Excelsior: 48% Asian, 41% foreign-born
  "7" = "Asian Immigrant Homeowners",            # the Sunset, Visitacion Valley: 62% Asian, 49% foreign-born, 65% own
  "8" = "Wealthy White Renters of the Marina",   # 62% white, 84% graduates, $200k+, two-thirds rent
  "9" = "Wealthy White and Asian Homeowners")    # west of Twin Peaks: 84% own, $200k+

# Bloc profiles: population-weighted shares, precinct median income, 2024 Trump share, normal vote
w <- demo$population
trump24 <- 1 - fed$X[, "2024_president"] / fed$M[, "2024_president"]
nv <- rowMeans(fed$X / fed$M, na.rm = TRUE)
prof <- do.call(rbind, lapply(seq_len(K), function(k) {
  i <- bloc == k
  wm <- function(x) weighted.mean(x[i], w[i], na.rm = TRUE)
  data.frame(bloc = k, name = bloc_names[[as.character(k)]], precincts = sum(i),
             white = wm(demo$pct_white), black = wm(demo$pct_black), asian = wm(demo$pct_asian),
             latino = wm(demo$pct_hispanic), foreign_born = wm(demo$pct_foreign), ba_plus = wm(demo$pct_ba_plus),
             grad = wm(demo$pct_grad), owner = wm(demo$pct_owner),
             median_income_k = median(demo$median_income[i], na.rm = TRUE) / 1000,
             normal_vote = 100 * weighted.mean(nv[i], rowSums(fed$M, na.rm = TRUE)[i]),
             trump_2024 = 100 * sum(fed$M[i, "2024_president"] - fed$X[i, "2024_president"], na.rm = TRUE) /
               sum(fed$M[i, "2024_president"], na.rm = TRUE))
}))
write.csv(prof,file.path(out, "bloc_profiles.csv"), row.names = FALSE)
print(format(prof, digits = 2), right = FALSE)

## 2. Two bloc portraits, in the format of the paper's Appendix D dashboards ----------------------------------
# One row per bloc: its precincts with race dots (one per 20 residents, placed uniformly within each precinct,
# not at homes) and a race bar; home language; the spread of precinct median income; and boxplots of precinct
# education and nativity, each against the city-wide value (dashed).
portrait_blocs <- c(1, 8)          # four points apart in partisanship, 30 apart on taxing high earners
g <- read_units("sf")
g <- suppressWarnings(sf::st_crop(g, c(xmin = -122.53, ymin = 37.70, xmax = -122.35, ymax = 37.84)))   # no Farallones
g <- sf::st_transform(g, 5070)
g$bloc <- bloc[match(g$unit_id, d$units)]
background <- sf::st_union(sf::st_geometry(g)); bb <- sf::st_bbox(g)

race_vars <- c(B03002_003E = "white", B03002_004E = "black", B03002_006E = "asian", B03002_012E = "latino")
race_colors <- c(white = "#E53935", black = "#2468DC", asian = "#159447", latino = "#F28C28")
bar_colors <- c(B03002_003E = "#E53935", B03002_004E = "#2468DC", B03002_006E = "#159447", B03002_012E = "#F28C28",
                Other = "#BDBDBD")
lang_lab <- c(C16001_002E = "English only", C16001_003E = "Spanish", C16001_006E = "French, Haitian, or Cajun",
              C16001_009E = "German or other West Germanic", C16001_012E = "Russian, Polish, or other Slavic",
              C16001_015E = "Other Indo-European", C16001_018E = "Korean", C16001_021E = "Chinese (incl. Mandarin, Cantonese)",
              C16001_024E = "Vietnamese", C16001_027E = "Tagalog (incl. Filipino)", C16001_030E = "Other Asian and Pacific Island",
              C16001_033E = "Arabic", C16001_036E = "Other and unspecified")
lang_col <- c(C16001_002E = "#C9CDD3", C16001_003E = "#E76F51", C16001_006E = "#DCA519", C16001_009E = "#7254A3",
              C16001_012E = "#3378B5", C16001_015E = "#2B9D8F", C16001_018E = "#BF4E8A", C16001_021E = "#48A23F",
              C16001_024E = "#9C755F", C16001_027E = "#00A5CF", C16001_030E = "#92952C", C16001_033E = "#E58FBA",
              C16001_036E = "#666666")
lang_order <- c("C16001_002E", names(sort(colSums(demo[names(lang_lab)[-1]]), decreasing = TRUE)))
box_vars <- c(pct_hs_plus = "High school+ (25+)", pct_ba_plus = "Bachelor's degree+ (25+)", pct_grad = "Graduate degree (25+)",
              pct_foreign = "Foreign-born", pct_non_english = "Non-English at home (5+)", pct_spanish = "Spanish at home (5+)")
tot <- colSums(demo[, grepl("^[BC][0-9]", names(demo))], na.rm = TRUE)
refs <- c(pct_hs_plus = 100 * sum(tot[sprintf("B15003_%03dE", 17:25)]) / tot[["B15003_001E"]],
          pct_ba_plus = 100 * sum(tot[sprintf("B15003_%03dE", 22:25)]) / tot[["B15003_001E"]],
          pct_grad    = 100 * sum(tot[sprintf("B15003_%03dE", 23:25)]) / tot[["B15003_001E"]],
          pct_foreign = 100 * tot[["B05002_013E"]] / tot[["B05002_001E"]],
          pct_non_english = 100 * (1 - tot[["C16001_002E"]] / tot[["C16001_001E"]]),
          pct_spanish = 100 * tot[["C16001_003E"]] / tot[["C16001_001E"]])
inc_b <- tot[sprintf("B19001_%03dE", 2:17)]                     # city median household income, pooled B19001
brk <- c(0, 10, 15, 20, 25, 30, 35, 40, 45, 50, 60, 75, 100, 125, 150, 200)
cum <- cumsum(inc_b); j <- which(cum >= sum(inc_b) / 2)[1]
income_ref <- brk[j] + (sum(inc_b) / 2 - c(0, cum)[j]) / inc_b[j] * (brk[j + 1] - brk[j])

FONT <- "Helvetica"; slate <- "#7086A4"
base <- theme_minimal(base_family = FONT, base_size = 18) +
  theme(axis.title = element_blank(), axis.text.y = element_blank(), axis.ticks.y = element_blank(),
        panel.grid.major.y = element_blank(), panel.grid.minor = element_blank(),
        panel.grid.major.x = element_line(color = "#e7e7e7", linewidth = .3), plot.margin = margin(4, 3, 4, 3),
        legend.position = "none")
W <- 22.6; lm <- .4; gw <- W - 2 * lm
colwidth <- c(4.6, 4.00, 1.50, 3.25, 4.55, 4.55); colgap <- (gw - sum(colwidth)) / 5
colstart <- c(0, cumsum(colwidth + colgap)[1:5])
top <- 1.72; rowh <- 3.96; rowgap <- .12; legh <- 3.2
H <- top + length(portrait_blocs) * (rowh + rowgap) + legh + .9
ragg::agg_png(file.path(out, "bloc_portraits.png"), width = W, height = H, units = "in", res = 110)
textat <- function(label, x, y, size = 12, font = 1, just = "left", color = "#252525")
  grid.text(label, x = unit(x, "in"), y = unit(H - y, "in"), just = just,
            gp = gpar(fontsize = 1.5 * size, fontface = font, col = color, fontfamily = FONT))
draw_at <- function(p, x, y, w, h) {
  pushViewport(viewport(x = unit(x, "in"), y = unit(H - y, "in"), width = unit(w, "in"), height = unit(h, "in")))
  grid.draw(ggplotGrob(p)); popViewport()
}
grid.newpage()
textat("Two San Francisco blocs: geography and demographics", lm, .34, 25, 2)
textat(sprintf("Two of the %d blocs from 64 propositions, 2012-2022. Trump share: 2024 presidential vote.", K), lm, .88, 13)
headers <- c("", "Map / Race", "Home\nlanguage", "Income (k$)", "Education (%)", "Language / Nativity (%)")
for (jc in 2:6) textat(headers[jc], lm + colstart[jc] + colwidth[jc] / 2, if (jc == 3) 1.2 else 1.35, if (jc == 3) 13 else 18, 2, just = "center")
for (rr in seq_along(portrait_blocs)) {
  k <- portrait_blocs[rr]; i <- bloc == k; p <- prof[k, ]
  ytop <- top + (rr - 1) * (rowh + rowgap); ymid <- ytop + rowh / 2; color <- pal[[k]]
  grid.rect(x = unit(lm, "in"), y = unit(H - ytop, "in"), width = unit(gw, "in"), height = unit(rowh, "in"),
            just = c("left", "top"), gp = gpar(fill = NA, col = color, lwd = 5))
  grid.text(paste(strwrap(sprintf("%d. %s", k, p$name), 20), collapse = "\n"), x = unit(lm + .14, "in"),
            y = unit(H - (ytop + .30), "in"), just = c("left", "top"),
            gp = gpar(fontsize = 1.5 * 17, fontface = 2, col = "#252525", fontfamily = FONT, lineheight = .95))
  textat(sprintf("Trump %.1f%%", p$trump_2024), lm + .14, ytop + rowh - .95, 19.5)
  textat(sprintf("%d precincts", p$precincts), lm + .14, ytop + rowh - .45, 15, color = "#555555")
  # map with race dots
  sel <- g[!is.na(g$bloc) & g$bloc == k, ]
  cnt <- demo[match(sel$unit_id, demo$unit_id), names(race_vars)]
  dots <- do.call(rbind, lapply(names(race_vars), function(v) {
    n <- round(cnt[[v]] / 20); keep <- n > 0
    if (!any(keep)) return(NULL)
    xy <- sf::st_coordinates(sf::st_sample(sf::st_geometry(sel)[keep], size = n[keep], type = "random", exact = TRUE))
    data.frame(x = xy[, 1], y = xy[, 2], category = race_vars[[v]])
  }))
  mp <- ggplot() + geom_sf(data = background, fill = "#E8E8E8", color = NA) +
    geom_sf(data = sel, fill = "#FAFAFA", color = "#D0D0D0", linewidth = .08) +
    geom_point(data = dots, aes(x, y, color = category), size = .25, alpha = .55, shape = 16) +
    scale_color_manual(values = race_colors) +
    coord_sf(xlim = bb[c("xmin", "xmax")], ylim = bb[c("ymin", "ymax")], datum = NA, expand = FALSE) +
    theme_void() + theme(legend.position = "none", plot.margin = margin(1, 1, 1, 1))
  draw_at(mp, lm + colstart[2] + colwidth[2] / 2, ytop + 1.67, colwidth[2] - .12, 3.18)
  rc <- colSums(demo[i, c("B03002_001E", names(race_vars))])
  rz <- data.frame(variable = c(names(race_vars), "Other"), count = c(rc[names(race_vars)], rc[["B03002_001E"]] - sum(rc[names(race_vars)])))
  rz$percent <- 100 * rz$count / sum(rz$count); rz$xmax <- cumsum(rz$percent); rz$xmin <- rz$xmax - rz$percent
  rz$variable <- factor(rz$variable, levels = rz$variable)
  bar <- ggplot(rz) + geom_rect(aes(xmin = xmin, xmax = xmax, ymin = 0, ymax = 1, fill = variable), color = "white", linewidth = .15) +
    geom_text(data = rz[rz$percent >= 8, ], aes(x = (xmin + xmax) / 2, y = .5, label = sprintf("%.0f%%", percent)),
              size = 5, color = "white", fontface = "bold") +
    scale_fill_manual(values = bar_colors) + scale_x_continuous(limits = c(0, 100.001), expand = c(0, 0)) +
    scale_y_continuous(limits = c(0, 1), expand = c(0, 0)) + theme_void() + theme(legend.position = "none")
  draw_at(bar, lm + colstart[2] + colwidth[2] / 2, ytop + 3.61, colwidth[2] - .36, .32)
  # home language, pooled age 5+, English at the bottom
  lc <- colSums(demo[i, c("C16001_001E", names(lang_lab))])
  lz <- data.frame(variable = factor(lang_order, levels = lang_order), percent = 100 * lc[lang_order] / lc[["C16001_001E"]])
  lz$ymax <- pmin(100, cumsum(lz$percent)); lz$ymin <- lz$ymax - lz$percent
  lb <- ggplot(lz) + geom_rect(aes(xmin = 0, xmax = 1, ymin = ymin, ymax = ymax, fill = variable), color = "white", linewidth = .15) +
    geom_text(data = lz[lz$percent >= 10, ], aes(x = .5, y = (ymin + ymax) / 2, label = sprintf("%.0f%%", percent)),
              size = 5, color = "#202020") +
    scale_fill_manual(values = lang_col) +
    scale_y_continuous(limits = c(0, 100.001), breaks = c(0, 50, 100), labels = c("0%", "50%", "100%"), expand = c(0, 0)) +
    scale_x_continuous(limits = c(0, 1), expand = c(0, 0)) + theme_minimal(base_family = FONT) +
    theme(axis.title = element_blank(), axis.text.x = element_blank(), axis.text.y = element_text(size = 14),
          axis.ticks = element_blank(), panel.grid = element_blank(), legend.position = "none", plot.margin = margin(7, 8, 7, 0))
  draw_at(lb, lm + colstart[3] + colwidth[3] / 2, ymid, colwidth[3], rowh - .08)
  # precinct median income: equal-precinct density, $10k bandwidth, reflected at 0 and $200k (top-coded)
  x <- demo$median_income[i] / 1000; x <- pmin(x[is.finite(x)], 200)
  de <- density(c(-x, x, 400 - x), bw = 10, from = 0, to = 200, n = 512)
  dp <- ggplot(data.frame(income = de$x, density = 3 * de$y), aes(income, density)) + geom_area(fill = color, alpha = .9) +
    geom_line(color = colorspace::darken(color, .3), linewidth = .65) +
    geom_vline(xintercept = income_ref, linetype = "dashed", color = "#555555", linewidth = .45) +
    scale_x_continuous(limits = c(0, 200), breaks = c(0, 100, 200), expand = expansion(mult = c(.06, .06))) +
    scale_y_continuous(expand = expansion(mult = c(0, .05))) + base +
    theme(axis.text.x = element_text(size = 18), plot.margin = margin(4, 16, 4, 3))
  draw_at(dp, lm + colstart[4] + colwidth[4] / 2, ymid, colwidth[4], rowh - .08)
  for (v in seq_along(box_vars)) {
    jc <- if (v <= 3) 5 else 6; cy <- ytop + .20 + ((v - 1) %% 3) * 1.23
    textat(box_vars[[v]], lm + colstart[jc] + .10, cy, 13, 2)
    z <- data.frame(value = demo[[names(box_vars)[v]]][i]); z <- z[is.finite(z$value), , drop = FALSE]
    bp <- ggplot(z, aes(x = value, y = 1)) +
      geom_boxplot(orientation = "y", width = .6, fill = slate, color = "#394D68", linewidth = .4,
                   outlier.size = .65, outlier.alpha = .45, outlier.stroke = 0) +
      geom_vline(xintercept = refs[[names(box_vars)[v]]], linetype = "dashed", color = "#303030", linewidth = .6) +
      scale_x_continuous(limits = c(0, 100), breaks = c(0, 25, 50, 75, 100), expand = expansion(mult = c(.06, .06))) +
      scale_y_continuous(limits = c(.4, 1.6), breaks = NULL) + base +
      theme(axis.text.x = element_text(size = 16), plot.margin = margin(0, 3, 0, 3))
    draw_at(bp, lm + colstart[jc] + colwidth[jc] / 2, cy + .60, colwidth[jc] - .08, .91)
  }
  for (jc in 4:6) for (edge in c(0, 1))
    grid.lines(x = unit(rep(lm + colstart[jc] + edge * colwidth[jc], 2), "in"),
               y = unit(H - c(ytop + .12, ytop + rowh - .12), "in"), gp = gpar(col = "#AEB6C0", lwd = .9))
}
ly <- top + length(portrait_blocs) * (rowh + rowgap)
grid.rect(x = unit(lm, "in"), y = unit(H - ly, "in"), width = unit(gw, "in"), height = unit(legh, "in"),
          just = c("left", "top"), gp = gpar(fill = "#FAFAFC", col = "#BBC1C9", lwd = 1.5))
textat("Race / ethnicity", lm + .25, ly + .32, 19, 2)
textat("Home language (age 5+); bars read bottom to top", lm + 5.2, ly + .32, 19, 2)
leg_race_lab <- c("White, non-Hispanic", "Black, non-Hispanic", "Asian, non-Hispanic", "Latino, any race", "Other (bar only)")
for (r in seq_along(bar_colors)) {
  y <- ly + .85 + (r - 1) * .5
  grid.rect(x = unit(lm + .25, "in"), y = unit(H - y, "in"), width = unit(.34, "in"), height = unit(.25, "in"), just = "left",
            gp = gpar(fill = bar_colors[[r]], col = NA))
  textat(leg_race_lab[r], lm + .73, y, 16)
}
for (r in seq_along(lang_order)) {
  v <- lang_order[r]; column <- (r - 1) %/% 5; row <- (r - 1) %% 5
  x <- lm + 5.2 + column * 5.4; y <- ly + .85 + row * .5
  grid.rect(x = unit(x, "in"), y = unit(H - y, "in"), width = unit(.34, "in"), height = unit(.25, "in"), just = "left",
            gp = gpar(fill = lang_col[[v]], col = NA))
  textat(lang_lab[[v]], x + .48, y, 14)
}
textat("Race: one dot per 20 residents, placed uniformly within the bloc's precincts; not residential locations. Boxes and income densities weight precincts equally.", lm, H - .62, 10)
textat("Dashed lines: city-wide pooled values. 2020-2024 ACS allocated to precincts by 2020 block population. Precinct incomes above $200k are top-coded.", lm, H - .3, 10)
invisible(dev.off())

## 3. Jensen-Shannon principal coordinates, coloured three ways -----------------------------------------------
# Principal coordinates of the precincts' Jensen-Shannon distances across the 64 propositions (js_pcoa()),
# PC1 against PC2, coloured by bloc, by the largest racial or ethnic group, and by the college-educated share.
js <- js_pcoa(d, n_pc = 3)
co <- as.data.frame(js$coords[, 1:2]); names(co) <- c("PC1", "PC2")
ix <- match(rownames(js$coords), d$units)
if (cor(co$PC1, nv[ix]) < 0) co$PC1 <- -co$PC1                        # PC1 runs toward the more Democratic precincts
co$bloc <- factor(bloc[ix], levels = seq_len(K))
race_sh <- as.matrix(demo[ix, c("pct_white", "pct_black", "pct_asian", "pct_hispanic")])
co$race <- factor(c("White", "Black", "Asian", "Latino")[max.col(race_sh, ties.method = "first")],
                  levels = c("White", "Black", "Asian", "Latino"))
co$race_share <- apply(race_sh, 1, max)
co$ba_plus <- demo$pct_ba_plus[ix]
r2 <- function(y, x) summary(lm(y ~ x))$r.squared
cat(sprintf("\nJS principal coordinates: PC1 %.1f%%, PC2 %.1f%% of the variation; %d precincts on %d propositions\n",
            js$pct[1], js$pct[2], nrow(co), js$n_questions))
cat(sprintf("R^2 of PC1, PC2 on: blocs %.2f, %.2f; race shares %.2f, %.2f; BA+ share %.2f, %.2f; normal vote %.2f, %.2f\n",
            r2(co$PC1, co$bloc), r2(co$PC2, co$bloc), r2(co$PC1, race_sh), r2(co$PC2, race_sh),
            r2(co$PC1, co$ba_plus), r2(co$PC2, co$ba_plus), r2(co$PC1, nv[ix]), r2(co$PC2, nv[ix])))

ax <- labs(x = sprintf("PC1 (%.0f%% of variation)", js$pct[1]), y = sprintf("PC2 (%.0f%%)", js$pct[2]))
th <- theme_minimal(base_size = 11) + theme(aspect.ratio = 1, legend.position = "bottom", legend.direction = "vertical",
                                            panel.grid.minor = element_blank(), plot.title = element_text(face = "bold"))
ctr <- aggregate(cbind(PC1, PC2) ~ bloc, co, median)
p_bloc <- ggplot(co, aes(PC1, PC2, colour = bloc)) + geom_point(size = 1.1, alpha = .75) +
  geom_label(data = ctr, aes(label = bloc), size = 3.2, fontface = "bold", show.legend = FALSE,
             fill = grDevices::adjustcolor("white", .85)) +
  scale_colour_manual(values = pal, labels = sprintf("%d %s", seq_len(K), bloc_names), name = NULL) +
  guides(colour = guide_legend(ncol = 1, override.aes = list(size = 3, alpha = 1))) + ax + th + ggtitle("Bloc")
p_race <- ggplot(co, aes(PC1, PC2, colour = race, alpha = race_share)) + geom_point(size = 1.1) +
  scale_colour_manual(values = c(White = "#E53935", Black = "#2468DC", Asian = "#159447", Latino = "#F28C28"), name = "Largest group") +
  scale_alpha(range = c(.25, 1), limits = c(25, 100), name = "Its share (%)") +
  guides(colour = guide_legend(ncol = 2, order = 1, override.aes = list(size = 3)), alpha = guide_legend(order = 2, nrow = 1)) + ax + th +
  ggtitle("Race and ethnicity") + theme(legend.box = "vertical")
p_edu <- ggplot(co, aes(PC1, PC2, colour = ba_plus)) + geom_point(size = 1.1) +
  scale_colour_gradient(low = "#DCE6F2", high = "#08306B", limits = c(0, 100), name = "Adults 25+ with a\nbachelor's degree (%)") +
  guides(colour = guide_colourbar(direction = "horizontal", barwidth = 10)) + ax + th + ggtitle("Education")
ggsave(file.path(out, "js_pca_demography.png"),
       (p_bloc | p_race | p_edu) + plot_annotation(
         title = "San Francisco's precincts in Jensen-Shannon principal coordinates of 64 propositions",
         subtitle = sprintf("The same %d precincts in each panel; numbers mark bloc medians", nrow(co))),
       width = 15, height = 7.5, dpi = 150, bg = "white")
