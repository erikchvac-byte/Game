# Game — State Management

## Overview

State is distributed across four mechanisms:

1. **Autoload singletons** — in-memory state for the current session
2. **Engine.set_meta / get_meta** — cross-scene transient state (cleared on exit)
3. **Static class vars** — minimal (`GameState.gd`)
4. **Scene tree position** — player position is the state for most things

There is currently **no save/load system**. All state resets on game exit.

---

## In-Memory State (Autoloads)

### InventoryManager
```gdscript
_slots: Array  # size=48 (12 hotbar + 36 grid)
# Each slot: null | ItemEntry{key: String, tex: Texture2D, count: int}
```
- Slot 0: reserved bucket slot (permanent)
- Slots 1–11: hotbar (actively used, hotkey-accessible)
- Slots 12–47: grid inventory
- Mutations: `add_item(key, tex)`, `remove_item(key)`, `has_item(key)`, `get_slot(index)`
- Signal: `slot_changed(index, item)` → HUD and Inventory UI

### HUD
```gdscript
water: int         # Current water level (0 = empty)
water_max: int     # Max water capacity (default 10)
selected_slot: int # Currently selected hotbar slot
```

### ShrineManager (legacy, mostly unused)
```gdscript
trust: int  # 0-100; persisted via Engine.set_meta("shrine_trust")
```

---

## Cross-Scene State (Engine.meta)

Used for state that must survive `change_scene_to_file()`:

| Key | Type | Set by | Read by | Purpose |
|---|---|---|---|---|
| `spawn_position` | `Vector2` | interior.gd on exit | main.gd _ready | Player spawn after interior exit |
| `shrine_trust` | `int` | ShrineManager._add_trust | ShrineManager._ready | Trust level persistence |
| `starting_items_granted` | `bool` | world.gd | world.gd | One-time axe/stone/bud grant |

---

## Per-Node State (not persisted)

Key state variables on live nodes:

| Node | Variable | Type | Meaning |
|---|---|---|---|
| Player | `facing` | `Facing` enum | DOWN/UP/SIDE |
| Player | `equipped_tool` | String | `""` or `"axe"` |
| Player | `carrying_water` | bool | Has water bucket |
| Player | `is_chopping` | bool | In chop animation |
| Player | `is_trading` | bool | In trade animation |
| Player | `auto_walk` | Vector2 | Door-transition velocity override |
| DryingRack | `_state` | `State` enum | EMPTY/FILLING/DRYING/READY |
| DryingRack | `_count` | int | 0-3 plants loaded |
| Plant | `_stage` | int | 0-3 growth stage |
| ChoppableTree | `_state` | `State` enum | IDLE/CHOPPING/FALLING/STUMP |
| ChoppableTree | `_chops_done` | int | Chops accumulated |
| StumpShrine | `_state` | `State` enum | IDLE/ITEM_PRESENT/PROCESSING/REWARD_SPAWNED |
| GreyHoodie | `_trade_completed` | bool | Has traded this day cycle |
| GreyHoodie | `_inside_home` | bool | Currently in home (invisible) |
| ForestCreature | `_state` | `State` enum | TREE_HOP/FLEE |
| WillowTree | `_played` | bool | Shake animation played |

---

## What Does NOT Persist

- Player position on scene exit (world re-entry uses `Engine.get_meta("spawn_position")` or default)
- Inventory contents
- Tree chop state (trees respawn on scene reload)
- Plant growth stage
- Day/night cycle time (starts at `start_time=0.35` each run)
- NPC position (GreyHoodie starts at waypoint 1 on each scene load)

---

## Adding Persistence (Future)

To add save/load, the best approach is:
1. Create a `SaveManager` autoload
2. On save: serialize `InventoryManager._slots`, player position, tree states, day time into a JSON/binary file
3. On load: restore from file before scene tree is ready

The `Engine.set_meta` pattern used for `spawn_position` is intentionally transient — do not use it for save data.
