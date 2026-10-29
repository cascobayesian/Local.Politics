# Seattle (King County): how the model-ready data were made

Seattle (King County) is a **metro cut-out** of the Washington data: the same returns, alignment and unit map, restricted to the metro area's units. It is not a separate data collection or a separate fit; on the atlas it shows the Washington blocs inside the metro area. Everything about sources, shapefiles and alignment is in [`../wa/DATA.md`](../wa/DATA.md).

| | |
|---|---|
| Parent | [`wa`](../wa/) (Washington) |
| Area | King County: every 2024 precinct whose id begins `KI`. |
| Units | 2,744 precincts |
| Years | 2012–2024 |
| Ballot measures | 73 |
| Federal contests | 9 (President and US Senate) |

The cut-out is defined in `code/atlas/build_panels.R` (`sub_place()`) in the Local Politics project. The files here are the parent's files restricted to these units, written by `scripts/export_model_ready.R`.
