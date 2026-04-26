# Game — Project Reference

> **Session start:** Read `ADR.md` for full architectural context and history.

## Where We Are
- **Last completed:** M4 — player_animation.gd (`res://Player/player_animation.gd`)
- **Next up:** M5 — World scene + TileMapLayer
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

## Stage 1 Milestones
| # | Milestone | Status |
|---|-----------|--------|
| M0 | Project settings + asset copy | ✅ Done |
| M1 | SpriteFrames resource | ✅ Done |
| M2 | Player scene (no script) | ✅ Done |
| M3 | player.gd movement script | ✅ Done |
| M4 | player_animation.gd | ✅ Done |
| M5 | World scene + TileMapLayer | Pending |
| M6 | Main scene + camera limits | Pending |
