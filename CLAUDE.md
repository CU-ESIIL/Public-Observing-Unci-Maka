# Claude Memory — Public Observing Unci Maka

## Project Overview
ESIIL working group bringing together Tribal members, scientists, and NASA researchers to monitor environmental impacts (uranium mining legacy) on Hopi and Pine Ridge Reservations using earth observation data. Focused on Craven Canyon / Cheyenne River study area, South Dakota.

## Repo Structure
```
notebooks/PineRidge/  # Cheyenne River cottonwood notebooks 00–08 (+ checks/ for 01s)
notebooks/Hopi/       # Blue Canyon EMIT/HLS exploratories
notebooks/archive/    # Retired: 01a_DEM_Prefetch, NAIP_Tile_Analysis, 2 duplicate HLS notebooks
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
> at the same time: `whitebox`, `scikit-image`, `scikit-learn`, `odc-stac`.
> (`mgrs` was on this list and is **no longer needed** — `01` derives MGRS geometry arithmetically.)

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
Phases 0 and 1a **done**. Phase 1b **run 2026-09-11** — 13TFJ produced 814 km² of valley bottom
(8.14% of the tile) in 1.5 s of hydrology; gate needs the geomorphic check against NAIP.
Phase 2 **in progress** (`03` built and runs, still pointed at the smoke-test mask).
Phases 3–7 have skeletons.

### Notebook state — restructured 2026-09-11, start here

The plan §18 renumbering is **done**. `01a` folded into `01`; `01s` moved to `checks/`.

| Notebook | Runs? | Note |
|---|---|---|
| `00_Study_Area` | ✅ | AOI definition still under review — see below |
| `01_VBET_ValleyBottom` | ✅ run on 13TFJ | three-tool chain; `TILE` + `DEM_RES_M` drive everything |
| `02_NAIP_Access` | skeleton | NAIP epoch inventory across the tile |
| `03_NAIP_Segmentation_Labels` | ✅ | runs against the `01s` mask |
| `04`–`08` | skeletons | config cell + section headings, analysis cells empty |
| `checks/01s_VBET_SmokeTest` | ✅ | standing environment check — run first on a new machine |

**The old blocker is cleared.** `01` no longer contains `d8_pointer`, `d8_flow_accumulation`,
`extract_streams`, `FLOW_ACCUM_THRESHOLD` or HUC chunking — verified by scan. It runs the chain
validated in `01s`. **It has still never been executed**, so treat its first 13TFJ run as the
Phase 1b gate, not a routine step.

**Skeleton means**: title stating what it reads/writes, section headings, a complete config cell,
and a manifest stub — analysis cells deliberately **empty**. Per plan §14 the markdown is *not*
written in advance; the group fills these in together. Don't fill them unasked.

**MGRS geometry is arithmetic, not a package.** `01` §2 derives any square's bounds *and* its EPSG
from the tile name in ~20 lines. `13TFJ` → EPSG:32613, 600–700 km E, 4800–4900 km N; buffered grid
13.44 M cells. **`mgrs` is no longer a needed dependency.** Deriving the CRS matters because the
corridor crosses into zone 14.

**Walkthrough reaches are gauge-anchored.** Four 2 × 2 km windows, one per 8-digit gauge in 13TFJ:
`06401500` Angostura, `06402600` Buffalo Gap, `06403700` Red Shirt (validated), `06408650` Scenic.
`EXAMPLE_WINDOWS` repeats in each config cell by convention — deliberate duplication (plan §14),
don't refactor into a shared module. **Coordinates for all but Red Shirt are approximate
placeholders marked `VERIFY`** — replace from the `usgs_gauges` layer on first run.

**Scale unit differs by step, and this matters:** 13TFJ is the right unit for VBET (~13.4 M cells
at 30 m, minutes) and the *wrong* unit for NAIP (~1,473 km² of valley bottom, ~6.3 G px at 60 cm,
~56 min segmentation plus a multi-hour network read). Keep `03` window/reach-scale.

**Suggested order next session:** (1) first real run of `01` on 13TFJ → Phase 1b gate; (2) repoint
`03` to `VBET_RUN = "vbet_13TFJ"`, run the four windows → Phase 2 gate; (3) fill `02` to close the
NAIP epoch-coverage item; (4) interpret the validation sample.

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

## VBET / Valley Bottom Pipeline (notebooks 00 → 01)

Produces `data/cheyenne_valley_bottom.gpkg`, the riparian analysis extent that notebooks 02–06
clip cottonwood classification to.

| Notebook | Produces |
|---|---|
| `00_Study_Area.ipynb` | `cheyenne_corridor_aoi.gpkg` — corridor AOI + flowlines + gauges |
| `01_VBET_ValleyBottom.ipynb` | `vbet_<TILE>_valley_bottom.gpkg`, `..._valley_mask_30m.tif`, DEM, HAND, slope |
| `checks/01s_VBET_SmokeTest.ipynb` | 20 × 20 km box at Red Shirt — seconds, validates the whole chain |

`01` fetches its own DEM tiles and flowlines; there is no separate prefetch notebook. The
WhiteboxTools binary is downloaded and persisted by `scripts/setup_cyverse.sh`, which also bakes
`WBT_PATH` into the kernel spec — notebooks only *use* it.

**Scale**: corridor AOI is ~6,225 km² over a 228 × 187 km envelope, 8,964 NHD reaches
(17,361 km). At 30 m that is ~47 M cells.

### The corridor AOI is buffer-defined, and that is under review

`00` builds the AOI from three arbitrary numbers: a 0.5° bbox pad, a **30 km** tributary filter
(`TRIB_BUFFER_DEG = 0.27`, there to exclude the Belle Fourche), and a **10 km** main-stem buffer.
Replacing them with HUC12 units was tested on 2026-09-11. **Measured, against the `01s` valley
bottom as the containment test:**

| AOI rule | km² | holds valley bottom |
|---|---|---|
| HUC12s touching the main stem | 3,966 | **62.7%** ✗ clips a third of the corridor |
| HUC12s touching any corridor flowline | 19,038 | 100% but 3× too big |
| HUC12s intersecting the current AOI | 10,788 | 100% but 1.7× too big |
| **current buffer AOI** | **6,225** | **91.7%** — also clips, by 8% |
| full Cheyenne basin at Eagle Butte | 62,690 | far too big |

**No HUC12 rule lands on the corridor**, because a HUC12 is a *catchment* (channel to divide) and a
riparian corridor is a *lateral* strip. Selecting whole catchments to approximate a corridor either
clips it or swallows whole uplands. Do not "fix" the AOI by switching wholesale to HUC12s.

Two things this did surface, both real:
- **The current 10 km buffer already clips ~8% of the valley bottom.** Whatever AOI is used must be
  validated as a *superset* of the valley bottom, not assumed to be one.
- **HUC topology is the right tool for the *tributary filter*, not for the extent.** The arbitrary
  30 km buffer that excludes the Belle Fourche can be replaced by dropping its HUC8s
  (`10120201/2/3`), which is principled rather than a distance guess.

Open decision, recorded in plan §2.6 and §17.

### DEM — do NOT use `py3dep.get_dem()` for the corridor
`py3dep` hits the 3DEP **dynamic** service, which renders elevation on demand. It is fine for a
few hundred km² and effectively unusable at corridor scale — this was the original bottleneck.
Notebook `01` §4 instead pulls **static staged 3DEP COG tiles** from the public USGS S3 bucket:
```
https://prd-tnm.s3.amazonaws.com/StagedProducts/Elevation/{1|13}/TIFF/current/{tile}/USGS_{1|13}_{tile}.tif
```
`1` = 1 arc-sec (~30 m), `13` = 1/3 arc-sec (~10 m). Tiles are named by their **NW corner**
(`n44w104` = lat 43–44, lon −104 to −103). The corridor needs 8 tiles at 30 m, ~415 MB total.
Downloads are resumable and cached; `BuildVRT` + one `Warp` mosaics, reprojects to EPSG:32613,
and clips in a single pass.

### DEM resolution — 10 m is a config change, 1 m is not

Measured on the real 13TFJ run (30 m, 110 km buffered square): 13.44 M cells, hydrology
**1.5 s**, ~298 MB of intermediates, valley bottom **814 km² = 8.14% of the tile**. That 8.14%
supersedes the 14.7% extrapolated from the smoke box — the smoke box was centred on the main
stem and was not representative.

| | cells | 1 raster | intermediates | hydrology | source |
|---|---|---|---|---|---|
| 30 m | 13 M | 0.05 GB | 0.3 GB | 1.5 s | 0.2 GB (4 tiles) |
| **10 m** | 121 M | 0.48 GB | 2.7 GB | ~14 s | 1.6 GB (4 tiles) |
| 1 m | 12,100 M | 48 GB | **268 GB** | 22 min+ | 37 GB (~150 tiles) |

**Why 1 m is out, and it is not WBT's fault.** WBT streams to disk. The wall is **our own
section 8** — the valley-bottom step is plain numpy (`binary_fill_holes`, `label`, `rasterize`)
holding several full-grid arrays, which is 48 GB *each* at 1 m. That is the pysheds memory
problem relocated into our code. Also: 1 m is a different product line tiled 10 km in UTM
(`x61y479`), so `tiles_for_bbox()` — which builds 1-degree names — does not work; and the ~150
tiles span two projects of different vintage (NRCS 2018, Black Hills 2023).

**Resolution-coupled parameters are now derived, never typed** (`01` and `01s` config cells):
- `DEM_PRODUCT = {30: "1", 10: "13"}[DEM_RES_M]` — a `KeyError` beats silently upsampling 30 m
  data and calling it 10 m.
- `BREACH_DIST_CELLS = round(BREACH_DIST_M / DEM_RES_M)`, `BREACH_DIST_M = 3000`. A fixed 100
  cells is 3 km at 30 m but only 1 km at 10 m — a different hydrological assumption, silently.
- `RUN_NAME` carries the resolution (`vbet_13TFJ_30m`), so two runs coexist instead of
  overwriting. **Note the existing `vbet_13TFJ` run predates this** and keeps its old name.

**`slope_deg` is NOT resolution-portable and is deliberately left un-derived.** Slope on a finer
DEM is systematically steeper — a smaller cell resolves relief a coarse cell averages away — so
30 m thresholds reused at 10 m shrink the valley bottom for grid reasons, not geomorphic ones.
**`01s` section 9 measures the shift** across whatever resolutions have been run and prints
re-tuned thresholds. Run `01s` at 30 m, change one number to 10, re-run, read section 9 — that
is the cheap test before committing a tile.

### Canopy height — NAIP-CHM (candidate fix for the §5.1 cottonwood/willow problem)

NTSG (U. Montana) published **NAIP-CHM**, a 0.6 m canopy height model for CONUS in Nature
*Scientific Data*, derived from NAIP 4-band imagery by U-Net. **0.6 m is exactly the `03` grid**,
so no resampling. RMSE 2.28 m, r² 0.87; grassland/shrubland were oversampled in training, which
is our matrix. Mature plains cottonwood is 15–30 m against 2–6 m sandbar willow, so a 2.28 m
RMSE is comfortably inside what that separation needs.

- **Free HTTP, no GEE, no account**: `https://rangeland.ntsg.umt.edu/data/naip-chm/<year>/<utm_zone>/`
  plus `index.csv` / `index.geojson` at the root. Also `gs://naip-chm-assets/`.
- Tiled by **NAIP DOQQ quarter-quad**, named `m_<quad>_<quarter>_<zone>_<gsd>_<naip_date>_<proc_date>_chm.tif`
  — note the **second date**, which is why a naive `<naip_item>_chm.tif` guess 404s. The index's
  `source_doqq` column joins straight to the STAC item IDs `03` already pins.
- UInt16, **divide by 100 for metres**, nodata 65535. `Accept-Ranges: bytes`, so windowed COG
  reads work exactly like NAIP. ~51 MB/tile.
- **Not vegetation-masked** — buildings and infrastructure are in the surface. Matters for the
  §17 planted-tree screen; less for us, since `03` only applies height to already-woody segments.
- **Epoch gap is accepted, not a blocker** (decided 2026-09-11). The tile covering Red Shirt is
  `m_4310217_se_13_060_20230815_20231127_chm.tif` — NAIP **2023-08-15**, while `03` labels the
  **2022-07-13** scene. Quad block 43102 is absent from 2022 and present in 2023. **Mature gallery
  canopy height does not change materially in one year**, so the 2023 layer is a valid height
  reference for 2022 patches. Two things it does *not* license: assuming pixel-perfect
  co-registration between two different acquisitions, and using the gap-crossing pair to infer
  *change* in height. Use it as a static height attribute, not a time point.

#### Download vs. derive — the deciding fact is that the product is single-epoch here

**Checked 2026-09-11, every published year, for Red Shirt quad block 43102:**

| Year | 2012 | 2014 | 2015–2022 | 2023 |
|---|---|---|---|---|
| tiles in block | 0 | 0 | **0** | **256** (60 cm) |

So the published CHM gives this study area **exactly one date: 2023**. It is not a time series.
Anything else has to be derived. That reframes the choice:

| | Download | Derive (NTSG model on our NAIP) |
|---|---|---|
| Epochs | **1** (2023 only) | 2016, 2018, 2020, 2021, 2022 — plus 2023 free |
| Date-matched to `03` labels (2022) | ✗ one year off | ✓ |
| Cost | ~51 MB/tile, minutes, no deps | PyTorch + weights + conditioning rasters, GPU-ish, per-epoch inference |
| Licence | CC-BY data | MIT code |

**DECIDED 2026-09-11 — lead with the published 2023 product. Do not start with inference.**
1. **Download the 2023 tile first** to answer the one question that gates everything — does canopy
   height actually separate cottonwood from willow in *our* patches? One tile, no dependencies. If
   height does not separate them, nothing else here is worth building. The 2022→2023 gap is
   accepted on the grounds above.
2. **Only then consider inference**, which is what Phase 4/6 needs: `06` trends condition within
   fixed patches across NAIP epochs, and a single 2023 layer cannot support that.

**Bound on what deriving actually buys.** Red Shirt has 7 NAIP epochs, but the model expects
**0.6 m 4-band**. 2016/2018/2020/2021/2022 are native 60 cm and feed straight in; **2012 and 2014
are 1 m**, so they are out of the training distribution and would need resampling with degraded
accuracy. Realistically the derivable series is **2016–2022 (5 epochs)**, not back to 2012 —
shorter than the NAIP record itself.

**The dependency cost is real.** PyTorch is the exact thing SAM was rejected for at v1 as too
heavy on CyVerse (plan §5). Adding it for inference is a genuine environment decision, not a
`pip install` — so make it only after step 1 has shown the payoff.

- **Local inference details**: MIT-licensed code, published weights (`model/model_20251016.pt`),
  `scripts/inference.py` (chip 432, overlap 0.2), conditioning rasters (elevation, climate PCA,
  soil PCA) via `scripts/download_conditioning_data.py`, Python 3.11.

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

`scripts/setup_cyverse.sh` copies it to `~/data-store/bin/WBT`, chmods the binary and plugins,
and passes `--env WBT_PATH` to the kernel spec. The notebooks only set `WBT_PATH` +
`set_whitebox_dir()` when that path already exists — they never download it themselves.

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
**Removed from `01`.** With flow accumulation gone every step is local, so tile seams no longer
corrupt anything and there is nothing chunking has to protect. If a memory-constrained instance
ever needs it back, chunk by **HUC, never by arbitrary tiles** — and note that the original reason
(keeping D8 routing valid across divides) no longer applies.

### Bugs fixed in this rework (don't reintroduce)
- Flowlines from notebook 00 carry only `nhdplus_comid`, no `totdasqkm`. The VBET drainage-area
  classing silently fell through and assigned **every** reach to `medium` — the Cheyenne main
  stem got headwater thresholds. `01` now pulls `nhdflowline_network`, which carries
  `totdasqkm` directly — no separate VAA join.
- `FLOW_ACCUM_THRESHOLD` was hardcoded to 500 cells and documented as "~50 km² at 10 m"; at 30 m
  that is 450 km². It is now derived from `STREAM_INIT_KM2` and resolution.
- The min-patch filter looped per connected component (`(labeled == i).sum()` over 47 M cells,
  thousands of times). Now a single `np.bincount`.
- Buffered flowlines were `union_all()`-ed before rasterizing. Rasterizing overlapping polygons
  to the same burn value already unions them; the union was pure waste.
- Output provenance recorded `gauge_id` even for full-corridor runs.

## NAIP Imagery (archived `NAIP_Tile_Analysis.ipynb`; access pattern now in `02`/`03`)

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
- **Gauge filter — this one bites.** The `usgs_gauges` layer holds **275** NLDI sites, but **224
  are 15-digit** groundwater/miscellaneous sites with no discharge record. Only the **51 8-digit**
  ids are surface-water stream gauges. Filter on `site_no.str.len() == 8` before anything else.
  (Counts re-checked against the file on 2026-09-11; earlier 259/211/48 figures were stale.)
- **CRS: NAIP is EPSG:26913** (NAD83 / UTM 13N), the VBET pipeline is EPSG:32613 (WGS84 / UTM 13N).
  Same zone, different datum, ~1-2 m apart. The notebook takes the CRS off the opened raster and
  reprojects the gauge point into it rather than hardcoding either one.
- **PC catalog ends at 2023**, so 2022 is the newest South Dakota epoch available there. Gauge
  06403700 (Red Shirt) has 7 epochs: 2012 and 2014 at 1 m, 2016/2018/2020/2021/2022 at 60 cm —
  a ready-made series for the change detection in notebook 06.
- Reads are windowed straight out of the COG under `GDAL_DISABLE_READDIR_ON_OPEN="EMPTY_DIR"`;
  nothing downloads a full tile.

## NAIP Auto-Labels (`notebooks/PineRidge/03_NAIP_Segmentation_Labels.ipynb`)

Phase 2. Segment → cluster → rule-assign, inside the valley bottom, producing training labels with
no hand digitizing. Reads a VBET run + NAIP; writes a class raster, gallery patches, a validation
sample, and a manifest.

- **`VBET_RUN` in the config cell picks the input.** Defaults to `smoketest_redshirt` because that
  is what exists; set it to `vbet_13TFJ` when Phase 1b lands and nothing else changes.
- **`WINDOW_IDX` picks the walkthrough reach** from `EXAMPLE_WINDOWS` (default 2 = Red Shirt, the
  validated one). `RUN_NAME` carries the gauge id, so the four windows don't overwrite each other.
- **Works a window at a time, not a tile.** 60 cm over the 13TFJ valley bottom is ~6.3 G pixels.
  Default is a 2 × 2 km window (11.1 M px, ~6 s to segment). Tile-scale runs loop windows.
- **Shadow adjacency is the woody/herbaceous discriminator, not NDVI.** In July the wet meadow is
  *greener* than the cottonwood canopy (0.31 vs 0.24). Shadow adjacency is 0.51 vs 0.03. See §5.2
  of the plan — this was the surprise of Phase 2 and it is why the method works.
- **Shadow is an absolute cut** (50% of scene median brightness), never a percentile — a percentile
  declares a fixed share of any image to be shadow whether or not shadow is there.
- **Rules are applied to k-means cluster means, not to pixels.** Ten decisions, printed as one
  table. Do not turn this into a per-pixel threshold: the auditability is the point.
- **HAND and distance-to-channel are computed and stored but deliberately excluded from the
  clustering.** The segmentation is already clipped to the valley bottom, so valley membership
  carries no information there — using it would be circular.
- **SLIC runs unmasked, then segments are filtered by `valley_frac >= 0.5`.** Passing `mask=` to
  `slic()` takes a different, far slower code path — it hung for minutes on 11 M px where the
  unmasked call takes 6 s. Same answer, so don't "fix" this back.
- **The class is `riparian_woody`, not `cottonwood`.** 4-band NAIP does not separate cottonwood
  from willow. Renaming waits on a canopy height model.
- **Planted trees classify as woody.** Shelterbelts and yard trees around ranch buildings come out
  as gallery. `elongation` and `dist_chan_m` are on every patch so they can be screened; the screen
  itself is a group decision and is not applied by default.
- **`minimum_rotated_rectangle` warns on every rasterized polygon** in shapely 2.1.2 (`invalid
  value` / `divide by zero` in `oriented_envelope`). Elongation is computed from the principal axes
  of the patch outline instead — correlates 0.92 with the rectangle version and is warning-free.
- **Outputs are committed with cells cleared**, per §11 of the plan: this repo is public and an
  executed copy would embed a 60 cm gallery map. Figures from a verification run live in the
  gitignored `data/<run>/figures/`.

## Figures

Every notebook's setup cell defines `FIG_DIR`, `FIG_DPI = 300` and a `savefig(name)` helper;
the config cell sets `FIG_SUBDIR` (usually `= RUN_NAME`). Output lands in
`figures/<FIG_SUBDIR>/<name>.png` at 300 dpi with `bbox_inches="tight"`.

- **`figures/` is gitignored, but `figures/.gitkeep` is tracked**, so the folder exists on a
  fresh clone with no setup step. Rules are `figures/*` + `!figures/.gitkeep`.
- **Contents stay out of git deliberately** — the repo is public and an executed run embeds a
  60 cm gallery map. Plan §11 is still an open CARE decision; flipping to tracked is a one-line
  .gitignore change *after* sign-off, not before.
- **`savefig()` must be called BEFORE `plt.show()`.** Showing a figure can clear it, and you
  would silently write a blank page. All 13 existing call sites follow this; keep new ones in
  the same order.
- Skeleton notebooks `02`, `04`–`08` carry the helper but have no plots yet.

## Known Issues and Fixes

### Folium basemap shows "API KEY REQUIRED"
CARTO now requires an API key. Their servers still return HTTP 200 — they burn the watermark into
the tile — so it fails silently rather than erroring. Do not use `tiles="CartoDB positron"`. Use
Esri, which needs no key: `.../Canvas/World_Light_Gray_Base/MapServer/tile/{z}/{y}/{x}` for a light
reference map, `.../World_Imagery/...` for aerial. Both are in notebooks 00 and 01.

### USGS gauge records are wildly uneven — check before analysing
- `usgs_gauges` holds 275 NLDI sites; only the **51 8-digit** ids are surface-water gauges.
- **06439500 Eagle Butte is discontinued**: 1934–1967, then only two partial years (2007–08).
  Its 2008 "annual mean" is inflated by a real 65,200 cfs flood and wrecks any multi-year plot.
  It is **not** dropped from `00` — it has ~33 continuous years, clears `MIN_YEARS_PER_DOY`, and
  draws in brown tagged `historic (no modern record)` via `MODERN_SINCE = 2010`. The corridor
  envelope gives it its own dashed line plus **monthly 25–75th whiskers** for variability.
  **Do not call it a pre-regulation baseline** — 1934–1967 straddles Angostura's completion
  (~1949, still unverified per §17) rather than predating it. It is the only *long* record at the
  downstream end of the corridor; that is the defensible claim.
- **Use percentiles, not mean ± SD, for flow variability.** Daily discharge here is strongly
  right-skewed, so a symmetric SD bar runs negative and cannot be drawn on the log axis at all.
  Quartiles are also robust to the 2008 flood — verified: injecting a 65,200 cfs spike leaves the
  June p75 unmoved, where a mean or a p90 would not be.
- **No period covers all seven gauges** — Buffalo Gap starts (1968) the year Eagle Butte's main
  record ends (1967), and intersecting all seven leaves only the flood-dominated 2007–08 blip.
  So the corridor envelope at the end of `00` is **deliberately not period-matched**: it pools
  every main-stem daily value by day of year and describes the corridor as one unit, with the
  bands mixing between-gauge and between-year spread. Set `POOL_GAUGES` to exclude `06439500`
  for a post-regulation-only view.
- **Day-of-year 366 must be filtered** before mapping onto the non-leap `REF_YEAR`. pandas maps
  `"2001-366"` to 2002-01-01 rather than raising, so on long records (Wasta has ~28 leap years,
  well past the 10-year filter) it silently plants a point a year past the axis.
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
