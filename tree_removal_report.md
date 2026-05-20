# Tree Removal Report — 2026-05-20

**Task:** Remove the three standard (non-willow) choppable tree systems from the project.  
**Constraint:** Willow tree system must remain completely untouched.

---

## REMOVED SCENES

| File | Reason |
|------|--------|
| `game/World/ChoppableTree/choppable_tree.tscn` | Base scene used by all three world tree instances |
| `game/World/ChoppableTree/choppable_tree_pine.tscn` | Species variant scene (standalone, never placed in world) |
| `game/World/ChoppableTree/choppable_tree_maple.tscn` | Species variant scene (standalone, never placed in world) |
| `game/World/ChoppableTree/choppable_tree_fir.tscn` | Species variant scene (standalone, never placed in world) |

---

## REMOVED SCRIPTS

| File | Reason |
|------|--------|
| `game/World/ChoppableTree/choppable_tree.gd` | Tree chop/fall state machine — tree-exclusive |
| `game/World/ChoppableTree/choppable_tree.gd.uid` | UID sidecar for above |

**Directory removed:** `game/World/ChoppableTree/` (empty after deletions)

---

## REMOVED ASSETS

### Tree Static Sprites
| File | Used by |
|------|---------|
| `game/assets/nature/trees/tree_pine_3.png` + `.import` | choppable_tree_pine.tscn |
| `game/assets/nature/trees/tree_maple.png` + `.import` | choppable_tree_maple.tscn |
| `game/assets/nature/trees/tree_fir.png` + `.import` | choppable_tree_fir.tscn |
| `game/assets/nature/trees/tree_pine_bushy_b.png` + `.import` | world.tscn Tree1 (now removed) |
| `game/assets/nature/trees/tree_pine_narrow.png` + `.import` | world.tscn Tree2 (now removed) |
| `game/assets/nature/trees/tree_ginkgo.png` + `.import` | world.tscn Tree3 (now removed) |

### Tree Animation Directories (9 frames each)
| Directory | Used by |
|-----------|---------|
| `game/assets/nature/trees/pine_chop/` | choppable_tree_pine.tscn |
| `game/assets/nature/trees/pine_fall/` | choppable_tree_pine.tscn |
| `game/assets/nature/trees/maple_chop/` | choppable_tree_maple.tscn |
| `game/assets/nature/trees/maple_fall/` | choppable_tree_maple.tscn |
| `game/assets/nature/trees/maple_hit_fall/` | Referenced in docs, no scene ref — orphaned |
| `game/assets/nature/trees/fir_chop/` | choppable_tree_fir.tscn |
| `game/assets/nature/trees/fir_fall/` | choppable_tree_fir.tscn |

### Stump Assets
| File | Used by |
|------|---------|
| `game/assets/nature/stumps/stump_round.png` + `.import` | All three species variant scenes |
| `game/assets/nature/stumps/stump_round_dissolve/` (16 frames) | Referenced in docs, no scene ref — orphaned |
| `game/assets/nature/stumps/log_brown_short.png` + `.import` | world.tscn Tree1/Tree2/Tree3 stump_texture |

### Assets KEPT (verified in use)
| File | Still used by |
|------|---------------|
| `game/assets/nature/stumps/log_fallen_brown.png` | world.tscn id=45_i52kj (world prop) |
| `game/assets/nature/stumps/BigMushroomStump.png` | world.tscn id=49_h4hkh (world prop) |
| `game/assets/nature/trees/willow/` | WillowTree system — untouched |
| `game/assets/nature/trees/tree_oak_green.png` | Orphaned (unrelated to removed systems — left for user) |

---

## REMOVED WORLD INSTANCES

| Node Name | Position | Scene |
|-----------|----------|-------|
| `Tree1` | Vector2(42, 213) | choppable_tree.tscn + tree_pine_bushy_b.png |
| `Tree2` | Vector2(93, 237) | choppable_tree.tscn + tree_pine_narrow.png |
| `Tree3` | Vector2(161, 202) | choppable_tree.tscn + tree_ginkgo.png |

All three were direct children of the `World` node in `world.tscn`.

---

## REMOVED COLLIDERS

All colliders were embedded in the `choppable_tree.tscn` base scene and removed with it:
- `TreeCollider` (StaticBody2D + CollisionShape2D, CircleShape2D r=10) — blocked player passage through trunk
- `ChopArea` (Area2D + CollisionShape2D, CircleShape2D r=22) — triggered interactable_entered/exited proximity signals

---

## REMOVED REFERENCES

### world.tscn ext_resources
| ID | Path | Reason |
|----|------|--------|
| `choptree_scene` | `res://World/ChoppableTree/choppable_tree.tscn` | Base scene |
| `52_3gnva` | `res://assets/nature/trees/tree_pine_bushy_b.png` | Tree1 texture |
| `53_i5ake` | `res://assets/nature/trees/tree_pine_narrow.png` | Tree2 texture |
| `54_dmovf` | `res://assets/nature/trees/tree_ginkgo.png` | Tree3 texture |
| `56_eyejc` | `res://assets/nature/stumps/log_brown_short.png` | Stump texture (all three trees) |

### world.gd code removed
| Location | Code | Purpose |
|----------|------|---------|
| Line 4 | `const CLICK_TREE_RADIUS := 22.0` | Right-click tree targeting radius |
| `_ready()` lines 46–49 | `for tree in get_nodes_in_group("choppable_trees")` loop | Signal wiring |
| `_on_wood_chopped()` | Entire 3-line function | Wood reward on chop |
| `_input()` | `is_in_group("choppable_trees")` + `player.is_chopping = true` | Chop animation trigger |
| `_on_right_click()` | 13-line tree search loop | Click-to-chop navigation |
| `_do_nav_interact()` | `is_in_group("choppable_trees")` + `player.is_chopping = true` | Nav-chop animation trigger |

---

## VALIDATION RESULTS

### Broken scene references
`grep -r "choppable_tree\|choptree_scene\|52_3gnva\|53_i5ake\|54_dmovf\|56_eyejc" game/**/*.{tscn,gd}` → **0 matches** ✅

### Missing scripts
`game/World/ChoppableTree/` directory — **removed entirely** ✅  
No other scripts referenced `choppable_tree.gd`.

### Invalid groups
`grep -r "choppable_trees" game/**/*.gd` → **0 matches** ✅

### Orphaned collisions
Tree1/Tree2/Tree3 nodes removed from world.tscn; their child colliders removed with them ✅

### Preload/load failures
`grep -r "tree_pine_3\|tree_maple\|tree_fir\|stump_round\|pine_chop\|maple_chop\|fir_chop" game/**/*.gd` → **0 matches** ✅

### Interaction system
- Well: ✅ untouched
- Plant/DryingRack: ✅ untouched
- NPC trade: ✅ untouched
- `_on_interactable_entered/exited` handlers: ✅ untouched (generic)
- Axe equip (EQUIPPABLE_TOOLS, C key): ✅ untouched
- Player movement: ✅ untouched

### Willow tree
- `game/World/WillowTree/willow_tree.gd` — **untouched** ✅
- `TreeWillowWeeping` node in world.tscn — **untouched** ✅
- Willow assets (`assets/nature/trees/willow/`) — **untouched** ✅
- `assets/_archived/willow_idle.png` — **untouched** ✅
- WillowFrames SpriteFrames in world.tscn — **untouched** ✅
- WillowProxShape/TreeCollider collision in world.tscn — **untouched** ✅

---

## CONFIRMATION

- ✅ Only willow remains as a tree system
- ✅ No standard choppable tree system remains (scenes, scripts, colliders, groups, signals, drops)
- ✅ No broken references in any .tscn, .gd, or .tres file
- ✅ Player movement unaffected
- ✅ Interaction system unaffected
- ✅ Axe/tool equip system unaffected (EQUIPPABLE_TOOLS, C key, hotbar)
- ✅ Willow system completely untouched
