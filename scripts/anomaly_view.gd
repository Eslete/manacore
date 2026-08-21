class_name AnomalyView
extends Control

## Combat or archive preview. Set preview_id before add_child.

var preview_id := ""
var interactive := false
var extra_spin := 0.0

var _t := 0.0
var _shake := 0.0
var _heal_punch := 0.0
var _shards: Array[Dictionary] = []


func _ready() -> void:
	if interactive:
		mouse_filter = Control.MOUSE_FILTER_STOP
	else:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
	if preview_id == "":
		Game.killed.connect(_on_killed)
	set_process(true)


func _on_killed(_id: String) -> void:
	if preview_id != "":
		return
	_shake = 1.0
	_spawn_kill_shards()
	queue_redraw()


func punch_heal() -> void:
	if preview_id != "":
		return
	_heal_punch = 1.0
	queue_redraw()


func _gui_input(ev: InputEvent) -> void:
	if not interactive:
		return
	if ev is InputEventScreenDrag:
		extra_spin += (ev as InputEventScreenDrag).relative.x * 0.012
	elif ev is InputEventMouseMotion:
		var m := ev as InputEventMouseMotion
		if m.button_mask & MOUSE_BUTTON_MASK_LEFT:
			extra_spin += m.relative.x * 0.012


func aim_local() -> Vector2:
	return size * Vector2(0.5, 0.38) if preview_id == "" else size * 0.5


func _span() -> float:
	return minf(size.x, size.y) * (0.88 if preview_id == "" else 1.0)


func _process(dt: float) -> void:
	_t += dt
	_heal_punch = maxf(0.0, _heal_punch - dt * 2.8)
	if preview_id == "":
		_shake = maxf(0.0, _shake - dt * 2.4)
		_step_shards(dt)
		if Game.alive:
			_shards.clear()
	else:
		_shake = 0.0
		_shards.clear()
	queue_redraw()


func _draw() -> void:
	if preview_id == "" and Game.front_cleared:
		return
	var e: Dictionary
	var preview := preview_id != ""
	if preview:
		e = Data.enemies()[preview_id]
	else:
		e = Game.current_enemy()
	var vis := str(e.get("visual", "shard"))
	var c := aim_local()
	if not preview:
		c += Vector2(sin(_t * 40.0) * _shake * 6.0, 0.0)
		if not Game.alive:
			c += Vector2(8.0, -5.0)
	var dead := 1.0 if preview else (0.62 if not Game.alive else 1.0)
	var cyan := Color(0.22, 0.92, 1.0, 0.85 * dead)
	var ice := Color(0.55, 0.72, 0.92, 0.9 * dead)
	var ink := Color(0.14, 0.08, 0.28, 0.95 * dead)
	var max_hp := maxf(float(e.get("max_integrity", 1.0)), 1.0)
	var spin := extra_spin
	var gp: Dictionary = e.get("gimmick_p", {})

	match vis:
		"shard":
			_draw_shard(c, spin)
		"splinter":
			_draw_splinter(c, spin)
		"polyhedron":
			_draw_polyhedron(c, spin)
		"regen":
			_poly(c, 6, _span() * 0.26, _t * 0.35 + spin, ice, ink)
			var ratio := 1.0 if preview else Game.integrity / max_hp
			draw_arc(c, _span() * 0.32, 0.0, TAU * ratio, 48, cyan, 3.0, true)
		"boss":
			_draw_boss(c, spin, ice, ink, cyan, preview, dead)
		"heal":
			_draw_heal(c, spin, false)
		"heal_boss":
			_draw_heal(c, spin, true)
		"shell":
			_draw_shell(c, spin, ice, ink, cyan, preview, dead)
		"reconstruct":
			_draw_reconstruct(c, spin, preview, dead)
		"fragment":
			_draw_fragment(c, spin, ice, ink, cyan, preview, gp)
		"recurse":
			_draw_recurse(c, spin, ice, ink, gp)
		"compress":
			_draw_compress(c, spin, ice, cyan, preview, dead)
		"needle":
			_draw_needle(c, spin)
		"plate":
			_draw_plate(c, spin)
		"cluster":
			_draw_cluster(c, spin, gp)
		"ring":
			_draw_ring(c, spin)
		_:
			draw_circle(c, 40.0, ice)
	if not preview:
		_draw_hit_flare(c)
	if not preview and not Game.alive:
		_draw_dead_pose(c, ice, cyan, ink)
	_draw_kill_shards()


func _draw_heal(c: Vector2, spin: float, boss: bool) -> void:
	var dead := 1.0 if preview_id != "" else (0.62 if not Game.alive else 1.0)
	var indigo := Color(0.28, 0.10, 0.52, dead)
	var violet := Color(0.72, 0.38, 1.0, dead)
	var white := Color(0.96, 0.98, 1.0, dead)
	var r := _span() * (0.22 if boss else 0.24)
	var pulse := 0.5 + 0.5 * sin(_t * 2.8)
	var rot := _t * 0.4 + spin
	var body_r := r * (0.96 + pulse * 0.05)
	var fill := indigo
	fill.a *= 0.72 + pulse * 0.28
	_poly(c, 6, body_r, rot, fill, violet)
	var mid := violet
	mid.a *= 0.88
	_poly(c + Vector2(-0.14, -0.18) * r, 6, body_r * 0.64, rot, mid, white)
	_poly(c + Vector2(-0.05, -0.07) * r, 6, body_r * 0.28, rot, white, violet)
	var layers := 5 if boss else 2
	for i in layers:
		var rr := r * (1.1 + i * 0.14) * (0.94 + pulse * 0.08)
		var a := (0.22 + pulse * 0.28) * (1.0 - i * 0.12) * dead
		var ring := white if i == 0 else violet
		draw_arc(c, rr, 0.0, TAU, 48, Color(ring.r, ring.g, ring.b, a), 2.0 + (1.2 if boss else 0.0), true)


func _draw_shell(c: Vector2, spin: float, ice: Color, ink: Color, cyan: Color, preview: bool, dead: float) -> void:
	var r := _span() * 0.2
	var rot := _t * 0.3 + spin
	_poly(c, 7, r, rot, ink, ice)
	var sr := 1.0 if preview else Game.shell_ratio()
	var thick := 5.0 + sr * 16.0
	var aa := (0.18 + sr * 0.62) * dead
	draw_arc(c, r * 1.34, 0.0, TAU, 64, Color(0.55, 0.82, 1.0, aa), thick, true)
	draw_arc(c, r * 1.12, 0.0, TAU, 48, Color(cyan.r, cyan.g, cyan.b, aa * 0.5), 2.2, true)
	for i in 7:
		var a := rot + TAU * float(i) / 7.0 - PI / 2.0
		var inner := c + Vector2(cos(a), sin(a)) * r * 1.18
		var outer := c + Vector2(cos(a), sin(a)) * (r * 1.18 + thick * 0.42)
		draw_line(inner, outer, Color(0.96, 0.98, 1.0, aa * 0.7), 2.0, true)


func _draw_boss(c: Vector2, spin: float, ice: Color, ink: Color, cyan: Color, preview: bool, dead: float) -> void:
	if not preview and not Game.has_method("boss_stage"):
		_draw_boss_legacy(c, spin, ice, ink, cyan)
		return
	var stage := -1
	if not preview:
		stage = int(Game.call("boss_stage"))
	var shell_a := dead
	var grid_a := dead
	var core_a := dead
	if preview:
		shell_a *= 0.38
		grid_a *= 0.40
		core_a *= 0.48
	else:
		shell_a *= (1.0 if stage == 0 else 0.18)
		grid_a *= (1.0 if stage == 1 else (0.18 if stage > 1 else 0.36))
		core_a *= (1.0 if stage == 2 else 0.42)
	var base := _span()
	var rot := _t * 0.12 + spin
	var sr := 1.0
	if not preview and Game.has_method("shell_ratio"):
		sr = Game.shell_ratio()
	var cage_col := Color(cyan.r, cyan.g, cyan.b, (0.28 + sr * 0.55) * shell_a)
	var ice_s := Color(ice.r, ice.g, ice.b, 0.7 * shell_a)
	var half := base * 0.30
	_stroke_closed(_ngon(c, 4, half * 1.18, rot), cage_col, 1.8 + sr * 4.5)
	_stroke_closed(_ngon(c, 4, half * 1.18, rot + PI * 0.25), ice_s, 1.4)
	var grid_col := Color(0.55, 0.82, 1.0, 0.42 * shell_a)
	var grid_t := PackedFloat32Array([-0.42, 0.0, 0.42])
	for t in grid_t:
		var u := t * half * 2.0
		draw_line(c + Vector2(-half, u).rotated(rot), c + Vector2(half, u).rotated(rot), grid_col, 1.2, true)
		draw_line(c + Vector2(u, -half).rotated(rot), c + Vector2(u, half).rotated(rot), grid_col, 1.2, true)
	var n := 3
	if not preview and stage >= 1:
		n = maxi(Game.part_count(), 1)
	var slots: Array[Vector2] = [
		Vector2(-1.0, -1.0), Vector2(1.0, -1.0), Vector2(0.0, 1.0),
		Vector2(-1.0, 1.0), Vector2(1.0, 1.0), Vector2(0.0, -1.0),
		Vector2(-1.0, 0.0), Vector2(1.0, 0.0),
	]
	var spacing := base * 0.13
	var face_edge := Color(cyan.r, cyan.g, cyan.b, grid_a)
	var face_fill := Color(ink.r, ink.g, ink.b, 0.35 * grid_a)
	for i in n:
		var slot: Vector2 = slots[i % slots.size()]
		var p := c + slot.rotated(rot) * spacing
		var cell := _ngon(p, 4, base * 0.042, rot)
		_fill_stroke(cell, face_fill, face_edge, 1.5)
		var s := base * 0.028
		draw_line(p + Vector2(-s, 0.0).rotated(rot), p + Vector2(s, 0.0).rotated(rot), face_edge, 1.1, true)
	var core_fill := Color(ink.r, ink.g, ink.b, core_a)
	var core_edge := Color(0.96, 0.98, 1.0, core_a)
	var core_r := base * (0.11 if stage == 2 and not preview else 0.08)
	if stage == 2 and not preview:
		core_fill = Color(0.22, 0.92, 1.0, core_a)
		core_edge = Color(0.96, 0.98, 1.0, core_a)
	_fill_stroke(_rhombus(c, core_r * 0.72, core_r, -rot * 0.4), core_fill, core_edge, 1.8)


func _draw_boss_legacy(c: Vector2, spin: float, ice: Color, ink: Color, cyan: Color) -> void:
	var rot := _t * 0.12 + spin
	var half := _span() * 0.22
	_stroke_closed(_ngon(c, 4, half * 1.2, rot), cyan, 2.0)
	_stroke_closed(_ngon(c, 4, half * 1.2, rot + PI * 0.25), ice, 1.4)
	var grid_t := PackedFloat32Array([-0.4, 0.0, 0.4])
	for t in grid_t:
		var u := t * half * 2.0
		draw_line(c + Vector2(-half, u).rotated(rot), c + Vector2(half, u).rotated(rot), ice, 1.1, true)
		draw_line(c + Vector2(u, -half).rotated(rot), c + Vector2(u, half).rotated(rot), ice, 1.1, true)
	_fill_stroke(_rhombus(c, half * 0.22, half * 0.28, -rot), ink, cyan, 1.6)


func _draw_reconstruct(c: Vector2, spin: float, preview: bool, dead: float) -> void:
	var u := _reconstruct_u(preview)
	var r := _span() * 0.24
	var rot := _t * 0.32 + spin
	var indigo := Color(0.28, 0.10, 0.52, dead)
	var violet := Color(0.72, 0.38, 1.0, dead)
	var cyan := Color(0.22, 0.92, 1.0, dead)
	var white := Color(0.96, 0.98, 1.0, dead)
	_poly(c, 5, r * 0.70, rot, indigo, cyan)
	_poly(c, 4, r * 0.28, -rot * 1.2, violet, white)
	var segs := 5
	var gap := 0.52 * (1.0 - u)
	var ring_r := r * 1.22
	var snap := u > 0.88
	if snap:
		draw_arc(c, ring_r, 0.0, TAU, 64, Color(0.96, 0.98, 1.0, (0.55 + 0.35 * u) * dead), 3.4, true)
		draw_arc(c, ring_r * 0.92, 0.0, TAU, 48, Color(0.72, 0.38, 1.0, 0.42 * dead), 1.6, true)
	else:
		_draw_broken_ring(c, ring_r, segs, gap, rot * 0.4, Color(0.22, 0.92, 1.0, 0.88 * dead), 3.0)
		_draw_broken_ring(c, ring_r * 0.92, segs, gap * 1.15, -rot * 0.25, Color(0.72, 0.38, 1.0, 0.55 * dead), 1.6)
	if u > 0.55 and u < 0.92:
		for i in segs:
			var a := rot * 0.4 + TAU * float(i) / float(segs)
			var p := c + Vector2(cos(a), sin(a)) * ring_r
			draw_circle(p, 2.4 + u * 1.6, Color(0.96, 0.98, 1.0, 0.55 * dead), true, -1.0, true)
	if _heal_punch > 0.0:
		var pk := _heal_punch
		draw_arc(c, r * (0.92 + pk * 0.55), 0.0, TAU, 64, Color(0.96, 0.98, 1.0, 0.62 * pk * dead), 4.2, true)
		draw_arc(c, r * (1.18 + pk * 0.28), 0.0, TAU, 48, Color(0.72, 0.38, 1.0, 0.42 * pk * dead), 2.4, true)
		draw_circle(c, r * 0.20 * (0.7 + pk), Color(0.86, 0.62, 1.0, 0.48 * pk * dead), true, -1.0, true)


func _reconstruct_u(preview: bool) -> float:
	if preview:
		return 0.5 + 0.5 * sin(_t * 1.7)
	if Game.has_method("gap_ratio"):
		return clampf(float(Game.call("gap_ratio")), 0.0, 1.0)
	if Game.has_method("damage_gap"):
		return clampf(float(Game.call("damage_gap")), 0.0, 1.0)
	if Game.has_method("since_hit"):
		return clampf(float(Game.call("since_hit")) / 0.8, 0.0, 1.0)
	var gap_t: Variant = Game.get("gap_t")
	if gap_t != null:
		return clampf(float(gap_t) / 0.8, 0.0, 1.0)
	return 0.5 + 0.5 * sin(_t * 2.1)


func _draw_broken_ring(c: Vector2, radius: float, segs: int, gap: float, rot: float, col: Color, width: float) -> void:
	var slice := TAU / float(maxi(segs, 1))
	var half := gap * 0.5
	for i in segs:
		var a0 := rot + slice * float(i) + half
		var a1 := rot + slice * float(i + 1) - half
		if a1 - a0 > 0.05:
			draw_arc(c, radius, a0, a1, 14, col, width, true)


func _spawn_kill_shards() -> void:
	var c := aim_local()
	var n := 5
	_shards.clear()
	for i in n:
		var a := TAU * float(i) / float(n) + 0.31
		var dir := Vector2(cos(a), sin(a))
		_shards.append({
			"p": c + dir * _span() * 0.10,
			"v": dir * (160.0 + float(i) * 22.0),
			"rot": a,
			"spin": (-1.0 if i % 2 == 0 else 1.0) * 5.2,
			"life": 0.52,
			"age": 0.0,
			"r": _span() * 0.055,
		})


func _step_shards(dt: float) -> void:
	var keep: Array[Dictionary] = []
	for bit in _shards:
		var age: float = float(bit["age"]) + dt
		if age >= float(bit["life"]):
			continue
		var p: Vector2 = bit["p"]
		p += (bit["v"] as Vector2) * dt
		bit["p"] = p
		bit["age"] = age
		bit["rot"] = float(bit["rot"]) + float(bit["spin"]) * dt
		keep.append(bit)
	_shards = keep


func _draw_kill_shards() -> void:
	for bit in _shards:
		var u := 1.0 - float(bit["age"]) / maxf(float(bit["life"]), 0.001)
		var fill := Color(0.28, 0.10, 0.52, u * 0.88)
		var edge := Color(0.22, 0.92, 1.0, u)
		_poly(bit["p"] as Vector2, 4, float(bit["r"]) * (0.45 + u * 0.55), float(bit["rot"]), fill, edge)


func _draw_dead_pose(c: Vector2, ice: Color, cyan: Color, ink: Color) -> void:
	var r := _span() * 0.20
	for i in 5:
		var a := TAU * float(i) / 5.0 + 0.42
		var off := Vector2(cos(a), sin(a)) * r * (0.58 + float(i % 2) * 0.28)
		var fill := ink
		fill.a *= 0.78
		var edge := cyan if i % 2 == 0 else ice
		edge.a *= 0.85
		_poly(c + off, 3 + i % 2, r * (0.18 + float(i % 3) * 0.05), a + 0.55, fill, edge)


func _draw_fragment(c: Vector2, spin: float, ice: Color, ink: Color, cyan: Color, preview: bool, gp: Dictionary) -> void:
	var base := _span()
	var n := 1
	if preview:
		n = maxi(int(gp.get("n", 3)), 2)
	else:
		n = Game.part_count()
	if n <= 1:
		_poly(c, 5, base * 0.22, _t * 0.55 + spin, ice, ink)
		return
	var orbit := base * 0.2
	var pr := base * 0.1
	for i in n:
		var a := _t * 0.45 + spin + TAU * i / n
		var p := c + Vector2(cos(a), sin(a)) * orbit
		_poly(p, 5, pr, -_t * 0.8 + i + spin, ice, cyan)


func _draw_recurse(c: Vector2, spin: float, ice: Color, ink: Color, gp: Dictionary) -> void:
	var r := _span() * 0.26
	var layers := maxi(int(gp.get("n", 3)), 2)
	var rr := r
	for i in layers:
		var fill := ice if i % 2 == 0 else ink
		var edge := ink if i % 2 == 0 else ice
		fill.a *= 1.0 - i * 0.12
		var rot := (_t * 0.3 + spin) * (1.0 if i % 2 == 0 else -1.0)
		_poly(c, 8, rr, rot, fill, edge)
		rr *= 0.55


func _draw_compress(c: Vector2, spin: float, ice: Color, cyan: Color, preview: bool, dead: float) -> void:
	var cmp: float
	if preview:
		cmp = 0.18 + 0.1 * sin(_t * 1.6)
	else:
		cmp = Game.compression()
	var r := _span() * 0.28 * (1.0 - cmp * 0.5)
	var dens := 0.55 + cmp * 0.45
	var fill := Color(
		clampf(ice.r * (0.65 + dens * 0.5), 0.0, 1.0),
		clampf(ice.g * (0.7 + dens * 0.4), 0.0, 1.0),
		clampf(ice.b * (0.85 + dens * 0.2), 0.0, 1.0),
		minf(ice.a * (0.65 + dens * 0.7), 1.0)
	)
	var core := Color(0.78, 0.9, 1.0, minf(0.5 + dens * 0.5, 1.0) * dead)
	_poly(c, 8, r, _t * 0.5 + spin, fill, cyan)
	_poly(c, 4, r * 0.42, -_t * 0.7 + spin, core, ice)


func _tri(center: Vector2, radius: float, rot: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in 3:
		var a := rot + TAU * float(i) / 3.0 - PI / 2.0
		pts.append(center + Vector2(cos(a), sin(a)) * radius)
	return pts


func _elong_tri(center: Vector2, h: float, w: float, rot: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	pts.append(center + Vector2(0.0, -h).rotated(rot))
	pts.append(center + Vector2(w, h * 0.42).rotated(rot))
	pts.append(center + Vector2(-w, h * 0.42).rotated(rot))
	return pts


func _ngon(center: Vector2, sides: int, radius: float, rot: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in sides:
		var a := rot + TAU * float(i) / float(sides) - PI / 2.0
		pts.append(center + Vector2(cos(a), sin(a)) * radius)
	return pts


func _rhombus(center: Vector2, hw: float, hh: float, rot: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	pts.append(center + Vector2(0.0, -hh).rotated(rot))
	pts.append(center + Vector2(hw, 0.0).rotated(rot))
	pts.append(center + Vector2(0.0, hh).rotated(rot))
	pts.append(center + Vector2(-hw, 0.0).rotated(rot))
	return pts


func _crystal_quad(center: Vector2, r: float, rot: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	pts.append(center + Vector2(0.0, -r * 1.18).rotated(rot))
	pts.append(center + Vector2(r * 0.82, r * 0.14).rotated(rot))
	pts.append(center + Vector2(-r * 0.16, r * 0.92).rotated(rot))
	pts.append(center + Vector2(-r * 0.78, -r * 0.10).rotated(rot))
	return pts


func _flat_hex(center: Vector2, rx: float, ry: float, rot: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in 6:
		var a := TAU * float(i) / 6.0 - PI / 2.0
		pts.append(center + Vector2(cos(a) * rx, sin(a) * ry).rotated(rot))
	return pts


func _chip(center: Vector2, r: float, rot: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	pts.append(center + Vector2(r * 0.15, -r * 0.72).rotated(rot))
	pts.append(center + Vector2(r * 0.88, r * 0.08).rotated(rot))
	pts.append(center + Vector2(-r * 0.22, r * 0.70).rotated(rot))
	pts.append(center + Vector2(-r * 0.70, -r * 0.18).rotated(rot))
	return pts


func _rod(center: Vector2, length: float, width: float, rot: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	var h := length * 0.5
	var w := width * 0.5
	pts.append(center + Vector2(-w, -h).rotated(rot))
	pts.append(center + Vector2(w, -h).rotated(rot))
	pts.append(center + Vector2(w, h).rotated(rot))
	pts.append(center + Vector2(-w, h).rotated(rot))
	return pts


func _kite(center: Vector2, h: float, w: float, rot: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	pts.append(center + Vector2(0.0, -h).rotated(rot))
	pts.append(center + Vector2(w, h * 0.12).rotated(rot))
	pts.append(center + Vector2(0.0, h * 0.82).rotated(rot))
	pts.append(center + Vector2(-w, h * 0.12).rotated(rot))
	return pts


func _fill_stroke(pts: PackedVector2Array, fill: Color, edge: Color, width: float) -> void:
	if pts.size() < 3:
		return
	draw_colored_polygon(pts, fill)
	_stroke_closed(pts, edge, width)


func _stroke_closed(pts: PackedVector2Array, col: Color, width: float) -> void:
	if pts.size() < 2:
		return
	var loop := PackedVector2Array(pts)
	loop.append(pts[0])
	draw_polyline(loop, col, width, true)


func _draw_needle(c: Vector2, spin: float) -> void:
	var dead := 1.0 if preview_id != "" else (0.62 if not Game.alive else 1.0)
	var h := _span() * 0.42
	var w := _span() * 0.048
	var rot := _t * 0.16 + spin
	var indigo := Color(0.28, 0.10, 0.52, dead)
	var cyan := Color(0.22, 0.92, 1.0, dead)
	_fill_stroke(_rhombus(c, w, h, rot), indigo, cyan, 1.7)


func _draw_cluster(c: Vector2, spin: float, gp: Dictionary) -> void:
	var dead := 1.0 if preview_id != "" else (0.62 if not Game.alive else 1.0)
	var n := maxi(int(gp.get("n", 5)), 1)
	var base := _span()
	var indigo := Color(0.28, 0.10, 0.52, dead)
	var cyan := Color(0.22, 0.92, 1.0, dead)
	var ice := Color(0.55, 0.72, 0.92, dead)
	var positions: Array[Vector2] = []
	for i in n:
		var a := _t * 0.28 + spin + TAU * float(i) / float(n)
		var orbit := base * (0.15 + 0.038 * float(i % 3))
		positions.append(c + Vector2(cos(a), sin(a)) * orbit)
	var web := Color(0.22, 0.92, 1.0, 0.20 * dead)
	var web_far := Color(0.55, 0.82, 1.0, 0.08 * dead)
	for i in n:
		draw_line(positions[i], positions[(i + 1) % n], web, 1.0, true)
		if n > 2:
			draw_line(positions[i], positions[(i + 2) % n], web_far, 1.0, true)
	var pr := base * 0.058
	for i in n:
		var p: Vector2 = positions[i]
		var rot := _t * 0.22 + float(i) * 0.65 + spin
		match i % 5:
			0:
				_fill_stroke(_rhombus(p, pr * 1.15, pr * 0.38, rot), indigo, cyan, 1.2)
			1:
				_fill_stroke(_chip(p, pr * 0.92, rot), indigo, ice, 1.2)
			2:
				_fill_stroke(_rod(p, pr * 1.55, pr * 0.32, rot), indigo, cyan, 1.2)
			3:
				_fill_stroke(_kite(p, pr * 1.12, pr * 0.55, rot), indigo, ice, 1.2)
			_:
				var tip := p + Vector2(0.0, -pr * 0.85).rotated(rot)
				var left := p + Vector2(-pr * 0.9, pr * 0.5).rotated(rot)
				var right := p + Vector2(pr * 0.9, pr * 0.5).rotated(rot)
				draw_line(tip, left, cyan, 1.8, true)
				draw_line(tip, right, cyan, 1.8, true)


func _draw_ring(c: Vector2, spin: float) -> void:
	var dead := 1.0 if preview_id != "" else (0.62 if not Game.alive else 1.0)
	var r1 := _span() * 0.24
	var r2 := _span() * 0.32
	var cyan := Color(0.22, 0.92, 1.0, 0.88 * dead)
	var ice := Color(0.55, 0.82, 1.0, 0.50 * dead)
	var white := Color(0.96, 0.98, 1.0, dead)
	_stroke_ring(c, r1, cyan, 2.6)
	_stroke_ring(c, r2, ice, 1.7)
	var a := _t * 0.85 + spin
	var bead_r := (r1 + r2) * 0.5
	var bead := c + Vector2(cos(a), sin(a)) * bead_r
	draw_circle(bead, 5.0, white, true, -1.0, false)
	draw_circle(bead, 2.2, Color(0.22, 0.92, 1.0, dead), true, -1.0, false)


func _stroke_tri(pts: PackedVector2Array, col: Color, width: float) -> void:
	draw_line(pts[0], pts[1], col, width, true)
	draw_line(pts[1], pts[2], col, width, true)
	draw_line(pts[2], pts[0], col, width, true)


func _draw_shard(c: Vector2, spin: float) -> void:
	var flash := 0.0 if preview_id != "" else Game.shot_flash
	var dead := 1.0 if preview_id != "" else (0.62 if not Game.alive else 1.0)
	var r := _span() * 0.22 * (1.0 + flash * 0.10)
	var rot := _t * 0.35 + spin
	var indigo := Color(0.28, 0.10, 0.52, dead)
	var cyan := Color(0.22, 0.92, 1.0, dead)
	var body := _crystal_quad(c, r, rot)
	_fill_stroke(body, indigo, cyan, 1.7)
	var a := _t * 0.75 + spin
	var p := c + Vector2(cos(a), sin(a)) * r * 1.36
	_fill_stroke(_rhombus(p, r * 0.11, r * 0.06, a + 0.4), Color(0.16, 0.06, 0.36, dead), cyan, 1.1)
	if flash > 0.22:
		_stroke_closed(body, Color(0.96, 0.98, 1.0, flash * dead), 2.4)


func _draw_splinter(c: Vector2, spin: float) -> void:
	var dead := 1.0 if preview_id != "" else (0.62 if not Game.alive else 1.0)
	var r := _span() * 0.155
	var rot := _t * 0.28 + spin
	var indigo := Color(0.28, 0.10, 0.52, dead)
	var cyan := Color(0.22, 0.92, 1.0, dead)
	var ice := Color(0.55, 0.72, 0.92, dead)
	_fill_stroke(_rhombus(c, r * 1.38, r * 0.26, rot), indigo, cyan, 1.5)
	var off := Vector2(r * 0.08, r * 0.28).rotated(rot)
	_fill_stroke(_rhombus(c + off, r * 1.12, r * 0.16, rot), ice, cyan, 1.2)


func _draw_polyhedron(c: Vector2, spin: float) -> void:
	var preview := preview_id != ""
	var dead := 1.0 if preview else (0.62 if not Game.alive else 1.0)
	var r := _span() * 0.20
	var rot := _t * 0.18 + spin
	var indigo := Color(0.28, 0.10, 0.52, dead)
	var cyan := Color(0.22, 0.92, 1.0, dead)
	var ice := Color(0.55, 0.72, 0.92, dead)
	var verts := _ngon(c, 6, r, rot)
	_fill_stroke(verts, indigo, cyan, 1.8)
	if verts.size() >= 6:
		draw_line(verts[0], verts[2], Color(ice.r, ice.g, ice.b, 0.55 * dead), 1.3, true)
		draw_line(verts[2], verts[4], Color(ice.r, ice.g, ice.b, 0.45 * dead), 1.2, true)
		draw_line(verts[1], verts[4], Color(cyan.r, cyan.g, cyan.b, 0.35 * dead), 1.1, true)
	var sr := 1.0 if preview else Game.shell_ratio()
	var thick := 2.2 + sr * 12.0
	var aa := (0.12 + sr * 0.62) * dead
	var start := rot + 0.35
	draw_arc(c, r * 1.24, start, start + TAU * 0.58, 40, Color(0.22, 0.92, 1.0, aa), thick, true)


func _draw_plate(c: Vector2, spin: float) -> void:
	var preview := preview_id != ""
	var dead := 1.0 if preview else (0.62 if not Game.alive else 1.0)
	var rx := _span() * 0.34
	var ry := _span() * 0.125
	var rot := sin(_t * 0.35) * 0.07 + spin * 0.18
	var indigo := Color(0.28, 0.10, 0.52, dead)
	var cyan := Color(0.22, 0.92, 1.0, dead)
	var body := _flat_hex(c, rx, ry, rot)
	_fill_stroke(body, indigo, cyan, 1.6)
	var sr := 1.0 if preview else Game.shell_ratio()
	var thick := 2.6 + sr * 13.0
	var aa := (0.16 + sr * 0.62) * dead
	_stroke_closed(_flat_hex(c, rx * 1.06, ry * 1.22, rot), Color(0.55, 0.82, 1.0, aa), thick)


static func burst_k(cd: float, max_cd: float, vis: float) -> float:
	if cd <= 0.0:
		return 0.0
	var age := max_cd - cd
	if age < 0.0 or age >= vis:
		return 0.0
	return 1.0 - age / vis


static func paint_beam(ci: CanvasItem, from: Vector2, to: Vector2, t: float) -> void:
	var dir := to - from
	var len := dir.length()
	if len < 2.0:
		return
	dir /= len
	var wob := Vector2(-dir.y, dir.x) * sin(t * 16.0) * 1.1
	var a := from + wob
	var b := to + wob * 0.25
	ci.draw_line(a, b, Color(0.62, 0.28, 1.0, 0.22), 5.0, true)
	ci.draw_line(a, b, Color(0.55, 0.82, 1.0, 0.55), 2.4, true)
	ci.draw_line(a, b, Color(0.96, 0.98, 1.0, 0.88), 1.15, true)
	var u := fmod(t * 2.4, 1.0)
	var bead := a.lerp(b, u)
	ci.draw_circle(bead, 2.6, Color(0.9, 0.95, 1.0, 0.55))
	ci.draw_circle(to, 5.5, Color(0.72, 0.42, 1.0, 0.22))
	ci.draw_circle(to, 2.4, Color(0.95, 0.98, 1.0, 0.7))


static func paint_lance(ci: CanvasItem, from: Vector2, to: Vector2, k: float) -> void:
	var dir := to - from
	var len := dir.length()
	if len < 2.0:
		return
	dir /= len
	var a := from
	var b := to + dir * 28.0
	ci.draw_line(a, b, Color(0.7, 0.35, 1.0, 0.28 * k), 6.0, true)
	ci.draw_line(a, b, Color(0.75, 0.9, 1.0, 0.7 * k), 2.6, true)
	ci.draw_line(a, b, Color(1.0, 1.0, 1.0, 0.95 * k), 1.2, true)
	ci.draw_circle(to, 7.0 * k, Color(0.92, 0.96, 1.0, 0.45 * k))


static func paint_prism(ci: CanvasItem, from: Vector2, to: Vector2, k: float) -> void:
	var dir := to - from
	var reach := dir.length()
	if reach < 2.0:
		return
	var base_ang := dir.angle()
	for i in 5:
		var ang := base_ang + float(i - 2) * 0.18
		var hit := from + Vector2(cos(ang), sin(ang)) * reach
		ci.draw_line(from, hit, Color(0.58, 0.38, 1.0, 0.2 * k), 3.2, true)
		ci.draw_line(from, hit, Color(0.82, 0.94, 1.0, 0.62 * k), 1.35, true)
		ci.draw_circle(hit, 3.4, Color(0.7, 0.45, 1.0, 0.35 * k))
		ci.draw_circle(hit, 1.6, Color(1.0, 1.0, 1.0, 0.8 * k))


static func paint_collapse(ci: CanvasItem, at: Vector2, k: float, t: float) -> void:
	var u := 1.0 - k
	var base := 120.0
	for i in 3:
		var rr := base * (1.12 - u * 0.82) * (1.0 - float(i) * 0.2)
		var aa := (0.4 - float(i) * 0.08) * k
		ci.draw_arc(at, maxf(rr, 2.0), 0.0, TAU, 28, Color(0.68, 0.28, 1.0, aa), 2.1, true)
	ci.draw_circle(at, base * 0.1 * (0.7 + k), Color(0.95, 0.9, 1.0, 0.5 * k))
	for i in 6:
		var a := TAU * float(i) / 6.0 + t * 0.4
		var outer := at + Vector2(cos(a), sin(a)) * base * (0.85 - u * 0.45)
		ci.draw_line(outer, at, Color(0.78, 0.55, 1.0, 0.28 * k), 1.2, true)


static func paint_horizon(ci: CanvasItem, y: float, width: float, col: Color) -> void:
	var cx := 0.0
	if ci is Control:
		cx = (ci as Control).size.x * 0.5
	var half := width * 0.5
	var pts := PackedVector2Array()
	var n := 8
	for i in n + 1:
		var u := float(i) / float(n)
		var x := cx - half + width * u
		var bulge := 8.0 * 4.0 * u * (1.0 - u)
		pts.append(Vector2(x, y + bulge))
	ci.draw_polyline(pts, col, 1.5, true)


func _draw_hit_flare(c: Vector2) -> void:
	var flash := Game.shot_flash
	if flash < 0.22:
		return
	var r := _span() * 0.22
	var k := clampf((flash - 0.22) / 0.78, 0.0, 1.0)
	var cyan := Color(0.22, 0.92, 1.0, 0.92 * k)
	var white := Color(0.96, 0.98, 1.0, 0.95 * k)
	_stroke_ring(c, r * (0.72 + k * 0.85), white, 5.0)
	_stroke_ring(c, r * (1.05 + k * 0.55), cyan, 3.2)
	draw_circle(c, r * (0.16 + k * 0.22), Color(0.22, 0.92, 1.0, 0.55 * k))
	draw_circle(c, r * (0.08 + k * 0.10), Color(0.96, 0.98, 1.0, 0.88 * k))
	for i in 6:
		var a := TAU * float(i) / 6.0 + _t * 2.4
		var inner := c + Vector2(cos(a), sin(a)) * r * 0.18
		var outer := c + Vector2(cos(a), sin(a)) * r * (0.95 + k * 0.55)
		draw_line(inner, outer, Color(0.96, 0.98, 1.0, 0.75 * k), 3.0, false)


func _stroke_ring(c: Vector2, radius: float, col: Color, width: float) -> void:
	var pts := PackedVector2Array()
	var n := 28
	for i in n + 1:
		var a := TAU * float(i) / float(n)
		pts.append(c + Vector2(cos(a), sin(a)) * radius)
	draw_polyline(pts, col, width, false)


static func paint_shooter(ci: CanvasItem, from: Vector2, to: Vector2, u: float) -> void:
	if from.distance_to(to) < 2.0:
		return
	var cyan_deep := Color(0.08, 0.46, 0.70)
	var cyan := Color(0.22, 0.92, 1.0)
	var white := Color(0.96, 0.98, 1.0)
	u = clampf(u, 0.0, 1.0)
	var p := from.lerp(to, u)
	var trail_from := from.lerp(to, maxf(0.0, u - 0.22))
	if trail_from.distance_to(p) >= 1.0:
		ci.draw_line(trail_from, p, Color(0.22, 0.92, 1.0, 0.92), 18.0, false)
		ci.draw_line(trail_from, p, Color(0.96, 0.98, 1.0, 0.95), 8.0, false)
	ci.draw_circle(p, 18.0, cyan_deep, true, -1.0, false)
	ci.draw_circle(p, 12.0, cyan, true, -1.0, false)
	ci.draw_circle(p, 6.0, white, true, -1.0, false)
	if u < 0.28:
		var mk := 1.0 - u / 0.28
		ci.draw_circle(from, 22.0 * mk, Color(0.22, 0.92, 1.0, 0.72 * mk), true, -1.0, false)
		ci.draw_circle(from, 11.0 * mk, Color(0.96, 0.98, 1.0, 0.95 * mk), true, -1.0, false)
	if u > 0.78:
		var ik := (u - 0.78) / 0.22
		ci.draw_circle(to, 28.0 * ik, Color(0.22, 0.92, 1.0, 0.45 * ik), true, -1.0, false)
		ci.draw_circle(to, 14.0 * ik, Color(0.96, 0.98, 1.0, 0.72 * ik), true, -1.0, false)
		for i in 5:
			var a := TAU * float(i) / 5.0
			var tip := to + Vector2(cos(a), sin(a)) * (18.0 + ik * 16.0)
			ci.draw_line(to, tip, Color(0.96, 0.98, 1.0, 0.8 * ik), 3.0, false)


func _poly(center: Vector2, sides: int, radius: float, rot: float, fill: Color, edge: Color) -> void:
	var pts := PackedVector2Array()
	for i in sides:
		var a := rot + TAU * i / sides - PI / 2.0
		pts.append(center + Vector2(cos(a), sin(a)) * radius)
	draw_colored_polygon(pts, fill)
	pts.append(pts[0])
	draw_polyline(pts, edge, 2.5, true)
