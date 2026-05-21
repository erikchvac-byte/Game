# New Tree Integration Report
**Date:** 2026-05-20  
**Session:** ADR-075 — Pine/Maple/Fir choppable tree systems

---

## PLACED TREE COUNT
**3 trees placed** in the grass area in front of the player's bakery house.

---

## TREE LOCATIONS

| Node | Species | World Position | Notes |
|------|---------|----------------|-------|
| TreePine1 | Pine | (55, 165) | Left of house, clear of door path |
| TreeMaple1 | Maple | (200, 162) | Right side, clear of Plant/DryingRack |
| TreeFir1 | Fir | (50, 240) | Lower left, open grass area |

All three are children of the World node in `world.tscn`.  
House door is at (112, 117) — no tree blocks the entrance or main north-south path.

---

## ANIMATIONS CONNECTED

### Pine (`res://resources/trees/pine_frames.tres`)
- `idle` — 1 frame, loop=true, 1 fps
- `chop` — 9 frames, loop=false, 9 fps
- `fall` — 9 frames, loop=false, 9 fps

### Maple (`res://resources/trees/maple_frames.tres`)
- `idle` — 1 frame, loop=true, 1 fps
- `chop` — 9 frames, loop=false, 9 fps
- `fall` — 9 frames, loop=false, 9 fps
- `hit_fall` — 9 frames, loop=false, 9 fps (chosen randomly ~50% on final chop)

### Fir (`res://resources/trees/fir_frames.tres`)
- `idle` — 1 frame, loop=true, 1 fps
- `chop` — 9 frames, loop=false, 9 fps
- `fall` — 9 frames, loop=false, 9 fps

### Stump (`res://resources/trees/stump_frames.tres`)
- `idle` — 1 frame, loop=true, 1 fps
- `dissolve` — 16 frames, loop=false, 8 fps (plays after tree falls, then hides)

---

## COLLISION SETUP

Each tree scene has:
- **TrunkCollider** `CollisionShape2D` — CapsuleShape2D (radius=5, height=10) at offset (0, 16)  
  Covers only the trunk base, not the canopy.
- **InteractArea** `Area2D` with CircleShape2D (radius=22) — triggers proximity prompt

All colliders disabled after tree falls (`disabled=true`).

---

## STUMP SETUP

- Stump uses shared `stump_frames.tres` (96×96, 0.5 scale) across all three species
- **StumpSprite** `AnimatedSprite2D` starts `visible=false`
- Shown after fall animation completes, plays `dissolve` animation (16 frames)
- Hidden again after dissolve finishes — state transitions to `GONE`
- Source: `GameAssets/Stumps/objects/Tree_stump_top-down_oblique_p_2/`

---

## Y-SORT VALIDATION

- All three trees set `y_sort_offset = 21` — trunk base sorts correctly
- Player renders behind canopy when north of trunk, in front when south ✅
- World node has `y_sort_enabled = true` — inherited by all children
- Willow tree (`y_sort_offset = 53`) unaffected — confirmed intact

---

## ISSUES FOUND

1. **Stale editor state** — world.tscn editor cache had phantom Tree1/Tree2/Tree3 nodes (Node2D) left over from a previous unsaved editor session despite ADR-074 committing their removal. These were deleted via MCP `delete_node`.
2. **Placeholder UIDs rejected** — wrote .tscn files with human-readable UIDs (`uid://pine_tree_scene01`) which are not valid base62. Required open+save via editor to assign real UIDs.
3. **`execute_editor_script` cannot set `y_sort_offset`** — CLAUDE.md warning confirmed: y_sort_offset is not a runtime GDScript property. Set via `node.set("y_sort_offset", 21)` in the editor script context, which worked.

---

## REPAIRS MADE

- Deleted Tree1/Tree2/Tree3 phantom nodes from editor in-memory scene
- Re-added tree nodes via `add_scene_instance` MCP tool
- Set positions and y_sort_offset via `execute_editor_script`
- Scene saved cleanly via `save_scene`

---

## CONFIRMATION CHECKLIST

- [x] Pine integrated — 3 animations (idle/chop/fall), placed at (55, 165)
- [x] Maple integrated — 4 animations (idle/chop/fall/hit_fall), placed at (200, 162)
- [x] Fir integrated — 3 animations (idle/chop/fall), placed at (50, 240)
- [x] Animated stump working — 16-frame dissolve, state→GONE after dissolve
- [x] Chopping fully functional — 3 chops required, chop→fall→stump→gone sequence verified
- [x] Wood granted — `_on_tree_chopped` adds wood to inventory (confirmed count 1→2)
- [x] Player depth sorting correct — player behind canopy, in front when south
- [x] No broken references — 0 editor errors on load
- [x] House entrance clear — trees do not block door at (112, 117)
- [x] No old tree system dependencies — world.gd uses group iteration, no hardcoded paths

---

## SOURCE ASSETS USED

| Species | Source Folder |
|---------|--------------|
| Pine | `GameAssets/TempAssetHolding/ResolvedReview/Tree Chop One/8a0d1475/` |
| Maple | `GameAssets/TempAssetHolding/ResolvedReview/Tree chop 2/7058ae11/` |
| Fir | `GameAssets/TempAssetHolding/ResolvedReview/Tree chop 3/291c36f2/` |
| Stump | `GameAssets/Stumps/objects/Tree_stump_top-down_oblique_p_2/default/` |

Copied to `game/assets/nature/trees/{pine,maple,fir}/` and `game/assets/nature/stumps/`.

---

## FILE INVENTORY CREATED

```
game/scenes/interactables/trees/
  choppable_tree.gd          # Base script (StaticBody2D, all species)
  pine_tree.tscn             # Pine species scene
  maple_tree.tscn            # Maple species scene
  fir_tree.tscn              # Fir species scene

game/resources/trees/
  pine_frames.tres           # SpriteFrames: idle/chop/fall
  maple_frames.tres          # SpriteFrames: idle/chop/fall/hit_fall
  fir_frames.tres            # SpriteFrames: idle/chop/fall
  stump_frames.tres          # SpriteFrames: idle/dissolve (shared)

game/assets/nature/trees/pine/     # pine_idle.png + pine_chop/ + pine_fall/
game/assets/nature/trees/maple/    # maple_idle.png + maple_chop/ + maple_fall/ + maple_hit_fall/
game/assets/nature/trees/fir/      # fir_idle.png + fir_chop/ + fir_fall/
game/assets/nature/stumps/         # stump_idle.png + stump_dissolve/
```
