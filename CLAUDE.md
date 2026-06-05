# Claude Memory — Public Observing Unci Maka

## Project Overview
ESIIL working group bringing together Tribal members, scientists, and NASA researchers to monitor environmental impacts (uranium mining legacy) on Hopi and Pine Ridge Reservations using earth observation data. Focused on Craven Canyon / Cheyenne River study area, South Dakota.

## Repo Structure
```
notebooks/          # Main project Jupyter notebooks (00–02 + STELLA/EMIT exploratories)
data/               # Study area boundaries (CravenCanyon_StudyArea.gpkg, GCP points)
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

## Key Environment Decisions Made
- **Slimmed root `environment.yml`** to ~23 packages (was 38). Removed transitive deps (shapely, pyproj, bokeh, fsspec, aiohttp, requests) and EMIT-only packages (panel, spectral, scikit-image, netCDF4, h5netcdf, s3fs, zarr, cartopy). These can be pip-installed separately when needed.
- **`pynhd`, `py3dep`, `pysheds`** are all present and correct — core to the VBET/NHD workflow.
- **`localtileserver`** is pip-only (not on conda-forge).
- **EMIT tools** (spectral, scikit-image, netCDF4, panel, s3fs) can be added with `pip install spectral scikit-image netCDF4 panel s3fs zarr` when running EMIT notebooks.

## CyVerse Deployment — Critical Facts
- **Deployment**: Docker image built from `docker/jupyterlab/Dockerfile` → pushed to DockerHub → used by CyVerse "JupyterLab ESIIL" app.
- **GitHub Actions**: `build-and-push-jupyterlab-image.yml` (manual trigger) builds/pushes the image. `gh-pages.yml` (push to main) deploys mkdocs site.
- **Ephemeral containers**: `/opt/conda/envs/` does NOT persist between sessions. The conda env must be recreated every session.
- **Persistent storage**: `/home/jovyan/data-store/` persists. Clone the repo there.
- **Memory constraint**: CyVerse containers have limited RAM. `mamba env create` with large envs segfaults. Fix: `conda config --set fetch_threads 1 && conda config --set extract_threads 1` before install.

## CyVerse Setup Sequence (Every Session)
```bash
cd ~/data-store/Public-Observing-Unci-Maka && git pull
conda config --set fetch_threads 1 && conda config --set extract_threads 1
mamba env create -f environment.yml
conda activate unci-maka-py
python -m ipykernel install --user \
  --name unci-maka-py \
  --display-name "Python (unci-maka-py)" \
  --env PROJ_DATA /opt/conda/envs/unci-maka-py/share/proj \
  --env PROJ_LIB /opt/conda/envs/unci-maka-py/share/proj \
  --env GDAL_DATA /opt/conda/envs/unci-maka-py/share/gdal
```

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

### `EnvironmentNameNotFound: unci-maka-py`
Conda env doesn't persist between CyVerse sessions. Re-run `mamba env create -f environment.yml`.

## Docs Site
- URL: https://cu-esiil.github.io/Public-Observing-Unci-Maka
- Built with mkdocs-material, deployed via GitHub Actions on push to main
- Key guide: `docs/resources/cyverse_basics.md`

## GitHub Workflows
- `fetch-template.yml` — syncs from `CU-ESIIL/Working_group_OASIS` template (manual trigger)
- `build-and-push-jupyterlab-image.yml` — builds + pushes Docker image (manual trigger, needs DOCKERHUB_USERNAME / DOCKERHUB_PASSWORD secrets)
- `gh-pages.yml` — deploys mkdocs site (auto on push to main, needs GH_TOKEN secret)
