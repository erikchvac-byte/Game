---
project_name: 'Game'
user_name: 'Erikc'
date: '2026-06-05'
sections_completed: ['technology_stack', 'scene_node_patterns', 'asset_resource_rules', 'dev_workflow_mcp_loop', 'critical_anti_patterns']
existing_patterns_found: 8
status: 'complete'
rule_count: 60
optimized_for_llm: true
---

# Project Context for AI Agents

_This file contains critical rules and patterns that AI agents must follow when implementing code in this project. Focus on unobvious details that agents might otherwise miss._

> **Source of truth & precedence.** `CLAUDE.md` and `ADR.md` (project root) are the canonical, auto-loaded references and **win on any conflict** with this file. This file is the lean *pre-flight digest* an agent reads before touching code — it restates a fact only when an agent needs it up front, and points to `CLAUDE.md`/`ADR.md` for depth rather than copying them. If this file drifts, defer to `CLAUDE.md`.

---

## Technology Stack & Versions

### Stack facts (immutable, version-pinned)

- **Engine:** Godot **4.6.2-stable**, Forward+ renderer, D3D12, Windows 11. `config/features=("4.6","Forward Plus")`. **Engine version is pinned — do NOT author against 4.7+ APIs or suggest an upgrade.** The renderer is fixed for this 2D pixel game; don't reach for Compatibility-renderer- or mobile-only features.
- **Language:** GDScript only (no C#). Scene/node composition model.
- **Entry points:** main scene `res://main.tscn`; world logic in `res://World/world.tscn` (`world.gd`). Player lives in `world.tscn`, not `main.tscn`.
- **Pixel-art render settings:** viewport 320×180 logical / 1280×720 window; stretch `canvas_items`/`keep`; texture filter **Nearest (0)** — never bilinear.
- **Player sprites:** 56×56 px (NOT 64×64 — ADR-013 was wrong). `AnimatedSprite2D` scale `0.5`. SpriteFrames at `res://resources/characters/erik_sprites.tres`.
- **Version-coupled engine behavior (true in 4.6.2 — re-verify if engine bumps):**
  - `y_sort_offset` is **inert at runtime** — depth sort is driven purely by `position.y`. (`y_sort_offset` exists only as a `.tscn` serialization field; setting it via script errors.)
  - `run/auto_save/save_before_running` is **disabled on this machine** — Play uses the on-disk scene, not the editor's in-memory state.

### GDScript-4 idioms an agent trips on immediately

- **Typed-var annotation required** where inference is weak: `var dir: String = player.facing` (bare `var dir = ...` mis-infers).
- **Signal syntax is 4.x callable-style:** `sig.connect(callable)` / `sig.emit(args)` — never 3.x `connect("sig", self, "_m")`. Live example: `$Plant.plant_harvested.connect($DryingRack.add_plant)`.
- **`@onready` / `@export` are annotations** (`@` prefix) — bare `onready`/`export` is a parse error.
- **`await`, not `yield`** (and `await` is banned inside `execute_game_script` — see below).
- **Pre-approved warnings — do NOT "fix" these:** `tile_bit_tools` nested-UID duplicates, `hud.gd INT_AS_ENUM_WITHOUT_CAST`, `world_drop_item.gd` unused-var.

### Agent environment & tooling (scaffolding, not shipped game)

- **Game autoloads** (in `project.godot [autoload]`, runtime-visible): `godot_mcp` addon services `MCPScreenshot` / `MCPInputService` / `MCPGameInspector`, plus `TransitionManager`, `BetterTerrain` (uid), `InventoryManager`. Respect the existing order; don't reorder.
  - Trap: a static autoload is globally visible to scripts only **after a project reload**; a runtime-added autoload is NOT visible until editor restart. This is why `world.gd` uses `get_node_or_null("/root/InventoryManager")` instead of bare `InventoryManager`.
- **MCP Pro bridge** = a Node process (`mcp-bridge/index.js`) — **not** a Godot autoload. The Godot editor must be open with the MCP Pro plugin active. PixelLab MCP is also available. (All MCP/filesystem/PixelLab tools are pre-approved in `.claude/settings.json`.)
- **MCP execution gotchas (the #1 dev-loop blockers):**
  - `execute_game_script` / `execute_editor_script` — **tabs only** (spaces → "Mixed use of tabs and spaces" parse error), **no `await`**, use **`_mcp_print()`** not `print()`. Both run synchronously.
  - `simulate_key` via MCP does **NOT** trigger `_input()` — call the handler directly via `execute_game_script`.
  - `play_scene` always runs the *main* scene — to load a non-main scene at runtime use `change_scene_to_file` (deferred → split into two calls: load, then read state).
- **Windows / PowerShell 5.1:** `Out-File` / `Set-Content` add a BOM that breaks Godot's text-resource parser → use `[System.IO.File]::WriteAllText(path, content, [Text.Encoding]::UTF8)`. (This is a *rule*; the *fact* is just "shell = PowerShell 5.1.")

## Critical Implementation Rules

### Godot Scene & Node Patterns

**.tscn editing safety (these have caused recurring regressions):**
- **Never full-rewrite a `.tscn` with the Write tool** — it silently drops inline node properties (root cause of the recurring y_sort_offset loss, ADR-073→090). Use targeted Edit calls, or MCP (`update_property`, `execute_editor_script`).
- **Never edit a `.tscn` on disk while it's open in the Godot editor** — Godot holds it in memory and overwrites your disk edit on next save. To edit on disk: `open_scene("other.tscn")` → edit → reopen the original.
- **`script = null` trap:** grep `.tscn` files for `^script = null` — an editor op can null a node's script, silently killing all its logic at runtime (root cause of the 2026-05-24 hotbar/input regression). Remove the line.
- **MCP scene-write caveat:** `PackedScene.pack()` expands instanced sub-scenes inline and breaks unique IDs — do NOT use it for scenes that instance other scenes. Write those `.tscn` directly via Write using minimal instance format (`instance=ExtResource(...)`).

**Depth sorting (ADR-015 / ADR-091 / ADR-114):**
- `World` node has `y_sort_enabled = true`; Player and all world objects are siblings under it. Sort is **purely `position.y`** — `y_sort_offset` is inert (see Stack facts).
- To control depth: move the node origin (= sort line) and offset the child sprite to hold the visual. A node sorts behind the player when `player.y > node_sort_y`, in front when below.
- **Tree y-sort rule (ADR-091, permanent):** tree node origin = trunk base; `TreeSprite` child at `position.y = -(half_tree_height)`; leave `y_sort_offset` at 0. New species = set `TreeSprite.position.y` only.

**Self-registering scene patterns (add content without touching world.gd):**
- **Trees:** `choppable_tree.tscn` self-registers to group `"choppable_trees"`. New tree = duplicate scene, drop in world.
- **Rocks:** shared `choppable_rock.gd`, group `"choppable_rocks"`, requires axe, drops `stone_pile`. New rock = drop scene in world.
- **Garden plants:** direct children of World (un-nested, ADR-114), self-register to `"garden_plants"`.

**Interactable system (world.gd):**
- `world.gd` keeps `_interactables: Array[Node]`; nearest chosen by `distance_squared` in `_get_nearest_interactable()`. Interactables emit `interactable_entered/exited` and expose `interact(player)` (see `well.gd`, `door.gd`).
- Input actions are named InputMap actions — never hardcode keycodes: Space=`interact`, T=`npc_trade`, C=`equip_toggle`.

**Tool pattern:** `player.equipped_tool: String`. `EQUIPPABLE_TOOLS` dict in `world.gd` maps `item_key → InputMap action`. Adding a tool = 1 dict entry + 1 InputMap action.

**Scene transitions (ADR-010/014):** `TransitionManager` autoload — `await TransitionManager.fade_to_black(0.4)` before `change_scene_to_file`; `fade_from_black(0.4)` at top of destination `_ready()`. Cross-scene state via `Engine.set_meta/get_meta`. Disconnect the Area2D signal before the first `await` to prevent double-trigger; freeze player with `set_physics_process(false)`.

### Asset & Resource Rules

**Hard rules (require user approval — these are Safety/Asset rules):**
- **Never substitute, overwrite, or delete an asset (PNG, `.tres`, etc.) without explicit user approval** — including regenerating over an existing path via PixelLab, or deleting an "orphan"/unused resource. Choosing/removing art is the user's call.
- Missing asset? **Check `C:\Users\erikc\Dev\Game\temp\` first** (staging for incoming art). Not there → stop and ask.
- When asked to review a set of PNGs, **open and view every file individually** — never sample or assume similarity.
- Beware **duplicate/byte-identical PNGs on disk** (e.g. cannabis/garden art) — editing one won't update its copies; confirm scope before changing art.

**Asset roots (full map in CLAUDE.md → Asset Layout):**
- In-project canonical: `res://assets/` + `res://resources/` (ADR-062). External source masters: `C:/Users/erikc/Dev/Game/GameAssets/`.
- Player sprites `res://assets/characters/erik/` (56×56) → SpriteFrames `res://resources/characters/erik_sprites.tres`. Tiles 16×16 `res://assets/tiles/`.
- New-animation extraction (GIF→PIL→per-dir folders→`scan()`→`.tres` block): follow the ADR-116 recipe.

**Resource/tileset MCP gotchas:**
- **Direct `.tres` edits are overwritten** on editor reload — make tileset changes via `execute_editor_script`. (And never via PowerShell `Set-Content`/`Out-File` — BOM corrupts the resource; see Tech Stack.)
- **Import before `load()`:** copy PNG in → `EditorInterface.get_resource_filesystem().scan()` → confirm `.import` exists → `load()`.
- `update_property` does NOT resolve resource paths → assign via `execute_editor_script` + `load()`.
- `save_scene` saves the *active* editor scene → `open_scene` the target first. Expect UID auto-rewrites on save.
- **`load()` failure is silent:** an un-imported or broken PNG returns a non-null *broken* texture, not an error. After `load()`, confirm the asset actually previews (e.g. `get_resource_preview`) — don't trust that the call "succeeded."
- **Editor-open trap applies to assets too:** never edit a `.tres`/PNG on disk while its scene/resource is open in the editor — Godot overwrites your disk change on next save (same rule as `.tscn`; see Scene Patterns).

### Dev Workflow & MCP Loop

**Playtest is mandatory (not optional QA):**
- **If you make it, you playtest it.** Run the game via MCP, exercise the actual feature, screenshot to confirm the real behavior — *every* feature, before reporting done. Parsing/compiling is NOT playtesting.
- **Verification honesty (PRIME DIRECTIVE):** label every claim as (a) PARSES/COMPILES, (b) REASONED (static, not run), or (c) VERIFIED (actually run + observed in the real system). Never write "verified" next to a contradicting caveat — if it wasn't run and observed, say "NOT verified — not tested." Under-claim when in doubt.

**MCP dev-loop blockers (the #1 time sinks):**
- `execute_game_script` / `execute_editor_script` — **tabs only** (spaces → "Mixed use of tabs and spaces" parse error), **no `await`** (crashes; split async into two calls — e.g. `change_scene_to_file` is deferred → call 1 loads, call 2 reads state), use **`_mcp_print()`** not `print()`.
- `simulate_key` via MCP does **NOT** trigger `_input()` — call the handler directly via `execute_game_script`.
- `play_scene` always runs the **main** scene — to test a non-main scene, `change_scene_to_file` at runtime (two-call pattern above).
- `save_scene` saves the **active** editor scene → always `open_scene` the target first.

**Session-end pre-flight gate (run before any doc-update/commit on "end session"):**
1. grep all `.tscn` for `^script = null` (silently nulls a node's script at runtime).
2. `get_editor_errors` — block on anything beyond the pre-approved warnings (`tile_bit_tools` UID dups, `hud.gd INT_AS_ENUM`, `world_drop_item.gd` unused-var).
3. `play_scene` + `get_output_log` — block on `Parse Error` / `Script failed to load` / `SCRIPT ERROR`; stop the scene after.
If any fail: print `⚠ SESSION-END BLOCKED`, list issues, wait for user.

**Git:** local `main` tracks `origin/master`; the safety classifier blocks direct default-branch pushes — user pushes via `! git push origin HEAD:master`, or use a feature branch + PR.

### Critical Don't-Miss / Anti-Patterns

These are the silent footguns NOT already covered above. The recurring `.tscn` regressions (full rewrite, `script = null`, `pack()`, `y_sort_offset`) live in **Scene & Node Patterns** — don't repeat them; this list is the rest.

- **Never reuse an autoload name as a `class_name`** — `class_name Foo` + an autoload also named `Foo` is a hard conflict. (Autoloads: `TransitionManager`, `InventoryManager`, `BetterTerrain`, the `godot_mcp` services.)
- **Don't trust `enabled` / `visible` after a complex `execute_editor_script` run** — the editor UI can silently flip them mid-session. Re-verify the node state before concluding a bug is in your logic.
- **NPC waypoints are stored in World-local coords** — never pass them straight to nav as global. Convert via `get_parent().to_global(waypoint)`.
- **`_inv_mgr` uses `get_node_or_null("/root/InventoryManager")`, not bare `InventoryManager`** — a runtime-added autoload isn't globally visible to scripts until an editor restart. Don't "simplify" it to the bare name until after a restart.
- **Don't author against `y_sort_offset` as a live property** — setting it via script *errors* (it's a `.tscn`-only serialization field). Control depth with `position.y`. (Why it's inert: Tech Stack.)

---

## Usage Guidelines

**For AI Agents:**

- Read this file before implementing any code. It captures the unobvious rules only — `CLAUDE.md` and `ADR.md` hold the full depth, and this file points to them rather than duplicating them.
- Follow ALL rules exactly. When two options exist, prefer the more restrictive one (don't substitute assets, don't delete, don't full-rewrite `.tscn`, don't claim "verified").
- The **Verification Honesty** rule (Dev Workflow) overrides everything: never call something verified unless you ran it in the live engine and observed the result.
- If a new durable pattern emerges, propose adding it here — keep each rule earning its place.

**For Humans:**

- Keep this file lean and agent-focused. If a rule becomes obvious or moves into `CLAUDE.md`/`ADR.md`, remove it here.
- Update when the engine version, autoload set, or MCP loop changes.
- Review periodically and prune outdated rules.

Last Updated: 2026-06-05
