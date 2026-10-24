extends Node2D
class_name OrbProjectile

var active: bool = false
var motion: Vector2 = Vector2.UP
var damage: float = 1.0
var ttl: float = 1.5
var radius: float = 7.0
var tint: Color = Color.CYAN

func _ready() -> void:
    visible = false
    set_process(false)

func activate(pos: Vector2, velocity: Vector2, power: float, size: float, color: Color) -> void:
    position = pos
    motion = velocity
    damage = power
    ttl = 1.65
    radius = size
    tint = color
    active = true
    visible = true
    queue_redraw()

func retire() -> void:
    active = false
    visible = false

func _draw() -> void:
    if not active:
        return
    var trail: Vector2 = -motion.normalized() * 23.0
    draw_line(trail, Vector2.ZERO, Color(tint.r, tint.g, tint.b, 0.34), radius * 2.4, true)
    draw_circle(Vector2.ZERO, radius + 4.0, Color(tint.r, tint.g, tint.b, 0.20))
    draw_circle(Vector2.ZERO, radius, tint)
    draw_circle(Vector2(-radius * 0.28, -radius * 0.35), radius * 0.36, Color.WHITE)
