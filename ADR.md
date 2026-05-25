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

## ADR-023: Interactable Router — Decoupled E-Key System
**Status:** Accepted
**Date:** 2026-05-05
**Context:** world.gd._input() had hardcoded `if _near_well / elif _near_plant` branches. Adding any new interactable required editing world.gd.
**Decision:** Each interactable (Well, Plant) is a Node2D parent grouping its children, with its own script defining `interact(player)`, `can_interact(player)`, and two signals: `interactable_entered(node)` / `interactable_exited(node)`. world.gd holds a single `_interactable: Node` var. Area2D proximity signals update it via the signals. `_input()` calls `_interactable.interact($Player)` — one line, no branching.
**Rationale:** String-based `connect("signal_name", callable)` bypasses GDScript static type analysis for custom signals on untyped nodes — works at runtime without parse errors. Well/Plant grouped under parent Node2Ds (`res://Interactables/well.gd`, `res://Plants/plant.gd`). Prompts and collision shapes are children of the parent, so each script only uses `$ChildName` paths. HUD accessed via `get_node_or_null("/root/HUD")` directly in each script.
**Consequences:** Adding a new interactable (chest, NPC, furnace) requires: create a Node2D scene with `interact()` + the two signals, drop it in world.tscn, connect its signals in world.gd `_ready()` — zero changes to _input() or existing scripts. `PLANT_STAGES` still hardcoded in plant.gd; PlantData resource refactor is a separate task.

---

## ADR-024: HUD Cleanup — E-Prompt in HUD, Removed Energy/Currency/Yellow Selection
**Status:** Accepted
**Date:** 2026-05-05
**Context:** HUD top bar had three sections (water, currency "0", energy green bar) and hotbar had a yellow selection square on the active slot. World-space WellPrompt/PlantPrompt sprites above objects served as proximity indicators. User requested: move E-prompt to HUD, remove energy section, remove currency "0" label, remove yellow selection square.
**Decision:**
- Removed energy section (green ColorRect bar + dot) from top bar — no game logic wired to energy yet.
- Removed currency section (gold dot + "0" Label) from top bar — no currency system active.
- Removed yellow border + dark-gold background from selected hotbar slot — all 12 slots now use uniform grey styling. `_slot_style(_selected)` parameter preserved (unused) for future re-introduction.
- Added `_e_prompt` TextureRect (key_e.png, 14×14px) anchored PRESET_CENTER_LEFT at x=3 inside the hotbar Panel — hidden by default.
- Added `show_interact_prompt(on: bool)` public method on HUD.
- `world.gd._on_interactable_entered/exited` now calls `HUD.show_interact_prompt(true/false)` — E indicator is HUD-driven.
- `well.gd` and `plant.gd`: all `$WellPrompt.visible` / `$PlantPrompt.visible` calls removed. World-space prompt nodes remain in scene but are permanently hidden. Plant still calls HUD directly when reaching max growth stage while player is in range.
- Removed dead helper functions `_build_bar` and `_color_dot` from hud.gd.
**Rationale:** World-space prompts floating above objects are immersion-breaking and don't match the Stardew-style HUD-indicator pattern. Centralizing in HUD gives a single, consistent "you can interact" signal. Removing unimplemented meters (energy, currency) reduces visual noise. Yellow selection square is visually distracting with no gameplay benefit at this stage.
**Consequences:** `show_interact_prompt` parameter renamed from `show` to `on` — `show` shadows `CanvasLayer.show()` in GDScript. `plant.gd.interact()` reuses the `hud` var already declared at function top rather than re-declaring it in the inner scope (duplicate var error). Energy and currency API (`set_energy`, `set_currency`) fully removed — add back when those systems are built.

---

## ADR-025: Drying Rack — 3-Plant Processing Loop with Inventory Reward
**Status:** Accepted (Updated 2026-05-13)
**Date:** 2026-05-06
**Context:** A drying rack prop needed to show 0/1/2/3 plants as the PurplePunchOne plant completes its full watering cycle. Originally a permanent decoration (never reset). Now a repeatable processing loop producing a random bud product.
**Decision:** `drying_rack.gd` implements a 4-state machine: `EMPTY → FILLING → DRYING → READY → EMPTY`. After the 3rd plant the script enters `DRYING` (5s timer). Timer expires → `READY` (1.5s golden amber pulse via `modulate`). `READY` expires → `_award_and_reset()` calls `Inventory.add_item("bud", PRODUCTS[randi() % 8])`, resets state, clears modulate. `add_plant()` is blocked in DRYING/READY. 8 product textures in `res://GameAssets/Bud/` + `herb_bundle_dried.png`. See ADR-040 for inventory stacking design.
**Rationale:** Timer-based passive processing. Golden pulse signals READY without extra UI. Random product texture per cycle provides visual variety; stacking is by item key not texture (see ADR-040).
**Consequences:** Rack cycles indefinitely. `rack_weed_*` assets unreferenced. If all inventory slots full, item is silently lost.

---

## ADR-026: Day/Night Cycle — CanvasModulate + DirectionalLight2D Keyframe Lerp
**Status:** Accepted
**Date:** 2026-05-06
**Context:** Needed a built-in Godot 4 dynamic day/night lighting system: smooth ambient color transitions, a sun light source, and data exposed for shadow calculations.
**Decision:** `DayNightCycle.gd` static autoload (`DayNight` Node in `main.tscn`, added to `"day_night_cycle"` group). Drives:
- `CanvasModulate.color` via `_AMBIENT` keyframe table (midnight blue → sunrise orange → noon near-white → sunset red → night blue)
- `DirectionalLight2D.energy/rotation_degrees/color` via separate keyframe tables
- Exposes `shadow_dir: Vector2`, `shadow_alpha: float`, `shadow_length_factor: float` for use by `object_shadow.gd`
- `cycle_duration = 120s`, `start_time = 0.35` (starts near morning)
- Night ambient floor: Color(0.38, 0.42, 0.62) — readable blue-tinted night, not near-black
**Rationale:** Keyframe lerp tables give smooth, author-controlled transitions at specific time fractions. Static autoload in `main.tscn` as a plain `Node` (not CanvasLayer) — no scene persistence needed, just data computation. Group membership allows `object_shadow.gd` nodes to find it lazily at runtime.
**Consequences:** `shadow_alpha` = sun energy × 0.48 (shadows fade at dawn/dusk). Shadow direction sweeps 170°→10° during day. `DirectionalLight2D.shadow_enabled = false` — this is ambient tinting, not a shadow caster (object shadows are drawn manually).

---

## ADR-027: Object Shadows — Custom 2D Flat Oval, No Rotation
**Status:** Accepted
**Date:** 2026-05-06
**Context:** Needed Stardew Valley–style grounded shadows on all world objects (PlayerHome, Well, Plant, DryingRack, Rock). Initial attempts incorrectly rotated the ellipse as the sun moved, producing a spinning oval.
**Decision:** `object_shadow.gd` extends `Node2D`. In `_draw()`, draws a flat horizontal oval (two-pass: faint outer halo + solid inner core) whose **centre shifts** based on sun direction, but the ellipse itself **never rotates**. Y-component of shift is flattened by 0.25 for top-down perspective. `z_as_relative = false`, `z_index = 0` so shadows render above ground tiles (z=0) rather than below them.
**Key parameters per object:**
| Object | ground_offset | shadow_size | cast_length |
|---|---|---|---|
| PlayerHome | (0, 24) | (50, 8) | 32 |
| Well | (0, 10) | (14, 6) | 14 |
| Plant | (0, 12) | (11, 5) | 10 |
| DryingRack | (0, 26) | (28, 5) | 18 |
| Rock | (0, 5) | (8, 4) | 7 |
**Rationale:** Stardew-style shadows are always a flat horizontal oval — they shift position with the sun angle but don't rotate. Rotating the ellipse produces an unrealistic spinning effect. `z_as_relative=false, z_index=0` is required: grandchild nodes with `z_as_relative=true, z_index=-1` get global z=-1 which goes below the Ground TileMapLayer (z=0), making shadows invisible.
**Consequences:** `_dnc` (DayNight node) is looked up lazily in `_process()` (not `_ready()`) because world subtree children initialize before `DayNight` registers itself in its group. Shadow parameters may need per-object tuning after visual inspection.

---

## ADR-028: Camera Viewport Zoom — 15% More Visible Area
**Status:** Accepted
**Date:** 2026-05-07
**Context:** Default Camera2D zoom (1, 1) shows exactly the 320×180 logical viewport. Wanted 15% more world visible at once without changing the base resolution.
**Decision:** `Camera2D.zoom = Vector2(0.87, 0.87)` on the player camera in `world.tscn`. (0.87 ≈ 1/1.15.)
**Rationale:** Reducing zoom zooms the camera out — 320/0.87 ≈ 368px wide and 180/0.87 ≈ 207px tall visible. Existing camera limits (0, 0, 640, 384) remain adequate; the wider viewport still has room to scroll. No changes to resolution, UI, or tile size needed.
**Consequences:** World objects appear ~15% smaller. Camera limits may need expanding if the world grows.

---

## ADR-029: Night Speed Multiplier — 2× During Night
**Status:** Accepted
**Date:** 2026-05-07
**Context:** Day/night cycle runs at constant speed (120s). User wanted daytime unchanged but nighttime cut in half.
**Decision:** In `DayNightCycle.gd._process()`, multiply `delta / cycle_duration` by `2.0` when `_t < 0.28 or _t > 0.80` (night territory), else `1.0`.
**Rationale:** The simplest possible implementation — single multiplier, no keyframe changes. Night (dawn transition at 0.28, dusk at 0.80) spans ~48% of 120s = ~57.6s originally; at 2× it becomes ~28.8s. Daytime (0.28–0.80) remains 62.4s. Total cycle ~91s.
**Consequences:** Night passes noticeably faster. Dawn/dusk transition windows (0.25–0.30, 0.73–0.80) also run at 2× — slightly snappier transitions, visually acceptable.

---

## ADR-030: House Night Lighting — 4-Point Diffused Glow + Light Mask Exclusion
**Status:** Accepted
**Date:** 2026-05-07
**Context:** Wanted interior-window-glow feel: warm ambient spilling onto surrounding ground at night, house facade staying dark. A single `PointLight2D` produced a visible front spotlight on the house walls.
**Decision:** Replace single `HouseBackLight` with 4 soft `PointLight2D` nodes in `world.tscn`, all sharing a 128×128 radial-gradient texture (white opaque center → transparent edge):

| Node | Position | Energy | Texture Scale | Role |
|---|---|---|---|---|
| `HouseGlowBack` | (112, 50) | 0.32 | 2.8 | Wide halo rising behind roofline |
| `HouseGlowLeft` | (70, 100) | 0.17 | 2.0 | Left yard / path spill |
| `HouseGlowRight` | (154, 100) | 0.17 | 2.0 | Right yard spill |
| `HouseGlowFront` | (112, 140) | 0.09 | 1.6 | Faint door/window ground spill |

**Light mask exclusion**: `PlayerHome.light_mask = 2` and `PlayerHomeDoor.light_mask = 2`. All `PointLight2D` nodes use the default `range_item_cull_mask = 1`. Since `(2 & 1) = 0`, the house and door sprites receive zero illumination from the night lights — only `CanvasModulate` ambient (the dark blue night tint) affects them. Sun (`DirectionalLight2D`) updated to `range_item_cull_mask = 3` (1|2) so daytime still illuminates the house normally.
**Rationale:** The light_mask split is the only reliable way to prevent `PointLight2D` from washing a specific sprite while still illuminating everything around it. No `LightOccluder2D` geometry needed. The contrast between warm-lit ground and dark-ambient house creates natural edge definition that reads as rim-lighting.
**Consequences:** House/door are never illuminated by future `PointLight2D` additions unless their `range_item_cull_mask` includes layer 2. Any new directional lights (moon, etc.) must also set `range_item_cull_mask = 3` to hit the house. Energy values are initial estimates — may need tuning after playtesting.

---

## ADR-031: Village Building Assets — GameAssets/Buildings/ Organized Subtree
**Status:** Accepted
**Date:** 2026-05-07
**Context:** 13 building PNGs downloaded from PixelLab and other sources needed importing into the project. The existing `GameAssets/Houses/` folder uses numbered filenames (1.png, 2.png…) with no descriptive naming. A separate, well-named subtree was needed to keep new assets discoverable.
**Decision:** Created `game/GameAssets/Buildings/` with three subdirectories mirroring the building category system:
- `houses/` — 8 residential buildings (two-story variants a/b/c, stone cottage, stone teal/brown, teal+tree, cozy farmhouse)
- `shops/` — 4 commercial buildings (bakery, general small shop, apothecary x2)
- `special/` — 1 landmark (tavern)
All files renamed to snake_case descriptive names. Imported via `EditorInterface.get_resource_filesystem().scan()`.
**Rationale:** Keeping new assets in a dedicated `Buildings/` subtree avoids polluting the existing numbered-name system in `Houses/` while establishing a clean naming convention for all future village buildings. snake_case names with type prefix (`house_`, `shop_`, `building_`) make assets immediately identifiable in the editor FileSystem dock.
**Consequences:** `shop_apothecary_alt.png` is pixel-identical to `shop_apothecary_main.png` — likely the same source file saved twice. Pending dedup. Original files remain in `C:/Users/erikc/Downloads/` (not deleted). No scene references yet — assets are available for placement.

---

## ADR-032: Bakery as Erik's Home — Building Asset Swap
**Status:** Accepted
**Date:** 2026-05-07
**Context:** The placeholder house sprite (`GameAssets/Village/Houses/3_1.png`, 80×90px at scale 2) was replaced with `shop_bakery_main.png` (256×256px) from the newly imported Buildings asset set. The bakery's dome shape and prominent BAKERY sign make it visually distinct as the main residence.
**Decision:** Replaced `PlayerHome` texture in `world.tscn` and `PlayerHomeRoof` texture in `main.tscn` with `shop_bakery_main.png`. Adjusted:
- PlayerHome: position (112, 80), scale (0.5, 0.5), y_sort_offset=35 → sort_y=115
- PlayerHomeCollider: position (112, 80), WallCenter size (60×25) at offset (0,25), LeftLower/RightLower (22×30) at (±38, 35)
- PlayerHomeDoor: position (112, 118), scale (1, 1)
- DoorEntrance: position (112, 128), shape (44×30)
- PlayerHomeRoof overlay: position (307, 144) in main, scale (0.5, 0.5), region Rect2(0, 0, 256, 160) — shows top dome as overhead layer
- Interior exit spawn: Vector2(112, 150) — 22px south of new door trigger
- Well relocated: (200, 126) → (30, 140) — left side of house
- DryingRack relocated: (205, 75) → (22, 85) — upper left yard
- HouseGlow lights repositioned: Back (112,28), Left (60,82), Right (164,82), Front (112,120)
- PlayerHome Shadow: ground_offset (0,42), shadow_size (65,10), cast_length 30
**Rationale:** Bakery's round dome silhouette creates a memorable main residence. Scale 0.5 on 256×256 source gives 128×128 world pixels — reasonable footprint for the 320×180 viewport. Well/DryingRack moved left to clear the bakery's wider visual presence and create intentional left-yard placement. y_sort_offset=35 ensures player renders in front of bakery only when south of the door (sort_y=115 ≈ door base).
**Consequences:** Door animation frames (29×19 at scale 1) are smaller than the bakery door visually — acceptable, fade transition masks the transition. Collision shapes are tuned estimates; adjust offsets if player can clip through corners. Interior scene unchanged — bakery is exterior-only; same 160×128 room inside.

---

## ADR-033: Remove Door Overlay Sprite — Direct Fade Transition
**Status:** Accepted
**Date:** 2026-05-08
**Context:** `PlayerHomeDoor` (AnimatedSprite2D, Door1-4.png 29×19px, `visible=false`) was a leftover from a pre-bakery house setup. The door animation frames were too small and stylistically mismatched for the bakery sprite. The node was never made visible in `world.gd` — confirming it was vestigial.
**Decision:** Deleted `PlayerHomeDoor` node, `DoorFrames` SpriteFrames sub-resource, and Door1-4.png ext_resources from `world.tscn`. Simplified `world.gd._on_door_entered` to go straight to `TransitionManager.fade_to_black(0.4)` → `change_scene_to_file` with no animation step.
**Rationale:** The bakery PNG already draws a door in the building sprite — no overlay needed. The fade-to-black is sufficient to mask the transition without a separate door-open animation. Playtested: DoorEntrance trigger → fade → interior works correctly.
**Consequences:** No door-open animation on entry. Future enhancement could add a per-building door animation at the right size/style if desired. `DoorEntrance` Area2D and collision remain unchanged — only the visual overlay was removed.

---

## ADR-034: World Object Polish — PurplePlant Sprite Fix + Log/Rock Collision
**Status:** Accepted
**Date:** 2026-05-08
**Context:** After the Plant Node2D was repositioned in the editor, its `PurplePlant` AnimatedSprite2D child retained a stale local offset of `(149, -32)`, placing the visual sprite ~149px away from the PlantArea/PlantCollider shapes — interactions stopped working. Separately, the log ("18", 58×63px) and flat rock ("Rock123x20", 69×19px) had shadows but no collision, so the player walked through them.
**Decision:** Reset `PurplePlant.position` to `(0, 0)`. Added `LogCollider` (StaticBody2D + CircleShape2D radius=20 at offset (0, 10)) to the "18" log node. Added `RockCollider` (StaticBody2D + RectangleShape2D 55×14) to `Rock123x20`.
**Rationale:** Applied via `execute_editor_script` (not direct file edit) because the editor had the scene cached in memory and wouldn't re-read disk changes without a full reload. Collision shapes are estimates based on sprite dimensions — log uses a circle at the base of the 58px-tall sprite, rock uses a wide flat rectangle covering the 69×19 sprite footprint.
**Consequences:** Collision sizes may need nudging after playtesting. Node "18" and "Rock123x20" are placeholder names — rename to descriptive strings when next editing world.tscn.

---

## ADR-035: Drying Rack Texture Order Reversed
**Status:** Accepted
**Date:** 2026-05-08
**Context:** `drying_rack.gd` TEXTURES array was ordered `[empty, 1plant, 2plants, 3plants]`. In gameplay, adding the first harvest showed the `3plants` image (visually fullest), adding the second showed `2plants`, and the third showed `1plant` — visually the rack appeared to be emptying as you filled it. User wanted the opposite: first harvest = fewest items hanging, third harvest = most items hanging.
**Decision:** Swapped TEXTURES indices 1 and 3: array is now `[empty, 3plants, 2plants, 1plant]`. Logic (`_count`, `add_plant()`) unchanged.
**Rationale:** The image filenames count items hanging; visually the first plant harvest puts all 3 bundles on the rack (full display), and subsequent harvests reduce the hanging count — consistent with a "processing" metaphor (hang all at once, then bundles come off). Swapping only the array requires zero logic changes.
**Consequences:** In-game rack now shows 3 bundles on first harvest, 2 on second, 1 on third. The progression reads as rack filling up and drying down — matches the intended visual progression.

---

## ADR-036: Shadow Rendering Fix — show_behind_parent + HouseGlowLeft Correction
**Status:** Accepted
**Date:** 2026-05-08
**Context:** Two visual bugs on the bakery building: (1) `object_shadow.gd` oval was drawing ON TOP of its parent sprite because with `z_as_relative=false, z_index=0` the shadow rendered after the parent in draw order. (2) `HouseGlowLeft` PointLight2D had drifted to position `(158,138)` (right side of bakery) from its intended `(60,82)` (left side), and had an erroneous `shadow_enabled=true` flag — causing both glow lights to cluster on the right, leaving the left dark, and activating Godot's shadow rendering pass unnecessarily.
**Decision:** Added `show_behind_parent = true` in `object_shadow.gd._ready()`. Corrected `HouseGlowLeft` position to `(60,82)` and removed `shadow_enabled = true`.
**Rationale:** `show_behind_parent` is the correct Godot 4 mechanism to guarantee a child Node2D draws before its parent regardless of z_index. Fixing the light position restores symmetric left/right glow around the bakery. Removing `shadow_enabled` eliminates the unneeded shadow pipeline pass on a simple ambient glow.
**Consequences:** All shadows (Well, Plant, DryingRack, Log, PlayerHome) now draw behind their parent sprites. HouseGlow lighting is symmetric. No gameplay changes.

---

## ADR-037: Starter Farm Map — 40×30 Cleared Center + Tree Border
**Status:** Accepted
**Date:** 2026-05-08
**Context:** The existing world map was an irregular ~45×26 cell field with no defined boundary. A Stardew Valley-style farm needs a clear player space with a natural wooded border.
**Decision:** Rebuilt `Ground` TileMapLayer as a clean 40×30 cell grid (cells 0,0–39,29). Interior filled with sources 2/3 (fivegrass/mabeyfive) random atlas variants (seed=42). 66 `Tree1.png` Sprite2D nodes added as direct `World` children along all four edges: 20 top (y=8), 20 bottom (y=472), 13 left (x=8, y=40–424), 13 right (x=632, y=40–424), all spaced 32px apart. `Camera2D.limit_bottom` updated 384→480.
**Rationale:** Sprite-based tree border (not tile-based) gives a natural-feeling forest edge that participates in the World y_sort system — top trees (y=8) naturally render behind gameplay objects, bottom trees (y=472) render in front. `Tree1.png` (55×54px, round bushy tree) at 32px spacing provides dense coverage over the 2-tile border without gaps.
**Consequences:** All existing objects (Bakery, Well, Plant, DryingRack, Player) were already within the cleared center — no repositioning needed. Border trees have no collision yet — add StaticBody2D children if player walkout is an issue. `y_sort_offset` is not settable at runtime in Godot 4.6.2; tree sort is purely by `position.y`, which is correct for border placement.

---

## Future Considerations (Post Stage 1)
- Run animation — generate with PixelLab once walk quality confirmed
- Stage 2: NPCs, farming/crop system
- Interior tileset: `GameAssets/interior/` has bed, furniture, carpet, kitchen assets ready to use
- Audio: no tool in stack yet — deferred
- GitHub MCP: not installed — using `gh` CLI directly (sufficient for now)
- Shadow `ground_offset` / `shadow_size` per-object tuning — may need visual refinement after playtesting

---

## ADR-040: Inventory Stacking — Key-Based with Hotbar-First Placement
**Status:** Accepted
**Date:** 2026-05-13
**Context:** Drying rack produces items that needed to land visibly in the hotbar, stack up to 16 per slot, and support visual variety (random sprite per stack) without breaking stacking logic.
**Decision:** `add_item(key: String, tex: Texture2D)` on `Inventory` autoload. Items stack by `key` (not by texture), so all buds (`key="bud"`) share a stack regardless of which random sprite was picked for that cycle. `tex` is used only when opening a new slot. Placement priority: HUD hotbar slots 1–11 first (slot 0 reserved for bucket), then inventory grid slots 0–35. Both layers store `{key, tex, count}` dicts. Slot count badge (Label, font_size 6, bottom-right) is shown when count > 1. `inventory.gd._items[]` changed from bare `Texture2D` to dict. `hud.gd._slot_items[]` added as parallel tracking array. `inventory.gd._slot_icons[]` stores direct TextureRect refs (replaces broken `get_node("TextureRect")` lookup — Godot 4 auto-names nodes `@TextureRect@N`).
**Rationale:** Separating stacking identity from visual texture allows random-sprite variety per new slot while maintaining a single logical item type. Hotbar-first keeps items immediately visible without opening inventory. Key-based comparison is robust to resource reference variance.
**Consequences:** `add_item` signature changed from `add_item(tex)` to `add_item(key, tex)` — only caller is `drying_rack.gd`. When hotbar is full, overflow goes to inventory grid. When both are full, item is silently lost. Badge hidden at count=1, visible at count≥2.

---

## ADR-041: NPC Trade Interaction — Proximity-Based Bud-for-Gem Exchange
**Status:** Accepted (supersedes door-locked design from 2026-05-13)
**Date:** 2026-05-14
**Context:** Initial design locked trade to the NPC arriving at the player bakery door. This was too restrictive — the NPC is a roaming trade partner and should be tradeable wherever the player intercepts it.
**Decision:** Removed `arrived_for_trade`/`departed_from_trade` signals and TRADE_WAIT/door-arrival state. Replaced with:
- `world.gd._process()` checks `player.global_position.distance_to(npc.global_position)` every frame against `NPC_TRADE_RADIUS = 36.0` px.
- NPC exposes `set_player_nearby(bool)` — called each frame; NPC stops walking and plays `idle_south` when player enters range, resumes pathing when player leaves.
- T prompt shown when `in_range AND npc.is_interactable()`. Hidden during `_is_trading` (1.5s pause) and `_trade_cooldown_timer` (5s after trade).
- `attempt_trade()` guards on `_is_trading OR _trade_cooldown_timer > 0`. On success: bud removed, gem added, `_is_trading = true`, `_idle_timer = TRADE_PAUSE (1.5s)`. When timer expires, `_is_trading = false`, cooldown starts. NPC resumes walk only if player no longer nearby.
**Rationale:** Proximity model is simpler than signals and naturally handles all NPC movement states (walking, idling, mid-path). Single distance check per frame is negligible cost. Decouples trade availability from NPC routing entirely.
**Consequences:** NPC pauses its patrol whenever player is within 36px — intentional UX. Cooldown prevents spam. `_trade_done_this_visit` removed (cooldown timer replaces it). Gem still uses WaterGem.png placeholder.
**Testing:** Verified via execute_game_script: (1) `_npc_trade_active` flips true at dist=10px; (2) T prompt visible confirmed at `/root/HUD/Hotbar/HotbarLayout/EPromptArea/TPrompt`; (3) `attempt_trade()` returns true, bud removed, gem in hotbar, `_is_trading=true`; (4) prompt hides while trading.

---

## ADR-042: Asset Naming Pass — Descriptive snake_case for All Assets
**Status:** Accepted
**Date:** 2026-05-14
**Context:** ~1,000+ PNG assets included numbered filenames (18.png, 5.png, 1.png, Rocks/1–19, Trees/1–6, etc.) making them undiscoverable and preventing meaningful reference auditing. Several active assets in world.tscn had broken or ambiguous path references.
**Decision:** Full visual-identification and rename pass across all GameAssets subfolders. Active assets renamed with UID-preserved .import files + scene reference updates. Inactive numbered files renamed in bulk via PowerShell.
- `Rocks/18.png` → `rock_grey_cluster.png` (grey cluster with pebbles; active in world.tscn)
- `Trees/5.png` → `log_fallen_brown.png` (horizontal fallen log; active in world.tscn)
- `Trees/4.png` → `log_brown_short.png` (short brown log trunk; active in world.tscn — was undocumented)
- `Caves/CaveEntrance/1.png` → `cave_entrance_arch_stone.png` (arched stone entrance; active in world.tscn)
- `Buildings/special/House Grey with teal roof animation.png` → `house_grey_teal_animation.png` (spaces+mixed case → snake_case; active in house_grey_teal_frames.tres)
- All 19 `Rocks/*.png` numbered files → descriptive `rock_TYPE_SIZE.png` names
- All `Trees/Tree1.png`, `2–6.png`, `Treeshadow.png` → descriptive names
- All `Houses/Houses/1–8.png`, `Shops/1–4.png`, `Tents/1–5.png`, `Well/1–4.png`, `Farm/1.png` → descriptive names
- All `NPCs/1–8.png` → `npc_sprite_HAIR.png` names
- `Chests/1–2.png` → `chest_wood_closed/open.png`
**Rationale:** Descriptive names make assets discoverable without opening each file. UID preservation in .import files (same uid, updated source_file path) means scene references find resources correctly after rename. Godot editor autosave conflict: must close scene (open a different scene) before editing .tscn on disk, or edits are overwritten within seconds.
**Consequences:** ASSET_INDEX.md updated with new names and active/legacy status. `shop_apothecary_alt.png` still pending dedup (pixel-identical to `shop_apothecary_main.png`). `Town/` and `Village/` legacy folders still use numbered/mixed-case names — large sets (~250 files each), deferred to a future pass.
**Testing:** Played main.tscn — world renders correctly with all renamed assets visible (rock cluster, fallen log, trees, cave entrance, teal house animation, NPC). No broken texture references.

---

## ADR-043: InventoryManager Autoload — Single Canonical Item Store
**Status:** Accepted
**Date:** 2026-05-14
**Context:** Item state lived in two places: `_slot_items[]` in `hud.gd` (hotbar) and `_items[]` in `inventory.gd` (grid). `add_item/remove_item/has_item` in `inventory.gd` delegated to HUD via `get_node_or_null("/root/HUD")` with method-name string checks — fragile, opaque coupling. HUD and Inventory were mutually aware of each other's internals.
**Decision:** New `res://autoload/InventoryManager.gd` owns a single `_slots[0..47]` array (0–11 = hotbar, 12–47 = grid). Emits `slot_changed(index, item)` signal on every mutation. `add_item/remove_item/has_item` live exclusively in InventoryManager. `hud.gd` and `inventory.gd` connect to the signal in `_ready()` and update visuals reactively — no data of their own. Callers (`drying_rack.gd`, `npc_grey_hoodie.gd`) continue to use `Inventory.add_item/has_item/remove_item`, which now delegate to InventoryManager.
**Rationale:** One source of truth. Adding an item anywhere fires the signal; both HUD and Inventory update without explicit coordination. New autoloads added after editor startup are not recognized by the GDScript parser until restart (see ADR-021) — so InventoryManager is accessed via `get_node("/root/InventoryManager")` and stored in a local `_inv_mgr: Node` var rather than by its global name. This avoids parse errors on the current session.
**Consequences:** Once the Godot editor is restarted, scripts can reference `InventoryManager` by name directly. The `_inv_mgr: Node` pattern is the interim workaround and can be cleaned up to `InventoryManager.xxx` after the next editor restart. Bucket slot (0) remains a HUD-only visual driven by `set_carrying_water()` — not managed by InventoryManager. `hotbar_add_item/has_item/remove_item` methods removed from `hud.gd`.
**Testing:** Game launched clean. HUD hotbar visible. No inventory-related parse or runtime errors.

---

## ADR-044: Axe Tool + Wood Resource — Equip State via player.equipped_tool
**Status:** Accepted
**Date:** 2026-05-14
**Context:** Needed first tool integration: axe that can be equipped/unequipped with C key, and wood as a stackable inventory resource. No prior tool equip system existed beyond the water bucket (which uses a separate `carrying_water` flag and HUD slot 0).
**Decision:**
- `player.gd`: added `var equipped_tool: String = ""`. Empty string = nothing equipped; `"axe"` = axe active.
- `world.gd`: renamed `_grant_starting_bud()` → `_grant_starting_items()` — grants axe (`tool_axe.png`), bud, and wood (`rock3.png` placeholder) at start via `Inventory.add_item()`.
- `world.gd._input()`: KEY_C calls `_handle_axe_toggle()` — checks `InventoryManager.has_item("axe")`, then flips `player.equipped_tool` between `""` and `"axe"`.
- Items land in hotbar slots 1–3 via InventoryManager hotbar-first placement. HUD and Inventory update via `slot_changed` signal (no additional wiring needed).
**Rationale:** Follows the same pattern as `carrying_water`: a string flag on the player root tracks equipped state; world.gd handles the key event; no changes to InventoryManager, HUD, or Inventory UI scripts needed. Equip state is data-only for now — no axe animations exist yet, but `player.equipped_tool` can drive animation suffix or ability logic when those are built.
**Consequences:** Wood uses `rock3.png` as a placeholder icon. Key `"wood"` stacks correctly. No tree-chopping mechanic yet — wood is granted at start for inventory testing. Axe equip has no gameplay effect yet beyond setting the flag.
**Testing:** Game launched. Hotbar shows bucket(0), axe(1), bud(2), wood(3). execute_game_script confirmed `equipped_tool` toggles between `""` and `"axe"` on repeated calls. Inventory grid correctly empty (all items in hotbar).

---

## ADR-045: Choppable Tree Scenes — Reusable Instance with Per-Tree State
**Status:** Accepted
**Date:** 2026-05-14
**Context:** Four trees in world.tscn were bare Sprite2D nodes (TreePine one/two/three/four) with separate Stump Sprite2Ds — no logic, no interaction, no shared structure. Converting them to a reusable scene enables new trees to be added by duplicating the scene with zero script changes.
**Decision:** `res://World/ChoppableTree/choppable_tree.tscn` — Node2D root with:
- `TreeSprite` (Sprite2D) and `StumpSprite` (Sprite2D, hidden by default)
- `TreeCollider` (StaticBody2D + CircleShape2D r=10) — blocks player while tree is standing
- `ChopArea` (Area2D + CircleShape2D r=22) — proximity detection for E-key interactable
- Script: `choppable_tree.gd` — implements the interactable pattern (`interactable_entered/exited`, `interact(player)`), `can_interact()` guards on `player.equipped_tool == "axe"`, per-instance `_chop_count` incremented on each `interact()` call, transitions to stump on `_chop_count >= chops_required`
- Exported vars configure each instance: `tree_texture`, `stump_texture`, `tree_visual_scale`, `stump_offset`, `stump_visual_scale`, `stump_flip_h`, `chops_required` (default 3)
- `wood_chopped` signal emitted on transition; `world.gd._on_wood_chopped()` calls `Inventory.add_item("wood", rock3.png)`
- 8 standalone nodes (4 TreePine + 4 Stump) removed from world.tscn; replaced with 4 `[node instance=ExtResource("choptree_scene")]` entries with per-tree property overrides
**Rationale:** Each instance has its own `_chop_count` and `_is_chopped` vars — no shared state. Adding a new tree = duplicate the scene + configure exports. Interactable pattern reuses the existing world.gd E-key router. Tree collider is disabled on chop so the player can walk through the stump.
**Consequences:** `chops_required = 3` is a scene default, overridable per instance. Wood uses `rock3.png` placeholder. No chop animation or sound yet. Stumps are permanent — no respawn timer.
**Testing:** Game launched. All 4 trees visible at correct positions. Script-driven chop of Tree1: `_is_chopped=true`, TreeSprite hidden, StumpSprite visible, `has_item("wood")=true`, wood count=2 (1 starting + 1 from chop). Live play test 2026-05-15: user confirmed all 4 trees chop correctly — 3-hit counter, tree→stump transition, wood granted on completion, axe-equip guard (no chop without axe).

---

## ADR-046: Interact Key — Spacebar (was E), SPC Prompt in HUD
**Status:** Accepted
**Date:** 2026-05-15
**Context:** The `interact` input action was bound to E. User requested spacebar to activate equipped tools and interactables — a more natural "use item in hand" mapping. The HUD E-prompt (`key_e.png` TextureRect) needed to reflect the new key.
**Decision:**
- `project.godot`: `interact` action keycode changed from 69 (E) to 32 (Space). All interactables (well, plant, drying rack, choppable trees) now respond to Space.
- `hud.gd`: `_e_prompt` changed from `TextureRect` (key_e.png) to a `Panel` + `Label` styled identically to the T-prompt (dark bg, amber border, amber text). Label text = "SPC". Container widened from 20px to 28px to fit the three-character label.
**Rationale:** Single keycode change propagates automatically to all interactable handlers via the named action. Styled label avoids needing a new spacebar PNG asset and matches the existing T-prompt aesthetic.
**Consequences:** E key no longer does anything in-world. All prior "Press E" UX cues now read as "SPC" in HUD. No changes to world.gd, individual interactable scripts, or the interactable router pattern (ADR-023).
**Testing:** Play-tested 2026-05-15: SPC prompt appeared when player stood next to Tree1 with axe equipped. Tree chopped to stump in 3 hits via scripted interact() calls. Wood count 1→2 confirmed in hotbar.

---

## ADR-047: Architecture Hardening — 6 Structural Fixes
**Status:** Accepted
**Date:** 2026-05-15
**Context:** Architecture review identified 8 systemic gaps that would break as more tools/items are added. Fixed the 6 that were actionable without requiring new feature design.
**Decision:**
1. **`_grant_starting_items()` first-load guard** — `Engine.set_meta("starting_items_granted", true)` set on first call; early-return if meta already exists. Prevents duplicate axe/bud/wood on every world scene re-entry.
2. **Named InputMap actions for T/C** — Added `npc_trade` (T, keycode 84) and `equip_toggle` (C, keycode 67) to project.godot. `world.gd._input()` updated from raw `event.keycode == KEY_T/KEY_C` checks to `event.is_action_pressed("npc_trade"/"equip_toggle")`. Keys are now rebindable via InputMap without touching code.
3. **drying_rack.gd: `/root/Inventory` → `/root/InventoryManager`** — `_award_and_reset()` was calling the old (non-existent) Inventory autoload, silently losing all bud rewards. Fixed to use InventoryManager.
4. **InventoryManager `ItemEntry` class** — Replaced anonymous dict `{key, tex, count}` with a typed inner class `ItemEntry` (key: String, tex: Texture2D, count: int). All slots are now typed. Stacking was already key-based — no behavior change, just type safety.
5. **Interactable priority list** — `_interactable: Node` (single ref) replaced with `_interactables: Array[Node]`. `_on_interactable_entered` appends (dedup guard), `_on_interactable_exited` erases. `_get_nearest_interactable()` returns the closest Node2D by `distance_squared_to` from player. SPC prompt hides only when the list is empty. Overlapping areas (e.g. two adjacent trees) now resolve to the closest target instead of whichever fired `body_entered` last.
6. **`player.facing` enum** — `String` var replaced with `enum Facing { DOWN, UP, SIDE }`. `facing_name() -> String` helper added to player.gd for animation name construction. `player_animation.gd` updated to call `facing_name()` and use `player.Facing.SIDE` enum comparison. Both interior scripts updated from `$Player.facing = "up"` to the typed `Facing.UP` enum assignment.
**Rationale:** Items 1–3 were silent bugs (duplicate items, lost bud rewards). Items 4–6 are structural changes that prevent future breakage: named actions make keybinding possible; interactable list eliminates the "last-enter wins" overlap bug; the facing enum eliminates string-mismatch silent failures as animation states are added.
**Consequences:** `_get_nearest_interactable()` is a public method (no `_` prefix — kept callable from execute_game_script for testing). World state persistence and animation state machine are out of scope for this session. `player.Facing` enum is accessible from external scripts as `($Player as CharacterBody2D).Facing.UP`. T/C keys remain the default bindings but are now rebindable.
**Testing:** All 7 changed scripts compile clean. Game boots: player idle_down animation works, hotbar shows axe/bud/wood (no duplicates). Starting-items guard confirmed (`Engine.has_meta("starting_items_granted") = true`). Interactable list size = 1 confirmed on game start. `_get_nearest_interactable()` returns Tree1. Tree chopped to stump in 3 hits, wood count = 2. No output log errors.

## ADR-048: Hotbar Selection + Equipped-Tool Indicators
**Status:** Accepted
**Date:** 2026-05-15
**Context:** `_slot_style(bool)` ignored its parameter — selected and unselected slots were visually identical. No indicator existed for which tool was equipped.
**Decision:** `_slot_style` now takes `selected: bool, equipped: bool`. Border color logic: dim (default) → near-white (selected) → amber-gold (equipped) → bright-gold + warm-bg (selected + equipped). `_equipped_slot: int = -1` tracks which slot is highlighted. `set_equipped_slot(index)` is a new public method on HUD. `world.gd._handle_axe_toggle()` calls `hud.set_equipped_slot(slot_idx)` after toggling, scanning InventoryManager for the equipped key's slot index (or -1 to clear).
**Rationale:** Two separate visual states (keyboard cursor vs active tool) need different colors. White = "where your cursor is"; gold = "what you have in hand". Scanning InventoryManager in `_handle_axe_toggle` keeps the HUD passive — it doesn't reach into game state, world pushes to it.
**Consequences:** Currently only the axe uses this system. Any future tool toggle must call `hud.set_equipped_slot()` to light up its slot. There is no auto-detection; it's explicit push-from-world.
**Testing:** Play-tested 2026-05-15: axe slot shows gold border on equip, clears on unequip. Selected (bucket) slot shows white border at all times. Both indicators visible simultaneously.

---

## ADR-057: Player Chop and Trade Animations — PixelLab NeoAnima Integration
**Status:** Accepted
**Date:** 2026-05-16
**Context:** Player had no animation for tree chopping or NPC trading — both interactions played no visual feedback. PixelLab generated a set of directional action animations (axe chop, trade/object-swap, push, jump, eating) exported as individual frame PNGs at 56×56 px. Trade gem reward used WaterGem.png placeholder. PixelLab frames were exported with a solid olive-green background (R=201,G=215,B=143,A=255) rather than transparent.
**Decision:** Integrate chop and trade animations into the player SpriteFrames. Strip the baked-in background color from all 66 frames via PowerShell pixel replacement. Add `is_chopping` and `is_trading` flags to `player.gd`; `player_animation.gd` checks them before walk/idle; `animation_finished` resets both. `world.gd` sets `is_chopping=true` on Space-key and right-click tree interact; `is_trading=true` on successful NPC trade. Added `_face_player_toward(target: Node2D)` helper in `world.gd` — called each frame from `_update_npc_proximity()` when player is in trade range and not moving, so player always faces the NPC; NPC already uses `face_toward()`. New gem reward icon: `Date-time-Coin.png` replaces `WaterGem.png` in `npc_grey_hoodie.gd`.
**Rationale:** Minimal footprint — no new nodes, no refactor. Flags on player + `animation_finished` signal is the idiomatic one-shot animation pattern in Godot. Pixel-stripping in PowerShell avoids adding external tooling dependencies. Facing from `_update_npc_proximity()` is the natural location — proximity already drives NPC facing, symmetry demanded the same for the player.
**Consequences:** New chop/trade frames are 56×56 (old walk/idle are 64×64) — minor size difference at scale=0.5 (28px vs 32px display). The 4 remaining NewStates animations (push, jump, eating, pull_object) are present in the project but not yet wired to any game state — reserved for future use. Player facing snaps to NPC direction while in trade range; walking out of range restores normal movement-based facing.
**Testing:** Chop animation confirmed transparent, triggers on Space and right-click nav. Trade animation confirmed transparent, triggers on T-key trade. Player and NPC face each other confirmed visually from both vertical and horizontal positioning.

## ADR-061: Willow Tree Proximity Animation
**Status:** Accepted
**Date:** 2026-05-17
**Context:** The `TreeWillowWeeping` node (beside the NPC house) was a static `Sprite2D` using the old `tree_willow_weeping.png`. New PixelLab-generated assets at `GameAssets/willow/default/` provide a 96×96 idle frame plus a 9-frame "shake" animation. Request: replace the static sprite with the animated asset and add proximity-triggered one-shot behavior (plays once on player enter, holds last frame, resets only after player leaves AND 120s elapses, then re-enters).
**Decision:**
1. Copy willow assets to `game/GameAssets/Willow/`: `willow_idle.png` + `willow_f0.png`–`willow_f8.png` (10 files).
2. Create `res://World/WillowTree/willow_tree.gd` — `extends Node2D` with `ProximityArea` body-entered/exited signals and `animation_finished` to hold the last frame.
3. In `world.tscn`: replace `TreeWillowWeeping` `Sprite2D` root with `Node2D` (same position, same scale `(2.975, 2.5)`, `willow_tree.gd` script). Add `AnimatedSprite2D` child (SpriteFrames inline sub_resource: `"idle"` 1fr loop + `"shake"` 9fr non-loop @8fps). Add `ProximityArea` Area2D child (CircleShape2D radius=17 in local space, ~50px world). Preserve all existing children (Shadow, TreeCollider, RedCapMushroom) with unchanged positions/scales.
**Rationale:** Keeping scale on the Node2D root means all existing children inherit the same transform as before — no position/scale recalculation needed. Radius=17 in scaled space gives ≈50px world proximity, which feels responsive without triggering from long range. The 120s reset matches a "the tree settled down after a while" narrative beat.
**Consequences:** Old `tree_willow_weeping.png` ext_resource ref (`48_n40p1`) is now unused in `world.tscn` (orphaned ext_resource — harmless). The `AnimatedSprite2D` `idle` animation plays before the player is nearby, and the `shake` animation plays and holds exactly once per approach+120s-gap cycle.
**Testing:** Live playtest confirmed: `animation=shake`, `frame=8`, `is_playing=false`, `_played=true` — animation triggered on proximity entry, held on final frame, not looping. NPC house and surrounding interactions unaffected.

---

## ADR-062: Asset Reorganization — Canonical res://assets/ + res://resources/ Layout
**Status:** Accepted
**Date:** 2026-05-17
**Context:** All project assets lived under `res://GameAssets/` in a flat, ad-hoc structure with mixed naming conventions (numbered, hash-suffixed, mixed-case folders). After the Phase 1 audit (227 VERIFIED_USED / 879 VERIFIED_UNUSED), a structured reorganization was needed to separate used assets from noise.
**Decision:** Execute a full move of 227 VERIFIED_USED PNGs + 5 .tres resource files to a semantically organized tree:
- `res://assets/characters/{erik,grey_hoodie}/` — player + NPC sprite frames
- `res://assets/nature/{trees/willow,bushes/purple_punch_one,rocks,stumps}/` — world flora/geology
- `res://assets/props/{well,drying_rack,bud,items}/` — interactive object graphics
- `res://assets/ui/` — HUD elements
- `res://assets/tiles/interior/` — tileset source PNGs
- `res://assets/structures/{houses,shops}/` — building sprites
- `res://assets/effects/` — reserved for future effects
- `res://resources/{tilesets,characters,structures}/` — .tres SpriteFrames + tileset resources
- `res://assets/_review_required/` — UNKNOWN assets quarantined for review
For each PNG: moved PNG + its `.import` file together (preserving UID); updated `source_file=` inside moved `.import`. Updated all path strings in 13 .tscn/.tres/.gd files. Special case: `[32x32_Tileset/atlas.png` — `[` in path requires `mcp__filesystem__move_file` (GDScript `globalize_path()` fails on `[`). Special case: `erik_sprites.tres` — prefix replacement incorrectly routed it to `assets/characters/`; caught and corrected to `resources/characters/`.
**Rationale:** Semantic grouping makes assets discoverable by purpose. Separating `.tres` resource files into `resources/` from raw PNGs in `assets/` follows the Godot convention. UIDs are preserved — Godot resolves by UID even before a filesystem scan, so the game is not broken mid-operation. Keeping `.import` with its PNG is the critical invariant for UID integrity.
**Consequences:** 879 VERIFIED_UNUSED assets remain in legacy `GameAssets/` folders — cleanup is Phase 2 (separate decision). 4 bud duplicate pairs deferred (need art replacement before move). `retiledmap.tscn` still has updated paths but is a scratch scene — not deleted. `project_reorganization_plan.md` documents the full mapping; `project_move_log.md` documents the execution.
**Testing:** `ResourceLoader.exists()` confirmed OK for 16 spot-checked resources spanning all subsystems. Godot filesystem scan completed with no errors. `atlas_32x32.png.import` auto-regenerated with new ctex hash (expected behavior).

---

## ADR-063: BOM Purge — PowerShell 5.1 UTF-8 BOM Breaks Godot Text Resources
**Status:** Accepted
**Date:** 2026-05-17
**Context:** After the ADR-062 asset reorganization (which used PowerShell `Set-Content`/`Out-File` to write `.tscn`/`.tres`/`.gd` files), the project failed to load with `Parse Error: Expected '['` at line 1 of `main.tscn` and 15 other files. Root cause: PowerShell 5.1 default encoding is UTF-16 LE, but when writing text via redirection it emits UTF-8 with BOM (`EF BB BF`). Godot's text resource parser treats the first character as the file header and chokes on `0xEF`.
**Decision:** Strip BOM bytes from all 16 affected files using `[System.IO.File]::WriteAllBytes(path, content_without_bom)`. Establish rule: never use `Out-File`, `Set-Content`, or PowerShell string redirection for Godot resource files.
**Rationale:** `WriteAllBytes` writes exactly the bytes provided — no encoding layer, no BOM. `[Text.Encoding]::UTF8` (without `new UTF8Encoding(true)`) also works. This is the only safe pattern on PS 5.1.
**Consequences:** Rule documented in CLAUDE.md. Future edits to `.tscn`/`.tres`/`.gd` must use the Write/Edit tools (which handle encoding correctly) or `WriteAllBytes`. Direct PowerShell writes to Godot resource files are prohibited.
**Testing:** All 16 files confirmed BOM-free after strip. `main.tscn` loads cleanly. Project boots without parse errors.

---

## ADR-064: Phase 2 Asset Cleanup — SAFE_TO_ARCHIVE Pass
**Status:** Accepted
**Date:** 2026-05-18
**Context:** After ADR-062 reorganization, 879 VERIFIED_UNUSED PNGs remained in `game/GameAssets/`. The `cleanup_candidates.md` analysis classified them into SAFE_TO_ARCHIVE (~366), REVIEW_FIRST (~463), and UNCERTAIN (~20). This ADR covers the SAFE_TO_ARCHIVE execution.
**Decision:** Move all 18 SAFE_TO_ARCHIVE groups (confirmed zero references, confirmed duplicates or legacy content) from `game/GameAssets/` to `C:/Users/erikc/Dev/Game/_archived/` — outside the Godot project directory so Godot does not import them. PNG + `.import` sidecars moved together. REVIEW_FIRST and UNCERTAIN items remain in `game/GameAssets/` pending further decisions.
**Rationale:** Archive rather than delete preserves recovery options if a file was mis-classified. Moving outside `game/` removes them from Godot's import scan, eliminating editor noise. The 18 groups were verified zero-referenced via `grep` across all `.tscn`/`.tres`/`.gd` files before moving.
**Consequences:** `game/GameAssets/` reduced from ~879 PNGs to ~487 PNGs. ~366 files now in `_archived/`. REVIEW_FIRST assets (unplaced buildings, future animations, interior furnishings, planned tools) remain accessible in `game/GameAssets/`. Also fixed: `hud.gd:379` `INT_AS_ENUM_WITHOUT_CAST` — cast `align as HBoxContainer.AlignmentMode`. `R2` (willow_idle stale path) was already resolved in prior session.
**Testing:** Archive contains 691 files (366 PNGs + 325 .import sidecars). `game/GameAssets/` confirmed 487 PNGs remaining. No active scene references were disturbed (confirmed by prior audit).

---

## ADR-065: TempAssetHolding Integration — Garden & Plant Assets
**Status:** Accepted
**Date:** 2026-05-18
**Context:** `C:\Users\erikc\Dev\Game\GameAssets\TempAssetHolding\` contained a PixelLab-generated batch of 54 PNG files (prompt: "Crops in a dirt patch, Garden, Summer garden, spring garden, dirt bare garden", exported 2026-05-18T17:02). All assets are 154×154 px AI-generated art — intentionally large-format for garden props. A full visual inspection was required before integration.
**Decision:** Verification-first inspection of all 54 files. Result: 22 NEW_UNIQUE_ASSET, 17 UNCERTAIN (confirmed intentional large-format), 15 DUPLICATE. 36 files copied to `res://assets/_review_required/` with semantic names. Originals preserved in TempAssetHolding. 2 source folders not found in current tree (`Crops_in_a_dirt_patch_Garden (1)` / garden gate and `dirt coin` / ancient coin) — assumed from a different export batch, not integrated.
**Rationale:** Verification-first rule: no file moved without visual inspection of actual pixel content. 154×154 px is valid for large garden props — Godot renders sprites at any placed scale. UNCERTAIN items approved as intentional large-format assets by user confirmation.
**Consequences:**
- `_review_required/dirt_patches/` — 4 square patch variants + long horizontal + long seeded + 9-frame pulse animation (15 files)
- `_review_required/plants/` — 20 plant sprites: cannabis stage_1/2/3, compact, silver/silver_b, mid_a/b/c, round_crown, dark_outline, dense, flowering_purple; planter_type_a/b/c; herb_type_a/b/c/d (cardinal directions from default_7)
- `_review_required/structures/` — `stump_door_dwelling.png` (ancient stump with carved hobbit-style door)
- All assets need Godot `scan()` import before they're usable in scenes
- 15 exact duplicates remain in TempAssetHolding — safe to delete when confirmed
**Testing:** PowerShell Get-ChildItem count confirmed 36 files across 3 subdirectories (15 + 1 + 20).

---

## ADR-066: TempAssetHolding Second Pass — Tree Chop Animations + Stump Dissolve
**Status:** Accepted
**Date:** 2026-05-19
**Context:** `TempAssetHolding` received a new batch of PixelLab assets after the ADR-065 pass, all exported 2026-05-19. Batch contains: 3 choppable-tree variants (Pine/Maple/Fir) with multi-sequence animations, 2 stump animation sets, 7 seamless 64×64 dirt tiles, and 30 new garden crop patch variants.
**Decision:** Verification-first inspection of all files. 4 asset groups classified INTEGRATE_NOW, remainder to ResolvedReview.
**Rationale:** Tree chop animations directly extend the existing `choppable_tree.tscn` pattern (exported `tree_texture` + `stump_texture` vars). Stump dissolve fills a missing post-chop effect slot. The 30 garden variants are REVIEW_REQUIRED since 6+ representative samples are already in the project and the additional variants exceed immediate need.
**Consequences:**
- `res://assets/nature/trees/tree_pine_3.png` — 96×96 pine static
- `res://assets/nature/trees/pine_chop/` — 9 frames (chop animation)
- `res://assets/nature/trees/pine_fall/` — 9 frames (fall animation)
- `res://assets/nature/trees/tree_maple.png` — 96×96 maple static
- `res://assets/nature/trees/maple_chop/` — 9 frames
- `res://assets/nature/trees/maple_fall/` — 9 frames (leaves blowing)
- `res://assets/nature/trees/maple_hit_fall/` — 9 frames (3-hit then fall)
- `res://assets/nature/trees/tree_fir.png` — 96×96 fir static
- `res://assets/nature/trees/fir_chop/` — 9 frames
- `res://assets/nature/trees/fir_fall/` — 9 frames
- `res://assets/nature/stumps/stump_round.png` — 96×96 round stump static
- `res://assets/nature/stumps/stump_round_dissolve/` — 16 frames (spiral disappear)
- All 71 files auto-imported by live Godot editor (verified .import files present)
- StumpAnima3 (2 alt stumps) → ResolvedReview/REVIEW_REQUIRED
- stumpanimaGone (64×64 seamless dirt tiles) → ResolvedReview/REVIEW_REQUIRED
- 30 garden crop variants (default/ through default_29/) → ResolvedReview/REVIEW_REQUIRED
- 15 staging duplicates (64x64Dirt, dirty22, longdirtStumpDoor, Pulsing dirt) → ResolvedReview/STAGING_DUPLICATE
- TempAssetHolding root is now empty (only ResolvedReview/ remains)
**Testing:** PowerShell verified 9 PNGs + 9 .import files in each animation folder; 16 PNG + 16 .import in stump_round_dissolve; all 4 static sprites have .import sidecar. `temp_asset_reconciliation_report.md` generated.

---

## ADR-067: _review_required Cleanup — All Assets Routed to Permanent Locations
**Status:** Accepted
**Date:** 2026-05-19
**Context:** `res://assets/_review_required/` contained 36 assets from the ADR-065 session that needed routing to their correct permanent project folders before they could be referenced in scenes.
**Decision:** Route every asset by visual inspection to its correct permanent folder.
**Rationale:** _review_required is a transit zone, not a permanent home. Leaving assets there makes them hard to find and reference. Now that we know what each file is, routing to canonical folders makes them discoverable and wirable.
**Consequences:**
- `grey_hoodie_rotations/` (8 directional statics) → `res://assets/characters/grey_hoodie/rotations/`
- `purple_jack/` (8 directional statics, female character) → `res://assets/characters/purple_jack/`
- `player_character_alt/` (full player sprite set, 59×49, Axe/Bow/Idle/Walk/Run etc + player_sprites.tres) → `res://assets/characters/player_alt/`
- `plants/cannabis/` (13 cannabis variants: stage_1/2/3, planter_a/b/c, mid_a/b/c, compact, silver, round_crown, dark_outline, dense, flowering_purple) → `res://assets/nature/plants/cannabis/`
- `plants/herbs/` (herb_type_a/b/c/d) → `res://assets/nature/plants/herbs/`
- `dirt_patches/` (4 square variants + 2 long patches + 9-frame pulse anim) → `res://assets/props/garden/`
- `RedCapMushroom.png` → `res://assets/nature/rocks/`
- `structures/stump_door_dwelling.png` → `res://assets/structures/`
- `tileset_32x32/` (66 tiles + 2 .tres resources) → `res://assets/tiles/32x32/`
- `Tile.png` (16×16 main game atlas) → `res://assets/tiles/`
- `willow_idle.png` → `res://assets/_archived/` (superseded by willow/willow_f0–f8 animation set)
- `tilemaplayer_icon.png` → `res://assets/_archived/` (Godot engine icon, not a game asset)
- `_review_required/` is now empty and can be removed when desired
**Testing:** PowerShell confirmed _review_required is empty. File counts verified for each destination folder.

---

## ADR-068: Choppable Tree Animation — Pine/Maple/Fir Species Scenes
**Status:** Accepted
**Date:** 2026-05-18
**Context:** Three existing generic `ChoppableTree` instances near the player's house used placeholder textures (pine_bushy_b, pine_narrow, tree_ginkgo) with no chop/fall animations. New PixelLab assets (tree_pine_3, tree_maple, tree_fir — 96×96 static + 9-frame chop/fall sequences) were staged in `res://assets/nature/trees/` from ADR-066.
**Decision:** Create three species-specific scenes (`choppable_tree_pine.tscn`, `choppable_tree_maple.tscn`, `choppable_tree_fir.tscn`) as standalone `.tscn` files with inline `SpriteFrames` sub-resources. Update `choppable_tree.gd` to drive a `ChopAnim` (`AnimatedSprite2D`) child — plays "chop" then "fall" on final chop, then shows stump. Replace Tree1/2/3 in `world.tscn` with the species scenes (TreePine/TreeMaple/TreeFir at same positions). Tree4 (oak) and WillowTree unchanged.
**Rationale:** Inline `SpriteFrames` in each species scene keeps all per-species data self-contained — zero `world.gd` or `choppable_tree.gd` changes needed to add new species. Backward compat: base `choppable_tree.tscn` now has an empty `ChopAnim` node; if `sprite_frames` is null the script falls back to instant sprite-swap (Tree4 still works).
**Consequences:**
- New files: `World/ChoppableTree/choppable_tree_{pine,maple,fir}.tscn`
- Animation speed: chop=10 fps, fall=8 fps (9 frames each — ~0.9s chop, ~1.1s fall)
- Stump: `stump_round.png` at scale 0.4, offset (0, 18) — all three species share the same stump
- Tree visual scale: 0.5 (96×96 → 48×48 in-game)
- `world.tscn` lesson: always close scene in editor (`open_scene("main.tscn")`) before editing .tscn on disk — editor autosave overwrites external edits within seconds
**Testing:** Played game via MCP. Chopped pine 3 times with axe — chop animation played, fall animation played, stump appeared, 2 wood granted. MapleTree and FirTree visible with correct species sprites. WillowTree and Tree4 unchanged. Screenshot confirmed.

---

## ADR-060: Trade Reliability Fixes — Double-Trigger Guard + Gem Icon
**Status:** Accepted
**Date:** 2026-05-17
**Context:** Two bugs reported after ADR-059 landed:
1. **Broken gem icon** — `Date-time-Coin.png` (introduced ADR-057 as placeholder) is a large UI sprite sheet. At 24×14 px hotbar slot size it renders as an unrecognizable colored mess. Player couldn't identify it as the trade reward.
2. **"No product available" overwriting success toast** — `_npc_trade_active` is set by `_update_npc_proximity()` in step 1 of `_process()`. The nav auto-trade fires in step 2. `_npc_trade_active` remains `true` for one full frame after the trade completes (proximity clears it on the *next* frame). Any second trigger within that window — T-key press or re-clicking the NPC — called `_handle_npc_trade()` again. The failure toast ("No product available") overwrote the success toast, leaving the player seeing the gem icon but a failure message.
**Decision:**
1. Replace `GEM_TEX` in `npc_grey_hoodie.gd` with `res://GameAssets/Items/Gems/gem_ruby.png` — a clean round gem sprite that reads clearly at any hotbar size.
2. Add `_npc.is_interactable()` guard to both `_handle_npc_trade()` trigger points in `world.gd`:
   - T-key path (`_input`): `if … and _npc != null and _npc.is_interactable()`
   - Nav arrival path (`_update_mouse_navigation`): `if pending and _npc.is_interactable()`
**Rationale:** `is_interactable()` is a real-time property check with no frame lag (unlike `_npc_trade_active` which has a one-frame update delay). Adding it at both call sites blocks the second call the instant the first trade sets `_trade_completed = true`. The gem icon fix uses an existing in-project asset that scales cleanly.
**Consequences:** Double-trigger is impossible regardless of input speed. Re-clicking the NPC after a completed trade is silently ignored rather than showing a misleading toast. `gem_ruby.png` key in InventoryManager is still `"gem"` — no stacking conflict.
**Testing:** `execute_game_script` confirmed: first `_handle_npc_trade()` → `slot2=gem`, `_trade_completed=true`, `is_interactable()=false`; second attempt blocked (`_npc_trade_active=true` but `is_interactable=false`). Screenshot: ruby gem shows as clear red sphere in hotbar slot.

---

## ADR-059: NPC Right-Click Navigation and Auto-Trade
**Status:** Accepted
**Date:** 2026-05-17
**Context:** Right-click navigation (ADR-055) only handled terrain and choppable trees. Clicking on or near the NPC did nothing — player could not click-to-navigate to the NPC to initiate a trade.
**Decision:** Extend the existing `_on_right_click()` target resolution system with an NPC check at highest priority (before tree scan). In `_update_mouse_navigation()`, add a dedicated NPC arrival branch before the `_interactables.has()` check. Changes are entirely in `world.gd` — no new nodes, signals, or pipelines.
- `_on_right_click`: if `_npc` is visible and click lands within `NPC_TRADE_RADIUS` (36 px) of NPC, set NPC as nav target with `pending=true`, return early (skips tree/terrain checks).
- `_update_mouse_navigation` NPC branch: each frame, update `_nav_target_pos` to track NPC's current position (handles NPC patrol movement). When `player.distance_to(npc) ≤ NPC_TRADE_RADIUS`, cancel nav and fire `_handle_npc_trade()`.
**Rationale:** Reuses all existing nav state (`_nav_target_pos`, `_nav_target_node`, `_nav_pending_interact`, `_nav_best_dist`, `_nav_stuck_time`). NPC doesn't use an Area2D/`_interactables` pattern so a separate arrival check was needed; tracking `_nav_target_pos` each frame allows the player to chase a moving NPC. Priority order (NPC > tree > terrain) matches the spec and is enforced by early return positioning in `_on_right_click`.
**Consequences:** Clicking within 36 px of a visible NPC always targets the NPC for trade — even if a tree is also nearby. NPC click radius equals trade radius (36 px), intentionally generous. If NPC enters home mid-navigation (`visible=false`), the `_on_right_click` guard prevents re-targeting but in-progress nav completes (arrives at last known NPC pos and fires trade if NPC is still interactable).
**Testing:** `execute_game_script`: right-click at NPC pos → `nav_active=true`, `target_node=GreyHoodie`, `pending=true`; after 4s walk → `nav_active=false`, `dist=35.0`, `trade_completed=true`, `slot2=gem`. Tree nav and terrain nav regression-tested: both unaffected.

---

## ADR-058: Hotbar Selection Behavioral Fix — Gold Border Tracks Selected Slot
**Status:** Accepted
**Date:** 2026-05-17
**Context:** The hotbar had two separate concepts: `selected_slot` (white border, keyboard cursor) and `_equipped_slot` (gold border, active tool). `_on_hud_slot_selected()` in `world.gd` had an early return `if _player.equipped_tool == new_tool: return` that fired when scrolling between any two non-tool slots (both yield `new_tool = ""`). `set_equipped_slot()` was never called, leaving the gold border frozen at the previous position rather than tracking the selection cursor.
**Decision:** Remove the early return. Conditionally update `equipped_tool` only when it changes (`if _player.equipped_tool != new_tool`). Always call `_hud.set_equipped_slot(index)` at the end of `_on_hud_slot_selected()` so the gold border tracks every slot selection unconditionally.
**Rationale:** The gold border is the active-item indicator. It should always match the selection cursor. The old early return was an optimization that broke the visual contract — skipping `set_equipped_slot` when the tool state didn't change meant the visual could drift from the selection.
**Consequences:** Gold border follows the selected slot at all times, including empty slots and non-tool items. `equipped_tool` still only carries the tool key string when the selected slot contains a registered tool; empty/non-tool selection correctly clears it. C-key toggle still works independently (sets `_equipped_slot` directly via `_handle_tool_toggle`).
**Testing:** `execute_game_script`: scrolling 0→1→2→3→4 confirmed `selected==equipped` at every step including non-tool slots. Screenshot: axe slot (slot 1) shows gold bg + bright gold border when selected.

---

## ADR-056: Mouse Navigation Stuck Detection
**Status:** Accepted
**Date:** 2026-05-15
**Context:** The right-click nav system (ADR-055) had no termination guard for unreachable targets. Right-clicking inside a building or against a wall caused `_nav_active = true` permanently — `move_and_slide()` slides the player along the collision surface at full walk speed (velocity ≠ 0) so the `ARRIVE_DIST` check never fires. The player would grind against obstacles indefinitely ("unhinged" behavior).
**Decision:** Add two variables (`_nav_best_dist: float = INF`, `_nav_stuck_time: float = 0.0`) and a constant (`NAV_STUCK_MAX = 1.0` s) to `world.gd`. Each `_process(delta)` tick: if `dist` improved by >0.5 px vs best, reset stuck timer; otherwise accumulate delta. If stuck for ≥1 s, call `_cancel_navigation()`. Also call `_cancel_navigation()` at the top of `_on_right_click()` when `_nav_active` is true, so re-clicking while navigating resets all state cleanly.
**Rationale:** Velocity-based stuck detection doesn't work here — `move_and_slide()` returns full slide velocity even against a wall. Progress-toward-target is the correct metric. Delta-based timing (not frame count) ensures consistent behavior at any frame rate.
**Consequences:** Player stops at the closest reachable point to any blocked click target after ≤1 s. Legitimate long-distance navigation is unaffected (player makes continuous progress, stuck timer never accumulates). Serves as a secondary fallback for tree nav if `ChopArea.body_entered` somehow misses.
**Testing:** `execute_game_script` confirmed: right-click at (280, 155) (inside bakery) → player slid against wall → `_nav_active = false`, `auto_walk = (0,0)` after ~1 s. Regression: terrain nav (stopped at 4.3 px from target) and tree nav (chop fired on arrival) both unaffected.

---

## ADR-055: Right-Click Mouse Navigation and Contextual Harvest
**Status:** Accepted
**Date:** 2026-05-15
**Context:** All world interaction was keyboard-only. Right-click mouse input had no behavior.
**Decision:** Add right-click navigation to `world.gd` with three behaviors:
1. Right-click empty terrain → walk player to clicked world position, stop within 5px.
2. Right-click an unchoppped tree (within 22px radius) → walk player to tree, auto-`interact()` on ChopArea entry if axe equipped; stop silently if not.
3. Keyboard input while navigating cancels mouse nav immediately.
**Rationale:** Implemented entirely in `world.gd` — no changes to `player.gd`, `choppable_tree.gd`, or any other file. Used existing `auto_walk` var on player (already supported) and existing `interactable_entered` signal to detect when player enters tree range. Click-to-tree detection uses same `choppable_trees` group already iterated in `_ready()`. `_nav_active` bool + `_nav_target_pos`/`_nav_target_node`/`_nav_pending_interact` state tracked in `world.gd`. `_update_mouse_navigation()` called from `_process()`. Right-click handled in `_input()` before the key-only early return, marked handled with `set_input_as_handled()`.
**Consequences:** Right-click now navigates. Keyboard still works (cancels mouse nav on first directional press). Space-chop, C-equip, scroll slot, NPC trade, door transitions — all unaffected. Chopped trees skipped in click detection via `_is_chopped` check. Invalid node guard via `is_instance_valid()`.
**Testing:** `execute_game_script` direct calls confirmed all three paths: (1) terrain walk → arrived at (416, 251) targeting (420, 250), nav_active=false; (2) tree with axe → chop_count=1 after arrival; (3) tree without axe → arrived at tree range, chop_count=0.

---

## ADR-054: Mouse Interaction Pipeline Fix — Auto-Equip on Slot Select + Scroll Direction
**Status:** Accepted
**Date:** 2026-05-15
**Context:** Mouse scroll worked visually (white border moved) but `player.equipped_tool` was never updated. `select_slot()` in `hud.gd` was cosmetic-only. Result: scrolling to axe slot showed white border but axe was never equipped — tree `can_interact()` always returned false, showing "Equip axe first (C)" even after scrolling to the axe. Scroll direction was also inverted (WHEEL_UP went left/lower-index instead of right/higher-index).
**Decision:**
1. Fix scroll direction in `hud.gd:_unhandled_input` — swap WHEEL_UP/WHEEL_DOWN operations.
2. Add `signal slot_selected(index: int)` to `hud.gd`; emit it in `select_slot()`.
3. In `world.gd._ready()`, connect `HUD.slot_selected` to new `_on_hud_slot_selected(index)`.
4. `_on_hud_slot_selected` checks slot content via `_inv_mgr.get_slot(index)`: if key is in `EQUIPPABLE_TOOLS`, set `player.equipped_tool` and call `hud.set_equipped_slot()`; otherwise unequip.
**Rationale:** The source of truth for equip state is `player.equipped_tool`. `hud.gd` has no path to it — a signal to `world.gd` keeps the existing architecture clean (HUD owns display, world owns game state). Auto-equip on any slot selection (scroll or number key) is consistent and matches typical game behavior.
**Consequences:** Scrolling to an equippable tool slot auto-equips it. Scrolling off unequips. The C key (toggle) still works but is now supplementary. Both white (selected) and gold (equipped) borders reflect correctly.
**Testing:** `execute_game_script` confirmed: `select_slot(1)` → `equipped_tool='axe'`, `_equipped_slot=1`; `select_slot(2)` → `equipped_tool=''`, `_equipped_slot=-1`; `select_slot(1)` again → `can_interact=true`; 3 chops → wood count incremented. Screenshot: gold border on axe slot, tree chopped to stump.

---

## ADR-053: HUD Mouse Filter Fix — MOUSE_FILTER_IGNORE on All Non-Interactive Panels
**Status:** Accepted
**Date:** 2026-05-15
**Context:** Mouse wheel hotbar slot cycling (`hud.gd:_unhandled_input`) silently failed whenever the cursor was positioned over the hotbar or top bar. The feature worked mid-screen but not over the HUD strips where the cursor naturally rests.
**Decision:** Set `mouse_filter = Control.MOUSE_FILTER_IGNORE` on all non-interactive Control nodes built procedurally in `hud.gd`: TopBar Panel, Hotbar Panel, EPromptArea Control, SpacePrompt Panel, TPrompt Panel, all 12 Slot Panels, Toast Panel, WaterGem TextureRect, and WaterMeter TextureProgressBar.
**Rationale:** In Godot 4, any Control node with `MOUSE_FILTER_STOP` (the default) calls `accept_event()` when the cursor is over it, marking the InputEvent as handled. `_unhandled_input` is only called for events that are NOT marked handled. Because the slot Panels covered the full hotbar strip, every mouse wheel event in that region was consumed before reaching `_unhandled_input`. Setting `MOUSE_FILTER_IGNORE` on display-only nodes lets events pass through to `_unhandled_input` regardless of cursor position. The inventory `dim` ColorRect retains `MOUSE_FILTER_STOP` (intentional — blocks clicks through the inventory overlay).
**Consequences:** Wheel scrolling now works anywhere on screen. No interactive UI elements exist in the HUD, so `MOUSE_FILTER_IGNORE` is correct for every node changed.
**Testing:** `execute_game_script` confirmed: all changed nodes report `mouse_filter=2`; simulated wheel-down advanced `selected_slot` from 3→4; screenshot confirmed white border moved to correct slot.

---

## ADR-052: Structural Refactor Validation — Tool Registry + Tree Group
**Status:** Accepted
**Date:** 2026-05-15
**Context:** After ADR-050 (tool registry) and ADR-051 (tree group registration) both landed in the same session, a structured validation pass was needed before shipping to confirm no regressions across the full system.
**Decision:** Full validation via `execute_game_script` — 7 tool/tree checks + 7 regression checks covering all active subsystems.
**Results:**
| Check | Outcome |
|---|---|
| TOOL-1: axe equip toggle (`_handle_tool_toggle("axe")`) | ✅ `equipped_tool: '' → 'axe'` |
| TOOL-2: EQUIPPABLE_TOOLS is data-driven | ✅ Keys `["axe"]`; adding a tool = 1 dict entry |
| TOOL-3: toggle off | ✅ `equipped_tool: 'axe' → ''` |
| TOOL-4: hotbar gold highlight | ✅ `HUD._equipped_slot=1`; gold border confirmed in screenshot |
| TREE-1: all 4 trees auto-registered via group | ✅ `get_nodes_in_group("choppable_trees")` returns 4 |
| TREE-2: independent state — chop Tree1 doesn't affect Tree2 | ✅ Tree2 `_chop_count=0` unchanged |
| TREE-3: full chop via `interact()` — Tree3 to stump | ✅ `_is_chopped: false → true`; stump visible |
| REGRESS-1: `_interactables: Array[Node]` arch intact | ✅ Array exists; well/plant signal-connected |
| REGRESS-2: distance sorting selects nearest | ✅ Plant (d²=12002) over Well (d²=29786) |
| REGRESS-3: inventory items all present | ✅ `has_item` true for axe, wood, bud |
| REGRESS-4: wood count increments on chop | ✅ 2 → 3 on `_on_wood_chopped()` |
| REGRESS-5: well `interact()` exists | ✅ `has_method('interact')=true` |
| REGRESS-6: plant `interact()` exists | ✅ `has_method('interact')=true` |
| REGRESS-7: plant→drying rack chain intact | ✅ `plant_harvested` signal + `add_plant` + `stage` property all present |
**Rationale:** All 14 checks pass. Architecture is clean and ready for feature work.
**Consequences:** None — validation only. Establishes the 14-check suite as the regression baseline for future refactors.

---

## ADR-051: Choppable Tree Group Registration
**Status:** Accepted
**Date:** 2026-05-15
**Context:** `world.gd._ready()` used a hardcoded array `[$Tree1, $Tree2, $Tree3, $Tree4]` to connect tree signals. Adding a 5th tree required editing `world.gd`. Architecture review flagged this as a scene-coupling issue.
**Decision:** `choppable_tree.gd._ready()` calls `add_to_group("choppable_trees")`. `world.gd._ready()` iterates `get_tree().get_nodes_in_group("choppable_trees")` to connect signals.
**Rationale:** Group self-registration is the idiomatic Godot pattern for this problem. No world.gd change is needed when a new tree is added — place the scene instance in the world and it registers automatically.
**Consequences:** `world.gd` no longer holds named references to individual tree nodes. Group lookup happens once at `_ready()`. Trees added after `_ready()` (dynamic spawn) would need an explicit `connect()` call — not a concern for static world layout.
**Testing:** 4 trees auto-registered in group, Tree2 chopped correctly, wood awarded. All existing signal connections verified via execute_game_script.

## ADR-050: Tool Registry — Generalized Equip/Toggle System
**Status:** Accepted
**Date:** 2026-05-15
**Context:** `_handle_axe_toggle()` in world.gd was axe-specific: hardcoded action name, hardcoded `"axe"` key, slot search over magic `range(1, 48)`. Adding a second equippable tool (pickaxe, fishing rod) would require copy-pasting the function. Architecture review (post ADR-049) flagged this as the highest-priority scalability risk.
**Decision:** Replace `_handle_axe_toggle()` with `_handle_tool_toggle(tool_key: String)`. Add `EQUIPPABLE_TOOLS` dict mapping item key → InputMap action. Cache `_inv_mgr` in `_ready()` instead of three separate `get_node_or_null()` lookups. Fix slot search to `range(1, _HOTBAR_SLOTS)` (only hotbar slots appear in HUD display).
**Rationale:** Adding a new equippable tool now requires one line in `EQUIPPABLE_TOOLS` and one registered InputMap action — no logic branches. The `_input()` loop is data-driven over the registry. Caching `_inv_mgr` removes three redundant node lookups per frame-event path.
**Consequences:** Slot search is now hotbar-only (slots 1–11). If a tool lands in the grid (unlikely given hotbar-first placement), the gold indicator won't display but equip still works. Acceptable trade-off — tools should always occupy hotbar. `choppable_tree.gd`, `InventoryManager`, HUD, and all other systems unchanged.
**Testing:** Axe equip/unequip, gold indicator, no-axe toast, and tree chop verified via execute_game_script after refactor.

## ADR-049: Full Integration Validation — Axe/Tree/Wood/Inventory System
**Status:** Accepted
**Date:** 2026-05-15
**Context:** After completing ADR-044 through ADR-048 (axe equip, choppable trees, hotbar indicators, spacebar rebind), a full integration test was needed to confirm every subsystem works end-to-end together and that no existing systems were broken.
**Decision:** Systematic 6-check validation via `execute_game_script` (since `simulate_key` via MCP does not route through `world.gd._input()` — that handler checks `event is InputEventKey` first, and MCP-dispatched key events do not pass this check). Direct method calls (`_handle_axe_toggle()`, `tree.interact(player)`) used to drive the game state.
**Results:**
| Check | Outcome |
|---|---|
| Axe equips with C (`_handle_axe_toggle`) | ✅ `equipped_tool` toggles `"" ↔ "axe"` |
| Gold border on axe slot | ✅ `hud.set_equipped_slot(1)` shows gold border |
| No-axe toast | ✅ `can_interact()` returns false → toast "Equip axe first (C)" |
| Exactly 3 chops | ✅ `_chop_count` 0→1→2, `_is_chopped` false; at 3 `_is_chopped=true` |
| Tree→stump transition | ✅ `TreeSprite.visible=false`, `StumpSprite.visible=true` |
| Wood awarded on chop | ✅ wood count 1→2→3 across two trees |
| Multiple trees independent | ✅ Tree2 stays at `_chop_count=2` while Tree3 independently completes |
| Reusable scene instances | ✅ All 4 ChoppableTree instances have own `_chop_count`/`_is_chopped` |
| Well signal wired | ✅ `interactable_entered` 1 connection, `can_interact`/`interact` present |
| Plant signal wired | ✅ `plant_harvested → DryingRack.add_plant` 1 connection |
| Plant growth logic | ✅ `can_interact` checks `carrying_water`, frame-step loop intact |
| HUD/Inventory | ✅ `slot_changed` connected, badges update correctly |
**Rationale:** Integration tests via `execute_game_script` are the reliable path when MCP key simulation doesn't reach game `_input()` handlers. Direct method calls test the same code path the player triggers. All systems confirmed working; no regressions found.
**Consequences:** `simulate_key` via MCP godot-mcp-pro does **not** trigger `world.gd._input()` — that handler filters `event is InputEventKey` and MCP sends a different event type. Use `execute_game_script` to drive game methods directly in future tests. This is now a documented testing pattern.

---

## ADR-069: Overlay TileMapLayer + town-grass-tile Per-Tile Transparency
**Status:** Accepted
**Date:** 2026-05-19
**Context:** town-grass-tile.png (256×256, 16×16 tiles) showed solid backgrounds when painted in the world. Two problems: (1) only one TileMapLayer existed ("Ground") — painting any tile on it replaces the existing ground tile, making overlay use impossible; (2) 139 of 256 tiles in the atlas had solid-colored backgrounds (various terrain colors: dark green, grey-stone, brick-red, light green, dirt, etc.) — even on a separate layer they would block the ground.
**Decision:** Add an "Overlay" TileMapLayer as a sibling of Ground in world.tscn (same tileset, same z_index=0, positioned after Ground in tree order so it renders on top). Run a per-tile flood-fill pass on town-grass-tile.png: for each of the 256 16×16 tiles, seed from each corner; if the corner is opaque, flood-fill matching pixels within tolerance=6 and set alpha=0. 21,892 pixels made transparent across 139 tiles.
**Rationale:** Separate layer is the fundamental requirement — a single TileMapLayer can only hold one tile per cell; overlay tiles must live on a higher layer. Per-tile corner flood-fill is safer than global color replacement because different tiles have different background colors (10 distinct terrain bg colors detected). Corner seeding ensures background-connected pixels are removed while isolated interior content (the decorative graphics) is preserved.
**Consequences:** Transparent-background tiles from town-grass-tile (source 5) can now be painted on the Overlay layer, rendering on top of the existing Ground layer tiles without covering them. Tiles that were entirely background-colored (blank tiles) become fully transparent — invisible but selectable. Tileset renamed to GrassBrick_OVERLAYS__tileset.tres (ADR-070) to reflect its intended role.

---

## ADR-070: Tileset Rename — GrassBrick_OVERLAYS__tileset.tres
**Status:** Accepted
**Date:** 2026-05-19
**Context:** `world_tileset.tres` was a generic name that didn't communicate the tileset's actual purpose (grass + brick terrain tiles + overlay decoration tiles). With the Overlay layer added (ADR-069), a more descriptive name was needed.
**Decision:** Rename `res://resources/tilesets/world_tileset.tres` → `res://resources/tilesets/GrassBrick_OVERLAYS__tileset.tres`. Update the single reference in `world.tscn` ext_resource path. Trigger filesystem scan.
**Rationale:** Only one file referenced the tileset, making this a zero-risk rename. The new name immediately communicates both the terrain contents (GrassBrick) and the overlay capability (OVERLAYS).
**Consequences:** Any future file that references the tileset must use the new path. UID `uid://nk6run28bicj` is unchanged — Godot will resolve by UID even if the path is cached stale.

---

## ADR-071: Project Structure Cleanup — Remove Duplication and Stray Root Artifacts
**Status:** Accepted
**Date:** 2026-05-19
**Context:** Audit revealed a three-tier asset duplication problem: repo-root `GameAssets/` (source art), `game/GameAssets/` (legacy unused copy), and `game/assets/` (canonical). A stray `project.godot` at repo root created nested-project ambiguity. Seven art experiment directories were scattered at repo root alongside docs and tooling.
**Decision:** (1) Delete `C:\Users\erikc\Dev\Game\project.godot` (stray stub, game runs from `game/`). (2) Delete `game/GameAssets/` entirely (985 files, zero active `res://` references confirmed). (3) Delete orphan `game/assets/tiles/32x32/22222x32.tres` (empty TileSet, no references). (4) Move 7 root-level art dirs into `GameAssets/` subdirectories. (5) Archive orphaned root-level `addons/`, `screenshots/`, `states/` into `_archived/`.
**Rationale:** `game/GameAssets/` had zero active references confirmed by grep across all .gd/.tscn/.tres files. Stray project.godot risked Godot loading the wrong project if root dir was opened in editor. Art dirs at root were structurally inconsistent with the `GameAssets/` convention already in place.
**Consequences:** Project now has a clean two-tier asset structure: `GameAssets/` (source art) and `game/assets/` (in-project canonical). No active references broken — all verified before deletion.

## ADR-072: Tileset Zombie Source Cleanup + world.gd Broken Preload Fix
**Status:** Accepted
**Date:** 2026-05-20
**Context:** Missing-resource audit revealed two issues: (1) `world.gd:64` used `preload("res://GameAssets/Bud/dry_bud.png")` — a path that was deleted in ADR-071. This caused a script parse failure, preventing `world.gd` from loading at all (game unrunnable). (2) The tileset `GrassBrick_OVERLAYS__tileset.tres` contained 4 zombie `TileSetAtlasSource` entries (source IDs 2, 3, 4, 7) with null textures and 0 effective tiles. These generated ~700 C++ DEBUGGER `create_tile` errors on every game run because the .tres still had serialized tile data that Godot tried to validate against a null texture.
**Decision:** (1) Fix `world.gd:64` — change path to `res://assets/props/bud/dry_bud.png` (the file exists there). (2) Remove sources 2, 3, 4, 7 from the tileset via `execute_editor_script` → `ts.remove_source(id)` → `ResourceSaver.save()`.
**Rationale:** Sources 2/3 were the original fivegrass/mabeyfive entries whose textures were lost during previous sessions; their data was superseded by source 5 (town-grass-tile). Source 4 was a textureless duplicate of atlas_32x32 (the live version is source 6). Source 7 was beach_tiles_48x48 that was added without a texture reference. All four had 0 cells in use (verified by querying Ground and Overlay TileMapLayers). Safe to delete.
**Consequences:** Output log goes from ~700 DEBUGGER lines to 4 clean startup lines. Game loads without script parse error. Ground and Overlay tile rendering unchanged (sources 0, 1, 5, 6, 8 intact).
**Testing:** Playtested via MCP — game launched, player visible, hotbar showed bud item (confirming fixed preload), output log completely clean. ✅

---

## ADR-073: Y-Sort Offset Calibration — All World Objects
**Status:** Accepted
**Date:** 2026-05-20
**Context:** `World` node in world.tscn has `y_sort_enabled = true`, but every world object had `y_sort_offset = 0` (default). This means each object sorts by its visual CENTER, not its ground contact point. For tall or scaled sprites (willow at node_scale 2.5×, houses at 256×256px, large trees) the behind→in-front transition happened at the wrong depth — e.g. the willow (visual base at world y≈150) sorted at y=97 (canopy center), causing players walking between y=97 and y=134 to appear in front of the tree even though they hadn't passed the trunk base yet. The same issue affected all buildings, trees, props, and NPC characters.
**Decision:** Set `y_sort_offset` on all 15 visual world objects so that `position.y + y_sort_offset` equals the ground contact point (visual bottom of the sprite, or door/wall base for buildings). Values calculated from: `half_height_in_world_pixels = tex_height × sprite_scale × node_scale / 2` with node child offsets accounted for. Characters (Player, GreyHoodie NPC) sort at feet: `y_sort_offset = half_height = tex_height × sprite_scale / 2`.
**Rationale:** y_sort_offset is the correct Godot 4 mechanism for this. It is a `.tscn` serialization field only — not accessible at runtime via GDScript (CLAUDE.md: "Setting it via execute_editor_script will error"). Edits made directly to world.tscn after closing the scene in editor (open_scene → edit → reopen pattern). Final offsets: Well +24, PlayerHome +35, Player +16, Plant +24, DryingRack +30, Big Rock +31, TreeWillowWeeping +53, HouseTwostoryTeal +42, BigMushroomStump +22, GreyHoodie +19, Log1 +13, Cave entrance +15, Tree1 +36, Tree2 +37, Tree3 +48.
**Consequences:** All sprite depth transitions now occur at the visual base of each object. Fine-tuning per-object (especially HouseTwostoryTeal whose door base was estimated at 42 without verifying the texture) may be needed after in-editor walkaround. Any new world object added must have y_sort_offset set in the Inspector — it defaults to 0 and will be wrong for any sprite taller than ~16px.
**Testing:** Playtested via MCP — player teleported to willow at y=140 (feet sort_y=156), rendered correctly in front of willow (sort_y=150). Player teleported behind bakery at y=95 (feet sort_y=111), correctly hidden behind building (bakery sort_y=115). NPC visible in front of well and teal house. ✅

---

## ADR-074: Remove Three Standard Choppable Tree Systems
**Status:** Accepted
**Date:** 2026-05-20
**Context:** The three choppable tree instances in world.tscn (Tree1/Tree2/Tree3 using pine_bushy_b, pine_narrow, ginkgo textures via `choppable_tree.tscn`) are being removed entirely. The four species-variant scenes (choppable_tree_pine/maple/fir.tscn) were also standalone scenes never placed in the world. All were tied to the `choppable_trees` group signal pipeline in world.gd. The willow tree is a completely separate system (proximity animation only, no chop/wood system) and must remain.
**Decision:** Delete all ChoppableTree files (base scene + 3 variant scenes + script + uid). Remove all 5 ext_resource entries and 3 node instances from world.tscn. Remove from world.gd: `CLICK_TREE_RADIUS` const, `choppable_trees` group signal loop, `_on_wood_chopped()`, `is_chopping` triggers, tree search in `_on_right_click`, `is_in_group` check in `_do_nav_interact`. Delete all tree/stump assets exclusively used by these systems (6 static PNGs, 7 animation directories, stump_round + dissolve, log_brown_short).
**Rationale:** The three trees were placeholder geometry. Removing them cleans the world for redesign. The axe system (EQUIPPABLE_TOOLS, equip_toggle, HUD gold border) is generic and stays — no code changes to player.gd, player_animation.gd, InventoryManager, or HUD.
**Consequences:** World now has no choppable trees. `is_chopping` player flag exists in player.gd/player_animation.gd but is never set from world.gd — the chop animation is dormant (not broken). The "wood" starting item remains in `_grant_starting_items()` but there is no longer any in-game source of additional wood. Willow, Well, Plant, DryingRack, NPC trade, door transitions — all unaffected.
**Testing:** Validated via grep — zero remaining references to any removed identifiers. Detailed report in `tree_removal_report.md`. Playtest pending.

---

## ADR-075: Pine/Maple/Fir Choppable Tree Integration
**Status:** Accepted
**Date:** 2026-05-20
**Context:** ADR-074 removed the old three-tree system. The new pine/maple/fir assets (96×96, generated via PixelLab) with full chop+fall+hit_fall animations were staged in `GameAssets/TempAssetHolding/ResolvedReview/`. A clean reusable architecture was needed to replace the old system.
**Decision:** New scene architecture — single shared `choppable_tree.gd` (StaticBody2D root) with `@export var species` to select chop variant; one .tscn per species (pine/maple/fir); shared `stump_frames.tres`; 4 SpriteFrames `.tres` files. Group-based signal wiring in world.gd iterates `"choppable_trees"` group. 3 trees placed in grass area at (55,165), (200,162), (50,240).
**Rationale:** Self-registering group pattern (established in ADR-051) means world.gd needs no per-tree wiring — any new tree dropped in world gets auto-connected. Species `@export` keeps scenes separate but script shared. Shared stump avoids per-species stump assets.
**Consequences:** Pine/Maple/Fir fully choppable (3 hits each). Maple has 50% chance of `hit_fall` animation on final chop. Stump plays 16-frame dissolve then disappears. Wood inventory granted on `tree_chopped` signal. `is_chopping` player flag wired again. Phantom Tree1/Tree2/Tree3 nodes (editor cache artifact) were deleted in same session.
**Testing:** Pine fully playtested via `execute_game_script` — 3 chops → chop anim × 3 → fall → stump dissolve → state=GONE → wood count 1→2. Screenshot confirmed pine absent from world after fall. Maple/Fir visually confirmed present and correctly sorted. 0 errors on boot.

---

## ADR-076: Fix Duplicate Tree Nodes + Rescale Tree/Stump Sprites
**Status:** Accepted
**Date:** 2026-05-20
**Context:** After ADR-075 placed the three choppable trees via MCP `add_scene_instance` + `add_node`, each tree ended up with duplicate child nodes (`TreeSprite2`, `StumpSprite2`, `TrunkCollider2`, `InteractArea2`, `InteractCol2`). These were created because `add_node` calls for `TreeSprite` etc. found a node of that name already present (from the instanced scene) and Godot auto-renamed the new node to `TreeSprite2`. The `choppable_tree.gd` script correctly controls `$TreeSprite` (the original), but `TreeSprite2` persisted permanently showing the idle PNG — appearing as a static "ghost" image during and after the chop/fall animation. Also, tree sprites at scale 0.5 on 96×96 art were visually small; stump dissolve at 0.5 scale was proportionally too large.
**Decision:** Use an editor script to delete all 15 duplicate nodes (5 per tree × 3 trees) from world.tscn. Update `TreeSprite` scale to `Vector2(0.625, 0.625)` (+25%) and `StumpSprite` scale to `Vector2(0.125, 0.125)` (−75%) in each source .tscn (pine/maple/fir_tree.tscn) via editor script + save_scene.
**Rationale:** Root cause was the MCP add_node pattern — instanced scenes already contain their children, so any subsequent add_node call for those same node types creates duplicates. The correct pattern for scene children is to modify them via overrides or editor script on the instanced root, not add_node. Scale changes improve visual readability of the trees and make the stump more proportionate during its brief dissolve.
**Consequences:** Ghost idle image gone — chop/fall/stump animations are now clean. Tree sprites 25% larger, stumps 75% smaller. world.tscn lost 70 lines of spurious node declarations. Orphaned sub_resources (TrunkShape, CapsuleShape2D_isdyu, CapsuleShape2D_c4deb) also removed by Godot on save. Future tree instances: never use add_node to add children to an already-instanced scene — use execute_editor_script to set properties on existing children.
**Testing:** Playtested — 3 chops on Pine → chop anim × 3 → fall anim → stump dissolve → state=GONE, tree_vis=false, stump_vis=false. No ghost image at any stage. Wood ×2 awarded. Maple and Fir intact.

---

## ADR-077: Tree Chop Timing Delay + Static Stump + Stump Position Fix
**Status:** Accepted
**Date:** 2026-05-21
**Context:** Three problems in the choppable tree system: (1) tree chop/fall animations fired the same frame as axe input — no delay between player swing and tree reaction; (2) stump played dissolve animation immediately after appearing, then disappeared; (3) stump spawned at StaticBody2D origin (tree center/canopy area) instead of the trunk base, causing visual floating.
**Decision:** (1) Timing: `interact()` sets `player.is_chopping=true` immediately, then `get_tree().create_timer(0.5)` fires `_begin_tree_reaction()` 0.5s later to start the tree animation. `player.is_chopping=false` is also reset in `_begin_tree_reaction` (player swing finishes just as tree starts reacting). (2) Stump: replaced `_stump_sprite.play("dissolve")` with `stop()` + `animation = "idle"` + `frame = 0` — shows `stump_idle.png` as a static frame. Removed `_on_stump_anim_finished()` and its signal connection. `State.GONE` removed from enum. (3) Position: added `@export var stump_y_offset: float = 28.0` set via `_stump_sprite.position = Vector2(0.0, stump_y_offset)` in `_ready()`. Offset 28.0 derived from sprite measurement: tree trunk base at ~y=87 in 96×96 sprite at scale 0.625 = 24.4 world units below origin; stump cut surface at ~y=8 at scale 0.125 = -5 world units from stump center; net offset = 24.4 - (-5) ≈ 28.
**Rationale:** `create_timer()` one-shot approach is lightweight and self-cleaning. Exporting `stump_y_offset` lets designers tune per-species without code changes. Using the `idle` animation (single stump_idle.png frame) rather than dissolve frame 0 makes intent explicit and future-proof.
**Consequences:** Player swing now visually precedes tree reaction by 0.5s — satisfying cause-and-effect. Stump stays on screen permanently (no GONE state) until scene reload — acceptable for current phase. `stump_y_offset` defaults to 28.0 (all three species share same offset; can be overridden in Inspector per instance). Chop state machine now: IDLE→CHOPPING→FALLING→STUMP (no GONE). Only `choppable_tree.gd` changed — no .tscn file edits needed.
**Testing:** Full 3-chop pipeline verified: state transitions IDLE×3→CHOPPING→FALLING→STUMP correct; stump_playing=false; stump_anim=idle; stump_frame=0; stump_pos=(0,28); tree_vis=false after fall; wood ×2 granted. Report: `tree_animation_stump_fix_report.md`.

---

## ADR-078: Farming System — 6 Regression Fixes
**Status:** Accepted
**Date:** 2026-05-21
**Context:** Six farming mechanics were broken: (1) well animation not resetting after interaction; (2) Space key showed "Equip axe first (C)" for all interactables when blocked; (3) well animation looped indefinitely during interaction instead of playing to end; (4) bucket animations caused player sprite to freeze when carrying_water=true (missing _bucket variants); (5) plant animation could hang forever if sprite_frames.get_animation_speed("default") returned 0; (6) water→plant state flow appeared broken due to wrong feedback and timing.
**Decision:** (1+3) `world.tscn` WellWaterFrames: `"loop": true` → `"loop": false`. `well.gd`: replaced all stop()+frame=0 resets with `_reset_sprite()` which calls `play("default")→stop()→frame=0` — `play()` clears the internal backwards-play flag that `stop()` alone does not clear. Removed dead `animation_finished` connection (never fires on looping animations; even with loop:false, the 0.25s timer fires first). (2) `world.gd`: replaced hardcoded `"Equip axe first (C)"` toast with a `blocked_message(player)` dispatch — if the target has the method, use its message; else fall back to the axe message. `well.gd` returns "Already carrying water"; `plant.gd` returns "Need water first"; trees (no method) get the axe message unchanged. (4) `player_animation.gd`: added `sprite_frames.has_animation(anim)` guard before `play()`; if a `_bucket` variant is absent, falls back to the base animation (`"idle_down"` etc.) so the sprite never freezes. (5) `plant.gd`: `get_animation_speed($PurplePlant.animation)` (uses actual animation name, not hardcoded "default") + `if fps <= 0.0: fps = 8.0` guard prevents `create_timer(INF)` hang. (6) No code change needed — bugs 1–5 fixes restore correct observable feedback; `carrying_water` timing (set after 0.25s await) is correct by design.
**Rationale:** `play()+stop()` is the reliable reset idiom in Godot 4.6 — `play()` is the only API that clears the backwards-play flag. `blocked_message()` duck-typing keeps interactables self-describing without a shared base class. `has_animation()` guard is defensive and prevents sprite-freeze even when SpriteFrames is incomplete.
**Consequences:** WellWater animation no longer loops during collection (plays 2 frames backwards at 2.22× then stops cleanly). Toast messages are now interactable-specific. Player sprite falls back to non-bucket animation instead of freezing (visible hint that bucket assets need adding to SpriteFrames). Plant animation never hangs. Full farming loop (well→water plant×3→harvest→drying rack) is repeatable indefinitely with no state corruption.
**Testing:** Script-driven: well interact → `frame=0`, `carrying_water=true`, `_collecting=false` confirmed. Plant advanced stages 0→1→2→3 with correct frames (5, 10, 0 after reset). DryingRack `_state=1` after harvest. Second full cycle started (well `can_interact=true`, plant `can_interact=true` with water, `well.blocked_message='Already carrying water'` confirmed). No regressions to axe/tree/NPC/inventory/drying rack.

---

## ADR-079: Tree Scale +20%, Y-Sort Formula, Left-Click Chop
**Status:** Accepted
**Date:** 2026-05-21
**Context:** Trees at scale 0.625 were visually small. Y-sort threshold of 36 (sprite half-height) caused the player to render behind trees too early — should transition exactly when player feet reach the trunk base. Left-click on trees moved the player but did not trigger interact.
**Decision:** TreeSprite scale 0.625→0.75, StumpSprite 0.125→0.15 across all three species .tscn files. Y-sort offset formula: `stump_y_offset(28) − player_half_height(16) = 12` → changed all three tree instances in world.tscn from 36→12. Added tree detection block in `world.gd _on_right_click()`: iterates `choppable_trees` group, detects click within 35px of any tree, sets `_nav_target_node` + `_nav_pending_interact`. `_do_nav_interact()` updated to show blocked toast when `can_interact` returns false (matching Space-key path).
**Rationale:** Y-sort threshold should match the visual ground contact point (trunk base), not the sprite's geometric bottom. The left-click fix reuses the existing NPC nav pattern — no new systems needed.
**Consequences:** Player appears in front of tree exactly when feet reach trunk base. Left-click chop now navigates to tree and chops on arrival if axe equipped, shows toast if not. `reload_project` required after editing world.tscn on disk — `open_scene` alone does not flush the runtime resource cache.
**Testing:** Script-driven: forced pine through FALLING→STUMP transition, player blocked by stump collider at expected distance. Left-click tree detection verified at 35px radius. Y-sort transition confirmed visually at trunk base.

---

## ADR-080: Stump Colliders + Log1 Removal
**Status:** Accepted
**Date:** 2026-05-21
**Context:** After a tree is chopped, the stump sprite appears but the player could walk through it — no collision. Log1 (a decorative fallen log Sprite2D with its own shadow and collision shape) was a leftover world prop to be removed.
**Decision:** Added `StumpCollider` (CollisionShape2D, CircleShape2D radius=7) to `pine_tree.tscn`, `maple_tree.tscn`, and `fir_tree.tscn`. In `choppable_tree.gd`: added `@onready var _stump_col` reference; `_ready()` sets `_stump_col.position = Vector2(0, stump_y_offset)` and `_stump_col.disabled = true`; fall-complete branch (`State.FALLING` → `State.STUMP`) sets `_stump_col.disabled = false`. Removed Log1 from world.tscn (Sprite2D + Shadow + TreeCollider StaticBody2D + CollisionShape2D), its exclusive ext_resource (log_fallen_brown.png, id=45_i52kj), and its exclusive sub_resource (RectangleShape2D_3gnva).
**Rationale:** Stump collider radius 7px matches the ~14px rendered size of the stump sprite (96×96 at scale 0.15). Position is set in script to stay in sync with `stump_y_offset` export var. Log1 removal is clean — no world.gd references, no shared resources.
**Consequences:** Stumps block player movement after chop. Trunk collider disables on chop (existing behavior); stump collider enables at the same moment. Tree scenes (pine/maple/fir) are fully self-contained reusable prefabs: drag `fir_tree.tscn` from FileSystem into world viewport to place a new wired tree. Log1 and all its assets are gone; no other nodes depended on them.
**Testing:** Script-driven: all 3 trees showed `StumpCollider disabled=true` at game start. Pine forced to STUMP state → `disabled=false` confirmed. Player at (250,300) walked north toward stump at (250,281) → stopped at y=294 (gap=13 = player_radius 6 + stump_radius 7). Maple+fir remained IDLE with collider disabled. 0 editor errors after Log1 removal.

---

## ADR-081: Temp Asset Import — Grove Dwellings, Bushes, Stones, UI Currency Icons
**Status:** Accepted
**Date:** 2026-05-22
**Context:** Four PixelLab-generated asset batches were sitting in `temp/` with machine-generated folder names (UUID fragments, prompt-truncated strings like `Top-down_view_of_tree_stump_ho_2`). The assets were not in `game/assets/` so Godot could not import or reference them.
**Decision:** Viewed each PNG visually to identify content, then copied to descriptive snake_case paths under `game/assets/`:
- 8 stump dwelling sprites → `game/assets/structures/grove/` (`stump_door_twisted`, `stump_home_hanging_post`, `stump_home_stone_well`, `stump_dwelling_birdhouse`, `stump_home_log_door`, `stump_home_totem`, `stump_home_mushroom`, `stump_home_mossy_mound`)
- 14 bush variants → `game/assets/nature/bushes/` (`bush_round_small`, `bush_hedge_wide`, `bush_dense_flat`, `bush_round_tall`, `bush_round_large`, `bush_wild_uneven`, `bush_wide_spreading`, `bush_hedge_block`, `bush_wild_scraggly`, `bush_hedge_low`, `bush_flowering`, `bush_conical`, `bush_sparse_flat`, `bush_hedge_corner`)
- 6 stone static sprites + 6 animation subdirs (53 frames) → `game/assets/nature/rocks/` (`stone_cluster_a` with `hit/`×9f + `hit_2/`×9f; `stone_pile_square` with `hit/`×16f; `rock_jagged` with `hit/`×9f + `break/`×9f; `rock_slate_flat` with `crumble/`×9f; `boulder_smooth`; `stone_pile_debris`)
- 4 currency UI icons → `game/assets/props/items/` (`currency_bill`, `currency_coin`, `currency_bills_wad`, `currency_coins_stack`)
**Rationale:** Names derived from visual content inspection, not AI-generated prompt names. Animation frames follow the existing tree animation directory pattern (`stone_cluster_a/hit/frame_000.png`). `temp/` folder left untouched.
**Consequences:** 32 new assets auto-import into Godot on next editor scan. None are wired into scenes yet. Animated stones require SpriteFrames `.tres` resources before use. `stump_door_twisted.png` is 48×48 (distinct entrance style); all other grove items are 64×64. Currency icons are 48×48, suitable for hotbar/UI use.
**Testing:** File presence confirmed via PowerShell copy output (0 errors, all 32 files + 53 animation frames copied).

---

## ADR-082: Stump Home 001 — Asset Import, SpriteFrames, World Placement
**Status:** Accepted
**Date:** 2026-05-22
**Context:** `temp/Stump_Home_001` contained a 128×128 stump house still PNG, a lights-on variant, and a 16-frame door-open/close animation. `temp/StillPNGs_Stump_Homes` contained 3 additional still variants. The world had a placeholder `StumpIdle` Sprite2D at (19, 318) using `stump_idle.png` — a simple round stump, not a dwelling. This session begins the stump shrine / grove gameplay system.
**Decision:**
1. Copied all assets to `game/assets/structures/grove/`: `stump_home_001.png`, `stump_home_001_lights.png`, `stump_home_002–004.png`, and `stump_home_001_door/frame_000–015.png`.
2. Created `res://resources/structures/stump_home_001_frames.tres` — SpriteFrames with `idle` (1 frame, loop) and `door_open` (16 frames @ 8fps, no loop).
3. Deleted `StumpIdle` Sprite2D from `world.tscn`, added `StumpHome001` AnimatedSprite2D at (13, 311), playing `idle`, SpriteFrames assigned.
4. User manually resized in editor — canonical scale is `Vector2(0.1953125, 0.1953125)` for all 128×128 grove dwelling sprites (~25px world-space display).
5. Both temp folders archived to `_archived/StumpHomes/` then deleted.
**Rationale:** AnimatedSprite2D chosen (over Sprite2D) so `door_open` can be triggered by the TBD activation mechanic without swapping nodes. Scale derived by user visual judgement against existing world objects.
**Consequences:** `door_open` animation is wired but never triggered yet — activation mechanic is TBD. `stump_home_002–004.png` are imported but not placed. All stump home / grove dwelling assets placed henceforth must use scale 0.1953125.
**Testing:** Playtested — stump home visible at lower-left grove position, idle animation running, no regressions in farming/chop systems. ✅

---

## ADR-083: ForestCreature Y-Sort Depth Sorting + Flee Behavior Polish
**Status:** Accepted
**Date:** 2026-05-22
**Context:** The ForestCreature (hobo man, 22px tall at scale 0.177) had no `y_sort_offset`, so it always sorted at its node origin rather than its ground contact point. This caused it to render in front of trees even when it was visually behind them. Additionally, the flee behavior was purely reactive (direct away from player at constant speed) with no differentiation between a stationary player nearby vs. a player actively chasing.
**Decision:**
1. Added `y_sort_offset = 11` to the `ForestCreature` node in `world.tscn` (half of 22px visual height → sorts at feet).
2. Retyped `_player` from `Node2D` to `CharacterBody2D` in `forest_creature.gd` to enable clean `.velocity` access without dynamic dispatch.
3. Added approach detection: `player_approaching = _player.velocity.dot(flee_dir) > 8.0` — true when player is actively moving toward the creature.
4. Speed boost when chased: `APPROACH_FLEE_MULT = 1.4` (34 → ~48px/s), normal speed when player is stationary nearby.
5. Upward bias when chased: flee direction gets a `Vector2(0, -0.35)` component added then renormalized — pushes creature toward the northern tree line where it can hide.
**Rationale:** `y_sort_offset` is a .tscn-only serialization field in Godot 4.6.2 — cannot be set via GDScript at runtime; must be written directly in the scene file. The 11px offset matches the visual half-height so sort transitions feel correct as the creature crosses a tree's sort threshold. The upward bias is subtle enough not to override the away-from-player direction but meaningfully favors heading toward cover. 1.4× speed avoids a "teleport" feel while still feeling like genuine flight.
**Consequences:** Creature now disappears behind trees when its sort key falls below the tree's (e.g., creature at local y=158+11=169 < pine at y=165+12=177). Upward bias works best with the current tree cluster north of the creature's spawn area — if the world layout changes, the bias direction may need revisiting.
**Testing:** Frozen creature at pine trunk (local y=158) confirmed occluded by pine (local y=165). Player at local y=208 remains visible in front of same pine. Clean boot, no parse errors. Flee triggers and creature runs north. ✅

---

## ADR-084: ForestCreature Tree-Hopping Primary Movement
**Status:** Accepted
**Date:** 2026-05-22
**Context:** ForestCreature was using pure random wander (`randf() * TAU` → new direction every 1.5–4s), which sent it to map edges and open terrain instead of keeping it in the wooded cluster. The stated requirement is: tree-hopping as the primary movement pattern — dart to a tree, hide briefly, pick the next tree. Edge-avoidance should be a consequence of tree placement, not a dedicated behavior.
**Decision:**
1. Replaced random wander with a 3-state machine: `TREE_HOP` (moving toward target tree) → `HIDING` (0.7–2.2s pause at tree) → `TREE_HOP`.
2. `_gather_trees()` runs deferred in `_ready()` — collects all tree nodes in two passes: `get_nodes_in_group("choppable_trees")` + name-pattern scan of World's children for "Tree/Pine/Maple/Fir/Willow". Result: 13 trees at runtime.
3. `_pick_next_tree()` filters to trees inside global camera bounds minus 20px margin, then prefers trees within 150px (`HOP_NEAR_RADIUS`). Falls back to any valid tree if none are close.
4. Flee behavior updated: steers toward nearest tree in the flee direction (within 80px, dot ≥ 0.2) so the creature runs for cover rather than open terrain.
**Rationale:** Trees are static-body nodes already present in the scene; scanning for them by group + name pattern avoids requiring all tree scenes to add a new group registration. The 150px near-preference keeps hops short (within the dense cluster) without ever forcing a destination. Border-safety is implicit — there are no trees near map edges.
**Consequences:** Creature always stays in the wooded area as long as trees exist there. If all trees are chopped, creature has no targets and stops. `HOP_NEAR_RADIUS = 150` may need widening if more trees are added far apart. TreeWillowWeeping (467,97) is in the candidate pool but almost never selected since it's far from spawn; adjust `HOP_NEAR_RADIUS` or exclude it explicitly if it causes breakout behavior.
**Testing:** Three screenshots confirmed creature moving between left wooded cluster (PineTree2/3/4, MapleTree cluster) over 30s, never reaching map border corners. Flee test: creature steers toward tree in flee direction. ✅

---

## ADR-085: Y-Sort Offset Full Restoration — All 25 World Objects
**Status:** Accepted
**Date:** 2026-05-22
**Context:** Audit confirmed that all y_sort_offset values set in ADR-073 (and trees in ADR-079) had been silently lost from world.tscn. Every subsequent session that rewrote or heavily edited world.tscn (ADR-074 through ADR-084) overwrote the file without preserving y_sort_offset fields. Only ForestCreature (=11, set in the previous session) remained. Result: all 24 other world objects sorted at their node origin (y_sort_offset=0), causing wrong depth transitions — player appeared behind the bakery too soon, in front of trees too late, etc.
**Decision:** Audit method: grep world.tscn for all `y_sort_offset` occurrences → found only 1 (ForestCreature). Cross-reference ADR-073/079 values against current node positions. Write all 25 y_sort_offset values directly to world.tscn (close-scene-first pattern via MCP open_scene).

Values restored:
| Node | position.y | y_sort_offset | sort_y | Source |
|---|---|---|---|---|
| Well | 75 | 24 | 99 | ADR-073 tested |
| PlayerHome | 80 | 35 | 115 | ADR-073 tested |
| Player (instanced) | 200 | 16 | 216 | ADR-073 tested |
| Plant | 109 | 24 | 133 | ADR-073 |
| DryingRack | 75 | 30 | 105 | ADR-073 + ADR-025 |
| Big Rock | 131 | 31 | 162 | ADR-073 |
| TreeWillowWeeping | 97 | 53 | 150 | ADR-073 tested |
| HouseTwostoryTeal | 75 | 42 | 117 | ADR-073 estimate |
| BigMushroomStump | 141 | 22 | 163 | ADR-073 |
| GreyHoodie | 158 | 19 | 177 | ADR-073 |
| Cave entrance | 407 | 15 | 422 | ADR-073 |
| StumpHome001 | 311 | 12 | 323 | calculated (128px × 0.195 ≈ 25px, half=12) |
| All 12 choppable trees | varies | 12 | varies | ADR-079 formula |
| ForestCreature | 320 | 11 | 331 | ADR-083/084 (already set) |

**Rationale:** y_sort_offset is a `.tscn`-only serialization field — cannot be set at runtime via GDScript (Godot 4.6.2). It must be written directly to world.tscn and is silently dropped any time the file is regenerated or rewritten. The fix uses the Edit tool on the raw .tscn file after closing the scene in the editor.
**Consequences:** All 25 world objects now sort by their visual ground contact point. Any future world.tscn rewrite (via execute_editor_script PackedScene pattern or full file replacement) will lose these values again — must be reapplied. Adding new world objects requires explicitly setting y_sort_offset in the Inspector before committing.
**Testing:** Playtested via MCP. Player teleported to local (55,155): hidden behind PineTree1 (sort_y 177 > player sort_y 171). Player teleported to (55,182): fully visible in front of same tree (player sort_y 198 > 177). Screenshot confirmed. 0 errors on boot. ✅

---

## ADR-086: Sprite Size + Collision + Camera Audit — Full Reconciliation
**Status:** Accepted
**Date:** 2026-05-22
**Context:** Stop-hook required a 7-item audit after ADR-085 only addressed y_sort_offset. The remaining items: (2) actual PNG frame dimensions, (3) scale reconciliation world.tscn vs .tscn defaults, (4) ADR cross-reference for the breaking scale changes, (5) collision shape audit, (6) camera zoom/viewport, (7) Area2D radii.

**Findings and fixes:**

**PNG Frame Dimensions (Item 2) — audited via execute_editor_script:**
| Sprite | Actual Size | Scale | Visual Size | Notes |
|---|---|---|---|---|
| Erik (player) | **56×56** | 0.5 | **28×28px** | ADR-013/057 claimed 64×64 — wrong |
| Hobo man (ForestCreature) | **124×124** | 0.177 | **22×22px** | ADR claimed 128×128 — off by 4px |
| Pine/Maple/Fir idle | 96×96 | 0.75 | 72×72px | ✓ |
| Stump idle + dissolve frames | 96×96 | 0.15 | 14.4×14.4px | ✓ |
| Willow frames | 96×96 | root 2.975×AnimSpr 0.505 | ~144×144px | Complex layered scale |
| Well water frames | 48×48 | 1.0 | 48×48px | ✓ |
| BigMushroomStump | 48×48 | 1.0 | 48×48px | visible=false |
| Grey hoodie NPC | 92×92 | 0.6 | 55×55px | Half=27.5; y_sort_offset=19 (8.5px low, acceptable) |
| Rock grey cluster | 58×63 | 1.0 | 58×63px | ✓ |
| Cave entrance | 34×31 | 1.0 | 34×31px | ✓ |
| Bush sparse flat | 48×48 | 1.0 | 48×48px | ✓ |
| StumpHome001 | 128×128 | 0.1953125 | 25×25px | ✓ |
| Bakery (per frame) | 256×256 | 0.5 | 128×128px | 3×3 spritesheet |
| Teal house (per frame) | 256×256 | 0.6 | 154×154px | 3×3 spritesheet |

**Scale reconciliation (Item 3):** No world.tscn overrides on any choppable tree instances — all use .tscn defaults (TreeSprite=0.75, StumpSprite=0.15). Player uses player.tscn default (AnimatedSprite2D scale=0.5). No conflicts found.

**ADR breaking-change cross-reference (Item 4):**
- **ADR-076:** TreeSprite 0.5→0.625 — first change that required y_sort recalibration; old offsets became incorrect.
- **ADR-079:** TreeSprite 0.625→0.75 — second change; recalibrated using player_half_height=16 (assumed 64×64 sprite). Actual sprite is 56×56 → correct half_height=14 → correct offset would be 28-14=14, not 12. 2px error, visually confirmed acceptable.
- Player sprites were always 56×56 (not 64×64 as ADR-013 stated). Discovered this session.

**Collision shape audit (Item 5):**
| Shape | Size | Node | Assessment |
|---|---|---|---|
| WellCollider | Circle r=18 | Well | 18px vs 24px visual radius — 6px inset, acceptable |
| WellArea | Circle r=26 | Well | Slightly larger than visual, generous trigger ✓ |
| PlantArea | Circle r=32 | Plant | Generous, functional ✓ |
| PlantCollider | Circle r=6 at (0,5) | Plant | visible=false, minimal blocker ✓ |
| DRackShape | Rect 44×10 at (0,26) | DryingRack | Covers base of rack ✓ |
| LogCollider (BigRock) | Rect 50×22 rotated | Big Rock | Set up for old log sprite; 24×22 effective for 58×63 rock. Low priority ✓ |
| TrunkCollider (Pine/Maple) | Capsule r=5 h=10 at (0,16) | Trees | Covers trunk area ✓ |
| TrunkCollider (Fir) | Capsule r=4 h=14 at (0,16) | Fir | **FIXED**: was scale=(1.27,-0.94) — negative y flipped physics resolution. Reset to scale=(1,1), position=(0,16) ✓ |
| StumpCollider | Circle r=7 | Trees | 14px diameter for 14.4px visual stump ✓ |
| InteractArea | Circle r=22 | Trees | Chop proximity trigger ✓ |
| Bakery WallCenter/LeftLower/RightLower | Rect 60×25, 21×31, 22×30 | PlayerHomeCollider | Multi-shape door gap ✓ |
| HouseTeal WallCenter | Rect 48.5×33.4 | HouseTealCollider | Single estimated box, no door gap ✓ |
| Borders | 640×16, 17×474, 16×480 | Borders | Map edges ✓ |
| NPCHomeDoor | Rect 30×10 | Area2D | NPC home trigger ✓ |

**Camera zoom/viewport (Item 6):** zoom=(0.87,0.87) was **lost from player.tscn** (same serialization-loss pattern as y_sort_offset). Restored. Visible area: ~368×207px world at 320×180 logical viewport. Limits (global L/T/R/B): 195/88/835/584 ✓.

**Area2D radii (Item 7):** WellArea r=26, PlantArea r=32, TreeInteract r=22, WillowProximity ~13px world, NPCTrade=36px (world.gd constant), DoorEntrance 14×6, NPCHomeDoor 30×10. All appropriate for their sprite sizes and intended interaction ranges ✓.

**Fixes made:**
1. `fir_tree.tscn` TrunkCollider: removed bad scale (1.27, -0.94) → (1, 1), position (2,16)→(0,16)
2. `world.tscn` Player y_sort_offset: 16→14 (actual sprite 56×56 at 0.5 = 28px visual, half=14)
3. `player.tscn` Camera2D zoom: restored (0.87, 0.87)

**Known acceptable discrepancies (not fixed):**
- Tree y_sort_offset=12 ← **INCORRECT — see ADR-087 for fix.** User confirmed player/ForestCreature still rendering in front of tree canopy.
- GreyHoodie y_sort_offset=19 vs actual correct 27.5. 8.5px low but NPC patrol stays south of teal house, so no visible sorting conflicts.
- BigRock LogCollider shape is for old log sprite, poorly fits 58×63 rock. Low priority static scenery.

**Consequences:** ADR-013 and ADR-057 sprite size claims (64×64, 128×128) are incorrect. All y_sort_offset formulas using player_half_height=16 are slightly off (should use 14). The 2px error is imperceptible at game scale. Future sprite calibration should use player_half_height=14.
**Testing:** Camera zoom confirmed at runtime (0.87, 0.87). Fir TrunkCollider scale confirmed (1,1) at runtime. Game boots clean, player + NPC + ForestCreature visible with correct depth sorting. Screenshot confirmed wider viewport and correct rendering. ✅

---

## ADR-087: Tree y_sort_offset Formula Correction — 12 → 28
**Status:** Accepted
**Date:** 2026-05-23
**Context:** User confirmed after ADR-085/086 that player and ForestCreature (ShT) still rendered in front of tree canopy when approaching from the north or walking past tree edges. The "2px difference" noted in ADR-086 as acceptable was in fact a 16px formula error causing a 34px incorrect band.

**Root cause:** ADR-079 set `y_sort_offset = stump_y_offset - player_half_height = 28 - 16 = 12`. The subtraction was wrong. The correct formula is:

```
tree_y_sort_offset = stump_y_offset (ground level of tree)
player_y_sort_offset = player_half_height (player's feet)

Depth transition triggers when:
  player.position.y + player_y_sort_offset = tree.position.y + tree_y_sort_offset
  player.position.y + 14 = tree.position.y + 28
  → player appears in front when player.position.y > tree.position.y + 14
  → player.feet (y+14) > trunk base (tree.y+28)  ✓
```

With old offset=12: transition at player.y = tree.y − 2 (2px north of tree center). Tree canopy extends 36px above center → 34px band where player was visually inside canopy but rendered in front.

**Decision:** Change all 12 choppable tree instances in `world.tscn` from `y_sort_offset = 12` → `y_sort_offset = 28`.

**Rationale:** The tree's depth sort key should equal the trunk base position (stump_y_offset=28 from tree origin). The player and ForestCreature each use their own half-height offsets independently — they do not subtract from the tree's offset. The offsets are compared against each other at sort time, not added together.

**Consequences:** Player and ForestCreature correctly render behind tree canopy until their feet pass the trunk base. Tested: behind at y=179 (feet=193, trunk base=193), in front at y=181. StumpHome001 y_sort_offset=12 left unchanged (correct for 25px stump visual, half=12.5).

**Files changed:** `game/World/world.tscn` — 12 nodes (TreePine1, TreeMaple1, TreeFir1, MapleTree, MapleTree2, FirTree, FirTree2, PineTree, PineTree2, PineTree3, PineTree4, MapleTree3).

**Testing:** Screenshot confirmed player hidden behind tree at trunk level, appears in front just past trunk base. ForestCreature offset=11 (its own half-height) also correctly sorts behind trees. ✅

---

## ADR-088: Tree y_sort_offset Persistence Fix + Value Calibration — 28 → 22
**Status:** Accepted
**Date:** 2026-05-23
**Context:** After ADR-087 set y_sort_offset=28 as instance overrides in world.tscn, the editor stripped those overrides on every resave (node move, MCP save_scene, etc.), silently resetting all trees to offset=0. The fix-strips-on-save loop was the root persistence bug. Additionally, empirical testing showed offset=28 placed the transition 5px too far south — player was still behind the tree at y=190 (feet at y=204, visually at the lower branch tips) when they should have been in front.

**Decision:**
1. Bake `y_sort_offset = 22` directly into the three base tree .tscn files (`pine_tree.tscn`, `maple_tree.tscn`, `fir_tree.tscn`) on the root node. Instance overrides in world.tscn are never written by the editor; values in the base scene survive every resave permanently.
2. Remove the spurious `y_sort_enabled = true` instance override on TreePine1 in world.tscn. (This sorted TreePine1's own children against each other, which was meaningless and caused StumpSprite to render in front of TreeSprite during the chopping transition.)
3. Value changed 28 → 22: transition fires when player feet reach ~y=203 (lower visible branch tips), not y=209 (physical trunk base as positioned by stump_y_offset). The 6px difference corresponds to the gap between the stump sprite center placement and the actual lowest visible canopy pixel.

**Rationale:** Instance overrides in world.tscn are always at risk of being stripped — any editor operation that rewrites the scene file loses overrides that don't have a matching property in the base scene. The only durable solution is to own the value in the base scene. Value 22 confirmed empirically: player at y=175 fully behind tree ✅, y=185 correctly behind (mid-branch zone) ✅, y=190 fully in front ✅.

**Key discovery:** `y_sort_offset` is NOT accessible via GDScript `get()` at runtime (returns null) — it is an engine-internal serialization field applied at scene load. `pine.y_sort_offset` raises a runtime error. Do not try to read or set it in execute_game_script; verify by playtesting positions.

**Consequences:** All 12 choppable tree instances in world.tscn now inherit offset=22 automatically. No per-instance overrides needed. Future tree placements (drag from FileSystem) get the correct offset for free.

**Files changed:** `game/scenes/interactables/trees/pine_tree.tscn`, `maple_tree.tscn`, `fir_tree.tscn` — root node `y_sort_offset = 22` baked in. `game/World/world.tscn` — `y_sort_enabled = true` removed from TreePine1 instance override.

**Testing:** y=175 → behind ✅; y=185 → behind (mid-branch, partially visible through transparency — correct) ✅; y=190 → fully in front ✅. Transition at player.y≈189, feet at y≈203. ✅

---

## ADR-089: Full Physics/Collision/Y-Sort Audit + Standardization
**Status:** Accepted
**Date:** 2026-05-23

**Context:** Recurring y_sort_offset loss (ADR-073→085→088) plus no authoritative documentation of collision body types, layers, or sprite ownership rules. Goal: complete audit of every player↔environment interaction, document the canonical state, fix all outstanding bugs.

**Findings:**

### Collision Body Type Matrix

| Object | Node Type | Physics Body | Collision Shape | Notes |
|--------|-----------|-------------|-----------------|-------|
| Player | CharacterBody2D | self | CapsuleShape2D r=4, h=12 | player.tscn |
| ForestCreature | CharacterBody2D | self | CapsuleShape2D r=4, h=4 at (0,3) — runtime | forest_creature.gd |
| Well | Node2D | WellCollider StaticBody2D | CircleShape2D r=18 (block) | WellArea Area2D r=26 (interact) |
| Plant | Node2D | PlantCollider StaticBody2D at (0,5) | CircleShape2D (small) | PlantArea Area2D (interact) |
| DryingRack | Sprite2D | DryingRackCollider StaticBody2D | RectangleShape2D 44×10 at (0,26) | No interact area — uses proximity in world.gd |
| Big Rock | Sprite2D | LogCollider StaticBody2D child | RectangleShape2D, oddly transformed | Originally for a log; poorly fits rock cluster (known, low priority) |
| Pine/Maple/Fir tree | StaticBody2D | self | TrunkCollider CapsuleShape2D r=4-5, h=10-14 at (0,16) | StumpCollider CircleShape2D r=7 (disabled until STUMP); InteractArea Area2D r=22 |
| PlayerHome (Bakery) | AnimatedSprite2D | PlayerHomeCollider StaticBody2D (sibling) | 3-shape compound at (112,80): WallCenter rect, LeftLower, RightLower | Separate node — not a child of PlayerHome |
| HouseTwostoryTeal | AnimatedSprite2D | HouseTealCollider StaticBody2D (child) | WallCenter + WallFront RectangleShape2D | BUG FIXED: WallFront was nested inside WallCenter (invalid) |
| GreyHoodie (NPC) | Node2D | None | None | Proximity only via NPC_TRADE_RADIUS=36px in world.gd; player walks through |
| WillowTree | Node2D | TreeCollider StaticBody2D | CircleShape2D r=7.4 | ProximityArea Area2D r=14.6 |
| BigMushroomStump | Sprite2D | MushroomCollider StaticBody2D | RectangleShape2D 20×10 at (2,15) | Currently hidden (visible=false) |
| StumpShrine | Node2D | DetectionArea Area2D | CircleShape2D r=30 — runtime | stump_shrine.gd creates at ready |
| DoorEntrance | Area2D | self | RectangleShape2D at (108,117) | Triggers bakery entry |
| NPCHomeDoor | Area2D | self | RectangleShape2D at (534,125) | Triggers NPC home entry |
| World Borders | StaticBody2D ×4 | self | RectangleShape2D (wide/tall strips) | Invisible |

### Collision Layers/Masks

All physics bodies and areas use **Godot defaults: layer=1, mask=1**. No explicit layer assignments exist anywhere in the project. This is intentional for the current game scope — the only interactions are Player↔Environment and ForestCreature↔Environment. If NPC-NPC isolation is needed later, assign Player to layer 1, Environment to layer 2, NPCs to layer 4.

### Y-Sort Offset Rule Table (AUTHORITATIVE)

`sort_y = node.position.y + node.y_sort_offset`

When `player.sort_y > object.sort_y`, player renders IN FRONT of object.

| Object | position.y | y_sort_offset | sort_y | Rule used |
|--------|-----------|--------------|--------|-----------|
| Player | varies | **14** (half of 28px rendered height) | p.y+14 | half_height |
| ForestCreature | varies | **11** (half of ~22px rendered height) | p.y+11 | half_height |
| Well | 75 | **24** | 99 | visual bottom |
| PlayerHome (Bakery) | 80 | **35** | 115 | door base |
| Plant | 109 | **24** | 133 | ground contact |
| DryingRack | 75 | **30** | 105 | ground contact |
| Big Rock | 131 | **31** | 162 | base of rock cluster |
| WillowWeeping | 97 | **53** | 150 | ground root line |
| HouseTwostoryTeal | 75 | **42** | 117 | door base (estimated) |
| BigMushroomStump | 141 | **22** | 163 | base of stump |
| GreyHoodie (NPC) | 158 | **19** | 177 | half_height |
| Cave entrance | 407 | **15** | 422 | base of arch |
| StumpHome001 | 311 | **12** | 323 | base of stump |
| Trees (Pine/Maple/Fir) | varies | **22** | t.y+22 | lower branch tips (baked in base scenes) |

### Sprite Ownership Map (what controls position/scale/offset)

| Property | Owner | Notes |
|----------|-------|-------|
| node.position | world.tscn placement | Never set at runtime |
| node.y_sort_offset | Base scene (instanced) or world.tscn inline node definition | NOT a runtime property |
| AnimatedSprite2D.scale | Scene file (.tscn) | Player=0.5, Bakery=0.5, TealHouse=0.6, StumpHome001=0.1953125 |
| AnimatedSprite2D.offset | Never used | All sprites centered on origin |
| CollisionShape2D.position | Scene file only | Offsets shape from parent physics body |
| TreeSprite scale | Tree base scene | TreeSprite=0.75, StumpSprite=0.15 |
| TrunkCollider position | Tree base scene | All trees: (0,16) |
| StumpSprite/StumpCollider position | choppable_tree.gd `_ready()` | Set to Vector2(0, stump_y_offset) = (0,28) |

### Tree Template Evaluation

Trees are already well-componentized via base scenes (pine/maple/fir_tree.tscn) + choppable_tree.gd:
- Self-registers to "choppable_trees" group in `_ready()`
- All visual/collision/interaction nodes are in the base scene
- No world.tscn changes needed to add new tree instances
- y_sort_offset=22 baked into base scene — survives all editor operations
- **No refactor required.** Template system is complete.

**Decisions Made:**

1. **Restore y_sort_offset for 12 inline world.tscn nodes** — Added directly to node definitions via Edit tool (not via editor script). Inline nodes in world.tscn retain properties on editor resave; the loss mechanism was prior full-file rewrites in ADR-085→088 sessions that didn't carry these values forward.

2. **Fix HouseTealCollider nested CollisionShape2D** — `WallFront` CollisionShape2D was a child of `WallCenter` CollisionShape2D (invalid in Godot — CollisionShape2D nodes must be direct children of physics bodies). Fixed by changing parent to `HouseTwostoryTeal/HouseTealCollider` and renaming to `WallFront`. The house now has two functioning wall segments.

3. **Add y_sort_offset=14 to player.tscn** — ADR-086 set this value but it was never written to the base scene (was written as a world.tscn instance override which was later lost). Now baked into player.tscn permanently.

4. **Collision layers: document and leave at defaults** — All objects on layer=1/mask=1 is intentional. No behavioral changes needed at current game scope.

**Consequences:**
- HouseTealCollider now has 2 active wall segments — player may be more blocked by the teal house side walls. Walk-around testing may reveal the y_sort_offset=42 estimate needs tuning.
- Inline y_sort_offset values will survive editor resaves as long as they are written as part of the node's own definition (not as instance property overrides). A full file rewrite (Write tool on world.tscn) must preserve them.
- **PREVENTION:** Never rewrite world.tscn in full. Always use targeted Edit tool calls for specific node changes.

**Files changed:** `game/World/world.tscn` (12 y_sort_offset values + HouseTealCollider fix), `game/Player/player.tscn` (y_sort_offset=14 baked in)

**Testing:** Player at y=170 behind pine tree (sort_y 184 < 203) ✅. Player at y=210 in front of pine tree (sort_y 224 > 203) ✅. Player at y=75 hidden behind bakery dome (sort_y 89 < 115) ✅. Player at y=130 in front of bakery door (sort_y 144 > 115) ✅. ForestCreature sorting correctly near tree trunk ✅. No regressions — game boots clean.

---

## ADR-090: Pine Tree TrunkCollider Fix + y_sort_offset Stripping Root Cause
**Status:** Accepted
**Date:** 2026-05-23

**Context:** Player could physically enter the right side of the pine tree trunk and render in front of the tree from certain approach angles. Investigation also finally identified why y_sort_offset keeps disappearing from pine_tree.tscn despite being "baked in."

**Findings:**

1. **TrunkCollider was left-side only.** Old values: `position=(-3,15), scale=(2.07,0.375), CapsuleShape2D r=1.45 h=32`. After scale: ~6px wide × ~13px tall, x range [-6, 0] — entirely to the left of the tree center. Player approaching from the right had zero physics resistance.

2. **y_sort_offset root cause identified.** Godot editor strips `y_sort_offset` from a .tscn file when saving that scene standalone. The editor only treats `y_sort_offset` as an active property when the node has a y_sort_enabled ancestor. In pine_tree.tscn opened alone, the root StaticBody2D has no parent with `y_sort_enabled=true`, so the editor considers the property inactive and drops it on every save. This is the root cause of the entire ADR-085→089→090 loop.

3. **Misc junk properties found:** `y_sort_enabled=true` on StumpCollider (CollisionShape2D — doesn't support this property). `y_sort_enabled=true` on TreePine1 instance in world.tscn (spurious, sorts tree's own children by Y — harmless but wrong). `motion_mode=1` dropped from player.tscn when Godot editor resaved it after user added y_sort_enabled to player node.

**Decisions:**

1. **Fixed TrunkCollider** — `radius=6, height=4, position=(0,22), scale removed`. Now 12px wide × 16px tall, centered on trunk. Covers local y=[14,30] (world y 215–231 for TreePine1 at y=201). Player blocked from both sides at trunk height.

2. **Established safe tuning workflow** — If collider visual tweaks are needed in the editor: open pine_tree.tscn → adjust → save → immediately text-edit pine_tree.tscn to restore `y_sort_offset = 22` on the PineTree root node (line after `[node name="PineTree"...]`). Never leave pine_tree.tscn without this line present.

3. **Tuning y_sort_offset** — To change the depth-sort feel (where player transitions behind→in-front), edit the number on line `y_sort_offset = 22` in pine_tree.tscn via text only. Range: 14 (transition near top of trunk) to 28 (transition exactly at stump level). Current value 22 = lower branch tips.

4. **Removed junk properties** — `y_sort_enabled=true` stripped from StumpCollider and TreePine1 instance. `motion_mode=1` restored to player.tscn.

**Consequences:**
- TrunkCollider now blocks lateral access to trunk zone from both sides — player can no longer walk into the right side of the tree trunk.
- y_sort_offset is fragile: any save of pine_tree.tscn via the Godot editor destroys it. Tuning must be done via text edit only.
- ADR-089 claim "y_sort_offset=22 baked into base scene — survives all editor operations" was incorrect. It survives world.tscn resaves (because it's in the base scene, not an override) but does NOT survive pine_tree.tscn resaves via the editor.

**Files changed:** `game/scenes/interactables/trees/pine_tree.tscn` (y_sort_offset=22, TrunkCollider fixed, StumpCollider junk removed), `game/Player/player.tscn` (y_sort_offset=14, motion_mode=1 restored), `game/World/world.tscn` (y_sort_enabled=true removed from TreePine1 instance)

**Testing:** Not yet playtested — session ended before confirmation run.

---

## ADR-091: Canonical Y-Sort Tree Architecture — Sprite Offset, No y_sort_offset
**Status:** Accepted
**Date:** 2026-05-24

**Context:** The recurring y_sort_offset loss loop (ADR-085→090) was caused by a fundamental mismatch: we were using `y_sort_offset` on tree base scenes to offset the depth-sort point, but Godot strips this property every time the scene is saved standalone (no y_sort_enabled ancestor present). We kept patching the symptom. ADR-091 eliminates the root cause by switching to the canonical Godot Recipes approach.

**Decision:** Node origin anchored at ground contact point (trunk base). Sprite child offset upward with negative Y. `y_sort_offset` stays at default 0 — never written to any .tscn, never stripped.

**Changes:**
1. **pine_tree.tscn, maple_tree.tscn, fir_tree.tscn** — removed `y_sort_offset = 22` from root node; added `position = Vector2(0, -22)` to TreeSprite. TrunkCollider moved from `(0, -6)` (legacy offset) to origin `(0, 0)` — collider is now at trunk base (node position). InteractArea at origin.
2. **choppable_tree.gd** — `stump_y_offset` default changed to `0.0`. With node at trunk base, stump renders exactly at ground contact by default. No export value needed unless per-species tuning is required.
3. **world.tscn** — All 8 tree instance positions shifted +22 Y (anchor moved down 22px to compensate for sprite offset). Visual position on screen is unchanged (node down 22, sprite up 22 = net zero shift). Only the depth-sort transition point changed: now exactly at trunk base.

**Rationale:**
- Canonical Godot Recipes pattern: origin = ground contact, sprite = offset child. This is how every professionally documented top-down 2D tree works.
- `y_sort_offset` at default 0 is never serialized to .tscn. Can never be stripped. The entire ADR-085→090 loop cannot repeat.
- TrunkCollider at origin is semantically correct: tree trunk physics IS at the trunk base.
- No special workflow required after editor saves. Depth sort is stable.

**Consequences:**
- Y_SORT_OFFSET TUNING RULE in CLAUDE.md is now obsolete for trees — removed.
- Depth-sort transition is at trunk base (node Y). Player transitions from behind → in front exactly when crossing the trunk. Verified: player at tree.y-10 = behind ✅, player at tree.y+15 = in front ✅.
- Stump appears at trunk base after chopping ✅.
- Any new tree species: set TreeSprite position Y = -(half_tree_height_px), leave y_sort_offset at 0 (default). Drop in world.tscn — no post-placement edits needed.

**Files changed:** `game/scenes/interactables/trees/pine_tree.tscn`, `game/scenes/interactables/trees/maple_tree.tscn`, `game/scenes/interactables/trees/fir_tree.tscn`, `game/scenes/interactables/trees/choppable_tree.gd`, `game/World/world.tscn` (all 8 tree instance Y positions +22)

**Testing:** Playtested via MCP execute_game_script. TreePine1 at global_y=223 (after +22 shift). Player at y=213 hidden behind tree ✅. Player at y=238 visible in front of trunk ✅. Stump rendered at trunk base after 3 chops ✅.

---

## ADR-092: Fay Grove Exchange Mechanic
**Status:** Accepted
**Date:** 2026-05-24

**Context:** The stump shrine needed a passive, mysterious exchange mechanic. The old `stump_shrine.gd` used Space-key interaction to directly offer items; the new design required: drop-item-and-leave flow, player-invisible processing, dual outcomes (processed vs double-raw), one trade at a time, ShT never seen near stump.

**Decision:** Complete replacement of `stump_shrine.gd` with a passive groove watcher. `forest_creature.gd` simplified to always-walking, stump-exclusion behavior.

**Grove mechanic (stump_shrine.gd):**
- Node2D at stump position. No signals, no Space interaction. Removed from world.gd interactable list.
- State machine: `IDLE → ITEM_PRESENT → PROCESSING → REWARD_READY → REWARD_SPAWNED → IDLE`
- Scans `world_drop_items` group each frame for items within `GROVE_RADIUS = 60px`
- `ITEM_PRESENT`: waits for player to leave grove. When player exits: queue_free the drop item (it "vanishes") → `PROCESSING`
- `PROCESSING`: 10s countdown. Player can re-enter, timer keeps running.
- `REWARD_READY`: if player NOT in grove → spawn reward WorldDropItem at original drop position. If player IS in grove → hold until player leaves.
- `REWARD_SPAWNED`: reward sits at drop spot (120s despawn). When player enters grove and comes within 20px: auto-grant to inventory + toast → `IDLE`.
- Exchange table: bud→hang_dry OR 2×bud; stone_pile→lumber OR 2×stone_pile; wood→lumber OR 2×wood. 40% processed / 60% double-raw. Never nothing.
- `grove_reward` meta on reward WorldDropItem prevents re-detection as a new offering.

**ShT behavior (forest_creature.gd):**
- Removed `HIDING` and `TRUST_HOLD` states. Only `TREE_HOP` and `FLEE`.
- Always walking: on arrival at tree, immediately picks next target (no pause).
- `STUMP_EXCLUSION_RADIUS = 80px`: trees within 80px of StumpHome001 are filtered out of hop targets.
- Invisible trees (`visible = false`) filtered from hop list.
- Starting position moved to (236, 211) — near MapleTree, far from stump.
- `y_sort_offset = 11` restored in world.tscn.

**WorldDropItem update:**
- Added `despawn_time` meta override. Grove reward items use 120s (vs normal 30–90s random), giving player time to return.

**Rationale:**
- Passive detection via group scan avoids physics body complexity (WorldDropItem is Node2D, not PhysicsBody).
- State machine cleanly separates each phase; `grove_reward` meta prevents feedback loops.
- Auto-grant on approach (no Space press) = satisfying pickup with no interface friction.
- ShT always moving matches "mysterious creature" feel; stump exclusion prevents ShT from hovering near its own home.

**Consequences:**
- ShrineManager.gd autoload is now unused (trust system retired). Left in place (safe, no errors).
- One trade at a time enforced by state machine — can't stack multiple drops.
- If player drops a non-exchangeable item in grove, grove ignores it (item despawns normally).

**Testing:** Full loop playtested via MCP. Dropped stone_pile → grove state ITEM_PRESENT → player moved away → 10s elapsed → REWARD_SPAWNED at drop pos → player returned within 20px → auto-granted 2× stone_pile (60% raw outcome) + toast. Grove back to IDLE. ShT at (639, 211) = 470px from stump, velocity non-zero (always moving), TREE_HOP state targeting WillowWeeping. ✅

**Files changed:** `game/World/StumpShrine/stump_shrine.gd`, `game/World/ForestCreature/forest_creature.gd`, `game/World/WorldDropItem/world_drop_item.gd`, `game/World/world.gd`, `game/World/world.tscn` (ForestCreature position + y_sort_offset)

---

## ADR-093: ForestCreature Scene Refactor — Self-Contained .tscn
**Status:** Accepted
**Date:** 2026-05-24

**Context:** ShT (ForestCreature) was an inline `CharacterBody2D` node in `world.tscn` with its sprite and collision created dynamically in `_ready()`. This pattern diverged from all other world inhabitants (trees, player) which are self-contained instanced scenes. Dynamic child creation hid the node structure from the editor, prevented drag-to-place multi-instancing, and made `y_sort_offset` invisible/fragile in `world.tscn`.

**Decision:** Refactored ShT into `res://World/ForestCreature/forest_creature.tscn` following the exact same pattern as `pine_tree.tscn` / `maple_tree.tscn` / `fir_tree.tscn`.

**Scene structure:**
- Root: `CharacterBody2D` — `y_sort_offset = 11` baked in, script attached
- `CreatureSprite` (AnimatedSprite2D) — hobo_man_sprites, scale 0.177, autoplay `idle_south`
- `CreatureCollider` (CollisionShape2D) — CapsuleShape2D radius=4/height=4 at position (0, 3)

**Script changes:**
- `_ready()` reduced from 18 lines to 4: removed all dynamic `AnimatedSprite2D` / `CapsuleShape2D` construction
- `_anim = $CreatureSprite` replaces dynamic creation + `add_child()`
- All behavior (flee, tree-hop, stump exclusion, stuck detection) unchanged

**world.tscn changes (2 targeted edits):**
- ext_resource `70_houwb` type changed from `Script` → `PackedScene` pointing to the new `.tscn`
- Inline `[node name="ForestCreature" type="CharacterBody2D"...]` replaced with `instance=ExtResource("70_houwb")` + position override only

**Rationale:**
- Mirrors choppable tree pattern exactly — ShT is now a sibling scene to pine/maple/fir
- `y_sort_offset=11` baked into scene root — survives editor saves, never needs restoration
- Drag-to-place multi-instancing becomes possible with zero script changes
- No hardcoded world-position dependencies; `get_parent()` / `get_tree().current_scene` paths unchanged

**Consequences:** None negative. Dead code removed. Editor now shows full node hierarchy for ForestCreature. Script ext_resource no longer referenced in world.tscn (owned by scene).

**Testing:** Playtested via `play_scene`. Output log clean. ShT confirmed at `(309, 352)`, velocity `(-30, 14)`, `CreatureSprite` exists, animation `walk_west`. ✅

**Files changed:** `game/World/ForestCreature/forest_creature.tscn` (new), `game/World/ForestCreature/forest_creature.gd`, `game/World/world.tscn`

---

## ADR-094: ShT Elusiveness — Stuck Detection, Teleport Escape, Flee Hysteresis
**Status:** Accepted
**Date:** 2026-05-24
**Context:** ShT (ForestCreature) could be permanently cornered against walls or map edges. Per-frame jitter (±0.30 rad `randf_range` every physics tick) caused visible stuttering. FLEE↔TREE_HOP state could flicker when player stood at exactly the flee radius boundary.
**Decision:** Three changes to `forest_creature.gd`: (1) Remove per-frame jitter entirely. (2) Add stuck detection — sample position every 0.35s; if ShT moves less than 5px for 3 consecutive samples while fleeing, teleport escape fires. (3) Add map-edge escape — if ShT position is within 10px of any map boundary while fleeing, teleport escape fires immediately. (4) Add flee hysteresis — enter FLEE at 64px, only exit when distance exceeds 90px. (5) Teleport respawn picks a random off-screen position (>184px from player, >35px outside camera edge), clamped to map bounds, stump-excluded; fallback to farthest map corner.
**Rationale:** Jitter root cause: `randf_range` at 60fps changes velocity direction every frame, producing per-pixel zigzag rather than organic movement. Hysteresis root cause: without it, any position exactly at FLEE_RADIUS causes a state toggle every frame (flee sets velocity away, tree-hop picks a tree target, alternating each tick). Teleport is the only practical escape on a map with no navmesh.
**Consequences:** ShT paths are straight (no jitter). Elusiveness comes from speed, tree-seeking, and teleport — not direction noise. Stuck detection fires after ~1.05s of no movement. Map-edge fires within one frame of hitting the boundary. Respawn is always off-screen so the player never sees the pop.
**Testing:** Flee triggered at 30px proximity — ShT fled 293px clean. Map-edge trigger: placed ShT at (220,115), instantly respawned 231px from player, 309px from stump ✅. State reads TREE_HOP + speed=34.0 after all teleports ✅. Output log clean throughout ✅.

**Files changed:** `game/World/ForestCreature/forest_creature.gd`

---

## ADR-095: StumpHome001 Self-Contained Scene Refactor
**Status:** Accepted
**Date:** 2026-05-25
**Context:** StumpHome001 (AnimatedSprite2D) and StumpShrine (Node2D with stump_shrine.gd) were two separate inline nodes in world.tscn at the same position. Inline nodes accumulate y_sort_offset stripping, can't be drag-placed, and split logically coupled things across the file.
**Decision:** Created `res://World/StumpShrine/stump_home_001.tscn`. Root Node2D with `y_sort_offset=12` baked in and `stump_shrine.gd` attached. Children: `StumpSprite` AnimatedSprite2D (scale 0.1953125, idle anim), `StumpCollider` StaticBody2D → `StumpShape` CircleShape2D (r=46, offset y=18). world.tscn updated: two inline nodes replaced with single instance at (13, 311).
**Rationale:** Mirrors ADR-093 (ForestCreature) pattern. y_sort_offset=12 baked into .tscn survives all editor operations. stump_shrine.gd uses `get_parent()` to find World — still works with root as direct child of World.
**Consequences:** Grove exchange mechanic unchanged. stump_home_001.tscn is drag-placeable if additional dwellings are needed.
**Testing:** Game ran clean (4-line output log). StumpHome001 visible at correct position ✅.

**Files changed:** `game/World/StumpShrine/stump_home_001.tscn` (created), `game/World/world.tscn`

---

## ADR-096: WillowTree Self-Contained Scene Refactor + Proximity Bug Fix
**Status:** Accepted
**Date:** 2026-05-25
**Context:** ADR-061's proximity shake system (willow triggers once on player enter, holds last frame 120s) regressed silently. The ADR-074 editor save accidentally modified the `CollisionShape2D` under `ProximityArea` — its Y scale was flipped to `-1.1442387`. Godot 4's physics engine does not support negative-scale collision shapes; the shape is silently ignored, `body_entered` never fires, shake never triggers. Additionally, the willow was an inline node block in world.tscn (~40 lines, 11 ext_resources, 3 SubResources).
**Decision:** (1) Fixed root cause: `CollisionShape2D.scale.y` under `ProximityArea` restored to positive (`1.1442387`). (2) Created `res://World/WillowTree/willow_tree.tscn`. Root `Node2D` with `y_sort_offset=53` baked in, `willow_tree.gd` script, scale `(2.975, 2.5)`. All children migrated: `AnimatedSprite2D` (WillowFrames with idle/shake), `ProximityArea` (centered at origin, `CollisionShape2D` with `ProxShape` r=38 → ~113px world reach), `Shadow` (obj_shadow_script), `TreeCollider`. world.tscn: entire inline block replaced with single instance at (467, 97).
**Rationale:** Self-contained scene bakes `y_sort_offset=53` and the script so both survive editor operations. Simplified ProximityArea (no cascading scales) makes the world-radius predictable: `38 * 2.975 = 113px` — covers the teal house to the right and equal distance left.
**Consequences:** Shake triggers from all directions ✅. ProxShape r=38 gives ~113px world X reach. `y_sort_offset=53` permanent in .tscn, no longer stripped by world.tscn saves.
**CRITICAL WARNING:** Dragging `CollisionShape2D` under `ProximityArea` in the Godot viewport silently re-introduces a negative Y scale, breaking the system. The editor does this when dragging shapes — it's a Godot editor behavior, not a bug we can prevent. Rule: **always edit CollisionShape2D position via Inspector field, never via viewport drag.**
**Testing:** Area monitoring=true, shape not disabled, overlapping bodies detected ✅. Output log clean ✅.

**Files changed:** `game/World/WillowTree/willow_tree.tscn` (created), `game/World/world.tscn`

---

## ADR-097: NavigationRegion2D Baked in world.tscn
**Status:** Accepted
**Date:** 2026-05-25
**Context:** Click-to-navigate (world.gd `_update_mouse_navigation`) drives the player with a direct vector to the target — no pathfinding. This causes the player to walk into walls and get stuck. A baked NavigationRegion2D is the prerequisite for wiring NavigationAgent2D to route around obstacles.
**Decision:** Added `NavRegion` NavigationRegion2D as a direct child of World in world.tscn. NavigationPolygon: outer boundary 640×480 at world-local origin, `parsed_geometry_type=PARSED_GEOMETRY_STATIC_COLLIDERS`, `source_geometry_mode=SOURCE_GEOMETRY_ROOT_NODE_CHILDREN`, `agent_radius=6.0`. Baked result: 231 vertices / 136 polygons, 28 obstacle outlines from all StaticBody2D shapes in the scene tree (buildings, trees, rocks, well, drying rack, border walls, stump — including shapes inside instanced tree scenes).
**Rationale:** Auto-parse from static colliders handles instanced scene obstacles (TrunkCollider, StumpCollider inside pine/maple/fir/willow .tscn) without manual polygon authoring. agent_radius=6.0 matches the player's ~6px collision capsule half-width. Baking required explicitly calling `NavigationServer2D.parse_source_geometry_data(nav_poly, source_geo, root)` with the scene root passed as the geometry root — calling `bake_navigation_polygon(false)` alone produced only 4 vertices (no obstacles), because the navigation polygon's source root defaults to the NavRegion node itself (no children), not its parent.
**Consequences:** Nav mesh is baked/static — rebake required if new StaticBody2D obstacles are added to world.tscn. Existing click-nav in world.gd is NOT yet wired to the nav mesh (still direct vector). NavRegion is ready for NavigationAgent2D to be added to player or NPCs.
**Testing:** Baked: 231 vertices / 136 polygons. Output log clean (4 lines). Game runs ✅.

**Files changed:** `game/World/world.tscn`

---

## Change Log
| Date | Change |
|------|--------|
| 2026-05-25 | ADR-097: NavigationRegion2D (NavRegion) added and baked in world.tscn. 640×480 outer boundary, PARSED_GEOMETRY_STATIC_COLLIDERS, agent_radius=6.0. 28 obstacles parsed (buildings, trees, rocks, well, drying rack, border walls, stump). Baked: 231 vertices / 136 polygons. Playtested ✅. |
| 2026-05-25 | Fix: ADR-096 completion — world.tscn inline TreeWillowWeeping still had viewport-dragged ProximityArea offsets (position/scale on both Area2D and CollisionShape2D) left from before ADR-096. willow_tree.tscn was correctly created (r=38, centered) but world.tscn was never updated to use it. Fixed inline node directly: reset ProximityArea + CollisionShape2D to origin, radius 14.55→38.0, added missing y_sort_offset=53. Shake now triggers from all directions including below. HouseTealCollider confirmed inside zone. Playtested ✅. |
| 2026-05-25 | ADR-096: WillowTree self-contained .tscn created. Root cause of ADR-061 regression identified (ADR-074 editor save flipped CollisionShape2D.scale.y negative under ProximityArea → body_entered never fires). Fixed. ProxShape r=38 → ~113px world reach (covers teal house + equal distance other side). y_sort_offset=53 baked in. CRITICAL WARNING documented: never drag CollisionShape2D in viewport — editor silently re-flips Y scale. Area verified: overlapping bodies detected ✅. |
| 2026-05-25 | ADR-095: StumpHome001 converted to self-contained stump_home_001.tscn. Root Node2D with y_sort_offset=12 baked in + stump_shrine.gd attached. Two inline world.tscn nodes (StumpHome001 AnimatedSprite2D + StumpShrine Node2D) replaced with single scene instance at (13, 311). Grove exchange mechanic unchanged. |
| 2026-05-24 | ADR-094: ShT elusiveness — stuck detection (3×0.35s samples, 5px threshold → teleport), map-edge escape (10px margin → instant teleport), off-screen respawn (>184px from player, stump-excluded), flee hysteresis (enter 64px / exit 90px). Per-frame jitter removed (caused stutter). Playtested ✅. |
| 2026-05-24 | ADR-093: ForestCreature refactored into self-contained forest_creature.tscn. Mirrors choppable tree pattern: root CharacterBody2D with y_sort_offset=11 baked in, CreatureSprite AnimatedSprite2D child, CreatureCollider child. world.tscn updated from inline node to scene instance. forest_creature.gd _ready() trimmed 18→4 lines. Playtested ✅. |
| 2026-05-24 | ADR-092: Fay Grove mechanic. stump_shrine.gd replaced with passive drop-watcher (IDLE→ITEM_PRESENT→PROCESSING→REWARD_READY→REWARD_SPAWNED). forest_creature.gd: removed HIDING/TRUST_HOLD, always walking, 80px stump exclusion zone, start pos moved to (236,211). world_drop_item.gd: despawn_time meta override. world.gd: shrine removed from interactables. Full loop playtested ✅. |
| 2026-05-24 | Wood icon: replaced rock3.png placeholder with wood_pile.png (48×48). Removed oversized inset hack from hud.gd. Roadmap audited — bucket animations confirmed done, cave entrance dropped, session-end rule updated to own roadmap accuracy. |
| 2026-05-24 | Fix: `script = null` instance override in main.tscn removed — Godot editor had written it during ADR-091 MCP ops, nulling world.gd at runtime (broke hotbar, mouse nav, interactions). SESSION-END PRE-FLIGHT RULE added to CLAUDE.md to catch this pattern before future doc commits. |
| 2026-05-24 | ADR-091: Canonical y-sort tree architecture — node at trunk base, sprite offset upward, no y_sort_offset. Permanently eliminates the y_sort_offset stripping loop (ADR-085→090). All 3 tree scenes + world.tscn updated. Playtested ✅. |
| 2026-05-23 | ADR-090: Pine tree TrunkCollider fixed (left-side only → symmetric 12px wide). y_sort_offset stripping root cause identified (Godot editor strips it on standalone scene save). Safe tuning workflow established. motion_mode=1 restored to player.tscn. |
| 2026-05-23 | ADR-089: Full physics/collision/y-sort audit. Restored 12 y_sort_offset values in world.tscn inline nodes. Fixed HouseTealCollider nested CollisionShape2D bug. Baked player y_sort_offset=14 into player.tscn. Documented complete collision matrix and sprite ownership rules. |
| 2026-05-23 | ADR-088: y_sort_offset persistence fix — baked into base tree scenes (not world.tscn instance overrides). Value calibrated 28→22 (lower branch tips, not trunk base). Removed y_sort_enabled=true from TreePine1 override. |
| 2026-05-23 | ADR-087: Fixed tree y_sort_offset formula error — all 12 choppable trees 12→28. Player/ForestCreature now correctly render behind canopy until trunk base. |
| 2026-05-22 | ADR-086: Full sprite/collision/camera audit. Fixed Fir TrunkCollider negative scale, Player y_sort_offset 16→14, camera zoom 1.0→0.87. Documented correct sprite sizes (56×56 player, 124×124 ForestCreature). |
| 2026-05-22 | ADR-085: Restored all 25 y_sort_offset values in world.tscn (lost since ADR-073, overwrites by subsequent sessions). All depth transitions now correct. |
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
| 2026-05-05 | HUD water section: blue dot replaced with WaterGem TextureRect; blue bar replaced with TextureProgressBar (WaterMeterBar.png). |
| 2026-05-05 | Interactable router implemented — well.gd, plant.gd own their logic; world.gd reduced to signal router. ADR-023 added. |
| 2026-05-05 | Asset inventory + organization: extracted 8 ZIPs, renamed assets by visual type. New folders: NPCs/GreyHoodie, NPCs/PurpleJack, Objects/DryingRacks (16 variants), Items/Bags (7), Items/Chests (3), Items/WateringCans (6), Items/Gems (8). ASSET_INDEX.md created. |
| 2026-05-05 | HUD cleanup: removed energy bar, currency "0" label, yellow slot selection. E-prompt moved into HUD hotbar (left side, proximity-driven). ADR-024 added. |
| 2026-05-06 | Drying rack 3-state mechanic: rack_weed_1/2/3plant.png textures, add_plant() via plant_harvested signal. Plant resets to seedling on harvest. ADR-025 added. |
| 2026-05-06 | Day/night cycle: DayNightCycle.gd in main.tscn, 120s loop, CanvasModulate + DirectionalLight2D keyframe lerp. Night floor raised to 0.38 brightness. ADR-026 added. |
| 2026-05-06 | Dynamic shadows: object_shadow.gd flat oval with positional shift (no rotation), two-pass soft rendering, z_as_relative=false. All 5 world objects have shadows. ADR-027 added. |
| 2026-05-07 | Camera zoom set to 0.87 — 15% more world visible. ADR-028 added. |
| 2026-05-07 | Night speed 2× multiplier in DayNightCycle._process(). Daytime unchanged. ADR-029 added. |
| 2026-05-07 | 4-point diffused house night lighting; PlayerHome/Door light_mask=2; Sun range_item_cull_mask=3. ADR-030 added. |
| 2026-05-07 | 13 village building PNGs imported into res://GameAssets/Buildings/ (houses/shops/special). Renamed to snake_case. ADR-031 added. |
| 2026-05-07 | Bakery (shop_bakery_main.png) replaces old house as Erik's home. Well+DryingRack moved left. All collisions, lights, shadows, roof overlay, interior spawn updated. ADR-032 added. |
| 2026-05-08 | Removed PlayerHomeDoor overlay sprite + Door1-4 assets. Transition now goes directly fade→interior. Playtested and confirmed. ADR-033 added. |
| 2026-05-08 | DoorEntrance trigger shrunk 44×30 → 14×6 px (must walk up to door). Fade starts at frame 6 of 9 animation (last 3 frames never seen). |
| 2026-05-08 | Drying rack replaced: new wooden A-frame assets (rack_new_*.png, 64×64). Added empty state. Added player collision (44×10 box). Shadow corrected (ground_offset y=26, size 28×5, cast_length 18). y_sort_offset=30. ADR-025 updated. |
| 2026-05-08 | Door animation fade moved from frame 6 → frame 4: player now sees only opening frames before scene cut; closing frames are fully hidden by fade. |
| 2026-05-08 | Player walks into door: auto_walk Vector2 added to player.gd; door trigger sets auto_walk north instead of freezing physics so walk_up plays through fade. |
| 2026-05-08 | PurplePlant sprite offset (149,-32) reset to (0,0) — sprite was 149px from its collision shapes after parent node was moved. ADR-034 added. |
| 2026-05-08 | Log ("18", 58×63) and Rock ("Rock123x20", 69×19) given StaticBody2D collision shapes. ADR-034 added. |
| 2026-05-08 | Drying rack TEXTURES array indices 1/3 swapped — first harvest now shows fullest visual state (3 bundles) and decrements. ADR-035 added. |
| 2026-05-08 | object_shadow.gd: show_behind_parent=true — shadow oval now draws behind parent sprite. HouseGlowLeft position fixed (158,138)→(60,82); shadow_enabled removed. ADR-036 added. |
| 2026-05-08 | 40×30 starter farm map: Ground rebuilt (1200 cells, sources 2/3 random), 66 Tree1.png border sprites, Camera limit_bottom 384→480. ADR-037 added. |
| 2026-05-08 | 33 tree sprites imported to res://GameAssets/Trees/ (17 evergreens, 16 deciduous) and 7 tool icons to res://GameAssets/Tools/ (axe, pickaxe, hammer, shovel, saw, hatchet, scythe). Renamed from unknown.png with descriptive names. |
| 2026-05-09 | town-grass-tile.png (256×256, 16×16 tiles) added to res://GameAssets/Tiles/ and registered as source 5 in world_tileset.tres via execute_editor_script. 256 tiles created across a 16×16 grid, paintable alongside existing sources. |
| 2026-05-09 | Plant/Shadow ground_offset corrected (0,12)→(0,22) to sit at base of 48×48 centered sprite. Well/Shadow widened to (22,9), cast_length→5 for a more grounded static look. Log ("18", now renamed to "Log") collision changed Circle r=20→RectangleShape2D 50×22 at (0,18); LogCollider reset to (0,0). Stray Trees/5.png sprite reparented from inside LogCollider to World root at (94,188). TreeWillowWeeping given Shadow + TreeCollider (CircleShape2D r=7 at y=18). Rock intentionally removed by user. |
| 2026-05-11 | Big Rock/Shadow node had position=(44,-3) causing shadow to appear 44px displaced from rock. Reset to (0,0) — shadow now correctly under rock. |
| 2026-05-11 | Camera limit_bottom expanded 384→496 to cover full 31-tile map height (496px). Cave entrance at (29,409) now reachable. ADR-038 added. |
| 2026-05-11 | HouseTwostoryTeal Sprite2D converted to AnimatedSprite2D using house_grey_teal_frames.tres (9-frame 768×768 grey/teal house). HouseTealCollider StaticBody2D (85×28) added. Shadow (ground_offset y=42, size 65×10) added. ADR-039 added. |
| 2026-05-11 | GreyHoodie NPC: Frame000 Sprite2D replaced with Node2D+AnimatedSprite2D. grey_hoodie_sprites.tres created (idle_south/east/west 4-frame, walk_east/west/north/south 6-frame). npc_grey_hoodie.gd patrol script: walks (165,150)↔(510,150) at 45px/s, 2.5s idle at each end. ADR-038 added. |
| 2026-05-11 | Log1 (Trees/5.png, 94,188) given Shadow (ground_offset y=10, size 22×5) + TreeCollider (CircleShape2D r=6 at y=8). |
| 2026-05-11 | BigMushroomStump (48×48, 440,85) given Shadow (ground_offset y=20, size 22×6) + MushroomCollider (RectangleShape2D 20×10 at y=18). |
| 2026-05-11 | Plant/Shadow ground_offset corrected (0,22)→(0,10): 48×48 sprite, shadow was too far below plant base. |

| 2026-05-11 | NPC bakery-stop waypoint corrected (165,150)→(112,165) — was landing at right edge of bakery sprite, now centered in front of door. |
| 2026-05-12 | Camera2D limits corrected to global coords accounting for World offset (195,88): left=195 top=88 right=835 bottom=584 (was 0,0,640,496 which confined player to bakery area). Root cause: World instanced at (195,88) in main.tscn shifts all global positions by that amount. |
| 2026-05-13 | Log1/TreeCollider: CircleShape2D (r=20.46) replaced with RectangleShape2D (28×10) at offset (0,0) — flat rectangle matches horizontal log footprint, eliminates lateral push/snap from curved collision resolution. |
| 2026-05-13 | GreyHoodie patrol waypoints updated: bakery (112,135), teal house (534,145). Spawn moved to (534,145). Path stays at y=135–145, safely south of both house walls (bakery wall bottom y≈118, teal wall bottom y≈132). NPC loops home→bakery→home. |
| 2026-05-13 | Extra TileMap column x=0 tiles removed — left-edge src0 (6,1) tiles added in prior session created a double-column visual; erased to restore user's original tiles at x=1+. |
| 2026-05-13 | BorderBottom repositioned y=487→y=471: north face now aligns with world-local y=463 (top of user's hedge row y=29, accounting for Ground offset -1). Player stops at y=457, just outside the hedge. |
| 2026-05-13 | NPC patrol root-cause fix: npc_grey_hoodie.gd was using global_position with world-local waypoints. World sits at (195,88) in main.tscn, so global_position offset every target by (195,88) — NPC flew northwest off-map on every cycle. Fixed all three uses to position (local). Waypoints (112,150)↔(534,158) now land south of both house sprite bottoms (bakery bottom y=144, teal house bottom y=153). NPC loops: teal house door → bakery door → teal house. |
| 2026-05-13 | NPC script simplified to walk_east/walk_west only; walk_north/walk_south removed (horizontal patrol only). Scene default animation fixed walk_north→idle_south. Log1 TreeCollider: CircleShape2D r=20.46→RectangleShape2D 28×10. |
| 2026-05-13 | NPC home interior added: res://World/NPCHome/interior.tscn (160×128, same tileset as player home). NPCHomeDoor Area2D added to world.tscn at (534,125) with 30×10 shape. world.gd wired: player auto-walks north → fade → NPC interior; exit spawns player at (534,140). 0.5s delay on door reconnect prevents re-entry on spawn. Spawn position pattern: interior.gd sets Engine.set_meta("spawn_position", ...) consumed by main.gd._ready(). |
| 2026-05-13 | Harvest-to-trade loop audited: identified missing dried product inventory icon, rack "complete" state, NPC sprite, and currency icon. Dried bud sprite added at GameAssets/Bud/states/dry/rotations/unknown.png — usable as inventory icon and world drop. More bud states deferred. |
| 2026-05-13 | Drying rack: 4-state machine (EMPTY→FILLING→DRYING 5s→READY 1.5s golden pulse→award+reset). _award_and_reset() picks random bud from 8 variants. 7 bud PNGs copied to res://GameAssets/Bud/ with clean names. ADR-025 updated. |
| 2026-05-13 | Inventory stacking: add_item(key, tex) — stacks by key up to 16, hotbar slots 1-11 first then inventory grid, badge label at count>1, new slot gets random tex. Fixed get_node("TextureRect") → direct _slot_icons[] ref. ADR-040 added. |
| 2026-05-13 | NPC trade interaction: GreyHoodie pauses at player door, E-key exchanges 1 bud for 1 gem (WaterGem.png placeholder), 10s trade window then NPC departs. has_item/remove_item added to hud.gd + inventory.gd. ADR-041 added. |
| 2026-05-13 | Keybinding standardization: E = environmental/world only (well, plant, drying rack, doors). T = NPC trade only. T prompt is a gold-bordered Panel/Label in EPromptArea; shown/hidden by show_trade_prompt(). E and T prompts are fully independent. Player starts with 1 bud in hotbar. |
| 2026-05-14 | NPC trade reworked to proximity-based: NPC stops when player within 36px, T prompt shows, trade executes on T press anywhere in world. Removed door-arrival signals. Added set_player_nearby(), _is_trading flag, 5s cooldown. ADR-041 updated. |
| 2026-05-14 | NPC post-trade cycle: after trade, NPC skips player door, walks to own house, plays walk_north then goes invisible. Tracks one full DayNightCycle (_t elapsed ≥ 1.0) then reappears at NPC door, resets _trade_completed, resumes patrol. NPC faces player during interaction (idle_east/west/south). |
| 2026-05-14 | Full asset naming pass: ~60 assets renamed to descriptive snake_case. 5 active asset paths fixed in world.tscn + house_grey_teal_frames.tres. UIDs preserved in .import files. ASSET_INDEX.md updated. ADR-042 added. |
| 2026-05-14 | InventoryManager autoload refactor: dual _items[]/_slot_items[] replaced with single _slots[48] store. slot_changed signal drives HUD + Inventory visuals reactively. hotbar_* methods removed from hud.gd. ADR-043 added. |
| 2026-05-14 | Axe tool + wood resource integrated: player.equipped_tool var, C key equip toggle in world.gd, _grant_starting_items() grants axe+bud+wood at start. Hotbar shows all three in slots 1–3. ADR-044 added. |
| 2026-05-14 | Permission allowlist expanded: added all remaining mcp__godot-mcp-pro__* tools + mcp__filesystem__edit_file/read_file/read_multiple_files/search_files to .claude/settings.json. |
| 2026-05-14 | Choppable tree scenes: 4 Sprite2D trees + 4 Stump Sprite2Ds replaced with choppable_tree.tscn instances. Each tracks own chop counter, transitions tree→stump, emits wood_chopped. ADR-045 added. |
| 2026-05-15 | Choppable tree live play test confirmed — all 4 trees chop correctly, 3-hit counter, tree→stump, wood granted. Axe-equip guard verified. ADR-045 testing updated. |
| 2026-05-15 | Permission allowlist: added Bash(Get-ChildItem *) to .claude/settings.json. |
| 2026-05-15 | Bug fix: world.gd `_on_wood_chopped()` and `_grant_starting_items()` used `/root/Inventory` (non-existent) instead of `/root/InventoryManager`. Fixed both. Wood now correctly awarded on chop and at game start. |
| 2026-05-15 | Interact key rebound E→Space; HUD SPC prompt replaces key_e.png TextureRect. ADR-046 added. |
| 2026-05-15 | Architecture hardening: 6 structural fixes — starting-items guard, named InputMap actions (npc_trade/equip_toggle), drying_rack InventoryManager fix, ItemEntry class, interactable priority list, player.facing enum. ADR-047 added. |
| 2026-05-15 | Hotbar equipped-slot indicator: _slot_style now takes selected+equipped bools; white border = selected slot, gold border = equipped tool slot; world.gd notifies HUD via set_equipped_slot() on axe toggle. ADR-048 added. |
| 2026-05-15 | Full integration validation: all 8 axe/tree/wood checks pass, all 6 existing-system checks pass (well, plant, drying rack, bucket, HUD, InventoryManager). simulate_key via MCP does not reach world.gd._input() — documented in ADR-049. Testing pattern established: use execute_game_script to call handlers directly. |
| 2026-05-15 | Tool registry refactor: replaced _handle_axe_toggle() with _handle_tool_toggle(tool_key), added EQUIPPABLE_TOOLS const dict, cached _inv_mgr in _ready(), fixed slot search range(1,48)→range(1,12). ADR-050 added. |
| 2026-05-15 | Tree group registration: choppable_tree.gd self-registers to "choppable_trees" group; world.gd uses get_nodes_in_group() instead of hardcoded [$Tree1...$Tree4] array. New trees require no script edits. ADR-051 added. |
| 2026-05-15 | Structural refactor validation: 14/14 checks pass across tool registry + tree group + all regression systems. CLAUDE.md Notes section added (session context, permissions reference). ADR-052 added. |
| 2026-05-15 | HUD mouse filter fix: MOUSE_FILTER_IGNORE added to all non-interactive Panel/Control nodes in hud.gd (TopBar, Hotbar, EPromptArea, SpacePrompt, TPrompt, 12 Slot Panels, Toast, WaterGem, WaterMeter). Mouse wheel slot cycling now works anywhere on screen. ADR-053 added. |
| 2026-05-15 | Mouse interaction pipeline fix: scroll direction corrected; slot_selected signal added to hud.gd; world.gd._on_hud_slot_selected() auto-equips equippable tools on slot selection. Full chop chain via mouse now works. ADR-054 added. |
| 2026-05-15 | Right-click mouse navigation: terrain walk-to-point (stops within 5px), tree targeting with auto-interact if axe equipped (stops silently if not), keyboard cancels nav. All in world.gd using existing auto_walk + interactable_entered pipeline. ADR-055 added. |
| 2026-05-15 | Mouse nav stuck detection: _nav_best_dist + _nav_stuck_time (delta-based, 1.0 s) added to world.gd. Cancels nav when player makes no progress toward target — fixes infinite wall-grinding on blocked clicks. _on_right_click now cancels previous nav before starting new one. ADR-056 added. |
| 2026-05-16 | Player chop + trade animations integrated: 66 PixelLab frames stripped of baked olive-green background (PowerShell pixel replacement), added to erik_sprites.tres (chop_down/up/side 16fr@12fps, trade_down/up/side 6fr@8fps, all non-looping). is_chopping/is_trading flags in player.gd, player_animation.gd handles state priority via animation_finished reset. world.gd triggers on Space/right-click chop and NPC trade. Date-time-Coin.png replaces WaterGem.png as trade reward gem icon. _face_player_toward() added to world.gd — player auto-faces NPC when in trade range and idle. ADR-057 added. |
| 2026-05-17 | Hotbar selection behavioral fix: _on_hud_slot_selected() early return removed; set_equipped_slot(index) always called; gold border now tracks selected slot unconditionally, including non-tool and empty slots. ADR-058 added. |
| 2026-05-17 | NPC right-click nav-to-trade: _on_right_click() checks NPC first at highest priority (within NPC_TRADE_RADIUS); _update_mouse_navigation() NPC arrival branch tracks NPC position and fires _handle_npc_trade() on range entry. Interaction priority: NPC > tree > terrain. ADR-059 added. |
| 2026-05-17 | Trade reliability fixes: gem_ruby.png replaces Date-time-Coin.png as trade reward icon (Date-time-Coin was a large UI sprite unreadable at hotbar size). is_interactable() guard added to both _handle_npc_trade() trigger points (T-key and nav arrival) — blocks double-trigger within the one-frame _npc_trade_active lag window that caused "No product available" to overwrite the success toast. ADR-060 added. |
| 2026-05-17 | Willow tree proximity animation: TreeWillowWeeping replaced Sprite2D root with Node2D + willow_tree.gd. New PixelLab assets (willow_idle.png + willow_f0–f8.png, 96×96) loaded as inline SpriteFrames. AnimatedSprite2D plays "shake" once on player proximity entry, holds final frame, resets after player exits + 120s. CircleShape2D ProximityArea radius=17 (≈50px world). ADR-061 added. |
| 2026-05-17 | Phase 1 asset audit completed (read-only). Report written to project_asset_audit.md. Key findings: 1,106 in-project PNGs, 227 VERIFIED_USED, 879 VERIFIED_UNUSED (all imported), 52 confirmed duplicate pairs, 0 broken references. Top cleanup candidates: shop_apothecary_alt.png (confirmed byte-identical to main), ErikPlayer/animations/Walk_v2/ (24 files, exact dups of root walk_* frames), Town/ + Village/ folders (~200 legacy numbered sprites, zero scene refs). Permission allowlist updated: added PowerShell(Write-Output *). |
| 2026-05-17 | Asset reorganization executed: 227 VERIFIED_USED PNGs + 5 .tres resources moved from GameAssets/ flat layout to res://assets/{characters,nature,props,ui,tiles,structures}/ + res://resources/{characters,tilesets,structures}/. 13 .tscn/.tres/.gd files updated for new paths. UNKNOWN assets quarantined to res://assets/_review_required/. All 16 spot-checked resources pass ResourceLoader.exists(). Plan at project_reorganization_plan.md, log at project_move_log.md. ADR-062 added. |
| 2026-05-17 | Full project verification pass. Status: CLEAN_WITH_REVIEW_ITEMS. 21/21 key files present; 79 ext_resource entries scanned across 6 scenes (1 stale path, UID-resolved); all groups verified end-to-end; all 23 canonical assets confirmed with .import files. 5 low-severity review items: icon.svg missing, willow_idle stale path in world.tscn:52 (UID resolves), 4 legacy bud preloads (deferred), tile_bit_tools nested UID duplicates, hud.gd INT_AS_ENUM_WITHOUT_CAST. Report at final_asset_health_report.md. |
| 2026-05-17 | Housekeeping: R1 resolved — GameAssets/Rocks/18.png copied to game/icon.png; project.godot config/icon updated from icon.svg to icon.png. R2 resolved — world.tscn:52 willow_idle path updated from res://GameAssets/Willow/willow_idle.png to res://assets/_review_required/willow_idle.png (UID uid://inuq3s4oqqdd preserved). |
| 2026-05-17 | BOM incident + fix: project failed to load with "Parse Error: Expected '['" on main.tscn + 6 .tres files. Root cause: PowerShell 5.1 default encoding writes UTF-8 BOM (EF BB BF) which Godot's text resource parser cannot handle. 16 files affected: main.tscn, world.tscn, player.tscn, 2 interior.tscn, world.gd, hud.gd, drying_rack.gd, npc_grey_hoodie.gd, retiledmap.tscn, 5 .tres in resources/, tileset_32x32.tres. Fixed by stripping BOM bytes via System.IO.File::WriteAllBytes(). Rule added to CLAUDE.md: always use WriteAllBytes or no-BOM UTF8 encoding for Godot files written from PowerShell. ADR-063 added. |
| 2026-05-18 | Phase 2 asset cleanup: SAFE_TO_ARCHIVE pass executed. 18 confirmed-zero-reference groups (~366 PNGs + .import sidecars) moved from game/GameAssets/ to _archived/ outside project. game/GameAssets/ reduced to 487 PNGs (REVIEW_FIRST + UNCERTAIN retained). hud.gd:379 INT_AS_ENUM_WITHOUT_CAST fixed (align as HBoxContainer.AlignmentMode). ADR-064 added. |
| 2026-05-18 | TempAssetHolding integration: full verification-first inspection of 54 PNGs (PixelLab batch, 154×154 px garden/plant assets). 36 files copied to res://assets/_review_required/ with semantic names (15 dirt patches, 1 structure, 20 plants). 15 duplicates left in TempAssetHolding. 2 source files not found (garden gate + ancient coin). stump_door_dwelling.png (new: stump with carved door), cannabis_planter_type_a/b/c (new: planter box variants). ADR-065 added. |
| 2026-05-19 | TempAssetHolding second pass: new PixelLab batch (tree chop animations + stump dissolve). INTEGRATE_NOW: Pine/Maple/Fir trees (static + 2–3 animation sequences each) + round stump with 16-frame spiral dissolve → res://assets/nature/trees/ + stumps/. 71 files total, all auto-imported. 15 staging duplicates + 36 garden variants → ResolvedReview. TempAssetHolding now empty. ADR-066 added. |
| 2026-05-19 | _review_required cleanup: all 36 assets routed to permanent locations — characters/grey_hoodie/rotations/, characters/purple_jack/, characters/player_alt/, nature/plants/cannabis/, nature/plants/herbs/, props/garden/, nature/rocks/, structures/, tiles/32x32/, tiles/Tile.png. willow_idle.png + tilemaplayer_icon.png archived (superseded/wrong folder). _review_required is now empty. ADR-067 added. |
| 2026-05-18 | Pine/maple/fir choppable trees wired with chop+fall animations. choppable_tree_{pine,maple,fir}.tscn created as standalone scenes with inline SpriteFrames (9-frame chop@10fps + 9-frame fall@8fps). choppable_tree.gd updated to play ChopAnim before showing stump; falls back to instant swap if no sprite_frames. world.tscn Tree1/2/3 replaced with TreePine/TreeMaple/TreeFir at same positions. Playtested: chop→fall→stump→wood granted. ADR-068 added. |
| 2026-05-19 | Tileset housekeeping: (1) atlas_32x32.png source fixed — region_size was (16,16), corrected to (32,32); 264 stale tile registrations removed, 72 correct tiles (8×9) registered. (2) beach_tiles_48x48.png (GameAssets/Beach/Tiles/Tiles.png, 192×112) imported + added as world_tileset source 7 with region_size=(48,48), 8 tiles. (3) town-grass-tile.png dark-grey background color (52,55,62) fully removed — 8,324 pixels made transparent in two passes (6,182 edge-reachable + 2,142 enclosed); tiles now render with no gray halo. Cache cleanup: 4 stale .import refs purged, 6 temp screenshots deleted. World playtested: no regressions. |
| 2026-05-19 | Overlay TileMapLayer added to world.tscn (sibling of Ground, same GrassBrick_OVERLAYS__tileset.tres, renders above Ground by tree order). Per-tile flood-fill background removal on town-grass-tile.png — 21,892 pixels across 139 tiles made transparent (corner-seeded per-tile fill, tolerance=6, multiple terrain bg colors handled independently). Tiles from town-grass-tile atlas can now be painted on Overlay layer without covering existing ground. ADR-069 added. |
| 2026-05-19 | world_tileset.tres renamed to GrassBrick_OVERLAYS__tileset.tres. Single reference in world.tscn updated. Filesystem scan triggered. ADR-070 added. |
| 2026-05-20 | Project structure audit + cleanup: (1) Deleted stray root project.godot (776-byte stub, was causing nested-project ambiguity — game runs from game/project.godot). (2) Deleted game/GameAssets/ legacy directory entirely (985 files: 487 PNGs, 490 imports, confirmed zero active res:// references). (3) Deleted orphan game/assets/tiles/32x32/22222x32.tres (empty TileSet, no references). (4) Moved 7 root-level experiment art dirs (Bushes Mine, Crafting tools, My trees one, My trees two, New 2 drying rack, Weed_plants_Hanging_on_a_rack, objects) into GameAssets/ subdirs. (5) Archived root-level addons/ (orphaned godot_mcp plugin, was tied to deleted root project.godot), screenshots/, states/ into _archived/. ADR-071 added. |
| 2026-05-20 | drying_rack.gd: fixed 4 broken res://GameAssets/ preload paths in PRODUCTS array. Recovered hang_dry.png, weed_plant.png, dry_bud.png from GameAssets/Bud/ source art → res://assets/props/bud/. herb_bundle_dried.png has no source — user to supply replacement art (ASSET REPLACEMENT RULE: never sub without approval). Solid.png added to GrassBrick_OVERLAYS__tileset.tres as source 8 (16×16, 256 tiles). ASSET REPLACEMENT RULE added to CLAUDE.md and project memory. |
| 2026-05-20 | world.gd:64 broken preload fixed (res://GameAssets/Bud/dry_bud.png → res://assets/props/bud/dry_bud.png). Removed 4 zombie TileSetAtlasSource entries (source IDs 2, 3, 4, 7) from GrassBrick_OVERLAYS__tileset.tres — all had null textures and 0 cells in use. Tileset spam (~700 C++ DEBUGGER errors per run) eliminated. ADR-072 added. |
| 2026-05-20 | Obsidian vault connected at C:\Users\erikc\Desktop\DesktopFolder\MeNew\GAME — readable via native Glob/Grep/Read tools (no MCP config needed; filesystem MCP is project-scoped only). Tree sprite sizing standards from vault mirrored into CLAUDE.md. No game changes this session. |
| 2026-05-20 | Full project asset inventory written to Obsidian vault as Project_Asset_Inventory.md. Catalogues ~1,400 assets: 568 in-project PNGs (game/assets/), 819 source PNGs (GameAssets/), 5 .tres resources. Every asset has status tag (IN_USE/AVAILABLE/STAGING/ARCHIVED), frame count for animations, and usage notes. |
| 2026-05-20 | y_sort_offset calibrated on all 15 world objects (buildings, trees, props, characters). Sort point moved from sprite center to ground contact for each object. Willow +53, houses +35/+42, choppable trees +36/+37/+48, characters (player/NPC) +16/+19. ADR-073 added. |
| 2026-05-20 | Three standard choppable tree systems removed (Tree1/Tree2/Tree3 + ChoppableTree scenes/scripts). Willow untouched. 6 static tree PNGs, 7 animation dirs, 2 stump assets deleted. world.gd choppable_trees signal pipeline removed. ADR-074 added. |
| 2026-05-20 | Pine/Maple/Fir choppable tree integration. New assets from TempAssetHolding staged to game/assets/nature/trees/{pine,maple,fir}/. 4 SpriteFrames .tres created (pine/maple/fir/stump). choppable_tree.gd (shared, species @export), 3 species scenes, 3 trees placed at (55,165)/(200,162)/(50,240). world.gd restored group-based tree signal wiring + _on_tree_chopped(). Playtested: full chop→fall→stump→gone→wood grant confirmed. ADR-075 added. |
| 2026-05-20 | Fixed duplicate ghost tree nodes: removed 15 phantom nodes (TreeSprite2/StumpSprite2/TrunkCollider2/InteractArea2/InteractCol2 × 3 trees) added by MCP add_node calls on top of instanced-scene children. Tree sprite scale +25% (0.5→0.625), stump scale −75% (0.5→0.125). Ghost idle image gone — chop pipeline clean. ADR-076 added. |
| 2026-05-21 | Tree animation/stump fixes: 0.5s chop delay (player swings first, tree reacts after); stump disabled animation (static idle frame via stop()+animation="idle"+frame=0); stump position set to trunk base (stump_y_offset=28.0 export var, set in _ready()). Verified: no ghost, no stump animation, stump at correct ground position, y-sort correct. ADR-077 added. |
| 2026-05-21 | Farming system — 6 regression fixes. (1) WellWater loop:true→false (world.tscn). (2) well.gd: _reset_sprite() using play("default")→stop()→frame=0 reliably clears backwards-play flag; removed dead animation_finished handler. (3) world.gd: blocked_message() dispatch replaces hardcoded "Equip axe first (C)" for all interactables. (4) plant.gd: get_animation_speed uses $PurplePlant.animation (not hardcoded "default") + fps<=0 fallback=8.0. (5) player_animation.gd: has_animation() guard before play(); _bucket variant falls back to base animation instead of freezing. Full loop (well→plant×3→drying rack) verified repeatable indefinitely. ADR-078 added. |
| 2026-05-21 | Tree scale +20% (0.625→0.75 TreeSprite, 0.125→0.15 StumpSprite all three species). y_sort_offset corrected 36→12 (formula: stump_y_offset − player_half_height = 28 − 16 = 12; player feet reach trunk base = transition point). Left-click tree chop added to world.gd: _on_right_click detects choppable_trees within 35px and sets nav target + pending interact; _do_nav_interact now shows blocked toast. Godot editor cache lesson: open_scene alone does not flush runtime resource cache — reload_project required. ADR-079 added. |
| 2026-05-21 | Stump colliders added to pine/maple/fir tree scenes (CircleShape2D r=7, disabled at start, enabled on fall-complete). choppable_tree.gd: _stump_col @onready, position set to stump_y_offset in _ready(), toggled in FALLING→STUMP transition. Log1 and all components (Shadow, TreeCollider, CollisionShape2D, exclusive ext_resource, exclusive sub_resource) removed from world.tscn. ADR-080 added. |
| 2026-05-22 | Temp asset batch imported with descriptive names. 4 categories from temp/: 8 grove stump dwellings → game/assets/structures/grove/; 14 bush variants → game/assets/nature/bushes/; 6 stone variants + 6 animation dirs (53 frames total) → game/assets/nature/rocks/; 4 currency UI icons → game/assets/props/items/. All machine-generated folder/file names replaced with descriptive snake_case. ADR-081 added. |
| 2026-05-22 | Stump_Home_001 + StillPNGs_Stump_Homes imported, wired, placed. 5 stills (001–004 + lights variant) + 16-frame door animation copied to game/assets/structures/grove/. SpriteFrames resource stump_home_001_frames.tres created (idle 1fr + door_open 16fr@8fps). StumpIdle Sprite2D replaced with StumpHome001 AnimatedSprite2D at (13,311). Canonical scale 0.1953125 for all 128×128 grove dwellings established by user. Both temp folders archived to _archived/StumpHomes/ then deleted. ADR-082 added. |
| 2026-05-22 | ForestCreature y_sort_offset=11 set in world.tscn (sorts at feet). _player retyped CharacterBody2D. Flee: approach detection (velocity dot > 8), 1.4× speed boost when chased, 35% upward bias toward tree cover. Confirmed occluded by pine when sort key < tree's. ADR-083 added. |
| 2026-05-22 | Player AnimatedSprite2D scale reverted to original Vector2(0.5, 0.5) = 32px tall. |
| 2026-05-22 | ForestCreature tree-hopping behavior: full rewrite of forest_creature.gd. State machine TREE_HOP/HIDING/FLEE. 13 trees gathered at runtime (group + name scan). 150px hop preference. Flee steers to nearby tree in flee direction. ADR-084 added. |
| 2026-05-22 | ForestCreature collision + y_sort fix: y_sort_offset=11 correctly saved to world.tscn (was absent despite ADR-083 noting it). Collision reduced from radius=5/height=10 (20px total, nearly sprite height) to radius=4/height=4 (12px) offset +3px toward feet. |
