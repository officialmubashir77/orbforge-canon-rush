# Technical architecture (Phase 1)

## Graph

`scenes/main/main.tscn` → `scripts/ui/main.gd` creates the menu state and screen holder. It instantiates `WorldPainter`, `OrbAudio`, and `OrbArena` for a campaign run. The arena spawns physics-body `OrbBall` instances, the movable `PlayerCannon`, a fixed 95-instance `OrbProjectile` pool, and the centralized `EffectsLayer`.

## Core event flow

1. Main UI selects a level and a weapon from JSON content.
2. `OrbArena.setup()` computes weapon stats using `RunRules.weapon_stats()` and starts wave 1.
3. Arena spawns physical orbs from the JSON wave budget; cannon fires at configurable intervals. Drag events control horizontal movement.
4. Projectiles execute physics ray queries to avoid skipping large targets; `OrbBall.receive_damage()` updates actual HP.
5. Killed orbs award score, spawn collectible coins, and create two smaller orbs when tier > 1.
6. Wave completes only when pending spawns and live orbs are both empty; after final wave, `run_finished` signal fires.
7. `Progression.complete_run()` allocates coins, stage bonus, best-score and unlock; `SaveSystem` writes progress; UI shows victory/retry.

## Ownership boundaries

- `GameData`: reads and validates configuration.
- `RunRules`: deterministic combat and upgrade calculations.
- `Progression`: purchases, unlocks, level rewards.
- `SaveSystem`: version migration and backup rotation.
- `OrbArena`: run, spawn/wave lifecycle, projectiles, ball destruction and coin collection.
- `OrbBall`: movement physics, HP, and rendering.
- `PlayerCannon`: movement smoothing, hitbox, recoil and cannon rendering.
- `EffectsLayer`: single centralized particle/pop-up draw loop.
- `OrbAudio`: rate-limited channel pool and background music.
- `main.gd`: navigation and user-facing information; does not implement projectile physics.

## Collision configuration

Layer 1: arena static floor and sides. Layer 2: moving `CharacterBody2D` orbs. Cannon `Area2D` monitors layer 2. Orb raycast mask is layer 2. All orbs collide with walls and floor rather than each other, avoiding unstable explosion-sized piles.

## Persistent schema

`schema=1`, `coins`, `gems`, `unlocked_level`, `equipped_weapon`, `unlocked_weapons`, `upgrades`, `best_scores`, `wins`, `losses`, `tutorial_seen`, `settings`. More fields require explicit backwards-compatible migration.

## Known technical debts

- `main.gd` programmatically builds menus rather than using reusable authored `.tscn` UI sub-scenes. Split out UI components when expanding beyond Phase 1.
- The first ten encounters are authored rather than full seed-driven procedural generation. Phase 2 should introduce a deterministic spawn budget generator.
- Collision and frame budgets require profiling on real Android devices.
- `screen/edge_to_edge` is currently disabled; monitor Android platform window-inset behavior with final target SDK.
