extends Node2D
class_name EffectsLayer

var particles: Array[Dictionary] = []
var labels: Array[Dictionary] = []
var rings: Array[Dictionary] = []
var quality: bool = true
var rng: RandomNumberGenerator = RandomNumberGenerator.new()

func _ready() -> void:
    rng.randomize()

func burst(pos: Vector2, tint: Color, count: int = 9) -> void:
    var amount: int = mini(42, count) if quality else mini(8, count)
    for i in range(amount):
        var angle: float = rng.randf_range(0.0, TAU)
        var speed: float = rng.randf_range(100.0, 330.0)
        particles.append({"pos": pos, "vel": Vector2.from_angle(angle) * speed, "life": 0.52, "max": 0.52, "color": tint, "size": rng.randf_range(3.0, 8.0)})
    if rings.size() < 24:
        rings.append({"pos": pos, "age": 0.0, "color": tint})

func popup(pos: Vector2, content: String, tint: Color = Color.WHITE) -> void:
    if labels.size() < 24:
        labels.append({"pos": pos, "text": content, "age": 0.0, "color": tint})

func _process(delta: float) -> void:
    for i in range(particles.size() - 1, -1, -1):
        var part: Dictionary = particles[i]
        part["life"] = float(part["life"]) - delta
        if float(part["life"]) <= 0.0:
            particles.remove_at(i)
        else:
            part["vel"] = (part["vel"] as Vector2) + Vector2(0, 320 * delta)
            part["pos"] = (part["pos"] as Vector2) + (part["vel"] as Vector2) * delta
            particles[i] = part
    for i in range(labels.size() - 1, -1, -1):
        var item: Dictionary = labels[i]
        item["age"] = float(item["age"]) + delta
        if float(item["age"]) > 0.75:
            labels.remove_at(i)
        else:
            item["pos"] = (item["pos"] as Vector2) + Vector2(0, -48.0 * delta)
            labels[i] = item
    for i in range(rings.size() - 1, -1, -1):
        var ring: Dictionary = rings[i]
        ring["age"] = float(ring["age"]) + delta
        if float(ring["age"]) >= 0.28:
            rings.remove_at(i)
        else:
            rings[i] = ring
    queue_redraw()

func _draw() -> void:
    for p in particles:
        var color: Color = p["color"]
        color.a = clampf(float(p["life"]) / float(p["max"]), 0.0, 1.0)
        draw_circle(p["pos"], float(p["size"]) * color.a, color)
    for r in rings:
        var progress: float = float(r["age"]) / 0.28
        var color: Color = r["color"]
        color.a = (1.0 - progress) * 0.55
        draw_arc(r["pos"], 18.0 + progress * 49.0, 0.0, TAU, 36, color, 4.0, true)
    var font: Font = ThemeDB.fallback_font
    for item in labels:
        var age: float = float(item["age"])
        var text: String = str(item["text"])
        var color: Color = item["color"]
        color.a = 1.0 - age / 0.75
        var text_width: float = font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 21).x
        draw_string(font, (item["pos"] as Vector2) - Vector2(text_width * 0.5, 0), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 21, color)
