# ADR — Game

**Overview:** Survival-to-farming 2D game built in Godot 4.6. Player directs from terminal; Claude drives execution via MCP tools.

**Perspective:** Top-down oblique — Zelda: A Link to the Past style. Camera elevated at a slight angle; characters show top + front face. 4-directional facing (down/side/up; left = side + flip_h). Not isometric, not pure bird's-eye.

---

## Stack

| Tool | Role |
|---|---|
| Godot MCP Pro 1.12.0 | Scene building, tilemap setup, script wiring |
| Filesystem MCP | Asset organization, file movement |
| PixelLab MCP Pro | Asset generation, character iteration |
| GitHub (`gh` CLI) | Version control — repo at github.com/erikchvac-byte/Game |
| Aseprite | Manual touch-ups only — no automation |

Asset pack: `GameAssets/` — ~800 PNG files, 16×16 tiles, 59×49 player sprites

---

## ADR-001: Engine Choice — Godot 4.6
**Status:** Accepted
**Date:** 2026-04-25
**Context:** Need a 2D game engine with strong MCP tooling support and a pixel art workflow.
**Decision:** Godot 4.6, Forward Plus renderer, D3D12 (Windows), Jolt Physics (3D setting — irrelevant for 2D).
**Rationale:** Godot MCP Pro 1.12.0 exposes 172 editor commands via WebSocket. Text-based scene/resource formats (.tscn, .tres, .gd) are fully writable by AI tooling without a running editor.
**Consequences:** Forward Plus is heavier than Compatibility mode but acceptable for PC target. Jolt physics setting is harmless for a 2D game.

---

## ADR-002: 2D Physics Body — CharacterBody2D
**Status:** Accepted
**Date:** 2026-04-25
**Context:** Player movement needs deterministic, game-feel control in a top-down oblique world.
**Decision:** CharacterBody2D with `motion_mode = MOTION_MODE_FLOATING`.
**Rationale:** Deterministic, no gravity interference, `move_and_slide()` (no args in Godot 4) handles collision cleanly. `MOTION_MODE_FLOATING` is required — default `GROUNDED` applies floor-snapping that breaks top-down movement.
**Consequences:** No physics-based momentum. Fine for Stage 1; revisit if feel needs tuning.

---

## ADR-003: Animation System — AnimatedSprite2D + SpriteFrames
**Status:** Accepted
**Date:** 2026-04-25
**Context:** Player has 9 directional animation strips (idle/walk/run × down/side/up) at 59×49px.
**Decision:** AnimatedSprite2D with a SpriteFrames resource. Separate `player_animation.gd` on the AnimatedSprite2D node reads state vars from the parent CharacterBody2D.
**Rationale:** Simpler than AnimationPlayer for sprite strips. Separation keeps movement script under ~80 lines. Animation script uses a `_current_anim` guard to prevent per-frame `play()` resets. Left direction = `"side"` + `flip_h = true` (no extra animation needed).
**Consequences:** No blend trees or transitions — acceptable for Stage 1.

---

## ADR-004: TileMap — TileMapLayer (not TileMap)
**Status:** Accepted
**Date:** 2026-04-25
**Context:** Ground tileset needed for world scene.
**Decision:** `TileMapLayer` node (Godot 4.3+), separate node per layer. `TileSet` as a standalone `.tres` resource.
**Rationale:** `TileMap` is deprecated in Godot 4.3+. `TileMapLayer` is the current API. Each layer = one node, making z-ordering and layer management explicit.
**Consequences:** More nodes than old TileMap for multi-layer maps. Acceptable.

---

## ADR-005: MCP Connection — Node.js Bridge Server
**Status:** Accepted
**Date:** 2026-04-25
**Context:** Godot MCP Pro ships with a standalone Node.js server (`server/build/index.js`) that bridges Claude Code (stdio MCP) to Godot's WebSocket endpoint. Godot connects to this server; Claude Code starts it as an MCP subprocess.
**Decision:** Custom bridge at `C:/Users/erikc/Dev/Game/mcp-bridge/index.js`. Registered in `.claude/settings.json` as `"godot-mcp-pro"`.
**Rationale:** Original pre-built server binary was missing. Built a replacement that listens on WebSocket ports 6505-6514 (same as what Godot's plugin connects to) and speaks MCP stdio for Claude Code. Uses `ws` npm package. Tool list derived from all `get_commands()` registrations in the GDScript command files. Flexible `additionalProperties: true` schema passes any params through to Godot.
**Consequences:** Godot editor must be open with MCP Pro plugin active. Claude Code must be restarted to pick up the new MCP server on each session. Bridge lives in the project repo — no external binary dependency.

---

## ADR-006: Base Resolution — 320×180
**Status:** Accepted
**Date:** 2026-04-25
**Context:** Pixel art game needs a low base resolution that scales cleanly to modern monitors.
**Decision:** 320×180 viewport, 1280×720 window, `stretch/mode = canvas_items`, `stretch/aspect = keep`.
**Rationale:** 320×180 is exactly 4× to 1280×720 (4K-friendly at 8×). `canvas_items` stretch mode scales individual pixels without blurring when combined with Nearest texture filter.
**Consequences:** All UI and world elements must be designed for 320×180 logical pixels.

---

## Technical Constraints
- Windows 11, Godot 4.6 required (no cross-platform target yet)
- All sprites pixel art — texture filter must be Nearest globally
- Never edit `project.godot` directly — use `set_project_setting` via Godot MCP
- Godot must be open for any MCP scene/script operations

---

## ADR-009: Main Scene Structure — Minimal Instance Format
**Status:** Accepted
**Date:** 2026-04-26
**Context:** M6 needed a Main scene composing World + Player. Using `execute_editor_script` with `PackedScene.pack()` expanded instanced scenes inline, duplicating tile data and breaking unique_ids — Player didn't appear at runtime.
**Decision:** Write `main.tscn` directly using the minimal Godot scene instance format: `instance=ExtResource(...)` with no child node overrides.
**Rationale:** The minimal format keeps each scene self-contained. Child nodes and their properties stay in their own `.tscn` files; main.tscn only stores the instance references and top-level property overrides (e.g. `position`).
**Consequences:** Future changes to world.tscn or player.tscn are automatically reflected in main.tscn with no re-save needed.

---

## Stage 1 — Milestones
| # | Milestone | Status |
|---|-----------|--------|
| M0 | Project settings + asset copy | ✅ Done |
| M1 | SpriteFrames resource | ✅ Done |
| M2 | Player scene (no script) | ✅ Done |
| M3 | player.gd movement script | ✅ Done |
| M4 | player_animation.gd | ✅ Done |
| M5 | World scene + TileMapLayer | ✅ Done |
| M6 | Main scene + camera limits | ✅ Done |

---

## ADR-008: Player Movement Speeds — Walk 60 / Run 110 px/s
**Status:** Accepted
**Date:** 2026-04-25
**Context:** player.gd needed concrete speed values for walk and run at 320×180 (16×16 tiles).
**Decision:** `WALK_SPEED = 60.0`, `RUN_SPEED = 110.0` px/s. Run triggered by Shift key (`run` input action).
**Rationale:** 60px/s ≈ 3.75 tiles/s walk; 110px/s ≈ 6.875 tiles/s run. Feels natural for top-down oblique at this resolution. Values are tunable — exposed as constants at top of script.
**Consequences:** Revisit during playtesting. `facing_left` bool on player root lets animation script drive `flip_h` without duplicating direction logic.

---

## ADR-007: Animation FPS — Idle 6 / Walk 8 / Run 12
**Status:** Accepted
**Date:** 2026-04-25
**Context:** SpriteFrames resource needed frame rates for each animation tier.
**Decision:** Idle = 6fps, Walk = 8fps, Run = 12fps. All 9 animations loop continuously.
**Rationale:** Snappy without jitter at 320×180. Standard pixel-art game feel hierarchy — idle slower, run fastest.
**Consequences:** Revisit if walk feels too slow or run too frantic during playtesting.

---

## Testing Results
- M0: Project settings verified via `get_project_info` — 320×180 viewport, 1280×720 window confirmed.
- M1: SpriteFrames created via `execute_editor_script` — all 9 animations loaded and saved with correct frame counts.
- M2: Player scene created — CharacterBody2D root, CollisionShape2D (CapsuleShape2D r=4 h=12), AnimatedSprite2D with SpriteFrames attached. `motion_mode = MOTION_MODE_FLOATING` confirmed.
- M3: player.gd validates clean. Script attached to Player root. `run` input action registered (Shift key).
- M4: player_animation.gd validates clean. Attached to AnimatedSprite2D. Fix required: explicit `var anim: String` annotation — Godot 4 type inference can't resolve string concat through an untyped parent reference.
- M5: World scene built — Node2D root, TileMapLayer (Ground), TileSet from Tile.png (240×192, 15×12 atlas at 16×16). 20×12 starter ground painted at atlas (0,0). `update_property` does not resolve resource paths — used `execute_editor_script` + `PackedScene.pack()` + `ResourceSaver.save()` pattern instead.
- M6: Main scene built — Node2D root instancing World + Player. Camera2D added to Player (child), limits (0,0,320,192), smoothing 8.0. Runtime verified: 240 tiles, idle_down playing, camera tracking. Stray Ground node removed from player.tscn. `PackedScene.pack()` unreliable for instanced scenes — write .tscn directly with minimal instance format instead.
- Post-M6 fixes: (1) Side sprite faces left by default → `flip_h = not player.facing_left`. (2) Tile atlas ground layout — Tile.png (15×12) uses cliff-edge bordered tiles for grass; only tile (9,1) is a seamlessly-tiling solid interior; bordered ground uses (6,0)/(8,0)/(10,0) top edge, (6,1)/(10,1) side edges, (9,1) interior. Pixel hashing via Python/PIL used to identify tiles.

---

## Known Issues
- None active.

---

## Open Questions
- None currently.

---

## ADR-010: Scene Transitions — get_tree().change_scene_to_file()
**Status:** Accepted
**Date:** 2026-04-27
**Context:** Player home needs bidirectional interior/exterior transitions.
**Decision:** `get_tree().change_scene_to_file(path)` for transitions. Cross-scene state (spawn position) passed via `Engine.set_meta()` / `Engine.get_meta()`. Interior is a self-contained scene with its own Player instance.
**Rationale:** `change_scene_to_file` works from any node in the tree. `Engine.set_meta()` is a built-in global that persists across scene changes without requiring an autoload — avoids the autoload-registration-at-runtime problem (new autoloads don't become globally visible to scripts until the next editor restart).
**Consequences:** Each location scene must have its own Player instance. Interior camera limits overridden at runtime in `_ready()`. A 0.4s delay before connecting `ExitDoor.body_entered` prevents immediate re-trigger on spawn.

---

## ADR-011: Interior Room Visuals — Polygon2D Background
**Status:** Accepted
**Date:** 2026-04-27
**Context:** Interior scene needed floor + wall visuals without a new tileset.
**Decision:** Two `Polygon2D` nodes at `z_index = -1`: dark brown wall rectangle (160×128), warm brown floor rectangle (128×96) inset 16px on all sides. The door gap in the south wall shows the dark wall color, reading as a doorway opening.
**Rationale:** `Polygon2D` renders correctly in world space within a Node2D scene. Avoids creating a new TileSet and painting tiles at this stage. Easy to replace with proper tiles later.
**Consequences:** Floor color is a placeholder. Proper interior tileset (from `GameAssets/interior/tiles.PNG`) deferred to later session.

---

## ADR-012: Ground Tileset Variety — FiveGrass + MabeyFive (10 tiles)
**Status:** Accepted
**Date:** 2026-04-28
**Context:** Initial ground used Tile.png and grass_stone_dirt.png tiles which looked uniform. A 32×32 Grasses.aseprite decoration overlay was tried but rejected (mixed plant/animal sprites with solid backgrounds). Two Aseprite files — FiveGrass.aseprite and MabeyFive.aseprite — each provide 5 clean 16×16 grass tile variants.
**Decision:** Replace all 960 ground cells with random tiles from FiveGrass (source 2, 5 variants) and MabeyFive (source 3, 5 variants). Each tile gets a random flip_h/flip_v alternative to break visual repetition. Removed decoration_tileset.tres and grasses_sheet.png.
**Rationale:** 10 base tiles × 4 transform alternatives = 40 effective visual variants. Pure random scatter with seed 77 produces natural-looking ground without checkerboard artifacts. No 32×32 sprites — all tiles are clean 16×16 ground textures.
**Consequences:** world_tileset.tres now has 3 sources (0=Tile.png, 1=grass_stone_dirt.png, 2=fivegrass.png, 3=mabeyfive.png). Tile.png and grass_stone_dirt.png are still referenced but no longer used for ground cells — available for other uses (paths, dirt, cliff edges).
**Testing:** Verified in-game — smooth organic green ground, no blank tiles, no checkerboard.

---

## Known Issues
- TileSet atlas creates ~1200 duplicate-tile errors in editor log on each project reload. These are from the M5 setup scripts running `create_tile()` for all 180 positions; tiles are already saved in `.tres`. Harmless — tilemap renders correctly.
- `class_name` conflicts with autoload names of the same string — avoid naming a class the same as any registered autoload.
- Godot auto-corrects invented UIDs in `.tscn` ext_resource entries to match what it assigns from `.gd.uid` files. Always use Godot-assigned UIDs or accept that Godot will correct them on next editor write.
- Editor UI interactions (Toggle Visible, Set enabled) during MCP sessions can accidentally set `enabled = false` / `visible = false` on nodes. Check .tscn files after execute_editor_script sessions that involve scene manipulation.

---

## Open Questions
- Exterior house has no collision on the "enter" path from west/east — camera/world limits naturally prevent this for now.
- Erik walk animations (PixelLab-generated) have not been playtested — quality may need iteration.

---

## ADR-013: Player Character — Erik (custom pixel art, 8-directional static + walk)
**Status:** Accepted
**Date:** 2026-04-28
**Context:** Original player used a generic asset-pack character (59×49 px, 9 animations). User provided a custom character "Erik" — 8 directional static sprites at 68×68 px. Diagonals dropped; 4 directions kept (N/S/E/W). Walk animations generated via PixelLab `animate_with_text` from resized 64×64 reference frames.
**Decision:** AnimatedSprite2D at scale=0.5. SpriteFrames `erik_sprites.tres` has 6 animations: idle_down/up/side + walk_down/up/side. Side animations use `flip_h` for left-facing. Walk frames: 4 per direction @ 8fps. Idle: 1 frame @ 6fps.
**Rationale:** Keeps existing player.gd architecture unchanged. Only player_animation.gd and player.tscn updated. `var dir: String` annotation required (Godot 4 can't infer type through untyped parent).
**Consequences:** Walk animations are AI-generated — quality may need refinement. Run animation deferred. All 16 walk frames + 4 idle frames live in `res://GameAssets/ErikPlayer/`.

---

## ADR-014: Scene Transitions — TransitionManager Autoload + Door Animation
**Status:** Accepted
**Date:** 2026-04-28
**Context:** Instant scene switches (no effect) felt jarring. Wanted a door-open animation before entering the house and a fade-to-black around all scene changes.
**Decision:** `TransitionManager` static autoload (`res://autoload/TransitionManager.gd`) owns a persistent `CanvasLayer` (layer=100) + `ColorRect`. Provides `await`-able `fade_to_black(duration)` and `fade_from_black(duration)`. `PlayerHomeDoor` upgraded from `Sprite2D` to `AnimatedSprite2D` with a 4-frame `open` animation (Door1-4.png, 8fps). Sequence: door animates (~0.5s) → fade to black (0.4s) → scene changes → fade from black in new scene.
**Rationale:** CanvasLayer autoload survives `change_scene_to_file()` — the only reliable way to keep an overlay across scene changes. Static autoload (declared in project.godot) differs from runtime `add_autoload` — it becomes globally visible immediately after project reload without editor restart. `set_physics_process(false)` on the player during the sequence prevents movement during the door/fade window. Signal disconnected before the first `await` to guard against double-trigger.
**Consequences:** All scene entry points must call `TransitionManager.fade_from_black()` (without await in `_ready()` so it fires in background). Fresh game start calls `fade_from_black(0.0)` as a safety no-op.

---

## ADR-015: Depth Sorting — Y-Sort on World + Overhead Layer
**Status:** Accepted
**Date:** 2026-04-28
**Context:** Player was rendering on top of the house roof when walking beside it at roof height (y < 126). The house and player were siblings under `Main` with `y_sort_enabled = true`, but `World` (containing the house) and `Player` are siblings — y-sort only works between direct siblings, not across subtrees. The entire `World` subtree always rendered before `Player` regardless of y-position.
**Decision:** Move `Player` into `world.tscn` as a direct sibling of `PlayerHome`. Enable `y_sort_enabled = true` on the `World` root node. Set `y_sort_offset = 30` on `PlayerHome` (sort y = 126, the eave line) and `y_sort_offset = -13` on `PlayerHomeDoor` (same sort y = 126). Keep a separate `Overhead` Node2D in `main.tscn` at `z_index = 2` with a `PlayerHomeRoof` sprite overlay.
**Rationale:** Y-sort sorts siblings by their effective Y position. With Player and house as siblings, the house renders after the player when `player.y < 126` (house in front = player behind roof) and the player renders after the house when `player.y > 126` (player in front = player approaching from south). Sort threshold at y=126 (eave line) feels correct — player begins going behind the building at the overhang, not at the door. The z=2 `Overhead` node in `Main` renders above everything and handles any remaining edge cases.
**Consequences:** Player must always be a child of `World`, not `Main`. `main.gd` accesses player via `$World/Player`. `world.gd` accesses player via `$Player`. Every future building in `world.tscn` must set `y_sort_offset` so its sort Y is at the "walkable in front" threshold (bottom of visible wall face). `Main` no longer needs `y_sort_enabled` — removed. Player default spawn position changed to (112, 200) (south of door).
**Testing:** Verified: player at y=170 appears in front of house; player at y=80 appears behind house. Door transition unaffected. UpperBlock replaced with WallCenter (58×30) sealing only the front wall gap between columns — roof zone (y:6–122) now fully walkable. Player at (112, 70) stays in position with physics active, hidden behind house sprite.

---

## ADR-016: Terrain Plugins — Better Terrain + TileBitTools
**Status:** Accepted
**Date:** 2026-05-03
**Context:** Manual tile placement for grass/dirt/water transitions requires placing corner/edge/center variants by hand. Wanted autotiling so painting a terrain type auto-selects the correct neighbor-aware tile.
**Decision:** Install [Better Terrain](https://github.com/Portponky/better-terrain) (Portponky) and [TileBitTools](https://github.com/dandeliondino/tile_bit_tools) (dandeliondino) as editor plugins. Both installed to `game/addons/`. Better Terrain folder must be `better-terrain` (hyphen) — plugin hardcodes that path for its autoload. Enabled in `project.godot` editor_plugins array. `BetterTerrain` autoload registered at `uid://0o8uu4vfmty7`.
**Rationale:** Better Terrain replaces Godot 4's built-in terrain system (slow, awkward API) with cleaner match-tiles/match-vertices modes and a bottom-panel Terrain dock. TileBitTools provides template-based bulk assignment of terrain peering bits — avoids clicking each tile variant individually in the editor.
**Consequences:** Editor restart required after first enable to register BetterTerrain autoload. Terrain bits still need to be assigned to `Tile.png` atlas tiles before autotiling works — next step is using TileBitTools to assign bits. `tile_bit_tools` folder contains a nested `tile_bit_tools/` subfolder (it's how the GitHub archive unpacked — harmless, plugin resolves from root `plugin.cfg`).

---

## ADR-018: Well Animation — Player-Triggered Reverse Playback
**Status:** Accepted
**Date:** 2026-05-04
**Context:** Static tile_025 well needed animation that activates only when player is nearby, plays in reverse, and blocks the player from walking through it.
**Decision:** Replaced Tile025 Sprite2D with WellWater AnimatedSprite2D (15 frames, 4 fps, loop). Added WellCollider StaticBody2D (CircleShape2D r=18) and WellArea Area2D (CircleShape2D r=26). Signals in world.gd: `body_entered` → `play_backwards("default")`, `body_exited` → `stop() + frame=0`. Moved entirely to world.tscn for y_sort depth sorting. y_sort_offset=24 so sort point is at well bottom.
**Rationale:** Well in world.tscn participates in y_sort with player. Area2D proximity is simpler than raycast. Reverse playback on approach gives a "drawing water" feel without a forward loop running at all times.
**Consequences:** Player cannot walk behind the well top. Animation only plays while player is in the 26px radius zone.

---

## ADR-019: PurplePunchOne Plant Animation
**Status:** Accepted
**Date:** 2026-05-04
**Context:** Static Tile024 Sprite2D (potted plant, 48×48) at (270, 95) needed replacing with the PurplePunchOne growth-to-bloom animation.
**Decision:** Replaced Tile024 Sprite2D with PurplePlant AnimatedSprite2D. 17 frames (Purple1, Purple2, Purple19–33) sourced from `GameAssets/PlantsGrow/PurplePunchOne/`. Speed set to 1.5 fps (very slow), loop=true, autoplay="default".
**Rationale:** Low speed (1.5 fps) gives a gentle ambient growth feel rather than a snappy animation. Looping the full growth-to-bloom cycle keeps the plant alive visually.
**Consequences:** Animation always plays (no proximity trigger). tile_024.png ext_resource removed from world.tscn; PNG file remains on disk but is unreferenced.

---

## ADR-017: Better Terrain Setup — 6 Terrain Types via Script
**Status:** Accepted
**Date:** 2026-05-03
**Context:** Better Terrain and TileBitTools were installed but terrain peering bits were unassigned. Needed to configure terrains programmatically to avoid slow UI workflow.
**Decision:** Configured all terrains via `execute_editor_script` using Better Terrain's GDScript API (`add_terrain`, `set_tile_terrain_type`, `add_tile_peering_type`). Added `Beach/Tiles/Tiles.png` as tileset source 4. Six terrains total:
- **0 Grass** — sources 2 (fivegrass, 20 tiles) + 3 (mabeyfive, 20 tiles) + Tile.png (9,1). All 8 peerings = grass. Plus 12 edge/corner tiles on Tile.png for grass↔dirt transitions.
- **1 Dirt** — Tile.png source 0, cols 6–10 row 3 (5 tiles). All peerings = dirt.
- **2 Water** — grass_stone_dirt source 1, cols 30–33 (4 blue tiles). All peerings = water.
- **3 Sand** — Beach/Tiles source 4, cols 6–11 rows 0–4 (30 tiles, light gray + orange). All peerings = sand.
- **4 Stone** — Beach/Tiles source 4, cols 0–2 rows 0–5 (18 tiles, blue-gray) + grass_stone_dirt cols 26–29 (4 gray tiles). All peerings = stone.
- **5 Cave** — Beach/Tiles source 4, cols 3–5 rows 0–5 (18 tiles, charcoal). All peerings = cave.
**Rationale:** Peering bit values for square MATCH_TILES: `[0, 3, 4, 7, 8, 11, 12, 15]` = RIGHT, BR_CORNER, BOTTOM, BL_CORNER, LEFT, TL_CORNER, TOP, TR_CORNER. All-peerings-same = center/fill tile. Grass edge tiles assigned with partial peering sets to drive autotile at grass↔dirt boundaries. Other terrain edges deferred — fill-only for now.
**Consequences:** Water/sand/stone/cave have no edge tiles yet — transitions between them will be abrupt (hard cut). Grass↔dirt has 12 edge/corner tiles giving smooth autotile transitions. TileBitTools Retiler not yet used — may revisit to re-tile existing map cells.

---

## ADR-020: Water Collection & Plant Growth Gameplay Loop
**Status:** Accepted
**Date:** 2026-05-05
**Context:** Needed first gameplay loop: player collects water from well, carries it to plant, waters plant one stage per trip, repeats 3 times to reach full growth.
**Decision:**
- `player.gd`: added `var carrying_water := false` flag
- `player_animation.gd`: appends `_bucket` suffix to animation name when `carrying_water` is true, switching to 6 bucket animations (walk_down/up/side_bucket, idle_down/up/side_bucket)
- `world.gd`: E key ("interact" action) triggers `_collect_water()` when near well, `_water_plant()` when near plant. Well uses timer-based fill (frame_count/fps seconds) not `await animation_finished` (doesn't fire on loop=true). Plant growth manually steps frames via `create_timer(1/fps)` per frame to avoid `play()` restarting from frame 0. `_collecting` and `_growing` flags prevent re-triggering mid-animation.
- `world.tscn`: added PlantArea (Area2D, 32px radius), PlantCollider (StaticBody2D, 6px radius — plant is solid), WellPrompt + PlantPrompt (Sprite2D key_e.png, hidden until in range), HUDLayer/BucketIcon (CanvasLayer showing full/empty bucket)
- Plant stages: frames [0, 5, 10, 16] — 3 waterings to full growth. Fully grown plant hides prompt permanently.
- Assets: east/west bucket walk = GIF frames 13-15 (3 frames, 8fps); north bucket walk = GIF frames 0-11 (12 frames, 8fps); south bucket walk = GIF frames 4-9 (6 frames, 8fps); south idle bucket = GIF frame 5 (1 frame). HUD icons from BucketFull PixelLab export. E key icon generated via PixelLab (32×32).
**Rationale:** Timer-based well fill is reliable regardless of animation loop setting. Manual frame stepping for plant avoids AnimatedSprite2D `play()` resetting to frame 0. PlantCollider added from the start per project rule (all objects need collision on placement). WellArea already existed and was reused.
**Consequences:** South walk bucket is a 6-frame cycle rather than a seamless loop — acceptable for now. Run animation still deferred. Bucket animations not save-persistent (reset on restart). No sound effects yet.

---

## ADR-021: HUD Architecture — Persistent Autoload CanvasLayers
**Status:** Accepted
**Date:** 2026-05-05
**Context:** Needed a permanent HUD (top bar + hotbar + toast) that survives scene changes (exterior ↔ interior). Previous approach was a HUDLayer node inside world.tscn, which disappeared on scene change.
**Decision:** Three static autoloads declared in project.godot: `HUD` (layer 10), `Inventory` (layer 20), `Shop` (layer 20). Each extends CanvasLayer and builds its UI tree programmatically in `_ready()`. Pattern follows existing TransitionManager autoload. `world.gd` accesses HUD via `get_node_or_null("/root/HUD")` at `_ready()` into an untyped `_hud` var — required because newly added autoloads aren't recognized by the GDScript parser until full editor restart; dynamic dispatch via untyped var resolves at runtime with no compile errors.
**Rationale:** Autoload CanvasLayer is the only pattern that persists across `change_scene_to_file()`. Programmatic node building (no .tscn) keeps the autoload self-contained. Untyped var + `get_node_or_null` avoids the editor restart requirement while keeping the code safe (null check guards every call).
**Consequences:** Editor will show stale parse errors for world.gd until restarted — ignore them, `validate_script` confirms clean compile. All future HUD calls from any scene use the same `/root/HUD` path.

---

## ADR-022: UI Component Design — Placeholder Colors, Asset-Ready Structure
**Status:** Accepted
**Date:** 2026-05-05
**Context:** User is producing assets separately and will supply them. UI needs to be functional and correct before assets arrive.
**Decision:** All placeholder visuals use `StyleBoxFlat` / `ColorRect` with solid colors. Top bar: water (blue dot + ColorRect fill bar), currency (gold dot + Label), energy (ColorRect fill bar + green dot). Hotbar: 12 Panel slots with StyleBoxFlat borders; selected slot highlighted gold. Toast: Panel + Label, fades via Tween. Inventory: 36-slot 6×6 GridContainer in a centered panel. Shop: two-panel HBoxContainer skeleton. Slot icons are `TextureRect` nodes — swap in textures via `HUD.set_slot_texture(slot, tex)`.
**Rationale:** ColorRect fill bars give pixel-perfect control over fill ratio (anchor_right = ratio). ProgressBar's default theme adds unwanted padding at 6px height. Programmatic construction means no .tscn dependency — assets drop in without scene edits.
**Consequences:** Font is Godot default (not pixel art) until user provides bitmap font. Bar fill uses anchor manipulation (`fill.anchor_right = ratio`) which requires the parent container to have a known size — may need adjustment if layout reflows.

---

## Future Considerations (Post Stage 1)
- Run animation — generate with PixelLab once walk quality confirmed
- Stage 2: NPCs, farming/crop system, day cycle
- Interior tileset: `GameAssets/interior/` has bed, furniture, carpet, kitchen assets ready to use
- Audio: no tool in stack yet — deferred
- GitHub MCP: not installed — using `gh` CLI directly (sufficient for now)

---

## Change Log
| Date | Change |
|------|--------|
| 2026-04-25 | ADR created. Project scoped, Stage 1 plan approved. |
| 2026-04-25 | MCP config corrected — using Godot MCP Pro Node.js bridge server. |
| 2026-04-25 | Built custom MCP bridge (mcp-bridge/index.js) — original binary was missing. |
| 2026-04-25 | Asset folder renamed from "SSEF Valley 1.1.2" to "GameAssets". |
| 2026-04-25 | M0 complete — project settings applied, GameAssets copied into res://. |
| 2026-04-25 | M1 complete — SpriteFrames resource built (9 anims, 42 total frames). ADR-007 added. |
| 2026-04-25 | GitHub repo initialized — github.com/erikchvac-byte/Game (private). Initial commit pushed. |
| 2026-04-25 | Permission allowlist added to .claude/settings.json (49 MCP + PowerShell entries). |
| 2026-04-25 | CLAUDE.md created with project reference (MCP params, asset layout, frame counts). |
| 2026-04-25 | M2 complete — Player scene built (CharacterBody2D + CollisionShape2D + AnimatedSprite2D). |
| 2026-04-25 | M3 complete — player.gd movement script written, validated, attached. ADR-008 added. |
| 2026-04-25 | M4 complete — player_animation.gd written, validated, attached to AnimatedSprite2D. |
| 2026-04-25 | M5 complete — World scene + TileMapLayer built. TileSet from Tile.png (15×12 atlas). 20×12 ground painted. |
| 2026-04-26 | M6 complete — Main scene + Camera2D. ADR-009 added (minimal .tscn instance format). |
| 2026-04-26 | Post-M6: fixed flip_h direction, fixed grass tiles (solid interior 9,1 + bordered edges). |
| 2026-04-27 | Player home door + interior scene. ADR-010/011 added. House collision corrected (3-shape door gap). |
| 2026-04-28 | Ground variety: FiveGrass + MabeyFive (10 tiles, 4 flip alternatives each). ADR-012 added. Removed 32×32 overlay. |
| 2026-04-28 | Player replaced with Erik — custom 68×68 pixel art, scaled 0.5, 4-direction walk generated via PixelLab. ADR-013 added. |
| 2026-04-28 | Scene transitions: TransitionManager autoload + door open animation + fade-to-black. ADR-014 added. Player spawns at door facing north. |
| 2026-04-28 | Depth sorting fixed: y_sort on World, Player moved into world.tscn, Overhead overlay in main.tscn. ADR-015 added. |
| 2026-04-28 | House collision fixed: UpperBlock (entire roof zone) replaced with WallCenter (front wall gap only) — roof area now walkable. |
| 2026-05-03 | Better Terrain + TileBitTools plugins installed. ADR-016 added. Terrain bits not yet assigned. |
| 2026-05-04 | Well animation — player-triggered reverse playback, moved to world.tscn, collision blocker added. ADR-018 added. |
| 2026-05-04 | PurplePunchOne plant animation added at (270,95); replaced static Tile024 Sprite2D. ADR-019 added. |
| 2026-05-05 | Water collection + plant growth loop implemented. Bucket walk animations (E/W/N/S), HUD icons, well fill timer, manual plant frame stepping. ADR-020 added. |
| 2026-05-05 | Full UI built — HUD (top bar + hotbar + toast), Inventory overlay, Shop skeleton. HUDLayer removed from world.tscn. ADR-021/022 added. |
