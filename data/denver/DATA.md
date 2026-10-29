# Greater Denver: how the model-ready data were made

Greater Denver is a **metro cut-out** of the Colorado data: the same returns, alignment and unit map, restricted to the metro area's units. It is not a separate data collection or a separate fit; on the atlas it shows the Colorado blocs inside the metro area. Everything about sources, shapefiles and alignment is in [`../co/DATA.md`](../co/DATA.md).

| | |
|---|---|
| Parent | [`co`](../co/) (Colorado) |
| Area | Seven counties: Adams, Arapahoe, Boulder, Broomfield, Denver, Douglas and Jefferson. A precinct is in if its point on surface falls in one of them. |
| Units | 1,728 (2024 precincts) |
| Years | 2011–2025 |
| Ballot measures | 78 |
| Federal contests | 8 (President and US Senate) |

The cut-out is defined in `code/atlas/build_panels.R` (`sub_place()`) in the Local Politics project. The files here are the parent's files restricted to these units, written by `scripts/export_model_ready.R`.
