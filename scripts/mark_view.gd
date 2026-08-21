extends Control

## Geometric mark for relics/weapons. Data `visual` keys.

var mark := "spark"
var dim := false


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	queue_redraw()


func _draw() -> void:
	var r := minf(size.x, size.y) * 0.38
	paint(self, size * 0.5, r, mark, _col())


func _col() -> Color:
	if dim:
		return Color(0.32, 0.36, 0.42, 0.85)
	if str(Game.tier) == "violet":
		return Color(0.86, 0.48, 1.0, 0.95)
	return Color(0.45, 0.9, 1.0, 0.95)


static func paint(ci: CanvasItem, pos: Vector2, r: float, kind: String, col: Color) -> void:
	match kind:
		"ring":
			ci.draw_arc(pos, r, 0.0, TAU, 28, col, 2.2, true)
		"core":
			ci.draw_circle(pos, r, col)
			ci.draw_circle(pos, r * 0.45, Color(1, 1, 1, 0.85))
		"conduit":
			ci.draw_line(pos + Vector2(-r, 0), pos + Vector2(r, 0), col, 2.4, true)
			ci.draw_circle(pos + Vector2(-r, 0), 3.0, col)
			ci.draw_circle(pos + Vector2(r, 0), 3.0, col)
		"dust":
			for i in 5:
				var a := TAU * i / 5.0
				ci.draw_circle(pos + Vector2(cos(a), sin(a)) * r * 0.7, 2.2, col)
		"shard":
			var pts := PackedVector2Array([
				pos + Vector2(0, -r),
				pos + Vector2(r * 0.7, r * 0.6),
				pos + Vector2(-r * 0.7, r * 0.6),
			])
			ci.draw_colored_polygon(pts, col)
		"flare":
			ci.draw_circle(pos, r * 0.55, col)
			ci.draw_line(pos + Vector2(0, -r), pos + Vector2(0, r), col, 1.6, true)
			ci.draw_line(pos + Vector2(-r, 0), pos + Vector2(r, 0), col, 1.6, true)
		"wake":
			ci.draw_arc(pos, r, PI * 0.15, PI * 0.85, 12, col, 2.0, true)
			ci.draw_arc(pos, r * 0.6, PI * 0.15, PI * 0.85, 12, col, 1.6, true)
		"pulse":
			ci.draw_circle(pos, r * 0.42, col)
			ci.draw_circle(pos, r * 0.85, Color(col.r, col.g, col.b, 0.25))
		"beam":
			ci.draw_line(pos + Vector2(0, r), pos + Vector2(0, -r), col, 3.0, true)
			ci.draw_circle(pos + Vector2(0, -r), 3.5, col)
		"lance":
			var lp := PackedVector2Array([
				pos + Vector2(0, -r),
				pos + Vector2(r * 0.28, r),
				pos + Vector2(-r * 0.28, r),
			])
			ci.draw_colored_polygon(lp, col)
		"prism":
			for i in 3:
				var a := -PI / 2.0 + TAU * i / 3.0
				ci.draw_circle(pos + Vector2(cos(a), sin(a)) * r * 0.55, r * 0.28, col)
		"collapse":
			ci.draw_arc(pos, r, 0.0, TAU, 24, col, 2.0, true)
			ci.draw_circle(pos, r * 0.22, col)
		_:
			ci.draw_circle(pos, r * 0.5, col)
