extends SceneTree

var passed: int = 0
var failed: int = 0

func _initialize() -> void:
    call_deferred("_run")

func _check(condition: bool, description: String) -> void:
    if condition:
        passed += 1
        print("PASS  ", description)
    else:
        failed += 1
        push_error("FAIL  " + description)

func _run() -> void:
    _check(GameData.validate_content().is_empty(), "Content integrity and 10 configured levels")
    _check(GameData.weapons().size() == 3, "Three data-driven weapon choices")
    _check(GameData.level_by_number(10).get("name", "") == "Valley Champion", "Level 10 configuration loads")
    _check(RunRules.clamp_cannon_x(-100.0, 720.0) == 66.0, "Left cannon boundary")
    _check(RunRules.clamp_cannon_x(990.0, 720.0) == 654.0, "Right cannon boundary")
    _check(RunRules.child_tier(3) == 2, "Splitting lowers ball tier")
    _check(RunRules.child_tier(1) == 0, "Minimum ball tier has no child")
    _check(RunRules.child_health(20.0, 3) < 20.0, "Children have lower health")
    _check(RunRules.damage_after_armor(10.0, 0.4) < 10.0, "Armor calculation affects damage")
    var normal: Dictionary = RunRules.weapon_stats(GameData.weapon_by_id("classic"), {"damage":0,"rate":0})
    var boosted: Dictionary = RunRules.weapon_stats(GameData.weapon_by_id("classic"), {"damage":2,"rate":2})
    _check(float(boosted["damage"]) > float(normal["damage"]), "Damage upgrade changes actual weapon stats")
    _check(float(boosted["fire_rate"]) > float(normal["fire_rate"]), "Rate upgrade changes real firing speed")
    var spread: Dictionary = RunRules.weapon_stats(GameData.weapon_by_id("spread"), {"damage":0,"rate":0})
    _check(int(spread["streams"]) == 3, "Tri-shot fires three separate trajectories")
    var state: Dictionary = SaveSystem.defaults()
    _check(Progression.can_play(state,1) and not Progression.can_play(state,2), "Campaign unlock gates")
    state["coins"] = 1500
    _check(Progression.buy_weapon(state,GameData.weapon_by_id("rapid")), "Weapon purchase spends currency")
    _check(not Progression.buy_weapon(state,GameData.weapon_by_id("rapid")), "Cannot repurchase unlocked weapon")
    _check(Progression.equip_weapon(state,"rapid") and state["equipped_weapon"] == "rapid", "Equip unlocked cannon")
    _check(Progression.purchase_upgrade(state,"damage"), "Permanent upgrade purchased")
    _check(int((state["upgrades"] as Dictionary)["damage"]) == 1, "Upgrade level persists in state")
    var bonus: int = Progression.complete_run(state,1,18,135,true)
    _check(bonus == 30 and int(state["unlocked_level"]) == 2, "Victory rewards and unlocks")
    _check(int((state["best_scores"] as Dictionary)["1"]) == 135, "Best score tracked")
    _check(SaveSystem.migrate({"schema":1,"coins":-123,"unlocked_level":999})["coins"] == 0, "Save validation clamps corrupt values")
    _check(SaveSystem.migrate({"schema":1,"unlocked_level":999})["unlocked_level"] == 11, "Save migration clamps campaign bounds")
    _check(is_equal_approx(float((SaveSystem.migrate({"schema":1,"settings":"bad","unlocked_weapons":123})["settings"] as Dictionary).get("music", -1)), 0.35), "Invalid nested save data safely recovers defaults")
    _check(SaveSystem.save_game(state), "Atomic save file commit")
    var loaded: Dictionary = SaveSystem.load_game()
    _check(int(loaded.get("coins",0)) == int(state.get("coins",0)), "Save file reloaded without coin loss")
    _check(str(loaded.get("equipped_weapon", "")) == "rapid", "Unlocked weapon restored from disk")
    var ball: OrbBall = OrbBall.new()
    root.add_child(ball)
    ball.configure(901, 2, 10.0, Vector2(350,340), Vector2(110,-250))
    _check(ball.radius == 46.0 and ball.health == 10.0, "Instantiated numbered physics ball has true collider and health")
    _check(not ball.receive_damage(4.0) and ball.health == 6.0, "Projectile damage reduces actual ball health")
    _check(ball.receive_damage(7.0) and ball.health == 0.0, "Final hit kills ball")
    var y_before: float = ball.position.y
    await physics_frame
    await physics_frame
    await physics_frame
    _check(ball.position.y != y_before, "Ball moves using physics ticks")
    ball.queue_free()
    var floor: StaticBody2D = StaticBody2D.new()
    floor.collision_layer = 1
    floor.collision_mask = 0
    floor.position = Vector2(350, 610)
    var shape: CollisionShape2D = CollisionShape2D.new()
    var floor_rect: RectangleShape2D = RectangleShape2D.new()
    floor_rect.size = Vector2(650, 32)
    shape.shape = floor_rect
    floor.add_child(shape)
    root.add_child(floor)
    var bouncing: OrbBall = OrbBall.new()
    root.add_child(bouncing)
    bouncing.configure(902, 1, 6.0, Vector2(350, 520), Vector2(0, 510))
    for _step in range(13):
        await physics_frame
    _check(bouncing.velocity.y < 0.0, "Physical ground collision produces upward bounce")
    bouncing.queue_free()
    floor.queue_free()
    var garage: OrbArena = OrbArena.new()
    root.add_child(garage)
    garage.setup(1, GameData.weapon_by_id("classic"), {"damage":0,"rate":0}, SaveSystem.defaults()["settings"], null)
    garage._shoot()
    var active: int = 0
    for projectile in garage.bullets:
        if projectile.active:
            active += 1
    _check(active >= 1, "Live cannon spawns real projectile")
    var parent_ball: OrbBall = OrbBall.new()
    garage.add_child(parent_ball)
    parent_ball.configure(1001,2,4.0,Vector2(300,400),Vector2(90,-200))
    garage.balls.append(parent_ball)
    garage._damage_ball(parent_ball, 6.0)
    _check(garage.balls.size() == 2, "Defeated tier-two ball spawns exactly two physics children")
    var one: OrbBall = garage.balls[0]
    var two: OrbBall = garage.balls[1]
    _check(one.velocity.x < 0 and two.velocity.x > 0, "Split children travel in different directions")
    garage._damage_ball(one,100.0)
    _check(garage.balls.size() == 1, "Minimum-tier ball dies without further splitting")
    garage._drop_coin(garage.cannon.position,8)
    garage._process(0.016)
    _check(garage.run_coins >= 8, "Coins are physically collectible near cannon")
    var before_health: int = garage.lives
    garage._on_player_touched(two)
    garage._on_player_touched(two)
    _check(garage.lives == before_health - 1, "Player damage applies with temporary invulnerability")
    garage._end_run(true)
    _check(garage.ended, "Victory finalizes run")
    garage.queue_free()
    var scene: PackedScene = load("res://scenes/main/main.tscn") as PackedScene
    _check(scene != null, "Main playable Godot scene loads")
    if scene != null:
        var menu: OrbMain = scene.instantiate() as OrbMain
        root.add_child(menu)
        _check(menu.screen == "menu", "Main menu initializes with functional UI")
        menu._show_garage()
        _check(menu.screen == "garage", "Garage screen navigation works")
        menu._show_settings()
        _check(menu.screen == "settings", "Settings screen navigation works")
        menu._show_levels()
        _check(menu.screen == "levels", "Level selection navigation works")
        menu._start_game(1)
        _check(menu.screen == "game" and menu.arena != null, "Play button route starts actual arena")
        var running: OrbArena = menu.arena
        _check(running != null and running.lives == 3, "Playable arena starts with three HP")
        var touch: InputEventScreenTouch = InputEventScreenTouch.new()
        touch.index = 0
        touch.position = Vector2(83, 700)
        touch.pressed = true
        running._unhandled_input(touch)
        _check(running.cannon.target_x < 360, "Touch mapping adjusts cannon target")
        menu._pause_game()
        _check(menu.screen == "pause" and running.process_mode == Node.PROCESS_MODE_DISABLED, "Pause suspends arena simulation")
        menu._resume_game()
        _check(menu.screen == "game", "Resume re-enables gameplay")
        running._end_run(true)
        await process_frame
        await process_frame
        _check(menu.screen == "result" and menu.last_run_won, "Campaign victory displays real result menu")
        menu.queue_free()
    print("ORBFORGE TEST RESULTS: ", passed, " passed; ", failed, " failed")
    if failed == 0:
        print("ALL ORBFORGE TESTS PASSED")
    quit(1 if failed > 0 else 0)
