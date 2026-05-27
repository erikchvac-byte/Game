# Game — Documentation Index

**Generated:** 2026-05-27 | **Scan:** Exhaustive | **Engine:** Godot 4.6.2-stable

👆 This file is the primary AI retrieval entry point. Start here for any feature work.

---

## Project Overview

- **Type:** Monolith Godot 4 game (GDScript)
- **Architecture:** Scene-component + singleton autoloads
- **Entry Point:** `res://main.tscn` → `res://World/world.tscn`
- **State:** Prototype — core loops working, content expansion in progress
- **As of:** 2026-05-27 — runnable, pre-flight passing, output log clean

---

## Quick Reference

| Topic | Where to look |
|---|---|
| Scene hierarchy | [Architecture → Scene Hierarchy](./architecture.md#scene-hierarchy) |
| Autoloads | [Architecture → Autoloads](./architecture.md#autoload-singletons) |
| Game systems | [Architecture → Core Systems](./architecture.md#core-systems) |
| Input map | [Architecture → Input Map](./architecture.md#input-map) |
| State (cross-scene) | [State Management](./state-management.md) |
| Asset locations | [Asset Inventory](./asset-inventory.md) |
| All scripts + their APIs | [Component Inventory](./component-inventory.md) |
| Directory structure | [Source Tree Analysis](./source-tree-analysis.md) |
| Run / setup / gotchas | [Development Guide](./development-guide.md) |

---

## Generated Documentation

- [Project Overview](./project-overview.md) — Executive summary, tech stack, project structure
- [Architecture](./architecture.md) — Scene hierarchy, all systems documented, depth sorting, input map
- [Source Tree Analysis](./source-tree-analysis.md) — Annotated full directory tree
- [Component Inventory](./component-inventory.md) — All authored scripts, their base types, signals, APIs
- [State Management](./state-management.md) — How state is stored, cross-scene mechanics, what doesn't persist
- [Asset Inventory](./asset-inventory.md) — All in-project PNGs: active, unwired, and missing
- [Development Guide](./development-guide.md) — Setup, run, common patterns, gotchas, session-end checklist

---

## Existing Documentation

- [CLAUDE.md](../CLAUDE.md) — Master dev reference: architecture decisions, quick facts, gotchas, roadmap
- [ADR.md](../ADR.md) — Architecture Decision Records (100+ entries)

---

## Getting Started

### Running the game
1. Open `C:/Users/erikc/Dev/Game/game/` in Godot 4.6.2
2. Press F5 to run `main.tscn`

### Finding where something is implemented
1. Check [Component Inventory](./component-inventory.md) for the script name
2. Check [Architecture → Core Systems](./architecture.md#core-systems) for the system description
3. Check [CLAUDE.md](../CLAUDE.md) for gotchas and cross-cutting constraints

### Working on a new feature
1. Read [Development Guide → patterns](./development-guide.md) for the relevant pattern
2. Check [Asset Inventory](./asset-inventory.md) for available (unwired) art
3. Check [State Management](./state-management.md) if the feature needs persistence

---

## Scan Metadata

- **Scan level:** Exhaustive (all source files read)
- **Scripts read:** 25 authored .gd files
- **Scenes catalogued:** 12 game scenes + 56+ addon scenes
- **Assets catalogued:** ~400+ PNGs across 30+ directories
- **State file:** [project-scan-report.json](./project-scan-report.json)
