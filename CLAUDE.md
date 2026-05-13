# Game — Project Reference

> **Session start:** Read `ADR.md` for full architectural context and history.

## Rules
- **PLAYTEST RULE:** If you make it, you play test it. Always. Run the game via MCP, exercise the feature, take a screenshot to confirm correct behavior before reporting done.

## Where We Are
- **Last completed:** Harvest-to-trade loop asset audit; dried bud sprite added at `GameAssets/Bud/states/dry/rotations/unknown.png`. Prior: NPC home interior + teal house door — `res://World/NPCHome/interior.tscn` (160×128), `NPCHomeDoor` Area2D at (534,125), world.gd wired with 0.5s reconnect delay.
- **Next up:** Wire drying rack collection mechanic: drying timer → "ready" signal → collect → bud enters inventory. Then: playtest NPC home entry/exit feel; refine teal house collision; cave entrance rigging; roof overlay for teal house in Overhead; dedup `shop_apothecary_alt.png`.
- **Bud asset:** `GameAssets/Bud/states/dry/rotations/unknown.png` — small pixelart dried bud, usable as inventory icon and/or world drop. More states (fresh, wet) deferred.
- **Camera lesson:** World node in main.tscn sits at position (195,88). Camera2D limits must be in **global** coords: left=195, top=88, right=835, bottom=584. Always add World offset when setting camera limits.
- **NPC position lesson:** Any NPC script that stores waypoints as world-local coords MUST use `position` (local) not `global_position`. Using `global_position` offsets all targets by the World node's (195,88) global offset, sending NPCs off-map.
- **Open decisions:** `shop_apothecary_alt.png` is a duplicate of `shop_apothecary_main.png` — pending dedup. Cave entrance at (29,409) — rigging TBD. Teal house collision (HouseTealCollider) is a single 85×28 box — needs door gap + side walls to match sprite.

---

## Quick Facts
- **Engine**: Godot 4.6.2-stable, Forward+, D3D12 (Windows)
- **Project path**: `C:/Users/erikc/Dev/Game/game/`
- **Viewport**: 320×180 logical, 1280×720 window
- **Stretch**: `canvas_items` / `keep`
- **Texture filter**: Nearest (value `0`)

## MCP Tool API Notes
- `set_project_setting`: params are `key` (string) and `value` — NOT `setting`
- `get_project_settings`: use `key` param for a single setting lookup
- `execute_editor_script`: param is `code` (GDScript string). Use `_mcp_print()` not `print()` to capture output. No `await` — runs synchronously.
- `add_node`: params are `type` and `name` (NOT `node_type`/`node_name`). Scene must be opened with `open_scene` first.
- `update_property`: does NOT resolve resource paths — use `execute_editor_script` with `load()` to assign resources.
- `save_scene`: saves the currently active editor scene, not necessarily the one you last modified. Always call `open_scene` before `save_scene`.
- `tilemap_fill_rect`: params unreliable — use `execute_editor_script` with a `set_cell()` loop instead.
- Scene write pattern: `PackedScene.new()` → `pack(root)` → `ResourceSaver.save(packed, path)` inside `execute_editor_script`. **Do NOT use this for scenes that instance other scenes** — `pack()` expands instances inline and breaks unique_ids. Write `.tscn` directly via the Write tool using minimal instance format (`instance=ExtResource(...)`) instead.
- All Godot MCP tools use `additionalProperties: true` schema — always load via ToolSearch before first call in a session
- Bridge server: `C:/Users/erikc/Dev/Game/mcp-bridge/index.js` — Godot editor must be open with MCP Pro plugin active
- `y_sort_offset` does NOT exist as a runtime GDScript property in Godot 4.6.2 — it is only a `.tscn` serialization field. Setting it via `execute_editor_script` (even via `set()`) will error. Sorting is purely by `position.y`; use `position.y` placement to control sort order.

## Asset Layout
- Source assets: `C:/Users/erikc/Dev/Game/GameAssets/` (~800 PNGs)
- In-project assets: `res://GameAssets/` (same tree, copied into `game/`)
- **Village buildings**: `res://GameAssets/Buildings/` — snake_case named, imported (ADR-031)
  - `houses/` — 8 residential: `house_twostory_a/b/c.png`, `house_cottage_stone.png`, `house_stone_teal.png`, `house_stone_brown.png`, `house_twostory_teal.png`, `house_farm_cozy.png`
  - `shops/` — 4 commercial: `shop_bakery_main.png`, `shop_general_small.png`, `shop_apothecary_main.png`, `shop_apothecary_alt.png` *(alt = duplicate, pending dedup)*
  - `special/` — 1 landmark: `building_tavern_main.png`
- **Erik player sprites**: `res://GameAssets/ErikPlayer/` — 64×64 px
  - Idle: `idle_south/north/east.png` (1 frame each)
  - Walk: `walk_south/north/east/west_0-3.png` (4 frames each, PixelLab generated)
  - SpriteFrames: `erik_sprites.tres`
  - Scale: `0.5` on AnimatedSprite2D node
- Ground tiles: `res://GameAssets/Tiles/` — 16×16 px

## Player Scene Architecture (ADR-002, ADR-003, ADR-013)
- Root: `CharacterBody2D`, `motion_mode = MOTION_MODE_FLOATING`
- Child: `CollisionShape2D` (CapsuleShape2D, ~8×12px)
- Child: `AnimatedSprite2D` scale=0.5 — script: `player_animation.gd`
- Root script: `player.gd` — exposes `velocity`, `facing`, `is_moving`, `facing_left`
- Animation names: `idle_down`, `idle_up`, `idle_side`, `walk_down`, `walk_up`, `walk_side`
- Left-facing: `flip_h = true` on AnimatedSprite2D (no separate left animation)
- `var dir: String = player.facing` — explicit type annotation required (Godot 4 inference limitation)

## TileMap (ADR-004)
- Use `TileMapLayer` node (not deprecated `TileMap`)
- `TileSet` as standalone `.tres` resource
- One `TileMapLayer` node per z-layer

## Tile.png Atlas Layout (15×12, 16×16 tiles)
- **(9,1)** — solid seamless interior grass (perfectly uniform edges, no marks)
- **(6,0)** top-left corner, **(8,0)** top edge, **(10,0)** top-right corner
- **(6,1)** left edge, **(10,1)** right edge
- **(6,2)-(10,2)** grass-to-dirt cliff transition (bottom edge)
- **(6,3)-(10,3)** pure dirt tiles
- Cols 0–4 rows 0–5: decorative objects (rocks, mushrooms, crops)
- Cols 0–6 rows 4–7: water tiles
- **Do NOT mix bordered tiles for interior ground** — corner marks create T-mark artifacts at seams

## Depth Sorting Pattern (ADR-015)
- `World` node has `y_sort_enabled = true` — all world objects and Player are siblings
- Player lives in `world.tscn`, NOT `main.tscn` — `main.gd` accesses it via `$World/Player`
- Buildings need `y_sort_offset` set so sort_y = bottom of visible wall face (the "walkable in front" line)
  - `PlayerHome` (Bakery): position y=80, `y_sort_offset=35` → sort y=115 (door base)
- Rule: `player.y < sort_y` → player behind building; `player.y > sort_y` → player in front
- `Overhead` Node2D in `main.tscn` at `z_index=2` holds roof overlay sprites — renders above everything
- Adding new buildings: add to `world.tscn`, set `y_sort_offset`, add roof sprite to `Overhead` in `main.tscn`

## Scene Transition Notes (ADR-010, ADR-014)
- `get_tree().change_scene_to_file(path)` works from any node
- Cross-scene state: `Engine.set_meta("key", value)` / `Engine.get_meta("key")` / `Engine.remove_meta("key")`
- **Static autoloads** (declared in project.godot) are globally visible after project reload — fine to use
- **DO NOT** use autoloads added at runtime — they don't become globally visible to scripts until editor restart
- Interior scene is self-contained with its own Player instance; camera limits overridden in `_ready()`
- `TransitionManager` autoload at `res://autoload/TransitionManager.gd` — persistent fade overlay (CanvasLayer layer=100)
  - Call `await TransitionManager.fade_to_black(0.4)` before `change_scene_to_file`
  - Call `TransitionManager.fade_from_black(0.4)` (no await) at top of destination scene's `_ready()`
  - Disconnect Area2D signal before first `await` to prevent double-trigger
  - `player.set_physics_process(false)` to freeze player during the sequence
- Interior: `res://World/PlayerHome/interior.tscn` — 160×128 room, exit at south-center (80, 124)
  - Player spawns at (80, 108) facing "up" (north) — set via `$Player.facing = "up"` in interior.gd `_ready()`
- Exterior door: `DoorEntrance` Area2D at world (112, 128) — player enters → fade → interior (no door animation; ADR-033)
- `Engine.set_meta("spawn_position", Vector2(112, 150))` set on interior exit → consumed in `main.gd._ready()`

## Interior Assets Available
- `res://GameAssets/interior/` — bed, carpet, furniture, kitchen, decorations, stairs
- `res://GameAssets/interior/tiles.PNG` (321×80) — floor/wall tile options for future interior tileset
- `res://GameAssets/Village/Door Animation/Door1-4.png` (29×19 each) — door open animation frames

## Ground Tileset (ADR-012, session 5)
- Sources: 0=Tile.png, 1=grass_stone_dirt.png, 2=fivegrass.png (5 tiles), 3=mabeyfive.png (5 tiles)
- All 960 ground cells use sources 2/3 with random variant (0–4) and flip alt (0–3)
- Flip alternatives added via `TileSetAtlasSource.create_alternative_tile()` + `TileData.flip_h/flip_v`
- Asset files: `res://GameAssets/Tiles/fivegrass.png` and `res://GameAssets/Tiles/mabeyfive.png`
- `get_game_screenshot` supports `save_path` param — use it to avoid base64 token overflow

## MCP / Editor Gotchas (session 5)
- **Direct .tres edits are overwritten** — Godot editor rewrites tileset on reload. Always use `execute_editor_script` for tileset changes, never the Write/Edit tools.
- **Textures must be imported before `load()`** — copy PNG into project, call `EditorInterface.get_resource_filesystem().scan()`, verify `.import` file exists, then run script.
- `TileSet.add_source(src, desired_id)` — second param forces the source ID (avoids getting unexpected ID).
- `TileSet.remove_source(id)` before re-adding ensures clean state when replacing a broken source.

## MCP / Editor Gotchas (session 4)
- Godot auto-corrects invented UIDs in `.tscn` to match `.gd.uid` files — expect UID rewrites on editor save
- `enabled = false` / `visible = false` can be accidentally set on nodes via editor UI during MCP sessions — verify after complex execute_editor_script runs
- `class_name Foo` conflicts with any autoload also named `Foo` — never reuse autoload names for class_name
- `Polygon2D` with `z_index = -1` works correctly as a colored background in Node2D scenes

## Day/Night Cycle (ADR-026, ADR-029)
- Script: `res://autoload/DayNightCycle.gd` — added as `DayNight` Node in `main.tscn` (NOT a static autoload, just in main)
- Joins group `"day_night_cycle"` in `_ready()` — shadow nodes find it via `get_first_node_in_group()`
- `cycle_duration = 120.0s`, `start_time = 0.35` (morning start)
- **Night speed 2×**: `_t < 0.28 or _t > 0.80` runs at 2× speed → night ~29s, day ~62s, total ~91s
- Drives `CanvasModulate` (sibling in main.tscn) and `Sun` DirectionalLight2D (sibling in main.tscn)
- **Sun `range_item_cull_mask = 3`** — must include layer 2 to illuminate house/door (light_mask=2 for night exclusion)
- Exposes: `shadow_dir: Vector2`, `shadow_alpha: float`, `shadow_length_factor: float`
- Night ambient floor: Color(0.38, 0.42, 0.62) — readable blue-tinted, not near-black

## House Night Lighting (ADR-030, ADR-032)
- 4 `PointLight2D` nodes in `world.tscn` (all `range_item_cull_mask=1`, warm amber Color(1,0.76,0.30)) — repositioned for Bakery:
  - `HouseGlowBack` (112,28) energy=0.32 scale=2.8 — wide halo above bakery dome
  - `HouseGlowLeft` (60,82) energy=0.17 scale=2.0 — left yard spill
  - `HouseGlowRight` (164,82) energy=0.17 scale=2.0 — right yard spill
  - `HouseGlowFront` (112,120) energy=0.09 scale=1.6 — faint door/path ground spill
- **`PlayerHome.light_mask = 2`** — excluded from night lights (cull_mask=1 misses layer 2)
- Any future `PointLight2D` that should NOT hit the house: leave `range_item_cull_mask=1` (default)
- Any future directional/point light that SHOULD hit the house: set `range_item_cull_mask=3`

## Dynamic Shadows (ADR-027)
- Script: `res://World/object_shadow.gd` — attach as child Node2D to any world object
- Draws a flat horizontal oval (two-pass: halo + core); **centre shifts with sun, ellipse does NOT rotate**
- **Critical z-order fix**: `z_as_relative = false`, `z_index = 0` — grandchild z=-1 relative = global z=-1 = invisible below terrain
- `_dnc` looked up lazily in `_process()` NOT `_ready()` — world subtree initializes before DayNight registers its group
- Exports: `ground_offset: Vector2`, `shadow_size: Vector2(w, h)`, `cast_length: float`
- All 5 objects in world.tscn have Shadow Node2D children (PlayerHome, Well, Plant, DryingRack, Rock)

## Drying Rack (ADR-025)
- Script: `res://Interactables/drying_rack.gd` — Sprite2D with 4-state machine: `EMPTY → FILLING → DRYING → READY → EMPTY`
- `add_plant()` blocked in DRYING/READY states; TEXTURES array: `[empty, 3plants, 2plants, 1plant]` (first plant shows fullest display)
- After 3rd plant: enters DRYING (5s timer), then READY (1.5s golden pulse via `modulate`), then `_award_and_reset()`
- `_award_and_reset()` picks a random texture from `PRODUCTS` array (8 bud types) via `randi() % PRODUCTS.size()` and calls `Inventory.add_item(tex)`
- `Inventory.add_item(tex)` tries hotbar (slots 1–11) first, then inventory grid (slots 0–35); stacks same texture up to 16, then opens new slot; returns false if all full (silent loss)
- Connected in `world.gd`: `$Plant.plant_harvested.connect($DryingRack.add_plant)`
- Assets: racks in `res://GameAssets/Objects/DryingRacks/`; 8 product textures in `res://GameAssets/Bud/` + `res://GameAssets/Objects/herb_bundle_dried.png`
- Collision: `DryingRackCollider` StaticBody2D → `CollisionShape2D` (RectangleShape2D 44×10) at offset (0, 26)
- Shadow: `ground_offset=(0,26)`, `shadow_size=(28,5)`, `cast_length=18.0`; `y_sort_offset=30`
- Plant (plant.gd) resets to frame 0 / stage 0 after emitting `plant_harvested`; no toast popups

## Stage 1 Milestones
| # | Milestone | Status |
|---|-----------|--------|
| M0 | Project settings + asset copy | ✅ Done |
| M1 | SpriteFrames resource | ✅ Done |
| M2 | Player scene (no script) | ✅ Done |
| M3 | player.gd movement script | ✅ Done |
| M4 | player_animation.gd | ✅ Done |
| M5 | World scene + TileMapLayer | ✅ Done |
| M6 | Main scene + camera limits | ✅ Done |
| Post | Player home door + interior | ✅ Done |
| Post | Day/night cycle + dynamic shadows | ✅ Done |
| Post | Drying rack 3-state mechanic | ✅ Done |
