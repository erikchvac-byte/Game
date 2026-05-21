# Tree Animation & Stump Fix Report

**Date:** 2026-05-21  
**ADR:** ADR-077  
**File modified:** `game/scenes/interactables/trees/choppable_tree.gd`

---

## Summary

Four issues were fixed in the Pine/Maple/Fir choppable tree system:
1. Chop/fall animations started immediately when axe input fired (no timing delay)
2. Stump played dissolve animation automatically on spawn
3. Stump spawned at scene origin (canopy center) instead of trunk base
4. Duplicate ghost nodes causing persistent idle image (fixed in ADR-076; this PR validates the clean result)

---

## TIMING CHANGES

**Problem:** `interact()` called `_tree_sprite.play("chop")` synchronously — tree animation started the same frame as the player axe swing.

**Fix:** `interact()` now starts `player.is_chopping = true` immediately (player swing begins), then fires a `SceneTreeTimer` with a **0.5-second delay** before the tree reacts.

### New flow:
```
t=0.0s   interact() called → player.is_chopping=true → player chop anim plays → timer starts
t=0.5s   _begin_tree_reaction() fires → player.is_chopping=false → _tree_sprite.play("chop")
t≈1.25s  chop anim ends → next state (IDLE or FALLING)
```

### NEW DELAY IMPLEMENTATION

Added `_begin_tree_reaction()` callback:

```gdscript
func interact(player: Node) -> void:
    ...
    get_tree().create_timer(0.5).timeout.connect(_begin_tree_reaction)

func _begin_tree_reaction() -> void:
    if _state != State.CHOPPING:
        return
    if _player:
        _player.is_chopping = false
    _tree_sprite.play("chop")
```

`create_timer()` returns a one-shot `SceneTreeTimer`; no manual cleanup needed. `player.is_chopping` is released in `_begin_tree_reaction` (not in `_on_tree_anim_finished`) so the player exits the chopping animation just as the tree starts reacting.

---

## STUMP ANIMATION FIX

**Problem:** `_on_tree_anim_finished()` called `_stump_sprite.play("dissolve")` — stump animated and disappeared immediately.

**Fix:** When fall animation ends, stump is shown **static** via:

```gdscript
_stump_sprite.stop()
_stump_sprite.animation = &"idle"   # stump_idle.png single-frame loop
_stump_sprite.frame = 0
_stump_sprite.visible = true
```

- `stop()` prevents any playback
- `animation = "idle"` switches to the dedicated static frame (stump_idle.png)
- `frame = 0` pins to the first (only) frame
- `stump_playing=false` confirmed in runtime check

`_on_stump_anim_finished()` and its signal connection have been removed (no animation = no finished signal).

---

## STUMP POSITION OFFSETS

**Problem:** `StumpSprite` had no position set (default `Vector2(0,0)`) — stump appeared at the tree sprite's center (canopy/scene origin), not the trunk base.

**Sprite analysis (96×96 @ scale 0.625 = 60×60 world px):**
- Pine trunk base: sprite y≈87 → world offset = (87−48)×0.625 = **24.4 world units** below origin
- Maple trunk base: sprite y≈85 → world offset = (85−48)×0.625 = **23.1 world units** below origin  
- Fir trunk base: sprite y≈87 → same as Pine ≈ **24.4 world units**

**Stump sprite analysis (96×96 @ scale 0.125 = 12×12 world px):**
- Stump cut surface (top): sprite y≈8 → world offset from center = (8−48)×0.125 = **−5 world units**

**Resulting stump y-offset** (aligns stump cut surface with trunk base):
- `24 − (−5) = 29 → rounded to **28.0**`

**Implementation** — set at `_ready()` via exported variable:

```gdscript
@export var stump_y_offset: float = 28.0

func _ready() -> void:
    _stump_sprite.position = Vector2(0.0, stump_y_offset)
```

`stump_y_offset` is an `@export var` so it can be fine-tuned per-species instance in the Godot Inspector without touching the script.

**Runtime verification:**
```
stump_pos=(0.0, 28.0)   ✓
stump_playing=false      ✓
stump_frame=0            ✓
stump_anim=idle          ✓
```

---

## COLLISION ADJUSTMENTS

No collision changes were required beyond the existing logic:

- `_trunk_col.disabled = true` — trunk StaticBody2D disabled after fall ✓
- `_interact_col.disabled = true` — interact Area2D disabled after fall ✓
- Collision shapes stay at their original positions (trunk base area) — correct ✓
- No canopy collision exists — correct ✓

---

## Y-SORT VALIDATION

- `World` node has `y_sort_enabled = true`
- Tree root positions: Pine (55,165), Maple (200,162), Fir (50,240)
- After fall, `tree_vis=false`; stump renders as child of tree root → y-sort uses tree root's `position.y`
- Stump at (0, 28) local = world (55, 193) for Pine. Player at y≈165–180 renders in front of stump (player.y > tree_root.y). Stump appears on ground behind player — correct depth ordering ✓

---

## FILES MODIFIED

| File | Change |
|------|--------|
| `game/scenes/interactables/trees/choppable_tree.gd` | Timing delay, static stump, stump position, removed stump anim signal |

No scene files (.tscn) required changes — stump position is set at `_ready()` from the export var.

---

## FINAL STATUS

| Check | Result |
|-------|--------|
| Player axe swing happens first (t=0) | ✅ |
| Tree reacts after 0.5s delay | ✅ |
| Stump animation disabled — static frame only | ✅ |
| Stump placed at trunk base (offset 28.0) | ✅ |
| No top-spawn / no floating stump | ✅ |
| No ghost idle image during chop/fall | ✅ (resolved ADR-076) |
| Collision disabled after fall | ✅ |
| Y-sort depth correct | ✅ |
| Script compiles without errors | ✅ |
| Full 3-chop → fall → static stump → wood grant | ✅ |
