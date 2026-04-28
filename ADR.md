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
- Interior floor tiles: replace Polygon2D with proper tileset once user finalizes grass tiles.
- Exterior house has no collision on the "enter" path from west/east — camera/world limits naturally prevent this for now.

---

## Future Considerations (Post Stage 1)
- Run animation (6f) — wire after walk is confirmed
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
