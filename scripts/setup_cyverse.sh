#!/usr/bin/env bash
# =============================================================================
# CyVerse session setup for the Unci Maka VBET / cottonwood notebooks.
#
# Run this at the start of every CyVerse session:
#
#     bash ~/data-store/Public-Observing-Unci-Maka/scripts/setup_cyverse.sh
#
# WHAT IT DOES
#   Builds a self-contained conda environment from environment.yml at a PREFIX
#   inside ~/data-store, then registers it as a Jupyter kernel.
#
# WHY A PREFIX ENV IN data-store
#   Conda environments do not have to live in /opt/conda/envs. `--prefix` puts
#   one anywhere, so putting it in ~/data-store makes it persist across
#   sessions. It is built ONCE (10-20 min) and reused forever after; only the
#   kernel registration has to repeat each session, which takes seconds.
#
# WHY NOT LAYER ON HYR-SENSE
#   An earlier version of this script built a venv with --system-site-packages
#   on top of HYR-SENSE. That does not work, and the failure is instructive:
#     * pip installs a NEW numpy into the venv, which shadows HYR-SENSE's numpy
#       but NOT its pandas/pyarrow, which are compiled against the old ABI:
#           AttributeError: _ARRAY_API not found
#     * pip simultaneously SKIPS upgrading aiohttp because HYR-SENSE's older
#       copy looks like it satisfies the requirement, so imports resolve to a
#       version missing newer symbols:
#           ImportError: cannot import name 'ClientConnectorDNSError'
#   Mixed-provenance site-packages breaks in both directions at once. HYR-SENSE
#   is Python 3.10 with a pinned older stack; this project needs a modern one.
#   They cannot be layered — the env must be self-consistent.
#
# IDEMPOTENT. Safe to re-run. Pass --recreate to rebuild the environment.
# =============================================================================
set -euo pipefail

DATA_STORE="${DATA_STORE:-$HOME/data-store}"
ENV_DIR="${ENV_DIR:-$DATA_STORE/envs/unci-maka}"
WBT_DIR="${WBT_DIR:-$DATA_STORE/bin/WBT}"
KERNEL_NAME="unci-maka"
KERNEL_DISPLAY="Python (Unci Maka / VBET)"

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_YML="$REPO_ROOT/environment.yml"

RECREATE=0
[[ "${1:-}" == "--recreate" ]] && RECREATE=1

say()  { printf '\n\033[1m== %s\033[0m\n' "$*"; }
ok()   { printf '   \033[32mok\033[0m   %s\n' "$*"; }
warn() { printf '   \033[33mwarn\033[0m %s\n' "$*"; }
die()  { printf '\n\033[31mERROR\033[0m %s\n\n' "$*" >&2; exit 1; }

command -v conda >/dev/null || die "conda not found on PATH."
[[ -f "$ENV_YML" ]] || die "environment.yml not found at $ENV_YML"

# Prefer mamba (much faster solver); fall back to conda.
if command -v mamba >/dev/null; then SOLVER=mamba; else SOLVER=conda; fi

# -----------------------------------------------------------------------------
say "1. Checking target: $ENV_DIR"
# -----------------------------------------------------------------------------
# A leftover venv from the old overlay approach lives at this same path and
# would be mistaken for a usable environment. Detect it by pyvenv.cfg.
if [[ -f "$ENV_DIR/pyvenv.cfg" ]]; then
    warn "found an old --system-site-packages venv here (the approach that"
    warn "caused the numpy/aiohttp import errors). Removing it."
    rm -rf "$ENV_DIR"
fi

if [[ $RECREATE -eq 1 && -d "$ENV_DIR" ]]; then
    echo "   --recreate: removing $ENV_DIR"
    rm -rf "$ENV_DIR"
fi

# -----------------------------------------------------------------------------
say "2. Conda environment"
# -----------------------------------------------------------------------------
if [[ -x "$ENV_DIR/bin/python" ]]; then
    ok "reusing $ENV_DIR"
    ok "$("$ENV_DIR/bin/python" -V 2>&1)"
else
    echo "   Building from $ENV_YML"
    echo "   This is a ONE-TIME cost (10-20 min). It persists in data-store."
    echo

    # CyVerse containers are memory-limited; parallel fetch/extract is the
    # documented cause of std::bad_alloc / segfaults during env creation.
    conda config --set fetch_threads 1   >/dev/null 2>&1 || true
    conda config --set extract_threads 1 >/dev/null 2>&1 || true

    df -h "$DATA_STORE" | tail -1 | awk '{print "   data-store free: " $4}'

    # --prefix overrides the `name:` in environment.yml (conda warns; harmless).
    "$SOLVER" env create --prefix "$ENV_DIR" --file "$ENV_YML" \
        || die "Environment creation failed.
   If it OOMed, the container needs more memory — relaunch the CyVerse app with
   a larger memory allocation, then re-run this script.
   Partial state was left at $ENV_DIR; re-run with --recreate to start clean."
    ok "created $ENV_DIR"
fi
ENV_PY="$ENV_DIR/bin/python"
[[ -x "$ENV_PY" ]] || die "No python at $ENV_PY — the env did not build."

# -----------------------------------------------------------------------------
say "3. Verifying the stack is self-consistent"
# -----------------------------------------------------------------------------
# Run this BEFORE the kernel is registered, so a broken env never reaches a
# notebook. Each import below corresponds to a failure seen in the field.
PROJ_SHARE="$ENV_DIR/share/proj"
GDAL_SHARE="$ENV_DIR/share/gdal"

PROJ_DATA="$PROJ_SHARE" PROJ_LIB="$PROJ_SHARE" GDAL_DATA="$GDAL_SHARE" \
"$ENV_PY" - <<'PY' || die "Verification failed — see the traceback above."
import sys, traceback
fail = []

def check(label, fn):
    try:
        fn(); print(f"     ok    {label}")
    except Exception:
        traceback.print_exc(); fail.append(label); print(f"     FAIL  {label}")

def _numpy_abi():
    # The exact break from the overlay approach: pandas/pyarrow compiled
    # against a different numpy than the one that ends up on sys.path.
    import numpy, pandas, pyarrow
    print(f"           numpy {numpy.__version__}  pandas {pandas.__version__} "
          f"pyarrow {pyarrow.__version__}")

def _geo():
    import geopandas, rasterio, rioxarray
    from osgeo import gdal
    print(f"           geopandas {geopandas.__version__}  "
          f"rasterio {rasterio.__version__}  GDAL {gdal.__version__}")

def _proj():
    import pyproj
    pyproj.CRS.from_epsg(32613)          # fails when PROJ_DATA is wrong

def _pynhd():
    # Pulls aiohttp/async_retriever — the second overlay failure.
    from pynhd import NLDI, nhdplus_vaa, WaterData

check("numpy / pandas / pyarrow ABI", _numpy_abi)
check("geospatial stack",             _geo)
check("pyproj EPSG:32613",            _proj)
check("pynhd + async_retriever",      _pynhd)
check("scipy",        lambda: __import__("scipy.ndimage"))
check("whitebox",     lambda: __import__("whitebox"))
check("dataretrieval", lambda: __import__("dataretrieval"))

sys.exit(1 if fail else 0)
PY
ok "all imports clean"

# -----------------------------------------------------------------------------
say "4. WhiteboxTools binary"
# -----------------------------------------------------------------------------
# WhiteboxTools() downloads a ~200 MB Rust binary from its constructor. Setting
# WBT_PATH makes download_wbt() return early. Keeping it outside the env means
# it survives an --recreate.
if [[ -x "$WBT_DIR/whitebox_tools" ]]; then
    ok "already present at $WBT_DIR"
else
    echo "   downloading once into $WBT_DIR (~200 MB)…"
    mkdir -p "$(dirname "$WBT_DIR")"
    WBT_DIR="$WBT_DIR" "$ENV_PY" - <<'PY'
import os, shutil
from pathlib import Path
import whitebox
wbt = whitebox.WhiteboxTools()          # triggers the one-time download
src = Path(wbt.exe_path)                # a DIRECTORY, not the exe itself
dst = Path(os.environ["WBT_DIR"])
shutil.copytree(src, dst, dirs_exist_ok=True)
for f in [dst / "whitebox_tools", *(dst / "plugins").glob("*")]:
    if f.is_file() and f.suffix != ".json":
        f.chmod(0o755)
print(f"     copied {src} -> {dst}")
PY
    ok "installed"
fi

WBT_PATH="$WBT_DIR" "$ENV_PY" -c "
import os, whitebox
w = whitebox.WhiteboxTools(); w.set_whitebox_dir(os.environ['WBT_PATH'])
print('    ', w.version().splitlines()[0].strip())
"

# -----------------------------------------------------------------------------
say "5. Registering the Jupyter kernel"
# -----------------------------------------------------------------------------
# Kernel registrations live in ~/.local/share/jupyter and do NOT persist —
# this is the only step that genuinely has to repeat each session.
[[ -d "$PROJ_SHARE" ]] || warn "no $PROJ_SHARE — PROJ errors are likely"

# NOTE: deliberately NOT setting VBET_DATA_DIR here.
# The notebooks resolve their data dir by walking up to the repo root, and the
# repo is cloned into ~/data-store — so <repo>/data is already persistent.
# An earlier version pointed VBET_DATA_DIR at a fresh empty directory, which
# overrode that and produced "cheyenne_corridor_aoi.gpkg not found" while the
# file sat in the repo all along. Set it manually only to relocate the rasters.
"$ENV_PY" -m ipykernel install --user \
    --name "$KERNEL_NAME" \
    --display-name "$KERNEL_DISPLAY" \
    --env PROJ_DATA "$PROJ_SHARE" \
    --env PROJ_LIB  "$PROJ_SHARE" \
    --env GDAL_DATA "$GDAL_SHARE" \
    --env WBT_PATH  "$WBT_DIR" >/dev/null
ok "kernel '$KERNEL_DISPLAY' registered"

# A kernel left over from the old overlay venv still shows in the picker and is
# still broken. Remove only kernels whose interpreter points INTO our own
# data-store envs directory and no longer exists — never touch image-provided
# kernels such as HYR-SENSE.
for spec in "$HOME/.local/share/jupyter/kernels"/*/kernel.json; do
    [[ -f "$spec" ]] || continue
    py="$("$ENV_PY" -c "
import json, sys
try:
    argv = json.load(open(sys.argv[1])).get('argv') or ['']
    print(argv[0])
except Exception:
    print('')" "$spec" 2>/dev/null)"
    case "$py" in
        "$DATA_STORE"/envs/*)
            if [[ ! -x "$py" ]]; then
                warn "removing stale kernel '$(basename "$(dirname "$spec")")' (missing $py)"
                rm -rf "$(dirname "$spec")"
            fi
            ;;
    esac
done

# -----------------------------------------------------------------------------
cat <<EOF

$(printf '\033[1m== Done\033[0m')

  Environment   : $ENV_DIR  (persists)
  WhiteboxTools : $WBT_DIR  (persists)
  Notebook data : $REPO_ROOT/data  (persists — the repo is in data-store)
  Kernel        : "$KERNEL_DISPLAY"  (re-run this script each session)

Next:
  1. Refresh the browser tab (the kernel list is fetched on page load).
  2. Open a notebook, pick "$KERNEL_DISPLAY", and RESTART the kernel if the
     notebook was already open with the old one.
  3. Run notebooks in order: 00 -> 01a -> 01.

Do NOT use the HYR-SENSE kernel for these notebooks — its Python 3.10 stack is
too old for pynhd, and mixing the two is what caused the numpy/aiohttp errors.

EOF
