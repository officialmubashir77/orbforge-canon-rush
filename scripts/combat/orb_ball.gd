extends CharacterBody2D
class_name OrbBall

var uid: int = 0
var tier: int = 1
var max_health: float = 8.0
var health: float = 8.0
var radius: float = 32.0
var tint: Color = Color("#78ddff")
var gravity_force: float = 1060.0
var bounce: float = 0.88
var min_bounce: float = 420.0
var flash: float = 0.0
var impact_scale: float = 0.0

func _ready() -> void:
    collision_layer = 2
    collision_mask = 1
    var shape_node: CollisionShape2D = CollisionShape2D.new()
    var shape: CircleShape2D = CircleShape2D.new()
    shape.radius = radius
    shape_node.shape = shape
    add_child(shape_node)

func configure(number: int, size_tier: int, hp: float, pos: Vector2, start_velocity: Vector2) -> void:
    uid = number
    tier = clampi(size_tier, 1, 4)
    radius = 20.0 + float(tier) * 13.0
    max_health = maxf(1.0, hp)
    health = max_health
    position = pos
    velocity = start_velocity
    var colors: Array[Color] = [Color("#52dfcc"), Color("#53baff"), Color("#ac87ff"), Color("#ff9b71")]
    tint = colors[tier - 1]
    if get_child_count() > 0:
        var collider: CollisionShape2D = get_child(0) as CollisionShape2D
        if collider != null:
            (collider.shape as CircleShape2D).radius = radius
    queue_redraw()

func receive_damage(amount: float) -> bool:
    health = maxf(0.0, health - amount)
    flash = 0.16
    impact_scale = 0.13
    queue_redraw()
    return health <= 0.0

func _physics_process(delta: float) -> void:
    velocity.y = minf(velocity.y + gravity_force * delta, 1400.0)
    var collision: KinematicCollision2D = move_and_collide(velocity * delta)
    if collision != null:
        var normal: Vector2 = collision.get_normal()
        velocity = velocity.bounce(normal) * bounce
        if normal.y < -0.7:
            velocity.y = -maxf(absf(velocity.y), min_bounce + tier * 24.0)
        elif absf(normal.x) > 0.7:
            velocity.x = signf(velocity.x) * maxf(absf(velocity.x), 115.0)
        position += normal * 1.5
        impact_scale = 0.08
    if flash > 0.0:
        flash = maxf(0.0, flash - delta)
    if impact_scale > 0.0:
        impact_scale = maxf(0.0, impact_scale - delta * 0.7)
    queue_redraw()

func _draw() -> void:
    var stretch_x: float = 1.0 + impact_scale
    var stretch_y: float = 1.0 - impact_scale * 0.75
    draw_set_transform(Vector2.ZERO, 0.0, Vector2(stretch_x, stretch_y))
    draw_circle(Vector2(2, 6), radius + 3.0, tint.darkened(0.68))
    draw_circle(Vector2.ZERO, radius, tint)
    draw_arc(Vector2(-2, -3), radius - 5.0, deg_to_rad(210), deg_to_rad(345), 28, Color(1, 1, 1, 0.28), 5.0, true)
    draw_circle(Vector2(-radius * 0.3, -radius * 0.38), radius * 0.24, Color(1, 1, 1, 0.37))
    draw_circle(Vector2(radius * 0.27, radius * 0.29), radius * 0.10, Color(0.01, 0.08, 0.2, 0.13))
    if flash > 0:
        draw_circle(Vector2.ZERO, radius - 2.0, Color(1, 1, 1, flash * 3.7))
    var text: String = str(ceili(health))
    var font: Font = ThemeDB.fallback_font
    var font_size: int = 23 if tier <= 2 else 27
    var width: float = font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
    draw_string(font, Vector2(-width * 0.5 + 1.0, font_size * 0.34 + 2.0), text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color(0.06, 0.11, 0.27, 0.7))
    draw_string(font, Vector2(-width * 0.5, font_size * 0.34), text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color.WHITE)
