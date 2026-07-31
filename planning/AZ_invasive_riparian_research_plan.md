# Research Plan — Mapping Invasive Russian Olive and Tamarisk in Southwest Dry Riparian Systems (AZ)

**Status:** Draft v0.1 (2026-06-27) · Author: M. Cook · Project: ESIIL Public Observing Unci Maka (geographic extension)

> Working plan written as a **Claude Code implementation handoff**. Parameters left as `TBD` are intentional — they should be derived from data/field reconnaissance, not assumed. Citations are listed with source URLs and should be verified against the original PDFs before any formal proposal submission.

---

## 1. Motivation and Scope

This project extends the working group's existing riparian-cottonwood mapping pipeline (notebooks `00–06`, an HLS-reflectance + VBET valley-bottom + image-classification workflow) and the methods developed in Cook et al. (2024, *Remote Sensing*) for quaking aspen, into a new geography and a new target: invasive woody phreatophytes in southwest Arizona dry riparian corridors.

**Primary objective (this phase).** Develop reproducible, open-source coding workflows to map the **extent** of two invasive species — saltcedar/tamarisk (*Tamarix* spp.) and Russian olive (*Elaeagnus angustifolia*) — using a classifier trained on high-resolution LiDAR-derived labels and applied to multi-seasonal Sentinel-2 (and Landsat/HLS) imagery.

**Class scheme (decided).** Coarse, management-relevant: **invasive woody** (tamarisk + Russian olive) vs. **native riparian woody** (Fremont/Rio Grande cottonwood, Goodding/coyote willow) vs. **background** (bare/herbaceous/agriculture/upland). Per-species discrimination is a stretch goal evaluated as a separate one-vs-rest experiment (§7.3), not a v1 requirement.

**Severity (deferred to Phase 2).** Extent first. Once the extent classifier is validated, fractional cover / structural severity is a follow-on using the same LiDAR as the response variable (§10).

**The central scientific challenge** is spectral and structural confusion between the invasives and co-occurring natives. In Rio Grande and tributary systems, Russian olive frequently occupies the understory of cottonwood/Goodding willow stands and can approach native cottonwood in canopy cover, while tamarisk forms dense monotypic thickets but overlaps spectrally with willow in summer. This is the same separability problem the aspen work addressed via **phenology-targeted seasonal compositing**, and that is the core methodological bet here.

---

## 2. Relationship to Prior Work (positioning)

This is not a greenfield problem — the plan should be explicit about what it borrows and what is novel.

- **Cook et al. (2024)** — directly transferable: phenology-driven seasonal S1+S2 compositing in GEE; spectral indices + SAR textural features targeting canopy structure, moisture, and chlorophyll; Random Forest classification; evaluation in a managed target geography. We reuse this architecture and re-parameterize the seasonal windows for southwest riparian phenology.
- **NASA Applied Sciences DEVELOP — Paria River (UT/AZ)** mapped Russian olive and tamarisk with Sentinel-2 and Tasseled-Cap seasonal phenology + Random Forest. This is the closest existing analog **in the same region** and the most important benchmark/baseline. The novelty of our work is the **LiDAR-derived high-resolution training data** (most prior efforts rely on sparse field points or photo-interpretation) and explicit native-vs-invasive separation.
- **Tamarix genotype mapping with Sentinel-2** and **Russian olive time-series (Tasseled Cap leaf-flush vs. senescence)** literature establish that multi-season Sentinel-2 + tasseled-cap differencing carries the phenological signal we need.
- **Existing repo pipeline (notebooks 00–06)** already implements valley-bottom delineation (VBET/`pysheds`/`py3dep`/`pynhd`), HLS reflectance access, training-data assembly, and a classification + change workflow for cottonwood. **Reuse this scaffolding** rather than rebuilding; the new work is mostly (a) LiDAR label generation and (b) re-specifying the feature stack and class scheme.

---

## 3. Study Area and Data Inventory

**Study area.** Southwest AZ dry riparian corridor(s) with available high-resolution LiDAR coverage (exact reach `TBD` — define from the LiDAR footprint intersected with NHD flowlines and a VBET valley bottom, consistent with notebook `01_VBET_ValleyBottom`).

| Layer | Source / access | Role | Notes |
|---|---|---|---|
| High-res LiDAR (point cloud or CHM) | Group-provided; cross-check USGS 3DEP / OpenTopography for gaps | **Training-label generation** + Phase-2 severity | Need acquisition date, pulse density, ground classification status |
| Sentinel-2 L2A (MSI) | GEE `COPERNICUS/S2_SR_HARMONIZED` and/or Copernicus DataSpace | Primary multi-seasonal features | 10–20 m; phenology backbone |
| Sentinel-1 GRD (C-band SAR) | GEE `COPERNICUS/S1_GRD` | Structure/moisture + texture | Optional v1; high value for thicket structure |
| HLS (L30/S30) | NASA `earthaccess` (LP DAAC) | Cross-sensor harmonized reflectance | Repo already accesses HLS (`01_/02_HLS_reflectance`) |
| NHD flowlines / catchments | `pynhd` | Riparian masking | Already in pipeline |
| 3DEP DEM | `py3dep` | VBET, terrain features | Already in pipeline |
| Field occurrence points | Group / partners / USGS | Independent validation | Critical — keep strictly separate from LiDAR training |

A published Colorado-River-tributary **tamarisk/Russian olive occurrence/absence dataset (2017)** exists and should be evaluated as supplemental independent validation.

---

## 4. Conceptual Approach

The workflow is a two-stage label-transfer design:

1. **High-resolution stage (LiDAR + any coincident high-res optical):** generate dense, spatially explicit class labels at sub-meter to few-meter resolution over the LiDAR footprint. This is the "training-data factory."
2. **Landscape stage (Sentinel/HLS):** aggregate those labels to the satellite grid, train a classifier on multi-seasonal spectral/structural features, and predict across the full riparian corridor beyond the LiDAR footprint.

The phenological premise (to be validated against the imagery, not assumed): tamarisk and Russian olive are separable from cottonwood/willow primarily in the **shoulder seasons** — delayed spring leaf-out and extended/late autumn senescence relative to native *Populus/Salix*, plus Russian olive's distinctive silvery-canopy reflectance in mid-summer. Seasonal composites and seasonal-difference (tasseled-cap) features are designed to capture exactly these windows. Phenological windows must be set from observed greenup/senescence curves for the specific reach and year(s), e.g., from Sentinel-2 NDVI/EVI time series and (where useful) HLS — **do not port the Southern Rockies aspen windows directly.**

---

## 5. LiDAR → Training Data Workflow (the novel core)

This is where the project adds the most value and carries the most methodological risk; it deserves the most rigor.

**5.1 LiDAR processing (R or Python).**
- R: `lidR` is the most mature open-source ALS toolkit (normalization, CHM via `rasterize_canopy`/pit-free algorithms, individual-tree segmentation, structural metrics). Recommended for the point-cloud work.
- Python alternative: `PDAL` (pipelines), `laspy`, `rasterio` if staying single-language.
- Derive: normalized heights, **CHM**, canopy cover, and structural-complexity metrics that distinguish dense invasive thickets from open native gallery forest — e.g., canopy height, vegetation/foliage height diversity, vertical complexity index, rugosity, return-density-based cover. The LiDAR-shrub literature reports these structural metrics outperform NDVI for invasive-shrub detection — a key argument for this design.

**5.2 Label assignment.** LiDAR structure alone will not name species. Options, in order of defensibility:
- (a) **Coincident high-resolution imagery** (NAIP, UAV, or any group-flown optical) co-interpreted with LiDAR structure to delineate training polygons by class. Strongest.
- (b) **Field-validated polygons / GPS stands** rasterized and attributed.
- (c) Structure-informed photo-interpretation where (a)/(b) are unavailable.
- **Guardrail:** species identity must come from imagery/field truth; LiDAR provides structure and crown delineation, not the label. Avoid circularity (don't define "invasive" purely by a structural threshold and then "validate" structurally).

**5.3 Aggregation to satellite grid.** Burn high-res labels to the Sentinel/HLS grid, retaining only **pure pixels** (e.g., ≥ `TBD`% single-class cover, threshold set from a mixed-pixel sensitivity analysis) to limit label noise. Record per-pixel class purity as a sample weight / filtering covariate.

---

## 6. Feature Engineering

Build seasonal composites keyed to the reach-specific phenology (§4), mirroring Cook et al. (2024) but re-parameterized:

- **Sentinel-2 seasonal composites** (e.g., spring leaf-out, peak summer, autumn senescence, dormant — windows `TBD` from time series): per-season median surface reflectance.
- **Spectral indices**: NDVI, EVI, NDWI/NDMI (moisture — relevant to phreatophyte water use), red-edge indices (chlorophyll), and **Tasseled-Cap brightness/greenness/wetness** plus **seasonal-difference TCT** (the leaf-flush-minus-senescence signal that the Russian olive literature found most discriminating).
- **Sentinel-1 (optional v1, recommended)**: VV/VH seasonal composites and GLCM texture for thicket structure.
- **Terrain / hydro context**: height-above-nearest-drainage, distance-to-channel, valley-bottom membership — invasives' position relative to the active channel differs from gallery cottonwood and is a cheap, informative prior.

Keep the feature stack modular and documented (one config file mapping feature name → source → seasonal window) so the same stack can be regenerated for new reaches.

---

## 7. Classification Modeling

**7.1 Baseline.** Random Forest (mirrors Cook 2024 and the Paria DEVELOP work) — robust, interpretable feature importance, handles correlated features. Implement in GEE (`ee.Classifier.smileRandomForest`) for scalable inference and/or `scikit-learn` for local experimentation; keep training data exportable so both paths use identical labels.

**7.2 Cross-validation.** **Spatial** CV (blocked by stream reach / spatial folds) — riparian samples are strongly autocorrelated and random k-fold will inflate accuracy. Report per-class precision/recall/F1, not just overall accuracy.

**7.3 Species discrimination experiment (stretch).** After the invasive-vs-native classifier validates, run a one-vs-rest experiment (tamarisk vs. rest; Russian olive vs. rest) to test whether phenological features separate the two invasives. Treat as a hypothesis test, not a deliverable; report honestly if separation is weak.

**7.4 Gradient boosting comparison (optional).** XGBoost/LightGBM as a secondary learner only if RF underperforms — avoid premature complexity.

---

## 8. Validation and Accuracy Assessment

- **Independent** reference data (field points / occurrence-absence dataset / withheld interpreted polygons) — never the LiDAR-derived training pixels.
- Confusion matrix with the invasive-vs-native confusion as the headline metric; quantify specifically the **cottonwood/willow ↔ invasive** error rates (the management-critical errors).
- Area-adjusted accuracy and confidence intervals (Olofsson et al. 2014 good-practice estimator) if producing area estimates for management.
- Spatial error visualization along the corridor to expose systematic failure zones (e.g., mixed understory Russian olive under cottonwood).

---

## 9. Open-Source Toolchain (mapped to existing repo)

| Task | Tool | Existing repo asset |
|---|---|---|
| Valley-bottom / riparian mask | `pysheds`, `py3dep`, `pynhd` (VBET) | `01_VBET_ValleyBottom.ipynb` |
| HLS / NASA data access | `earthaccess` | `01_/02_HLS_reflectance.ipynb`, `tools/emit/` patterns |
| Sentinel composites + RF inference | GEE Python API (`earthengine-api`, `geemap`) | new |
| LiDAR processing | `lidR` (R) or `PDAL`/`laspy` (Python) | new |
| Raster/vector wrangling | `rioxarray`, `geopandas`, `rasterio` | env in `environment.yml` |
| ML | `scikit-learn` (+ GEE smileRandomForest) | new |
| Tiling for large rasters | `localtileserver` | noted in `environment.yml` |

Language split (decided/recommended): **Python** for satellite + ML + orchestration; **R/`lidR`** for the point-cloud stage if the team prefers its ALS ecosystem — bridge via exported CHM/metric GeoTIFFs so there's no live R↔Python coupling.

---

## 10. Phase 2 — Severity (deferred, scoped here for continuity)

Once extent is validated, model **fractional invasive cover** (continuous regression) and/or **structural severity** (LiDAR height/density/vertical-complexity fields) as the response, predicted from the same Sentinel feature stack. The LiDAR footprint provides continuous training targets, so this reuses the entire Phase-1 infrastructure with a regression head (RF regression / gradient boosting). Defer parameter choices until Phase 1 error structure is understood.

---

## 11. Implementation Roadmap (Claude Code handoff)

Recommended split: **this planning doc and literature scaffolding** are well-suited to the desktop Cowork environment; **the actual implementation** (GEE auth, `earthaccess` credentialed pulls, LiDAR pipelines, iterative model runs against repo notebooks) is better done in **Claude Code** inside your dev environment, where it can run the conda env, hit GEE/earthaccess, and iterate on the existing notebooks.

Suggested sequencing:

1. **Data reconnaissance** — confirm LiDAR metadata (date, density, ground class), coincident optical, field reference availability. Define study reach. *Gate: do we have what label generation requires?*
2. **Riparian mask** — adapt `01_VBET_ValleyBottom` to the AZ reach.
3. **Phenology characterization** — pull S2 NDVI/EVI time series; set seasonal windows from data.
4. **LiDAR label factory** (§5) — the critical path; build and document.
5. **Feature stack** (§6) — modular, config-driven seasonal composites.
6. **Baseline RF + spatial CV** (§7–8) — invasive vs. native vs. background.
7. **Validation + error mapping** (§8).
8. **Stretch: species discrimination** (§7.3); then **Phase 2 severity**.

Track decisions and parameter choices in this `planning/` directory (or a project memory file) for posterity, per project documentation practice.

---

## 12. Key Risks and Honest Caveats

- **Label species-identity is the weakest link.** If we lack coincident high-res optical or field truth over the LiDAR footprint, the whole training set rests on photo-interpretation — state this limitation explicitly and budget effort for it.
- **Understory Russian olive is partly invisible to passive optical** when overtopped by cottonwood. Sentinel will under-detect it; LiDAR sees it but only within the footprint. Be candid that the landscape map will be biased toward overstory/open-canopy invasives. This is a real, publishable limitation, not a bug to hide.
- **Phenology transfer is not guaranteed.** Southwest riparian greenup/senescence differs from the Southern Rockies; windows must be re-derived. Single-year phenology may be anomalous (drought) — consider ≥2 years if data allow.
- **Spatial autocorrelation will inflate naive accuracy.** Spatial CV is non-negotiable.
- **Tamarisk beetle defoliation** (*Diorhabda*) alters tamarisk phenology/canopy across the Southwest and can confound both spectral and structural signals depending on acquisition timing — check beetle presence/timing for the study reach.

---

## 13. References (verify against originals before formal use)

1. Cook, M.; Chapman, T.; Hart, S.J.; Paudel, A.; Balch, J.K. (2024). *Mapping Quaking Aspen Using Seasonal Sentinel-1 and Sentinel-2 Composite Imagery across the Southern Rockies, USA.* Remote Sensing, 16(9), 1619. https://www.mdpi.com/2072-4292/16/9/1619
2. NASA Applied Sciences (DEVELOP). *Mapping Russian Olive and Tamarisk to Inform Invasive Species Management Along the Paria River, Utah & Arizona.* https://appliedsciences.nasa.gov/what-we-do/projects/mapping-russian-olive-and-tamarisk-inform-invasive-species-management-along
3. *A rapid and accurate method of mapping invasive Tamarix genotypes using Sentinel-2 images.* PMC. https://pmc.ncbi.nlm.nih.gov/articles/PMC10117385/
4. *Russian olive distribution and invasion dynamics along the Powder River, Montana and Wyoming, USA.* Biological Invasions (2024). https://link.springer.com/article/10.1007/s10530-024-03394-3
5. Evangelista, P.H.; Stohlgren, T.J.; Morisette, J.T.; Kumar, S. (2009). *Mapping Invasive Tamarisk (Tamarix): A Comparison of Single-Scene and Time-Series Analyses of Remotely Sensed Data.* Remote Sensing, 1(3), 519–533. (multi-temporal Landsat ETM+ + Maxent, Arkansas River CO — early precedent for our multi-season approach). https://www.mdpi.com/2072-4292/1/3/519
6. *Detecting patches of invasive shrubs using high-density airborne LiDAR data and spectral imagery.* ScienceDirect. https://www.sciencedirect.com/science/article/abs/pii/S1618866725000986
7. *The Use of an Airborne Laser Scanner for Rapid Identification of Invasive Tree Species Acer negundo in Riparian Forests.* Remote Sensing, 15(1), 212 (2023). https://www.mdpi.com/2072-4292/15/1/212
8. *Fusion of Dense Airborne LiDAR and Multispectral Sentinel-2 and Pleiades Satellite Imagery for Mapping Riparian Forest Species Biodiversity at Tree Level.* PMC. https://www.ncbi.nlm.nih.gov/pmc/articles/PMC10975437/
9. *Remote Sensing of Tamarisk Biomass, Insect Herbivory, and Defoliation: Novel Methods in the Grand Canyon Region, Arizona.* ScienceDirect. https://www.sciencedirect.com/science/article/abs/pii/S0099111216301045
10. *Tamarisk and Russian Olive Occurrence and Absence Dataset Collected in Select Tributaries of the Colorado River for 2017.* Data, 3(4), 42. https://www.mdpi.com/2306-5729/3/4/42
11. USDA FEIS species summary: *Elaeagnus angustifolia.* https://www.fs.usda.gov/database/feis/plants/tree/elaang/all.html
12. Olofsson, P. et al. (2014). *Good practices for estimating area and assessing accuracy of land change.* Remote Sensing of Environment, 148, 42–57. (accuracy/area estimator — verify)
