# San Diego County: how the model-ready data were made

San Diego County is a **metro cut-out** of the California data: the same returns, alignment and unit map, restricted to the metro area's units. It is not a separate data collection or a separate fit; on the atlas it shows the California blocs inside the metro area. Everything about sources, shapefiles and alignment is in [`../ca/DATA.md`](../ca/DATA.md).

| | |
|---|---|
| Parent | [`ca`](../ca/) (California) |
| Area | San Diego County: every 2024 precinct whose id begins with county FIPS `06073`. |
| Units | 1,859 precincts |
| Years | 2012–2024 |
| Ballot measures | 74 |
| Federal contests | 9 (President and US Senate) |

The cut-out is defined in `code/atlas/build_panels.R` (`sub_place()`) in the Local Politics project. The files here are the parent's files restricted to these units, written by `scripts/export_model_ready.R`.
