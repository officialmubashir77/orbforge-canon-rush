# Gameplay design, Phase 1

Move horizontally and survive sequential waves. The cannon auto-fires straight upward. Enemy balls bounce through gravity and floor/wall collision. Every collision costs one HP unless the ~1-second hit invulnerability is active. Destroying an orb can cause it to split into two child tiers. Minimum-tier orbs vanish when killed. Complete the last wave to clear a level; lose all three HP to fail, keeping legitimately collected coins.

## Three functional weapons

| Weapon | Damage | Shot rate | Pattern | Cost |
|---|---:|---:|---|---:|
| Classic Cannon | 5.0 | 3.4/s | Single straight projectile | Free |
| Rapid Blaster | 2.2 | 8.0/s | Fast straight projectile | 85 coins |
| Tri-Shot Cannon | 2.7 | 2.4/s | Three divergent trajectories (13 degrees apart) | 175 coins |

Permanent upgrades: Damage ×1.17 per purchased level (max 30); fire rate ×1.10 per level (max 20) capped at 15/s. Config and formulas are deliberately separated from visual text.

Combo score: `kill_base = 8 + tier × 12`; score multiplier rises by one every five kills (cap 5×) if the 2.5-second combo remains active. Each kill drops a collectable coin worth `3 + tier × 3`; non-collected coins are auto-settled on run end, and the final wave adds its configured bonus. All coin rewards depend on defeated real enemies.

Level balancing is *initial design*, not validated duration data. The ten JSON entries specify distinct wave budgets, HP and speeds. Beginner onboarding uses a short unobtrusive drag-control tip that can be reset in Settings.
