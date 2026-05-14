# GameAssets Index
> Auto-generated 2026-05-05. Update when adding new assets.

## Player — Erik (`ErikPlayer/`)
56×56 px, PixelLab mannequin, high top-down view.

**Flat frames (active in game):**
| File pattern | Count | Notes |
|---|---|---|
| `idle_{dir}.png` | 4 | south / north / east / west |
| `idle_{dir}_bucket.png` | 3 | south / north / east |
| `walk_{dir}_{n}.png` | 22 | south×6, north×6, east×6, west×4 |
| `walk_{dir}_bucket_{n}.png` | 22 | south×6, north×3, east×3, west×3 + bucket variants |
| `{dir}.png` | 4 | raw PixelLab rotation stills (east/north/south/west) |

**PixelLab animation exports (`animations/`):**
| Folder | Frames | Directions | Notes |
|---|---|---|---|
| `Eating_big_red_cap_mushroom_and_seeing_red_sparks-1712ee53` | 16 | 4 | Eating mushroom |
| `Holding_a_bucket_of_water-1f650d97` | 16 | 4 | Carrying bucket walk |
| `Jumping-3ee4560a` | 9 | 4 | Jump arc |
| `Pull_Object-e217c136` | 6 | 4 | Pulling |
| `Push_Object-a918a249` | 6 | 4 | Pushing |
| `Walk_v2` | 6 | 4 | Updated walk cycle |

**Reference rotations (`rotations/`):** 8-direction stills (N/NE/E/SE/S/SW/W/NW)

---

## Player — Generic Spritesheet (`Player Character/`)
Separate asset-pack character (not Erik). Spritesheets per action/direction.

| Folder | Files |
|---|---|
| `Axe/` `Bow/` `Death/` `Hit/` `Hoe/` | Down / Side / Up (3 each) |
| `Idle/` `Pickup/` `Run/` `Walk/` | Down / Side / Up (3 each) |
| `Sword/` `pickaxe/` | Down / Side / Up (3 each) |
| `Sprites/Sprites.png` | Full combined spritesheet |

---

## NPCs (`NPCs/`)

**Generic NPCs** (legacy, renamed 2026-05-14):
| File | Description |
|---|---|
| `npc_sprite_dark_hair.png` | Multi-direction sheet, dark hair |
| `npc_sprite_red_hair.png` | Multi-direction sheet, red hair |
| `npc_sprite_green_hair.png` | Multi-direction sheet, green hair |
| `npc_sprite_gold_hair.png` | Multi-direction sheet, gold/blonde hair |
| `npc_sprite_brown_hair.png` | Multi-direction sheet, brown hair |
| `npc_sprite_pink_hair.png` | Multi-direction sheet, pink/magenta hair |
| `npc_sprite_darkgreen_hair.png` | Multi-direction sheet, dark green hair |
| `npc_sprite_grey_hair.png` | Multi-direction sheet, grey hair |

**GreyHoodie** (`NPCs/GreyHoodie/`) — 92×92, scruffy tie-dye hoodie character
| Animation | Frames | Directions |
|---|---|---|
| `Breathing_Idle` | 4 | E / S / W |
| `Push_Object` | 6 | E / S |
| `slowly_receiving_a_bag_of_dry_lettuce` | 4 | N / S |
| `Walking` | 6 | 4 |
Rotations: 8-direction stills

**PurpleJack** (`NPCs/PurpleJack/`) — female, purple/white jacket
Rotations only: 8-direction stills, no animations yet

---

## Tiles (`Tiles/`)
| File | Notes |
|---|---|
| `Tile.png` | Main 240×192 atlas, 15×12 grid at 16×16. Used for ground TileSet |
| `fivegrass.png` | 5 grass tile variants (active in world) |
| `mabeyfive.png` | 5 more grass variants (active in world) |
| `grass_stone_dirt.png` | Stone/dirt transition tiles |
| `Stairs.png` | Stair sprite |

---

## Environment — World Objects

### Rocks (`Rocks/`)
19 individual rock sprites, renamed to descriptive snake_case (2026-05-14):
| File | Description | Active |
|---|---|---|
| `rock_grey_cluster.png` | Grey cluster with pebbles (formerly 18.png) | ✅ world.tscn |
| `rock_grey_small_round.png` | Small grey rounded boulder | legacy |
| `rock_dark_medium.png` | Medium dark boulder | legacy |
| `rock_grey_triangular.png` | Small triangular grey rock | legacy |
| `rock_dark_tiny.png` | Tiny dark rock piece | legacy |
| `rock_grey_cluster_large.png` | Large grey clustered rocks | legacy |
| `rock_dark_small_round.png` | Small rounded dark stone | legacy |
| `rock_grey_medium_round.png` | Medium grey rounded boulder | legacy |
| `rock_grey_cluster_irregular.png` | Large irregular grey cluster | legacy |
| `rock_dark_pebble.png` | Small dark stone pebble | legacy |
| `rock_dark_grey_medium.png` | Medium dark grey boulder | legacy |
| `rock_dark_fragment.png` | Small dark rock fragment | legacy |
| `rock_grey_pebble_tiny.png` | Tiny grey stone pebble | legacy |
| `rock_grey_medium_round_2.png` | Medium rounded grey stone (alt) | legacy |
| `rock_dark_small.png` | Small dark rock piece | legacy |
| `rock_grey_upright.png` | Small upright grey stone | legacy |
| `rock_dark_round_medium.png` | Medium dark rounded rock | legacy |
| `rock_grey_stacked_large.png` | Large stacked grey rocks | legacy |
| `rock_grey_cluster_medium.png` | Medium grey clustered rocks | legacy |

### Trees (`Trees/`)
Renamed to descriptive snake_case (2026-05-14):
| File | Description | Active |
|---|---|---|
| `tree_pine_tall.png` | Tall conifer/pine (formerly Tree1.png) | border sprites |
| `bush_green_round.png` | Small rounded green bush (formerly 2.png) | legacy |
| `shrub_berries_red.png` | Tiny red berry cluster (formerly 3.png) | legacy |
| `log_brown_short.png` | Short brown tree trunk log (formerly 4.png) | ✅ world.tscn |
| `log_fallen_brown.png` | Long horizontal fallen log (formerly 5.png) | ✅ world.tscn |
| `tree_foliage_overlay_dark.png` | Dark foliage shadow overlay (formerly 6.png) | legacy |
| `shadow_tree_black.png` | Black irregular tree shadow (formerly Treeshadow.png) | legacy |
| `tree_willow_weeping.png` | Green weeping willow canopy | ✅ world.tscn |
| `tree_pine_bushy_b.png` | Bushy pine tree variant B | ✅ world.tscn |
| `tree_pine_narrow.png` | Narrow pine tree | ✅ world.tscn |
| `tree_ginkgo.png` | Ginkgo tree | ✅ world.tscn |
| `tree_oak_green.png` | Green oak tree | ✅ world.tscn |

### Caves (`Caves/`)
| Subfolder | Contents |
|---|---|
| `CaveEntrance/` | `cave_entrance_arch_stone.png` (formerly 1.png — arched brick/stone entrance) |
| `Ores/` | Coal, Diamond, Emerald, Gold, Iron, Purple Ore, RedOre |
| `Rocks/` | 4 cave rock variants |
| `Tiles/Tiles.png` | Cave tile atlas |

### Water (`Water/`)
| Subfolder | Contents |
|---|---|
| `Bridge/` | `16X16.PNG` (tile), `Bridge can be used…` (160×80 object) |
| `Rocks/` | 4 water rocks (sized: 23×19, 58×63, 16×35, 33×32) |
| `RockyLake/16x16.png` | Rocky lake tile |
| `Tiles/Tiles 16x16.png` | Water tile atlas |
| `Water Dots/` | `Dot1`–`Dot5` — water surface decoration |
| `Waterfall/Waterfall.png` | Waterfall sprite |

### Well Water (`WellWater/`)
`WellWater1.png` – `WellWater15.png` — 15-frame well fill animation

---

## Buildings & Structures

### Houses (`Houses/`) — LEGACY, not in active scenes
Renamed from numbered filenames (2026-05-14). None currently referenced in world.tscn.
| Subfolder | Old Name → New Name |
|---|---|
| `Farm/` | `1.png` → `farmhouse_barn_main.png` (red barn, green roof) |
| `Houses/` | `1–8.png` → `house_generic_01–08.png` (8 varied house styles) |
| `Shops/` | `1.png` → `shop_striped_red_brown.png`, `2.png` → `shop_striped_teal_green.png`, `3.png` → `shop_striped_red_brown_alt.png`, `4.png` → `shop_striped_teal_blue_alt.png` |
| `Tents/` | `1.png` → `tent_yellow_white.png`, `2.png` → `tent_yellow.png`, `3.png` → `tent_purple_dark.png`, `4.png` → `tent_red_orange.png`, `5.png` → `tent_navy_dark.png` |
| `Well/` | `1.png` → `well_roofed_red.png`, `2.png` → `well_roofed_teal.png`, `3.png` → `well_roofed_purple.png`, `4.png` → `well_roofed_dark.png` |

### Town (`Town/`)
Larger town asset pack. Some folders duplicate Village content.
| Subfolder | Contents |
|---|---|
| `1_16x16.png`, `2.png`, `3.png` | Town background/environment sprites |
| `Cart/` | `1.png`–`3.png` (3 cart variants) |
| `Door Animation/` | `Door1`–`Door4` (4-frame open animation, 29×19) |
| `Houses/` | 27 house designs × 3 files each (`N_1/2/3.png`) + `WINDOW_1/2`, `roofexpand` |
| `Objects/` | Seats (front/back/side), boxes (bOX_1, bOX_3 series) |
| `Roads/` | `TILES_16X16.PNG`, `1.PNG`, `DECO_1`–`DECO_4`, `DECO_SIDEWALK`, `DECO_WALL_1`–`3` |
| `Smoke/` | `smoke1`–`smoke8` (8-frame chimney smoke) |

### Village (`Village/`)
| Subfolder | Contents |
|---|---|
| `Cart/` | `1.png`–`3.png` |
| `Door Animation/` | `Door1`–`Door4` (same as Town) |
| `Fire/` | `fire1`–`fire8` (8-frame fire animation) |
| `Houses/` | 13 houses × 3 files + Blacksmith (3), Shop_1/2/3 (3 each) |
| `Objects/` | Lights (left/right/both), Seats, Boxes (same series as Town) |
| `Smoke/` | `Smoke1`–`Smoke8` |

### Winter (`Winter/`)
Winter-themed equivalents. Mirrors main structure.
| Subfolder | Contents |
|---|---|
| `Barn/1.png` | Winter barn |
| `Bridge/` | Bridge sprite |
| `Houses/` | `1.png`–`2.png` |
| `Rocks/` | `1`–`13` |
| `Shop/1.png` | Winter shop |
| `Tiles/Tile.png` | Snow tile atlas |
| `Trees/` | `1`–`5` |
| `Will and Mill/` | `1.png`–`2.png` |
| `Wooden/` | `1`–`8.png` + `CaveEntrance.png` |

### Wooden (`Wooden/`)
6 wooden structure sprites (`1.png`–`6.png`)

---

## Farm (`Farm/`)
| File | Notes |
|---|---|
| `Crops/crops 16x16.png` | Crop tile atlas |
| `Mill/1.png`, `Mill/2.png` | Windmill sprites |

---

## Beach (`Beach/`)
| Subfolder | Contents |
|---|---|
| `Beach umbrella/` | `1`–`4.PNG` (4 umbrella colors/states) |
| `Chair/` | `1_1`–`1_4.png`, `2_1`–`2_4.png` (2 chair types × 4 states) |
| `Tiles/Tiles.png` | Beach tile atlas |
| `Tree/Tree.png` | Palm tree |

---

## Chests (`Chests/`) — LEGACY
Renamed 2026-05-14. Not referenced in active scenes (see Items/Chests/ for named versions).
| File | Description |
|---|---|
| `chest_wood_closed.png` | Closed wooden treasure chest (formerly 1.png) |
| `chest_wood_open.png` | Open wooden treasure chest (formerly 2.png) |

---

## Plants & Nature

### Plants Growing (`PlantsGrow/`)
| Subfolder | Contents |
|---|---|
| `PurplePunchOne/` | `Purple1`, `Purple2`, `Purple19`–`Purple33` — 17 growth frames (active in world) |

### Objects (`Objects/`)
Standalone props, visually identified:
| File | Description |
|---|---|
| `BigMushroomStump.png` | Brown mushroom cap on wooden stump |
| `RedCapMushroom.png` | Red-capped mushroom (two stems) |
| `herb_bundle_dried.png` | Hanging bundle of dried dark herbs |
| `DryingRacks/` | 16 drying rack / plant display variants (see below) |

### Drying Racks (`Objects/DryingRacks/`)
| File | Description |
|---|---|
| `rack_hanging_herbs_purple.png` | Horizontal hanging bar, purple herbs + bottom shelf |
| `rack_shelf_tall_dark.png` | Tall dark wood shelving with round pots |
| `table_plant_display.png` | Table with multiple potted plants |
| `rack_ladder_hanging_produce.png` | Leaning ladder with red/green hanging produce |
| `cabinet_hutch_plants.png` | Large dark hutch/cabinet with plants on top |
| `rack_aframe_red_produce.png` | A-frame rack loaded with red produce |
| `rack_aframe_empty.png` | Empty dark wood A-frame rack |
| `rack_shelf_tall_light.png` | Tall light-wood shelving with plants |
| `rack_shelf_short_brown.png` | Short brown shelving with plants |
| `rack_hanging_beam_herbs.png` | Horizontal beam with hanging herb bundles |
| `rack_hanging_colorful_peppers.png` | Decorative hanging display, colorful peppers/herbs |
| `table_pots_brown.png` | Table with brown/green pots |
| `rack_shelf_wide_plants.png` | Wide multi-shelf unit with plants |
| `table_small_pots.png` | Small low table with a few pots |
| `table_plant_display_2.png` | Table with green potted plants (variant 2) |
| `cabinet_decorative_hanging.png` | Cabinet with decorative green/gold hanging items |

---

## Items (`Items/`)

### Bags (`Items/Bags/`)
| File | Description |
|---|---|
| `satchel_leather.png` | Brown leather messenger/satchel |
| `satchel_brown.png` | Plain brown satchel |
| `pouch_brown.png` | Small brown drawstring pouch |
| `backpack_hiking.png` | Brown hiking pack with straps |
| `backpack_large.png` | Large brown backpack |
| `backpack_military.png` | Dark military-style backpack |
| `bag_duffel.png` | Brown duffel/tool bag |

### Chests (`Items/Chests/`)
| File | Description |
|---|---|
| `chest_wood_closed.png` | Closed brown wooden chest |
| `chest_wood_open.png` | Open brown wooden chest |
| `chest_metal.png` | Grey metal trunk/chest |

### Watering Cans (`Items/WateringCans/`)
| File | Description |
|---|---|
| `watering_can_clay_brown.png` | Classic clay/terracotta can |
| `watering_can_copper.png` | Copper-toned can |
| `watering_can_green.png` | Bright green painted can |
| `watering_can_metal_grey.png` | Grey galvanised metal can |
| `watering_can_metal_silver.png` | Polished silver metal can |
| `watering_can_metal_2.png` | Second silver metal can variant |

### Gems (`Items/Gems/`)
| File | Description |
|---|---|
| `gem_ruby.png` | Round polished red gem/ruby |
| `gem_cluster_dark_red.png` | Dark red bumpy gem cluster |
| `geode_pink.png` | Dark geode, pink crystal interior |
| `geode_amethyst.png` | Purple amethyst geode slice |
| `crystal_cluster_teal.png` | Teal/cyan crystal cluster |
| `crystal_cluster_rainbow.png` | Rainbow-colored crystal cluster |
| `stone_smooth_white.png` | Smooth white/grey oval stone (or egg) |
| `wreath_holly.png` | Round holly wreath, red berries |

---

## UI (`UI/`)
| File | Notes |
|---|---|
| `WaterGem.png` | HUD water gem icon |
| `WaterMeterBar.png` | HUD water meter bar texture |
| `WaterMeterBar.gif` | Animated version |
| `bucket_empty.png` | HUD bucket empty state |
| `bucket_full.png` | HUD bucket full state |
| `key_e.png` | "Press E" interaction prompt icon (32×32) |

---

## Interior (`interior/`)
| Subfolder / File | Contents |
|---|---|
| `tiles.PNG` | Interior floor/wall tile atlas (321×80) |
| `atlas_32x32.png` | 32×32 interior atlas |
| `stairs.png` | Stair sprite |
| `Bed/` | `BED.PNG`, `BED_2.PNG`, `bed_3.png` |
| `carpet/` | BLUE / PAIGE / PURPLE / red — 3 pieces each |
| `chimney/1.png` | Chimney |
| `decorations/` | Curtains (×4), Books (closed ×3, open ×4), Paintings (×5), Candle |
| `flower and tree pots/` | 7 pot types × 2 variants each (`N.png` + `N_1.png`) |
| `furniture/` | Bookshelf, Desk, Drawer, Window (×3), Chairs (big/small, 3 angles each), Shelves (×2), Tables (×2) |
| `inn/` | `16x16.png` tile atlas, `shelfs.png` |
| `kitchen/` | `16x16.png` tile atlas, appliance/counter sprites (`1_1`–`8_4`, 13 files) |
