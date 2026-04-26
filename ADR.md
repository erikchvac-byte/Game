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

## Stage 1 — Milestones
| # | Milestone | Status |
|---|-----------|--------|
| M0 | Project settings + asset copy | ✅ Done |
| M1 | SpriteFrames resource | ✅ Done |
| M2 | Player scene (no script) | ✅ Done |
| M3 | player.gd movement script | ✅ Done |
| M4 | player_animation.gd | ✅ Done |
| M5 | World scene + TileMapLayer | Pending |
| M6 | Main scene + camera limits | Pending |

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

---

## Known Issues
- None active.

---

## Open Questions
- None currently.

---

## Future Considerations (Post Stage 1)
- Run animation (6f) — wire after walk is confirmed
- Stage 2: NPCs, farming/crop system, day cycle
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
