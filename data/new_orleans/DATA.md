# Greater New Orleans: how the model-ready data were made

Greater New Orleans is a **metro cut-out** of the Louisiana data: the same returns, alignment and unit map, restricted to the metro area's units. It is not a separate data collection or a separate fit; on the atlas it shows the Louisiana blocs inside the metro area. Everything about sources, shapefiles and alignment is in [`../la/DATA.md`](../la/DATA.md).

| | |
|---|---|
| Parent | [`la`](../la/) (Louisiana) |
| Area | The eight-parish New Orleans–Metairie metropolitan area (OMB 2023): Jefferson, Orleans, Plaquemines, St. Bernard, St. Charles, St. James, St. John the Baptist and St. Tammany (parish codes 051, 071, 075, 087, 089, 093, 095, 103). Not Orleans Parish alone. |
| Units | 928 precincts |
| Years | 2000–2024 |
| Ballot measures | 168 |
| Federal contests | 18 (President and US Senate) |

The cut-out is defined in `code/atlas/build_panels.R` (`sub_place()`) in the Local Politics project. The files here are the parent's files restricted to these units, written by `scripts/export_model_ready.R`.
