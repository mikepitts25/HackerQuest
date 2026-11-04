extends Control
## Lightweight animated skyline drawn with native canvas primitives.
## Kept behind the title controls and never intercepts input.

var clock := 0.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _process(delta: float) -> void:
	clock += delta
	queue_redraw()

func _draw() -> void:
	var horizon := size.y * 0.76
	draw_rect(Rect2(Vector2.ZERO, size), Color("080e1c"))
	# Soft bands of indigo behind the silhouette.
	for i in 32:
		var t := float(i) / 32
		draw_rect(Rect2(0, horizon - 260 + i * 10, size.x, 10), Color(0.10, 0.07, 0.22, sin(t * PI) * 0.55))
	var moon := Vector2(size.x * 0.76, size.y * 0.24)
	draw_circle(moon, 49, Color("182c47"))
	draw_arc(moon, 54, 0, TAU, 64, Color(0.35, 0.88, 0.91, 0.4), 1.0, true)
	for i in 19:
		var x := float(i) * size.x / 18 - 15
		var height := 70 + fmod(i * 73.0, 190)
		var width := size.x / 18 + 12
		draw_rect(Rect2(x, horizon - height, width, height), Color("101a2c"))
		draw_line(Vector2(x, horizon - height), Vector2(x + width - 2, horizon - height), Color(0.4, 0.3, 0.7, 0.55), 2)
		for row in int(height / 18) - 1:
			for col in 3:
				if (i + row * 3 + col * 7) % 4 == 0:
					continue
				var color := Color("65dcd3") if i % 3 == 0 else Color("d296b8")
				color.a = 0.16 + 0.15 * (0.5 + 0.5 * sin(clock * 0.6 + i + row))
				draw_rect(Rect2(x + 7 + col * 10, horizon - height + 12 + row * 18, 4, 7), color)
	draw_line(Vector2(0, horizon), Vector2(size.x, horizon), Color("3d747f"), 1)
	for i in 13:
		var x := float(i) / 12 * size.x
		draw_line(Vector2(size.x / 2 + (x - size.x / 2) * 0.15, horizon), Vector2(x, size.y), Color(0.22, 0.48, 0.55, 0.12), 1)
	for i in 8:
		var t := float(i) / 8
		var y := horizon + t * t * (size.y - horizon)
		draw_line(Vector2(0, y), Vector2(size.x, y), Color(0.22, 0.48, 0.55, 0.14), 1)
	for i in 12:
		var x := fmod(i * 71.0 + clock * (8 + i % 3 * 6), size.x)
		var y := 70 + fmod(i * 137.0, horizon - 100)
		draw_circle(Vector2(x, y), 1.5, Color(0.4, 0.9, 0.86, 0.35))
