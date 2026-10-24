extends Node2D
class_name OrbHeroMark

var pulse: float = 0.0

func _process(delta: float) -> void:
    pulse += delta
    queue_redraw()

func _draw() -> void:
    var shimmer: float = 0.5 + 0.5 * sin(pulse * 2.1)
    draw_circle(Vector2(0, 12), 104, Color(0.13, 0.68, 0.91, 0.035))
    draw_circle(Vector2(0, 12), 76 + shimmer * 5, Color(0.20, 0.83, 0.98, 0.08))
    draw_arc(Vector2(0, 17), 93, 0, TAU, 60, Color(0.36, 0.9, 1, 0.11), 3, true)
    var orb1: Vector2 = Vector2(-96, -43 + sin(pulse * 2.3) * 8)
    var orb2: Vector2 = Vector2(104, -70 + sin(pulse * 1.8 + 2) * 7)
    for data in [{"pos":orb1,"r":34.0,"fill":Color("#48d6cc")},{"pos":orb2,"r":46.0,"fill":Color("#a27cff")}]:
        var p: Vector2 = data["pos"]
        var radius: float = data["r"]
        var shade: Color = data["fill"]
        draw_circle(p + Vector2(3, 5), radius + 3, Color(0, 0.07, 0.18, 0.52))
        draw_circle(p, radius, shade)
        draw_arc(p, radius - 5, deg_to_rad(213), deg_to_rad(327), 24, Color(1, 1, 1, 0.56), 5, true)
        draw_circle(p + Vector2(-radius * 0.3, -radius * 0.36), radius * 0.24, Color(1, 1, 1, 0.59))
    draw_line(Vector2(0, -6), Vector2(0, -71), Color("#23416b"), 57, true)
    draw_line(Vector2(0, -6), Vector2(0, -71), Color("#53d9ee"), 38, true)
    draw_line(Vector2(-12, -39), Vector2(-12, -72), Color(1, 1, 1, 0.4), 9, true)
    draw_line(Vector2(-27, -69), Vector2(27, -69), Color("#dcfaff"), 12, true)
    for wheel_x in [-44, 44]:
        draw_circle(Vector2(wheel_x, 55), 24, Color("#112644"))
        draw_circle(Vector2(wheel_x, 55), 16, Color("#8caed9"))
        draw_circle(Vector2(wheel_x, 55), 8, Color("#254876"))
    draw_circle(Vector2(0, 32), 51, Color("#213b69"))
    draw_circle(Vector2(0, 31), 39, Color("#4fa8c2"))
    draw_circle(Vector2(-9, 18), 22, Color("#56edee"))
    draw_circle(Vector2(-18, 12), 9, Color(1, 1, 1, 0.61))
    draw_arc(Vector2.ZERO, 118, deg_to_rad(211), deg_to_rad(330), 26, Color(0.48, 0.91, 1, 0.17), 3, true)
