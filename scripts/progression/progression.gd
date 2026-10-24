extends RefCounted
class_name Progression

static func can_play(state: Dictionary, level: int) -> bool:
    return level >= 1 and level <= 10 and level <= int(state.get("unlocked_level", 1))

static func buy_weapon(state: Dictionary, weapon: Dictionary) -> bool:
    var id: String = str(weapon.get("id", ""))
    var cost: int = int(weapon.get("cost", 0))
    var unlocked: Dictionary = state.get("unlocked_weapons", {}) as Dictionary
    if unlocked.get(id, false) or id.is_empty() or int(state.get("coins", 0)) < cost:
        return false
    state["coins"] = int(state.get("coins", 0)) - cost
    unlocked[id] = true
    state["unlocked_weapons"] = unlocked
    return true

static func equip_weapon(state: Dictionary, id: String) -> bool:
    var unlocked: Dictionary = state.get("unlocked_weapons", {}) as Dictionary
    if not bool(unlocked.get(id, false)) or GameData.weapon_by_id(id).is_empty():
        return false
    state["equipped_weapon"] = id
    return true

static func purchase_upgrade(state: Dictionary, key: String) -> bool:
    if key != "damage" and key != "rate":
        return false
    var levels: Dictionary = state.get("upgrades", {}) as Dictionary
    var current: int = int(levels.get(key, 0))
    var limit: int = 30 if key == "damage" else 20
    if current >= limit:
        return false
    var price: int = RunRules.upgrade_cost(key, current)
    if int(state.get("coins", 0)) < price:
        return false
    state["coins"] = int(state.get("coins", 0)) - price
    levels[key] = current + 1
    state["upgrades"] = levels
    return true

static func complete_run(state: Dictionary, level: int, collected_coins: int, score: int, victory: bool) -> int:
    var bonus: int = 0
    if victory:
        bonus = int(GameData.level_by_number(level).get("bonus", 0))
        state["unlocked_level"] = maxi(int(state.get("unlocked_level", 1)), mini(11, level + 1))
        var completed: Dictionary = state.get("best_scores", {}) as Dictionary
        var key: String = str(level)
        completed[key] = maxi(int(completed.get(key, 0)), score)
        state["best_scores"] = completed
        state["wins"] = int(state.get("wins", 0)) + 1
    else:
        state["losses"] = int(state.get("losses", 0)) + 1
    state["coins"] = int(state.get("coins", 0)) + collected_coins + bonus
    return bonus
