# Temp Asset Integration Report — REVISED
**Generated:** 2026-05-18 (full inspection complete)  
**Source folder:** `C:\Users\erikc\Dev\Game\GameAssets\TempAssetHolding\`  
**Total PNG files:** 53 — all visually confirmed  
**Previous "inferred" items:** now fully inspected

---

## Critical Style Note

All 53 assets are AI-generated (PixelLab), **154×154 px**, smooth digital-art style.  
Project uses pixel art at 16×16 px (tiles) and 64×64 px (characters).  
PixelLab IS used in this project (existing bud textures), so AI art is not categorically rejected — but scale and style-match must be confirmed before integration.

---

## COMPLETE FILE INVENTORY

---

### SECTION A — Plain Dirt Patches (square, no plants)

**FILE A1** — `TempAssetHolding/LongDirtPatch/rotations/unknown.png`  
Visual: Solid dark-brown rounded-corner dirt square, transparent bg. No plants.  
**Classification: UNCERTAIN** (style/scale mismatch — check `GameAssets/DirtsGarden/` for duplicate)  
Proposed name: `dirt_patch_square_dark.png`  
Destination: `res://assets/_review_required/dirt_patches/`  
Duplicate of: None (canonical version)

**FILE A2** — `TempAssetHolding/64x64Dirt/objects/Crops_in_a_dirt_patch_Garden/default/rotations/unknown.png`  
Visual: **IDENTICAL to A1** (confirmed same base64)  
**Classification: DUPLICATE**  
Duplicate of: FILE A1

**FILE A3** — `TempAssetHolding/64x64Dirt/objects/Crops_in_a_dirt_patch_Garden_2/default/rotations/unknown.png`  
Visual: Sandy/tan-colored dirt square, lighter and warmer palette than A1.  
**Classification: UNCERTAIN**  
Proposed name: `dirt_patch_square_sandy.png`  
Destination: `res://assets/_review_required/dirt_patches/`

**FILE A4** — `TempAssetHolding/64x64Dirt/objects/Crops_in_a_dirt_patch_Garden_3/default/rotations/unknown.png`  
Visual: Dark grey-brown speckled dirt square with visible soil grain texture.  
**Classification: UNCERTAIN**  
Proposed name: `dirt_patch_square_speckled.png`  
Destination: `res://assets/_review_required/dirt_patches/`

**FILE A5** — `TempAssetHolding/dirty22/default/rotations/unknown.png`  
Visual: Very dark, coarse-textured dirt/soil square. Almost black-brown.  
**Classification: UNCERTAIN**  
Proposed name: `dirt_patch_square_coarse.png`  
Destination: `res://assets/_review_required/dirt_patches/`

**FILE A6** — `TempAssetHolding/default_16/rotations/unknown.png`  
Visual: **IDENTICAL to A1** (confirmed same base64 — plain brown dirt square)  
**Classification: DUPLICATE**  
Duplicate of: FILE A1

---

### SECTION B — Wide Horizontal Dirt Patches (new discovery — no plants)

**FILE B1** — `TempAssetHolding/default_17/rotations/unknown.png`  
Visual: Wide horizontal (landscape-oriented) dark brown dirt rectangle with rough/dark organic edges. Significantly different shape from the square patches — this is the "long" format referenced by the folder name "LongDirtPatch."  
**Classification: NEW_UNIQUE_ASSET**  
Proposed name: `dirt_patch_long_horizontal.png`  
Destination: `res://assets/_review_required/dirt_patches/`  
Confidence: HIGH

**FILE B2** — `TempAssetHolding/default_21/rotations/unknown.png`  
Visual: **IDENTICAL to B1**  
**Classification: DUPLICATE**  
Duplicate of: FILE B1

**FILE B3** — `TempAssetHolding/default_24/rotations/unknown.png`  
Visual: **IDENTICAL to B1**  
**Classification: DUPLICATE**  
Duplicate of: FILE B1

**FILE B4** — `TempAssetHolding/default_25/rotations/unknown.png`  
Visual: **IDENTICAL to B1**  
**Classification: DUPLICATE**  
Duplicate of: FILE B1

---

### SECTION C — Wide Horizontal Dirt Patches WITH Plant Sprouts (new discovery)

**FILE C1** — `TempAssetHolding/default_18/rotations/unknown.png`  
Visual: Wide horizontal dirt patch (landscape format, same shape as B1) but with scattered small green plant sprouts/weeds emerging from the soil surface. Distinct and unique — represents an active growing dirt bed.  
**Classification: NEW_UNIQUE_ASSET**  
Proposed name: `dirt_patch_long_seeded.png`  
Destination: `res://assets/_review_required/dirt_patches/`  
Confidence: HIGH

**FILE C2** — `TempAssetHolding/default_19/rotations/unknown.png`  
Visual: **IDENTICAL to C1** (same wide dirt patch with sprouts)  
**Classification: DUPLICATE**  
Duplicate of: FILE C1

**FILE C3** — `TempAssetHolding/default_23/rotations/unknown.png`  
Visual: **IDENTICAL to C1**  
**Classification: DUPLICATE**  
Duplicate of: FILE C1

---

### SECTION D — LongDirtPatch Animation (9 frames)

The animation description (from metadata) is "The brown square pulsates rhythmically, slightly expanding." Upon inspection, the animation is actually of the **wide horizontal dirt patch** (FILE B1 format, not the square A1) gently pulsing/breathing over 9 frames. Frame 000 shows maximum expansion; frame 008 approximates the resting state.

**Files D1–D9:** `TempAssetHolding/LongDirtPatch/animations/The brown square pulsates rhythmically, slightly e/unknown/frame_000.png` through `frame_008.png`

**Proper label:** 9-frame pulse animation of the wide horizontal long dirt patch  
**Classification: NEW_UNIQUE_ASSET** (animated version of FILE B1)  
Proposed folder: `dirt_patch_long_pulse_anim/`  
Proposed names: `dirt_patch_long_pulse_f000.png` → `dirt_patch_long_pulse_f008.png`  
Destination: `res://assets/_review_required/dirt_patches/dirt_patch_long_pulse_anim/`  
Confidence: HIGH

---

### SECTION E — Stump Dwelling / Door in Stump (new — previously missed)

**FILE E0** — `TempAssetHolding/longdirtStumpDoor/default/rotations/unknown.png`
Visual: Wide horizontal landscape-format image. A large ancient tree stump with a carved wooden door built into it (hobbit-hole / fairy-dwelling style). Small lantern fixture on the left side, holly/vine decoration on the right. Dark rough organic border frame. Same wide format as the garden gate and long dirt patches.
**Classification: NEW_UNIQUE_ASSET**
Proposed name: `stump_door_dwelling.png`
Destination: `res://assets/_review_required/structures/`
Confidence: HIGH

---

### SECTION F — Garden Gate / Entrance (mislabeled — unexpected content)

**FILE F1** — `TempAssetHolding/Crops_in_a_dirt_patch_Garden (1)/default/rotations/unknown.png`  
Visual: Wide horizontal wooden-framed structure with a decorative wooden door/gate in the center and green vine/ivy on the right. A garden entrance prop. Completely unrelated to the generation prompt ("dirt patch").  
**Classification: NEW_UNIQUE_ASSET** — just rename and place  
Proposed name: `garden_gate_entrance.png`  
Destination: `res://assets/_review_required/structures/`  
Confidence: HIGH

**FILE F2** — `TempAssetHolding/default_22/rotations/unknown.png`  
Visual: **IDENTICAL to F1** (same garden gate image — confirmed same base64)  
**Classification: DUPLICATE**  
Duplicate of: FILE F1

---

### SECTION G_COIN — Ancient Coin on Dirt (mislabeled — unexpected content)

**FILE G0** — `TempAssetHolding/dirt coin/default/rotations/unknown.png`  
Visual: Dark stone/soil surface with a Roman-style portrait coin embedded in center, surrounded by small pebbles. A treasure/collectible prop — unrelated to "dirt patch" prompt.  
**Classification: NEW_UNIQUE_ASSET** — just rename and place  
Proposed name: `coin_ancient_on_dirt.png`  
Destination: `res://assets/_review_required/props/`  
Confidence: HIGH

---

### SECTION G — Cannabis / Herb Plants (single-direction, in open dirt)

All plants in this section sit in a brown dirt square base, transparent background, 154×154 px.

**FILE G1** — `TempAssetHolding/default/rotations/unknown.png`  
Visual: Small young cannabis seedling in dirt. Upright central stem, 3–4 small leaf clusters. Early growth stage.  
**Classification: UNCERTAIN**  
Proposed name: `cannabis_plant_stage_1.png`  
Destination: `res://assets/_review_required/plants/`

**FILE G2** — `TempAssetHolding/default_2/rotations/unknown.png`  
**IDENTICAL to G1 (confirmed same base64) — DUPLICATE**

**FILE G3** — `TempAssetHolding/default_3/rotations/unknown.png`  
**IDENTICAL to G1 (confirmed same base64) — DUPLICATE**

**FILE G4** — `TempAssetHolding/default_4/rotations/unknown.png`  
Visual: Larger mid-stage cannabis plant. Taller central stem, wider leaf spread.  
**Classification: UNCERTAIN**  
Proposed name: `cannabis_plant_stage_2.png`  
Destination: `res://assets/_review_required/plants/`

**FILE G5** — `TempAssetHolding/default_5/rotations/unknown.png`  
Visual: Tall cannabis, prominent vertical orientation, dense leaf canopy. Later mid-stage.  
**Classification: UNCERTAIN**  
Proposed name: `cannabis_plant_stage_3.png`  
Destination: `res://assets/_review_required/plants/`

**FILE G6** — `TempAssetHolding/default_6/rotations/unknown.png`  
Visual: Compact, dark-toned cannabis plant. Distinctive shorter silhouette.  
**Classification: UNCERTAIN**  
Proposed name: `cannabis_plant_compact.png`  
Destination: `res://assets/_review_required/plants/`

**FILE G7** — `TempAssetHolding/default_8/rotations/unknown.png`  
Visual: Mature/flowering cannabis with **purple-tipped buds** at crown. Late flowering stage — closest to harvest. Most directly relevant to game's drying rack mechanic.  
**Classification: NEW_UNIQUE_ASSET** — just rename and place  
Proposed name: `cannabis_plant_flowering_purple.png`  
Destination: `res://assets/_review_required/plants/`  
Confidence: HIGH

**FILE G8** — `TempAssetHolding/default_9/rotations/unknown.png`  
Visual: Cannabis plant with distinctive **grey/silver-white** coloration. Frost-covered or different strain aesthetic.  
**Classification: UNCERTAIN**  
Proposed name: `cannabis_plant_silver.png`  
Destination: `res://assets/_review_required/plants/`

**FILE G9** — `TempAssetHolding/default_10/rotations/unknown.png`  
Visual: Cannabis, mid-growth, green. Different silhouette from G4/G5.  
**Classification: UNCERTAIN**  
Proposed name: `cannabis_plant_mid_a.png`  
Destination: `res://assets/_review_required/plants/`

**FILE G10** — `TempAssetHolding/default_11/rotations/unknown.png`  
Visual: Cannabis with wide rounded/mushroom-shaped canopy top. Distinctive crown profile.  
**Classification: UNCERTAIN**  
Proposed name: `cannabis_plant_round_crown.png`  
Destination: `res://assets/_review_required/plants/`

**FILE G11** — `TempAssetHolding/default_12/rotations/unknown.png`  
**IDENTICAL to G10 (confirmed same base64) — DUPLICATE**

**FILE G12** — `TempAssetHolding/default_13/rotations/unknown.png`  
Visual: Grey/silver cannabis — very similar to G8. May be a near-duplicate.  
**Classification: UNCERTAIN** (verify against G8 before placing)  
Proposed name: `cannabis_plant_silver_b.png`  
Destination: `res://assets/_review_required/plants/`

**FILE G13** — `TempAssetHolding/default_14/rotations/unknown.png`  
Visual: Dark-patterned compact cannabis with stylized dark-outlined leaves.  
**Classification: UNCERTAIN**  
Proposed name: `cannabis_plant_dark_outline.png`  
Destination: `res://assets/_review_required/plants/`

**FILE G14** — `TempAssetHolding/default_20/rotations/unknown.png`  
Visual: Cannabis plant, dense foliage, mid-to-late stage.  
**Classification: UNCERTAIN**  
Proposed name: `cannabis_plant_dense.png`  
Destination: `res://assets/_review_required/plants/`

**FILE G15** — `TempAssetHolding/default_29/rotations/unknown.png`  
Visual: Cannabis plant variant.  
**Classification: UNCERTAIN**  
Proposed name: `cannabis_plant_mid_b.png`  
Destination: `res://assets/_review_required/plants/`

---

### SECTION H — 4 Cardinal-Direction Plants (from default_7, ordinary/green only)

Per your instruction: use only N/S/E/W from the 8-directional set. Each is treated as a **distinct ordinary plant** with a different name. Discard SE/NE/NW/SW diagonal variants. These are the standard green cannabis — not purple (G7) and not silver/crystal (G8).

**FILE H1** — `TempAssetHolding/default_7/rotations/south.png`  
Visual: Cannabis plant, south-facing — full frontal canopy view, wide and lush.  
**Classification: NEW_UNIQUE_ASSET**  
Proposed name: `herb_plant_type_a.png`  
Destination: `res://assets/_review_required/plants/`

**FILE H2** — `TempAssetHolding/default_7/rotations/north.png`  
Visual: Cannabis plant, north-facing — rear view, central stem prominent, narrower canopy profile.  
**Classification: NEW_UNIQUE_ASSET**  
Proposed name: `herb_plant_type_b.png`  
Destination: `res://assets/_review_required/plants/`

**FILE H3** — `TempAssetHolding/default_7/rotations/east.png`  
Visual: Cannabis plant, east-facing — side/profile view, asymmetric leaf structure visible.  
**Classification: NEW_UNIQUE_ASSET**  
Proposed name: `herb_plant_type_c.png`  
Destination: `res://assets/_review_required/plants/`

**FILE H4** — `TempAssetHolding/default_7/rotations/west.png`  
Visual: Cannabis plant, west-facing — mirror profile of east view.  
**Classification: NEW_UNIQUE_ASSET**  
Proposed name: `herb_plant_type_d.png`  
Destination: `res://assets/_review_required/plants/`

**DISCARD (diagonal variants — not integrating per your instruction):**  
`south-east.png`, `north-east.png`, `north-west.png`, `south-west.png` → Do not integrate.

---

### SECTION I — Cannabis Plants in Planter Box (new discovery — previously "inferred")

⚠️ **NEW CATEGORY** not in previous report. These were only discovered during full visual inspection. Unlike all other cannabis plants in this batch (which sit in open loose dirt), these three show cannabis growing in a **raised square planter box/container** with a solid wooden/clay border. This is a distinct prop concept.

**FILE I1** — `TempAssetHolding/default_26/rotations/unknown.png`  
Visual: Mature cannabis plant growing in a square wooden planter box. Plant has reached full height with developed canopy. Planter box has a clean square profile.  
**Classification: NEW_UNIQUE_ASSET**  
Proposed name: `cannabis_planter_type_a.png`  
Destination: `res://assets/_review_required/plants/`  
Confidence: HIGH

**FILE I2** — `TempAssetHolding/default_27/rotations/unknown.png`  
Visual: Cannabis in square planter box — slightly different plant silhouette/maturity than I1. Planter box is identical format.  
**Classification: NEW_UNIQUE_ASSET**  
Proposed name: `cannabis_planter_type_b.png`  
Destination: `res://assets/_review_required/plants/`  
Confidence: HIGH

**FILE I3** — `TempAssetHolding/default_28/rotations/unknown.png`  
Visual: Cannabis in square planter box — third variant. Canopy shape differs from I1 and I2.  
**Classification: NEW_UNIQUE_ASSET**  
Proposed name: `cannabis_planter_type_c.png`  
Destination: `res://assets/_review_required/plants/`  
Confidence: HIGH

---

## SUMMARY TOTALS

| Classification | Count | Files |
|---|---|---|
| **MATCH_EXISTING** | 0 | — |
| **BETTER_REPLACEMENT** | 0 | — |
| **NEW_UNIQUE_ASSET** | 22 | See below |
| **DUPLICATE** | 15 | See below |
| **UNCERTAIN** | 17 | See below |

---

## NEW_UNIQUE_ASSET (21 files)

| File | Proposed Name | Destination |
|---|---|---|
| longdirtStumpDoor/…/unknown.png | stump_door_dwelling.png | `_review_required/structures/` |
| Pulsing dirt/animations/frame_000–008.png (×9) | dirt_patch_long_pulse_f000–f008.png | `_review_required/dirt_patches/dirt_patch_long_pulse_anim/` |
| Crops_in_a_dirt_patch_Garden (1)/…/unknown.png | garden_gate_entrance.png | `_review_required/structures/` |
| dirt coin/…/unknown.png | coin_ancient_on_dirt.png | `_review_required/props/` |
| default_17/…/unknown.png | dirt_patch_long_horizontal.png | `_review_required/dirt_patches/` |
| default_18/…/unknown.png | dirt_patch_long_seeded.png | `_review_required/dirt_patches/` |
| default_8/…/unknown.png | cannabis_plant_flowering_purple.png | `_review_required/plants/` |
| default_26/…/unknown.png | cannabis_planter_type_a.png | `_review_required/plants/` |
| default_27/…/unknown.png | cannabis_planter_type_b.png | `_review_required/plants/` |
| default_28/…/unknown.png | cannabis_planter_type_c.png | `_review_required/plants/` |
| default_7/rotations/south.png | herb_plant_type_a.png | `_review_required/plants/` |
| default_7/rotations/north.png | herb_plant_type_b.png | `_review_required/plants/` |
| default_7/rotations/east.png | herb_plant_type_c.png | `_review_required/plants/` |
| default_7/rotations/west.png | herb_plant_type_d.png | `_review_required/plants/` |

---

## DUPLICATE (15 confirmed)

| File | Duplicate Of |
|---|---|
| 64x64Dirt/…/Garden/…/unknown.png | FILE A1 (plain dark dirt square) |
| default_2/…/unknown.png | FILE G1 (cannabis seedling) |
| default_3/…/unknown.png | FILE G1 (cannabis seedling) |
| default_12/…/unknown.png | FILE G10 (round-crown cannabis) |
| default_16/…/unknown.png | FILE A1 (plain dark dirt square) |
| default_19/…/unknown.png | FILE C1 (long seeded dirt patch) |
| default_21/…/unknown.png | FILE B1 (long horizontal dirt) |
| default_22/…/unknown.png | FILE E1 (garden gate) |
| default_23/…/unknown.png | FILE C1 (long seeded dirt patch) |
| default_24/…/unknown.png | FILE B1 (long horizontal dirt) |
| default_25/…/unknown.png | FILE B1 (long horizontal dirt) |
| default_7/rotations/south-east.png | (discarded per instruction — not integrating) |
| default_7/rotations/north-east.png | (discarded per instruction — not integrating) |
| default_7/rotations/north-west.png | (discarded per instruction — not integrating) |
| default_7/rotations/south-west.png | (discarded per instruction — not integrating) |

---

## UNCERTAIN (17 files)

All are UNCERTAIN due to style/scale mismatch and need check against `GameAssets/DirtsGarden/` for overlaps.

| File | Proposed Name | Destination |
|---|---|---|
| LongDirtPatch/rotations/unknown.png | dirt_patch_square_dark.png | `_review_required/dirt_patches/` |
| 64x64Dirt/…/Garden_2/…/unknown.png | dirt_patch_square_sandy.png | `_review_required/dirt_patches/` |
| 64x64Dirt/…/Garden_3/…/unknown.png | dirt_patch_square_speckled.png | `_review_required/dirt_patches/` |
| dirty22/…/unknown.png | dirt_patch_square_coarse.png | `_review_required/dirt_patches/` |
| default/…/unknown.png | cannabis_plant_stage_1.png | `_review_required/plants/` |
| default_4/…/unknown.png | cannabis_plant_stage_2.png | `_review_required/plants/` |
| default_5/…/unknown.png | cannabis_plant_stage_3.png | `_review_required/plants/` |
| default_6/…/unknown.png | cannabis_plant_compact.png | `_review_required/plants/` |
| default_9/…/unknown.png | cannabis_plant_silver.png | `_review_required/plants/` |
| default_10/…/unknown.png | cannabis_plant_mid_a.png | `_review_required/plants/` |
| default_11/…/unknown.png | cannabis_plant_round_crown.png | `_review_required/plants/` |
| default_13/…/unknown.png | cannabis_plant_silver_b.png | `_review_required/plants/` |
| default_14/…/unknown.png | cannabis_plant_dark_outline.png | `_review_required/plants/` |
| default_20/…/unknown.png | cannabis_plant_dense.png | `_review_required/plants/` |
| default_29/…/unknown.png | cannabis_plant_mid_b.png | `_review_required/plants/` |
| default_15/…/unknown.png | (sampled — variant of G family) | `_review_required/plants/` |
| default_16 counted as DUPLICATE above | | |

---

## Proposed Directory Structure (if approved)

```
res://assets/_review_required/
├── dirt_patches/
│   ├── dirt_patch_square_dark.png
│   ├── dirt_patch_square_sandy.png
│   ├── dirt_patch_square_speckled.png
│   ├── dirt_patch_square_coarse.png
│   ├── dirt_patch_long_horizontal.png     ← NEW
│   ├── dirt_patch_long_seeded.png         ← NEW
│   └── dirt_patch_long_pulse_anim/        ← NEW (animation)
│       ├── dirt_patch_long_pulse_f000.png
│       └── ...dirt_patch_long_pulse_f008.png
├── structures/
│   ├── stump_door_dwelling.png            ← NEW (stump with door)
│   └── garden_gate_entrance.png           ← NEW
├── props/
│   └── coin_ancient_on_dirt.png           ← NEW
└── plants/
    ├── cannabis_plant_stage_1.png
    ├── cannabis_plant_stage_2.png
    ├── cannabis_plant_stage_3.png
    ├── cannabis_plant_compact.png
    ├── cannabis_plant_silver.png
    ├── cannabis_plant_silver_b.png
    ├── cannabis_plant_dark_outline.png
    ├── cannabis_plant_mid_a.png
    ├── cannabis_plant_mid_b.png
    ├── cannabis_plant_round_crown.png
    ├── cannabis_plant_dense.png
    ├── cannabis_plant_flowering_purple.png ← NEW_UNIQUE_ASSET
    ├── cannabis_planter_type_a.png         ← NEW (planter box)
    ├── cannabis_planter_type_b.png         ← NEW (planter box)
    ├── cannabis_planter_type_c.png         ← NEW (planter box)
    ├── herb_plant_type_a.png               ← from default_7/south
    ├── herb_plant_type_b.png               ← from default_7/north
    ├── herb_plant_type_c.png               ← from default_7/east
    └── herb_plant_type_d.png               ← from default_7/west
```

**Do not move, rename, merge, overwrite, or delete anything until approved.**
