extends Control

## Combat overlay. Draws bolts in _draw so the mobile renderer cannot drop a signal-only Control.

const BOLT_DUR := 0.28

var core_node: Control
var anomaly_node: Control
var _fx_t := 0.0
var _bolts: Array[Dictionary] = []


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	clip_contents = false
	z_index = 4
	if not Game.shot.is_connected(_on_shot):
		Game.shot.connect(_on_shot)


func _on_shot(ok: bool) -> void:
	if not ok:
		return
	_bolts.clear()
	_bolts.append({"age": 0.0, "dur": BOLT_DUR})


func _process(dt: float) -> void:
	_age_bolts(dt)
	if not is_visible_in_tree():
		return
	_fx_t += dt
	queue_redraw()


func _age_bolts(dt: float) -> void:
	if _bolts.is_empty():
		return
	var keep: Array[Dictionary] = []
	for b in _bolts:
		var age: float = float(b["age"]) + dt
		if age >= float(b["dur"]):
			continue
		b["age"] = age
		keep.append(b)
	_bolts = keep


func _draw() -> void:
	if size.x < 4.0 or size.y < 4.0:
		return
	var accent := _accent()
	AnomalyView.paint_horizon(self, size.y * 0.72, size.x * 0.62, Color(accent.r, accent.g, accent.b, 0.20))
	var ends := _shot_ends()
	var from: Vector2 = ends[0]
	var to: Vector2 = ends[1]
	for b in _bolts:
		var dur: float = float(b["dur"])
		var u := 1.0 if dur <= 0.0 else clampf(float(b["age"]) / dur, 0.0, 1.0)
		AnomalyView.paint_shooter(self, from, to, u)
	if Game.beam_on and Game.alive:
		AnomalyView.paint_beam(self, from, to, _fx_t)
	var lance_k := AnomalyView.burst_k(Game.lance_cd, 2.4, 0.28)
	if lance_k > 0.0:
		AnomalyView.paint_lance(self, from, to, lance_k)
	var prism_k := AnomalyView.burst_k(Game.prism_cd, 1.6, 0.34)
	if prism_k > 0.0:
		AnomalyView.paint_prism(self, from, to, prism_k)
	var collapse_k := AnomalyView.burst_k(Game.collapse_cd, 2.2, 0.42)
	if collapse_k > 0.0:
		AnomalyView.paint_collapse(self, to, collapse_k, _fx_t)


func _shot_ends() -> Array[Vector2]:
	var from := Vector2(size.x * 0.5, size.y * 0.90)
	var to := Vector2(size.x * 0.5, size.y * 0.22)
	if core_node != null and is_instance_valid(core_node) and core_node.size.y > 4.0 and core_node.has_method("aim_local"):
		var aim: Vector2 = core_node.call("aim_local")
		from = core_node.global_position + aim - global_position
	if anomaly_node != null and is_instance_valid(anomaly_node) and anomaly_node.size.y > 4.0 and anomaly_node.has_method("aim_local"):
		var aim: Vector2 = anomaly_node.call("aim_local")
		to = anomaly_node.global_position + aim - global_position
	if from.distance_to(to) < 48.0:
		from = Vector2(size.x * 0.5, size.y * 0.90)
		to = Vector2(size.x * 0.5, size.y * 0.22)
	return [from, to]


func _accent() -> Color:
	if str(Game.tier) == "violet":
		return Color(0.82, 0.42, 1.0)
	return Color(0.4, 0.88, 1.0)
