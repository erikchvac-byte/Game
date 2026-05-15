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
