extends Node2D
class_name OrbArena

signal hud_updated(info: Dictionary)
signal run_finished(won: bool, collected_coins: int, final_score: int)
signal wave_started(wave_number: int, wave_total: int)

const MAX_BALLS: int = 24
const MAX_PROJECTILES: int = 95
const MAX_COINS: int = 100

var audio: OrbAudio
var stage_number: int = 1
var configuration: Dictionary = {}
var weapon: Dictionary = {}
var stats: Dictionary = {}
var arena_size: Vector2 = Vector2(720, 1280)
var floor_y: float = 1110.0
var cannon: PlayerCannon
var effects: EffectsLayer
var balls: Array[OrbBall] = []
var bullets: Array[OrbProjectile] = []
var pickups: Array[Dictionary] = []
var rng: RandomNumberGenerator = RandomNumberGenerator.new()
var next_ball_id: int = 1
var pending_spawn: int = 0
var current_wave: int = -1
var spawn_clock: float = 0.0
var transition_clock: float = 0.0
var fire_clock: float = 0.0
var hud_clock: float = 0.0
var current_score: int = 0
var run_coins: int = 0
var combo: int = 0
var combo_timer: float = 0.0
var lives: int = 3
var ended: bool = false
var player_sensitivity: float = 1.0
var active_touch: int = -1

func setup(level_id: int, weapon_data: Dictionary, upgrades: Dictionary, settings: Dictionary, sound: OrbAudio) -> void:
    stage_number = level_id
    configuration = GameData.level_by_number(level_id)
    weapon = weapon_data
    stats = RunRules.weapon_stats(weapon, upgrades)
    audio = sound
    player_sensitivity = float(settings.get("sensitivity", 1.0))
    rng.seed = 170001 + level_id * 29171
    arena_size = get_viewport_rect().size
    floor_y = arena_size.y - 161.0
    effects = EffectsLayer.new()
    effects.quality = bool(settings.get("effects", true))
    add_child(effects)
    _add_boundaries()
    cannon = PlayerCannon.new()
    cannon.position = Vector2(arena_size.x * 0.5, floor_y - 27.0)
    cannon.target_x = cannon.position.x
    cannon.arena_width = arena_size.x
    cannon.set_weapon(str(weapon.get("id", "classic")), stats["color"] as Color)
    add_child(cannon)
    cannon.ball_touched.connect(_on_player_touched)
    for i in range(MAX_PROJECTILES):
        var bullet: OrbProjectile = OrbProjectile.new()
        bullets.append(bullet)
        add_child(bullet)
    _begin_next_wave()
    _send_hud()

func _add_boundary(center: Vector2, rect_size: Vector2) -> void:
    var wall: StaticBody2D = StaticBody2D.new()
    wall.collision_layer = 1
    wall.collision_mask = 0
    wall.position = center
    var shape: CollisionShape2D = CollisionShape2D.new()
    var box: RectangleShape2D = RectangleShape2D.new()
    box.size = rect_size
    shape.shape = box
    wall.add_child(shape)
    add_child(wall)

func _add_boundaries() -> void:
    _add_boundary(Vector2(arena_size.x * 0.5, floor_y + 18.0), Vector2(arena_size.x, 40.0))
    _add_boundary(Vector2(-19, arena_size.y * 0.5), Vector2(40, arena_size.y * 2.0))
    _add_boundary(Vector2(arena_size.x + 19, arena_size.y * 0.5), Vector2(40, arena_size.y * 2.0))

func _begin_next_wave() -> void:
    current_wave += 1
    var waves: Array = configuration.get("waves", []) as Array
    if current_wave >= waves.size():
        _end_run(true)
        return
    var wave: Dictionary = waves[current_wave]
    pending_spawn = int(wave.get("count", 1))
    spawn_clock = 0.0
    transition_clock = 0.0
    wave_started.emit(current_wave + 1, waves.size())
    effects.popup(Vector2(arena_size.x * 0.5, arena_size.y * 0.31), "WAVE " + str(current_wave + 1), Color("#81f8ff"))

func _spawn_ball() -> void:
    var waves: Array = configuration.get("waves", []) as Array
    var wave: Dictionary = waves[current_wave]
    var tier: int = int(wave.get("tier", 1))
    var hp: float = float(wave.get("hp", 8))
    var speed: float = float(wave.get("speed", 140))
    var ball: OrbBall = OrbBall.new()
    add_child(ball)
    var direction: float = -1.0 if rng.randi_range(0, 1) == 0 else 1.0
    var radius: float = 20.0 + tier * 13.0
    var x: float = rng.randf_range(radius + 35, maxf(radius + 36, arena_size.x - radius - 35))
    ball.configure(next_ball_id, tier, hp, Vector2(x, arena_size.y * 0.22), Vector2(speed * direction, -rng.randf_range(70, 210)))
    next_ball_id += 1
    balls.append(ball)
    pending_spawn -= 1

func _physics_process(delta: float) -> void:
    if ended:
        return
    if combo_timer > 0.0:
        combo_timer -= delta
        if combo_timer <= 0.0:
            combo = 0
    fire_clock -= delta
    if fire_clock <= 0.0:
        _shoot()
        fire_clock += 1.0 / maxf(0.5, float(stats["fire_rate"]))
    _move_projectiles(delta)
    if pending_spawn > 0:
        spawn_clock -= delta
        if spawn_clock <= 0.0 and balls.size() < MAX_BALLS:
            _spawn_ball()
            spawn_clock = 0.95
    elif balls.is_empty():
        transition_clock += delta
        if transition_clock >= 1.0:
            _begin_next_wave()
    hud_clock -= delta
    if hud_clock <= 0.0:
        _send_hud()
        hud_clock = 0.12

func _shoot() -> void:
    if cannon == null:
        return
    var streams: int = int(stats["streams"])
    var spread: float = float(stats["spread_degrees"])
    var speed: float = float(stats["projectile_speed"])
    for index in range(streams):
        var angle: float = deg_to_rad((float(index) - (float(streams) - 1.0) * 0.5) * spread)
        var launch_velocity: Vector2 = Vector2.UP.rotated(angle) * speed
        for projectile in bullets:
            if not projectile.active:
                projectile.activate(cannon.position + Vector2((float(index) - (float(streams) - 1.0) * 0.5) * 13.0, -65), launch_velocity, float(stats["damage"]), float(stats["projectile_radius"]), stats["color"] as Color)
                break
    cannon.play_recoil()
    if audio != null:
        audio.play_sfx("shot")

func _move_projectiles(delta: float) -> void:
    var space: PhysicsDirectSpaceState2D = get_world_2d().direct_space_state
    for projectile in bullets:
        if not projectile.active:
            continue
        projectile.ttl -= delta
        var destination: Vector2 = projectile.position + projectile.motion * delta
        if projectile.ttl <= 0.0 or destination.y < -40 or destination.x < -40 or destination.x > arena_size.x + 40:
            projectile.retire()
            continue
        var query: PhysicsRayQueryParameters2D = PhysicsRayQueryParameters2D.create(projectile.position, destination, 2)
        var result: Dictionary = space.intersect_ray(query)
        if not result.is_empty():
            var target: Object = result.get("collider")
            if target is OrbBall:
                _damage_ball(target as OrbBall, projectile.damage)
                projectile.retire()
                continue
        projectile.position = destination

func _damage_ball(ball: OrbBall, damage: float) -> void:
    if ended or not is_instance_valid(ball) or not balls.has(ball):
        return
    var destroyed: bool = ball.receive_damage(RunRules.damage_after_armor(damage, 0.0))
    effects.burst(ball.position + Vector2(0, -ball.radius * 0.2), ball.tint, 4)
    if randi_range(0, 2) == 0:
        effects.popup(ball.position + Vector2(0, -ball.radius), str(ceili(damage)), Color("#edfcff"))
    if audio != null:
        audio.play_sfx("impact")
    if destroyed:
        _destroy_ball(ball)

func _destroy_ball(ball: OrbBall) -> void:
    if not balls.has(ball):
        return
    balls.erase(ball)
    combo = mini(50, combo + 1)
    combo_timer = 2.5
    current_score += RunRules.score_for_kill(ball.tier, combo)
    var reward: int = RunRules.ball_reward(ball.tier)
    var pos: Vector2 = ball.position
    var tier: int = ball.tier
    var max_hp: float = ball.max_health
    var color: Color = ball.tint
    effects.burst(pos, color, 17)
    effects.popup(pos + Vector2(0, -37), "+" + str(RunRules.score_for_kill(tier, combo)), Color("#ffe09e"))
    _drop_coin(pos, reward)
    if audio != null:
        audio.play_sfx("split")
    ball.queue_free()
    if tier > 1:
        for i in range(2):
            if balls.size() >= MAX_BALLS:
                break
            var direction: float = -1.0 if i == 0 else 1.0
            var child: OrbBall = OrbBall.new()
            add_child(child)
            var child_tier: int = RunRules.child_tier(tier)
            var child_hp: float = RunRules.child_health(max_hp, tier)
            var child_radius: float = 20.0 + child_tier * 13.0
            var x: float = clampf(pos.x + direction * child_radius * 0.55, child_radius + 3.0, arena_size.x - child_radius - 3.0)
            var y: float = clampf(pos.y, child_radius + 150, floor_y - child_radius - 3.0)
            child.configure(next_ball_id, child_tier, child_hp, Vector2(x, y), Vector2(direction * (230 + 25 * tier), -510 - 30 * tier))
            next_ball_id += 1
            balls.append(child)
    _send_hud()

func _drop_coin(pos: Vector2, amount: int) -> void:
    if pickups.size() >= MAX_COINS:
        run_coins += amount
        return
    pickups.append({"pos": pos, "velocity": Vector2(rng.randf_range(-170.0, 170.0), -220.0), "value": amount, "life": 0.0})

func _process(delta: float) -> void:
    if ended:
        return
    for i in range(pickups.size() - 1, -1, -1):
        var coin: Dictionary = pickups[i]
        var pos: Vector2 = coin["pos"]
        var v: Vector2 = coin["velocity"]
        var age: float = float(coin["life"]) + delta
        v.y += 640.0 * delta
        pos += v * delta
        if pos.y > floor_y - 12.0:
            pos.y = floor_y - 12.0
            v.y = -absf(v.y) * 0.29
            v.x *= 0.85
        var target: Vector2 = cannon.position if cannon != null else Vector2.ZERO
        var distance: float = pos.distance_to(target)
        if distance < 190.0 or age > 5.0:
            pos = pos.move_toward(target, (340.0 + 600.0 / maxf(40.0, distance) * 34.0) * delta)
        if distance < 39.0 or age > 10.0:
            run_coins += int(coin["value"])
            if audio != null:
                audio.play_sfx("coin")
            pickups.remove_at(i)
        else:
            coin["pos"] = pos
            coin["velocity"] = v
            coin["life"] = age
            pickups[i] = coin
    queue_redraw()

func _on_player_touched(ball: OrbBall) -> void:
    if ended or cannon.invulnerability > 0.0 or not is_instance_valid(ball):
        return
    lives -= 1
    cannon.take_hit()
    effects.burst(cannon.position, Color("#ff6c9c"), 22)
    effects.popup(cannon.position + Vector2(0, -78), "-1 HP", Color("#ffb9d0"))
    if audio != null:
        audio.play_sfx("hurt")
    ball.velocity.x += (-1.0 if ball.position.x > cannon.position.x else 1.0) * 100.0
    if lives <= 0:
        _end_run(false)
    else:
        _send_hud()

func _end_run(won: bool) -> void:
    if ended:
        return
    ended = true
    for coin in pickups:
        run_coins += int(coin["value"])
    pickups.clear()
    if audio != null and won:
        audio.play_sfx("win")
    run_finished.emit(won, run_coins, current_score)

func _send_hud() -> void:
    var waves: Array = configuration.get("waves", []) as Array
    hud_updated.emit({"level":stage_number,"wave":current_wave + 1,"waves":waves.size(),"health":lives,"coins":run_coins,"score":current_score,"combo":combo})

func _unhandled_input(event: InputEvent) -> void:
    if ended:
        return
    if event is InputEventScreenTouch:
        var touch: InputEventScreenTouch = event as InputEventScreenTouch
        if touch.pressed and active_touch < 0:
            active_touch = touch.index
            cannon.set_horizontal_target(cannon.position.x + (touch.position.x - cannon.position.x) * player_sensitivity)
        elif not touch.pressed and touch.index == active_touch:
            active_touch = -1
    elif event is InputEventScreenDrag:
        var drag: InputEventScreenDrag = event as InputEventScreenDrag
        if drag.index == active_touch:
            cannon.set_horizontal_target(cannon.position.x + (drag.position.x - cannon.position.x) * player_sensitivity)
    elif event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
        cannon.set_horizontal_target(cannon.position.x + (event.position.x - cannon.position.x) * player_sensitivity)
    elif event is InputEventMouseButton:
        var mouse: InputEventMouseButton = event as InputEventMouseButton
        if mouse.button_index == MOUSE_BUTTON_LEFT and mouse.pressed:
            cannon.set_horizontal_target(cannon.position.x + (mouse.position.x - cannon.position.x) * player_sensitivity)

func _draw() -> void:
    draw_rect(Rect2(0, floor_y + 3, arena_size.x, 36), Color("#0e2e42"))
    draw_rect(Rect2(0, floor_y, arena_size.x, 5), Color("#55f1bd"))
    draw_rect(Rect2(0, floor_y + 6, arena_size.x, 3), Color(0.44, 0.94, 0.82, 0.12))
    for coin in pickups:
        var pos: Vector2 = coin["pos"]
        draw_circle(pos + Vector2(2, 3), 12, Color(0, 0.1, 0.2, 0.30))
        draw_circle(pos, 10, Color("#f7be49"))
        draw_circle(pos + Vector2(-3, -3), 4, Color("#fff8ca"))
        draw_arc(pos, 8, 0, TAU, 16, Color("#fff6ad"), 2, true)
