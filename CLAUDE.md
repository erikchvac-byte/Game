# Game — Project Reference

> **Session start:** Read `ADR.md` for full architectural context and history. Then read the **Notes** section at the bottom of this file.

## Rules
- **PLAYTEST RULE:** If you make it, you play test it. Always. Run the game via MCP, exercise the feature, take a screenshot to confirm correct behavior before reporting done.
- **TASK TRACKING RULE:** For any task with 3+ distinct steps, use `TaskCreate` to create subtasks before starting, mark each `in_progress` when begun, and `completed` when done. Check `TaskList` at the start of each session to resume any open tasks.
- **ASSET REPLACEMENT RULE:** Never substitute one PNG for a different PNG without explicit user approval first. If an asset is missing and no exact match exists, stop and ask — do not pick a "close enough" alternative. Choosing replacement art is the user's job.
- **SESSION-END RULE:** When the user says any of: "end session", "update docs", "session end", "wrap up", "close session", or similar finalization language — automatically perform all of the following before stopping: (1) update `ADR.md` with any architectural decisions made this session + append a change log row; (2) update CLAUDE.md "Where We Are" to reflect current state; (3) replace the Notes section with a fresh session-end entry covering: game state, open issues, pending tasks, and available-but-unwired assets; (4) commit all doc changes. Do not create an ADR for minor fixes unless an actual architectural decision was made.

## Where We Are
- **Last completed:** Obsidian vault connected (2026-05-20). Vault at `C:\Users\erikc\Desktop\DesktopFolder\MeNew\GAME` is readable via native Glob/Grep/Read tools — no MCP config needed. Current vault file: `TREE SPRITE SIZING.md` (tree sizing standards table, see Quick Facts below).
- **Previous (2026-05-20):** world.gd broken preload fix + tileset zombie source cleanup (ADR-072).
  - **world.gd:64 fixed:** `preload("res://GameAssets/Bud/dry_bud.png")` → `res://assets/props/bud/dry_bud.png`. Was a missed path from ADR-071 cleanup that caused script parse failure (game unrunnable). ✅
  - **Tileset zombie sources removed (ADR-072):** Sources 2, 3, 4, 7 in `GrassBrick_OVERLAYS__tileset.tres` had null textures and 0 cells in use — orphaned leftovers with no texture reference. Removed via editor script. Tileset spam (~700 C++ DEBUGGER errors per run) eliminated. Active sources now: 0=Tile.png, 1=grass_stone_dirt.png, 5=town-grass-tile.png, 6=atlas_32x32.png, 8=Solid.png. ✅
  - **Playtested:** Output log clean (4 lines only), player visible, bud item in hotbar. ✅
- **Previous (2026-05-20):** Project structure cleanup + drying_rack path fixes.
  - **Structure cleanup (ADR-071):** Deleted stray root `project.godot`, `game/GameAssets/` (985 files, zero refs), orphan `22222x32.tres`. Moved 7 root art dirs into `GameAssets/`. Archived orphaned root `addons/`. Project now has clean two-tier asset structure. ✅
  - **drying_rack.gd paths fixed:** All 4 broken `res://GameAssets/` preloads in `PRODUCTS` replaced with `res://assets/props/bud/`. Three PNGs (hang_dry, weed_plant, dry_bud) recovered from source art. `herb_bundle_dried.png` has no source — **user to supply replacement art**. ✅
  - **Solid.png added to tileset:** Source 8 in `GrassBrick_OVERLAYS__tileset.tres` (16×16, 256 tiles). When painting Overlay tiles, scroll UP past Solid.png in source picker to reach town-grass-tile (source 5). ✅
  - **Overlay + town-grass-tile (ADR-069/070):** `Overlay` TileMapLayer in `world.tscn`. All 256 town-grass-tile tiles have transparent backgrounds. Paint on `Overlay` layer — tiles render above Ground without replacing it. ✅
  - **Species trees (ADR-068):** `choppable_tree_pine/maple/fir.tscn` with chop+fall animations. Playtested ✅.
- **MCP testing lesson:** `simulate_key` via MCP godot-mcp-pro does NOT trigger `world.gd._input()` — that handler filters `event is InputEventKey` and MCP sends a different event type. Use `execute_game_script` to call handlers directly (e.g. `world._handle_tool_toggle("axe")`, `tree.interact(player)`). `await` crashes in `execute_game_script` — split async operations into two calls.
- **Space/interact:** Space (keycode 32) = `interact` action. T = `npc_trade` action. C = `equip_toggle` action. All three are now named InputMap actions in project.godot — no hardcoded keycodes in world.gd.
- **Space bug fix:** Pressing Space near a tree without the axe equipped now shows toast `"Equip axe first (C)"` instead of silently failing. Press C to equip, then Space to chop.
- **Interactable system:** `world.gd` uses `_interactables: Array[Node]` (not a single ref). `_get_nearest_interactable()` returns the closest by distance_squared. Two overlapping areas resolve to the nearest — no more last-enter-wins race condition.
- **Inventory:** `InventoryManager.ItemEntry` typed inner class (key: String, tex: Texture2D, count: int). Stacking by key. `_grant_starting_items()` guarded by `Engine.has_meta("starting_items_granted")` — no duplicates on re-entry.
- **Tool pattern (generalized):** `player.equipped_tool: String` (empty = nothing equipped). C → `world._handle_tool_toggle("axe")`. `EQUIPPABLE_TOOLS` dict in world.gd maps `item_key → InputMap_action`. Adding a new equippable tool = 1 line in the dict + 1 InputMap action. HUD gold highlight via `hud.set_equipped_slot(slot_idx)`. Slot search limited to `range(1, _HOTBAR_SLOTS)` (hotbar only).
- **Hotbar indicators:** `hud._slot_style(selected, equipped)` — gold border = selected slot (also active item). `hud.set_equipped_slot(index)` is the push API; called on every slot selection in `_on_hud_slot_selected` (not just tool slots). `_on_slot_changed` applies 50% inset for `key == "wood"` (rock3.png placeholder is oversized).
- **NPC right-click trade:** Left-click within `NPC_TRADE_RADIUS` (36px) of visible NPC targets the NPC for nav. `_update_mouse_navigation` tracks NPC position each frame and fires `_handle_npc_trade()` on arrival. Priority in `_on_right_click`: NPC > tree > terrain. `is_interactable()` guard on both T-key and nav arrival prevents double-trigger within the one-frame `_npc_trade_active` lag window.
- **Trade gem icon:** `res://assets/props/items/gem_ruby.png` — clean round red gem, readable at any hotbar size. Key in InventoryManager = `"gem"`.
- **player.facing:** Now `enum Facing { DOWN, UP, SIDE }`. Use `player.facing_name()` to get animation string. Interior scripts assign `($Player as CharacterBody2D).Facing.UP`.
- **Pending editor restart:** InventoryManager accessed via `get_node_or_null("/root/InventoryManager")` (added post-startup). After Godot restart, replace with bare `InventoryManager` name.
- **Tree scene pattern:** `res://World/ChoppableTree/choppable_tree.tscn` — self-registers to group `"choppable_trees"` in `_ready()`. Exported vars: `tree_texture`, `stump_texture`, `tree_visual_scale`, `stump_offset`, `stump_visual_scale`, `stump_flip_h`, `chops_required`. New trees = duplicate scene + drop in world — zero world.gd changes needed. Signals: `interactable_entered/exited` (SPC prompt), `wood_chopped` (grants wood via world.gd).
- **Wood placeholder:** `res://assets/props/items/rock3.png` used as wood icon. Key = `"wood"`. Stacks by key in InventoryManager. Granted at start (once) + on each chop.
- **Drying rack:** `_award_and_reset()` calls `/root/InventoryManager` (fixed from old `/root/Inventory`). Bud rewards land in inventory.
- **Next up:** Teal house collision refinement (door gap + side walls); cave entrance rigging; roof overlay for teal house in Overhead; dedup `shop_apothecary_alt.png`. Town/ and Village/ folders (~250 files each) still use numbered/mixed-case names — next naming pass. Paint town-grass overlay tiles on the new `Overlay` layer to decorate the world.
- **PowerShell encoding lesson:** PowerShell 5.1 writes UTF-8 with BOM by default. Godot cannot parse .tscn/.tres/.gd files that start with a BOM — use `[System.IO.File]::WriteAllBytes()` or `WriteAllText(path, content, [Text.Encoding]::UTF8)` (no-BOM). Never use `Out-File` or `Set-Content` for Godot resource files.
- **Godot autosave lesson:** Close scene in editor before editing .tscn on disk. Pattern: `open_scene("other.tscn")` → edit file → `open_scene("world.tscn")`. UID must be restored in .tscn ext_resource entries for renamed assets (Godot strips uid field for broken paths).
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
- **Obsidian vault**: `C:\Users\erikc\Desktop\DesktopFolder\MeNew\GAME` — readable via Glob/Grep/Read (no MCP needed)

## Obsidian Vault — Tree Sprite Sizing Standards
| Type | Size | Grid equivalent |
|---|---|---|
| Small / shrub | 32×48 px | 2×3 tiles |
| Medium tree | 48×64 px | 3×4 tiles |
| Large tree | 64×96 px | 4×6 tiles |
| Very large / landmark | 80×112 px | 5×7 tiles |

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
- Source assets: `C:/Users/erikc/Dev/Game/GameAssets/` (~800 PNGs + newly organized subdirs: bushes/, crafting_tools/, trees/, drying_rack_alt/, weed_plants/, objects_misc/)
- In-project assets (VERIFIED_USED): `res://assets/` + `res://resources/` (reorganized 2026-05-17, ADR-062)
- In-project legacy DELETED: `res://GameAssets/` — removed 2026-05-19 (985 files, zero active refs, ADR-071)
- **Active building assets**: `res://assets/structures/`
  - `shops/` — bakery: `shop_bakery_main.png`, `shop_bakery_open.png`
  - `houses/` — teal house animation: `house_grey_teal_animation.png`
  - `cave_entrance_arch_stone.png`
  - `stump_door_dwelling.png` — ancient stump with carved door (prop/structure)
- **Tree + stump assets** (NEW — 2026-05-19):
  - Static: `res://assets/nature/trees/tree_pine_3.png`, `tree_maple.png`, `tree_fir.png` (96×96 each)
  - Animations: `trees/pine_chop/`, `pine_fall/`, `maple_chop/`, `maple_fall/`, `maple_hit_fall/`, `fir_chop/`, `fir_fall/` — 9 frames each
  - Stump static: `res://assets/nature/stumps/stump_round.png` (96×96)
  - Stump dissolve: `res://assets/nature/stumps/stump_round_dissolve/` — 16 frames
  - All auto-imported; not yet wired to ChoppableTree scenes
- **Erik player sprites**: `res://assets/characters/erik/` — 64×64 px
  - Idle: `idle_south/north/east.png` (1 frame each); bucket variants same pattern
  - Walk: `walk_south/north/east_{0-5}.png` (6 frames each)
  - Chop/trade animations: `chop_{north,side,south}/`, `trade_{north,side,south}/`
  - SpriteFrames: `res://resources/characters/erik_sprites.tres`
  - Scale: `0.5` on AnimatedSprite2D node
- Ground tiles: `res://assets/tiles/` — 16×16 px

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

## Ground Tileset (ADR-012, ADR-072)
- Active sources: 0=Tile.png (203 cells), 1=grass_stone_dirt.png (registered, 0 cells), 5=town-grass-tile.png (41 ground + 917 overlay cells), 6=atlas_32x32.png (registered, 0 cells), 8=Solid.png (1030 cells)
- Tileset: `res://resources/tilesets/GrassBrick_OVERLAYS__tileset.tres`
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
- Assets: racks in `res://assets/props/drying_rack/`; 8 product textures in `res://assets/props/bud/` + `res://assets/nature/plants/herbs/herb_plant_type_a.png` (placeholder — user to supply `herb_bundle_dried.png` replacement)
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

## Notes
> Check this section at the start of every session. Add short-lived context here (things in progress, temp decisions, reminders). Remove entries once resolved.

### Session end — 2026-05-20 (Obsidian vault connection)
- **Game state:** Runnable and clean (world.gd preload fixed, tileset clean — from prior session ADR-072). No game changes this session.
- **Obsidian vault connected.** `C:\Users\erikc\Desktop\DesktopFolder\MeNew\GAME` readable via Glob/Grep/Read without any MCP config change. Vault has one file: `TREE SPRITE SIZING.md` — sizing standards table now mirrored in CLAUDE.md Quick Facts.
- **Vault access method:** Filesystem MCP is restricted to project dir only. Use native Glob/Grep/Read tools for vault access — these have no path restrictions.
- **Tileset is clean.** Active sources: 0=Tile.png, 1=grass_stone_dirt.png, 5=town-grass-tile.png, 6=atlas_32x32.png, 8=Solid.png. No zombie sources.
- **Overlay TileMapLayer:** `Overlay` node in `world.tscn`. Scroll UP in source picker — Solid.png at bottom, town-grass-tile is source 5.
- **Cave tiles pending.** `GameAssets/Caves/Tiles/Tiles.png` (208×192) has irregular layout — needs clarification before adding as a tileset source.
- **tile_bit_tools UID duplicates.** Nested copy at `tile_bit_tools/tile_bit_tools/` causing ~34 editor warnings. Remove to clean up (not yet done).
- **Pending editor restart note:** `_inv_mgr` fetched via `get_node_or_null("/root/InventoryManager")` in world.gd. Replace with bare `InventoryManager` after confirming autoload is in project.godot.
- **Wood icon is a placeholder.** `res://assets/props/items/rock3.png` used for wood key. Replace with real wood sprite.
- **herb_bundle_dried.png has no source.** `herb_plant_type_a.png` is placeholder in drying rack PRODUCTS. User to supply replacement art.
- **Next priorities:** Teal house collision refinement (door gap + side walls); cave entrance rigging; NPC trade-receive animation; stump dissolve animation.
- **Available but unwired:** player_alt (59×49, 3-dir), purple_jack + grey_hoodie/rotations (8-dir NPCs), cannabis/herb plants (13+4 variants), garden dirt patches (5 static + 9-frame pulse), tileset_32x32 (66 tiles).

### Permissions Allowlist (as of 2026-05-15)
All Godot MCP and filesystem MCP tools are pre-approved in `.claude/settings.json`. No prompts expected for any of these:

**Godot MCP (all approved):** execute_game_script, execute_editor_script, get_game_screenshot, get_editor_screenshot, play_scene, stop_scene, open_scene, save_scene, create_scene, delete_scene, read_script, create_script, edit_script, validate_script, attach_script, get_scene_tree, get_game_scene_tree, get_scene_file_content, get_node_properties, get_game_node_properties, set_game_node_property, get_editor_errors, get_output_log, clear_output, simulate_key, simulate_action, simulate_sequence, simulate_mouse_click, simulate_mouse_move, add_node, add_scene_instance, delete_node, rename_node, move_node, duplicate_node, update_property, batch_set_property, batch_get_properties, connect_signal, disconnect_signal, reload_project, reload_plugin, add_autoload, remove_autoload, get_autoload, set_input_action, tilemap_set_cell, tilemap_get_info, tilemap_get_used_cells, tilemap_clear, tilemap_get_cell, project_path_to_uid, uid_to_project_path, set_editor_camera, get_editor_camera, find_nodes_by_type, find_nodes_in_group, find_node_references, find_nodes_by_script, find_signal_connections, find_nearby_nodes, find_ui_elements, find_unused_resources, search_files, search_in_files, list_scripts, get_signals, get_filesystem_tree, get_project_info, get_project_settings, get_project_statistics, set_project_setting, get_scene_exports, get_scene_dependencies, get_input_actions, get_node_groups, get_open_scripts, get_physics_layers, collision_layer_info, collision_mask_info, set_anchor_preset, setup_control, setup_collision, setup_physics_body, setup_navigation_agent, setup_navigation_region, setup_environment, setup_lighting, create_resource, edit_resource, read_resource, add_resource, create_theme, set_theme_color, set_theme_constant, set_theme_font_size, set_theme_stylebox, get_theme_info, create_animation, list_animations, remove_animation, get_animation_info, add_animation_track, set_animation_keyframe, create_animation_tree, get_animation_tree_structure, set_blend_tree_node, set_tree_parameter, add_state_machine_state, add_state_machine_transition, remove_state_machine_state, remove_state_machine_transition, create_particles, apply_particle_preset, get_particle_info, set_particle_color_gradient, set_particle_material, add_audio_bus, add_audio_bus_effect, add_audio_player, set_audio_bus, get_audio_bus_layout, get_audio_info, create_shader, edit_shader, read_shader, assign_shader_material, get_shader_params, set_shader_param, add_gridmap, add_mesh_instance, add_raycast, bake_navigation_mesh, set_navigation_layers, get_navigation_info, set_node_groups, wait_for_node, watch_signals, monitor_properties, capture_frames, start_recording, stop_recording, replay_recording, run_test_scenario, run_stress_test, assert_node_state, assert_screen_text, compare_screenshots, analyze_scene_complexity, analyze_signal_flow, detect_circular_dependencies, get_performance_monitors, get_editor_performance, get_resource_preview, get_collision_info, move_to, navigate_to, cross_scene_set_property, tilemap_fill_rect, set_auto_dismiss, set_physics_layers, set_particle_material, get_android_preset_info, list_android_devices, list_export_presets, get_export_info, deploy_to_android, export_project, click_button_by_text

**Filesystem MCP (all approved):** read_file, read_text_file, read_multiple_files, read_media_file, edit_file, write_file, search_files, create_directory, move_file, directory_tree, list_directory, list_directory_with_sizes, list_allowed_directories, get_file_info

**PixelLab MCP (all approved):** get_balance, generate_image_pixflux, generate_image_bitforge, animate_with_text, animate_with_skeleton, estimate_skeleton, inpaint, rotate
