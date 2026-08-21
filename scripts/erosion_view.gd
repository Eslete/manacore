extends Control

## Top encroachment. High erosion = anomaly occupies more of the screen.

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_process(true)


func _process(_dt: float) -> void:
	queue_redraw()


func _region_visual() -> String:
	var rid := Game.current_region_id()
	var regs: Dictionary = Data.regions()
	if regs.has(rid):
		return str(regs[rid].get("visual", "sky"))
	return "sky"


func _draw() -> void:
	var h := size.y * Game.erosion
	if h < 2.0:
		return
	var fog := Color(0.04, 0.08, 0.16, 0.28)
	var col := Color(0.35, 0.62, 0.95, 0.18)
	match _region_visual():
		"sky", "orbit":
			fog = Color(0.22, 0.38, 0.58, 0.22)
			col = Color(0.55, 0.78, 0.94, 0.14)
		"atmo":
			fog = Color(0.12, 0.05, 0.03, 0.3)
			col = Color(0.95, 0.5, 0.26, 0.18)
		"sat":
			fog = Color(0.03, 0.07, 0.14, 0.3)
			col = Color(0.42, 0.72, 0.9, 0.16)
		"solar":
			fog = Color(0.14, 0.06, 0.02, 0.28)
			col = Color(1.0, 0.68, 0.22, 0.16)
	var top := Rect2(0.0, 0.0, size.x, h)
	draw_rect(top, fog)
	for i in 7:
		var x := size.x * (0.08 + i * 0.13)
		var hh := h * (0.55 + fmod(i * 1.7, 1.0) * 0.45)
		draw_rect(Rect2(x, 0.0, 7.0, hh), col)
