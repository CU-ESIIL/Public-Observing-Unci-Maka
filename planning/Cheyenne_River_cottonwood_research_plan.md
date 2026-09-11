# Research Plan — Mapping Cottonwood Gallery Forest along the Cheyenne River

**Project:** ESIIL Observing Unci Maka (Pine Ridge / Cheyenne River)
**Status:** Draft v0.4 · Last updated 2026-09-11
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
| 0 | Foundations — env, bug fixes, tiling, manifests | **Done 2026-09-11** |
| 1a | Smoke test — VBET on a 20 × 20 km box at Red Shirt | **Passed 2026-09-11** |
| 1b | Pilot valley bottom (VBET on 13TFJ) | **Run 2026-09-11** — 13.44 M cells, hydrology 1.5 s, HAND 0.0 m on stream, valley bottom 814 km² (8.14%), 212 patches. Gate needs the geomorphic eyeball against NAIP |
| 2 | Pilot extent — NAIP auto-labels | **In progress** — notebook `03` built and run at Red Shirt; gate needs the validation sample interpreted |
| 3 | Phenology windows + Landsat cube | Skeleton (`04`) |
| 4 | Change — extent and condition | Skeletons (`05`, `06`) |
| 5 | Drivers — flow, water quality, drought | Skeleton (`07`) |
| 6 | Scale to corridor | Not started |
| 7 | Products | Skeleton (`08`), gated on §11 |

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
| 2026-09-11 | **AOI stays buffer-defined for now; a wholesale switch to HUC12 units is rejected** | Measured (§2.6): main-stem HUC12s hold only 62.7% of the validated valley bottom, and every HUC12 rule that holds 100% is 1.7–3× too big. A catchment unit cannot approximate a lateral corridor |
| 2026-09-11 | **Any AOI must be validated as a superset of the valley bottom** — the current one is not | The 10 km buffer clips ~8% of the `01s` valley bottom in the tributary draws. This was assumed, never checked (§2.6) |
| 2026-09-11 | **Replacing the 30 km tributary filter with a HUC8 exclusion is proposed, pending group review** | Dropping the Belle Fourche by its HUC8s (`10120201/2/3`) is a hydrologic statement; a 30 km radius is a guess that happens to work (§2.6) |
| 2026-09-11 | **Phase 2 is built on a NAIP *window*, not a whole tile** | 60 cm over the 13TFJ valley bottom is ~6.3 G pixels. The notebook runs a 2 × 2 km window and loops; nothing needs the tile in memory at once |
| 2026-09-11 | **Phase 2 runs against the `01s` smoke-test valley bottom until Phase 1b lands** | The method does not depend on which VBET run supplies the mask. `VBET_RUN` is a one-line config change, so Phase 2 was not blocked on Phase 1b |
| 2026-09-11 | **Shadow adjacency is the primary woody/herbaceous discriminator** — needs group review | NDVI cannot separate cottonwood from wet meadow in July; both are green. A tree casts a shadow and grass does not, so "is there shadow within 5 m" is the closest thing to a canopy-height measurement available without lidar. It is what makes the woody cluster separate cleanly (§5.2) |
| 2026-09-11 | **Shadow is an absolute brightness cut (50% of scene median), not a percentile** | A percentile declares a fixed share of *any* image to be shadow whether or not shadow is present. Measured 0.8% of pixels at Red Shirt 2022, which matches the visible tree shadows |
| 2026-09-11 | **Rules are applied to k-means cluster means, never to pixels** | Ten auditable decisions printed in one table, instead of a threshold applied ten million times. This is what makes the class assignment arguable and portable |
| 2026-09-11 | **Class is named `riparian_woody`, not `cottonwood`** | Confirms the §5.1 position with data: 4-band NAIP does not separate cottonwood from willow. Renaming waits on a canopy height model |
| 2026-09-11 | **HAND and distance-to-channel describe patches but are excluded from the clustering** | Avoids the §5 circularity — the segmentation is already clipped to the valley bottom, so valley membership carries no information where it is applied |
| 2026-09-11 | **Validation sample is generated by the labelling notebook and kept in a separate GeoPackage layer** | Stratified by mapped class with a recorded seed, never used in training. Generating it next to the labels is what makes it actually get interpreted (§6) |
| 2026-09-11 | **Lead with the published NAIP-CHM 2023 tile; defer local inference** | Canopy height of mature gallery cottonwood does not change materially in one year, so the 2023 layer is a valid *static height attribute* for the 2022 labels. One 51 MB download with no new dependencies answers the §5.1 separability question; only if height separates the classes is PyTorch inference worth taking on. Explicitly **not** licensed by this: treating the 2022/2023 pair as a change signal, or assuming pixel-perfect co-registration |
| 2026-09-11 | **DEM stays at 30 m for now; 10 m is supported and 1 m is rejected for VBET** | Measured from the 13TFJ run: 10 m is 9× cells (~14 s hydrology, 2.7 GB) and fine; 1 m is 900× (268 GB of intermediates, 48 GB per array in the numpy valley-bottom step) and a different product line `tiles_for_bbox()` cannot address |
| 2026-09-11 | **Resolution-coupled parameters are derived from `DEM_RES_M`, not typed** | `DEM_PRODUCT` and `BREACH_DIST_CELLS` both change meaning with the grid, and both fail *silently* — a fixed 100-cell breach is 3 km at 30 m and 1 km at 10 m, and product "1" at `DEM_RES_M = 10` just upsamples 30 m data |
| 2026-09-11 | **`slope_deg` is left un-derived and must be re-tuned empirically per resolution** | Slope is systematically steeper on a finer DEM, so 30 m thresholds silently shrink the valley bottom at 10 m for grid reasons. `01s` §9 measures the shift rather than guessing a correction factor |
| 2026-09-11 | **NAIP-CHM (NTSG, 0.6 m CONUS) adopted as the candidate answer to §5.1**, download-first | 0.6 m matches the `03` grid exactly; RMSE 2.28 m against a 15–30 m vs 2–6 m cottonwood/willow separation; free HTTP, CC-BY. Local inference is MIT-licensed and possible but pulls in PyTorch — the dependency SAM was rejected for |
| 2026-09-11 | **§18 renumbering adopted and executed** — notebooks are now `00`–`08`, `01s` moved to `checks/` | The stubs were 617 bytes and `03` was new, so renaming was still free. It gets expensive the moment the stubs are filled, and filling them was the next step |
| 2026-09-11 | **`01a_DEM_Prefetch` folded into `01`; archived** | `01s` already did DEM fetch, mosaic, VAA join and WBT setup inline in 27 cells, and both notebooks had skip-if-exists guards, so the split bought no caching. `01a` had never been run. Also kills the awkward `01a`/`01b` lettering |
| 2026-09-11 | **WhiteboxTools binary persistence lives in `scripts/setup_cyverse.sh`, not in a notebook** | The script already downloaded it, persisted it, and baked `WBT_PATH` into the kernel spec — `01a`'s copy cells were redundant. Notebooks only *use* what is there |
| 2026-09-11 | **Walkthrough reaches are gauge-anchored**: one 2 × 2 km window per 8-digit gauge in 13TFJ (`06401500` Angostura, `06402600` Buffalo Gap, `06403700` Red Shirt, `06408650` Scenic) | Every window then has a flow record to read beside it in Phase 5, and Angostura-vs-Buffalo Gap straddles the dam effect (~2 cfs vs ~65 cfs median). Red Shirt is already validated |
| 2026-09-11 | **MGRS square bounds derived by arithmetic, not a lookup table or the `mgrs` package** | The grid is deterministic: column letters repeat every 3 zones, rows every 2 zones and every 2,000,000 m of northing. ~20 readable lines, no new dependency, and it yields the CRS too — which matters because the corridor crosses into zone 14 |
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

### 2.6 The corridor AOI is buffer-defined — open decision

`00_Study_Area-Cottonwoods.ipynb` defines the AOI from three arbitrary numbers: a 0.5° bounding-box
pad, a **30 km** tributary filter (`TRIB_BUFFER_DEG = 0.27`, present to exclude the Belle Fourche),
and a **10 km** main-stem buffer. None is derived from anything. Replacing them with HUC units was
tested on 2026-09-11, using the `01s` valley bottom as the containment test — an AOI is only valid
if it is a **superset of the valley bottom**.

| AOI rule | HUC12s | km² | holds valley bottom |
|---|---|---|---|
| HUC12s touching the main stem | 43 | 3,966 | **62.7%** |
| HUC12s touching any corridor flowline | 214 | 19,038 | 100% |
| HUC12s intersecting the current AOI | 122 | 10,788 | 100% |
| **current buffer AOI** | — | **6,225** | **91.7%** |
| full Cheyenne basin at Eagle Butte | — | 62,690 | 100% |

**Finding: there is no HUC12 selection rule that lands on the corridor.** A HUC12 is a *catchment*
— it runs from the channel to the drainage divide. A riparian corridor is a *lateral* strip a short
distance either side of the channel. The two geometries are orthogonal, so approximating one with
the other either clips the corridor (main-stem HUC12s miss the tributary valley bottoms, which
extend into neighbouring HUC12s) or swallows entire uplands.

**Two real problems it did surface:**

1. **The current AOI already clips the valley bottom by ~8%.** This is a latent bug, not a
   hypothetical: the `01s` valley bottom extends past the 10 km buffer in the tributary draws. Any
   AOI — buffer or otherwise — must be *validated* as a superset, and none has been.
2. **HUC topology is the right tool for the tributary filter, not for the extent.** The 30 km
   distance guess that excludes the Belle Fourche can be replaced by dropping its HUC8s
   (`10120201`, `10120202`, `10120203`), which is a hydrologic statement rather than an arbitrary
   radius. This is the part of the idea worth keeping.

**Proposed split, for group decision (§12 — not settled here):** use **HUC8 topology for
*selection*** (which reaches and gauges belong to the Cheyenne, replacing the 30 km filter), and a
**valley-bottom-validated buffer for the *extent*** (which pixels get fetched). Note that the AOI's
job is only ever to be a fetch boundary — once VBET runs, the **valley bottom is the real analysis
extent**, so the AOI needs to be a safe superset, not an elegant object.

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

### 5.2 What actually separates woody from herbaceous — shadow, not greenness

Implemented in `03_Cottonwood_Training_Data.ipynb` and confirmed at Red Shirt on 2022 NAIP.

The expectation going in was that NDVI would carry the woody/herbaceous split. **It does not.** In
mid-July on this reach the wet-meadow point bars are *greener* than the cottonwood canopy — the
herbaceous cluster sits at mean NDVI 0.31 against the woody cluster's 0.24. A greenness threshold
alone puts the meadow in the gallery class and some of the gallery outside it.

What separates them is that **a tree is a three-dimensional object and grass is not**:

| Feature | How it is computed | Woody | Herbaceous |
|---|---|---|---|
| **Shadow adjacency** | shadow mask dilated ~5 m, averaged per segment | **0.51** | **0.03** |
| Roughness | local SD of NIR over a 9 m window | 0.14 | 0.09 |
| NDVI | segment mean | 0.24 | 0.31 |

Shadow adjacency does nearly all the work. It is the closest available proxy for canopy height
without lidar, and it is why the §5.1 mitigation ladder starts at "check 3DEP lidar coverage"
rather than "add more spectral indices".

**Two parameters this rests on, and their sensitivities:**

- **Shadow is an absolute cut**, at 50% of scene median brightness — not a percentile. A percentile
  labels a fixed share of any image as shadow whether or not any is present. At Red Shirt 2022 the
  absolute cut found 0.8% of pixels, matching the visible tree shadows.
- **Shadow length depends on sun elevation**, so it varies with acquisition date and latitude. NAIP
  is flown in summer, which bounds the variation, but `VERIFY` this across the 2012–2022 epochs
  before comparing patch areas between years — a longer-shadow epoch will map slightly more woody
  area for the same trees. This is a **change-detection** risk, not an extent risk, and it is the
  first thing to check in Phase 4.

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

**In progress.** `notebooks/PineRidge/03_Cottonwood_Training_Data.ipynb` implements the label
factory and has been run end to end on a 2 × 2 km window at Red Shirt against the `01s` valley
bottom (NAIP `sd_m_4310217_se_13_060_20220713`, 2022, 60 cm):

- 172,728 SLIC segments over 11.1 M pixels in 6 s; 112,022 of them inside the valley bottom.
- k-means (k = 10, seed 42) produced one clean woody cluster — mean NDVI 0.24, shadow adjacency
  0.51, roughness 0.14 — separated from a herbaceous cluster at NDVI 0.31 but shadow adjacency
  0.03. **Shadow adjacency, not greenness, is what separates them.**
- Mapped **7.7 ha of riparian woody canopy in 458 patches**, 2.9% of the 260 ha of valley bottom in
  the window; the overlay tracks individual crowns along the channel.
- 300 stratified validation points written for group interpretation.

*Two gate questions remain open*: the accuracy number (needs the validation sample interpreted) and
the cottonwood/willow question (needs lidar). Cost per tile is recorded in §17.

**Phase 3 — Phenology + Landsat cube.** Derive seasonal windows from observed greenness curves (HLS
for timing precision); build the annual Landsat composite stack over the pilot valley bottom.
*Gate: is there a real late-season separability signal at 30 m? Record measured cost per tile.*

**Phase 4 — Change.** Label transfer, benchmark-epoch classification, per-patch trend analysis,
area-adjusted accuracy. *If a canopy-height layer is in the design by this point, note that the
published CHM is single-epoch (2023) for this area — per-epoch condition trends require running
the model ourselves, which is a PyTorch dependency decision, not a data download (§17).*
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
- [ ] **Validate the AOI against the valley bottom, and decide the AOI rule** (§2.6). The current
      buffer clips ~8% of the `01s` valley bottom; no HUC12 rule fits the corridor. Proposed: HUC8
      topology for reach/gauge *selection*, valley-bottom-validated buffer for *extent*.
- [x] ~~3DEP lidar coverage over the Cheyenne corridor~~ — **answered 2026-09-11: it exists.** The
      TNM Access API returns **150 1 m products** intersecting 13TFJ, from two projects
      (`SD_Southwest_NRCS_SD_2018_D18`, `SD_BlackHills_D23`). Note these are bare-earth **DTM**,
      not a CHM — a CHM needs DSM−DTM from the point cloud (LPC), which is a separate product.
- [~] **CHM source for §5.1 — decided 2026-09-11: start with the published 2023 tile.**
      Measured 2026-09-11: the published NAIP-CHM covers this
      study area for **2023 only** — every other year has zero tiles in quad block 43102, so the
      product is single-epoch here, not a time series. Options: (a) **download the 2023 tile** —
      free, minutes, no dependencies, and enough to answer whether height separates cottonwood
      from willow at all; (b) **run NTSG's MIT-licensed model on our own NAIP** — date-matches the
      2022 labels and yields 2016–2022 (the 2012/2014 epochs are 1 m and outside the model's
      0.6 m training distribution), but adds PyTorch, the dependency SAM was rejected for in §5;
      (c) derive from the 3DEP point cloud — most work, fully independent.
      **Adopted: (a) first, as a gate on (b).** The one-year offset is accepted because mature
      canopy height is effectively static over that interval. Still open underneath this: whether
      height actually separates the classes in our patches, and — only if it does — whether the
      per-epoch series `06` would need is worth a PyTorch dependency.
- [x] ~~MGRS tile index — `13TFJ` exists only as a comment string~~ — **done 2026-09-11.** `01` §2
      derives any square's bounds *and* its EPSG code arithmetically (~20 lines, no `mgrs`
      dependency); verified that Red Shirt falls inside 13TFJ and that the buffered grid is
      13.44 M cells, matching §2.3. The square is written to the run GeoPackage as `mgrs_tile`.
- [ ] NAIP epoch coverage across all of 13TFJ, not only gauge 06403700; and pre-2012 availability.
      Notebook `02` is built to answer exactly this.
- [ ] **Gauge coordinates for the three non-Red-Shirt walkthrough windows** are approximate
      placeholders in the config cells, marked `VERIFY`. Replace from the `usgs_gauges` layer on
      the first run of `02`.
- [ ] **Screen planted trees out of the gallery product.** Shelterbelts and yard trees classify as
      woody exactly like cottonwood — visible around the ranch buildings in the Red Shirt window.
      `elongation` and `dist_chan_m` are carried on every patch so a screen is possible; what the
      screen should be is a group decision, not a default.
- [ ] Angostura Dam completion date (1949?) and the Edgemont / Craven Canyon mill operating period.
- [ ] Water-quality station coverage — determines whether Q3's mining component is analytical or
      contextual.
- [~] **Valley-bottom area as a fraction of tile area** — **partly answered 2026-09-11.** The Red
      Shirt smoke box is **14.7%** valley bottom (59.0 of 400 km²). Extrapolating that fraction to a
      100 km square gives ~1,473 km² of valley bottom on 13TFJ, ~6.3 G pixels at 60 cm, and a measured
      ~56 min of segmentation plus a network-bound (and parallelisable) imagery read. **Answered 2026-09-11 by the real 13TFJ run: 8.14%** (814 km² of 10,000), not 14.7% — the
      smoke box was centred on the main stem and overstated it by ~1.8×. Re-scale the NAIP cost
      estimates accordingly: ~814 km² of valley bottom, not ~1,473.
- [ ] Phenological windows from observed greenness curves (Phase 3) — must not be assumed.

---

## 18. Repo structure — executed 2026-09-11

The renumbering proposed in earlier drafts has been **carried out**. Notebook state verified
against the files; the working table lives in `CLAUDE.md`.

| Notebook | Content | State |
|---|---|---|
| `00_Study_Area` | corridor AOI, flowlines, gauges | runs |
| `01_VBET_ValleyBottom` | DEM → flowlines → hydrology → valley bottom, for one MGRS square | **rewritten, not yet run** |
| `02_NAIP_Access` | NAIP epoch inventory across the tile + chip access | skeleton |
| `03_NAIP_Segmentation_Labels` | auto-label factory | runs |
| `04_Landsat_Phenology_Cube` | seasonal composites + **derived** windows | skeleton |
| `05_Classification_and_Extent_Change` | label transfer, benchmark epochs | skeleton |
| `06_Gallery_Condition_Trends` | per-patch time series | skeleton |
| `07_Flow_and_WaterQuality_Drivers` | NWIS / WQP / drought | skeleton |
| `08_Synthesis_and_Products` | community-facing outputs, gated on §11 | skeleton |
| `checks/01s_VBET_SmokeTest` | standing environment check | runs |

**Skeleton** means: title stating what the notebook reads and writes, section headings, a
complete config cell, and a manifest stub — with the analysis cells deliberately **empty**.
Per §14 the markdown is not written in advance; the group fills these in together.

**The blocker is cleared.** `01` no longer contains `d8_pointer`, `d8_flow_accumulation`,
`extract_streams`, `FLOW_ACCUM_THRESHOLD` or the HUC-chunking section — verified by scan. It now
runs the validated three-tool chain ported from `01s`, parameterised by `TILE` rather than by a
centre point and a box half-width.

**Archived** (`notebooks/archive/`): `01a_DEM_Prefetch` (folded into `01`), `NAIP_Tile_Analysis`
(superseded by `02` and `03`), and the two duplicate HLS notebooks.

### Still outstanding

- `environment.yml` — `scikit-learn`, `scikit-image`, `odc-stac` are needed by `03`; `mgrs` is
  **no longer needed** (§2.1 geometry is arithmetic). `docker/jupyterlab/environment.yml` stays
  intentionally drifted per `CLAUDE.md`; batch all image-affecting changes for the next rebuild.
- The **first real run of `01` on 13TFJ** — the Phase 1b gate, and the thing everything
  downstream is waiting on.
- Repointing `03` at `vbet_13TFJ` and running the four walkthrough windows.

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
