extends Control

## Deep indigo space with crisp star dots and a subtle bottom planet limb.

var _stars: Array[Vector4] = [] # x, y, size, phase
var _t := 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var rng := RandomNumberGenerator.new()
	rng.seed = 17
	for i in 260:
		_stars.append(Vector4(rng.randf(), rng.randf(), rng.randf(), rng.randf() * TAU))
	set_process(true)


func _process(dt: float) -> void:
	_t += dt
	queue_redraw()


func _region_visual() -> String:
	var rid := Game.current_region_id()
	var regs: Dictionary = Data.regions()
	if regs.has(rid):
		return str(regs[rid].get("visual", "orbit"))
	return "orbit"


func _draw() -> void:
	var w := size.x
	var h := size.y
	if w < 2.0 or h < 2.0:
		return

	var vis := _region_visual()
	var bg := Color(0.025, 0.012, 0.07)
	var star_col := Color(0.96, 0.98, 1.0, 1.0)
	var star_alt := Color(0.22, 0.92, 1.0, 1.0)
	var star_n := 220
	var limb := Color(0.22, 0.92, 1.0)
	match vis:
		"atmo":
			bg = Color(0.04, 0.012, 0.08)
			star_col = Color(0.96, 0.92, 1.0, 1.0)
			star_alt = Color(0.90, 0.72, 1.0, 1.0)
			star_n = 180
			limb = Color(0.72, 0.38, 1.0)
		"sat":
			bg = Color(0.018, 0.022, 0.08)
			star_col = Color(0.92, 0.98, 1.0, 1.0)
			star_alt = Color(0.22, 0.92, 1.0, 1.0)
			star_n = 260
			limb = Color(0.72, 0.98, 1.0)
		"solar":
			bg = Color(0.028, 0.016, 0.07)
			star_col = Color(0.96, 0.98, 1.0, 1.0)
			star_alt = Color(0.22, 0.92, 1.0, 1.0)
			star_n = 200
			limb = Color(0.22, 0.92, 1.0)

	draw_rect(Rect2(Vector2.ZERO, size), bg)

	var n_stars := mini(star_n, _stars.size())
	for i in n_stars:
		var s: Vector4 = _stars[i]
		var tw: float = 0.75 + 0.25 * (0.5 + 0.5 * sin(_t * (0.7 + s.z * 2.2) + s.w))
		var rad: float = 0.70 + s.z * 1.40
		if s.z > 0.88:
			rad = 2.10 + s.z * 0.50
		var a: float = (0.70 + s.z * 0.30) * tw
		var p: Vector2 = Vector2(s.x * w, s.y * h * 0.86)
		var col := star_alt if s.z > 0.72 else star_col
		draw_circle(p, rad, Color(col.r, col.g, col.b, a), true, -1.0, true)

	_draw_planet(w, h, limb)
	if vis == "sat":
		_draw_sat_motes(w, h)


func _draw_planet(w: float, h: float, limb: Color) -> void:
	var pr := w * 1.32
	var pc := Vector2(w * 0.5, h + pr * 0.74)
	draw_circle(pc, pr, Color(0.04, 0.02, 0.10), true, -1.0, true)
	draw_circle(pc + Vector2(-pr * 0.18, -pr * 0.12), pr * 0.48, Color(0.12, 0.05, 0.26, 0.70), true, -1.0, true)
	draw_circle(pc + Vector2(pr * 0.10, -pr * 0.06), pr * 0.32, Color(0.18, 0.08, 0.36, 0.48), true, -1.0, true)
	draw_circle(pc + Vector2(-pr * 0.08, pr * 0.06), pr * 0.22, Color(0.08, 0.04, 0.18, 0.55), true, -1.0, true)
	draw_arc(pc, pr + 3.0, PI * 1.14, PI * 1.86, 48, Color(limb.r, limb.g, limb.b, 0.88), 3.6, true)


func _draw_sat_motes(w: float, h: float) -> void:
	for i in 8:
		var a: float = _t * 0.07 + float(i) * 0.72
		var orbit: float = w * (0.16 + float(i % 4) * 0.06)
		var p: Vector2 = Vector2(w * 0.5, h * 0.46) + Vector2(cos(a), sin(a) * 0.38) * orbit
		draw_circle(p, 1.4 + float(i % 2), Color(0.72, 0.98, 1.0, 0.70 + float(i % 3) * 0.10), true, -1.0, true)
