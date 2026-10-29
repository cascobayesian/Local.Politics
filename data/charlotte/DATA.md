# Greater Charlotte: how the model-ready data were made

Greater Charlotte is a **metro cut-out** of the North Carolina data: the same returns, alignment and unit map, restricted to the metro area's units. It is not a separate data collection or a separate fit; on the atlas it shows the North Carolina blocs inside the metro area. Everything about sources, shapefiles and alignment is in [`../nc/DATA.md`](../nc/DATA.md).

| | |
|---|---|
| Parent | [`nc`](../nc/) (North Carolina) |
| Area | Centralina's nine North Carolina counties: Anson, Cabarrus, Gaston, Iredell, Lincoln, Mecklenburg, Rowan, Stanly and Union (the South Carolina side of the region is not in the data). A precinct is in if its point on surface falls in one of them. |
| Units | 459 precincts |
| Years | 2012–2024 |
| Ballot measures | 10 |
| Federal contests | 8 (President and US Senate) |

The cut-out is defined in `code/atlas/build_panels.R` (`sub_place()`) in the Local Politics project. The files here are the parent's files restricted to these units, written by `scripts/export_model_ready.R`.
