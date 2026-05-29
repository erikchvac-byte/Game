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

- [ ] **Hotbar (7-slot)** — `res://assets/ui/hotbar_7slot.png` imported. **BLOCKED — user decision needed.** Current hotbar is 12-slot procedural (hud.gd). To use this PNG as-is: reduce SLOT_COUNT 12→7 and update inventory logic. Alternatively: use as background decoration behind existing slots. Cannot substitute art without explicit approval.
- [ ] **Water/fill bar** — `res://assets/ui/fill_bar_new.png` imported. **BLOCKED — needs approval.** Candidate replacement for `WaterMeterBar.png` in `hud.gd:70-72` TextureProgressBar, or wire as a new stamina bar (stamina system doesn't exist yet). Per ASSET REPLACEMENT RULE, needs explicit user decision.
- [ ] **UI panel — grey metallic** — `res://assets/ui/panel_grey_metal.png` imported. **BLOCKED — no target scene.** Possible use: crafting UI background, dialog frame. Tell me which scene/element.
- [ ] **UI panel — dark wood** — `res://assets/ui/panel_dark_wood.png` imported. Same as above.
- [ ] **UI panel — light wood** — `res://assets/ui/panel_light_wood.png` imported. Same as above.

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

## Items / Pickups

- [x] **Seed packets** — `res://assets/props/items/seed_packets.png` wired as starting inventory item `"seed_packets"` in `world.gd`. Visible in hotbar slot ✅. Acquisition method (shop/chest) TBD.
