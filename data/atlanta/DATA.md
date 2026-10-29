# Greater Atlanta: how the model-ready data were made

Greater Atlanta is a **metro cut-out** of the Georgia data: the same returns, alignment and unit map, restricted to the metro area's units. It is not a separate data collection or a separate fit; on the atlas it shows the Georgia blocs inside the metro area. Everything about sources, shapefiles and alignment is in [`../ga/DATA.md`](../ga/DATA.md).

| | |
|---|---|
| Parent | [`ga`](../ga/) (Georgia) |
| Area | The 11 counties of the Atlanta Regional Commission: Cherokee, Clayton, Cobb, DeKalb, Douglas, Fayette, Forsyth, Fulton, Gwinnett, Henry and Rockdale. A precinct is in if its point on surface falls in one of them. |
| Units | 1,203 precincts |
| Years | 2016–2024 |
| Ballot measures | 21 |
| Federal contests | 6 (President and US Senate) |

The cut-out is defined in `code/atlas/build_panels.R` (`sub_place()`) in the Local Politics project. The files here are the parent's files restricted to these units, written by `scripts/export_model_ready.R`.
