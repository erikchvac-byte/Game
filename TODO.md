# Game — To Do List

> One task per asset/feature. Add here when assets are imported and need wiring.

---

## Player Character — Erik (new animation set in temp/)

- [ ] **Erik idle animation** — 4-dir × 6f idle with body sway — imported to temp/idle, needs wiring to `erik_sprites.tres` + `player_animation.gd`
- [ ] **Erik crafting animation** — north-only × 9f back-facing crafting motion — needs wiring to `erik_sprites.tres`
- [ ] **Erik digging/shovel animation** — 3-dir (E/S/W) × 16f shovel dig cycle — needs wiring to `erik_sprites.tres` + game mechanic
- [ ] **Erik eating mushroom animation** — 4-dir × 16f red mushroom eat + red sparks — needs wiring to `erik_sprites.tres` + consume system
- [ ] **Erik jumping animation** — 4-dir × 9f crouch-launch-land — needs wiring to `erik_sprites.tres` + movement system
- [ ] **Erik push object animation** — 4-dir × 6f arms-forward push — needs wiring to `erik_sprites.tres` + push mechanic
- [ ] **Erik trading animation (new)** — 4-dir × 6f arm-extend hand-off — needs wiring to `erik_sprites.tres` (replaces or supplements existing trade?)
- [ ] **Erik pickaxe animation (new)** — 4-dir × 9f pickaxe downward swing — needs wiring to `player_animation.gd` (branch on `equipped_tool == "pickaxe"`)
- [ ] **Erik axe animation (new)** — 3-dir (S/N/E) × 16f wood axe chop — needs wiring to `erik_sprites.tres` (no west dir — use east mirror)

## UI

- [ ] **Hotbar (7-slot)** — `temp/HotBar New/hotbar_7slot.png` — imported, needs wiring to HUD scene (replaces or supplements existing hotbar?)
- [ ] **Water/fill bar** — `temp/New water fill bar/.../fill_bar.png` — imported, needs wiring to HUD (water meter? stamina bar?)
- [ ] **UI panel — grey metallic** — `temp/UI Panels.../Date_and_time_1/.../unknown.png` — imported, needs scene/use assignment
- [ ] **UI panel — dark wood** — `temp/UI Panels.../Date_and_time_2/.../unknown.png` — imported, needs scene/use assignment
- [ ] **UI panel — light wood** — `temp/UI Panels.../Date_and_time_3/.../unknown.png` — imported, needs scene/use assignment

## Crops / Plants

- [ ] **Corn/wheat sprout emergence animation** — 17f grow anim (Group 1) — needs crop system scene integration
- [ ] **Corn stalk growth animation** — 16f sprout→full corn stalk (Group 2) — needs crop system scene integration
- [ ] **Berry bush growth animation** — 17f small plant→large leafy bush (Group 3) — needs crop system scene integration
- [ ] **Orange-fruited mature bush (static)** — `orange_fruited_mature_bush.png` + `This_plant_has_a_bun/rotations/unknown.png` — **no valid animation** (only candidate was misgenerated — needs PixelLab regeneration before wiring). Static sprite available for world placement.
- [ ] **Corn/wheat growth stage sprites** — static frames (seed mound, mid-stalk, ears, full wheat) — needs crop growth state machine
- [ ] **Berry bush stage sprites** — static frames (small plant, blue/orange berry stage) — needs crop growth state machine
- [ ] **Weed sprites** — low weeds + small growing weeds — needs world/tile placement
- [ ] **Garden plot sprites** — 2-stage garden (young seedlings, mature plants) — needs farming scene integration

## Items / Pickups

- [ ] **Seed packets** — `seed_packets.png` (fanned cards, multiple varieties) — needs inventory item wiring
