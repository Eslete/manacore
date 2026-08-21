extends Control

## First region is Earth's sky. Later regions stay off-world.

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
		return str(regs[rid].get("visual", "sky"))
	return "sky"


func _draw() -> void:
	var w := size.x
	var h := size.y
	if w < 2.0 or h < 2.0:
		return
	var vis := _region_visual()
	if vis == "sky" or vis == "orbit":
		_draw_earth_sky(w, h)
		return
	_draw_space(w, h, vis)


func _draw_earth_sky(w: float, h: float) -> void:
	var bands := 18
	for i in bands:
		var u := float(i) / float(bands - 1)
		var y0 := h * float(i) / float(bands)
		var y1 := h * float(i + 1) / float(bands)
		var zenith := Color(0.18, 0.42, 0.78)
		var mid := Color(0.55, 0.78, 0.94)
		var haze := Color(0.86, 0.90, 0.92)
		var col := zenith.lerp(mid, clampf(u * 1.35, 0.0, 1.0))
		if u > 0.62:
			col = mid.lerp(haze, clampf((u - 0.62) / 0.38, 0.0, 1.0))
		draw_rect(Rect2(0.0, y0, w, y1 - y0 + 1.0), col)
	_draw_clouds(w, h)
	var ground_h := h * 0.16
	var gy := h - ground_h
	draw_rect(Rect2(0.0, gy, w, ground_h), Color(0.08, 0.16, 0.12))
	draw_rect(Rect2(0.0, gy, w, 7.0), Color(0.42, 0.62, 0.48, 0.55))
	draw_rect(Rect2(0.0, gy - 10.0, w, 12.0), Color(0.78, 0.88, 0.94, 0.35))


func _draw_clouds(w: float, h: float) -> void:
	var puff := Color(0.96, 0.98, 1.0, 0.16)
	for g in 4:
		var base_x := w * (0.12 + float(g) * 0.22) + sin(_t * 0.03 + float(g)) * w * 0.04
		var base_y := h * (0.18 + float(g % 3) * 0.10)
		for i in 5:
			var ox := float(i - 2) * w * 0.035
			var oy := (1.0 if i % 2 == 0 else -1.0) * h * 0.012
			var rad := w * (0.046 + float(i % 3) * 0.012)
			draw_circle(Vector2(base_x + ox, base_y + oy), rad, puff, true, -1.0, true)


func _draw_space(w: float, h: float, vis: String) -> void:
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
