extends Node2D
class_name WorldPainter

var screen_size: Vector2 = Vector2(720, 1280)
var dim: bool = false
var offset: float = 0.0
var stars: Array[Dictionary] = []

func _ready() -> void:
    var random: RandomNumberGenerator = RandomNumberGenerator.new()
    random.seed = 914724
    for i in range(32):
        stars.append({"x": random.randf(), "y": random.randf_range(0.09, 0.76), "r": random.randf_range(1.1, 3.0)})

func _process(delta: float) -> void:
    offset = fmod(offset + delta * 9.0, screen_size.x + 180.0)
    queue_redraw()

func _draw() -> void:
    var w: float = screen_size.x
    var h: float = screen_size.y
    var top: Color = Color("#0b1640")
    var bottom: Color = Color("#163c64")
    for i in range(44):
        var value: float = float(i) / 44.0
        draw_rect(Rect2(0.0, h * value, w, h / 43.0 + 2.0), top.lerp(bottom, value), true)
    draw_circle(Vector2(w * 0.77, h * 0.23), minf(w * 0.22, 146.0), Color(0.24, 0.78, 1.0, 0.065))
    draw_circle(Vector2(w * 0.77, h * 0.23), minf(w * 0.14, 105.0), Color(0.24, 0.78, 1.0, 0.09))
    for star in stars:
        var pos: Vector2 = Vector2(w * float(star["x"]), h * float(star["y"]))
        draw_circle(pos, float(star["r"]), Color(0.64, 0.89, 1.0, 0.25))
    for i in range(5):
        var cloud_x: float = fposmod(i * w * 0.34 + offset * (0.24 + i * 0.05), w + 280.0) - 140.0
        var cloud_y: float = h * (0.19 + i * 0.11)
        draw_circle(Vector2(cloud_x, cloud_y), 55.0, Color(0.53, 0.82, 1.0, 0.035))
        draw_circle(Vector2(cloud_x + 38, cloud_y + 8), 38.0, Color(0.53, 0.82, 1.0, 0.035))
    var hill_back: PackedVector2Array = PackedVector2Array([Vector2(0,h * 0.85),Vector2(w * 0.23,h * 0.76),Vector2(w * 0.4,h * 0.83),Vector2(w * 0.65,h * 0.74),Vector2(w,h * 0.84),Vector2(w,h),Vector2(0,h)])
    draw_colored_polygon(hill_back, Color("#12365c"))
    var hill_front: PackedVector2Array = PackedVector2Array([Vector2(0,h * 0.94),Vector2(w * 0.17,h * 0.86),Vector2(w * 0.35,h * 0.94),Vector2(w * 0.62,h * 0.84),Vector2(w,h * 0.91),Vector2(w,h),Vector2(0,h)])
    draw_colored_polygon(hill_front, Color("#15476d"))
    if dim:
        draw_rect(Rect2(Vector2.ZERO, screen_size), Color(0.01, 0.025, 0.07, 0.23), true)
