# Game — Asset Inventory

All in-project art assets live in `res://assets/` (verified, no legacy duplicates as of 2026-05-19).

---

## Characters

### Erik (Player)
- **Path:** `res://assets/characters/erik/`
- **Size:** 56×56 px per frame; `AnimatedSprite2D scale=0.5` → 28×28 world size
- **SpriteFrames:** `res://resources/characters/erik_sprites.tres`
- **Animations:**
  - Idle: `idle_south`, `idle_north`, `idle_east` (1 frame each)
  - Idle w/ bucket: `idle_south_bucket`, `idle_north_bucket`, `idle_east_bucket`
  - Walk: `walk_south/north/east_{0-5}` (6 frames each)
  - Walk w/ bucket: `walk_south/north/east_bucket_{0-5}`
  - Chop: `chop_south/north/side/` (16 frames each)
  - Trade: `trade_south/north/side/` (6 frames each)

### GreyHoodie (NPC)
- **Path:** `res://assets/characters/grey_hoodie/`
- **SpriteFrames:** `res://resources/characters/grey_hoodie_sprites.tres`
- **Animations:** `idle_south/east/west`, `walk_south/north/east/west`, `breathing_idle/east/south/west`
- **Extras:** `grey_hoodie/rotations/` — rotation frames (unwired)

### Forest Creature (ShT)
- **Path:** `res://assets/characters/forest_creature/hobo/`
- **SpriteFrames:** `res://resources/characters/hobo_man_sprites.tres`
- **Animations:** `idle_east/north/south/west/northeast/northwest/southeast/southwest`, `walk_east/north/south/west`

### Unused/Available Characters
- `res://assets/characters/player_alt/` — Alt player (Axe/Bow/Idle/Run/Walk/etc. dirs, unwired)
- `res://assets/characters/purple_jack/` — Purple Jack character (unwired)

---

## Nature

### Trees
| Species | Static | Chop | Fall | Notes |
|---|---|---|---|---|
| Pine | `nature/trees/pine/` (static) | `pine/pine_chop/` (9 frames) | `pine/pine_fall/` (9 frames) | 96×96 |
| Maple | `nature/trees/maple/` | `maple_chop/`, `maple_fall/`, `maple_hit_fall/` | 9 frames each | 96×96 |
| Fir | `nature/trees/fir/` | `fir_chop/`, `fir_fall/` | 9 frames | 96×96 |
| Willow | `nature/trees/willow/` | — | — | Animated (shake), 2.975× scaled |
| Oak | `nature/trees/tree_oak_green.png` | — | — | Static PNG only, unwired |

**SpriteFrames resources:**
- `res://resources/pine_frames.tres`
- `res://resources/maple_frames.tres`
- `res://resources/fir_frames.tres`
- `res://resources/stump_frames.tres`
- `res://resources/stump_home_001_frames.tres`

### Stumps
- `res://assets/nature/stumps/stump_round.png` — 96×96 static (tree stump after chop)
- `res://assets/nature/stumps/stump_dissolve/` — 16-frame dissolve animation (unwired)

### Rocks
| Set | Location | Frames | Status |
|---|---|---|---|
| Rounded poky | `nature/rocks/rounded_poky_rock/` | 2 anims × 9 frames | No SpriteFrames .tres yet |
| Tower rock | `nature/rocks/tower_rock/` | 2 anims × 9 frames | No SpriteFrames .tres yet |
| Square rock | `nature/rocks/square_rock/` | 1 anim × 16 frames | No SpriteFrames .tres yet |
| Jagged rock | `nature/rocks/rock_jagged/` | break + hit anims | No SpriteFrames .tres yet |
| Slate flat | `nature/rocks/rock_slate_flat/` | crumble anim | No SpriteFrames .tres yet |
| Stone cluster A | `nature/rocks/stone_cluster_a/` | hit × 2 | No SpriteFrames .tres yet |
| Stone pile square | `nature/rocks/stone_pile_square/` | hit | No SpriteFrames .tres yet |
| Red cap mushroom | `nature/rocks/RedCapMushroom.png` | static | Unwired |

### Bushes
- **14 variants** at `res://assets/nature/bushes/` (including `purple_punch_one/` animated)
- All Sprite2D-ready PNGs; none wired into world.tscn yet

### Plants
- `nature/plants/cannabis/` — cannabis plant frames
- `nature/plants/herbs/herb_plant_type_a.png` — herb plant (used as drying rack placeholder)
- Plant growth sprite: `PurplePlant` in `world.tscn` (AnimatedSprite2D, inline)

---

## Props

### Bud Products (8 types)
- `res://assets/props/bud/dry_bud.png`
- `res://assets/props/bud/hang_dry.png`
- `res://assets/props/bud/plant_green.png`
- `res://assets/props/bud/plant_green_2.png`
- `res://assets/props/bud/plant_purple.png`
- `res://assets/props/bud/weed_plant.png`
- `res://assets/props/bud/weed_plant_2.png`
- `res://assets/nature/plants/herbs/herb_plant_type_a.png` (placeholder for `herb_bundle_dried.png`)

### Drying Rack
- `res://assets/props/drying_rack/rack_new_empty.png`
- `res://assets/props/drying_rack/rack_new_3plants.png`
- `res://assets/props/drying_rack/rack_new_2plants.png`
- `res://assets/props/drying_rack/rack_new_1plant.png`

### Furniture (unwired, Sprite2D-ready)
- `res://assets/props/furniture/furniture_grandfather_clock.png`
- `res://assets/props/furniture/furniture_bed.png`
- `res://assets/props/furniture/furniture_plant_shelf.png`

### Items / Collectibles
- `res://assets/props/items/tool_axe.png` — axe (equippable tool)
- `res://assets/props/items/stone_pile.png` — stone pile (grove input)
- `res://assets/props/items/wood_pile.png` — wood (from tree chop / grove output)
- `res://assets/props/items/lumber.png` — lumber (grove processed output)
- `res://assets/props/items/gem_ruby.png` — ruby gem (NPC trade reward)
- `res://assets/props/items/` — 39+ additional items (ingots ×19, wood piles ×14, currency ×5; imported, unwired)

### Well
- `res://assets/props/well/` — animated well water sprite

### Garden
- `res://assets/props/garden/` — dirt patches + `dirt_patch_long_pulse_anim/` animated

---

## Structures

### Active Buildings
| Asset | Path | Used In |
|---|---|---|
| Bakery main | `structures/shops/shop_bakery_main.png` | world.tscn PlayerHome |
| Bakery open | `structures/shops/shop_bakery_open.png` | world.tscn (open animation) |
| Teal house | `structures/houses/house_grey_teal_animation.png` | world.tscn HouseTwostoryTeal |
| Cave entrance | `structures/cave_entrance_arch_stone.png` | world.tscn |
| Stump dwelling | `structures/stump_door_dwelling.png` | world.tscn |

### Grove Stumps (stump_home series)
| Asset | Status |
|---|---|
| `structures/grove/stump_home_001.png` | Active (Fay Grove, animated) |
| `structures/grove/stump_home_001_door/` | Door open animation (unwired) |
| `structures/grove/stump_home_005.png` | Imported, not placed |
| `structures/grove/stump_home_005_door/` | Door animation, unwired |
| `stump_home_002–004.png` | Imported, not placed |
| `structures/grove/` — 7 more dwelling sprites | Imported, not placed |

---

## Tiles

| Tileset | Location | Dimensions | Use |
|---|---|---|---|
| Main world | `assets/tiles/Tile.png` | 16×16 | Ground + cliff transitions |
| Solid | `assets/tiles/Solid.png` | 16×16 | Large solid atlas |
| Interior | `assets/tiles/interior/` | varies | Room floors/walls |
| 32×32 | `assets/tiles/32x32/` | 32×32 | Larger format tiles |

Active `.tres` tileset: `res://resources/tilesets/GrassBrick_OVERLAYS__tileset.tres`

---

## UI

- `res://assets/ui/WaterGem.png` — water icon in top bar
- `res://assets/ui/WaterMeterBar.png` — water progress bar texture
- `res://assets/ui/bucket_empty.png` — hotbar slot 0 empty
- `res://assets/ui/bucket_full.png` — hotbar slot 0 full

---

## Effects

- `res://assets/effects/` — (present, contents not wired to any script)

---

## Asset Counts Summary

| Category | Approx. Count | Active | Unwired |
|---|---|---|---|
| Character sprites | ~200 frames | 3 characters | 2 alts |
| Tree frames | ~120 frames | 4 species | 0 |
| Stump frames | ~30 frames | 1 | 1 |
| Rock sets | 7 sets | 0 (no SpriteFrames) | 7 |
| Bush variants | 14 | 0 | 14 |
| Prop items | 39+ | 5 (axe, stone, wood, lumber, gem) | 34+ |
| Structure PNGs | ~20 | 5 | 15 |
| Furniture PNGs | 3 | 0 | 3 |
| Bud types | 8 | 8 (drying rack rewards) | 0 |
