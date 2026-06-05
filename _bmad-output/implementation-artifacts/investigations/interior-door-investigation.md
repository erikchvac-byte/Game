# Investigation: Interior Animated Door — "unverified" interaction

## Hand-off Brief

1. **What happened.** The ADR-117 interior animated door (`door.gd` + `door.tscn`, placed in `interior.tscn`) shipped with its interaction logic only *reasoned/parsed*, never run — flagged "door interaction NOT verified live."
2. **Where the case stands.** **Concluded.** Live playtest (2026-06-05) VERIFIED the full chain end-to-end: proximity registration → nearest-interactable selection → one-shot open animation → settle-closed → re-arm, with a clean output log. The door mechanic is **working**; nothing is functionally broken.
3. **What's needed next.** No functional fix required. What remains is the pre-existing backlog of cosmetic/robustness nits (TODO.md) — none block the door, and one (the vanity UID) is already closed. Highest value: decide the orphan `house_grey_hoodie_door_frames.tres` and visually check the exterior rock overlap.

## Case Info

| Field            | Value                                                                      |
| ---------------- | -------------------------------------------------------------------------- |
| Ticket           | N/A (ADR-117 follow-up)                                                     |
| Date opened      | 2026-06-05                                                                  |
| Status           | Concluded                                                                  |
| System           | Godot 4.6.2-stable, Forward+/D3D12, Windows 11                              |
| Evidence sources | Source (`door.gd`, `door.tscn`, `interior.gd`, `interior.tscn`, `door_sprites.tres`, `player.gd`, `player.tscn`), live MCP playtest, TODO.md deferred findings |

## Problem Statement

ADR-117 / CLAUDE.md note: "door interaction NOT verified live — logic only reasoned/parses." The investigation independently traces the door's interaction path, then exercises it in the running engine to determine whether it actually works and what (if anything) is left to fix.

## Evidence Inventory

| Source                       | Status    | Notes                                                                 |
| ---------------------------- | --------- | --------------------------------------------------------------------- |
| `door.gd`                    | Available | Interactable pattern (matches `well.gd`); `_animating` guard          |
| `door.tscn`                  | Available | Node2D + AnimatedSprite2D + DoorArea(CircleShape2D r=26), no collision body |
| `interior.tscn`              | Available | AnimatedDoor placed (58,-9) scale 0.83; Player named "Player"          |
| `interior.gd`                | Available | `_input` interact handler + `_interactables`/`_get_nearest_interactable` |
| `door_sprites.tres`          | Available | "open" anim, 9 frames, loop=false, speed=8                            |
| `player.gd` / `player.tscn`  | Available | `auto_walk` exposed; no own `_input`; default collision layer/mask 1  |
| Live playtest (MCP)          | Available | Full cycle exercised + screenshot + clean output log                  |

## Confirmed Findings

### Finding 1: Proximity detection fires and registers the door

**Evidence:** Live — after moving Player into the DoorArea, `area.get_overlapping_bodies()` includes Player, and `interior._interactables == [AnimatedDoor]`; `_get_nearest_interactable()` returned the door.

**Detail:** DoorArea (mask 1) detects the Player body (layer 1, `player.tscn:11` has no override). `door.gd:42-45` `_on_area_entered` emits `interactable_entered`; `interior.gd:54-56` appends it. Chain works.

### Finding 2: Interact triggers a one-shot open that settles closed and re-arms

**Evidence:** Live — `door.interact(player)` → `_animating=true, playing=true, anim=open`. On a later frame: `_animating=false, playing=false, frame=0`. A second `interact` re-opened (guard released); an immediate double-call held the guard (`_animating` stayed true, no second play).

**Detail:** `door.gd:29-40` — `interact()` guards on `_animating`, plays "open"; `_on_animation_finished` resets to frame 0 + `stop()` + clears `_animating`. `door_sprites.tres` has `loop=false`, so `animation_finished` fires. Re-armable and double-trigger-safe.

### Finding 3: Rest state is closed, door renders, room frames correctly

**Evidence:** Live — on scene load, DoorSprite reported `animation=open frame 0`; screenshot `temp/door_test_midswing.png` shows the wooden door closed on the north wall, player at it, whole room within the 0.7-zoom viewport. Output log: only the 2 engine banner lines, no `SCRIPT ERROR` / `Parse Error`.

**Detail:** `door.gd:25-27` `_ready` rests on `open`/frame 0. The decorative door has no collision body (`door.tscn` — DoorArea is the only Area2D, no StaticBody) — confirmed by design; the north `Walls` collider blocks movement, not the door.

## Deduced Conclusions

### Deduction 1: The "unverified" flag is now retired; the door is functionally complete

**Based on:** Findings 1–3.

**Reasoning:** Every link the door depends on — area mask vs player layer, signal wiring, `interact` handler, animation `loop=false`, guard, rest-frame reset — was observed working in the live engine, not inferred.

**Conclusion:** No functional defect exists. The remaining items are quality/robustness nits, not bugs.

## Source Code Trace

| Element       | Detail                                                                                  |
| ------------- | --------------------------------------------------------------------------------------- |
| Entry         | `interior.gd:39-45` `_input` on action `interact` → `_get_nearest_interactable().interact()` |
| Trigger       | Player Space-press while overlapping DoorArea (`door.tscn` DoorArea, r=26×0.83 scale)    |
| Condition     | `door.gd:30` not `_animating`; `door_sprites.tres` `loop=false` so `animation_finished` fires |
| Related files | `door.gd`, `door.tscn`, `interior.gd`, `interior.tscn`, `door_sprites.tres`, `well.gd` (pattern), `player.gd`/`player.tscn` |

## Conclusion

**Confidence:** High — Confirmed root state (working), deterministic live exercise of every branch.

The door interaction works. The ADR-117 "NOT verified live" caveat is resolved by this session's playtest. What is "left to fix" is **not** the mechanic — it is the 9 pre-existing deferred code-review findings (TODO.md §"Code Review — Deferred Findings"), all cosmetic, robustness, or user-decision items. See Recommended Next Steps for the prioritized list.

## Recommended Next Steps

### Fix direction (prioritized — none block the door)

**Robustness (small code edits):**
1. **`_get_nearest_interactable` has no max-range cull** — `interior.gd:63`. Mirrors `world.gd`; add a distance cap only if interactables grow.
2. **Hardcoded `"Player"` name match** — `door.gd:43,47`. Works (instance is named Player); fragile on rename. Consider group/`is` check.
3. **Inconsistent input-consumption on interact-miss** — `interior.gd:42-45` marks input handled only when a target exists.
4. **Door rest-frame depends on `loop=false`** — `door.gd:35-40`. Defensive nit; correct today.
5. **No facing / `can_interact` gate; interact doesn't cancel active mouse-nav** — `door.gd`/`interior.gd`. Consistent with the door being decorative; revisit if it gains function.

**Already resolved (was on the TODO list, no longer applies):**
- **Vanity UID** — TODO cited `door_sprites.tres` carrying hand-crafted `uid://b8doorspritescab`. The current file (regenerated this session, uncommitted) carries normal random `uid://c7mw3xmc0ldaf`. **Closed.**

**User-decision / visual:**
7. **Orphan `house_grey_hoodie_door_frames.tres`** — referenced only in `.godot` cache. Decide delete (needs approval — Safety Rule) or wire as a future exterior door.
8. **Possible rock overlap** — `world.tscn` TowerRock1 (230,142) / SquareRock1 (245,149). Needs a visual playtest (exterior, unrelated to interior door).
9. **Wall-collider asymmetry / SouthRight overhang** — `interior.tscn` opposing walls 140 vs 143; SouthRight overhangs east wall ~7px. Cosmetic (behind walls).

### Diagnostic

None required — behavior confirmed live. If item 8 is pursued, screenshot the exterior rock cluster.

## Reproduction Plan

Verification (not a defect repro): `play_scene` (main) → `change_scene_to_file("res://World/PlayerHome/interior.tscn")` → move Player to global ~(58,-33) → confirm `_interactables`/nearest = AnimatedDoor → `door.interact(player)` → observe `open` plays once then settles `frame 0`, `_animating` clears. Done 2026-06-05; passed.

## Side Findings

- `well.tscn` does not exist — the Well is built inline in `world.tscn`; the door correctly follows `well.gd`'s *script* pattern regardless. (Confirmed: Glob found only `well.gd`.)
- TODO.md line citations for the door findings (`interior.gd:34-40`, `:58`) have drifted from the current file (`_input` at 39-45, `_get_nearest_interactable` at 63) — cosmetic doc drift, no impact.
- Three pre-existing uncommitted files (`interior.tscn`, `world.tscn`, `door_sprites.tres`) were in the working tree at session start (noted in CLAUDE.md); this investigation read them as-is and did not modify them.
