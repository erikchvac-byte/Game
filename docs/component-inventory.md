# Game — Component Inventory

All authored game components (scripts). Addon scripts excluded.

---

## Entry Points

| Scene/Script | Root Type | Purpose |
|---|---|---|
| `main.tscn` / `main.gd` | Node2D | App root; handles spawn position from interior exit |
| `World/world.tscn` / `world.gd` | Node2D | Main gameplay scene — all world logic lives here |

---

## Autoload Singletons

| Name | Script | Base Type | Singleton Role |
|---|---|---|---|
| TransitionManager | `autoload/TransitionManager.gd` | Node | Black-screen fade transitions |
| InventoryManager | `autoload/InventoryManager.gd` | Node | 48-slot item storage + signals |
| ShrineManager | `autoload/ShrineManager.gd` | Node | Legacy trust/exchange (unused) |
| HUD | `UI/hud.gd` | CanvasLayer | Top bar + hotbar + toast |
| Inventory | `UI/inventory.gd` | CanvasLayer | Full grid inventory overlay |
| Shop | `UI/shop.gd` | CanvasLayer | Shop overlay skeleton |
| GameState | `autoload/GameState.gd` | (class, not autoload) | Static spawn position vars |

---

## Player

| Script | Base Type | Key Exports / API |
|---|---|---|
| `Player/player.gd` | CharacterBody2D | `facing: Facing`, `equipped_tool: String`, `is_moving`, `is_chopping`, `is_trading`, `carrying_water`, `auto_walk`, `nav_agent` |
| `Player/player_animation.gd` | AnimatedSprite2D | Reads parent state each `_process`; drives animation name + flip_h |

---

## World Systems

| Script | Base Type | Signals Out | Key Behaviour |
|---|---|---|---|
| `World/world.gd` | Node2D | — | Interactable array, nav click-routing, NPC proximity, door transitions |
| `World/object_shadow.gd` | Node2D | — | Reusable ellipse shadow; reads DayNightCycle group |
| `autoload/DayNightCycle.gd` | Node | — | 120s cycle; drives CanvasModulate + Sun; exposes shadow data |

---

## Interactables

| Script | Base Type | Signals Out | Interaction Pattern |
|---|---|---|---|
| `Interactables/well.gd` | Node2D | `interactable_entered`, `interactable_exited` | `can_interact`: !carrying_water; sets `player.carrying_water=true` |
| `Interactables/drying_rack.gd` | Sprite2D | — (awards via InventoryManager) | `add_plant()` public method; 4-state timer machine |
| `Plants/plant.gd` | Node2D | `interactable_entered`, `interactable_exited`, `plant_harvested` | Water-gated 4-stage growth; emits plant_harvested on completion |
| `scenes/interactables/trees/choppable_tree.gd` | StaticBody2D | `interactable_entered`, `interactable_exited`, `tree_chopped` | Axe required; 3-chop state machine; auto-registers to `"choppable_trees"` group |

---

## NPCs & Creatures

| Script | Base Type | Signals / Group | Behaviour |
|---|---|---|---|
| `NPCs/npc_grey_hoodie.gd` | CharacterBody2D | — | 2-waypoint nav patrol; bud→gem trade; enters home after trade |
| `World/ForestCreature/forest_creature.gd` | CharacterBody2D | — | TREE_HOP / FLEE AI; stuck detection + off-screen teleport |
| `World/WillowTree/willow_tree.gd` | Node2D | — | One-shot proximity shake; 120s cooldown |
| `World/StumpShrine/stump_shrine.gd` | Node2D | `"shrine"` | Drop-and-exchange loop; scans `"world_drop_items"` group |

---

## World Objects

| Script | Base Type | Group | Behaviour |
|---|---|---|---|
| `World/WorldDropItem/world_drop_item.gd` | Node2D | `"world_drop_items"` | Meta-driven (item_key, item_tex); 30-90s despawn timer; `consume()` API |

---

## UI Components

| Script | Base Type | Layer | Public API |
|---|---|---|---|
| `UI/hud.gd` | CanvasLayer | 10 | `set_water()`, `show_interact_prompt()`, `show_trade_prompt()`, `show_toast()`, `set_equipped_slot()`, `set_slot_texture()` |
| `UI/inventory.gd` | CanvasLayer | 20 | `open()`, `close()`, `toggle()`; Tab/I/Esc keys; reads InventoryManager slot_changed |
| `UI/shop.gd` | CanvasLayer | 20 | `open()`, `close()`; layout skeleton only (not functional) |

---

## Interior Scenes

| Script | Base Type | Purpose |
|---|---|---|
| `World/PlayerHome/interior.gd` | Node2D | Bakery interior; click-nav; exit → spawn at (112, 150) |
| `World/NPCHome/interior.gd` | Node2D | NPC home interior; click-nav; exit → spawn at (534, 140) |

---

## Dev Tools

| Script | Type | Purpose |
|---|---|---|
| `tools/collision_validator.gd` | EditorScript | Validates y_sort_offset values against expected table; run via execute_editor_script |

---

## Reuse Patterns

### Adding a new interactable
Implement these methods/signals:
```gdscript
signal interactable_entered(node: Node)
signal interactable_exited(node: Node)
func can_interact(player: CharacterBody2D) -> bool
func blocked_message(player: CharacterBody2D) -> String
func interact(player: CharacterBody2D) -> void
```
Then connect in `world.gd._ready()`.

### Adding a new item type
```gdscript
InventoryManager.add_item("my_key", preload("res://assets/props/items/my_item.png"))
```

### Adding a new equippable tool
```gdscript
# world.gd
const EQUIPPABLE_TOOLS := {
    "axe": "equip_toggle",
    "my_tool": "my_action",  # ← add this
}
# Also add InputMap action "my_action" in project settings
```
