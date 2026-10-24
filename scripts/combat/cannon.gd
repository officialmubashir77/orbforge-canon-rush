extends Node2D
class_name PlayerCannon

signal ball_touched(ball: OrbBall)

var target_x: float = 360.0
var arena_width: float = 720.0
var movement_speed: float = 1650.0
var recoil: float = 0.0
var weapon_id: String = "classic"
var skin_color: Color = Color("#42e7ff")
var invulnerability: float = 0.0

func _ready() -> void:
    var area: Area2D = Area2D.new()
    area.name = "CannonHitbox"
    area.collision_layer = 0
    area.collision_mask = 2
    area.monitoring = true
    var collision: CollisionShape2D = CollisionShape2D.new()
    var shape: RectangleShape2D = RectangleShape2D.new()
    shape.size = Vector2(69, 48)
    collision.shape = shape
    area.add_child(collision)
    add_child(area)
    area.body_entered.connect(_on_body_entered)

func set_weapon(id: String, color: Color) -> void:
    weapon_id = id
    skin_color = color
    queue_redraw()

func set_horizontal_target(value: float) -> void:
    target_x = RunRules.clamp_cannon_x(value, arena_width)

func play_recoil() -> void:
    recoil = minf(16.0, recoil + 9.0)

func take_hit() -> void:
    invulnerability = 1.1
    queue_redraw()

func _physics_process(delta: float) -> void:
    position.x = move_toward(position.x, target_x, movement_speed * delta)
    recoil = move_toward(recoil, 0.0, 84.0 * delta)
    invulnerability = maxf(0.0, invulnerability - delta)
    queue_redraw()

func _on_body_entered(body: Node2D) -> void:
    if body is OrbBall:
        ball_touched.emit(body as OrbBall)

func _draw() -> void:
    if invulnerability > 0.0 and int(Time.get_ticks_msec() / 90) % 2 == 0:
        return
    draw_circle(Vector2(0, 18), 49.0, Color(0.0, 0.06, 0.15, 0.19))
    draw_circle(Vector2(-33, 21), 20.0, Color("#1b2f5b"))
    draw_circle(Vector2(33, 21), 20.0, Color("#1b2f5b"))
    draw_circle(Vector2(-33, 21), 11.0, Color("#d1e2ff"))
    draw_circle(Vector2(33, 21), 11.0, Color("#d1e2ff"))
    var shaft_w: float = 18.0 if weapon_id == "rapid" else 22.0
    var barrel_h: float = 57.0 if weapon_id == "spread" else 62.0
    var barrel: Rect2 = Rect2(-shaft_w, -barrel_h + recoil, shaft_w * 2.0, 60.0)
    draw_rect(barrel, Color("#1d2f55"), true)
    draw_rect(Rect2(-shaft_w + 5, -barrel_h + recoil, 9, 57), skin_color, true)
    draw_rect(Rect2(-shaft_w - 4, -barrel_h + recoil, shaft_w * 2 + 8, 11), Color("#e2f6ff"), true)
    if weapon_id == "spread":
        draw_rect(Rect2(-31, -42 + recoil, 10, 30), skin_color.lightened(0.15), true)
        draw_rect(Rect2(21, -42 + recoil, 10, 30), skin_color.lightened(0.15), true)
    if weapon_id == "rapid":
        draw_rect(Rect2(-25, -53 + recoil, 50, 8), Color("#ffefae"), true)
    draw_circle(Vector2(0, 12), 35.0, Color("#223c6b"))
    draw_circle(Vector2(0, 8), 27.0, skin_color.darkened(0.38))
    draw_circle(Vector2(-7, 0), 15.0, skin_color)
    draw_circle(Vector2(-12, -6), 7.0, Color(1, 1, 1, 0.56))
    draw_arc(Vector2(0, 12), 31.0, 0.0, TAU, 30, Color("#b5cbf2"), 4.0, true)
