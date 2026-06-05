# Game — Project Reference

> **Session start:** Read `ADR.md` for full architectural context and history. Then read the **Roadmap** and **Notes** sections at the bottom of this file.

## Rules
- **VERIFICATION HONESTY RULE (PRIME DIRECTIVE — overrides all else):** Never state or imply that something is "verified," "confirmed," "tested," "playtested," or "working" unless it was actually exercised in the real running system and the real result was observed. The following are NOT verification and must NEVER be presented as evidence: self-built composites, mockups, restatements of my own math/assumptions, "it should work," code that merely parses/compiles, or static reasoning. These are circular — they only prove I repeated my own intent.
  - Always separate and label: (a) PARSES/COMPILES, (b) REASONED (static, not run), (c) VERIFIED (actually run + observed in the real system).
  - NEVER put a verification claim next to a caveat that contradicts it. If a caveat like "not tested live" applies, the thing is NOT verified — say so plainly and do not use the word "verified" anywhere near it.
  - When something was not actually run and observed, the required wording is: "NOT verified — not tested." When in doubt, under-claim.
  - Violation example (this exact failure, 2026-05-31): I claimed a wall composite "Verified" Erik's head cleared the wall; it was a Python image I hand-built from the same scale I'd just chosen — circular, not a playtest.
- **ASSET INSPECTION RULE:** When instructed to check, review, or analyze PNG files or other discrete asset files, EVERY file in the specified set must be individually inspected before responding or taking action. Do not sample, skip, or assume similarity between assets. Confirm each file has been individually opened and viewed before proceeding. Never claim to have reviewed files that were not explicitly opened.
- **PLAYTEST RULE:** If you make it, you play test it. Always. Run the game via MCP, exercise the feature, take a screenshot to confirm correct behavior before reporting done.
- **TASK TRACKING RULE:** For any task with 3+ distinct steps, use `TaskCreate` to create subtasks before starting, mark each `in_progress` when begun, and `completed` when done. Check `TaskList` at the start of each session to resume any open tasks.
- **ASSET REPLACEMENT RULE:** Never substitute one PNG for a different PNG without explicit user approval first. If an asset is missing and no exact match exists, **check `C:\Users\erikc\Dev\Game\temp` first** before asking — this is the user's staging folder for new/incoming assets. If not found there either, stop and ask. Choosing replacement art is the user's job.
- **SESSION-END PRE-FLIGHT RULE:** Before executing SESSION-END, run these checks. If ANY fail, stop immediately, print `⚠ SESSION-END BLOCKED`, list every issue found, and wait for the user to either resolve the issue or type `override session-end` to bypass. Do NOT proceed with doc updates or commit until the user responds.
  1. **`script = null` override check** — grep all `.tscn` files for lines matching `^script = null`. Each hit means a Godot editor operation silently nulled a scene script, breaking all logic on that node (root cause of the 2026-05-24 hotbar/input regression). Alert: "script = null found in [file:line] — this overrides [scene]'s script at runtime. Fix: remove the `script = null` line."
  2. **Editor error check** — call `get_editor_errors` via MCP. If any errors are returned that are not pre-existing/known warnings (e.g. tile_bit_tools UID duplicates), list them and block.
  3. **Game runability check** — call `play_scene` + `get_output_log` (brief run). If the output log contains `Parse Error`, `Script failed to load`, or `SCRIPT ERROR`, block with the log snippet. Stop the scene after checking.
  4. **No block if:** all checks pass, or the only errors are the pre-approved known warnings (`tile_bit_tools` nested UID duplicates, `hud.gd INT_AS_ENUM_WITHOUT_CAST`). Those are not blocking.
- **SESSION-END RULE:** When the user says any of: "end session", "update docs", "session end", "wrap up", "close session", or similar finalization language — **first run SESSION-END PRE-FLIGHT**, then automatically perform all of the following: (1) update `ADR.md` with any architectural decisions made this session + append a change log row; (2) update CLAUDE.md "Where We Are" to reflect current state; (3) replace the Notes section with a fresh session-end entry covering: game state, open issues, pending tasks, and available-but-unwired assets; (4) **update the Roadmap section** — remove completed items, remove dropped items, add new priorities discovered this session, keep it accurate and current; (5) commit all doc changes. Do not create an ADR for minor fixes unless an actual architectural decision was made.
- **TSCN EDIT RULE:** Never rewrite any `.tscn` file in full using the Write tool. Always use targeted Edit tool calls for specific node changes. Full rewrites silently drop inline node properties — this was the root cause of the recurring y_sort_offset loss (ADR-073→090). **Never edit a `.tscn` file on disk while it is open in the Godot editor** — Godot holds the scene in memory and overwrites your disk edit on the next save, silently discarding all changes. To modify a scene: either (a) use MCP tools (`update_property`, `execute_editor_script`) which write directly into Godot's memory, or (b) open a different scene first via MCP `open_scene`, edit the file on disk, then reopen the original.
- **TREE Y-SORT RULE (ADR-091 — canonical, permanent):** Tree node origin = trunk base (ground contact). TreeSprite child has `position = Vector2(0, -22)` (sprite draws upward). `y_sort_offset` stays at default 0 — never written to any tree .tscn, never stripped. Depth sort transition is at node Y (trunk base). To add a new tree species: set TreeSprite.position.y = -(half_tree_height_px), leave everything else at defaults. To move a tree in world.tscn: set instance position directly — no y_sort_offset override needed. TrunkCollider at origin (y=0). StumpCollider at origin. stump_y_offset export = 0.0 (stump appears at trunk base by default).
- **CONFLICT CHECK RULE:** Before implementing any major decision or change, check for conflicts with existing architecture, active systems, asset dependencies, ADR decisions, or anything else that could break or contradict what's already in place. If a potential problem is found, stop and discuss it with the user — do not proceed and self-fix silently.

## Where We Are
- **Current state (2026-06-05):** Runnable, pre-flight ✅, output log clean (1 known unused-var warning in world_drop_item.gd — not blocking). All systems ADR-105–117 live. Full per-feature history lives in `ADR.md` — this section stays lean (newest decisions only).
- **Interior-door robustness pass (2026-06-05, no ADR — robustness hardening):** ADR-117's "door interaction NOT verified live" caveat is **CLOSED** — a `bmad-investigate` case (`_bmad-output/implementation-artifacts/investigations/interior-door-investigation.md`) VERIFIED the full door chain live (registration → nearest → one-shot open → settle-closed → re-arm → guard), then 5 robustness edits were applied + VERIFIED live: (1) `interior.gd._get_nearest_interactable()` max-range cull (`INTERACT_RANGE_SQ=64²`; far 138px→NULL, near 15px→door); (2)+(3) door matches the player by **group** — `door.gd` `is_in_group("player")` + `player.gd._ready()` `add_to_group("player")` (rename-proof, replaces the hardcoded `"Player"` name match); (4) `interior.gd._input` interact always `_cancel_navigation()`+`set_input_as_handled()` even on a miss; (5) `door.gd._ready()` defensively forces `set_animation_loop("open", false)`. Files `door.gd`/`player.gd`/`interior.gd` **STAGED** (not committed). **Group-as-rename-proof node ID is the canonical pattern** for new interactables.
- **Project-context doc (2026-06-05, no ADR — tooling artifact):** Generated `_bmad-output/project-context.md` via the BMAD `bmad-generate-project-context` workflow — a lean, LLM-optimized "rules of the road" file for AI agents (5 sections, ~60 rules, `status: complete`). It captures only unobvious rules and **defers to CLAUDE.md + ADR.md for depth**. No game code/scene/asset changed this session; no architectural decision made.
- **Interior camera zoom-out (2026-06-04, no ADR — ADR-117 tweak):** The enlarged interior room was taller than the 16:9 viewport allowed at the exterior's 0.87 zoom, so the north door tucked under the top HUD bar and the south exit crowded the hotbar. `interior.gd._ready()` now sets `cam.zoom = Vector2(0.7, 0.7)` (interior's own Player instance only — exterior camera untouched). At 0.7 the limit span (224×150) < visible area, so the camera is static/centered on the room. VERIFIED in-engine on a fresh scene load (zoom read back (0.7,0.7) from _ready(); whole room framed with margin).
- **Interior door + room expansion (ADR-117, 2026-06-03):** Interior room enlarged (walls extended, furniture/rocks moved). New **decorative** animated door on the north wall: `Interactables/door.gd`+`door.tscn` (uid `u22gcftx5ace`), `Node2D`+`AnimatedSprite2D` (`door_sprites.tres`, `open` 9f loop=false speed=10) + `DoorArea` (r=26). Follows `well.gd`'s interactable pattern (emits `interactable_entered/exited`, exposes `interact(player)` → one-shot `open` with `_animating` guard, rests on frame 0 = closed). **No collision body** — purely cosmetic (the wall blocks, not the door; `ExitDoor` Area2D on the south wall still does the real scene exit). `interior.gd` adopts `world.gd`'s `_interactables`/`_get_nearest_interactable()` pattern. **Camera-limit fix:** `interior.gd` limits `+160→+224`/`+128→+150` to bound the enlarged room. Camera VERIFIED in-engine (limits read back L0/T-39/R224/B111, room frames in viewport); **door interaction NOT verified live** — logic only reasoned/parses. Review: 1 patch (camera) applied+verified, 9 nits deferred to `TODO.md`, 4 dismissed.
- **Planting animation (ADR-116, 2026-06-02):** First mechanic-wired player animation. 4 GIFs in `temp/Player_Erik_PlantingSeeds/` (9f @ 56×56) extracted → 27 RGBA PNGs in `assets/characters/erik/planting_{south,north,side}/` (PIL; **`east`→`planting_side`** w/ flip_h, `west` dropped). `erik_sprites.tres` gains `planting_down/side/up` (9f, loop=false, speed=8; folder=compass, anim-name=down/up/side per `chop_*` convention). **Canonical wiring pattern** (template for the unwired-anim backlog): `player.gd` `is_planting` flag + `player_animation.gd` `elif is_planting: "planting_"+dir` branch (after `is_trading`, cleared on `animation_finished`) + `world.gd._try_plant_seed()` sets the flag when the seed is consumed. VERIFIED in-engine: anims load (existing intact), plant → one-shot anim (seed 3→2→1) → auto-returns to idle; frame-5 screenshot shows the bend-over pose.
- **Seed planting (ADR-115, 2026-06-02):** Garden bed now **starts empty** (3 pre-placed `CannabisPlant` instances removed from `world.tscn`). Player sows sprouts from a **stacked `seed_packets` hotbar item** (`_grant_starting_items` grants ×3, one slot, count badge "3"). `world.gd._try_plant_seed()` runs first in the interact branch: with a seed selected **and** the player within `_BED_PLANT_RADIUS` (40px) of the bed, it consumes 1 seed and spawns `cannabis_plant.tscn` as a **direct World child** (ADR-114 un-nest rule) at the nearest of 3 `_GARDEN_SLOTS` (named `CannabisPlant1/2/3`), wiring its signals into the existing water-gated growth loop; otherwise it returns false so normal interact (water/well/chop) proceeds. Slot geometry is a const in `world.gd` (move with the bed manually). Watering/growth (`plant.gd`) untouched. VERIFIED in-engine: seed count 3→2→0, sprouts at correct slots (stage-0 seedling), watering advances stage 0→1.
- **Garden depth sort (ADR-114, 2026-06-02):** Bed **un-nested** — the 3 plants are now **direct children of World** (`CannabisPlant1/2/3` in `world.tscn`), self-registering to `garden_plants` (group wiring in `world.gd` unchanged, count 4). `cannabis_garden_bed.tscn` is now **dirt-only**. **Depth is driven by node-origin `position.y`, NOT `y_sort_offset`** (confirmed live: `y_sort_offset` is inert in 4.6.2 — sorting is purely `position.y`). Tree-pattern decoupling: move the node origin (= sort line) and offset the child sprite to hold the visual. Dirt: bed instance at (264,90), `Bed` sprite `position.y=+32` → dirt always sorts behind the player, flicker tie-point off the patch. Plants: instance y=115, `PurplePlant` sprite y=+9, `Shadow` y=+8.61 (art pixel-identical to ADR-113) → player **in front** when standing in the bed, **behind** when north of the plot (walk-behind for tall plants). VERIFIED fresh-frame: legs over dirt (no slice/flicker), player over seedlings in bed.
- **Recent (detail in ADR.md):** ADR-113 cannabis garden bed (water-gated grow→drying-rack, `garden_plants` group, dirt-stripped `*_nodirt.png` sprites); ADR-112 wall rigging (9 `StaticBody2D` templates at `res://scenes/structures/walls/`, base collider, placed-walls in world.tscn are still bare Sprite2D); ADR-111 hotbar (`hotbar17.png`, `HOLE_X` anchoring, SPC/T overlay removed); grey-hoodie house swap (`house_grey_hoodie_002.png`); static-idle revert (`player_animation.gd:34` → `"idle_" + dir`); walk-anim uses `get_real_velocity()`. **OPEN:** orange-fruited bush anim misgenerated (PixelLab regen); digging-north dir missing; crafting/digging/eating/jumping/push/trade_item/chop_axe anims in .tres but unwired.
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
- **Godot autosave:** Close scene before editing `.tscn` on disk: `open_scene("other.tscn")` → edit → `open_scene("world.tscn")`. **`run/auto_save/save_before_running` is DISABLED on this machine (2026-06-02)** — Play uses the on-disk scene (not the editor's in-memory state), so disk `.tscn` edits are no longer clobbered on Play; manually Ctrl+S in-editor edits before Play to see them.
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
- **Staging / incoming assets**: `C:\Users\erikc\Dev\Game\temp\` — user drops new animation sets and sprites here. Always check this folder before reporting a missing asset. Subfolders vary — PixelLab export bundles (hash-named dirs with `animations/` containing direction subdirs of frame_NNN.png) or named staging folders; currently holds `RockWallBrockenMidEnd/`.
- Source assets: `C:/Users/erikc/Dev/Game/GameAssets/` (~800 PNGs + organized subdirs incl. bushes/, drying_rack_alt/, weed_plants/, objects_misc/). Tool art (hoe, scythe) lives in-project at `res://assets/props/items/` — NOT under GameAssets/ and there is no `crafting_tools/` folder.
- In-project assets (VERIFIED_USED): `res://assets/` + `res://resources/` (reorganized 2026-05-17, ADR-062)
- In-project legacy DELETED: `res://GameAssets/` — removed 2026-05-19 (985 files, zero active refs, ADR-071)
- **Active building assets**: `res://assets/structures/`
  - `shops/` — bakery: `shop_bakery_main.png`, `shop_bakery_open.png`
  - `houses/` — teal house animation: `house_grey_teal_animation.png`
  - `cave_entrance_arch_stone.png`
  - `stump_door_dwelling.png` — ancient stump with carved door (prop/structure)
  - `walls/` — 9 wall PNGs (brick/rubble × long/end/tall + broken_end_long/short + mid_collapsed). Scene templates at `res://scenes/structures/walls/` are `StaticBody2D` root (origin at base, tree convention): per-wall uniform scale normalizes tallest part to 24px, base `RectangleShape2D` collider, `y_sort_offset=7` (ADR-112). **Use scene templates, not raw PNGs.** Placed in `World/world.tscn` (10 instances).
- **Tree + stump assets** (per-species subdirs):
  - Trees under `res://assets/nature/trees/`: `pine/` (`pine_idle.png` + `pine_chop/`, `pine_fall/`), `maple/` (`maple_idle.png` + `maple_chop/`, `maple_fall/`, `maple_hit_fall/`), `fir/` (`fir_idle.png` + `fir_chop/`, `fir_fall/`), `willow/` (`willow_f0`–`willow_f8.png`, 9 frames). Plus `tree_oak_green.png` (static, unwired).
  - Stumps under `res://assets/nature/stumps/`: `stump_idle.png`, `BigMushroomStump.png`, `log_fallen_brown.png`, `stump_dissolve/` (32 frames)
  - All auto-imported. Willow (`TreeWillowWeeping`) + `BigMushroomStump` are placed in world.tscn; pine/maple/fir not yet wired to ChoppableTree scenes.
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
- 8 objects in world.tscn have Shadow Node2D children (PlayerHome, Well, Plant, DryingRack, Big Rock, TreeWillowWeeping, HouseTwostoryTeal, BigMushroomStump)

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

1. **Crafting system expansion** — Minimal workbench proven (ADR-105). Next: hoe → tillable soil, more recipes, ingot/currency wiring, UI font size pass (CanvasLayer at window res), NPCHome world-accessible door.

2. **Crop / farming system** — Cannabis garden DONE (ADR-113 mechanic + ADR-114 depth fix + ADR-115 seed planting): `cannabis_garden_bed.tscn` is now **dirt-only**; the bed **starts empty** and the player **sows** plants from a stacked `seed_packets` hotbar item (Space while on the bed → `world.gd._try_plant_seed()` spawns `cannabis_plant.tscn` as a direct World child at the nearest of 3 `_GARDEN_SLOTS`). Water-gated grow → drying rack via `garden_plants` group. **To place a new garden: drop a bed (dirt) scene; planting slots are a const in `world.gd` (`_GARDEN_SLOTS`) — control depth with each node's `position.y` (NEVER `y_sort_offset` — inert in 4.6.2).** Next: (a) generalize slots so a second bed can be placed (slots are currently hard-coded to the one bed); (b) **timed** CropGrowth (real-time) using corn/berry sets in `res://assets/nature/crops/` (corn 17f/16f, berry 17f) — distinct from the water-gated mechanic; (c) hoe → tillable soil. Plant 0.3/bed 0.5 scale first-pass. Orange bush blocked (PixelLab regen).

3. **UI design decisions** — assets imported but blocked on user decisions. See `TODO.md` for exact questions:
   - ~~`hotbar_7slot.png`~~ — RESOLVED (ADR-111): replaced by `hotbar17.png`, 7-slot hotbar live.
   - `fill_bar_new.png` — replace `WaterMeterBar.png` OR new stamina bar?
   - `panel_grey_metal/dark_wood/light_wood` — which scene/element should each back?

4. **chop_axe animation wiring** — `chop_axe_down/side/up` (16f) are in `erik_sprites.tres`. Currently `player_animation.gd` still plays `chop_*` for axe hits. To use new animation: add `elif player.equipped_tool == "axe": anim = "chop_axe_" + dir` before the else `anim = "chop_" + dir` branch.

5. **Mechanic hooks for new animations** — **`planting_down/side/up` now wired (ADR-116) as the canonical template** (player.gd flag → player_animation.gd `elif` branch → mechanic sets flag → `animation_finished` clears it). Still unwired with frames ready: crafting, digging, eating, jumping, push, trade_item. Each needs the same 3 pieces. New GIF art → use the ADR-116 PIL extraction recipe (GIF frames → `convert('RGBA')` → `planting_*`-style per-dir folders → `scan()` → add a `trade_*`-format block to `erik_sprites.tres`).

6. **Wall placement + collision** — 9 rigged templates at `res://scenes/structures/walls/` (ADR-112: StaticBody2D root, base collider, tallest part 24px). The walls currently in `world.tscn` are bare dragged Sprite2D (no collision). Next: replace those with template instances so the player is blocked + y-sorts. **Heads-up (ADR-114):** the templates' `y_sort_offset=7` is **inert** in 4.6.2 — sorting is purely `position.y`. The walls occlude correctly only because the root origin sits at the wall base; when wiring, verify depth by base `position.y`, not the offset.

### Blocked / waiting on user
- **Orange-fruited mature bush animation** — static sprites ready, animation needs PixelLab regeneration (prompt: fruit-laden bush, idle sway or pick animation)
- **Digging north animation** — no north-facing dir in source assets; ask user if PixelLab regen needed
- **UI wiring** — hotbar 7-slot, fill bar, 3 panels all need design decision before wiring

---

## Notes
> Check this section at the start of every session. Add short-lived context here (things in progress, temp decisions, reminders). Remove entries once resolved.

### Session end — 2026-06-05 (interior-door robustness pass)
- **Game state:** Runnable. Pre-flight ✅ (no `script = null` in any `.tscn`; editor errors were only my own MCP test-script noise — `gdscript://` parse errors + `_mcp_error`/`f0` unused-vars from `execute_game_script` — plus the pre-approved `world_drop_item.gd:11` unused-var; `play` main + output log clean, only the 2 engine banner lines, no Parse/SCRIPT errors).
- **What changed this session:** **5 robustness edits** to the ADR-117 interior door, all VERIFIED live (3 files **STAGED, not committed**): `game/Interactables/door.gd`, `game/Player/player.gd`, `game/World/PlayerHome/interior.gd`. (1) `interior.gd._get_nearest_interactable()` max-range cull `INTERACT_RANGE_SQ=64²` (far 138px→NULL, near 15px→door); (2)+(3) door matches player by **group** — `door.gd` `is_in_group("player")` in `_on_area_entered/exited` + `player.gd._ready()` `add_to_group("player")` (rename-proof, replaces hardcoded name); (4) `interior.gd._input` interact branch always `_cancel_navigation()`+`set_input_as_handled()` even on a miss; (5) `door.gd._ready()` defensively forces `set_animation_loop("open", false)`. Investigation case file `_bmad-output/implementation-artifacts/investigations/interior-door-investigation.md` created (door chain VERIFIED working; ADR-117 caveat retired). Change-log row only — no numbered ADR (robustness, no architectural decision).
- **⚠ Door investigation closed the "NOT verified live" caveat:** the door interaction is now VERIFIED working end-to-end. **Group-as-rename-proof node ID is the canonical pattern** for future interactables (see `door.gd`/`player.gd`).
- **✅ RESOLVED — three pre-existing uncommitted files now committed (2026-06-05, commit `4d0f4e9`):** `interior.tscn` (furniture layout pass — clock/bed/shelf/door repositioned + rescaled, colliders matched), `world.tscn` (one `Overlay` tile paint), `door_sprites.tres` (`open` re-timed: open frame lingers 6s, ease 1.5s, speed 10→8; UID re-randomized to `c7mw3xmc0ldaf`, normal). Re-verified live before commit: interior loads clean, furniture flush with no overlap, door `interact()` plays without error. No longer in the working tree.
- **⚠ Investigation case file untracked:** `_bmad-output/.../interior-door-investigation.md` is `??` (not staged). Decide whether to commit it with the docs.
- **Tooling notes:** `play_scene` always plays "main" — to load a non-main scene at runtime use `execute_game_script` + `change_scene_to_file` (change_scene is deferred → split into 2 calls: load, then read state). **`execute_game_script` code must have NO leading whitespace** — the MCP wrapper supplies indentation; a leading tab/space → "Parse error: Unindent doesn't match"/"Mixed tabs and spaces". (This corrects the earlier "must be tabs" note.) No `await`; use `_mcp_print()`. **Typed-array gotcha:** assigning an untyped literal to a typed field (`interior._interactables = [door]`) silently errors mid-script — use `.clear()` + `.append()`. The MCP bridge needs a live editor link — if "Godot not connected", toggle the MCP Pro plugin off/on.
- **⚠ PENDING — push likely still blocked:** local `main` tracks `origin/master` and the safety classifier has denied direct default-branch pushes before (ADR-115/116/117 + this + last session's doc commits may all be unpushed). To push: user runs `! git push origin HEAD:master`, OR feature branch + PR, OR add a Bash permission rule.
- **Open issues:**
  - **8 deferred review findings remain in `TODO.md`** (section "Code Review — Deferred Findings") — the 5 robustness items are now FIXED (cull, group-match input-consume, loop-off, nav-cancel) and the vanity UID is RESOLVED; what's left is user-decision/visual: orphan `house_grey_hoodie_door_frames.tres` (delete needs approval), possible TowerRock1/SquareRock1 exterior overlap (needs visual playtest), wall-collider asymmetry / SouthRight overhang (cosmetic, behind walls), and a facing/`can_interact` gate (only matters if the door gains function).
  - **Garden slots hard-coded to one bed** — `_GARDEN_SLOTS`/`_bed_slots` in `world.gd` assume the single bed at (264,90). A second bed needs slot geometry generalized.
  - **Garden plant/bed scale** — plant 0.3 / bed 0.5 first-pass; plants sit slightly high (cosmetic).
  - **Walk-behind balance** — plant sort line at y=115 favors "player in front in bed"; walk-behind zone is the grass strip north of the plot. Adjustable via plant instance y.
  - **Duplicate cannabis/garden PNGs** — several byte-identical copies on disk. Left pending cleanup decision (Safety Rule).
  - **NPC walk-when-stationary** — failed fix still in `npc_grey_hoodie.gd`. Different strategy needed.
  - **Orange-fruited mature bush** / **Digging north** — no valid animation; need PixelLab regen.
  - **UI decisions pending** — fill bar, 3 panels (see `TODO.md`); **Craft UI font oversized** (CanvasLayer at window res).
  - **No world door to NPCHome**; **Hoe has no gameplay effect** (no tillable soil).
  - **Walls in world.tscn** are bare Sprite2D (no collision), NOT the rigged templates at `res://scenes/structures/walls/` (ADR-112).
  - `RoundedPokyRock` scene not placed; `tile_bit_tools` UID dup warnings (pre-approved); `_inv_mgr` uses `get_node_or_null("/root/InventoryManager")` (swap to bare `InventoryManager` after editor restart).
- **Animation status (all in erik_sprites.tres — ADR-109/116):**
  - ✅ `pickaxe_strike_down/side/up` — wired and playtested
  - ✅ `planting_down/side/up` — wired (ADR-116), `planting_down` playtested; side/up load-verified
  - ⛔ `idle_animated_down/side/up` — UNWIRED as of 2026-06-01 (reverted to static `idle_*` because the sway read as walking; frames remain in .tres)
  - ⏳ `crafting_up` — in .tres, no mechanic
  - ⏳ `digging_down/side` — in .tres, no mechanic, north dir missing
  - ⏳ `eating_down/side/up` — in .tres, no consume system
  - ⏳ `jumping_down/side/up` — in .tres, no jump mechanic
  - ⏳ `push_down/side/up` — in .tres, no push mechanic
  - ⏳ `trade_item_down/side/up` — in .tres, no new trigger
  - ⏳ `chop_axe_down/side/up` — in .tres, player_animation.gd still uses chop_* for axe
- **Available but unwired:** `tool_scythe.png`, ingots ×19, wood piles ×14, currency ×5, stump_home_002–004, grove dwellings ×7, bushes ×14, player_alt, purple_jack, grey_hoodie/rotations, cannabis/herb plants, tree_oak_green.png, KnG_ShT diagonal run frames, Shovel sprite (Tool_Set)

### Permissions Allowlist
All Godot MCP, filesystem MCP, and PixelLab MCP tools are pre-approved in `.claude/settings.json` — no prompts expected for any of them.
