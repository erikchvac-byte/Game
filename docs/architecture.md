# Game — Architecture

## Overview

Top-down 2D life-sim using Godot 4's scene/node composition model. All game logic is GDScript. Global state flows through autoload singletons. The world is a single outdoor scene (`world.tscn`) with interior scenes loaded on transition.

---

## Scene Hierarchy

```
main.tscn  (main.gd)
├── World  [world.tscn, world.gd, y_sort_enabled=true]
│   ├── TileMapLayer (ground layer)
│   ├── TileMapLayer (overlay layer)
│   ├── NavRegion  NavigationRegion2D  ← baked nav mesh
│   ├── Player  [player.tscn, player.gd]
│   │   ├── CollisionShape2D  (CapsuleShape2D ~8×12px)
│   │   ├── AnimatedSprite2D  (player_animation.gd, scale=0.5)
│   │   ├── NavAgent  NavigationAgent2D
│   │   └── Camera2D  (limits: left=195, top=88, right=835, bottom=584)
│   ├── PlayerHome  AnimatedSprite2D  (bakery, y_sort_offset=35)
│   ├── DoorEntrance  Area2D
│   ├── HouseTwostoryTeal  StaticBody2D
│   ├── Well  Node2D  (well.gd, y_sort_offset=24)
│   ├── Plant  Node2D  (plant.gd, y_sort_offset=24)
│   ├── DryingRack  Sprite2D  (drying_rack.gd, y_sort_offset=30)
│   ├── [BigRock, LogCollider, ...]  StaticBody2D obstacles
│   ├── GreyHoodie  CharacterBody2D  (npc_grey_hoodie.gd, y_sort_offset=19)
│   │   ├── NpcCollider  CollisionShape2D
│   │   └── NavAgent  NavigationAgent2D
│   ├── ForestCreature  CharacterBody2D  (forest_creature.gd, y_sort_offset=11)
│   ├── StumpHome001  Node2D  (stump_shrine.gd, y_sort_offset=12)
│   ├── WillowTree  Node2D  (willow_tree.gd, y_sort_offset=53)
│   ├── [Pine/Maple/Fir tree instances, y_sort origin=trunk base]
│   ├── [Shadow Node2D children on Well, PlayerHome, Plant, DryingRack, Rock]
│   ├── HouseGlowBack/Left/Right/Front  PointLight2D (x4, amber night lights)
│   └── NPCHomeDoor  Area2D
├── CanvasModulate  (day/night ambient color)
├── Sun  DirectionalLight2D  (range_item_cull_mask=3)
├── DayNight  Node  (DayNightCycle.gd)
└── Overhead  Node2D  (z_index=2, roof overlay sprites)

Interior scenes (loaded on transition):
  res://World/PlayerHome/interior.tscn  (interior.gd, 160×128)
  res://World/NPCHome/interior.tscn     (interior.gd, 160×128)
```

---

## Autoload Singletons

| Name | Script | Layer | Purpose |
|---|---|---|---|
| `TransitionManager` | `autoload/TransitionManager.gd` | — | Fade-to/from-black screen transitions |
| `InventoryManager` | `autoload/InventoryManager.gd` | — | 12-slot hotbar + 36-slot grid, signal-based |
| `ShrineManager` | `autoload/ShrineManager.gd` | — | Legacy trust system (now mostly unused; shrine logic in stump_shrine.gd) |
| `HUD` | `UI/hud.gd` | CanvasLayer 10 | Water bar, hotbar, toast notifications |
| `Inventory` | `UI/inventory.gd` | CanvasLayer 20 | Full inventory grid overlay (Tab/I) |
| `Shop` | `UI/shop.gd` | CanvasLayer 20 | Shop overlay (Esc to close) |
| `BetterTerrain` | addon | — | Terrain tileset plugin |
| `MCPScreenshot/InputService/GameInspector` | addon | — | MCP AI dev tools |

---

## Core Systems

### Player (`player.gd`)
- `CharacterBody2D`, `MOTION_MODE_FLOATING`
- Movement priority: `auto_walk` (door transition) → `nav_agent` path → keyboard input
- Exposes: `facing: Facing`, `is_moving`, `is_chopping`, `is_trading`, `equipped_tool: String`, `carrying_water`
- Animation driven by `player_animation.gd` (AnimatedSprite2D child) reading parent state each frame

### Navigation (ADR-097/098/099)
- `NavigationRegion2D` (`NavRegion`) baked in `world.tscn` — must rebake after adding/moving StaticBody2D obstacles
- Player has `NavigationAgent2D` (`NavAgent`) child; `world.gd` calls `nav_agent.set_target_position()` on left-click
- GreyHoodie also has `NavigationAgent2D` for waypoint patrol
- Interior scenes use simple `auto_walk` vector (no nav mesh)

### Interactable System (`world.gd`)
- `_interactables: Array[Node]` — nodes registered via `interactable_entered/exited` signals
- `_get_nearest_interactable()` — by `distance_squared_to` from player
- Space key triggers `interact(player)` on nearest; can check `can_interact()` and `blocked_message()`

### Inventory (`InventoryManager.gd`)
- `HOTBAR_SLOTS=12`, `GRID_SLOTS=36`, `MAX_STACK=16`
- Slot 0 = reserved bucket slot
- `add_item(key, tex)` — stacks hotbar first, then grid, then new slot
- Emits `slot_changed(index, item)` signal → HUD and Inventory UI update

### Tree Chopping (`choppable_tree.gd`)
- State machine: `IDLE → CHOPPING → FALLING → STUMP`
- Self-registers to `"choppable_trees"` group in `_ready()`
- `can_interact()` requires `player.equipped_tool == "axe"`
- Emits `tree_chopped` → `world.gd` adds wood to inventory

### Plant Growth (`plant.gd`)
- 4 stages gated by `player.carrying_water`
- Water consumed on interact; `plant_harvested` signal → DryingRack.add_plant()

### Drying Rack (`drying_rack.gd`)
- State machine: `EMPTY → FILLING → DRYING (5s) → READY (1.5s golden pulse)`
- Awards random bud texture from `PRODUCTS[8]` array via `InventoryManager`

### Fay Grove Exchange (`stump_shrine.gd`)
- Passive: scans `"world_drop_items"` group within 60px radius
- Drop sequence: IDLE → ITEM_PRESENT (player steps away) → PROCESSING (10s) → REWARD_SPAWNED → auto-collect on re-entry
- Exchange table: bud/stone_pile/wood → 40% processed / 60% double-raw

### NPC GreyHoodie (`npc_grey_hoodie.gd`)
- `CharacterBody2D` with `NavigationAgent2D` waypoint patrol (2 waypoints in World-local coords)
- States: walking, idle, trading, entering/inside home
- Trade: player must have `bud`, receives `gem`; NPC then walks home for 1 day cycle
- `is_interactable()` guard: false during trade animation or if trade already completed

### Forest Creature ShT (`forest_creature.gd`)
- States: `TREE_HOP` (wanders between trees) / `FLEE` (when player within 64px)
- Flee hysteresis: exits FLEE only at 90px distance
- Panic burst at <28px or fast player approach
- Stuck detection: teleports off-screen if stuck 3× in 0.35s intervals
- Boundary: stays within MAP_MIN/MAX (MAP_MAX_Y=445, top of brick wall)

### Day/Night Cycle (`DayNightCycle.gd`)
- 120s total; night runs 2× speed (t<0.28 or t>0.80) → ~29s night, ~62s day
- Drives: `CanvasModulate` color, `DirectionalLight2D` energy/rotation/color
- Exposes `shadow_dir`, `shadow_alpha`, `shadow_length_factor` for `object_shadow.gd`

### Dynamic Shadows (`object_shadow.gd`)
- Attach as child Node2D; reads DayNight group lazily in `_process()`
- Draws flat horizontal oval (no rotation) with halo+core two-pass rendering
- `z_as_relative=false`, `z_index=0`, `show_behind_parent=true`

### Scene Transitions (`TransitionManager.gd`)
- `await TransitionManager.fade_to_black(0.4)` before `change_scene_to_file()`
- `TransitionManager.fade_from_black(0.4)` in destination `_ready()`
- Cross-scene state via `Engine.set_meta("spawn_position", Vector2)`

---

## Depth Sorting

- `World` node: `y_sort_enabled=true` — all world objects sorted by Y position
- `y_sort_offset` tuned per node so sort transition = bottom of visible wall face
- Trees: origin at trunk base (no y_sort_offset); TreeSprite child at `position.y = -22`
- Player: `y_sort_offset=14` (baked in player.tscn)
- `Overhead` Node2D at `z_index=2` in main.tscn renders roof overlays above all world Y-sort

---

## Input Map

| Key | Action | Handler |
|---|---|---|
| Arrow / WASD | ui_left/right/up/down | player.gd physics_process |
| Shift | run | player.gd |
| Space | interact | world.gd _input |
| T | npc_trade | world.gd _input |
| C | equip_toggle | world.gd _input |
| Q | drop_item | world.gd _input |
| 1-0 | hotbar slot select | hud.gd _unhandled_input |
| Mouse wheel | hotbar cycle | hud.gd _unhandled_input |
| Left click | navigate / click-nav | world.gd _input → nav_agent |
| Tab / I | inventory toggle | inventory.gd _input |

---

## Physics Collision Layers

- Layer 1: terrain/static obstacles (buildings, rocks, trees)
- Layer 2: player + NPCs + creatures
- `range_item_cull_mask=1` on house lights (excludes buildings); `=3` on Sun (includes buildings)

---

## Known Architecture Notes

- `ShrineManager` autoload is now unused (stump_shrine.gd owns all grove logic); harmless to keep
- `_inv_mgr` in world.gd uses `get_node_or_null("/root/InventoryManager")` — can simplify to bare `InventoryManager` after editor restart
- Nav mesh is static — must rebake `NavRegion` node when adding/moving StaticBody2D obstacles
- `y_sort_offset` is a `.tscn` serialization field only (not a GDScript runtime property)
