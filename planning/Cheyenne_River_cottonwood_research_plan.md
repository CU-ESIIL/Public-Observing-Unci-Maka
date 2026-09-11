# Research Plan — Mapping Cottonwood Gallery Forest along the Cheyenne River

**Project:** ESIIL Observing Unci Maka (Pine Ridge / Cheyenne River)
**Status:** Draft v0.2 · Last updated 2026-09-11
**Scope:** Cheyenne River corridor, Angostura Reservoir → Oahe Reservoir, South Dakota.

> This is a **living document**. It is updated at phase gates (§16), not rewritten. Decisions are
> **appended** to the decision log (§0.2) with a date and a reason — superseded entries are struck
> through, never deleted, so the reasoning stays visible. Anything marked `VERIFY` is an assumption
> that has not yet been checked against data (§17).

> A companion plan, `planning/AZ_invasive_riparian_research_plan.md`, covers a separate geography
> (invasive riparian species in Arizona). The two share methods and document structure. They are
> **not** merged and neither supersedes the other.

---

## 0.1 Phase status

| Phase | Description | Status |
|---|---|---|
| 0 | Foundations — env, bug fixes, tiling, manifests | Not started |
| 1a | Smoke test — VBET on a 20 × 20 km box at Red Shirt | **Passed 2026-09-11** |
| 1b | Pilot valley bottom (VBET on 13TFJ) | Not started |
| 2 | Pilot extent — NAIP auto-labels | Not started |
| 3 | Phenology windows + Landsat cube | Not started |
| 4 | Change — extent and condition | Not started |
| 5 | Drivers — flow, water quality, drought | Not started |
| 6 | Scale to corridor | Not started |
| 7 | Products | Not started |

## 0.2 Decision log

| Date | Decision | Reason |
|---|---|---|
| 2026-09-11 | Imagery backbone is Landsat C2 L2 (1984–2025) + NAIP (60 cm) | Landsat gives the only multi-decadal record; NAIP is the only resolution that resolves a gallery |
| 2026-09-11 | Training labels derived automatically from NAIP; no manual digitizing for training | Portability to other rivers; manual labels do not transfer |
| 2026-09-11 | **Tiling unit is the MGRS 100-km square** (UTM 13N) | HLS/Sentinel-2 granules are already named and distributed on this grid, so phenology inputs arrive pre-tiled; consistent with the group's other phenology work |
| 2026-09-11 | **Pilot tile is 13TFJ** | Contains three main-stem gauges including Red Shirt (7 NAIP epochs) and the Angostura-to-Scenic reach where regulation and mining legacy both apply |
| 2026-09-11 | **VBET runs on 13TFJ before any imagery work** | Validates the WhiteboxTools chain cheaply; produces the real riparian mask rather than a placeholder |
| 2026-09-11 | **Code stays in notebooks. No `src/` package.** | The notebooks are a teaching and exploration product for the working group, not just a pipeline. Readability outranks DRY here |
| 2026-09-11 | **GEE deferred, not excluded** | Revisit only if the measured pilot cost (§13) shows local/CyVerse scaling is infeasible |
| 2026-09-11 | **Run manifests tracked in git; rasters never** | Manifests are small, text-diffable, and are what makes a result re-derivable |
| 2026-09-11 | Data sovereignty for derived products is an **open decision** requiring working-group sign-off | Not ours to settle unilaterally (§11) |
| 2026-09-11 | **MGRS tiles imagery only. Hydrology is not tiled by MGRS.** | A rectangular tile severs contributing area; flow accumulation and HAND are corrupted at every seam (§2.4) |
| 2026-09-11 | **VBET uses the NHD flowline network as its stream definition**, replacing `D8FlowAccumulation` → `ExtractStreams` | Removes the only globally-dependent step, so tile seams stop mattering; also removes the most expensive step and uses curated hydrography with real drainage areas |
| 2026-09-11 | **A 20 × 20 km smoke test at Red Shirt runs before any full tile** | None of the VBET outputs have ever been produced; find breakages in a 30-second run, not a 30-minute one |
| 2026-09-11 | **WhiteboxTools stays, pinned to core MIT tools only; no plugins, no extensions** | The three tools used are MIT-licensed core, verified locally (§14.1). Dropping flow accumulation cut the dependency to three replaceable tools |
| 2026-09-11 | **Analysis mask is `large` + `medium` drainage classes only** | The 162 small-class reaches are ephemeral badlands draws contributing >half the area and no gallery habitat. Cuts the Red Shirt valley bottom from 97.2 to 59.0 km² (24.3% → 14.7% of the box) |
| 2026-09-11 | **Riparian NDVI screening deferred** | Excluding the small class achieves most of the same reduction with no imagery cost. Revisit only if tributary relic stands become a question worth the compute |
| 2026-09-11 | **VBET also writes a binary uint8 mask raster**, burned from the same smoothed polygon as the GeoPackage | The mask is what clips imagery in Phases 2–4; deriving both from one geometry stops the raster and vector disagreeing |
| 2026-09-11 | ~~The corridor spans seven MGRS squares, all in zone 13~~ **Superseded: nine squares across UTM zones 13 and 14** | Verified with the `mgrs` library. The corridor crosses the zone boundary at −102°; the original figure came from arithmetic that assumed a single zone (§2.5) |

---

## 1. Research questions

- **Q1 — Extent.** Where is cottonwood gallery forest along the Cheyenne River, and can it be mapped
  reproducibly without hand-built training data?
- **Q2 — Change.** Has gallery extent and condition changed since 1984, and where along the corridor
  is change concentrated?
- **Q3 — Drivers.** Is that change associated with altered flow regime (regulation, drought,
  withdrawal) and/or with water-quality signals connected to the uranium mining legacy?

Q1 is the methods contribution and the reusable product. Q2 is the headline result. Q3 carries the
most uncertainty and is scoped as an **association analysis, not a causal claim**.

---

## 2. Study area and the unit of work

The corridor AOI from `00_Study_Area-Cottonwoods.ipynb` is **6,225 km²** across a 228 × 187 km
envelope, with 8,964 NHD reaches. Processing that wall-to-wall at 60 cm is not sensible; the work is
tiled, and each tile is masked to the riparian corridor before any imagery is read.

### 2.1 Tiling — MGRS 100-km squares

The analysis unit is the **MGRS 100-km square in UTM zone 13N (EPSG:32613)**. Reasons:

1. HLS and Sentinel-2 granules are distributed under these identifiers (`T13TFJ`), so phenology
   inputs need no re-tiling.
2. Squares are exactly 100 km on a side in the projected CRS — uniform compute per tile, trivially
   indexable, and no custom grid artifact to maintain.
3. It matches the grid convention already used in the group's other phenology work.

**This grid is for imagery only.** Hydrology is tiled differently and for a different reason — see
§2.4.

**Important caveat.** A Sentinel-2/HLS granule is **109.8 km** with deliberate inter-tile overlap.
It is *named* by the 100-km square but is not congruent with it. The analysis unit is the **true
100-km square**; the HLS granule is a superset that gets clipped to it. Treating them as identical
double-counts along seams.

### 2.2 Squares intersecting the corridor

Computed from the corridor AOI (2026-09-11):

| Square | UTM zone | AOI km² | Flowline km | Main-stem gauges |
|---|---|---|---|---|
| **13TFJ** | 13 | 2,149 | 6,228 | 06401500 Angostura, 06402600 Buffalo Gap, 06403700 Red Shirt, 06408650 Scenic |
| 13TGK | 13 | 936 | 2,658 | — |
| 14TKQ | 14 | 832 | 2,921 | 06438500 Plainview |
| 14TLQ | 14 | 685 | 1,206 | 06439500 Eagle Butte |
| 13TFH | 13 | 630 | 2,468 | — |
| 13TGJ | 13 | 509 | 1,175 | 06423500 Wasta |
| 13TEJ | 13 | 248 | 565 | — |
| 13TEH | 13 | 225 | 792 | — |
| 13TFK | 13 | <1 | 500 | — |

Nine squares cover the corridor. Areas are from a 1 km point sample and flowline lengths from a
250 m sample, both assigned to squares by the `mgrs` library (sampled AOI total 6,214 km² against a
true 6,225 km², so the figures are good to well under 1%). This **supersedes an earlier
seven-square, single-zone table** that was derived arithmetically.

### 2.3 Pilot

**13TFJ.** It holds three main-stem gauges, the reach directly below Angostura Dam, and Red Shirt —
the only site where NAIP epoch coverage is confirmed (2012, 2014 at 1 m; 2016, 2018, 2020, 2021,
2022 at 60 cm). The whole workflow is built and validated here before any other square is touched.

Scaling proceeds square by square. 13TGK is the natural second tile: it is the downstream,
lower-gradient end of the corridor, so running the **frozen** 13TFJ workflow there is a genuine
transferability test rather than a repeat.

### 2.4 Hydrology is not tiled by MGRS

An MGRS square is, hydrologically, an arbitrary rectangle. The Cheyenne enters 13TFJ from the west
carrying thousands of km² of Black Hills drainage originating **outside** the square. Running
`D8FlowAccumulation` within the square gives the main stem near-zero accumulation at the inlet, so
`ExtractStreams` fails to recognize it as a stream for some distance downstream and HAND is then
computed against a network missing the main channel. A buffer does not fix this — nothing short of
the true contributing area does. This is the failure mode `CLAUDE.md` already warns about: *chunk by
HUC, never by arbitrary tiles.*

**Resolution: remove the dependency instead of enlarging the tile.**

Of the WhiteboxTools chain, only `D8FlowAccumulation` → `ExtractStreams` is globally dependent.
`Slope` is local, and `BreachDepressionsLeastCost` has a bounded search radius. `D8Pointer`
existed only to feed flow accumulation — `ElevationAboveStream` takes `(dem, streams, output)`
and derives its own flow paths — so dropping accumulation drops the pointer too. The revised
chain is three tool calls instead of six:

```
BreachDepressionsLeastCost → ElevationAboveStream (HAND, against rasterized NHD) → Slope
```

Edge effect to expect: cells whose flow path leaves the processing extent without reaching a
stream get nodata HAND. Near the channel — the only place the valley bottom is delineated — this
does not arise.

Notebook `01a` already joins `pynhd.nhdplus_vaa()` on COMID, so the flowlines carry real
`totdasqkm` drainage areas — better information than a threshold on derived accumulation, and the
same values the VBET drainage-area classing needs. With flow accumulation gone, **every remaining
step is local, tile seams stop mattering, and the most expensive step disappears.**

`VERIFY` — **the one new risk.** NHD flowline geometry can be laterally offset from the DEM thalweg,
and the Cheyenne is a braided, shifting prairie river where that offset may be large. HAND measured
against a misplaced stream line produces artifacts. Before trusting the output, check flowline
position against the DEM minimum within a channel corridor and snap where the offset is material.
This check is part of the Phase 1 gate.

### 2.5 The corridor crosses a UTM zone boundary

**Longitude −102° is the UTM 13N / 14N boundary, and the corridor crosses it.** Roughly the eastern
30% of the corridor's width — including the Plainview and Eagle Butte gauges — is in zone 14. Three
consequences:

- **MGRS squares near the boundary are partial.** `13TGK` and `14TKQ` are adjacent across it; the
  clean "uniform 100 km per tile" property in §2.1 holds in the interior but not at the seam.
- **HLS/Sentinel-2 granules for the eastern corridor are `14T…`, not `13T…`.** Any code that assumes
  a `13T` prefix will silently find nothing out there.
- **`EPSG:32613` is not the right CRS for the whole corridor.** It is correct for the pilot and the
  western squares; extending it east of −102° accumulates distortion. Zone-14 squares should be
  processed in `EPSG:32614`, with a decision needed at Phase 6 on the CRS for corridor-wide
  products. **This is deferred, not resolved** — it does not affect Phases 1–5, which are entirely
  within 13TFJ.

---

## 3. Core design — two scales, two products

A **label-transfer** architecture is what makes "no hand-built training data" workable.

**Scale A — NAIP (60 cm–1 m, 2012–2022).** Unsupervised object-based segmentation inside the
valley-bottom mask produces dense gallery labels automatically. Human effort for training is zero;
the cluster→class step is rule-based and physically interpretable, which is what makes it portable
to another river.

**Scale B — Landsat Collection 2 L2 (30 m, 1984–2025, Planetary Computer `landsat-c2-l2`).** NAIP
labels are aggregated to the 30 m grid with a pixel-purity filter and used to train the landscape
model.

This yields **two distinct products, and keeping them distinct is the central methodological
recommendation:**

1. **Extent change at benchmark epochs** — hard classification at a handful of dates
   (e.g. ~1985, 1995, 2005, 2015, 2022). Answers "are galleries growing or shrinking in area."
2. **Condition trends within fixed gallery units** — NAIP-derived patches become stable analysis
   units, and full annual Landsat index series (NDVI/NDMI, phenology metrics) are extracted per
   patch and trended.

**Why split them.** A hard classifier trained on 2012–2022 NAIP labels and pushed back to 1984
carries real domain-shift risk: TM vs. ETM+ vs. OLI band-pass differences, atmospheric-correction
consistency, and the stronger assumption that cottonwood's spectral-phenological signature is
*stationary over 40 years*. Continuous index trends within fixed units are far more robust to sensor
drift, and they measure decline as **vigor**, not only area. Reporting both — and stating plainly
that the hard-classification product is coarser in time — is more defensible than forcing a single
annual land-cover time series.

---

## 4. The phenology bet

Cottonwood galleries are narrow relative to a 30 m pixel, so separability must come from the **time
axis**, not the spatial one. In a western South Dakota mixed-grass prairie matrix:

- Cool-season grasses green up **before** cottonwood leaf-out and **cure brown by mid-to-late
  summer**.
- Cottonwood stays green into September and yellows late.

So the **late-season (roughly September–early October) composite should be the discriminating
window** — cottonwood green against a cured, brown matrix — and a spring-vs-late-season difference
feature should carry most of the signal. This mirrors the phenology-targeted compositing in Cook et
al. (2024) for aspen, re-parameterized for this system.

`VERIFY` — **the windows must be derived from observed greenness curves for this corridor, not
assumed.** That derivation is an explicit Phase 3 task and is where HLS earns its place: 30 m with
~2–3 day revisit pins down phenological dates far better than Landsat's 16.

---

## 5. Auto-labeling from NAIP

Inside the valley-bottom mask, on a single NAIP epoch:

1. **Segment** — SLIC or Felzenszwalb superpixels (`scikit-image`) over the 4 NAIP bands + NDVI.
   Deliberately **not** SAM/`samgeo` at v1: it pulls in `torch`, is heavy on CyVerse, and superpixels
   are sufficient for canopy-vs-matrix. SAM is a documented upgrade path, not a v1 dependency.
2. **Cluster** — k-means or GMM on segment-mean spectral and texture features. **Seed fixed and
   recorded** (§9).
3. **Assign classes by rule** — using automatic, physically meaningful criteria: high NDVI, canopy
   texture and shadow structure (which separates tree canopy from smooth meadow at 60 cm), patch
   geometry (galleries are elongate and channel-adjacent), distance-to-channel, and **HAND gradient
   within the valley bottom**.

> **Note on a circularity the earlier draft contained.** Do *not* use "is within the valley bottom"
> as a class-assignment rule. The segmentation is already clipped to the valley bottom, so that term
> carries no information where it is applied. Distance-to-channel and HAND *gradient* do carry
> signal; flat membership does not.

### 5.1 The known weak point, stated up front

Four-band leaf-on NAIP separates **woody riparian from grass and bare ground** well. It separates
**cottonwood from willow / shrub thicket** poorly — this is the dominant accuracy risk. Two
mitigations, in order:

- `VERIFY` **Check 3DEP lidar coverage for the corridor** (USGS / OpenTopography). A canopy height
  model separates mature cottonwood (~15–25 m) from willow (~2–5 m) decisively and would resolve the
  single largest class-confusion risk. This is an availability check, not an assumption.
- If lidar is unavailable, the v1 class is honestly named **"riparian woody / gallery forest"**, with
  cottonwood dominance inferred from patch structure and stature proxies, and the limitation carried
  in every product and figure.

---

## 6. Validation

**Unsupervised training does not exempt the project from validation.** Any accuracy statement needs
an independent reference sample:

- A **stratified random sample of ~300–500 points**, photo-interpreted once on the highest-resolution
  NAIP epoch, kept **strictly separate** from the auto-labels.
- This is the one irreducible piece of manual work, and it is **validation, not training**.
- It is also a natural **working-group activity** — interpretation is exactly the task where local
  knowledge of the river outperforms a remote analyst. Worth designing as a group session rather
  than a solo chore.
- Field data (working-group campaigns, STELLA-Q2 spectra in `tools/STELLA/`) supplements it where
  available.
- **Spatial/blocked cross-validation by reach.** Riparian samples are strongly autocorrelated and
  random k-fold will inflate accuracy. Report per-class precision/recall/F1, not only overall
  accuracy.

---

## 7. Change analysis

- **Extent change** between benchmark epochs, reported with **area-adjusted accuracy and confidence
  intervals** (Olofsson et al. 2014). Raw pixel-count differences between two imperfect maps are not
  a defensible area-change number.
- **Per-patch condition trends** — Mann-Kendall significance and Theil-Sen slope on annual
  late-season NDVI/NDMI, plus phenology metrics (start/end of season, season length, integrated
  greenness).
- **Longitudinal framing** — results summarized by river segment moving downstream (below Angostura
  → Red Shirt → Scenic → Wasta → Eagle Butte) so spatial gradients in change are visible.

---

## 8. Drivers

### 8.1 Flow regime (quantitative)

**Gauge records are very uneven, and this constrains the design.** Checked against NWIS on
2026-09-11 (complete year = ≥ 300 days of record):

| Site | Name | Record | Complete years |
|---|---|---|---|
| 06423500 | near Wasta | 1914–2024 | **93** |
| 06438500 | near Plainview | 1950–2024 | **54** |
| 06401500 | below Angostura Dam | 1945–2024 | 32 |
| 06402600 | near Buffalo Gap | 1968–2024 | 28 |
| 06403700 | at Red Shirt | 1998–2024 | 26 |
| 06408650 | near Scenic | 2007–2024 | 17 |
| 06439500 | near Eagle Butte | 1934–1967, **then 2007–2008 only** | 32 (all pre-1968) |

Consequences:

- **Eagle Butte is discontinued.** It has a 39-year gap (1968–2006) and its only modern data are two
  partial years, 2007 (224 days) and 2008 (190 days). It cannot anchor anything in the satellite
  era. Notebook 00 uses it as the downstream anchor for the corridor geometry, which is fine — but
  not for flow analysis.
- **Wasta and Plainview are the backbone** of any flow-regime work: both span the whole Landsat
  record continuously. Anchor §8.1 on those.
- **Red Shirt starts in 1998**, so the pilot site has no discharge for the first 14 years of the
  Landsat record. Pair it with Wasta for anything needing the full period.
- **06401500 below Angostura is a seasonal gauge.** It has reported ~181 days a year since 1978,
  every year. A "complete calendar year" filter would discard a continuous 1945–2024 record — the
  most important one for the regulation question. Notebook 00 therefore requires a **minimum number
  of contributing years per day-of-year**, not complete years.
- **The reach below Angostura is chronically dewatered.** Median daily flow is **1.5 cfs pre-1978
  and 2.0 cfs in 1978–2024**, against **62–70 cfs at Buffalo Gap**, the next gauge downstream. The
  river regains flow through accretion between the two. A median flow near zero means no spring
  peak and no recession limb, which under the recruitment-box framework means **no recruitment
  window at all** in that reach. `VERIFY` this against the recruitment-box thresholds rather than
  asserting it. Note the record starts 1945 and the dam dates to ~1949, so this is **not** a
  before/after observation — it is the operating regime, consistent with §15.
- **Annual statistics must be computed only from complete years**, and record completeness must be
  shown alongside any hydrograph. An annual mean from a partial year that happens to contain a flood
  is not comparable to one from a full year — see the 2008 Eagle Butte case in §17.

NWIS daily discharge is accessible via `dataretrieval` in notebook 00. Derive **recruitment-relevant** metrics rather than generic
statistics, anchored in the **cottonwood recruitment box** (Mahoney & Rood 1998):

- annual peak magnitude and **timing relative to seed release** (roughly late May–June);
- **post-peak stage recession rate** — successful establishment needs a gradual decline;
- 7-day low flow; low/zero-flow duration; IHA-style regime metrics.

This framework is well established for Great Plains cottonwood and yields testable, mechanistic
hypotheses instead of a fishing expedition.

### 8.2 Water quality / mining legacy

**Inventory first, analyze second.** Query NWIS-qw and the Water Quality Portal for uranium, gross
alpha, radium, specific conductance, and suspended sediment across the corridor; report station
coverage, analytes, and periods of record **before** committing to any statistical linkage.

Coverage is likely sparse and irregular. If it is inadequate, the water-quality component becomes
**contextual and descriptive** — that is decided by the data inventory, not promised in advance.
The spatial logic is favorable if data exist: historical mining sources sit in the upstream
Angostura-to-Red Shirt segment (inside pilot tile 13TFJ), so a downstream gradient design is
available.

### 8.3 Inference honesty

With one regulated river and seven gauges, this is an association analysis. Two things strengthen it:

- a **space-for-time contrast** between the regulated main stem and less-regulated tributary reaches
  already present in the AOI;
- **climate/drought covariates** (gridMET or PRISM-derived SPEI/PDSI) so drought is controlled for
  rather than confounded with regulation.

---

## 9. Reproducibility

Three mechanisms, all lightweight enough to live inside a notebook.

### 9.1 Run manifests — tracked in git

Every notebook that produces an output also writes a small sidecar manifest
(`<output>.manifest.json`) recording:

- **STAC item IDs** for every NAIP and Landsat scene consumed — the Planetary Computer catalog is
  not immutable, so "re-run notebook 03" is not reproducible without a pinned item list;
- all parameters from the config cell;
- **random seeds** (k-means, sample draws);
- tile ID, CRS, resolution, and output bounds;
- environment hash (`conda list --explicit` digest) and a UTC timestamp;
- the notebook filename and git commit.

Manifests are **small, text, and always committed**, even when the raster they describe is not.
This is the single highest-value reproducibility change and it costs a few lines per notebook.

### 9.2 Config cell convention

Every notebook opens with one clearly marked configuration cell holding **every** parameter — tile
ID, dates, thresholds, seeds, paths. No parameter is buried in a later cell. Pointing the workflow at
another square, or another river, is then a single-cell edit, which is what "reusable" means when
there is no package (§14).

### 9.3 Determinism check

A phase gate is not passed until a re-run of the notebook reproduces the previous manifest's key
outputs. Verifying that `resolve_data_dir()` works is necessary but not sufficient — the gate is on
*results*, not paths.

---

## 10. Data storage and access

| Artifact | Lives in | In git? |
|---|---|---|
| Notebooks, plan, docs, `environment.yml` | repo | Yes |
| Run manifests (`*.manifest.json`) | repo, next to outputs | **Yes** |
| Corridor AOI, valley bottom, tile index, gallery patches | `data/` | No — gitignored by `*data/` |
| DEM, HAND, NAIP chips, Landsat cube | `data/` (local) / `~/data-store/` (CyVerse) | No |
| Conda env (`unci-maka`) | `~/data-store/envs/` on CyVerse | No |
| WhiteboxTools binary | `~/data-store/bin/WBT` | No |
| Large shared products | Box / CyVerse data-store | No |

**Consequence to accept knowingly:** because `data/` is entirely gitignored, the authoritative
`cheyenne_corridor_aoi.gpkg` is **not** version-controlled. Re-deriving it depends on a live NLDI
service returning the same result. The run manifest records how it was built, which is the mitigation
— but it is a mitigation, not an equivalent. Revisit if NLDI results ever drift.

**Rasters never go in git.** GitHub hard-rejects files over 100 MB and these routinely run to GB.

---

## 11. Data sovereignty and CARE — open decision

All *inputs* are public federal data (NAIP, Landsat, HLS, 3DEP, NHD, NWIS). **Derived
cottonwood-gallery maps for a culturally important species on and adjacent to Tribal land are a
different question**, and it is not one this plan settles.

**Interim posture, in force until the working group and Tribal partners decide otherwise:**

- Derived outputs stay in the gitignored `data/` tree.
- Nothing location-specific is published to the docs site, a public artifact, or any external
  service.
- Precise gallery locations are not included in public figures; corridor-scale summaries are the
  default presentation.

**Requires working-group and Tribal partner sign-off:** whether derived maps are published at all;
at what spatial precision; where they are stored; who may access them; how attribution and
benefit-sharing work. CARE principles are named as a working-group goal — this section is where they
become operational rather than aspirational, and it should be filled in by the group, not by the
analysts.

---

## 12. Disclaimer — AI assistance in this project

Parts of this repository are developed with an AI coding assistant (Claude Code). The group should
know exactly what that means.

**What happens:**

- The assistant reads files in this repository and runs commands **on the local machine or CyVerse
  instance** when asked to.
- Content it reads or is shown — including file contents — is **transmitted to Anthropic's API** in
  order to generate responses. It does not stay on the machine.
- It writes notes to a local memory directory to carry context between sessions. Those notes live on
  the user's machine.

**Operating rules adopted for this project:**

- The assistant **does not search outside this repository, publish, push, deploy, or send anything to
  an external service without being asked for it explicitly each time.**
- It **does not make analytical or study-design decisions unilaterally** — parameter choices, class
  schemes, and method selections are brought to the group. The decision log (§0.2) is the record.
- **No data that the working group has not agreed can leave the project is shared with the
  assistant.** This applies to community-contributed data, field observations, and anything
  identifying culturally sensitive locations. Public federal imagery is not in this category;
  community data is.
- Derived products covered by §11 are **not** published through any AI-assisted publishing path
  (artifacts, hosted pages, external services) before sign-off.

`VERIFY` — the group should check Anthropic's current data-usage and retention terms directly rather
than relying on this summary, and revisit this section if those terms change.

---

## 13. Scaling, and the Google Earth Engine decision

**Decision: GEE is deferred, not excluded.** All v1 work runs locally and on CyVerse with the
existing conda stack. No GEE dependency enters `environment.yml` at this stage.

**Revisit trigger.** Phase 2 and Phase 3 gates must record the **measured cost of one tile**:
wall-clock time, peak memory, and bytes read for (a) NAIP segmentation over the 13TFJ valley-bottom
mask and (b) the annual Landsat composite stack. Multiply by seven squares. If corridor-scale
processing is infeasible on CyVerse within those numbers, GEE is reconsidered **with evidence**
rather than on intuition.

**What reconsidering it would have to weigh.** GEE's advantage is that Landsat compositing happens
server-side at continental scale. Its cost here is direct: **pushing training labels or derived
gallery maps to GEE assets means that data leaves for Google infrastructure**, which is precisely the
question §11 reserves for the working group. A GEE path therefore cannot be adopted as a pure
engineering decision. Note also that the masking strategy (§2) may make the question moot — the
valley bottom is a small fraction of the 6,225 km² corridor, and `VERIFY` quantifying that fraction
after Phase 1 is the cheapest way to find out.

---

## 14. Code organization — notebooks, deliberately

**These notebooks are a teaching and exploration product for the working group, not only a
pipeline.** Members should be able to open one and follow the method by reading it top to bottom.

Therefore:

- **No `src/` package.** Method logic stays visible in cells.
- **Simple, straightforward, digestible code.** Comments explain *why*, briefly. Not verbose, not
  absent.
- **Some duplication is accepted** as a cost of readability — the path/PROJ preamble repeating across
  notebooks is a known, tolerated cost, not a bug to refactor away.
- **Reusability comes from convention, not abstraction**: one config cell at the top (§9.2),
  consistent naming, tile ID as a parameter. Repointing at another square or another river is a
  config edit.
- Notebooks are expected to be **filled in and annotated as a group** — leave room for that, and
  don't over-write the markdown in advance.

---

### 14.1 Toolchain licensing — WhiteboxTools

The group's preference is for purely open-source tooling, so the WhiteboxTools dependency was
checked rather than assumed. Verified locally on 2026-09-11 against the installed v2.4.0:

- **The core is MIT licensed** (`LICENSE.txt` ships in the distribution — John Lindsay, 2017–2021).
- **All three tools this project uses are in the MIT core binary**, not in the plugin directory:
  `BreachDepressionsLeastCost`, `ElevationAboveStream`, `Slope`. They ran with no license, no key,
  no nag, and no limit.
- The commercial surface is separate: 25 bundled plugins plus an `install_wb_extension` hook for the
  **Whitebox Toolset Extension**, and Whitebox Geospatial Inc. sells its own Python product line.
  **None of that is in our path.** `VERIFY` — the vendor's current commercial terms were not checked
  against their website; do that directly before relying on this in a grant or a publication.

**The dependency is shallow, which is the real protection.** Dropping `D8FlowAccumulation` (§2.4)
cut the chain from six tools to three, and each remaining one has a mature open-source equivalent:

| Step | Open alternative |
|---|---|
| `Slope` | `gdaldem slope` — GDAL, already a dependency |
| `BreachDepressionsLeastCost` | RichDEM (MIT), GRASS `r.hydrodem` (GPL), or `pysheds` (already in `environment.yml`) |
| `ElevationAboveStream` | GRASS `r.stream.distance` computes elevation above stream directly (GPL) |

**Rule adopted:** use core tools only. If a future step needs a plugin or extension — note that the
lidar tools (`normalize_lidar`, `individual_tree_detection`) relevant to the §5.1 canopy-height idea
**are** plugins — treat that as a trigger to reach for `lidR` (R, GPL) or PDAL (BSD) instead, not as
a reason to buy a licence. Pin the WhiteboxTools version in the manifest so a licence-model change
upstream cannot retroactively affect a completed run.

---

## 15. Risks and caveats

- **Cottonwood/willow confusion in 4-band NAIP** — the dominant accuracy risk (§5.1).
- **Gallery width vs. 30 m pixels** — mixed pixels are pervasive. The purity filter helps training,
  but the map remains biased toward wider galleries; narrow single-tree-row galleries will be missed.
- **Cross-sensor drift** TM↔ETM+↔OLI over 40 years — apply harmonization coefficients (Roy et al.
  2016) or test their effect; the continuous-index product is the hedge.
- **Signature stationarity** — pushing modern labels back to 1984 assumes cottonwood's
  spectral-phenological signature has not shifted. It is an assumption, and it should be stated.
- **Landsat starts in 1984 — after Angostura Dam closure (`VERIFY` 1949) and after the peak
  Edgemont / Craven Canyon uranium era (`VERIFY` ~1950s–1970s).** The satellite record documents the
  **post-impact trajectory, not the impact itself.** This must be stated plainly rather than implied
  away. Historic aerial photography is the only route to a pre-dam baseline; out of scope for now,
  noted as a future workstream.
- **Single-year phenology can be anomalous** in a drought-prone system — use multi-year composites.
- **Spatial autocorrelation will inflate naive accuracy** — blocked CV by reach is non-negotiable.
- **NAIP epoch coverage is confirmed only at Red Shirt.** `VERIFY` coverage across the rest of 13TFJ
  and the corridor, and whether pre-2012 NAIP is reachable outside Planetary Computer.

---

## 16. Phased roadmap with gates

Each phase ends with a **gate** — a question answered before the next phase starts. Gates are where
this document gets updated (§0.1, §0.2).

**Phase 0 — Foundations.** Environment additions; fix the `01a` `DATA_DIR` bug; resolve the HLS
duplication; build the MGRS tile index; establish the config-cell and manifest conventions.
*Gate: pilot notebooks run clean on the `unci-maka` kernel, and a manifest is written and committed.*

**Phase 1a — Smoke test.** Run the revised chain (§2.4) on a **20 × 20 km box at Red Shirt**
(0.44 M cells at 30 m — seconds, not minutes). None of the VBET outputs have ever been produced, so
this is where the WBT binary, the VAA join, breaching, HAND, slope, and polygonization get shaken
out. Keep it in the repo as the standing check that a CyVerse environment works before anyone
commits to a real tile.
*Gate: does the chain complete and produce a valley-bottom polygon that tracks the channel?*
**Passed 2026-09-11.** 221 reaches, drainage area 0.8–27,728 km² so the main stem classes as
`large` correctly; all three hydrology steps ran in 0.1 s on 0.44 M cells; HAND is exactly 0 m at
every stream cell; HAND nodata is 2.3%, confined to the box edge as expected; median flowline
offset from the local terrain minimum is **2.5 m** (90th pct 7.3 m), so NHD is well registered here
and no snapping step is needed. Valley bottom 97.2 km², 24.3% of the box — see the open question in
§17 on whether the `small` class belongs in a cottonwood mask.

**Phase 1b — Pilot valley bottom.** Run the same chain over **13TFJ** (13.4 M cells with a 5 km
buffer).
*Gate: does the valley bottom look geomorphically right against NAIP imagery — following the
floodplain, not climbing terraces? Are the NHD flowlines adequately registered to the DEM thalweg
(§2.4)? And what fraction of the tile does the valley bottom cover — the number that sets the real
scaling problem (§13)?*

**Phase 2 — Pilot extent (NAIP auto-labels).** Segmentation → clustering → rule-based class
assignment on 2022 NAIP within the 13TFJ mask. Interpret the validation sample.
*Gate: is accuracy sufficient to transfer these as labels — and is cottonwood/willow separable, or
is the honest class "riparian woody"? Record measured cost per tile (§13).*

**Phase 3 — Phenology + Landsat cube.** Derive seasonal windows from observed greenness curves (HLS
for timing precision); build the annual Landsat composite stack over the pilot valley bottom.
*Gate: is there a real late-season separability signal at 30 m? Record measured cost per tile.*

**Phase 4 — Change.** Label transfer, benchmark-epoch classification, per-patch trend analysis,
area-adjusted accuracy.
*Gate: is the change signal larger than its uncertainty?*

**Phase 5 — Drivers.** Flow metrics, water-quality inventory, drought covariates, association
analysis.
*Gate: does the water-quality record support formal analysis, or is it contextual?*

**Phase 6 — Scale to corridor.** Run the frozen workflow on 13TGK as a transferability test, then
the remaining five squares.
*Gate: does the method hold in the downstream, lower-gradient setting without re-tuning?*

**Phase 7 — Products.** Community-facing maps and summaries; documented reusable workflow —
subject to §11 sign-off.

---

## 17. Open items to verify

- [x] ~~MGRS square designators in §2.2~~ — **done 2026-09-11**; corrected to nine squares across two
      UTM zones (§2.2, §2.5).
- [x] ~~NHD flowline registration against the DEM thalweg~~ — **done 2026-09-11** at Red Shirt;
      median offset 2.5 m, no snapping needed. Re-check when the run moves beyond 13TFJ.
- [x] ~~Eagle Butte hydrograph outlier~~ — **explained 2026-09-11.** Not bad data: the gauge was
      dormant 1968–2006 and briefly reactivated for two partial years. June 2008 carried a genuine
      65,200 cfs flood, so the 2008 "annual" mean (2,535 cfs, from 190 days) plots against 2007
      (278 cfs, from 224 days) as a near-vertical line. **Fix is a completeness rule, not an
      outlier filter** (§8.1).
- [x] ~~Does the `small` class belong in the mask?~~ — **resolved 2026-09-11: no.** Excluded;
      `ANALYSIS_CLASSES = ["large", "medium"]`. Reaches are still classed and written out, so
      re-including them is a one-word change, not a re-run.
- [ ] **Tributary relic cottonwood.** Excluding the small class assumes no gallery forest in the
      headwater draws. Some may hold relic stands. Deferred, not dismissed — the cheapest test is
      an NDVI screen on NAIP once Phase 2 exists, per **NHD reach** (not per patch: connected
      components merge the main stem and every draw into one patch holding 95.6% of the area).
- [ ] 3DEP lidar coverage over the Cheyenne corridor — materially changes the cottonwood/willow story.
- [ ] NAIP epoch coverage across all of 13TFJ, not only gauge 06403700; and pre-2012 availability.
- [ ] Angostura Dam completion date (1949?) and the Edgemont / Craven Canyon mill operating period.
- [ ] Water-quality station coverage — determines whether Q3's mining component is analytical or
      contextual.
- [ ] Valley-bottom area as a fraction of tile area (after Phase 1) — sets the real scaling problem.
- [ ] Phenological windows from observed greenness curves (Phase 3) — must not be assumed.

---

## 18. Repo work implied by this plan

Proposed, **not yet executed** — confirm before any of it happens.

**Fix**
- `01a_DEM_Prefetch.ipynb` — `DATA_DIR = _resolve_data_dir()` is overwritten two lines later by
  `Path(os.environ.get("VBET_DATA_DIR", "../../data"))`. The walk-up is dead code; the fallback
  resolves correctly *only* from `notebooks/PineRidge/`, by coincidence of directory depth. Make it
  match notebooks `00` and `01`.
- `NAIP_Tile_Analysis.ipynb` — `BUFFER_M = 5000` is a 10 km box while the comment says 2 km; the chip
  is also clipped by the tile edge, so the gauge is not centered.
- `01_HLS_reflectance.ipynb` / `02_HLS_reflectance.ipynb` — functionally duplicate (same 19 cells,
  only the heading differs) and still pointed at the old Craven Canyon AOI. Retire both to
  `archive/`; HLS returns in Phase 3 where it has a real job.

**Change**
- `01_VBET_ValleyBottom.ipynb` — replace `D8FlowAccumulation` + `ExtractStreams` with a rasterized
  NHD flowline network feeding `ElevationAboveStream` (§2.4). `FLOW_ACCUM_THRESHOLD` and
  `STREAM_INIT_KM2` become unnecessary for stream definition; drainage-area classing reads
  `totdasqkm` directly. The HUC-8 chunking path in section 8 also becomes unnecessary for
  correctness, though it may still help on memory-constrained instances.

**Add**
- `environment.yml` — `scikit-learn`, `scikit-image`, `odc-stac`, `mgrs`. `docker/jupyterlab/
  environment.yml` stays intentionally drifted on `whitebox` per `CLAUDE.md`; batch all
  image-affecting changes for the next rebuild.
- A tile-index notebook cell or small GeoPackage layer for the seven MGRS squares.

**Renumbering (proposed — costs nothing while 03–06 are empty stubs; confirm before doing it)**

| New | Content |
|---|---|
| `00_Study_Area` | exists |
| `01a_DEM_Prefetch`, `01b_VBET_ValleyBottom` | exist (`01` → `01b`) |
| `02_NAIP_Access` | from `NAIP_Tile_Analysis` |
| `03_NAIP_Segmentation_Labels` | auto-label factory |
| `04_Landsat_Phenology_Cube` | seasonal composites + windows |
| `05_Classification_and_Extent_Change` | label transfer, benchmark epochs |
| `06_Gallery_Condition_Trends` | per-patch time series |
| `07_Flow_and_WaterQuality_Drivers` | NWIS / WQP |
| `08_Synthesis_and_Products` | community-facing outputs |

---

## 19. References

1. Cook, M.; Chapman, T.; Hart, S.J.; Paudel, A.; Balch, J.K. (2024). *Mapping Quaking Aspen Using
   Seasonal Sentinel-1 and Sentinel-2 Composite Imagery across the Southern Rockies, USA.* Remote
   Sensing, 16(9), 1619.
2. Woodward, B.D. et al. (2018). *CO-RIP: A Riparian Vegetation and Corridor Extent Dataset for
   Colorado River Basin Streams and Rivers.* ISPRS Int. J. Geo-Inf., 7(10), 397.
3. Mahoney, J.M.; Rood, S.B. (1998). *Streamflow requirements for cottonwood seedling recruitment —
   an integrative model.* Wetlands, 18, 634–645.
4. Olofsson, P. et al. (2014). *Good practices for estimating area and assessing accuracy of land
   change.* Remote Sensing of Environment, 148, 42–57.
5. Roy, D.P. et al. (2016). *Characterization of Landsat-7 to Landsat-8 reflective wavelength and
   normalized difference vegetation index continuity.* Remote Sensing of Environment, 185, 57–70.
6. VBET — Riverscapes Valley Bottom Extraction Tool. https://tools.riverscapes.net/vbet/ ·
   https://github.com/jtgilbert/VBET-2

`VERIFY` — references should be checked against originals before any formal use.
