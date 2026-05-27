# Game — Source Tree Analysis

Root: `C:/Users/erikc/Dev/Game/game/`

```
game/
├── project.godot                   # Engine config; autoloads, input map, display settings
├── main.tscn                       # App entry — handles spawn_position meta, fades in
├── main.gd                         # Entry script: spawn pos + fade-in
│
├── World/                          # Outdoor world + all sub-systems
│   ├── world.tscn                  # Main world scene (y_sort, nav mesh, all entities)
│   ├── world.gd                    # World controller: input, interactables, nav, NPC proximity
│   ├── object_shadow.gd            # Reusable shadow Node2D (reads DayNight group)
│   │
│   ├── PlayerHome/
│   │   └── interior.tscn           # Bakery interior (160×128, own Camera2D limits)
│   │   └── interior.gd             # Interior: click-nav, exit door → main.tscn
│   │
│   ├── NPCHome/
│   │   └── interior.tscn           # GreyHoodie's home (same layout as PlayerHome)
│   │   └── interior.gd             # Same as PlayerHome interior.gd (exit → spawn at NPC door)
│   │
│   ├── ForestCreature/
│   │   ├── forest_creature.tscn    # ShT CharacterBody2D (CreatureSprite AnimatedSprite2D)
│   │   └── forest_creature.gd      # AI: TREE_HOP / FLEE states, stuck detection, teleport
│   │
│   ├── StumpShrine/
│   │   ├── stump_home_001.tscn     # Ancient stump scene (y_sort_offset=12)
│   │   └── stump_shrine.gd         # Fay Grove drop-and-exchange 4-state machine
│   │
│   ├── WillowTree/
│   │   ├── willow_tree.tscn        # Landmark willow (scale=(2.975,2.5), ProximityArea)
│   │   └── willow_tree.gd          # One-shot shake on player proximity; 120s reset
│   │
│   └── WorldDropItem/
│       ├── world_drop_item.tscn    # Droppable item (Sprite2D + DespawnTimer + Area2D)
│       └── world_drop_item.gd      # group="world_drop_items"; meta-driven; 30-90s despawn
│
├── Player/
│   ├── player.tscn                 # CharacterBody2D (CollisionShape2D, AnimatedSprite2D,
│   │                               #   NavAgent, Camera2D, y_sort_offset=14)
│   └── player.gd                   # Movement (auto_walk → nav_agent → keyboard), facing enum
│
├── autoload/                       # Global singletons (declared in project.godot)
│   ├── DayNightCycle.gd            # 120s cycle; ambient color + sun energy; shadow data
│   ├── GameState.gd                # Static vars: spawn_position, use_custom_spawn (minimal use)
│   ├── InventoryManager.gd         # 12 hotbar + 36 grid slots; key+tex+count; slot_changed signal
│   ├── ShrineManager.gd            # Legacy trust+exchange (now unused; stump_shrine.gd owns it)
│   └── TransitionManager.gd        # Fade overlay CanvasLayer layer=100
│
├── UI/                             # All CanvasLayer UI (registered as autoloads)
│   ├── hud.gd                      # CanvasLayer 10: water bar, 12-slot hotbar, toast
│   ├── inventory.gd                # CanvasLayer 20: 36-slot grid overlay (Tab/I)
│   └── shop.gd                     # CanvasLayer 20: shop overlay skeleton (Esc)
│
├── Interactables/
│   ├── drying_rack.gd              # 4-state Sprite2D; 3-plant → 5s dry → random bud reward
│   └── well.gd                     # Water-fill interactable; sets player.carrying_water
│
├── Plants/
│   └── plant.gd                    # 4-stage growth gated by water; emits plant_harvested
│
├── NPCs/
│   └── npc_grey_hoodie.gd          # CharacterBody2D: 2-waypoint patrol, bud→gem trade, home cycle
│
├── scenes/
│   └── interactables/
│       └── trees/
│           ├── choppable_tree.gd   # Base tree: IDLE→CHOPPING→FALLING→STUMP state machine
│           ├── pine_tree.tscn      # Pine species (pine_frames.tres)
│           ├── maple_tree.tscn     # Maple species (maple_frames.tres)
│           └── fir_tree.tscn       # Fir species (fir_frames.tres)
│
├── tools/
│   └── collision_validator.gd      # Editor script: validates y_sort_offset values in .tscn files
│
├── resources/
│   ├── characters/
│   │   ├── erik_sprites.tres       # Player SpriteFrames
│   │   ├── grey_hoodie_sprites.tres # NPC SpriteFrames
│   │   └── hobo_man_sprites.tres   # ForestCreature SpriteFrames
│   └── tilesets/
│       ├── GrassBrick_OVERLAYS__tileset.tres  # Main world tileset
│       ├── interior_tileset.tres              # Interior tileset
│       └── [other .tres tilesets]
│
├── assets/                         # All in-project art (organized by type)
│   ├── characters/                 # Player (erik), GreyHoodie, ForestCreature, alts
│   ├── nature/                     # Trees, stumps, rocks, bushes, plants
│   ├── props/                      # Bud, drying_rack, furniture, items, well
│   ├── structures/                 # Buildings (bakery, teal house, grove stumps)
│   ├── tiles/                      # Ground tiles (16×16), interior, 32×32
│   └── ui/                         # WaterGem, WaterMeterBar, bucket icons
│
├── addons/                         # Editor plugins (not game logic)
│   ├── godot_mcp/                  # MCP Pro AI dev bridge
│   ├── tile_bit_tools/             # Tileset bit-pattern helper
│   ├── better-terrain/             # Terrain auto-tiler
│   ├── AsepriteWizard/             # .ase → SpriteFrames importer
│   ├── retiler/                    # Tilemap retiling utility
│   └── palette_enforcer/           # Pixel art color palette enforcer
│
└── GDScript/                       # Third-party script utilities
    └── addons/YATI/                # Tiled (.tmx) map importer
```

## Critical Entry Points

| Path | Purpose |
|---|---|
| `main.tscn` | App root — handles cross-scene spawn position |
| `World/world.tscn` | Main gameplay scene — load this to play |
| `Player/player.tscn` | Instanced into world.tscn; owns camera |
| `project.godot` | Autoloads, input map, window settings |

## Key Resource Files

| Path | Purpose |
|---|---|
| `resources/characters/erik_sprites.tres` | Player animation frames |
| `resources/tilesets/GrassBrick_OVERLAYS__tileset.tres` | Active world tileset |
| `resources/tilesets/interior_tileset.tres` | Interior room tileset |
| `scenes/interactables/trees/pine_tree.tscn` | Reusable pine tree instance |
