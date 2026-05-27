# Game — Project Overview

**Type:** Monolith Godot 4 game  
**Engine:** Godot 4.6.2-stable, Forward+, D3D12 (Windows)  
**Language:** GDScript  
**Authored:** 2026-05-27

## Executive Summary

A top-down 2D life-sim / action game (pixel art, 32×180 logical viewport). The player explores a small outdoor world, chops trees, waters plants, dries harvests, and interacts with a shy forest creature (ShT) who runs a cryptic grove exchange. One NPC (GreyHoodie) patrols between the bakery and the player's starting area, offering bud→gem trades. A full day/night cycle with directional shadow rendering drives the world's atmosphere.

The project is in mid-prototype stage: core gameplay loops are functional, content (interiors, NPCs, more biomes) is being added.

## Technology Stack

| Category | Technology | Notes |
|---|---|---|
| Engine | Godot 4.6.2-stable | Forward+, D3D12 on Windows |
| Language | GDScript | Typed, strict |
| Renderer | Forward+ | Nearest-filter pixel art |
| Viewport | 320×180 → 1280×720 | canvas_items/keep stretch |
| Physics | Godot built-in 2D + Jolt (3D) | 2D only actively used |
| Nav | Godot NavigationRegion2D | Baked nav mesh in world.tscn |

## Architecture Classification

- **Pattern:** Scene-component (Godot nodes) + singleton autoloads for cross-scene state
- **Repository:** Monolith (single Godot project at `game/`)
- **Entry point:** `res://main.tscn` → `main.gd`

## Project Structure Summary

```
game/
├── main.tscn / main.gd          # App entry point — spawn position handling
├── project.godot                 # Godot project config + autoloads
├── World/
│   ├── world.tscn / world.gd    # The main outdoor world scene
│   ├── PlayerHome/              # Bakery interior
│   ├── NPCHome/                 # GreyHoodie's home interior
│   ├── ForestCreature/          # ShT AI (elusive creature)
│   ├── StumpShrine/             # Fay Grove exchange system
│   ├── WillowTree/              # Proximity-animated landmark
│   └── WorldDropItem/           # Droppable item scene
├── Player/                      # Player CharacterBody2D + animation
├── autoload/                    # Global singletons
├── UI/                          # HUD, Inventory, Shop (CanvasLayer nodes)
├── Interactables/               # Well, DryingRack
├── Plants/                      # Plant growth system
├── NPCs/                        # GreyHoodie patrol + trade logic
├── scenes/interactables/trees/  # ChoppableTree + 3 species scenes
├── assets/                      # All in-project PNGs, organized by category
├── resources/                   # SpriteFrames .tres, TileSets .tres
└── addons/                      # Editor plugins (godot_mcp, tile_bit_tools, etc.)
```

## Key Links

- [Architecture](./architecture.md) — Scene hierarchy, systems, patterns
- [Source Tree Analysis](./source-tree-analysis.md) — Annotated directory tree
- [Development Guide](./development-guide.md) — Setup and run instructions
- [Asset Inventory](./asset-inventory.md) — All in-project art assets
- [State Management](./state-management.md) — How game state is stored
