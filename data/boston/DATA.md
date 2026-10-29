# Greater Boston: how the model-ready data were made

Greater Boston is a **metro cut-out** of the Massachusetts data: the same returns, alignment and unit map, restricted to the metro area's units. It is not a separate data collection or a separate fit; on the atlas it shows the Massachusetts blocs inside the metro area. Everything about sources, shapefiles and alignment is in [`../ma/DATA.md`](../ma/DATA.md).

| | |
|---|---|
| Parent | [`ma`](../ma/) (Massachusetts) |
| Area | The 101 cities and towns of the Metropolitan Area Planning Council (MAPC). |
| Units | 1,190 precincts |
| Years | 2012–2024 |
| Ballot measures | 25 |
| Federal contests | 10 (President and US Senate) |

The cut-out is defined in `code/atlas/build_panels.R` (`sub_place()`) in the Local Politics project. The files here are the parent's files restricted to these units, written by `scripts/export_model_ready.R`.
