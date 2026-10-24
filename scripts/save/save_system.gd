extends RefCounted
class_name SaveSystem

const PATH: String = "user://orbforge_save_v1.json"
const BACKUP: String = "user://orbforge_save_v1.backup.json"
const TEMP: String = "user://orbforge_save_v1.tmp"
const SCHEMA: int = 1

static func defaults() -> Dictionary:
    return {
        "schema": SCHEMA,
        "coins": 0,
        "gems": 0,
        "unlocked_level": 1,
        "equipped_weapon": "classic",
        "unlocked_weapons": {"classic": true, "rapid": false, "spread": false},
        "upgrades": {"damage": 0, "rate": 0},
        "best_scores": {},
        "wins": 0,
        "losses": 0,
        "tutorial_seen": false,
        "settings": {"music": 0.35, "sfx": 0.65, "sensitivity": 1.0, "shake": true, "effects": true}
    }

static func migrate(raw: Dictionary) -> Dictionary:
    var state: Dictionary = defaults()
    if raw.is_empty():
        return state
    for key in ["coins", "gems", "unlocked_level", "wins", "losses"]:
        state[key] = maxi(0, int(raw.get(key, state[key])))
    state["unlocked_level"] = clampi(int(state["unlocked_level"]), 1, 11)
    var unlocked: Dictionary = state["unlocked_weapons"]
    var prev_unlocked: Dictionary = {}
    if raw.get("unlocked_weapons", null) is Dictionary:
        prev_unlocked = raw["unlocked_weapons"] as Dictionary
    for id in unlocked.keys():
        unlocked[id] = bool(prev_unlocked.get(id, unlocked[id]))
    unlocked["classic"] = true
    state["unlocked_weapons"] = unlocked
    var equipped: String = str(raw.get("equipped_weapon", "classic"))
    state["equipped_weapon"] = equipped if bool(unlocked.get(equipped, false)) else "classic"
    var old_upgrades: Dictionary = {}
    if raw.get("upgrades", null) is Dictionary:
        old_upgrades = raw["upgrades"] as Dictionary
    state["upgrades"] = {"damage": clampi(int(old_upgrades.get("damage", 0)), 0, 30), "rate": clampi(int(old_upgrades.get("rate", 0)), 0, 20)}
    var old_scores: Dictionary = {}
    if raw.get("best_scores", null) is Dictionary:
        old_scores = raw["best_scores"] as Dictionary
    var scores: Dictionary = {}
    for key in old_scores.keys():
        if str(key).is_valid_int() and int(key) >= 1 and int(key) <= 10:
            scores[str(key)] = maxi(0, int(old_scores[key]))
    state["best_scores"] = scores
    state["tutorial_seen"] = bool(raw.get("tutorial_seen", false))
    var old_settings: Dictionary = {}
    if raw.get("settings", null) is Dictionary:
        old_settings = raw["settings"] as Dictionary
    var settings: Dictionary = state["settings"]
    settings["music"] = clampf(float(old_settings.get("music", 0.35)), 0.0, 1.0)
    settings["sfx"] = clampf(float(old_settings.get("sfx", 0.65)), 0.0, 1.0)
    settings["sensitivity"] = clampf(float(old_settings.get("sensitivity", 1.0)), 0.6, 1.8)
    settings["shake"] = bool(old_settings.get("shake", true))
    settings["effects"] = bool(old_settings.get("effects", true))
    state["settings"] = settings
    return state

static func read_one(path: String) -> Dictionary:
    if not FileAccess.file_exists(path):
        return {}
    var value: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
    if not value is Dictionary:
        return {}
    var data: Dictionary = value as Dictionary
    if int(data.get("schema", -1)) < 0 or int(data.get("schema", -1)) > SCHEMA:
        return {}
    return data

static func load_game() -> Dictionary:
    var current: Dictionary = read_one(PATH)
    if not current.is_empty():
        return migrate(current)
    var recovery: Dictionary = read_one(BACKUP)
    if not recovery.is_empty():
        push_warning("Recovered OrbForge progress from backup save")
        return migrate(recovery)
    return defaults()

static func save_game(state: Dictionary) -> bool:
    var safe: Dictionary = migrate(state)
    var handle: FileAccess = FileAccess.open(TEMP, FileAccess.WRITE)
    if handle == null:
        push_error("Failed to create temporary save")
        return false
    handle.store_string(JSON.stringify(safe, "  "))
    handle.flush()
    handle.close()
    var temp_abs: String = ProjectSettings.globalize_path(TEMP)
    var primary_abs: String = ProjectSettings.globalize_path(PATH)
    var backup_abs: String = ProjectSettings.globalize_path(BACKUP)
    if FileAccess.file_exists(PATH):
        if FileAccess.file_exists(BACKUP):
            DirAccess.remove_absolute(backup_abs)
        if DirAccess.rename_absolute(primary_abs, backup_abs) != OK:
            push_error("Failed to rotate old save")
            return false
    if DirAccess.rename_absolute(temp_abs, primary_abs) != OK:
        push_error("Failed to commit save")
        if FileAccess.file_exists(BACKUP):
            DirAccess.rename_absolute(backup_abs, primary_abs)
        return false
    return true
