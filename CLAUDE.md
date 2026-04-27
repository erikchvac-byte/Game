# Game — Project Reference

> **Session start:** Read `ADR.md` for full architectural context and history.

## Where We Are
- **Last completed:** Player home door + interior scene (session 4, commit `9508969`)
- **Next up:** Interior tileset (replace Polygon2D floor with proper tiles from `GameAssets/interior/`), then Stage 2 planning
- **Open decisions:** None

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

## Asset Layout
- Source assets: `C:/Users/erikc/Dev/Game/GameAssets/` (~800 PNGs)
- In-project assets: `res://GameAssets/` (same tree, copied into `game/`)
- Player sprites: `res://GameAssets/Player Character/{Idle,Walk,Run}/{Down,Side,Up}.png`
  - Frame size: **59×49 px** per frame
  - Idle: **4 frames** (236px wide)
  - Walk: **4 frames** (236px wide)
  - Run: **6 frames** (354px wide)
  - Left = Side + `flip_h = true` (no separate asset)
- Ground tiles: `res://GameAssets/Tiles/` — 16×16 px

## Player Scene Architecture (ADR-002, ADR-003)
- Root: `CharacterBody2D`, `motion_mode = MOTION_MODE_FLOATING`
- Child: `CollisionShape2D` (CapsuleShape2D, ~8×12px)
- Child: `AnimatedSprite2D` — script: `player_animation.gd`
- Root script: `player.gd` — exposes `velocity`, `facing`, `is_moving`
- Animation names: `idle_down`, `idle_side`, `idle_up`, `walk_down`, `walk_side`, `walk_up`, `run_down`, `run_side`, `run_up`

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

## Scene Transition Notes (ADR-010)
- `get_tree().change_scene_to_file(path)` works from any node
- Cross-scene state: `Engine.set_meta("key", value)` / `Engine.get_meta("key")` / `Engine.remove_meta("key")`
- **DO NOT** use autoloads added at runtime — they don't become globally visible to scripts until editor restart
- Interior scene is self-contained with its own Player instance; camera limits overridden in `_ready()`
- Add `await get_tree().create_timer(0.4).timeout` before connecting ExitDoor signal to prevent spawn-trigger
- Interior: `res://World/PlayerHome/interior.tscn` — 160×128 room, Polygon2D floor/wall, exit at south-center
- Exterior door: `DoorEntrance` Area2D at world (112, 141); house collision is 3-shape (upper block + left/right lower flanking a 58px door gap)
- `Engine.set_meta("spawn_position", Vector2(112, 168))` set on interior exit → consumed in `main.gd._ready()`

## Interior Assets Available
- `res://GameAssets/interior/` — bed, carpet, furniture, kitchen, decorations, stairs
- `res://GameAssets/interior/tiles.PNG` (321×80) — floor/wall tile options for future interior tileset
- `res://GameAssets/Village/Door Animation/Door1-4.png` (29×19 each) — door open animation frames

## MCP / Editor Gotchas (session 4)
- Godot auto-corrects invented UIDs in `.tscn` to match `.gd.uid` files — expect UID rewrites on editor save
- `enabled = false` / `visible = false` can be accidentally set on nodes via editor UI during MCP sessions — verify after complex execute_editor_script runs
- `class_name Foo` conflicts with any autoload also named `Foo` — never reuse autoload names for class_name
- `Polygon2D` with `z_index = -1` works correctly as a colored background in Node2D scenes

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
