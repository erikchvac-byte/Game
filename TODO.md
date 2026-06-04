# Game — To Do List

> One task per asset/feature. Add here when assets are imported and need wiring.

---

## Player Character — Erik (new animation set)

- [x] **Erik idle animation** — `idle_animated_down/side/up` added to `erik_sprites.tres`. `player_animation.gd` updated: idle now uses animated versions; bucket-carrying still uses static idle_*_bucket.
- [x] **Erik crafting animation** — `crafting_up` (9f, north-only) added to `erik_sprites.tres`. No player_animation.gd branch yet — mechanic doesn't exist. Animation ready to wire when crafting state is defined on player.
- [x] **Erik digging/shovel animation** — `digging_down` + `digging_side` (16f each) added to `erik_sprites.tres`. ⚠ No north dir in source assets — flag for PixelLab regen if needed. Shovel mechanic not yet implemented.
- [x] **Erik eating mushroom animation** — `eating_down/side/up` (16f each) added to `erik_sprites.tres`. Consume system not yet implemented.
- [x] **Erik jumping animation** — `jumping_down/side/up` (9f each) added to `erik_sprites.tres`. Jump mechanic not yet implemented.
- [x] **Erik push object animation** — `push_down/side/up` (6f each) added to `erik_sprites.tres`. Push mechanic not yet implemented.
- [x] **Erik trading animation (new)** — `trade_item_down/side/up` (6f each) added to `erik_sprites.tres` as supplement to existing `trade_*`. Use for item hand-off events vs NPC dialogue trade.
- [x] **Erik pickaxe animation (new)** — `pickaxe_strike_down/side/up` (9f each) added to `erik_sprites.tres`. `player_animation.gd` updated: when `equipped_tool == "pickaxe"` and `is_chopping`, plays `pickaxe_strike_` + dir. Playtested ✅
- [x] **Erik axe animation (new)** — `chop_axe_down/side/up` (16f each) added to `erik_sprites.tres`. No west dir in source — east + flip_h covers left-facing. No player_animation.gd branch yet; existing `chop_*` plays for axe. Wire when chop_axe replaces chop_* for axe tool.

## UI

- [x] **Hotbar (7-slot)** — `hotbar_7slot.png` wired as hotbar background in `hud.gd`. SLOT_COUNT 12→7 across `hud.gd`, `world.gd` (_HOTBAR_SLOTS), `InventoryManager.gd` (HOTBAR_SLOTS), `UI/inventory.gd` + `Plants/inventory.gd` (hardcoded 12→7). Playtested ✅.
- [x] **Water/fill bar** — `fill_bar_new.png` wired to HUD top bar. Replaced TextureProgressBar (couldn't use 200×200 PNG as TP texture — forces 200×200 minimum size) with Control wrapper + TextureRect(fill_bar_new.png, STRETCH_SCALE) + ColorRect(blue fill, width=ratio×44px). `_refresh_water_bar()` updated. WaterMeterBar.png no longer referenced. Playtested ✅.
- [ ] **UI panel — grey metallic** — `res://assets/ui/panel_grey_metal.png` available. Wiring deferred — awaiting scene/element assignment.
- [ ] **UI panel — dark wood** — `res://assets/ui/panel_dark_wood.png` available. Wiring deferred — awaiting scene/element assignment.
- [ ] **UI panel — light wood** — `res://assets/ui/panel_light_wood.png` available. Wiring deferred — awaiting scene/element assignment.

## Crops / Plants

> ⚠ Full crop system requires a dedicated session: PlantableSoil scene, CropGrowth state machine, harvest mechanic. All animation assets are imported and ready.

- [ ] **Corn/wheat sprout emergence animation** — 17f (Group 1) — at `res://assets/nature/crops/`. Needs crop system.
- [ ] **Corn stalk growth animation** — 16f (Group 2) — at `res://assets/nature/crops/`. Needs crop system.
- [ ] **Berry bush growth animation** — 17f (Group 3) — at `res://assets/nature/crops/`. Needs crop system.
- [ ] **Orange-fruited mature bush (static)** — **BLOCKED — needs PixelLab animation regen.** Static sprite at `res://assets/nature/crops/berry_bush/`. No valid animation (misgenerated).
- [ ] **Corn/wheat growth stage sprites** — static stage frames — needs crop growth state machine.
- [ ] **Berry bush stage sprites** — static stage frames — needs crop growth state machine.
- [ ] **Weed sprites** — needs world/tile placement decision.
- [ ] **Garden plot sprites** — 2-stage garden sprites — needs farming scene integration.

## Code Review — Deferred Findings (animated door + interior expansion, 2026-06-03)

> From adversarial code review (Blind Hunter + Edge Case Hunter). 1 patch already fixed & verified (camera limits in `interior.gd`). The 9 below were deferred — pre-existing pattern, cosmetic, or need a user decision. 4 findings were dismissed as verified-OK noise.

- [ ] **Orphan `house_grey_hoodie_door_frames.tres`** — new SpriteFrames referenced only in `.godot` cache (unused). Likely intended for a future *exterior* animated door. **Decide: delete or wire.** Deletion needs explicit approval (Safety Rule).
- [ ] **Possible rock overlap** — `world.tscn`: TowerRock1 (230,142) / SquareRock1 (245,149) repositioned this session, ~7–15px apart at scale 0.5. **Needs a visual playtest** — may be fine or may be a visible overlap.
- [ ] **Hand-crafted UID `uid://b8doorspritescab`** — `door_sprites.tres` uses a non-random vanity UID (collision-prone vs Godot's generator). Works now; regenerate to a random UID when convenient.
- [ ] **`_get_nearest_interactable` has no max-range cull** — `interior.gd:58`. Matches `world.gd`'s existing pattern; not a regression. Consider a distance cap if interactables grow.
- [ ] **Hardcoded `"Player"` node-name match** — `door.gd:43,47`. Verified working today (node is named Player); matches codebase convention. Fragile if renamed.
- [ ] **Wall-collider asymmetry / SouthRight overhang** — `interior.tscn`: opposing walls 140 vs 143; SouthRight overhangs east wall ~7px. Eyeballed geometry, cosmetic (behind walls).
- [ ] **Inconsistent input-consumption on interact-miss** — `interior.gd:34-40`: input only marked handled when a target exists. Minor.
- [ ] **Door rest-frame relies on `loop=false`** — `door.gd`: settles on frame 0 via `animation_finished`. Defensive nit; frames correct today.
- [ ] **Door has no facing/`can_interact` gate; interact doesn't cancel active mouse-nav** — `door.gd` / `interior.gd`. Design choice consistent with the door being decorative.

## Items / Pickups

- [x] **Seed packets** — `res://assets/props/items/seed_packets.png` wired as starting inventory item `"seed_packets"` in `world.gd`. Visible in hotbar slot ✅. Acquisition method (shop/chest) TBD.
