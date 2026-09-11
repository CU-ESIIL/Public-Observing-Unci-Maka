# Claude Memory — Public Observing Unci Maka

## Project Overview
ESIIL working group bringing together Tribal members, scientists, and NASA researchers to monitor environmental impacts (uranium mining legacy) on Hopi and Pine Ridge Reservations using earth observation data. Focused on Craven Canyon / Cheyenne River study area, South Dakota.

## Repo Structure
```
notebooks/PineRidge/  # Cheyenne River cottonwood notebooks (00, 01a, 01, 01s, NAIP, 03–06 stubs)
notebooks/Hopi/       # Blue Canyon EMIT/HLS exploratories
notebooks/archive/    # Retired: the two duplicate HLS notebooks
planning/           # Research plans — START HERE, see below
runs/               # Run manifests (small JSON, tracked in git; the rasters are not)
data/               # Study area boundaries + VBET intermediates (gitignored via *data/)
tools/emit/         # NASA EMIT data tools (vendored, not a submodule)
tools/STELLA/       # STELLA-Q2 field spectrometer CSV outputs
docs/resources/     # mkdocs site source — cyverse_basics.md is the key setup guide
docker/jupyterlab/  # Dockerfile + environment.yml for CyVerse Docker image
environment.yml     # Root conda env for local and manual CyVerse installs
requirements.txt    # Docs-only (mkdocs/GitHub Pages CI) — NOT the project environment
```

## Environment Files — There Are Three, Each Has a Different Purpose
| File | Purpose | Python | Named |
|---|---|---|---|
| `environment.yml` (root) | Local dev + manual CyVerse install | 3.12 | `unci-maka-py` |
| `docker/jupyterlab/environment.yml` | Baked into CyVerse Docker image | 3.12 | `unci-maka-py` |
| `requirements.txt` | mkdocs docs build + gh-pages CI only | n/a | n/a |

The two `environment.yml` files should stay in sync on core packages. The docker one additionally includes JupyterLab infrastructure packages (`nb_conda_kernels`, `papermill`, `jupyterlab-geojson`, `openssh`, etc.).

> **Deliberate drift — do not "fix":** the root `environment.yml` is ahead of the docker one.
> The Docker image is not being rebuilt right now, and on CyVerse the gap is closed by
> `scripts/setup_cyverse.sh`, which builds the env from the root `environment.yml` into
> data-store.
>
> **Pending for the next image rebuild** — add all of these to `docker/jupyterlab/environment.yml`
> at the same time: `whitebox`, `scikit-image`, `scikit-learn`, `odc-stac`, and pip `mgrs`.

Note there is a **fourth** environment present on CyVerse that this repo does not define:
`hyr-sense`, baked into the ESIIL image. It is Python 3.10 with an older pinned stack and is
**not used** by these notebooks — see the warning below.

## Cottonwood Mapping — read the plan first

**`planning/Cheyenne_River_cottonwood_research_plan.md` is the source of truth** for the Cheyenne
River cottonwood work: research questions, design, phase status, a decision log, and a `VERIFY`
list of unchecked assumptions. It is a living document — update it at phase gates, append to the
decision log rather than rewriting it.

`planning/AZ_invasive_riparian_research_plan.md` is a separate geography. Neither supersedes the other.

### Decisions that are settled (do not relitigate)

| Decision | Value |
|---|---|
| Tiling unit | **MGRS 100-km squares**; HLS/Sentinel-2 granules already ship on this grid |
| Pilot tile | **13TFJ** — holds Angostura, Buffalo Gap, Red Shirt, Scenic |
| Corridor extent | **9 MGRS squares across UTM zones 13 AND 14** — it crosses the −102° boundary, so EPSG:32613 is *not* right corridor-wide |
| Analysis mask | **large + medium drainage classes only**; the 162 small-class badlands draws are excluded |
| Code organisation | **Notebooks, no `src/` package** — these are a teaching product; readability beats DRY |
| GEE | Deferred, not excluded; revisit only on measured cost evidence |
| Reproducibility | Run manifests always committed to `runs/`; rasters never in git |
| WhiteboxTools | **MIT core tools only, no plugins/extensions** (see below) |

### Phase status
Phase 0 (foundations) and Phase 1a (VBET smoke test) are **done**. Phase 1b (VBET on all of 13TFJ)
and Phase 2 (NAIP auto-labels) are next.

## Key Environment Decisions Made
- **Slimmed root `environment.yml`** to ~23 packages (was 38). Removed transitive deps (shapely, pyproj, bokeh, fsspec, aiohttp, requests) and EMIT-only packages (panel, spectral, scikit-image, netCDF4, h5netcdf, s3fs, zarr, cartopy). These can be pip-installed separately when needed.
- **`pynhd`, `py3dep`** are core to the NHD/DEM workflow. `py3dep` is now only for small AOIs — see the VBET section below.
- **`whitebox`** (WhiteboxTools) is the hydrology engine for VBET, replacing `pysheds`. `pysheds` is kept in the env until the WBT path is validated end-to-end, then can be dropped.
- **`localtileserver`** is pip-only (not on conda-forge).
- **EMIT tools** (spectral, scikit-image, netCDF4, panel, s3fs) can be added with `pip install spectral scikit-image netCDF4 panel s3fs zarr` when running EMIT notebooks.

## CyVerse Deployment — Critical Facts
- **Deployment**: Docker image built from `docker/jupyterlab/Dockerfile` → pushed to DockerHub → used by CyVerse "JupyterLab ESIIL" app.
- **GitHub Actions**: `build-and-push-jupyterlab-image.yml` (manual trigger) builds/pushes the image. `gh-pages.yml` (push to main) deploys mkdocs site.
- **Ephemeral containers**: envs *you create* in `/opt/conda/envs/` do NOT persist, and neither do `pip install`s into an existing env. But conda's `--prefix` can place an env anywhere — putting it in `~/data-store/` makes it persist. That is the whole trick.
- **Persistent storage**: `/home/jovyan/data-store/` persists. Clone the repo there, and keep envs/binaries/data there too.
- **Kernel registrations never persist** — `scripts/setup_cyverse.sh` re-registers each session; that is the only step that genuinely must repeat.
- **Memory constraint**: CyVerse containers have limited RAM. `mamba env create` with large envs segfaults. Fix: `conda config --set fetch_threads 1 && conda config --set extract_threads 1` before install.

## CyVerse Setup Sequence (Every Session)
```bash
cd ~/data-store/Public-Observing-Unci-Maka && git pull
bash scripts/setup_cyverse.sh
```
Then refresh the browser tab and pick the "Python (Unci Maka / VBET)" kernel.

`scripts/setup_cyverse.sh` builds a **self-contained conda env at a prefix in data-store**:
`mamba env create --prefix ~/data-store/envs/unci-maka -f environment.yml`. Conda envs do not
have to live in `/opt/conda/envs` — `--prefix` puts one in persistent storage, so it is built
once (10-20 min) and reused. Only kernel registration repeats each session.

**Do NOT layer a venv on HYR-SENSE.** This was tried and fails in two directions at once:
pip installs a new numpy into the venv which shadows HYR-SENSE's numpy but not its
NumPy-1.x-compiled pandas/pyarrow (`AttributeError: _ARRAY_API not found`), while simultaneously
skipping the aiohttp upgrade because the old copy looks like it satisfies the requirement
(`ImportError: cannot import name 'ClientConnectorDNSError'`). HYR-SENSE is Python 3.10 with a
pinned older stack; a mixed-provenance site-packages tree cannot be made consistent.
The notebooks must run on the `unci-maka` kernel, never HYR-SENSE.

The script verifies the stack (numpy/pandas/pyarrow ABI, pyproj EPSG:32613, pynhd/aiohttp)
*before* registering the kernel, so a broken env never reaches a notebook. It also prunes dead
kernels pointing into `data-store/envs`, and never touches image-provided kernels.

Override the location with `ENV_DIR=<path>`; rebuild with `--recreate`.

### PROJ path resolution in the notebooks
All three notebooks use a `_find_share()` helper that checks `sys.prefix` **then**
`sys.base_prefix`, and verifies the directory exists. With the standalone conda env `sys.prefix`
is correct on its own; the fallback is retained because it is free and makes the notebooks work
under a venv too. The kernel spec also sets `PROJ_DATA`/`GDAL_DATA` explicitly.

## VBET / Valley Bottom Pipeline (notebooks 00 → 01a → 01)

Produces `data/cheyenne_valley_bottom.gpkg`, the riparian analysis extent that notebooks 02–06
clip cottonwood classification to.

| Notebook | Produces |
|---|---|
| `00_Study_Area-Cottonwoods.ipynb` | `cheyenne_corridor_aoi.gpkg` — corridor AOI + flowlines + gauges |
| `01a_DEM_Prefetch.ipynb` | `cheyenne_dem_30m.tif`, `cheyenne_flowlines_vaa.gpkg`, persistent WBT binary |
| `01_VBET_ValleyBottom.ipynb` | `cheyenne_valley_bottom.gpkg`, `cheyenne_valley_mask_30m.tif` |
| `01s_VBET_SmokeTest.ipynb` | 20 × 20 km box at Red Shirt — runs in seconds, validates the whole chain. **Run this first on a new machine.** Writes patches, a binary uint8 mask for clipping imagery, and a manifest. |
| `NAIP_Tile_Analysis.ipynb` | NAIP chip via Planetary Computer (anonymous) |

**Scale**: corridor AOI is ~6,225 km² over a 228 × 187 km envelope, 8,964 NHD reaches
(17,361 km). At 30 m that is ~47 M cells.

### DEM — do NOT use `py3dep.get_dem()` for the corridor
`py3dep` hits the 3DEP **dynamic** service, which renders elevation on demand. It is fine for a
few hundred km² and effectively unusable at corridor scale — this was the original bottleneck.
Notebook 01a instead pulls **static staged 3DEP COG tiles** from the public USGS S3 bucket:
```
https://prd-tnm.s3.amazonaws.com/StagedProducts/Elevation/{1|13}/TIFF/current/{tile}/USGS_{1|13}_{tile}.tif
```
`1` = 1 arc-sec (~30 m), `13` = 1/3 arc-sec (~10 m). Tiles are named by their **NW corner**
(`n44w104` = lat 43–44, lon −104 to −103). The corridor needs 8 tiles at 30 m, ~415 MB total.
Downloads are resumable and cached; `BuildVRT` + one `Warp` mosaics, reprojects to EPSG:32613,
and clips in a single pass.

### Hydrology — WhiteboxTools, not pysheds
`pysheds` holds several full-grid float32 arrays in Python memory at once (~190 MB each at 30 m),
which is the memory wall on CyVerse. WBT is a multithreaded Rust engine that streams to/from disk.

**The chain changed in Sept 2026 — three tools, not six:**
```
BreachDepressionsLeastCost → ElevationAboveStream (HAND, vs rasterized NHD) → Slope
```
`D8FlowAccumulation` → `ExtractStreams` was dropped because **flow accumulation is the only
globally-dependent step**: it needs the whole upstream watershed, so it cannot be computed
correctly inside a clipped tile — streams entering from outside start at zero. The NHD flowlines
are used as the stream network instead, and they already carry surveyed `totdasqkm`. `D8Pointer`
went with it: `elevation_above_stream(dem, streams, output)` takes no pointer and derives its own
flow paths. Every remaining step is local, so **tile seams stop mattering**.

Verified at Red Shirt: HAND is exactly 0 m at every stream cell, nodata 2.3% (box edges only),
all three steps 0.1 s on 0.44 M cells. Median NHD-vs-terrain offset 2.5 m, so no snapping needed
*there* — re-check when moving beyond 13TFJ.

**WhiteboxTools licensing (checked 2026-09-11):** the core is **MIT** and all three tools used are
in the core binary, not the 25 bundled plugins. The commercial surface (Whitebox Toolset Extension,
the vendor's own Python line) is not in our path. **Rule: core tools only.** If a step needs a
plugin — note the lidar tools *are* plugins — switch to `lidR`/PDAL/GRASS rather than buy a licence.
The dependency is shallow by design: `gdaldem slope`, RichDEM/GRASS `r.hydrodem`, and GRASS
`r.stream.distance` cover all three.

**CyVerse gotcha**: `WhiteboxTools()` calls `download_wbt()` from its constructor, fetching a
~200 MB binary into the `whitebox` package dir under `/opt/conda`, which does not persist.
Two facts from the package source:
- `download_wbt()` returns early if the **`WBT_PATH`** env var is set — set it *before*
  constructing `WhiteboxTools`, or the download happens anyway.
- `exe_path` is the **directory** holding `whitebox_tools` plus `plugins/` and `img/`, not the
  executable's path. `set_whitebox_dir(d)` just assigns it. Copy the whole directory, not just
  the binary, or plugin-backed tools fail to launch.

Notebook 01a copies it to `~/data-store/bin/WBT` and chmods the binary and plugins; both
notebooks then set `WBT_PATH` + `set_whitebox_dir()` when that path exists. Adding
`export WBT_PATH=/home/jovyan/data-store/bin/WBT` to the shell profile makes it apply everywhere.

### Data directory resolution
All three notebooks call `_resolve_data_dir()`, which prefers `$VBET_DATA_DIR`, else walks up
from the working directory to the repo root (`.git` / `environment.yml`) and returns
`<repo>/data`, else falls back to `../data`. Walking up makes it cwd-independent, so it works
from `notebooks/`, from the repo root, and under papermill.

**Do not set `VBET_DATA_DIR` in the kernel spec.** On CyVerse the repo is cloned into
`~/data-store`, so `<repo>/data` is already persistent — no redirect is needed. An earlier
version of `setup_cyverse.sh` pointed it at a fresh empty directory, which overrode the repo
path and caused `cheyenne_corridor_aoi.gpkg not found` while the file sat in the repo. Set it
manually only to relocate the big rasters somewhere else.

### Chunking
Section 8 of notebook 01 has an optional HUC-8 chunked path (`USE_HUC_CHUNKING = True`), off by
default — 30 m runs single-pass fine. It exists for small instances and for 10 m runs (~420 M
cells). **Chunk by HUC, never by arbitrary tiles**: HUC boundaries are drainage divides, so no
flow crosses them and D8 routing stays valid. Rectangular tiles sever contributing area and
corrupt flow accumulation and HAND at every seam.

### Bugs fixed in this rework (don't reintroduce)
- Flowlines from notebook 00 carry only `nhdplus_comid`, no `totdasqkm`. The VBET drainage-area
  classing silently fell through and assigned **every** reach to `medium` — the Cheyenne main
  stem got headwater thresholds. 01a joins `pynhd.nhdplus_vaa()` on COMID to fix it.
- `FLOW_ACCUM_THRESHOLD` was hardcoded to 500 cells and documented as "~50 km² at 10 m"; at 30 m
  that is 450 km². It is now derived from `STREAM_INIT_KM2` and resolution.
- The min-patch filter looped per connected component (`(labeled == i).sum()` over 47 M cells,
  thousands of times). Now a single `np.bincount`.
- Buffered flowlines were `union_all()`-ed before rasterizing. Rasterizing overlapping polygons
  to the same burn value already unions them; the union was pure waste.
- Output provenance recorded `gauge_id` even for full-corridor runs.

## NAIP Imagery (`notebooks/PineRidge/NAIP_Tile_Analysis.ipynb`)

Pulls a high-resolution NAIP chip centered on a USGS stream gauge to look for cottonwood gallery
forest. Consumes the `usgs_gauges` layer of `cheyenne_corridor_aoi.gpkg` (notebook 00); feeds the
still-empty notebooks 03/04. Currently one gauge, one tile — the loop comes later.

- **Source is Planetary Computer STAC, not AWS.** `https://planetarycomputer.microsoft.com/api/stac/v1`,
  collection `naip`, with `modifier=planetary_computer.sign_inplace`. Signing works **anonymously**
  — no account, no subscription key. The original notebook used requester-pays
  `s3://naip-analytic`, which needs per-user AWS keys and bills egress; that is the wrong shape for
  a shared working-group notebook and was removed along with `boto3`.
- **SAS tokens expire (~45 min).** A read that suddenly 403s means a stale token: re-run the STAC
  search cell, don't debug the raster.
- **Gauge filter — this one bites.** The `usgs_gauges` layer holds 259 NLDI sites, but **211 are
  15-digit groundwater/miscellaneous sites with no discharge record**. Only the **48 8-digit** ids
  are surface-water stream gauges. Filter on `site_no.str.len() == 8` before doing anything else.
- **CRS: NAIP is EPSG:26913** (NAD83 / UTM 13N), the VBET pipeline is EPSG:32613 (WGS84 / UTM 13N).
  Same zone, different datum, ~1-2 m apart. The notebook takes the CRS off the opened raster and
  reprojects the gauge point into it rather than hardcoding either one.
- **PC catalog ends at 2023**, so 2022 is the newest South Dakota epoch available there. Gauge
  06403700 (Red Shirt) has 7 epochs: 2012 and 2014 at 1 m, 2016/2018/2020/2021/2022 at 60 cm —
  a ready-made series for the change detection in notebook 06.
- Reads are windowed straight out of the COG under `GDAL_DISABLE_READDIR_ON_OPEN="EMPTY_DIR"`;
  nothing downloads a full tile.

## Known Issues and Fixes

### Folium basemap shows "API KEY REQUIRED"
CARTO now requires an API key. Their servers still return HTTP 200 — they burn the watermark into
the tile — so it fails silently rather than erroring. Do not use `tiles="CartoDB positron"`. Use
Esri, which needs no key: `.../Canvas/World_Light_Gray_Base/MapServer/tile/{z}/{y}/{x}` for a light
reference map, `.../World_Imagery/...` for aerial. Both are in notebooks 00 and 01.

### USGS gauge records are wildly uneven — check before analysing
- `usgs_gauges` holds ~275 NLDI sites; only the **8-digit** ids are surface-water gauges.
- **06439500 Eagle Butte is discontinued**: 1934–1967, then only two partial years (2007–08).
  Its 2008 "annual mean" is inflated by a real 65,200 cfs flood and wrecks any multi-year plot.
- **06401500 Angostura is seasonal** — ~181 days/year since 1978. A "complete calendar year" filter
  silently discards a continuous 1945–2024 record. Notebook 00 requires a minimum number of
  contributing **years per day-of-year** instead.
- **Wasta (93 yrs) and Plainview (54 yrs)** are the only gauges spanning the full Landsat record.
- Median flow below Angostura is **~2 cfs** vs **~65 cfs** at Buffalo Gap just downstream.
### PROJ/CRS Errors (`pyproj unable to set PROJ database path` / `CRSError: no database context`)
- **Root cause**: Jupyter kernel starts without `conda activate`, so PROJ_DATA/GDAL_DATA env vars are never set.
- **Fix 1 (preferred)**: Use the `--env` flags in the `ipykernel install` command above — bakes paths into the kernel spec.
- **Fix 2 (in-notebook fallback)**: Add as the very first cell, before any imports:
  ```python
  import os, sys
  os.environ['PROJ_DATA'] = os.path.join(sys.prefix, 'share', 'proj')
  os.environ['PROJ_LIB'] = os.path.join(sys.prefix, 'share', 'proj')
  ```

### `mamba env create` Segfault / `std::bad_alloc`
Set thread limits before running: `conda config --set fetch_threads 1 && conda config --set extract_threads 1`

### `EnvironmentNameNotFound` / kernel missing after a session restart
Expected — kernel registrations never persist. Re-run `bash scripts/setup_cyverse.sh` and refresh
the browser tab. The conda env and WBT binary in `~/data-store/` are detected and reused, so
this takes seconds, not minutes.

### `_ARRAY_API not found` / `cannot import name 'ClientConnectorDNSError'`
The notebook is running on the **hyr-sense kernel**, not `unci-maka`. Switch kernels and restart.
These two errors always appear together and always mean mixed-provenance site-packages.

### Environment half-built or broken
`bash scripts/setup_cyverse.sh --recreate` re-solves from scratch. The WBT binary and
`VBET_DATA_DIR` live outside the env and are preserved.

## Docs Site
- URL: https://cu-esiil.github.io/Public-Observing-Unci-Maka
- Built with mkdocs-material, deployed via GitHub Actions on push to main
- Key guide: `docs/resources/cyverse_basics.md`

## GitHub Workflows
- `fetch-template.yml` — syncs from `CU-ESIIL/Working_group_OASIS` template (manual trigger)
- `build-and-push-jupyterlab-image.yml` — builds + pushes Docker image (manual trigger, needs DOCKERHUB_USERNAME / DOCKERHUB_PASSWORD secrets)
- `gh-pages.yml` — deploys mkdocs site (auto on push to main, needs GH_TOKEN secret)
