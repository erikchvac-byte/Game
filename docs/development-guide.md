# Game — Development Guide

## Prerequisites

| Tool | Version | Notes |
|---|---|---|
| Godot | 4.6.2-stable | Forward+ renderer; download from godotengine.org |
| OS | Windows 11 | D3D12 required for Forward+ on Windows |
| Claude Code | latest | For AI-assisted development via MCP bridge |
| Node.js | 18+ | Required for MCP bridge server |

## Opening the Project

1. Launch Godot 4.6.2
2. **Import project:** `C:/Users/erikc/Dev/Game/game/`
3. Let the import process complete (first time imports all PNGs)
4. The project opens with `world.tscn` visible in the editor

## Running the Game

- **F5** or click the Play button — runs `res://main.tscn` (configured as main scene)
- **F6** — runs the currently open scene
- **F8** — stop

## MCP Bridge (AI Dev Tools)

The Godot MCP Pro plugin enables Claude Code to interact with the running editor/game.

```
Bridge server: C:/Users/erikc/Dev/Game/mcp-bridge/index.js
```

1. Ensure the `godot_mcp` plugin is enabled in Godot (Project → Project Settings → Plugins)
2. The bridge runs automatically when Claude Code session starts (configured in `.claude/settings.json`)
3. All `mcp__godot-mcp-pro__*` tools are pre-approved — no permission prompts

**Key MCP tools for development:**
- `execute_editor_script` — run arbitrary GDScript in the editor (use `_mcp_print()` for output)
- `execute_game_script` — run code while game is playing
- `play_scene`, `stop_scene` — control the game session
- `get_output_log` — read Godot output log
- `get_editor_errors` — check for editor errors
- `bake_navigation_mesh` — rebake nav mesh after adding obstacles

## Editing Scenes

### TileMap
- Use `TileMapLayer` nodes (not deprecated `TileMap`)
- Active tileset: `res://resources/tilesets/GrassBrick_OVERLAYS__tileset.tres`
- **Do NOT edit `.tres` files directly** — the editor overwrites them on reload. Use `execute_editor_script` for programmatic tileset changes.

### Adding a New Tree Species
1. Duplicate `pine_tree.tscn`
2. Create a SpriteFrames `.tres` for the new species with `idle`, `chop`, `fall` animations
3. Assign it to TreeSprite; set `species` export var
4. Place in `world.tscn` — the tree auto-registers to `"choppable_trees"` group
5. TreeSprite `position.y = -(half_height_px)`; leave `y_sort_offset` at default 0
6. Rebake NavRegion if the tree trunk blocks navigation

### Adding a New Interactable
1. Create node with `Area2D` proximity zone
2. Emit `interactable_entered(self)` and `interactable_exited(self)` signals
3. Implement `can_interact(player)`, `blocked_message(player)`, and `interact(player)` methods
4. Connect signals in `world.gd._ready()` or have the node self-connect to world

### Adding a New Equippable Tool
1. Add item to `InventoryManager` via `add_item(key, tex)`
2. Add a row in `world.gd.EQUIPPABLE_TOOLS` dict: `"item_key": "inputmap_action_name"`
3. Add the `InputMap` action in `Project → Project Settings → Input Map`

### Adding Items to the Grove Exchange
1. Edit `stump_shrine.gd.EXCHANGE_TABLE`
2. Format: `"item_key": {"processed": [key, tex_path], "raw": [key, tex_path, count]}`

### Scene Transition Pattern
```gdscript
# Leaving a scene:
$Area.body_entered.disconnect(_on_body_entered)  # prevent double-trigger
if player: player.set_physics_process(false)
await TransitionManager.fade_to_black(0.4)
Engine.set_meta("spawn_position", Vector2(x, y))  # if needed
get_tree().change_scene_to_file("res://target.tscn")

# Arriving in a scene (_ready):
TransitionManager.fade_from_black(0.4)  # no await needed
if Engine.has_meta("spawn_position"):
    $Player.position = Engine.get_meta("spawn_position")
    Engine.remove_meta("spawn_position")
```

## Project Structure Gotchas

### y_sort_offset Rules
- `y_sort_offset` is only a `.tscn` serialization field — never read/write it via GDScript at runtime
- Trees do NOT use `y_sort_offset` — their trunk base IS their sort origin
- All other nodes: use the `collision_validator.gd` tool to verify expected values
- Edit via text only (`Edit` tool on `.tscn` file); editor operations silently strip it

### Never Rewrite .tscn Files
- Always use targeted `Edit` calls for specific node changes
- Full `Write` rewrites silently drop inline node properties (y_sort_offset, etc.)

### Nav Mesh
- The nav mesh in `world.tscn` (NavRegion node) is static
- Rebake after adding or moving any `StaticBody2D` obstacle node
- Use `mcp__godot-mcp-pro__bake_navigation_mesh` via MCP or the editor UI

### PowerShell Encoding
- Never use `Out-File` or `Set-Content` for Godot files
- PS 5.1 adds UTF-16 BOM which breaks Godot's text resource parser
- Use `[System.IO.File]::WriteAllText(path, content, [Text.Encoding]::UTF8)` instead

### Autoload Autosave Issue
- Close the active scene before editing a `.tscn` file on disk
- Pattern: `open_scene("other.tscn")` → edit file → `open_scene("world.tscn")`

## Session End Checklist (from CLAUDE.md)

Before committing:
1. Grep all `.tscn` files for lines matching `^script = null` — these break scene scripts
2. Run `get_editor_errors` via MCP — check for non-approved errors
3. Run `play_scene` + `get_output_log` briefly — look for `Parse Error`, `Script failed to load`, `SCRIPT ERROR`
4. Pre-approved warnings (non-blocking): `tile_bit_tools` nested UID duplicates, `hud.gd INT_AS_ENUM_WITHOUT_CAST`

## Known Issues (as of 2026-05-27)

- `HouseTwostoryTeal` collision has 2 shapes with suspicious rotations — verify/tune in-game
- `tile_bit_tools` nested UID duplicates: ~34 editor warnings (cosmetic, non-blocking)
- `ShrineManager` autoload is now unused (stump_shrine.gd owns all logic)
- `_inv_mgr` in world.gd uses path lookup instead of bare autoload name — will fix after editor restart
- `herb_bundle_dried.png` missing source art — placeholder in use for one drying rack product slot
- Nav mesh must be manually rebaked when obstacles change
