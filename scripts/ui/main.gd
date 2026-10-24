extends Control
class_name OrbMain

const CYAN: Color = Color("#56e6ec")
const GOLD: Color = Color("#ffd178")
const LIGHT: Color = Color("#eef8ff")
const MUTED: Color = Color("#a9bfda")
const NAVY: Color = Color("#122449")

var player_data: Dictionary = {}
var screen: String = "menu"
var selected_level: int = 1
var holder: Control
var world: WorldPainter
var audio: OrbAudio
var arena: OrbArena
var pause_overlay: Control
var hud_refs: Dictionary = {}
var last_run_won: bool = false
var last_run_score: int = 0
var last_run_coins: int = 0
var last_run_bonus: int = 0

func _ready() -> void:
    player_data = SaveSystem.load_game()
    audio = OrbAudio.new()
    add_child(audio)
    _apply_audio_settings()
    holder = Control.new()
    holder.name = "ScreenRoot"
    holder.set_anchors_preset(Control.PRESET_FULL_RECT)
    holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(holder)
    _show_menu()

func _exit_tree() -> void:
    if not player_data.is_empty():
        SaveSystem.save_game(player_data)

func _notification(what: int) -> void:
    if what == NOTIFICATION_APPLICATION_PAUSED or what == NOTIFICATION_WM_CLOSE_REQUEST:
        if not player_data.is_empty():
            SaveSystem.save_game(player_data)

func _size() -> Vector2:
    return get_viewport_rect().size

func _clear() -> void:
    if holder == null:
        return
    for child in holder.get_children():
        holder.remove_child(child)
        child.queue_free()
    arena = null
    pause_overlay = null
    hud_refs.clear()
    var background: WorldPainter = WorldPainter.new()
    background.screen_size = _size()
    holder.add_child(background)
    world = background

func _ui_label(parent: Node, text: String, pos: Vector2, dimensions: Vector2, font_size: int = 22, color: Color = LIGHT, alignment: HorizontalAlignment = HORIZONTAL_ALIGNMENT_CENTER) -> Label:
    var item: Label = Label.new()
    item.text = text
    item.position = pos
    item.size = dimensions
    item.horizontal_alignment = alignment
    item.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    item.add_theme_color_override("font_color", color)
    item.add_theme_font_size_override("font_size", font_size)
    item.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    item.mouse_filter = Control.MOUSE_FILTER_IGNORE
    parent.add_child(item)
    return item

func _panel(parent: Node, pos: Vector2, dimensions: Vector2, fill: Color = NAVY, border: Color = Color("#2b4a75"), curve: int = 28) -> Panel:
    var panel: Panel = Panel.new()
    panel.position = pos
    panel.size = dimensions
    var style: StyleBoxFlat = StyleBoxFlat.new()
    style.bg_color = fill
    style.set_corner_radius_all(curve)
    style.border_color = border
    style.set_border_width_all(2)
    style.shadow_color = Color(0, 0, 0, 0.18)
    style.shadow_size = 8
    panel.add_theme_stylebox_override("panel", style)
    parent.add_child(panel)
    return panel

func _button(parent: Node, text: String, pos: Vector2, dimensions: Vector2, action: Callable, tint: Color = CYAN, dark_text: bool = true, font_size: int = 24) -> Button:
    var button: Button = Button.new()
    button.text = text
    button.position = pos
    button.size = dimensions
    button.focus_mode = Control.FOCUS_NONE
    button.add_theme_font_size_override("font_size", font_size)
    button.add_theme_color_override("font_color", Color("#112343") if dark_text else LIGHT)
    button.add_theme_color_override("font_hover_color", Color("#112343") if dark_text else LIGHT)
    button.add_theme_color_override("font_pressed_color", Color("#112343") if dark_text else LIGHT)
    var standard: StyleBoxFlat = StyleBoxFlat.new()
    standard.bg_color = tint
    standard.set_corner_radius_all(18)
    standard.shadow_color = Color(tint.r, tint.g, tint.b, 0.23)
    standard.shadow_size = 5
    var hover: StyleBoxFlat = standard.duplicate() as StyleBoxFlat
    hover.bg_color = tint.lightened(0.14)
    var pressed: StyleBoxFlat = standard.duplicate() as StyleBoxFlat
    pressed.bg_color = tint.darkened(0.12)
    button.add_theme_stylebox_override("normal", standard)
    button.add_theme_stylebox_override("hover", hover)
    button.add_theme_stylebox_override("pressed", pressed)
    button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
    button.pressed.connect(_button_pressed.bind(action))
    parent.add_child(button)
    return button

func _button_pressed(action: Callable) -> void:
    if audio != null:
        audio.play_sfx("button")
    if action.is_valid():
        action.call()

func _topbar(parent: Node, heading: String, back_to: String = "menu") -> void:
    var width: float = _size().x
    _button(parent, "<", Vector2(28, 40), Vector2(65, 64), Callable(self, "_back_to").bind(back_to), Color("#263e63"), false, 30)
    _ui_label(parent, heading, Vector2(102, 42), Vector2(width - 206, 60), 34, LIGHT)
    _ui_label(parent, "COINS  " + str(player_data.get("coins", 0)), Vector2(width - 180, 111), Vector2(150, 34), 18, GOLD, HORIZONTAL_ALIGNMENT_RIGHT)

func _back_to(destination: String) -> void:
    match destination:
        "levels": _show_levels()
        "garage": _show_garage()
        "settings": _show_settings()
        _: _show_menu()

func _show_menu() -> void:
    screen = "menu"
    _clear()
    var w: float = _size().x
    var h: float = _size().y
    _ui_label(holder, "ORBFORGE", Vector2(26, h * 0.15), Vector2(w - 52, 84), 66, LIGHT)
    _ui_label(holder, "C A N N O N   R U S H", Vector2(28, h * 0.15 + 83), Vector2(w - 56, 34), 20, CYAN)
    var hero: OrbHeroMark = OrbHeroMark.new()
    hero.position = Vector2(w * 0.5, h * 0.32)
    holder.add_child(hero)
    _ui_label(holder, "BLAST. SPLIT. UPGRADE.", Vector2(45, h * 0.39), Vector2(w - 90, 44), 23, MUTED)
    var panel: Panel = _panel(holder, Vector2(37, h * 0.45), Vector2(w - 74, 116), Color("#11294e"), Color("#2a5f86"))
    _ui_label(panel, "GREEN VALLEY  /  CHAPTER 01", Vector2(17, 13), Vector2(panel.size.x - 34, 36), 17, CYAN)
    _ui_label(panel, "LEVEL " + str(mini(10, int(player_data.get("unlocked_level", 1)))), Vector2(15, 48), Vector2(panel.size.x - 30, 52), 36, LIGHT)
    var btn_w: float = minf(500, w - 78)
    var btn_x: float = (w - btn_w) * 0.5
    _button(holder, "PLAY NOW", Vector2(btn_x, h * 0.57), Vector2(btn_w, 86), Callable(self, "_play_current"), CYAN, true, 32)
    _button(holder, "LEVEL SELECT", Vector2(btn_x, h * 0.57 + 109), Vector2(btn_w, 67), Callable(self, "_show_levels"), Color("#263f68"), false, 23)
    _button(holder, "CANNON GARAGE", Vector2(btn_x, h * 0.57 + 193), Vector2(btn_w, 67), Callable(self, "_show_garage"), Color("#263f68"), false, 23)
    _button(holder, "SETTINGS", Vector2(btn_x, h * 0.57 + 277), Vector2(btn_w, 64), Callable(self, "_show_settings"), Color("#203555"), false, 21)
    _ui_label(holder, "OFFLINE ARCADE  |  PHASE 1  |  VERSION 0.1", Vector2(15, h - 69), Vector2(w - 30, 35), 15, MUTED)
    _ui_label(holder, "TOTAL WINS  " + str(player_data.get("wins", 0)) + "     COINS  " + str(player_data.get("coins", 0)), Vector2(30, 21), Vector2(w - 60, 38), 16, GOLD)

func _play_current() -> void:
    var target: int = mini(10, int(player_data.get("unlocked_level", 1)))
    _start_game(target)

func _show_levels() -> void:
    screen = "levels"
    _clear()
    var w: float = _size().x
    var h: float = _size().y
    _topbar(holder, "SELECT LEVEL")
    _ui_label(holder, "10 unique wave encounters", Vector2(22, 180), Vector2(w - 44, 42), 21, MUTED)
    var gap: float = 18.0
    var cell_w: float = (w - 94 - gap) * 0.5
    var start_y: float = 256.0
    var cell_h: float = minf(122.0, (h - 348.0) / 5.0 - 12.0)
    for level in range(1, 11):
        var col: int = (level - 1) % 2
        var row: int = (level - 1) / 2
        var x: float = 47.0 + float(col) * (cell_w + gap)
        var y: float = start_y + float(row) * (cell_h + 14.0)
        var allowed: bool = Progression.can_play(player_data, level)
        var button: Button = _button(holder, "LEVEL " + str(level) + ("  |  LOCKED" if not allowed else ""), Vector2(x, y), Vector2(cell_w, cell_h), Callable(self, "_start_game").bind(level), Color("#22567b") if allowed else Color("#233149"), not allowed, 21)
        button.disabled = not allowed
        if not allowed:
            button.add_theme_color_override("font_disabled_color", Color("#8494af"))
    _ui_label(holder, "Clear a level to unlock the next.", Vector2(30, h - 84), Vector2(w - 60, 35), 18, MUTED)

func _show_garage() -> void:
    screen = "garage"
    _clear()
    var w: float = _size().x
    var h: float = _size().y
    _topbar(holder, "CANNON GARAGE")
    _ui_label(holder, "Choose your combat style", Vector2(34, 174), Vector2(w - 68, 48), 21, MUTED)
    var weapons: Array = GameData.weapons()
    var card_height: float = minf(150.0, (h - 570.0) / 3.0)
    for index in range(weapons.size()):
        var item: Dictionary = weapons[index]
        var id: String = str(item.get("id", ""))
        var price: int = int(item.get("cost", 0))
        var unlocked: bool = bool((player_data["unlocked_weapons"] as Dictionary).get(id, false))
        var equipped: bool = str(player_data.get("equipped_weapon", "classic")) == id
        var c: Color = Color(str(item.get("color", "#ffffff")))
        var y: float = 233.0 + index * (card_height + 15.0)
        var card: Panel = _panel(holder, Vector2(31, y), Vector2(w - 62, card_height), Color("#142b52"), c.darkened(0.42), 20)
        _ui_label(card, str(item["name"]), Vector2(22, 7), Vector2(card.size.x - 45, 37), 24, c, HORIZONTAL_ALIGNMENT_LEFT)
        _ui_label(card, str(item["subtitle"]), Vector2(23, 47), Vector2(card.size.x - 46, 27), 17, MUTED, HORIZONTAL_ALIGNMENT_LEFT)
        _ui_label(card, "DMG " + str(item["damage"]) + "    RATE " + str(item["fire_rate"]) + "/s", Vector2(23, 78), Vector2(card.size.x - 45, 29), 17, LIGHT, HORIZONTAL_ALIGNMENT_LEFT)
        var button_text: String = ""
        if equipped:
            button_text = "EQUIPPED"
        elif unlocked:
            button_text = "EQUIP"
        else:
            button_text = "UNLOCK " + str(price)
        var button: Button = _button(card, button_text, Vector2(card.size.x - 205, card.size.y - 47), Vector2(181, 41), Callable(self, "_garage_select").bind(id), c, true, 17)
        button.disabled = equipped
    var upgrade_top: float = 233.0 + 3.0 * (card_height + 15.0) + 12.0
    _ui_label(holder, "PERMANENT UPGRADES", Vector2(26, upgrade_top), Vector2(w - 52, 45), 25, LIGHT)
    var owned: Dictionary = player_data["upgrades"] as Dictionary
    for i in range(2):
        var key: String = "damage" if i == 0 else "rate"
        var level: int = int(owned.get(key, 0))
        var cap: int = 30 if key == "damage" else 20
        var cost: int = RunRules.upgrade_cost(key, level)
        var row_y: float = upgrade_top + 57.0 + i * 88.0
        _panel(holder, Vector2(31, row_y), Vector2(w - 62, 77), Color("#152d51"), Color("#29466e"), 16)
        _ui_label(holder, ("POWER" if i == 0 else "FIRE RATE") + "  LV " + str(level), Vector2(49, row_y + 6), Vector2(w - 270, 32), 22, LIGHT, HORIZONTAL_ALIGNMENT_LEFT)
        _ui_label(holder, "+17% per level" if i == 0 else "+10% per level", Vector2(49, row_y + 38), Vector2(w - 270, 26), 16, MUTED, HORIZONTAL_ALIGNMENT_LEFT)
        var upgrade_button: Button = _button(holder, "MAX" if level >= cap else "UP  " + str(cost), Vector2(w - 220, row_y + 14), Vector2(166, 49), Callable(self, "_purchase_upgrade").bind(key), GOLD, true, 18)
        upgrade_button.disabled = level >= cap
    _ui_label(holder, "All upgrades affect actual projectile combat.", Vector2(28, h - 64), Vector2(w - 56, 34), 16, MUTED)

func _garage_select(weapon_id: String) -> void:
    var data: Dictionary = GameData.weapon_by_id(weapon_id)
    if data.is_empty():
        return
    var unlocked: Dictionary = player_data["unlocked_weapons"] as Dictionary
    if not bool(unlocked.get(weapon_id, false)):
        if not Progression.buy_weapon(player_data, data):
            _toast("NEED MORE COINS")
            return
    Progression.equip_weapon(player_data, weapon_id)
    _save()
    _show_garage()

func _purchase_upgrade(key: String) -> void:
    if not Progression.purchase_upgrade(player_data, key):
        _toast("NOT ENOUGH COINS")
        return
    audio.play_sfx("upgrade")
    _save()
    _show_garage()

func _toast(message: String) -> void:
    var notice: Label = _ui_label(holder, message, Vector2(45, _size().y * 0.72), Vector2(_size().x - 90, 50), 24, GOLD)
    var tween: Tween = create_tween()
    tween.tween_interval(0.75)
    tween.tween_property(notice, "modulate:a", 0.0, 0.3)
    tween.tween_callback(notice.queue_free)

func _setting_slider(title: String, key: String, value: float, min_value: float, max_value: float, y: float) -> void:
    var w: float = _size().x
    _ui_label(holder, title, Vector2(60, y), Vector2(w - 120, 39), 22, LIGHT, HORIZONTAL_ALIGNMENT_LEFT)
    var slider: HSlider = HSlider.new()
    slider.position = Vector2(65, y + 43)
    slider.size = Vector2(w - 130, 43)
    slider.min_value = min_value
    slider.max_value = max_value
    slider.step = 0.05
    slider.value = value
    slider.value_changed.connect(_on_setting_slider.bind(key))
    holder.add_child(slider)

func _setting_toggle(title: String, key: String, value: bool, y: float) -> void:
    var w: float = _size().x
    var toggle: CheckButton = CheckButton.new()
    toggle.position = Vector2(57, y)
    toggle.size = Vector2(w - 114, 64)
    toggle.text = title
    toggle.button_pressed = value
    toggle.add_theme_font_size_override("font_size", 22)
    toggle.toggled.connect(_on_setting_toggle.bind(key))
    holder.add_child(toggle)

func _show_settings() -> void:
    screen = "settings"
    _clear()
    var w: float = _size().x
    var h: float = _size().y
    _topbar(holder, "SETTINGS")
    var settings: Dictionary = player_data["settings"] as Dictionary
    _setting_slider("Music volume", "music", float(settings.get("music", 0.35)), 0.0, 1.0, 220.0)
    _setting_slider("Sound effects", "sfx", float(settings.get("sfx", 0.65)), 0.0, 1.0, 340.0)
    _setting_slider("Touch sensitivity", "sensitivity", float(settings.get("sensitivity", 1.0)), 0.6, 1.8, 460.0)
    _setting_toggle("Impact particles", "effects", bool(settings.get("effects", true)), 594.0)
    _setting_toggle("Visual impact feedback", "shake", bool(settings.get("shake", true)), 665.0)
    _button(holder, "REPLAY TUTORIAL", Vector2(65, 789), Vector2(w - 130, 68), Callable(self, "_reset_tutorial"), Color("#294366"), false, 22)
    _button(holder, "RESET SAVE DATA", Vector2(65, 877), Vector2(w - 130, 68), Callable(self, "_confirm_reset"), Color("#6b3655"), false, 22)
    _ui_label(holder, "Progress and settings are stored offline.", Vector2(35, h - 76), Vector2(w - 70, 39), 17, MUTED)

func _on_setting_slider(value: float, key: String) -> void:
    var settings: Dictionary = player_data.get("settings", {}) as Dictionary
    settings[key] = value
    player_data["settings"] = settings
    _apply_audio_settings()
    _save()

func _on_setting_toggle(pressed: bool, key: String) -> void:
    var settings: Dictionary = player_data.get("settings", {}) as Dictionary
    settings[key] = pressed
    player_data["settings"] = settings
    _save()

func _reset_tutorial() -> void:
    player_data["tutorial_seen"] = false
    _save()
    _toast("TUTORIAL RESET")

func _confirm_reset() -> void:
    var confirm: ConfirmationDialog = ConfirmationDialog.new()
    confirm.title = "Reset progress?"
    confirm.dialog_text = "This permanently resets levels, coins, weapons, upgrades, and records on this device."
    confirm.ok_button_text = "RESET ALL"
    confirm.confirmed.connect(_perform_reset)
    confirm.canceled.connect(confirm.queue_free)
    holder.add_child(confirm)
    confirm.popup_centered(Vector2i(570, 240))

func _perform_reset() -> void:
    player_data = SaveSystem.defaults()
    _save()
    _apply_audio_settings()
    _show_settings()

func _apply_audio_settings() -> void:
    if audio == null:
        return
    var settings: Dictionary = player_data.get("settings", {}) as Dictionary
    audio.set_levels(float(settings.get("music", 0.35)), float(settings.get("sfx", 0.65)))

func _save() -> void:
    if not SaveSystem.save_game(player_data):
        push_warning("Save write failed")

func _start_game(level: int) -> void:
    if not Progression.can_play(player_data, level):
        return
    selected_level = level
    screen = "game"
    _clear()
    world.dim = true
    var weapon: Dictionary = GameData.weapon_by_id(str(player_data.get("equipped_weapon", "classic")))
    if weapon.is_empty():
        weapon = GameData.weapon_by_id("classic")
    arena = OrbArena.new()
    arena.name = "LiveArena"
    holder.add_child(arena)
    arena.hud_updated.connect(_update_hud)
    arena.wave_started.connect(_wave_started)
    arena.run_finished.connect(_run_finished)
    arena.setup(level, weapon, player_data.get("upgrades", {}) as Dictionary, player_data.get("settings", {}) as Dictionary, audio)
    _build_hud()
    _update_hud({"level":level,"wave":1,"waves":(GameData.level_by_number(level).get("waves", []) as Array).size(),"health":3,"coins":0,"score":0,"combo":0})
    if not bool(player_data.get("tutorial_seen", false)):
        _ui_label(holder, "DRAG LEFT / RIGHT TO DODGE    |    AUTO FIRE", Vector2(14, _size().y - 124), Vector2(_size().x - 28, 38), 17, CYAN)
        player_data["tutorial_seen"] = true
        _save()

func _build_hud() -> void:
    var w: float = _size().x
    var background: Panel = _panel(holder, Vector2(15, 18), Vector2(w - 30, 178), Color("#101f3d"), Color("#2a5a79"), 24)
    background.mouse_filter = Control.MOUSE_FILTER_IGNORE
    hud_refs["level"] = _ui_label(holder, "LEVEL", Vector2(35, 31), Vector2(235, 46), 26, LIGHT, HORIZONTAL_ALIGNMENT_LEFT)
    hud_refs["wave"] = _ui_label(holder, "WAVE", Vector2(35, 79), Vector2(240, 36), 19, CYAN, HORIZONTAL_ALIGNMENT_LEFT)
    hud_refs["health"] = _ui_label(holder, "HP 3 / 3", Vector2(w - 282, 33), Vector2(151, 39), 24, Color("#ff99ae"))
    hud_refs["coins"] = _ui_label(holder, "COINS 0", Vector2(32, 128), Vector2(w * 0.39, 38), 20, GOLD, HORIZONTAL_ALIGNMENT_LEFT)
    hud_refs["score"] = _ui_label(holder, "SCORE 0", Vector2(w * 0.37, 128), Vector2(w * 0.39, 38), 20, LIGHT)
    hud_refs["combo"] = _ui_label(holder, "", Vector2(w * 0.38, 201), Vector2(w * 0.24, 40), 20, GOLD)
    _button(holder, "II", Vector2(w - 110, 37), Vector2(70, 62), Callable(self, "_pause_game"), Color("#315479"), false, 24)
    _ui_label(holder, "MOVE TO AVOID THE ORBS", Vector2(25, _size().y - 107), Vector2(w - 50, 40), 17, Color("#c0f9eb"))

func _update_hud(info: Dictionary) -> void:
    if hud_refs.is_empty():
        return
    (hud_refs["level"] as Label).text = "LEVEL " + str(info.get("level", 1))
    (hud_refs["wave"] as Label).text = "WAVE " + str(info.get("wave", 1)) + " / " + str(info.get("waves", 1))
    (hud_refs["health"] as Label).text = "HP  " + str(info.get("health", 3)) + " / 3"
    (hud_refs["coins"] as Label).text = "COINS  " + str(info.get("coins", 0))
    (hud_refs["score"] as Label).text = "SCORE  " + str(info.get("score", 0))
    (hud_refs["combo"] as Label).text = "x" + str(info.get("combo", 0)) + " COMBO" if int(info.get("combo", 0)) >= 3 else ""

func _wave_started(_number: int, _total: int) -> void:
    pass

func _pause_game() -> void:
    if screen != "game" or arena == null:
        return
    screen = "pause"
    arena.process_mode = Node.PROCESS_MODE_DISABLED
    pause_overlay = _overlay("PAUSED", "Take a break. Your run is safe.")
    var w: float = _size().x
    var h: float = _size().y
    _button(pause_overlay, "RESUME", Vector2(w * 0.16, h * 0.53), Vector2(w * 0.68, 70), Callable(self, "_resume_game"), CYAN)
    _button(pause_overlay, "RESTART", Vector2(w * 0.16, h * 0.53 + 92), Vector2(w * 0.68, 66), Callable(self, "_restart"), Color("#315479"), false)
    _button(pause_overlay, "MAIN MENU", Vector2(w * 0.16, h * 0.53 + 180), Vector2(w * 0.68, 66), Callable(self, "_show_menu"), Color("#315479"), false)

func _resume_game() -> void:
    if pause_overlay != null:
        pause_overlay.queue_free()
        pause_overlay = null
    if arena != null:
        arena.process_mode = Node.PROCESS_MODE_INHERIT
    screen = "game"

func _restart() -> void:
    _start_game(selected_level)

func _overlay(heading: String, detail: String) -> Control:
    var w: float = _size().x
    var h: float = _size().y
    var layer: Control = Control.new()
    layer.set_anchors_preset(Control.PRESET_FULL_RECT)
    layer.size = _size()
    holder.add_child(layer)
    var dark: ColorRect = ColorRect.new()
    dark.color = Color(0.005, 0.014, 0.055, 0.81)
    dark.set_anchors_preset(Control.PRESET_FULL_RECT)
    layer.add_child(dark)
    _panel(layer, Vector2(w * 0.08, h * 0.30), Vector2(w * 0.84, h * 0.51), Color("#152a4b"), Color("#3c7792"), 30)
    _ui_label(layer, heading, Vector2(w * 0.10, h * 0.34), Vector2(w * 0.80, 87), 46, LIGHT)
    _ui_label(layer, detail, Vector2(w * 0.14, h * 0.41), Vector2(w * 0.72, 88), 20, MUTED)
    return layer

func _run_finished(won: bool, earned: int, score: int) -> void:
    if screen != "game" or arena == null:
        return
    last_run_won = won
    last_run_score = score
    last_run_coins = earned
    last_run_bonus = Progression.complete_run(player_data, selected_level, earned, score, won)
    _save()
    call_deferred("_show_result")

func _show_result() -> void:
    if arena == null:
        return
    screen = "result"
    arena.process_mode = Node.PROCESS_MODE_DISABLED
    var heading: String = "LEVEL CLEARED" if last_run_won else "RUN OVER"
    var detail: String = "+" + str(last_run_coins + last_run_bonus) + " COINS  |  " + str(last_run_score) + " PTS"
    var layer: Control = _overlay(heading, detail)
    var w: float = _size().x
    var h: float = _size().y
    _button(layer, "NEXT LEVEL" if last_run_won and selected_level < 10 else "RETRY LEVEL", Vector2(w * 0.16, h * 0.53), Vector2(w * 0.68, 69), Callable(self, "_next_or_retry"), CYAN)
    _button(layer, "CANNON GARAGE", Vector2(w * 0.16, h * 0.53 + 92), Vector2(w * 0.68, 66), Callable(self, "_show_garage"), Color("#315479"), false)
    _button(layer, "MAIN MENU", Vector2(w * 0.16, h * 0.53 + 180), Vector2(w * 0.68, 66), Callable(self, "_show_menu"), Color("#315479"), false)

func _next_or_retry() -> void:
    if last_run_won and selected_level < 10:
        _start_game(selected_level + 1)
    else:
        _start_game(selected_level)

func _unhandled_key_input(event: InputEvent) -> void:
    if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
        if screen == "game":
            _pause_game()
        elif screen == "pause":
            _resume_game()
        elif screen != "menu":
            _show_menu()
        get_viewport().set_input_as_handled()
