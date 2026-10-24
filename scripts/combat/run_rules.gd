extends RefCounted
class_name RunRules

static func clamp_cannon_x(value: float, arena_width: float) -> float:
    return clampf(value, 66.0, maxf(66.0, arena_width - 66.0))

static func damage_after_armor(damage: float, armor: float) -> float:
    return maxf(0.25, damage * (1.0 - clampf(armor, 0.0, 0.8)))

static func child_tier(parent_tier: int) -> int:
    return maxi(0, parent_tier - 1)

static func child_health(parent_max_health: float, parent_tier: int) -> float:
    if parent_tier <= 1:
        return 0.0
    return maxf(3.0, ceilf(parent_max_health * 0.58))

static func weapon_stats(base: Dictionary, upgrades: Dictionary) -> Dictionary:
    var damage_level: int = clampi(int(upgrades.get("damage", 0)), 0, 30)
    var rate_level: int = clampi(int(upgrades.get("rate", 0)), 0, 20)
    return {
        "damage": float(base.get("damage", 5.0)) * pow(1.17, damage_level),
        "fire_rate": minf(15.0, float(base.get("fire_rate", 3.0)) * pow(1.10, rate_level)),
        "projectile_speed": float(base.get("projectile_speed", 1100.0)),
        "projectile_radius": float(base.get("projectile_radius", 8.0)),
        "streams": int(base.get("streams", 1)),
        "spread_degrees": float(base.get("spread_degrees", 0.0)),
        "color": Color(str(base.get("color", "#ffffff")))
    }

static func upgrade_cost(category: String, level: int) -> int:
    var initial: int = 55 if category == "damage" else 75
    return int(ceil(float(initial) * pow(1.36, maxi(0, level))))

static func score_for_kill(tier: int, combo: int) -> int:
    return (8 + tier * 12) * mini(5, 1 + int(combo / 5.0))

static func ball_reward(tier: int) -> int:
    return 3 + tier * 3
