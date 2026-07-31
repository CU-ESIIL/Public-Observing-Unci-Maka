#!/usr/bin/env bash
# =============================================================================
# CyVerse session setup for the Unci Maka VBET / cottonwood notebooks.
#
# Run this at the start of every CyVerse session:
#
#     bash ~/data-store/Public-Observing-Unci-Maka/scripts/setup_cyverse.sh
#
# WHAT IT DOES
#   Builds (or reuses) a small overlay virtualenv on top of an existing conda
#   env — by default HYR-SENSE — and registers it as a Jupyter kernel.
#
# WHY AN OVERLAY INSTEAD OF `mamba env create`
#   * HYR-SENSE is baked into the CyVerse image, so it survives session
#     restarts and already has the heavy geospatial stack (GDAL, geopandas,
#     rasterio, ...). Rebuilding all that from environment.yml costs 10-20
#     minutes of every session and regularly OOMs the container.
#   * `pip install` straight into /opt/conda/envs/HYR-SENSE does NOT persist
#     (the container filesystem is ephemeral) and would mutate an environment
#     shared with other HYR-SENSE users.
#   * A venv created with --system-site-packages inherits everything from
#     HYR-SENSE but writes new packages into ~/data-store, which DOES persist.
#     First run takes a couple of minutes; later sessions are seconds.
#
# IDEMPOTENT. Safe to re-run. Pass --recreate to rebuild the overlay.
# =============================================================================
set -euo pipefail

BASE_ENV="${BASE_ENV:-HYR-SENSE}"
DATA_STORE="${DATA_STORE:-$HOME/data-store}"
VENV_DIR="${VENV_DIR:-$DATA_STORE/envs/unci-maka}"
WBT_DIR="${WBT_DIR:-$DATA_STORE/bin/WBT}"
VBET_DATA_DIR="${VBET_DATA_DIR:-$DATA_STORE/unci-maka-data}"
KERNEL_NAME="unci-maka"
KERNEL_DISPLAY="Python (Unci Maka / VBET)"

RECREATE=0
[[ "${1:-}" == "--recreate" ]] && RECREATE=1

say()  { printf '\n\033[1m== %s\033[0m\n' "$*"; }
ok()   { printf '   \033[32mok\033[0m   %s\n' "$*"; }
warn() { printf '   \033[33mwarn\033[0m %s\n' "$*"; }
die()  { printf '\n\033[31mERROR\033[0m %s\n\n' "$*" >&2; exit 1; }

# -----------------------------------------------------------------------------
say "1. Locating base conda environment: $BASE_ENV"
# -----------------------------------------------------------------------------
CONDA_BASE="$(conda info --base 2>/dev/null)" || die "conda not found on PATH."
BASE_PREFIX="$CONDA_BASE/envs/$BASE_ENV"

if [[ ! -x "$BASE_PREFIX/bin/python" ]]; then
    echo "   Could not find $BASE_PREFIX/bin/python"
    echo "   Available environments:"
    conda env list | sed 's/^/     /'
    die "Set BASE_ENV to one of the above, e.g.  BASE_ENV=my-env bash $0"
fi
BASE_PY="$BASE_PREFIX/bin/python"
ok "$BASE_PREFIX"
ok "$("$BASE_PY" -V 2>&1)"

# -----------------------------------------------------------------------------
say "2. Auditing the base environment"
# -----------------------------------------------------------------------------
# Anything already present in HYR-SENSE is inherited by the overlay and never
# reinstalled. Only the misses below get pip-installed into ~/data-store.
"$BASE_PY" - <<'PY'
import importlib.util as u
core = ["numpy","pandas","geopandas","rasterio","rioxarray","xarray","shapely",
        "pyproj","scipy","matplotlib","folium","osgeo"]
extra = ["whitebox","pynhd","dataretrieval","pyarrow","py3dep"]
for label, mods in (("core (expected present)", core), ("project extras", extra)):
    print(f"   {label}:")
    for m in mods:
        print(f"     {'ok  ' if u.find_spec(m) else 'MISS'}  {m}")
PY

MISSING_CORE="$("$BASE_PY" -c "
import importlib.util as u
core=['numpy','pandas','geopandas','rasterio','rioxarray','shapely','pyproj','scipy','matplotlib','folium','osgeo']
print(' '.join(m for m in core if not u.find_spec(m)))")"
if [[ -n "$MISSING_CORE" ]]; then
    warn "Base env is missing core geospatial packages: $MISSING_CORE"
    warn "The overlay will try to pip-install them, which is slow and may conflict"
    warn "with conda's GDAL. Consider a different BASE_ENV if this looks wrong."
fi

# -----------------------------------------------------------------------------
say "3. Overlay virtualenv"
# -----------------------------------------------------------------------------
if [[ $RECREATE -eq 1 && -d "$VENV_DIR" ]]; then
    echo "   --recreate: removing $VENV_DIR"
    rm -rf "$VENV_DIR"
fi

if [[ -x "$VENV_DIR/bin/python" ]]; then
    ok "reusing $VENV_DIR"
else
    echo "   creating $VENV_DIR (inherits $BASE_ENV via --system-site-packages)"
    mkdir -p "$(dirname "$VENV_DIR")"
    "$BASE_PY" -m venv --system-site-packages "$VENV_DIR"
    ok "created"
fi
VENV_PY="$VENV_DIR/bin/python"

# Guard: a venv built against a previous container's conda env breaks when the
# image is updated. Detect the dangling base and rebuild automatically.
if ! "$VENV_PY" -c "import sys" 2>/dev/null; then
    warn "overlay is broken (base env changed?) — recreating"
    rm -rf "$VENV_DIR"
    "$BASE_PY" -m venv --system-site-packages "$VENV_DIR"
fi

# -----------------------------------------------------------------------------
say "4. Installing missing project packages into the overlay"
# -----------------------------------------------------------------------------
NEED="$("$VENV_PY" -c "
import importlib.util as u
# import name -> pip name
req = {'whitebox':'whitebox', 'pynhd':'pynhd', 'dataretrieval':'dataretrieval',
       'ipykernel':'ipykernel'}
print(' '.join(p for m, p in req.items() if not u.find_spec(m)))")"

if [[ -z "$NEED" ]]; then
    ok "nothing to install"
else
    echo "   installing: $NEED"
    # --no-warn-script-location: scripts land in the venv, which is expected.
    "$VENV_PY" -m pip install --quiet --upgrade pip
    "$VENV_PY" -m pip install --no-warn-script-location $NEED
    ok "installed"
fi

# -----------------------------------------------------------------------------
say "5. WhiteboxTools binary (persistent)"
# -----------------------------------------------------------------------------
# WhiteboxTools() downloads a ~200 MB Rust binary from its constructor. Setting
# WBT_PATH makes download_wbt() return early, so we only ever fetch it once and
# keep it in ~/data-store.
if [[ -x "$WBT_DIR/whitebox_tools" ]]; then
    ok "already present at $WBT_DIR"
else
    echo "   downloading WhiteboxTools once into $WBT_DIR (~200 MB)…"
    mkdir -p "$(dirname "$WBT_DIR")"
    WBT_DIR="$WBT_DIR" "$VENV_PY" - <<'PY'
import os, shutil
from pathlib import Path
import whitebox
wbt = whitebox.WhiteboxTools()          # triggers the one-time download
src = Path(wbt.exe_path)                # NOTE: a directory, not the exe itself
dst = Path(os.environ["WBT_DIR"])
shutil.copytree(src, dst, dirs_exist_ok=True)
for f in [dst / "whitebox_tools", *(dst / "plugins").glob("*")]:
    if f.is_file() and f.suffix != ".json":
        f.chmod(0o755)
print(f"     copied {src} -> {dst}")
PY
    ok "installed"
fi

# -----------------------------------------------------------------------------
say "6. Registering the Jupyter kernel"
# -----------------------------------------------------------------------------
# Kernel registrations do NOT persist between sessions — this must run each time.
# PROJ/GDAL data live under the BASE env (the venv has no share/proj), so the
# kernel spec must point at BASE_PREFIX, not VENV_DIR.
PROJ_SHARE="$BASE_PREFIX/share/proj"
GDAL_SHARE="$BASE_PREFIX/share/gdal"
[[ -d "$PROJ_SHARE" ]] || warn "no $PROJ_SHARE — PROJ errors are likely"
[[ -d "$GDAL_SHARE" ]] || warn "no $GDAL_SHARE"

mkdir -p "$VBET_DATA_DIR"
"$VENV_PY" -m ipykernel install --user \
    --name "$KERNEL_NAME" \
    --display-name "$KERNEL_DISPLAY" \
    --env PROJ_DATA "$PROJ_SHARE" \
    --env PROJ_LIB  "$PROJ_SHARE" \
    --env GDAL_DATA "$GDAL_SHARE" \
    --env WBT_PATH  "$WBT_DIR" \
    --env VBET_DATA_DIR "$VBET_DATA_DIR" >/dev/null
ok "kernel '$KERNEL_DISPLAY' registered"

# -----------------------------------------------------------------------------
say "7. Verifying"
# -----------------------------------------------------------------------------
PROJ_DATA="$PROJ_SHARE" PROJ_LIB="$PROJ_SHARE" GDAL_DATA="$GDAL_SHARE" \
WBT_PATH="$WBT_DIR" "$VENV_PY" - <<'PY'
import os, sys, traceback
fail = []
try:
    import geopandas, rasterio, rioxarray, scipy, folium, numpy, pandas
    from osgeo import gdal
    print(f"     geopandas {geopandas.__version__}  rasterio {rasterio.__version__}  GDAL {gdal.__version__}")
except Exception:
    traceback.print_exc(); fail.append("geospatial stack")

try:
    import pyproj
    pyproj.CRS.from_epsg(32613)     # the exact call that fails without PROJ_DATA
    print("     pyproj: EPSG:32613 resolved")
except Exception:
    traceback.print_exc(); fail.append("pyproj/PROJ_DATA")

try:
    import pynhd; print("     pynhd ok")
except Exception:
    traceback.print_exc(); fail.append("pynhd")

try:
    import whitebox
    wbt = whitebox.WhiteboxTools()
    wbt.set_whitebox_dir(os.environ["WBT_PATH"])
    print("    ", wbt.version().splitlines()[0].strip())
except Exception:
    traceback.print_exc(); fail.append("whitebox")

sys.exit(1 if fail else 0)
PY

# -----------------------------------------------------------------------------
cat <<EOF

$(printf '\033[1m== Done\033[0m')

  Base env      : $BASE_PREFIX  (from the image — persists)
  Overlay       : $VENV_DIR  (persists)
  WhiteboxTools : $WBT_DIR  (persists)
  Notebook data : $VBET_DATA_DIR  (persists)
  Kernel        : "$KERNEL_DISPLAY"  (re-register each session by re-running this)

Next:
  1. Refresh the browser tab (JupyterLab fetches the kernel list on page load).
  2. Open a notebook and pick "$KERNEL_DISPLAY" from the kernel picker.
  3. Run notebooks in order: 00 -> 01a -> 01.

VBET_DATA_DIR is baked into the kernel spec, so the notebooks write to
persistent storage automatically. For terminal use, also export it:

  export VBET_DATA_DIR=$VBET_DATA_DIR

EOF
