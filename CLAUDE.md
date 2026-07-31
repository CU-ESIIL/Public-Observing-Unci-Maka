# Claude Memory — Public Observing Unci Maka

## Project Overview
ESIIL working group bringing together Tribal members, scientists, and NASA researchers to monitor environmental impacts (uranium mining legacy) on Hopi and Pine Ridge Reservations using earth observation data. Focused on Craven Canyon / Cheyenne River study area, South Dakota.

## Repo Structure
```
notebooks/          # Main project Jupyter notebooks (00, 01a, 01–06 + STELLA/EMIT exploratories)
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

> **Deliberate drift — do not "fix":** the root `environment.yml` has `whitebox`, the docker one
> does not. The VBET rework needs WhiteboxTools, but the Docker image is not being rebuilt right
> now. On CyVerse that gap is closed by `scripts/setup_cyverse.sh`, which builds the env from
> the root `environment.yml` into data-store. Add `whitebox` to
> `docker/jupyterlab/environment.yml` at the same time as the next image rebuild.

Note there is a **fourth** environment present on CyVerse that this repo does not define:
`hyr-sense`, baked into the ESIIL image. It is Python 3.10 with an older pinned stack and is
**not used** by these notebooks — see the warning below.

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
which is the memory wall on CyVerse. WBT is a multithreaded Rust engine that streams to/from
disk. Chain: `BreachDepressionsLeastCost` → `D8Pointer` → `D8FlowAccumulation` →
`ExtractStreams` → `ElevationAboveStream` (HAND) → `Slope`. Breaching replaces the
`fill_pits → fill_depressions → resolve_flats` chain and is the single largest speedup.

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

### `VBET_DATA_DIR`
All three notebooks resolve paths via `Path(os.environ.get("VBET_DATA_DIR", "../data"))`.
On CyVerse export it to a `~/data-store/` path **before launching the kernel**, in every notebook,
or the DEM mosaic is lost at session end:
```bash
export VBET_DATA_DIR=/home/jovyan/data-store/unci-maka-data
```

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

## Known Issues and Fixes
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
