extends RefCounted
class_name GameData

const WEAPONS_FILE: String = "res://data/weapons/weapons.json"
const LEVELS_FILE: String = "res://data/levels/phase1.json"

static func read_json(path: String) -> Dictionary:
    if not FileAccess.file_exists(path):
        push_error("Missing content file: " + path)
        return {}
    var text: String = FileAccess.get_file_as_string(path)
    var value: Variant = JSON.parse_string(text)
    if not value is Dictionary:
        push_error("Invalid JSON content: " + path)
        return {}
    return value as Dictionary

static func weapons() -> Array:
    return read_json(WEAPONS_FILE).get("weapons", []) as Array

static func levels() -> Array:
    return read_json(LEVELS_FILE).get("levels", []) as Array

static func weapon_by_id(id: String) -> Dictionary:
    for item in weapons():
        if str(item.get("id", "")) == id:
            return item as Dictionary
    return {}

static func level_by_number(number: int) -> Dictionary:
    for item in levels():
        if int(item.get("id", 0)) == number:
            return item as Dictionary
    return {}

static func validate_content() -> Array[String]:
    var errors: Array[String] = []
    var seen: Dictionary = {}
    var all_weapons: Array = weapons()
    var all_levels: Array = levels()
    if all_weapons.size() < 3:
        errors.append("Expected at least three usable weapons")
    for weapon in all_weapons:
        var id: String = str(weapon.get("id", ""))
        if id.is_empty() or seen.has(id):
            errors.append("Invalid or duplicate weapon ID: " + id)
        seen[id] = true
        if float(weapon.get("damage", 0)) <= 0 or float(weapon.get("fire_rate", 0)) <= 0 or int(weapon.get("streams", 0)) <= 0:
            errors.append("Non-positive weapon stats: " + id)
    if all_levels.size() != 10:
        errors.append("Phase 1 must contain ten levels")
    for index in range(all_levels.size()):
        var level: Dictionary = all_levels[index]
        if int(level.get("id", 0)) != index + 1:
            errors.append("Level numbering mismatch")
        var waves: Array = level.get("waves", []) as Array
        if waves.is_empty():
            errors.append("No waves in level " + str(index + 1))
        for wave in waves:
            if int(wave.get("count", 0)) < 1 or int(wave.get("tier", 0)) < 1 or float(wave.get("hp", 0)) <= 0:
                errors.append("Invalid wave at level " + str(index + 1))
    return errors
