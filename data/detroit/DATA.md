# Greater Detroit: how the model-ready data were made

Greater Detroit is a **metro cut-out** of the Michigan data: the same returns, alignment and unit map, restricted to the metro area's units. It is not a separate data collection or a separate fit; on the atlas it shows the Michigan blocs inside the metro area. Everything about sources, shapefiles and alignment is in [`../mi/DATA.md`](../mi/DATA.md).

| | |
|---|---|
| Parent | [`mi`](../mi/) (Michigan) |
| Area | The seven SEMCOG counties: Livingston, Macomb, Monroe, Oakland, St. Clair, Washtenaw and Wayne. A precinct is in if its point on surface falls in one of them. |
| Units | 1,970 precincts |
| Years | 2014–2022 |
| Ballot measures | 10 |
| Federal contests | 7 (President and US Senate) |

The cut-out is defined in `code/atlas/build_panels.R` (`sub_place()`) in the Local Politics project. The files here are the parent's files restricted to these units, written by `scripts/export_model_ready.R`.
