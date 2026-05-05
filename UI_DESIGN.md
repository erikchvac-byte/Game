# UI Design Specification
**Project:** Game (Stardew-style pot growing)
**Last updated:** 2026-05-05
**Status:** Draft — approved by interview

---

## Overview

Top-down farming game centered on collecting water, growing plants through animated growth stages, and managing a daily loop of planting, watering, harvesting, and selling. UI is minimal, flat pixel art style — permanent top and bottom bars, world fills the center.

---

## Screen Layout (320×180 logical px)

```
┌─────────────────────────────────────────┐
│  [Water bar]    [Currency]   [Energy bar]│  ← Top bar (permanent)
├─────────────────────────────────────────┤
│                                         │
│                                         │
│            GAME WORLD                   │
│                                         │
│                                         │
├─────────────────────────────────────────┤
│  [ ][ ][ ][ ][ ][ ][ ][ ][ ][ ][ ][ ]  │  ← Hotbar 12 slots (permanent)
└─────────────────────────────────────────┘
```

- Both bars are **always visible** — no auto-hide
- Top bar: ~12px tall
- Bottom hotbar: ~16px tall
- Usable world area: ~152px tall

---

## HUD Elements

### Top Bar

| Element | Position | Details |
|---------|----------|---------|
| Water fill bar | Top-left | Shows current / max water in watering can. Droplet icon left of bar. |
| Currency | Top-center | Coin icon + number. Position finalized when currency system is designed. |
| Energy fill bar | Top-right | Depletes on tool use, refills after sleep. Bolt/leaf icon right of bar. |

### Bottom Hotbar

- 12 slots, bottom edge, full width
- Holds **everything**: tools, items, seeds, consumables
- Navigate: **number keys 1–12** or **scroll wheel**
- Selected slot: highlighted frame
- **Watering can slot**: shows a number badge (current water count) in corner of icon
- Hotbar is the bottom row of the full inventory — same slot pool

---

## Tools

All six tools occupy hotbar slots:

| Tool | Purpose |
|------|---------|
| Watering can | Water plants in pots |
| Bucket / jug | Collect water from well |
| Shovel / trowel | Plant seeds in pots |
| Scythe / shears | Harvest mature plants |
| Hoe | Tend soil (fertilize, remove weeds) |
| Fertilizer applicator | Apply fertilizer to pots |

---

## Plant Growth Display

- **No floating UI above pots**
- The plant's own sprite animation communicates growth stage entirely
- Each plant has a unique animation per growth stage
- The animation IS the progress indicator — no bar, no label, no icons above pot

---

## Interaction Prompts

- A small popup appears **above the target object** when the player is in range
- Format: button icon + action label (e.g. `[E] Water`, `[E] Harvest`, `[E] Enter Shop`)
- Disappears when player moves out of range
- One prompt visible at a time

---

## Notifications (Toast)

- Appears in **top-right corner**
- Slides in, holds briefly, fades out
- Paired with animation/visual feedback on the interacted object
- Examples:
  - `Plant watered!`
  - `Not enough water`
  - `Harvest ready!`
  - `Seed planted`
  - `Item sold`

---

## Inventory (Full Screen Overlay)

- Opens via: **Tab / I key** OR **backpack icon on HUD**
- Full-screen overlay — world pauses or dims behind it
- Hotbar slots are the bottom row of this same grid
- Scroll if inventory exceeds visible grid
- Close via same key or Escape

---

## Shop Interface (Full Screen)

- Triggered by interacting with a shop NPC or building
- Two-panel full-screen layout:
  - **Left panel**: player inventory
  - **Right panel**: shop stock (items to buy)
- Buy / sell tabs or toggle at top
- Selected item shows name, description, price
- Confirm / cancel buttons

---

## Visual Style

- **Clean flat pixel art**
- Minimal or no borders on panels
- Simple solid color backgrounds (semi-transparent dark fill over world for overlays)
- No wood/stone decorative frames
- Nearest-neighbor texture filter (matches game assets)
- One bitmap pixel font for all UI text

---

## Asset Checklist

### Icons (16×16 px)
- [ ] Watering can
- [ ] Shovel / trowel
- [ ] Scythe / shears
- [ ] Hoe
- [ ] Fertilizer applicator
- [ ] Bucket / jug
- [ ] Coin / currency icon
- [ ] Backpack / inventory icon
- [ ] Water droplet (HUD bar icon, ~10×10px)
- [ ] Energy icon — bolt, leaf, or star (~10×10px)

### UI Panels
- [ ] Top HUD bar background
- [ ] Hotbar background panel
- [ ] Hotbar slot frame (empty)
- [ ] Hotbar slot highlight (selected)
- [ ] Number badge overlay (for water count on watering can slot)
- [ ] Water fill bar — background + fill
- [ ] Energy fill bar — background + fill
- [ ] Inventory overlay background (full-screen, semi-transparent)
- [ ] Inventory slot frame
- [ ] Shop screen — left panel background
- [ ] Shop screen — right panel background
- [ ] Shop tab sprites (buy / sell)
- [ ] Toast notification panel
- [ ] Interaction prompt bubble / box

### Buttons
- [ ] Confirm button
- [ ] Cancel button

### Font
- [ ] Pixel bitmap font (one size for all UI text; second size optional for headers)

---

## TBD / Deferred

| Item | Notes |
|------|-------|
| Currency position (exact) | Top-center placeholder — finalize when currency system designed |
| Energy icon style | Bolt vs leaf vs star — not decided |
| Day/night UI elements | Deferred to later session |
| Inventory grid dimensions | Finalize when item count is known |
| Backpack icon position on top bar | Not specified yet |
| Number badge style | Corner of slot vs below icon |

---

## Implementation Notes (Godot)

- All UI lives in a `CanvasLayer` (layer = 10) in `main.tscn`
- Shop and inventory overlays are separate `CanvasLayer` nodes (layer = 20) shown/hidden on demand
- Toast notification: `AnimationPlayer` on a `PanelContainer` — slide + fade tween
- Hotbar selection: `HBoxContainer` of 12 `TextureRect` / `Panel` nodes, highlight driven by input
- Water and energy bars: `ProgressBar` nodes with custom styleboxes
- Interaction prompt: `Label` + `PanelContainer` child of the interactable object, visible toggle on `Area2D` body_entered / body_exited
