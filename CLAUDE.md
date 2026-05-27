# Game — Project Reference

> **Session start:** Read `ADR.md` for full architectural context and history. Then read the **Roadmap** and **Notes** sections at the bottom of this file.

## Rules
- **ASSET INSPECTION RULE:** When instructed to check, review, or analyze PNG files or other discrete asset files, EVERY file in the specified set must be individually inspected before responding or taking action. Do not sample, skip, or assume similarity between assets. Confirm each file has been individually opened and viewed before proceeding. Never claim to have reviewed files that were not explicitly opened.
- **PLAYTEST RULE:** If you make it, you play test it. Always. Run the game via MCP, exercise the feature, take a screenshot to confirm correct behavior before reporting done.
- **TASK TRACKING RULE:** For any task with 3+ distinct steps, use `TaskCreate` to create subtasks before starting, mark each `in_progress` when begun, and `completed` when done. Check `TaskList` at the start of each session to resume any open tasks.
- **ASSET REPLACEMENT RULE:** Never substitute one PNG for a different PNG without explicit user approval first. If an asset is missing and no exact match exists, stop and ask — do not pick a "close enough" alternative. Choosing replacement art is the user's job.
- **SESSION-END PRE-FLIGHT RULE:** Before executing SESSION-END, run these checks. If ANY fail, stop immediately, print `⚠ SESSION-END BLOCKED`, list every issue found, and wait for the user to either resolve the issue or type `override session-end` to bypass. Do NOT proceed with doc updates or commit until the user responds.
  1. **`script = null` override check** — grep all `.tscn` files for lines matching `^script = null`. Each hit means a Godot editor operation silently nulled a scene script, breaking all logic on that node (root cause of the 2026-05-24 hotbar/input regression). Alert: "script = null found in [file:line] — this overrides [scene]'s script at runtime. Fix: remove the `script = null` line."
  2. **Editor error check** — call `get_editor_errors` via MCP. If any errors are returned that are not pre-existing/known warnings (e.g. tile_bit_tools UID duplicates), list them and block.
  3. **Game runability check** — call `play_scene` + `get_output_log` (brief run). If the output log contains `Parse Error`, `Script failed to load`, or `SCRIPT ERROR`, block with the log snippet. Stop the scene after checking.
  4. **No block if:** all checks pass, or the only errors are the pre-approved known warnings (`tile_bit_tools` nested UID duplicates, `hud.gd INT_AS_ENUM_WITHOUT_CAST`). Those are not blocking.
- **SESSION-END RULE:** When the user says any of: "end session", "update docs", "session end", "wrap up", "close session", or similar finalization language — **first run SESSION-END PRE-FLIGHT**, then automatically perform all of the following: (1) update `ADR.md` with any architectural decisions made this session + append a change log row; (2) update CLAUDE.md "Where We Are" to reflect current state; (3) replace the Notes section with a fresh session-end entry covering: game state, open issues, pending tasks, and available-but-unwired assets; (4) **update the Roadmap section** — remove completed items, remove dropped items, add new priorities discovered this session, keep it accurate and current; (5) commit all doc changes. Do not create an ADR for minor fixes unless an actual architectural decision was made.
- **TSCN EDIT RULE:** Never rewrite any `.tscn` file in full using the Write tool. Always use targeted Edit tool calls for specific node changes. Full rewrites silently drop inline node properties — this was the root cause of the recurring y_sort_offset loss (ADR-073→090).
- **TREE Y-SORT RULE (ADR-091 — canonical, permanent):** Tree node origin = trunk base (ground contact). TreeSprite child has `position = Vector2(0, -22)` (sprite draws upward). `y_sort_offset` stays at default 0 — never written to any tree .tscn, never stripped. Depth sort transition is at node Y (trunk base). To add a new tree species: set TreeSprite.position.y = -(half_tree_height_px), leave everything else at defaults. To move a tree in world.tscn: set instance position directly — no y_sort_offset override needed. TrunkCollider at origin (y=0). StumpCollider at origin. stump_y_offset export = 0.0 (stump appears at trunk base by default).
- **CONFLICT CHECK RULE:** Before implementing any major decision or change, check for conflicts with existing architecture, active systems, asset dependencies, ADR decisions, or anything else that could break or contradict what's already in place. If a potential problem is found, stop and discuss it with the user — do not proceed and self-fix silently.

## Where We Are
- **Current state (2026-05-27):** Runnable, pre-flight ✅, output log clean (4 lines). Fay Grove exchange working — drop item, step away, return to collect reward. ShT stays above brick wall (MAP_MAX_Y=445). Door entry works. Nav mesh rebaked after tree repositioning — player routes around trees correctly. NPC GreyHoodie patrol uses NavigationAgent2D (ADR-100). Player click-nav wired to nav mesh (ADR-098/099). NavRegion baked in world.tscn (ADR-097). All systems working. **BMad v6.8.0 installed** (`_bmad/`). **Project docs generated** (`docs/index.md` — exhaustive scan of all 25 authored scripts). **Furniture wired into interior.tscn** — grandfather clock (NW), bed (NE), plant shelf (W-mid); y_sort_enabled on Interior root; collision confirmed. **HouseTwostoryTeal collision fixed** (ADR-101) — MainBody + FrontLeft + FrontRight shapes with door gap; y_sort_offset=43. **Choppable rock system live** (ADR-102) — TowerRock1 at (450,290), SquareRock1 at (75,420); axe required; drops stone_pile. **Grove expanded** (ADR-103) — hang_dry→gem_ruby, lumber→ingot_copper_01; door_open animation + amber pulse during processing.
- **Key gotchas:** `simulate_key` via MCP does NOT trigger `_input()` — use `execute_game_script` to call handlers directly. `await` crashes in `execute_game_script` — split async ops into two calls. NPC waypoints in World-local coords → convert to global via `get_parent().to_global()`.
- **Input actions:** Space=`interact`, T=`npc_trade`, C=`equip_toggle` — named InputMap actions, no hardcoded keycodes.
- **Interactable system:** `world.gd` uses `_interactables: Array[Node]`; `_get_nearest_interactable()` by distance_squared.
- **Inventory:** `InventoryManager.ItemEntry` (key, tex, count). Stacking by key. `_inv_mgr` uses `get_node_or_null("/root/InventoryManager")` — replace with bare `InventoryManager` after editor restart.
- **Tool pattern:** `player.equipped_tool: String`. `EQUIPPABLE_TOOLS` dict in world.gd maps `item_key → InputMap_action`. Adding a tool = 1 dict entry + 1 InputMap action.
- **Tree scene pattern:** `choppable_tree.tscn` self-registers to `"choppable_trees"` group. New tree = duplicate scene + drop in world, no world.gd changes needed.
- **Rock scene pattern:** `choppable_rock.gd` shared script, self-registers to `"choppable_rocks"` group. 3 rock type scenes in `scenes/interactables/rocks/`. SpriteFrames in `resources/rocks/`. Requires axe. Drops stone_pile on break. New rock instance = drop scene into world, no world.gd changes needed.
- **NPC right-click trade:** Priority `_on_right_click`: NPC > tree > terrain. `NPC_TRADE_RADIUS=36px`. `is_interactable()` guard prevents double-trigger.
- **player.facing:** `enum Facing { DOWN, UP, SIDE }`. Use `player.facing_name()` for animation string.
- **PowerShell encoding:** Never use `Out-File`/`Set-Content` for Godot files — PS 5.1 adds BOM. Use `[System.IO.File]::WriteAllText(path, content, [Text.Encoding]::UTF8)`.
- **Godot autosave:** Close scene before editing `.tscn` on disk: `open_scene("other.tscn")` → edit → `open_scene("world.tscn")`.
- **Camera:** World node in main.tscn at (195,88). Camera2D limits in global coords: left=195, top=88, right=835, bottom=584.

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
- **Erik player sprites**: `res://assets/characters/erik/` — **56×56 px** (ADR-013 claimed 64×64 — incorrect)
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

## Ground Tileset (ADR-012, ADR-072)
- Active sources: 0=Tile.png (203 cells), 1=grass_stone_dirt.png (registered, 0 cells), 5=town-grass-tile.png (41 ground + 917 overlay cells), 6=atlas_32x32.png (registered, 0 cells), 8=Solid.png (1030 cells)
- Tileset: `res://resources/tilesets/GrassBrick_OVERLAYS__tileset.tres`
- `get_game_screenshot` supports `save_path` param — use it to avoid base64 token overflow

## MCP / Editor Gotchas
- **Direct .tres edits are overwritten** — editor rewrites tileset on reload. Always use `execute_editor_script` for tileset changes.
- **Textures must be imported before `load()`** — copy PNG into project, call `EditorInterface.get_resource_filesystem().scan()`, verify `.import` exists, then run script.
- `TileSet.add_source(src, desired_id)` — second param forces source ID. `remove_source(id)` before re-adding for clean state.
- Godot auto-corrects invented UIDs in `.tscn` to match `.gd.uid` files — expect UID rewrites on editor save.
- `enabled = false` / `visible = false` can be accidentally set via editor UI during MCP sessions — verify after complex `execute_editor_script` runs.
- `class_name Foo` conflicts with any autoload also named `Foo` — never reuse autoload names for class_name.
- `Polygon2D` with `z_index = -1` works as a colored background in Node2D scenes.

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

## Roadmap
> **Session-end DOES update this list** — completed items get marked done, new priorities get added. Each entry: what to do, where to find the pieces, what's blocking it.

### Active priorities (in order)

1. **Wire remaining grove/bush/stone assets** — `stump_home_002–004.png` imported but not placed. 14 bushes at `game/assets/nature/bushes/` are decorative Sprite2D-ready. 39 new items in `props/items/` (ingots, wood piles, currency) available for InventoryManager.

2. **Rock placement fine-tuning** — `RoundedPokyRock` scene exists (`rounded_poky_rock.tscn`, ext_resource `71_rock_r` in world.tscn) but was removed from the world per user request. Re-add when placement position is decided. TowerRock1 at (450,290) and SquareRock1 at (75,420) are live. Consider adding more rock instances in varied locations (near cave entrance, NE corner) once base positions feel right.

3. **Grove expansion — continued** — door_open animation stays at last frame after playing (no door_close). StumpHome001 modulate pulse working. Consider: add a "door_close" or return-to-idle callback after door_open animation finishes.

### Blocked / waiting on user
- **`herb_bundle_dried.png`** — no source art exists. Currently using `herb_plant_type_a.png` as placeholder in drying rack PRODUCTS. User to supply replacement before this slot is usable.
- **`tree_oak_green.png`** — orphaned static PNG at `res://assets/nature/trees/`. No animation strips. User to decide: wire as a non-choppable decorative tree, or delete.
- **`shop_apothecary_alt.png`** — confirmed byte-identical duplicate of `shop_apothecary_main.png`. Pending dedup (user decision on which name to keep).

---

## Notes
> Check this section at the start of every session. Add short-lived context here (things in progress, temp decisions, reminders). Remove entries once resolved.

### Session end — 2026-05-27 (rocks + grove expansion)
- **Game state:** Runnable. Pre-flight ✅. Output log clean (4 lines, no errors). Only known warning: `world_drop_item.gd` unused `_area` linter (pre-approved).
- **What changed this session:**
  - **Choppable rock system (ADR-102):** 3 SpriteFrames .tres created (`resources/rocks/`). `choppable_rock.gd` script (hit/break/pile states, requires axe, emits `rock_broken` → stone_pile). 3 .tscn scenes (`scenes/interactables/rocks/`). TowerRock1 at (450,290) and SquareRock1 at (75,420) placed in world.tscn. RoundedPokyRock removed per user request but scene + ext_resource retained. world.gd wired: group connection in `_ready()`, `_on_rock_broken()` handler, click-nav support.
  - **Grove expansion (ADR-103):** EXCHANGE_TABLE now supports `hang_dry` (→gem_ruby / ×2 hang_dry) and `lumber` (→ingot_copper_01 / ×2 lumber). On item capture: StumpHome001 plays `door_open` animation. During 10s processing: StumpHome001 modulate pulses warm amber (sin wave at 2.5Hz). Resets to Color.WHITE when processing completes.
- **Rock system architecture:**
  - One shared script `choppable_rock.gd`: exports `hits_required` (3/4/5 per type). `_has_hit_anim` flag handles square_rock (no hit anim). Group `"choppable_rocks"` for world.gd auto-connection.
  - SpriteFrames: "idle" (loop), "hit" (loop:false), "break" (loop:false), "pile" (loop:true). Square rock pile has 4 variant frames.
  - All rock sprites 64×64 source, scale=0.75 → 48px world size, sprite position.y=-24 (origin at ground base).
- **Open issues:**
  - `RoundedPokyRock` removed from world — scene at `scenes/interactables/rocks/rounded_poky_rock.tscn`, ext_resource `71_rock_r` still in world.tscn header, ready to re-instance
  - StumpHome001 `door_open` stays at last frame after playing — no door_close animation exists
  - `tile_bit_tools/tile_bit_tools/` nested UID duplicates — ~34 editor warnings (pre-approved, non-blocking)
  - `_inv_mgr` in world.gd uses `get_node_or_null("/root/InventoryManager")` — replace with bare `InventoryManager` after editor restart
  - `herb_bundle_dried.png` no source art — placeholder in use
  - `tree_oak_green.png` orphaned at `res://assets/nature/trees/` — user's call
  - BigRock LogCollider poorly fits 58×63 rock cluster (low priority, known)
  - ShrineManager.gd autoload is now unused — harmless, can be removed later
  - Nav mesh is static — rebake if new StaticBody2D obstacle nodes are added or moved
- **Next priorities:** (1) Wire remaining grove/bush/stone assets. (2) Rock placement fine-tuning (RoundedPokyRock position). (3) Grove door_close/idle return.
- **Available but unwired:** ingots ×19, wood piles ×14, currency items ×5, stump_home_002–004 (stills, no scripts), grove dwellings ×7, bushes (14 variants), player_alt, purple_jack + grey_hoodie/rotations, cannabis/herb plants, garden dirt patches, tree_oak_green.png.

### Permissions Allowlist
All Godot MCP, filesystem MCP, and PixelLab MCP tools are pre-approved in `.claude/settings.json` — no prompts expected for any of them.
