extends Control

## Cyan/violet sphere on CORE. Combat mini-core is sphere-only.

const PURPLE := Color(0.42, 0.16, 0.72)
const PURPLE_LIT := Color(0.72, 0.38, 1.0)
const CYAN := Color(0.22, 0.92, 1.0)
const CYAN_DEEP := Color(0.08, 0.46, 0.70)
const CYAN_LIT := Color(0.72, 0.98, 1.0)
const WHITE := Color(0.96, 0.98, 1.0)
const VIOLET_SOFT := Color(0.90, 0.72, 1.0)

const _ORB_PAD := 1.42
const _BODY_PAD := 1.06

var compact := false
var _t := 0.0
var _bits: Array[Dictionary] = []
var _motes: Array[Dictionary] = []
var _mote_acc := 0.0
var _prev_flash := 0.0
var _prev_shot := 0.0
var _glow: ColorRect
var _orb: ColorRect
var _glow_mat: ShaderMaterial
var _orb_mat: ShaderMaterial


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	clip_contents = false
	set_process(true)
	_glow_mat = ShaderMaterial.new()
	_glow_mat.shader = load("res://shaders/core_glow.gdshader")
	_glow = ColorRect.new()
	_glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_glow.show_behind_parent = true
	_glow.color = Color.WHITE
	_glow.material = _glow_mat
	add_child(_glow)
	_orb_mat = ShaderMaterial.new()
	_orb_mat.shader = load("res://shaders/core_orb.gdshader")
	_orb = ColorRect.new()
	_orb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_orb.show_behind_parent = true
	_orb.color = Color.WHITE
	_orb.material = _orb_mat
	add_child(_orb)


func _process(dt: float) -> void:
	_t += dt
	var flash := Game.tap_flash
	if not compact and flash > 0.72 and _prev_flash <= 0.72:
		_surge_inflow()
	_prev_flash = flash
	if compact:
		var shot := Game.shot_flash
		if shot > 0.72 and _prev_shot <= 0.72:
			_muzzle_burst()
		elif shot > _prev_shot + 0.35:
			_muzzle_burst()
		_prev_shot = shot
		_motes.clear()
		_mote_acc = 0.0
	else:
		_spawn_inflow(dt)
		_step_motes(dt)
	_step_bits(dt)
	_sync_orb()
	queue_redraw()


func aim_local() -> Vector2:
	return size * Vector2(0.5, 0.50) if compact else size * Vector2(0.5, 0.52)


func _center() -> Vector2:
	return aim_local()


func _radius() -> float:
	return minf(size.x, size.y) * (0.10 if compact else 0.22)


func _accent() -> Color:
	return PURPLE_LIT if str(Game.tier) == "violet" else CYAN


func _accent_deep() -> Color:
	return PURPLE if str(Game.tier) == "violet" else CYAN_DEEP


func _accent_lit() -> Color:
	return VIOLET_SOFT if str(Game.tier) == "violet" else CYAN_LIT


func _surge_inflow() -> void:
	var c := _center()
	var r := _radius()
	var n := 10
	var charged := Game.level_of("flywheel") > 0 and Game.flywheel_charge_ratio() >= 0.8
	for i in n:
		if _motes.size() >= 28:
			break
		var a := TAU * float(i) / float(n) + randf() * 0.28
		var spawn_r := r * randf_range(2.15, 2.75)
		var p := c + Vector2(cos(a), sin(a)) * spawn_r
		var to_c := c - p
		var dist := to_c.length()
		if dist < 1.0:
			continue
		var life := randf_range(0.42, 0.62)
		var spd := (dist - r) / life
		_motes.append({
			"p": p,
			"v": to_c / dist * spd,
			"life": life,
			"age": 0.0,
			"r": randf_range(5.0, 7.2) * (1.22 if charged else 1.0),
			"hot": charged,
		})


func _muzzle_burst() -> void:
	var c := _center()
	var r := _radius()
	var spark_r := maxf(8.0, r * 0.22)
	var n := 7
	for i in n:
		var a := -PI * 0.5 + (float(i) - float(n - 1) * 0.5) * 0.20
		var dir := Vector2(cos(a), sin(a))
		_bits.append({
			"p": c + dir * r * 0.88,
			"v": dir * (260.0 + float(i) * 16.0),
			"life": 0.36,
			"age": 0.0,
			"r": spark_r * (1.0 - float(i) * 0.06),
		})
	for i in 3:
		var a := -PI * 0.5 + (float(i) - 1.0) * 0.38
		var dir := Vector2(cos(a), sin(a))
		_bits.append({
			"p": c + dir * r * 0.40,
			"v": dir * 140.0,
			"life": 0.24,
			"age": 0.0,
			"r": spark_r * 0.78,
		})
	if _bits.size() > 28:
		_bits = _bits.slice(_bits.size() - 28)


func _step_bits(dt: float) -> void:
	var keep: Array[Dictionary] = []
	for bit in _bits:
		var age: float = float(bit["age"]) + dt
		if age >= float(bit["life"]):
			continue
		var p: Vector2 = bit["p"]
		var v: Vector2 = bit["v"]
		p += v * dt
		bit["p"] = p
		bit["age"] = age
		keep.append(bit)
	_bits = keep


func _spawn_inflow(dt: float) -> void:
	if _motes.size() >= 28:
		_mote_acc = minf(_mote_acc, 0.0)
		return
	var prod := maxf(Game.production(), 0.4)
	var rate := 3.2 + prod * 0.70
	rate = minf(rate, 20.0)
	_mote_acc += dt * rate
	var c := _center()
	var r := _radius()
	var charged := Game.level_of("flywheel") > 0 and Game.flywheel_charge_ratio() >= 0.8
	while _mote_acc >= 1.0 and _motes.size() < 28:
		_mote_acc -= 1.0
		var a := randf() * TAU
		var spawn_r := r * randf_range(2.2, 2.8)
		var p := c + Vector2(cos(a), sin(a)) * spawn_r
		var to_c := c - p
		var dist := to_c.length()
		if dist < 1.0:
			continue
		var travel := dist - r
		var life := randf_range(0.85, 1.40)
		var spd := maxf(travel, r * 0.4) / life
		var mr := randf_range(4.6, 6.8)
		if charged:
			mr *= 1.28
		_motes.append({
			"p": p,
			"v": to_c / dist * spd,
			"life": life,
			"age": 0.0,
			"r": mr,
			"hot": charged,
		})


func _step_motes(dt: float) -> void:
	var c := _center()
	var body := _radius()
	var keep: Array[Dictionary] = []
	for mote in _motes:
		var age: float = float(mote["age"]) + dt
		if age >= float(mote["life"]):
			continue
		var p: Vector2 = mote["p"]
		p += (mote["v"] as Vector2) * dt
		if p.distance_to(c) <= body:
			continue
		mote["p"] = p
		mote["age"] = age
		keep.append(mote)
	_motes = keep


func _orbit_pt(c: Vector2, r: float, a: float) -> Vector2:
	return c + Vector2(cos(a), sin(a)) * r


func _draw() -> void:
	if size.x < 4.0 or size.y < 4.0:
		return
	var c := _center()
	var r := _radius()
	var fly_lv := Game.level_of("flywheel")
	var fly_u := Game.flywheel_charge_ratio() if fly_lv > 0 else 0.0
	if not compact:
		_draw_motes()
	if fly_lv > 0:
		_draw_flywheel(c, r, fly_u)
	if not compact:
		_draw_relics(c, r)
	_draw_beam_origin(c, r)
	_draw_bits()


func _draw_relics(c: Vector2, r: float) -> void:
	var eq: Array[String] = Game.equipped
	var n := mini(eq.size(), 4)
	if n <= 0:
		return
	var passives: Dictionary = Data.passives()
	var MarkView := preload("res://scripts/mark_view.gd")
	var mark_r := r * 0.16
	var col := _accent()
	for i in n:
		var id: String = eq[i]
		var visual := "spark"
		if passives.has(id):
			visual = str(passives[id].get("visual", "spark"))
		var a := float(i) * TAU * 0.25
		MarkView.paint(self, _orbit_pt(c, r * 1.92, a), mark_r, visual, col)


func _sync_orb() -> void:
	if _orb == null or _orb_mat == null or _glow == null or _glow_mat == null:
		return
	var c := _center()
	var r := _radius()
	if r < 2.0 or size.x < 4.0:
		_orb.visible = false
		_glow.visible = false
		return
	_orb.visible = true
	_glow.visible = true
	var flash := Game.shot_flash if compact else Game.tap_flash
	var fly_u := Game.flywheel_charge_ratio() if Game.level_of("flywheel") > 0 else 0.0
	var col := _accent()
	if fly_u >= 0.8:
		col = col.lerp(_accent_lit(), 0.16)
	if flash > 0.0:
		col = col.lerp(_accent_lit(), flash * 0.22)
	var body_half := r * _BODY_PAD
	_orb.position = c - Vector2(body_half, body_half)
	_orb.size = Vector2(body_half, body_half) * 2.0
	_orb_mat.set_shader_parameter("body_col", col)
	_orb_mat.set_shader_parameter("body_ratio", 1.0 / _BODY_PAD)
	_orb_mat.set_shader_parameter("aa_width", 2.6 / maxf(body_half, 1.0))
	_orb_mat.set_shader_parameter("flash", flash)
	var glow_half := r * _ORB_PAD
	_glow.position = c - Vector2(glow_half, glow_half)
	_glow.size = Vector2(glow_half, glow_half) * 2.0
	_glow_mat.set_shader_parameter("body_col", col)
	_glow_mat.set_shader_parameter("body_ratio", 1.0 / _ORB_PAD)
	_glow_mat.set_shader_parameter("glow_amt", 0.40 + flash * 0.28)
	_glow_mat.set_shader_parameter("aa_width", 2.6 / maxf(glow_half, 1.0))


func _draw_flywheel(c: Vector2, r: float, u: float) -> void:
	var track_r := r * (1.38 if compact else 1.18)
	var thick := 3.2 if compact else 5.4
	var dim := _accent_deep()
	dim.a = 0.32 if compact else 0.40
	draw_arc(c, track_r, 0.0, TAU, 64, dim, thick, false)
	if u <= 0.001:
		return
	var hot := _accent().lerp(_accent_lit(), clampf(u, 0.0, 1.0))
	hot.a = 0.38 + 0.62 * u
	if u >= 0.8:
		draw_arc(c, track_r, 0.0, TAU, 64, hot, thick, false)
		var a := -PI * 0.5 + _t * 2.2
		var mote := c + Vector2(cos(a), sin(a)) * track_r
		var mote_r := 2.2 if compact else 3.6
		draw_circle(mote, mote_r, _accent_lit(), true, -1.0, false)
		draw_circle(mote, mote_r * 0.45, WHITE, true, -1.0, false)
	else:
		var a0 := -PI * 0.5
		var a1 := a0 + TAU * u
		var pts := maxi(8, int(round(64.0 * u)))
		draw_arc(c, track_r, a0, a1, pts, hot, thick, false)


func _draw_beam_origin(c: Vector2, body_r: float) -> void:
	if not Game.beam_on:
		return
	var p := c + Vector2(0.0, -body_r * 0.92)
	draw_circle(p, body_r * 0.10, _accent(), true, -1.0, false)


func _draw_motes() -> void:
	var charged := Game.level_of("flywheel") > 0 and Game.flywheel_charge_ratio() >= 0.8
	for mote in _motes:
		var u := 1.0 - float(mote["age"]) / maxf(float(mote["life"]), 0.001)
		var p: Vector2 = mote["p"]
		var pr := maxf(4.2, float(mote["r"]) * (0.88 + u * 0.12))
		var col := _accent()
		if charged or bool(mote.get("hot", false)):
			col = col.lerp(_accent_lit(), 0.35)
		col.a = 0.55 + u * 0.45
		draw_circle(p, pr, col, true, -1.0, false)


func _draw_bits() -> void:
	for bit in _bits:
		var u := 1.0 - float(bit["age"]) / maxf(float(bit["life"]), 0.001)
		var p: Vector2 = bit["p"]
		var pr := float(bit["r"]) * (0.35 + u * 0.65)
		var col := _accent()
		col.a = u
		draw_circle(p, pr, col, true, -1.0, false)
