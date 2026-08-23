# Toad's Great Escape Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [x]`) syntax for tracking.

**Goal:** Build a playable 18-stage Wind in the Willows book-homage obby from the existing procedural Roblox framework.

**Architecture:** Keep the current procedural generation pipeline and strengthen the theme where the game already composes stages, zones, decoration, checkpoints, HUD, and docs. Add one static Python contract test to protect the storyboard and keep future kid edits from silently breaking stage/template alignment.

**Tech Stack:** Roblox Luau, Rojo project layout, Bash check script, Python standard library for static repository tests, StyLua, Selene.

---

## File Structure

- Modify `src/shared/Config/GameConfig.lua`: add title/subtitle/story values used by UI and docs.
- Modify `src/shared/Config/WorldGenConfig.lua`: define the exact 18-stage storyboard order.
- Modify `src/shared/Config/ZoneConfig.lua`: rename zones to book-homage chapters with brighter palettes.
- Modify `src/server/WorldGen/Templates/StageTemplates.lua`: implement/rename missing stage templates and add stage signs/set pieces.
- Modify `src/server/WorldGen/StageBuilder.lua`: use story names in banners.
- Modify `src/server/WorldGen/DecorBuilder.lua`: tune lighting and zone decoration to storybook color.
- Modify `src/client/Controllers/UIController.lua`: show game title and chapter-style milestone text.
- Modify `README.md` and `README_KIDS.md`: document the new theme and kid remix hooks.
- Create `scripts/storyboard_contract.sh`: static contract test for stage count, template coverage, title, and kid-doc copy.
- Modify `scripts/check.sh`: run the Python storyboard contract before Luau format/lint.

## Tasks

### Task 1: Add Storyboard Contract Test

**Files:**
- Create: `scripts/storyboard_contract.sh`
- Modify: `scripts/check.sh`

- [x] Create a Bash test that parses `WorldGenConfig.lua` and `StageTemplates.lua`, asserts 18 configured stages, asserts every configured stage has a matching template function, asserts `GameConfig.Title` includes `Toad`, and asserts `README_KIDS.md` references `Wind in the Willows`.
- [x] Run `scripts/storyboard_contract.sh`; expected result before implementation: fail because the stage list is currently 16 and `GameConfig.Title` does not exist.
- [x] Add `scripts/storyboard_contract.sh` to `scripts/check.sh` before `stylua`.
- [x] Re-run `scripts/storyboard_contract.sh` after production changes; expected result: pass.

### Task 2: Define Title, Zones, And 18-Stage Storyboard

**Files:**
- Modify: `src/shared/Config/GameConfig.lua`
- Modify: `src/shared/Config/WorldGenConfig.lua`
- Modify: `src/shared/Config/ZoneConfig.lua`

- [x] Add `Title = "Toad's Great Escape"` and short subtitle/story strings to `GameConfig`.
- [x] Replace the stage list with 18 unique story chapters: `RiverbankWelcome`, `MoleBurrowBounce`, `RattyRiverStones`, `ToadHallGate`, `LibraryTumble`, `RunawayCaravan`, `TavernBarrelHop`, `CourtroomChaos`, `JailbreakBars`, `LaundryCartEscape`, `BargeCrossing`, `TrainTunnelDash`, `WildWoodGusts`, `BadgerLanternPath`, `MotorcarMadness`, `RoadsideConeSprint`, `HomecomingRingRun`, `ToadHallFireworks`.
- [x] Rename the three zones to Riverbank & Toad Hall, Trouble & Escape, and Wild Wood Homecoming with distinct palettes.

### Task 3: Implement Stage Templates

**Files:**
- Modify: `src/server/WorldGen/Templates/StageTemplates.lua`

- [x] Rename existing templates where possible instead of deleting their useful behavior.
- [x] Add missing templates for the 18-stage contract.
- [x] Keep every stage finishable with a visible forward route.
- [x] Add short signs and set pieces: river stones, burrow clouds, hall gate, books, caravan conveyor, tavern barrels, court lasers, jail bars, laundry cart escape, barge boats, train tunnel, wild wood wind, badger lanterns, road cones, homecoming rings, fireworks.

### Task 4: Make Story Visible In Banners, HUD, And Docs

**Files:**
- Modify: `src/server/WorldGen/StageBuilder.lua`
- Modify: `src/client/Controllers/UIController.lua`
- Modify: `README.md`
- Modify: `README_KIDS.md`

- [x] Add a display-name lookup for configured stage types.
- [x] Change checkpoint banners from plain `Stage N / total` to `Stage N / total: Story Name`.
- [x] Add a title strip to the HUD using `GameConfig.Title`.
- [x] Update milestone copy so it sounds like a storybook chase.
- [x] Rewrite kid docs around changing seed, colors, speeds, stage order, and signs.

### Task 5: Verify

**Files:**
- No production changes unless verification exposes a bug.

- [x] Run `scripts/storyboard_contract.sh`; expected: pass.
- [x] Run `./scripts/check.sh`; expected: pass or report missing local tools clearly.
- [x] Run `git diff --check`; expected: no whitespace errors.
- [x] Inspect `git diff --stat` and summarize changed files.
