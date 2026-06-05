# Plan: Cheyenne River Corridor — Study Area Definition (Notebook 00)

## Context

The cottonwood classification workflow starts with defining an AOI covering the Cheyenne River corridor from Angostura Reservoir (near Hot Springs, SD) downstream/eastward to Oahe Reservoir (Missouri River, near Eagle Butte, SD). Notebook `00_Study_Area-Cottonwoods.ipynb` was incomplete — it had a working pynhd NLDI data fetch but the Folium map cell crashed with a geometry access bug, and the scope was only loosely defined around one gauge.

The outputs of this notebook feed into `01_VBET_ValleyBottom.ipynb` as the authoritative study area.

## Confirmed USGS Gauge IDs (Cheyenne River main stem, west → east)

| Site ID | Name | Lon |
|---------|------|-----|
| `06401500` | Cheyenne R below Angostura Dam, SD | -103.44 |
| `06402600` | Cheyenne R near Buffalo Gap, SD | -103.07 |
| `06403700` | Cheyenne R at Red Shirt, SD *(reference)* | -102.89 |
| `06408650` | Cheyenne R near Scenic, SD | -102.64 |
| `06423500` | Cheyenne R near Wasta, SD | -102.40 |
| `06438500` | Cheyenne R near Plainview, SD | -101.93 |
| `06439500` | Cheyenne R near Eagle Butte, SD | -101.22 |

**Note:** `06404000` is Battle Creek near Keystone — NOT the Cheyenne main stem. Do not use.

## What Was Built

### `notebooks/00_Study_Area-Cottonwoods.ipynb` (fully rewritten)

10-cell notebook:
1. Title markdown
2. Setup — imports + PROJ env vars
3. **Gauge anchors** — fetch `06401500` (Angostura), `06403700` (Red Shirt), `06439500` (Eagle Butte)
4. **Flowlines** — navigate upstream from Eagle Butte (`upstreamMain` + `upstreamTributaries` distance=600 km), clipped to corridor bounding box; tributaries filtered to 30 km (0.27°) lateral buffer around main stem to exclude Belle Fourche headwaters
5. **USGS gauge sites** — all gauges within 30 km of main stem, displayed sorted west→east
6. **Export** → `data/cheyenne_corridor_aoi.gpkg` with three layers: `study_area`, `flowlines`, `usgs_gauges`
7. **Folium interactive map** — main stem (dark blue), tributaries (light blue), anchor gauges (red), other gauges (yellow); fixed original bug (`station.geometry.y` → `station.geometry.iloc[0].y`)
8. Hydrograph section markdown
9. **Hydrograph fetch** — `dataretrieval.nwis.get_dv()`, daily discharge (param 00060), 1990–2024
10. **Hydrograph plot** — annual mean discharge, one panel per gauge, sorted upstream→downstream

### `notebooks/01_VBET_ValleyBottom.ipynb` (minor update)

Added **Option D** to the AOI configuration cell: when `data/cheyenne_corridor_aoi.gpkg` exists (produced by notebook 00), it loads the pre-built AOI polygon and flowlines instead of re-fetching from NLDI.

### `environment.yml` and `docker/jupyterlab/environment.yml`

Added `dataretrieval` to the `pip:` section of both files (USGS NWIS Python client, pip-only).

## Key Design Decisions

- **Navigate from downstream anchor** (`06439500`) upstream — NLDI `upstreamTributaries` traversal direction captures main stem and all tributaries from Oahe back to Angostura.
- **30 km lateral trib filter** — `unary_union(flw_main.geometry.values).buffer(0.27°)` keeps direct Cheyenne tributaries while excluding Belle Fourche headwaters that extend 50+ km from the main stem.
- **Hydrograph in notebook 00** (not separate notebook) — gauge discovery and discharge data access stay together; substantive analysis can be split out later if needed.

## Verification Checklist

- [ ] Run notebook 00 top-to-bottom with no errors
- [ ] Folium map renders; anchor gauges appear in red at correct locations
- [ ] `data/cheyenne_corridor_aoi.gpkg` created with three layers
- [ ] Flowlines span lon ≈ -103.4 (Angostura) to -101.2 (Eagle Butte)
- [ ] Hydrograph plot shows data for at least Red Shirt (`06403700`) and Eagle Butte (`06439500`)
- [ ] Notebook 01 with Option D active loads the GeoPackage and skips NLDI re-fetch
