extends Control

const _CoreView := preload("res://scripts/core_view.gd")
const _FxView := preload("res://scripts/fx_view.gd")

@onready var _anomaly: AnomalyView
@onready var _core: _CoreView
@onready var _fx: Control
@onready var _space_bg: Control
@onready var _erosion: Control

var _screens: Dictionary = {}
var _region_l: Label
var _name_l: Label
var _stab_bar: Control
var _chip_l: Label
var _mana_l: Label
var _rate_l: Label
var _pulse_b: Button
var _weapon_chip_row: HBoxContainer
var _shoot_chip: Button
var _lance_chip: Button
var _prism_chip: Button
var _collapse_chip: Button
var _tab_buttons: Dictionary = {}
var _tab := "core"
var _flash := 0.0
var _mana_flash := 0.0
var _stab_pulse := 0.0
var _deny_t := 0.0
var _tap_pop: Label
var _tap_pop_t := 0.0

var _core_mana: Label
var _core_prod: Label
var _core_scroll: ScrollContainer
var _core_dock: VBoxContainer
var _core_btns: Dictionary = {}
var _ascend_b: Button
var _core_discharge_b: Button
var _anomaly_discharge_b: Button

var _relic_title: Label
var _relic_id := ""
var _relic_scroll: ScrollContainer
var _relic_layer: Control
var _relic_inspect: Control
var _relic_inspect_close: Button
var _relic_inspect_name: Label
var _relic_inspect_info: Label
var _relic_inspect_action: Button
var _relic_inspect_mark: Control
var _relic_inspect_visual := ""

var _space_map: Control
var _space_dots: Dictionary = {}
var _reset_dlg: ConfirmationDialog

var _archive_scroll: ScrollContainer
var _archive_layer: Control
var _archive_id := ""
var _archive_title: Label
var _inspect: Control
var _inspect_name: Label
var _inspect_info: Label
var _inspect_close: Button


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_build()
	Game.changed.connect(_refresh)
	Game.killed.connect(func(_id):
		_flash = 1.0
		if _tab == "archive":
			call_deferred("_layout_archive")
	)
	Game.tapped.connect(_on_tapped)
	Game.shot.connect(_on_shot)
	Game.gap_healed.connect(_on_gap_healed)
	_goto("core")
	_refresh()


func _process(dt: float) -> void:
	_flash = maxf(0.0, _flash - dt * 1.6)
	_mana_flash = maxf(0.0, _mana_flash - dt * 4.0)
	_stab_pulse = maxf(0.0, _stab_pulse - dt * 3.2)
	_deny_t = maxf(0.0, _deny_t - dt * 2.6)
	_sync_mana_flash()
	if _tab == "anomaly":
		if _stab_bar:
			_stab_bar.queue_redraw()
		if Game.weapon_unlocked("beam"):
			if Game.beam_on:
				_pulse_b.modulate = Color(0.75, 1.0, 1.0)
			elif _beam_ready():
				_pulse_b.modulate = Color.WHITE
			else:
				_pulse_b.modulate = Color(0.55, 0.6, 0.66)
		else:
			_pulse_b.modulate = _shooter_arm_modulate()
		_sync_weapon_chips()
	elif _tab == "core":
		_sync_core_devices()
		if _tap_pop_t > 0.0:
			_tap_pop_t = maxf(0.0, _tap_pop_t - dt)
			if _tap_pop:
				_tap_pop.modulate.a = clampf(_tap_pop_t / 0.8, 0.0, 1.0)
				_tap_pop.visible = _tap_pop_t > 0.0
	elif _tab == "space":
		_space_map.queue_redraw()


func _set_cap(b: Button, t: String) -> void:
	var cap := b.find_child("Cap", true, false)
	if cap is Label:
		(cap as Label).text = t


func _build() -> void:
	_space_bg = Control.new()
	_space_bg.set_script(load("res://scripts/space_view.gd"))
	_space_bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_space_bg)

	_erosion = Control.new()
	_erosion.set_script(load("res://scripts/erosion_view.gd"))
	_erosion.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_erosion)

	var root := VBoxContainer.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.offset_left = 16
	root.offset_top = 28
	root.offset_right = -16
	root.offset_bottom = -10
	root.add_theme_constant_override("separation", 8)
	add_child(root)

	var stage := Control.new()
	stage.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(stage)

	_screens["anomaly"] = _make_combat()
	_screens["core"] = _make_core_screen()
	_screens["relics"] = _make_relics_screen()
	_screens["space"] = _make_space_screen()
	_screens["archive"] = _make_archive_screen()
	for id in _screens:
		var s: Control = _screens[id]
		s.set_anchors_preset(Control.PRESET_FULL_RECT)
		s.visible = false
		stage.add_child(s)

	var tabs := HBoxContainer.new()
	tabs.add_theme_constant_override("separation", 6)
	root.add_child(tabs)
	for pair in [
		["core", "CORE"],
		["anomaly", "ANOMALY"],
		["relics", "RELICS"],
		["space", "SPACE"],
		["archive", "ARCHIVE"],
	]:
		var b := _ghost_btn(str(pair[1]))
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.add_theme_font_size_override("font_size", 13)
		b.custom_minimum_size = Vector2(0, 44)
		var id := str(pair[0])
		b.pressed.connect(func():
			_goto(id)
		)
		tabs.add_child(b)
		_tab_buttons[id] = b


func _make_combat() -> Control:
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 10)
	var top := VBoxContainer.new()
	top.add_theme_constant_override("separation", 4)
	root.add_child(top)
	_region_l = _label("", 13, Color(0.7, 0.8, 0.9))
	top.add_child(_region_l)
	_name_l = _label("—", 24, Color(0.94, 0.97, 1.0))
	top.add_child(_name_l)
	_stab_bar = Control.new()
	_stab_bar.custom_minimum_size = Vector2(0, 8)
	_stab_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_stab_bar.draw.connect(_draw_stab)
	top.add_child(_stab_bar)
	_chip_l = _label("", 13, Color(0.78, 0.84, 0.9))
	_chip_l.visible = false
	top.add_child(_chip_l)

	var world := Control.new()
	world.size_flags_vertical = Control.SIZE_EXPAND_FILL
	world.clip_contents = false
	root.add_child(world)

	_anomaly = AnomalyView.new()
	_anomaly.custom_minimum_size = Vector2(0, 160)
	_anomaly.z_index = 0
	_anomaly.clip_contents = false
	_anomaly.modulate = Color(0.78, 0.80, 0.88)
	world.add_child(_anomaly)
	_anchor_band(_anomaly, 0.0, 0.56)

	_core = _CoreView.new()
	_core.custom_minimum_size = Vector2(0, 56)
	_core.z_index = 2
	_core.compact = true
	_core.clip_contents = false
	world.add_child(_core)
	_anchor_band(_core, 0.82, 1.0)

	var fx := _FxView.new()
	fx.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fx.z_index = 4
	fx.clip_contents = false
	world.add_child(fx)
	_anchor_band(fx, 0.0, 1.0)
	fx.core_node = _core
	fx.anomaly_node = _anomaly
	_fx = fx

	var dock := VBoxContainer.new()
	dock.add_theme_constant_override("separation", 8)
	root.add_child(dock)
	var stats := HBoxContainer.new()
	dock.add_child(stats)
	_mana_l = _label("0", 20, Color(0.55, 0.92, 1.0))
	_mana_l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stats.add_child(_mana_l)
	_rate_l = _label("+0/s", 15, Color(0.7, 0.82, 0.9))
	_rate_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	stats.add_child(_rate_l)

	_weapon_chip_row = HBoxContainer.new()
	_weapon_chip_row.add_theme_constant_override("separation", 6)
	_weapon_chip_row.custom_minimum_size = Vector2(0, 40)
	_weapon_chip_row.visible = false
	_shoot_chip = _chip_btn("사격 시작")
	_lance_chip = _chip_btn("창")
	_prism_chip = _chip_btn("프리즘")
	_collapse_chip = _chip_btn("붕괴")
	_shoot_chip.pressed.connect(_press_shooter)
	_lance_chip.pressed.connect(func(): Game.fire_lance())
	_prism_chip.pressed.connect(func(): Game.fire_prism())
	_collapse_chip.pressed.connect(func(): Game.fire_collapse())
	_weapon_chip_row.add_child(_shoot_chip)
	_weapon_chip_row.add_child(_lance_chip)
	_weapon_chip_row.add_child(_prism_chip)
	_weapon_chip_row.add_child(_collapse_chip)
	dock.add_child(_weapon_chip_row)

	_anomaly_discharge_b = _chip_btn("연속 방전")
	_anomaly_discharge_b.visible = false
	_anomaly_discharge_b.pressed.connect(func(): Game.try_research_discharge())
	dock.add_child(_anomaly_discharge_b)

	_pulse_b = _shoot_btn()
	_pulse_b.button_down.connect(func():
		if Game.weapon_unlocked("beam"):
			Game.set_beam(true)
	)
	_pulse_b.button_up.connect(func():
		if Game.weapon_unlocked("beam"):
			Game.set_beam(false)
	)
	_pulse_b.pressed.connect(func():
		if not Game.weapon_unlocked("beam"):
			_press_shooter()
	)
	dock.add_child(_pulse_b)
	return root


func _make_core_screen() -> Control:
	var root := Control.new()
	var view := Control.new()
	view.set_anchors_preset(Control.PRESET_FULL_RECT)
	view.set_script(load("res://scripts/core_view.gd"))
	root.add_child(view)

	var tap := Button.new()
	_clear_btn(tap)
	tap.set_anchors_preset(Control.PRESET_FULL_RECT)
	tap.pressed.connect(func(): Game.tap_core())
	root.add_child(tap)

	_tap_pop = _label("", 22, Color(0.72, 1.0, 0.95))
	_tap_pop.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_tap_pop.visible = false
	_tap_pop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(_tap_pop)

	_core_mana = _label("0", 28, Color(0.55, 0.92, 1.0))
	_core_mana.set_anchors_preset(Control.PRESET_TOP_WIDE)
	_core_mana.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_core_mana.offset_top = 8
	_core_mana.offset_left = 88
	_core_mana.offset_right = -88
	root.add_child(_core_mana)
	_core_prod = _label("+0/s", 14, Color(0.7, 0.82, 0.9))
	_core_prod.set_anchors_preset(Control.PRESET_TOP_WIDE)
	_core_prod.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_core_prod.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_core_prod.offset_top = 42
	_core_prod.offset_bottom = 78
	_core_prod.offset_left = 88
	_core_prod.offset_right = -88
	root.add_child(_core_prod)

	_core_scroll = ScrollContainer.new()
	_core_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_core_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	_core_scroll.mouse_filter = Control.MOUSE_FILTER_STOP
	_core_scroll.z_index = 8
	root.add_child(_core_scroll)
	_core_dock = VBoxContainer.new()
	_core_dock.add_theme_constant_override("separation", 8)
	_core_dock.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_core_dock.mouse_filter = Control.MOUSE_FILTER_STOP
	_core_scroll.add_child(_core_dock)
	_core_btns.clear()
	for group in Data.generator_groups():
		if typeof(group) != TYPE_DICTIONARY:
			continue
		var g: Dictionary = group
		var title_text := str(g.get("title", ""))
		if title_text != "":
			_core_dock.add_child(_group_title(title_text))
		var ids = g.get("ids", [])
		for raw_id in ids:
			var id := str(raw_id)
			if id == "" or not Data.upgrades().has(id):
				continue
			var b := _device_btn(id)
			var captured := id
			b.pressed.connect(func(): Game.try_upgrade(captured))
			_core_dock.add_child(b)
			_core_btns[id] = b

	_ascend_b = _ghost_btn("위계")
	_ascend_b.visible = false
	_ascend_b.disabled = true
	_ascend_b.custom_minimum_size = Vector2(200, 48)
	_ascend_b.z_index = 8
	root.add_child(_ascend_b)
	_ascend_b.pressed.connect(func(): Game.try_ascend())

	_core_discharge_b = _ghost_btn("연속 방전")
	_core_discharge_b.visible = false
	_core_discharge_b.disabled = true
	_core_discharge_b.custom_minimum_size = Vector2(200, 40)
	_core_discharge_b.z_index = 8
	root.add_child(_core_discharge_b)
	_core_discharge_b.pressed.connect(func(): Game.try_research_discharge())

	var save := _ghost_btn("저장")
	save.custom_minimum_size = Vector2(72, 36)
	save.pressed.connect(func(): Game.save_game())
	root.add_child(save)
	save.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	save.offset_left = -80
	save.offset_right = -8
	save.offset_top = 8
	save.offset_bottom = 44
	var reset := _ghost_btn("초기화")
	reset.custom_minimum_size = Vector2(72, 36)
	reset.pressed.connect(_confirm_reset)
	root.add_child(reset)
	reset.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	reset.offset_left = -80
	reset.offset_right = -8
	reset.offset_top = 44
	reset.offset_bottom = 80
	_reset_dlg = ConfirmationDialog.new()
	_reset_dlg.title = "초기화"
	_reset_dlg.dialog_text = "진행을 지울까요?"
	_reset_dlg.ok_button_text = "초기화"
	_reset_dlg.cancel_button_text = "취소"
	_reset_dlg.confirmed.connect(func(): Game.reset_game())
	root.add_child(_reset_dlg)
	root.resized.connect(_layout_core_devices)
	return root


func _make_relics_screen() -> Control:
	var root := Control.new()
	_relic_title = _label("RELICS", 18, Color(0.7, 0.8, 0.9))
	_relic_title.set_anchors_preset(Control.PRESET_TOP_WIDE)
	_relic_title.offset_bottom = 28
	root.add_child(_relic_title)
	_relic_scroll = ScrollContainer.new()
	_relic_scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	_relic_scroll.offset_top = 36
	_relic_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_relic_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	root.add_child(_relic_scroll)
	_relic_layer = Control.new()
	_relic_layer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_relic_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_relic_scroll.add_child(_relic_layer)
	_relic_inspect = Control.new()
	_relic_inspect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_relic_inspect.visible = false
	_relic_inspect.mouse_filter = Control.MOUSE_FILTER_STOP
	root.add_child(_relic_inspect)
	_relic_inspect_close = _ghost_btn("닫기")
	_relic_inspect_close.custom_minimum_size = Vector2(72, 36)
	_relic_inspect_close.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_relic_inspect_close.offset_left = -80
	_relic_inspect_close.offset_right = -8
	_relic_inspect_close.offset_top = 8
	_relic_inspect_close.offset_bottom = 44
	_relic_inspect_close.pressed.connect(func():
		_relic_id = ""
		_relic_inspect_visual = ""
		_relic_inspect.visible = false
		if _relic_scroll:
			_relic_scroll.visible = true
		_layout_relics()
	)
	_relic_inspect.add_child(_relic_inspect_close)
	_relic_inspect_name = _label("", 16, Color(0.9, 0.94, 1.0))
	_relic_inspect_name.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_relic_inspect_name.offset_top = -200
	_relic_inspect_name.offset_bottom = -168
	_relic_inspect_name.offset_left = 8
	_relic_inspect_name.offset_right = -8
	_relic_inspect.add_child(_relic_inspect_name)
	_relic_inspect_info = _label("", 14, Color(0.72, 0.8, 0.88))
	_relic_inspect_info.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_relic_inspect_info.offset_top = -164
	_relic_inspect_info.offset_bottom = -72
	_relic_inspect_info.offset_left = 8
	_relic_inspect_info.offset_right = -8
	_relic_inspect.add_child(_relic_inspect_info)
	_relic_inspect_action = _chip_btn("장착")
	_relic_inspect_action.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_relic_inspect_action.offset_top = -60
	_relic_inspect_action.offset_bottom = -8
	_relic_inspect_action.offset_left = 8
	_relic_inspect_action.offset_right = -8
	_relic_inspect_action.pressed.connect(_on_relic_inspect_action)
	_relic_inspect.add_child(_relic_inspect_action)
	root.resized.connect(_layout_relics)
	return root


func _make_space_screen() -> Control:
	var root := Control.new()
	_space_map = Control.new()
	_space_map.set_anchors_preset(Control.PRESET_FULL_RECT)
	_space_map.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_space_map.draw.connect(_draw_space_map)
	root.add_child(_space_map)
	for id in Data.space_ids():
		var b := Button.new()
		b.custom_minimum_size = Vector2(44, 44)
		_clear_btn(b)
		b.set_meta("enemy_id", id)
		b.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_space_map.add_child(b)
		_space_dots[id] = b
	root.resized.connect(_layout_space)
	return root


func _make_archive_screen() -> Control:
	var root := Control.new()
	_archive_title = _label("ARCHIVE", 18, Color(0.7, 0.8, 0.9))
	_archive_title.set_anchors_preset(Control.PRESET_TOP_WIDE)
	_archive_title.offset_bottom = 28
	root.add_child(_archive_title)
	_archive_scroll = ScrollContainer.new()
	_archive_scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	_archive_scroll.offset_top = 36
	_archive_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_archive_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	root.add_child(_archive_scroll)
	_archive_layer = Control.new()
	_archive_layer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_archive_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_archive_scroll.add_child(_archive_layer)
	_inspect = Control.new()
	_inspect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_inspect.visible = false
	_inspect.mouse_filter = Control.MOUSE_FILTER_STOP
	root.add_child(_inspect)
	var spec := Control.new()
	spec.name = "Spec"
	spec.set_anchors_preset(Control.PRESET_FULL_RECT)
	spec.offset_top = 48
	spec.offset_bottom = -168
	spec.set_script(load("res://scripts/anomaly_view.gd"))
	spec.set("interactive", true)
	spec.mouse_filter = Control.MOUSE_FILTER_STOP
	_inspect.add_child(spec)
	_inspect_close = _ghost_btn("닫기")
	_inspect_close.custom_minimum_size = Vector2(72, 36)
	_inspect_close.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_inspect_close.offset_left = -80
	_inspect_close.offset_right = -8
	_inspect_close.offset_top = 8
	_inspect_close.offset_bottom = 44
	_inspect_close.pressed.connect(func():
		_archive_id = ""
		_inspect.visible = false
		if _archive_scroll:
			_archive_scroll.visible = true
		_layout_archive()
	)
	_inspect.add_child(_inspect_close)
	_inspect_name = _label("", 16, Color(0.9, 0.94, 1.0))
	_inspect_name.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_inspect_name.offset_top = -160
	_inspect_name.offset_bottom = -128
	_inspect.add_child(_inspect_name)
	_inspect_info = _label("", 14, Color(0.72, 0.8, 0.88))
	_inspect_info.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_inspect_info.offset_top = -124
	_inspect_info.offset_bottom = -12
	_inspect_info.offset_left = 8
	_inspect_info.offset_right = -8
	_inspect.add_child(_inspect_info)
	root.resized.connect(_layout_archive)
	return root


func _goto(id: String) -> void:
	if id != "anomaly":
		Game.set_beam(false)
		Game.set_shooter_on(false)
	_tab = id
	if id != "archive":
		_archive_id = ""
		if _inspect:
			_inspect.visible = false
		if _archive_scroll:
			_archive_scroll.visible = true
	if id != "relics":
		_relic_id = ""
		_relic_inspect_visual = ""
		if _relic_inspect:
			_relic_inspect.visible = false
		if _relic_scroll:
			_relic_scroll.visible = true
	for k in _screens:
		(_screens[k] as Control).visible = str(k) == id
	_fx.visible = id == "anomaly"
	_erosion.visible = id == "anomaly"
	_highlight_tabs()
	if id == "core":
		call_deferred("_layout_core_devices")
	elif id == "relics":
		call_deferred("_layout_relics")
	elif id == "space":
		call_deferred("_layout_space")
	elif id == "archive":
		call_deferred("_layout_archive")
	elif id == "anomaly":
		_sync_weapon_chips()


func _highlight_tabs() -> void:
	for id in _tab_buttons:
		var b: Button = _tab_buttons[id]
		b.modulate = Color(0.75, 1.0, 1.0) if str(id) == _tab else Color(0.55, 0.6, 0.66)


func _layout_core_devices() -> void:
	var s: Control = _screens["core"]
	var c := s.size * 0.5
	var pad := 8.0
	var content_h := 0.0
	if _core_dock:
		content_h = _core_dock.get_combined_minimum_size().y
	var dock_h := minf(content_h, 304.0)
	if _core_scroll:
		_core_scroll.position = Vector2(pad, s.size.y - dock_h - pad)
		_core_scroll.size = Vector2(s.size.x - pad * 2.0, dock_h)
	if _tap_pop:
		_tap_pop.position = Vector2(c.x - 60.0, c.y - 88.0)
		_tap_pop.size = Vector2(120.0, 32.0)
	_sync_core_devices()


func _position_core_chrome() -> void:
	if not _screens.has("core"):
		return
	var s: Control = _screens["core"]
	var c := s.size * 0.5
	var pad := 8.0
	var dock_h := _core_scroll.size.y if _core_scroll else 0.0
	var y := s.size.y - dock_h - pad
	var gap_y := 4.0
	if _ascend_b:
		_ascend_b.size = Vector2(200, 48)
		if _ascend_b.visible:
			y -= _ascend_b.size.y + gap_y
			_ascend_b.position = Vector2(c.x - _ascend_b.size.x * 0.5, y)
	if _core_discharge_b and _core_discharge_b.visible:
		_core_discharge_b.size = Vector2(200, 40)
		y -= _core_discharge_b.size.y + gap_y
		_core_discharge_b.position = Vector2(c.x - _core_discharge_b.size.x * 0.5, y)


func _sync_core_devices() -> void:
	_core_mana.text = "%s / %s" % [Fmt.compact(Game.mana), Fmt.compact(Game.max_mana())]
	_core_prod.text = _core_prod_line()
	for id in _core_btns:
		_caption_device(_core_btns[id] as Button, str(id))
	_ascend_b.visible = Game.ascend_unlocked()
	_ascend_b.disabled = not Game.can_ascend()
	var nxt := Game.next_tier_id()
	var cost := 0.0
	if nxt != "" and Data.tiers().has(nxt):
		cost = float(Data.tiers()[nxt].cost)
	_ascend_b.text = "위계 · %s" % Fmt.compact(cost)
	_sync_discharge_buttons()
	_position_core_chrome()


func _caption_device(b: Button, id: String) -> void:
	if b == null or not Data.upgrades().has(id):
		return
	var u: Dictionary = Data.upgrades()[id]
	var lv := Game.level_of(id)
	var mx := int(u.get("max", 0))
	var at_max := mx > 0 and lv >= mx
	var title := b.find_child("Title", true, false)
	var sub := b.find_child("Sub", true, false)
	if at_max:
		b.disabled = true
		b.modulate = Color(0.78, 1.0, 1.0)
		b.add_theme_color_override("font_disabled_color", Color(0.75, 0.96, 1.0))
		b.add_theme_stylebox_override("disabled", _bar_style(Color(0.10, 0.28, 0.36, 0.92)))
		if title is Label:
			(title as Label).text = str(u.name)
		if sub is Label:
			(sub as Label).text = "레벨 %d · MAX" % lv
		return
	b.add_theme_stylebox_override("disabled", _bar_style(Color(0.08, 0.1, 0.14, 0.55)))
	b.remove_theme_color_override("font_disabled_color")
	var cost := Data.upgrade_cost(id, lv)
	var affordable := Game.mana >= cost
	b.disabled = not affordable
	if title is Label:
		(title as Label).text = "%s %s" % [u.name, u.action]
	if sub is Label:
		(sub as Label).text = "레벨 %d · %s · %s" % [lv, str(u.get("blurb", "")), Fmt.compact(cost)]
	b.modulate = Color.WHITE if affordable else Color(0.5, 0.55, 0.6)


func _visible_passive_ids() -> Array[String]:
	var out: Array[String] = []
	for id in Data.passive_ids_for_ui():
		if id in Game.owned and Game.passive_unlocked(id):
			out.append(id)
	return out


func _unlocked_extra_weapons() -> Array[String]:
	var out: Array[String] = []
	for id in Data.weapon_upgrade_ids():
		if id == "shooter":
			continue
		if Game.weapon_unlocked(id):
			out.append(id)
	return out


func _extra_weapons_unlocked() -> bool:
	return not _unlocked_extra_weapons().is_empty()


func _sync_discharge_buttons() -> void:
	if _core_discharge_b:
		_core_discharge_b.visible = false
	if _anomaly_discharge_b == null:
		return
	var violet_i := Data.tier_order().find("violet")
	var show := (
		(not Game.discharge_unlocked)
		and ("reconstructor" in Game.sighted)
		and Game.tier_rank() >= violet_i
	)
	_anomaly_discharge_b.visible = show
	if not show:
		return
	_anomaly_discharge_b.text = "연속 방전 · %s" % Fmt.compact(Game.discharge_cost())
	_anomaly_discharge_b.disabled = not Game.can_research_discharge()


func _core_prod_line() -> String:
	return Fmt.rate(Game.last_net)


func _press_shooter() -> void:
	if Game.has_rapid():
		Game.toggle_shooter()
	else:
		Game.fire_shooter()


func _shooter_arm_text() -> String:
	if not Game.combat_live():
		return "대기"
	if Game.has_rapid():
		if Game.shooter_on:
			return "사격 중지"
		return "사격 시작"
	return "사격"


func _upgrade_name(id: String) -> String:
	if Data.upgrades().has(id):
		return str(Data.upgrades()[id].get("name", id))
	return id


func _shooter_arm_modulate() -> Color:
	var sid := Game.combat_status_id()
	if sid == "empty" or _deny_t > 0.0:
		return Color(1.0, 0.38, 0.36)
	if sid == "firing" or Game.shooter_on:
		return Color(0.75, 1.0, 1.0)
	if Game.combat_live():
		return Color.WHITE
	return Color(0.55, 0.6, 0.66)


func _sync_weapon_chips() -> void:
	if _pulse_b:
		if Game.weapon_unlocked("beam"):
			_pulse_b.text = Game.combat_status_label()
		else:
			_pulse_b.text = _shooter_arm_text()
	_sync_discharge_buttons()
	if _weapon_chip_row == null:
		return
	if _shoot_chip:
		_shoot_chip.visible = Game.weapon_unlocked("beam")
		if _shoot_chip.visible:
			_shoot_chip.text = _shooter_arm_text()
			_shoot_chip.modulate = _shooter_arm_modulate()
	if _lance_chip:
		_lance_chip.visible = Game.weapon_unlocked("lance")
		if _lance_chip.visible:
			_lance_chip.text = _upgrade_name("lance")
	if _prism_chip:
		_prism_chip.visible = Game.weapon_unlocked("prism")
		if _prism_chip.visible:
			_prism_chip.text = _upgrade_name("prism")
	if _collapse_chip:
		_collapse_chip.visible = Game.weapon_unlocked("collapse")
		if _collapse_chip.visible:
			_collapse_chip.text = _upgrade_name("collapse")
	_weapon_chip_row.visible = (
		(_shoot_chip != null and _shoot_chip.visible)
		or (_lance_chip != null and _lance_chip.visible)
		or (_prism_chip != null and _prism_chip.visible)
		or (_collapse_chip != null and _collapse_chip.visible)
	)
	if not _weapon_chip_row.visible:
		return
	_modulate_weapon_chip(_lance_chip, false, Game.lance_cd > 0.0, Game.can_lance())
	_modulate_weapon_chip(_prism_chip, false, Game.prism_cd > 0.0, Game.can_prism())
	_modulate_weapon_chip(_collapse_chip, false, Game.collapse_cd > 0.0, Game.can_collapse())


func _beam_ready() -> bool:
	return Game.weapon_unlocked("beam") and Game.alive and not Game.front_cleared and (Game.beam_on or Game.mana > 0.0)


func _modulate_weapon_chip(b: Button, active: bool, on_cd: bool, ready: bool) -> void:
	if b == null:
		return
	b.disabled = false
	if active:
		b.modulate = Color(0.75, 1.0, 1.0)
	elif on_cd:
		b.modulate = Color(0.75, 1.0, 1.0)
	elif ready:
		b.modulate = Color.WHITE
	else:
		b.modulate = Color(0.55, 0.6, 0.66)


func _weapon_catalog_ids() -> Array[String]:
	var out: Array[String] = []
	for id in Data.weapon_upgrade_ids():
		if id == "rapid":
			if Game.weapon_unlocked("shooter"):
				out.append(id)
			continue
		if id == "eff":
			if Game.weapon_unlocked("beam"):
				out.append(id)
			continue
		if Game.weapon_unlocked(id):
			out.append(id)
	return out


func _relic_list_entries() -> Array:
	var out: Array = []
	var weapons: Array[String] = _weapon_catalog_ids()
	var relics: Array[String] = _visible_passive_ids()
	if not weapons.is_empty():
		out.append({"k": "h", "id": "weapons", "t": "무기"})
		for id in weapons:
			out.append({"k": "c", "id": id})
	if not relics.is_empty():
		out.append({"k": "h", "id": "relics", "t": "유물"})
		for id in relics:
			out.append({"k": "c", "id": id})
	return out


func _relic_is_passive(id: String) -> bool:
	return Data.passives().has(id)


func _portrait_grid(width: float) -> Dictionary:
	var pad := 8.0
	var gap := 8.0
	var cols := 5 if width >= 1000.0 else (4 if width >= 720.0 else 3)
	var cell_w := (width - pad * 2.0 - gap * float(cols - 1)) / float(cols)
	return {"pad": pad, "gap": gap, "cols": cols, "cell_w": cell_w}


func _relic_cell_h(cell_w: float) -> float:
	return 8.0 + cell_w * 0.48 + 4.0 + 16.0 + 2.0 + 14.0 + 4.0 + 36.0 + 4.0


func _relic_header_text(id: String) -> String:
	if id == "relics":
		return "유물 · 장착 %d/4" % Game.equipped.size()
	return "무기"


func _make_relic_header(id: String) -> Label:
	var h := _label(_relic_header_text(id), 13, Color(0.62, 0.74, 0.82))
	h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	h.set_meta("entry_k", "h")
	h.set_meta("entry_id", id)
	return h


func _layout_relics() -> void:
	if _relic_title:
		_relic_title.text = "RELICS"
	if _relic_id != "":
		if _relic_scroll:
			_relic_scroll.visible = false
		if _relic_layer:
			_relic_layer.visible = false
		if _relic_inspect:
			_relic_inspect.visible = true
		_sync_relic_inspect()
		return
	if _relic_inspect:
		_relic_inspect.visible = false
	if _relic_scroll:
		_relic_scroll.visible = true
	if _relic_layer:
		_relic_layer.visible = true
	var s := _relic_scroll.size if _relic_scroll else _relic_layer.size
	if s.x < 8.0:
		return
	var g := _portrait_grid(s.x)
	var pad := float(g["pad"])
	var gap := float(g["gap"])
	var cols := int(g["cols"])
	var cell_w := float(g["cell_w"])
	var cell_h := _relic_cell_h(cell_w)
	var step := cell_h + gap
	var entries: Array = _relic_list_entries()
	var spec := ""
	for e in entries:
		var kind := str(e.get("k", ""))
		var eid := str(e.get("id", ""))
		spec += kind + ":" + eid + "|"
	var need_rebuild := str(_relic_layer.get_meta("list_spec", "")) != spec
	if not need_rebuild:
		if int(_relic_layer.get_meta("grid_cols", 0)) != cols:
			need_rebuild = true
		elif absf(float(_relic_layer.get_meta("grid_cell_w", 0.0)) - cell_w) > 0.5:
			need_rebuild = true
		elif _relic_layer.get_child_count() != entries.size():
			need_rebuild = true
	_relic_layer.set_meta("list_spec", spec)
	_relic_layer.set_meta("grid_cols", cols)
	_relic_layer.set_meta("grid_cell_w", cell_w)
	if need_rebuild:
		for c in _relic_layer.get_children():
			_relic_layer.remove_child(c)
			c.queue_free()
		for e in entries:
			if str(e.get("k", "")) == "h":
				_relic_layer.add_child(_make_relic_header(str(e.get("id", ""))))
			else:
				_relic_layer.add_child(_make_relic_card(str(e.get("id", "")), cell_w, cell_h))
	var y := 0.0
	var col := 0
	var header_h := 22.0
	for i in entries.size():
		var node: Control = _relic_layer.get_child(i)
		var e: Dictionary = entries[i]
		if str(e.get("k", "")) == "h":
			if col != 0:
				y += step
				col = 0
			if node is Label:
				(node as Label).text = _relic_header_text(str(e.get("id", "")))
			node.position = Vector2(pad, y)
			node.size = Vector2(s.x - pad * 2.0, header_h)
			y += header_h + 4.0
			continue
		if col >= cols:
			col = 0
			y += step
		node.position = Vector2(pad + float(col) * (cell_w + gap), y)
		_sync_relic_card(node, str(e.get("id", "")), cell_w, cell_h)
		col += 1
	if col != 0:
		y += step
	_relic_layer.custom_minimum_size = Vector2(s.x, y)


func _make_relic_card(id: String, cell_w: float, cell_h: float) -> Panel:
	var cell := Panel.new()
	var frame := _bar_style(Color(0.07, 0.12, 0.18, 0.72))
	frame.corner_radius_top_left = 12
	frame.corner_radius_top_right = 12
	frame.corner_radius_bottom_left = 12
	frame.corner_radius_bottom_right = 12
	cell.add_theme_stylebox_override("panel", frame)
	cell.mouse_filter = Control.MOUSE_FILTER_STOP
	cell.clip_contents = true
	cell.set_meta("relic_id", id)
	var hit := Control.new()
	hit.name = "Hit"
	hit.mouse_filter = Control.MOUSE_FILTER_STOP
	cell.add_child(hit)
	var mark := _mark("spark", false, cell_w * 0.48)
	mark.name = "Mark"
	mark.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cell.add_child(mark)
	var title := _label("", 13, Color(0.9, 0.94, 1.0))
	title.name = "Name"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.autowrap_mode = TextServer.AUTOWRAP_OFF
	title.clip_text = true
	cell.add_child(title)
	var status := _label("", 11, Color(0.78, 0.86, 0.92))
	status.name = "Status"
	status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status.autowrap_mode = TextServer.AUTOWRAP_OFF
	status.clip_text = true
	cell.add_child(status)
	var action := _chip_btn("장착")
	action.name = "Action"
	action.custom_minimum_size = Vector2(0, 36)
	cell.add_child(action)
	var captured := id
	hit.gui_input.connect(func(ev: InputEvent) -> void:
		if _is_press(ev):
			_relic_id = captured
			_layout_relics()
	)
	action.pressed.connect(func() -> void:
		_on_relic_tile_action(captured)
	)
	_sync_relic_card(cell, id, cell_w, cell_h)
	return cell


func _sync_relic_card(cell: Control, id: String, cell_w: float, cell_h: float) -> void:
	cell.size = Vector2(cell_w, cell_h)
	cell.custom_minimum_size = Vector2(cell_w, cell_h)
	var mark_px := cell_w * 0.48
	var btn_h := 36.0
	var btn_y := cell_h - 4.0 - btn_h
	var passive := _relic_is_passive(id)
	var owned := (not passive) or id in Game.owned
	var equipped := passive and id in Game.equipped
	var visual := "spark"
	var name_text := id
	if passive and Data.passives().has(id):
		var p: Dictionary = Data.passives()[id]
		visual = str(p.get("visual", "spark"))
		name_text = str(p.get("name", id))
	elif Data.upgrades().has(id):
		var u: Dictionary = Data.upgrades()[id]
		visual = str(u.get("visual", "spark"))
		name_text = str(u.get("name", id))
	var status_text := ""
	var action_text := ""
	var action_off := false
	if passive:
		if equipped:
			status_text = "장착"
			action_text = "해제"
		elif owned:
			status_text = "보유"
			action_text = "장착"
		else:
			status_text = "미보유"
			action_text = "미보유"
			action_off = true
	else:
		var lv := Game.level_of(id)
		var mx := 0
		if Data.upgrades().has(id):
			mx = int(Data.upgrades()[id].get("max", 0))
		var at_max := mx > 0 and lv >= mx
		status_text = "레벨 %d · MAX" % lv if at_max else "레벨 %d" % lv
		if at_max:
			action_text = "MAX"
			action_off = true
		else:
			var cost := Data.upgrade_cost(id, lv)
			action_text = "강화 · %s" % Fmt.compact(cost)
			action_off = Game.mana < cost
	if equipped:
		cell.modulate = Color(0.75, 1.0, 1.0)
	elif owned:
		cell.modulate = Color.WHITE
	else:
		cell.modulate = Color(0.35, 0.38, 0.42)
	var hit := cell.get_node_or_null("Hit")
	if hit is Control:
		var h := hit as Control
		h.position = Vector2.ZERO
		h.size = Vector2(cell_w, btn_y)
	var mark := cell.get_node_or_null("Mark")
	if mark is Control:
		var m := mark as Control
		if str(m.get("mark")) != visual or bool(m.get("dim")) == owned:
			m.set("mark", visual)
			m.set("dim", not owned)
			m.queue_redraw()
		m.position = Vector2((cell_w - mark_px) * 0.5, 8.0)
		m.size = Vector2(mark_px, mark_px)
		m.custom_minimum_size = Vector2(mark_px, mark_px)
	var title := cell.get_node_or_null("Name")
	if title is Label:
		var t := title as Label
		t.text = name_text
		t.position = Vector2(4.0, 8.0 + mark_px + 4.0)
		t.size = Vector2(cell_w - 8.0, 16.0)
	var status := cell.get_node_or_null("Status")
	if status is Label:
		var st := status as Label
		st.text = status_text
		st.position = Vector2(4.0, 8.0 + mark_px + 4.0 + 16.0 + 2.0)
		st.size = Vector2(cell_w - 8.0, 14.0)
	var action := cell.get_node_or_null("Action")
	if action is Button:
		var ab := action as Button
		ab.text = action_text
		ab.disabled = action_off
		ab.position = Vector2(4.0, btn_y)
		ab.size = Vector2(cell_w - 8.0, btn_h)


func _sync_relic_inspect() -> void:
	if _relic_id == "" or _relic_inspect == null:
		return
	var id := _relic_id
	var passive := _relic_is_passive(id)
	var owned := (not passive) or id in Game.owned
	var equipped := passive and id in Game.equipped
	var visual := "spark"
	var name_text := id
	var blurb_text := ""
	if passive and Data.passives().has(id):
		var p: Dictionary = Data.passives()[id]
		visual = str(p.get("visual", "spark"))
		name_text = str(p.get("name", id))
		blurb_text = str(p.get("blurb", ""))
	elif Data.upgrades().has(id):
		var u: Dictionary = Data.upgrades()[id]
		visual = str(u.get("visual", "spark"))
		name_text = str(u.get("name", id))
		blurb_text = str(u.get("blurb", ""))
	if _relic_inspect_visual != visual or _relic_inspect_mark == null or not is_instance_valid(_relic_inspect_mark):
		if _relic_inspect_mark and is_instance_valid(_relic_inspect_mark):
			_relic_inspect.remove_child(_relic_inspect_mark)
			_relic_inspect_mark.queue_free()
		_relic_inspect_mark = _mark(visual, not owned, 96.0)
		_relic_inspect_mark.set_anchors_preset(Control.PRESET_CENTER_TOP)
		_relic_inspect_mark.offset_left = -48
		_relic_inspect_mark.offset_right = 48
		_relic_inspect_mark.offset_top = 72
		_relic_inspect_mark.offset_bottom = 168
		_relic_inspect.add_child(_relic_inspect_mark)
		_relic_inspect_visual = visual
	elif _relic_inspect_mark:
		_relic_inspect_mark.set("dim", not owned)
		_relic_inspect_mark.queue_redraw()
	_relic_inspect_name.text = name_text
	var bits: PackedStringArray = []
	if blurb_text != "":
		bits.append(blurb_text)
	if passive:
		if equipped:
			bits.append("장착")
		elif owned:
			bits.append("보유")
		else:
			bits.append("미보유")
		if owned and not equipped and Game.equipped.size() == 4:
			bits.append("장착 4/4 · 가장 오래된 유물이 해제됩니다")
		_relic_inspect_action.text = "미보유" if not owned else ("해제" if equipped else "장착")
		_relic_inspect_action.disabled = not owned
	else:
		var lv := Game.level_of(id)
		var mx := 0
		if Data.upgrades().has(id):
			mx = int(Data.upgrades()[id].get("max", 0))
		var at_max := mx > 0 and lv >= mx
		var cost := Data.upgrade_cost(id, lv)
		bits.append("레벨 %d" % lv)
		if at_max:
			bits.append("MAX")
			_relic_inspect_action.text = "MAX"
			_relic_inspect_action.disabled = true
		else:
			bits.append(Fmt.compact(cost))
			_relic_inspect_action.text = "강화"
			_relic_inspect_action.disabled = Game.mana < cost
	_relic_inspect_info.text = "\n".join(bits)


func _on_relic_inspect_action() -> void:
	if _relic_id == "":
		return
	if _relic_is_passive(_relic_id):
		if _relic_id in Game.owned:
			Game.toggle_passive(_relic_id)
		return
	Game.try_upgrade(_relic_id)


func _on_relic_tile_action(id: String) -> void:
	if id == "":
		return
	if _relic_is_passive(id):
		if id in Game.owned:
			Game.toggle_passive(id)
	else:
		Game.try_upgrade(id)
	_layout_relics()


func _layout_space() -> void:
	var s := _space_map.size
	if s.y < 8.0:
		return
	var order: Array[String] = Data.space_ids()
	var n := order.size()
	for i in n:
		var id := order[i]
		if not _space_dots.has(id):
			continue
		var b: Button = _space_dots[id]
		var u := 0.0 if n == 1 else float(i) / float(n - 1)
		var y := s.y * (0.9 - u * 0.78)
		var x := s.x * (0.5 + 0.16 * sin(float(i) * 1.1))
		b.position = Vector2(x - 22.0, y - 22.0)
		var on := id == Game.enemy_id and not Game.front_cleared
		var done := id in Game.archived
		b.modulate = Color(0.7, 1.0, 1.0) if on else (Color(0.45, 0.85, 0.72) if done else Color(0.4, 0.45, 0.5))
	_space_map.queue_redraw()


func _draw_space_map() -> void:
	var order: Array[String] = Data.space_ids()
	var pts: PackedVector2Array = PackedVector2Array()
	for i in order.size():
		var id := order[i]
		if not _space_dots.has(id):
			continue
		var b: Button = _space_dots[id]
		pts.append(b.position + b.size * 0.5)
	for i in range(1, pts.size()):
		_space_map.draw_line(pts[i - 1], pts[i], Color(0.35, 0.55, 0.7, 0.35), 2.0, true)
	for i in order.size():
		var id := order[i]
		if not _space_dots.has(id):
			continue
		var b: Button = _space_dots[id]
		var p := b.position + b.size * 0.5
		var col := Color(0.35, 0.4, 0.48)
		if id in Game.archived:
			col = Color(0.4, 0.82, 0.7)
		elif id == Game.enemy_id and not Game.front_cleared:
			col = _accent()
		_space_map.draw_circle(p, 11.0, col)
	_space_map.draw_string(
		ThemeDB.fallback_font,
		Vector2(16, 28),
		_region_header(),
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		16,
		Color(0.7, 0.8, 0.9, 0.85)
	)


func _layout_archive() -> void:
	for c in _archive_layer.get_children():
		_archive_layer.remove_child(c)
		c.queue_free()
	var s := _archive_scroll.size if _archive_scroll else _archive_layer.size
	if s.x < 8.0:
		return
	if _archive_id != "":
		if _archive_scroll:
			_archive_scroll.visible = false
		_archive_layer.visible = false
		_inspect.visible = true
		var spec := _inspect.find_child("Spec", false, false)
		if spec:
			spec.set("preview_id", _archive_id)
			spec.set("interactive", true)
			spec.queue_redraw()
		if Data.enemies().has(_archive_id):
			var e: Dictionary = Data.enemies()[_archive_id]
			_inspect_name.text = str(e.get("codename", _archive_id))
			_inspect_info.text = _archive_blurb(e, _archive_id)
		else:
			_inspect_name.text = "UNKNOWN ENTITY"
			_inspect_info.text = "분석 데이터 없음"
		return
	_inspect.visible = false
	if _archive_scroll:
		_archive_scroll.visible = true
	_archive_layer.visible = true
	var ids: Array[String] = []
	if not Game.front_cleared and Game.enemy_id not in Game.archived:
		ids.append("")
	for id in Game.archived:
		ids.append(id)
	if ids.is_empty():
		_archive_layer.custom_minimum_size = Vector2(s.x, s.y)
		var empty := _label("기록된 이상체가 없다.", 15, Color(0.62, 0.7, 0.78))
		empty.position = Vector2(8, 16)
		empty.size = Vector2(s.x - 16.0, 32.0)
		_archive_layer.add_child(empty)
		return
	var g := _portrait_grid(s.x)
	var pad := float(g["pad"])
	var gap := float(g["gap"])
	var cols := int(g["cols"])
	var cell_w := float(g["cell_w"])
	var cell_h := cell_w
	var step := cell_h + gap
	var rows := int(ceili(float(ids.size()) / float(cols)))
	_archive_layer.custom_minimum_size = Vector2(s.x, float(rows) * step)
	for i in ids.size():
		var enemy_id := ids[i]
		var cell := _make_archive_tile(enemy_id, cell_w, cell_h)
		var col := i % cols
		var row := i / cols
		cell.position = Vector2(pad + float(col) * (cell_w + gap), float(row) * step)
		_archive_layer.add_child(cell)


func _make_archive_tile(id: String, cell_w: float, cell_h: float) -> Panel:
	var cell := Panel.new()
	var frame := _bar_style(Color(0.07, 0.12, 0.18, 0.72))
	frame.corner_radius_top_left = 12
	frame.corner_radius_top_right = 12
	frame.corner_radius_bottom_left = 12
	frame.corner_radius_bottom_right = 12
	cell.add_theme_stylebox_override("panel", frame)
	cell.mouse_filter = Control.MOUSE_FILTER_STOP
	cell.clip_contents = true
	cell.size = Vector2(cell_w, cell_h)
	cell.custom_minimum_size = Vector2(cell_w, cell_h)
	var thumb_h := cell_h * 0.70
	var thumb := Control.new()
	thumb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	thumb.position = Vector2(4.0, 4.0)
	thumb.size = Vector2(cell_w - 8.0, thumb_h - 8.0)
	if id != "":
		thumb.set_script(load("res://scripts/anomaly_view.gd"))
		thumb.set("preview_id", id)
		thumb.set("interactive", false)
	cell.add_child(thumb)
	var title := _label("", 13, Color(0.9, 0.94, 1.0))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.autowrap_mode = TextServer.AUTOWRAP_OFF
	title.clip_text = true
	title.position = Vector2(4.0, thumb_h)
	title.size = Vector2(cell_w - 8.0, cell_h - thumb_h - 4.0)
	cell.add_child(title)
	if id == "":
		title.text = "UNKNOWN ENTITY"
		cell.modulate = Color(0.72, 0.76, 0.8)
		cell.mouse_filter = Control.MOUSE_FILTER_IGNORE
	else:
		if Data.enemies().has(id):
			var e: Dictionary = Data.enemies()[id]
			title.text = str(e.get("name", id))
		else:
			title.text = id
		var captured := id
		cell.gui_input.connect(func(ev: InputEvent) -> void:
			if _is_press(ev):
				_archive_id = captured
				_layout_archive()
		)
	return cell


func _archive_blurb(entry: Dictionary, enemy_id: String) -> String:
	var bits: PackedStringArray = []
	bits.append(str(entry.get("name", enemy_id)))
	var region := str(entry.get("region", ""))
	if region != "":
		bits.append(region)
	var trait_line := str(entry.get("trait", ""))
	if trait_line != "":
		bits.append(trait_line)
	var note := str(entry.get("note", ""))
	if note != "":
		bits.append(note)
	var relic := str(Game.archive_relic.get(enemy_id, ""))
	if relic != "":
		bits.append("사용 유물  ·  %s" % relic)
	return "\n".join(bits)


func _refresh() -> void:
	_region_l.text = _region_header()
	if Game.front_cleared:
		if Game.ascend_unlocked():
			_name_l.text = "위계 돌파" if Game.can_ascend() else "위계 대기"
		else:
			_name_l.text = "전선 안정"
		_chip_l.text = ""
	elif Game.is_identified():
		var e: Dictionary = Game.current_enemy()
		_name_l.text = str(e.get("codename", e.get("name", "?")))
		if Game.combat_live():
			_chip_l.text = _status_line()
		else:
			_chip_l.text = "붕괴"
	else:
		_name_l.text = "UNKNOWN ENTITY"
		_chip_l.text = ""
	_chip_l.visible = _chip_l.text.strip_edges() != ""
	_mana_l.text = "%s / %s" % [Fmt.compact(Game.mana), Fmt.compact(Game.max_mana())]
	_rate_l.text = Fmt.rate(Game.last_net)
	if _stab_bar:
		_stab_bar.queue_redraw()
	if _tab == "core":
		_sync_core_devices()
	elif _tab == "relics":
		_layout_relics()
	elif _tab == "space":
		_layout_space()
	elif _tab == "anomaly":
		_sync_weapon_chips()


func _draw_stab() -> void:
	var w := _stab_bar.size.x
	var h := _stab_bar.size.y
	_stab_bar.draw_rect(Rect2(Vector2.ZERO, Vector2(w, h)), Color(0.08, 0.1, 0.14, 0.7))
	var r := Game.stability_ratio()
	var fill := _accent()
	if Game.stability_is_shell():
		fill = fill.lerp(Color(0.78, 0.52, 0.28), 0.38)
		fill = fill.darkened(0.16)
	if _stab_pulse > 0.0:
		fill = fill.lerp(Color.WHITE, _stab_pulse * 0.7)
	_stab_bar.draw_rect(Rect2(Vector2.ZERO, Vector2(w * r, h)), fill)
	if _stab_pulse > 0.0:
		_stab_bar.draw_rect(Rect2(Vector2.ZERO, Vector2(w, h)), Color(1.0, 1.0, 1.0, _stab_pulse * 0.28))


func _region_header() -> String:
	var rid := Game.current_region_id()
	var regions: Dictionary = Data.regions()
	if regions.has(rid):
		return str(regions[rid].get("label", ""))
	return ""


func _status_line() -> String:
	var bits: PackedStringArray = []
	var gimmick := Game.gimmick_label()
	if gimmick != "":
		bits.append(gimmick)
	if Game.part_count() > 1:
		bits.append("%d" % Game.part_count())
	return "  ·  ".join(bits)


func _accent() -> Color:
	if str(Game.tier) == "violet":
		return Color(0.82, 0.42, 1.0)
	return Color(0.4, 0.88, 1.0)


func _anchor_band(c: Control, top: float, bottom: float) -> void:
	c.layout_mode = 1
	c.anchor_left = 0.0
	c.anchor_top = top
	c.anchor_right = 1.0
	c.anchor_bottom = bottom
	c.offset_left = 0.0
	c.offset_top = 0.0
	c.offset_right = 0.0
	c.offset_bottom = 0.0
	c.grow_horizontal = Control.GROW_DIRECTION_BOTH
	c.grow_vertical = Control.GROW_DIRECTION_BOTH


func _on_shot(ok: bool) -> void:
	if ok:
		_mana_flash = 1.0
		_stab_pulse = 1.0
		_flash = maxf(_flash, 0.32)
		if _stab_bar:
			_stab_bar.queue_redraw()
		if _fx:
			_fx.queue_redraw()
	else:
		_deny_t = 1.0
		_sync_mana_flash()
		if _pulse_b and not Game.weapon_unlocked("beam"):
			_pulse_b.modulate = Color(1.0, 0.38, 0.36)


func _on_gap_healed(_amount: float) -> void:
	_stab_pulse = 1.0
	_flash = maxf(_flash, 0.7)
	if _stab_bar:
		_stab_bar.queue_redraw()
	if _anomaly:
		_anomaly.punch_heal()


func _confirm_reset() -> void:
	if _reset_dlg == null:
		return
	_reset_dlg.popup_centered()


func _sync_mana_flash() -> void:
	if _mana_l == null:
		return
	var base := Color(0.55, 0.92, 1.0)
	if _deny_t > 0.0:
		_mana_l.add_theme_color_override("font_color", Color(1.0, 0.38, 0.36).lerp(base, 1.0 - clampf(_deny_t, 0.0, 1.0)))
	elif _mana_flash > 0.0:
		_mana_l.add_theme_color_override("font_color", base.lerp(Color.WHITE, clampf(_mana_flash, 0.0, 1.0)))
	else:
		_mana_l.add_theme_color_override("font_color", base)


func _on_tapped(amount: float) -> void:
	if _tap_pop == null or amount <= 0.0:
		return
	_tap_pop.text = "+%s" % Fmt.compact(amount)
	_tap_pop.visible = true
	_tap_pop.modulate.a = 1.0
	_tap_pop_t = 0.8


func _group_title(text: String) -> Label:
	var l := _label(text, 12, Color(0.7, 0.8, 0.9))
	l.custom_minimum_size = Vector2(0, 18)
	l.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	return l


func _label(text: String, px: int, col: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", px)
	l.add_theme_color_override("font_color", col)
	l.add_theme_constant_override("outline_size", 5)
	l.add_theme_color_override("font_outline_color", Color(0.02, 0.03, 0.07, 0.88))
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


func _is_press(ev: InputEvent) -> bool:
	if ev is InputEventScreenTouch:
		return (ev as InputEventScreenTouch).pressed
	if ev is InputEventMouseButton:
		var mb := ev as InputEventMouseButton
		return mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT
	return false


func _ghost_btn(text: String) -> Button:
	var b := Button.new()
	b.text = text
	_clear_btn(b)
	return b


func _clear_btn(b: Button) -> void:
	var s := StyleBoxEmpty.new()
	b.add_theme_stylebox_override("normal", s)
	b.add_theme_stylebox_override("hover", s)
	b.add_theme_stylebox_override("pressed", s)
	b.add_theme_stylebox_override("disabled", s)
	b.add_theme_color_override("font_color", Color(0.85, 0.9, 0.96))
	b.add_theme_color_override("font_hover_color", Color(1, 1, 1))
	b.add_theme_color_override("font_pressed_color", _accent())
	b.add_theme_color_override("font_disabled_color", Color(0.5, 0.55, 0.6))


func _device_btn(id: String) -> Button:
	var u: Dictionary = Data.upgrades()[id]
	var b := Button.new()
	b.custom_minimum_size = Vector2(0, 68)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.mouse_filter = Control.MOUSE_FILTER_STOP
	b.focus_mode = Control.FOCUS_NONE
	b.add_theme_font_size_override("font_size", 16)
	b.add_theme_color_override("font_color", Color(0.88, 0.96, 1.0))
	b.add_theme_color_override("font_hover_color", Color(1, 1, 1))
	b.add_theme_color_override("font_pressed_color", Color(0.55, 0.92, 1.0))
	b.add_theme_color_override("font_disabled_color", Color(0.5, 0.55, 0.6))
	b.add_theme_stylebox_override("normal", _bar_style(Color(0.07, 0.16, 0.24, 0.9)))
	b.add_theme_stylebox_override("hover", _bar_style(Color(0.12, 0.28, 0.38, 0.95)))
	b.add_theme_stylebox_override("pressed", _bar_style(Color(0.16, 0.42, 0.52, 0.98)))
	b.add_theme_stylebox_override("disabled", _bar_style(Color(0.08, 0.1, 0.14, 0.55)))
	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_theme_constant_override("separation", 10)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	b.add_child(row)
	row.set_anchors_preset(Control.PRESET_FULL_RECT)
	row.offset_left = 12
	row.offset_right = -12
	row.offset_top = 6
	row.offset_bottom = -6
	var glyph := _mark(str(u.get("visual", "spark")), false, 28.0)
	glyph.name = "Glyph"
	row.add_child(glyph)
	var col := VBoxContainer.new()
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_theme_constant_override("separation", 2)
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_child(col)
	var title := _label("%s %s" % [u.name, u.action], 16, Color(0.9, 0.94, 1.0))
	title.name = "Title"
	title.autowrap_mode = TextServer.AUTOWRAP_OFF
	col.add_child(title)
	var sub := _label("", 13, Color(0.68, 0.76, 0.84))
	sub.name = "Sub"
	sub.autowrap_mode = TextServer.AUTOWRAP_OFF
	col.add_child(sub)
	return b


func _orb_btn(id: String) -> Button:
	var u: Dictionary = Data.upgrades()[id]
	var b := Button.new()
	b.custom_minimum_size = Vector2(72, 72)
	_clear_btn(b)
	var col := VBoxContainer.new()
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	b.add_child(col)
	col.set_anchors_preset(Control.PRESET_FULL_RECT)
	col.add_child(_mark(str(u.get("visual", "spark")), false, 36.0))
	var cap := _label("0", 12, Color(0.8, 0.9, 1.0))
	cap.name = "Cap"
	cap.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(cap)
	return b


func _mark(kind: String, dim: bool, px: float) -> Control:
	var m := Control.new()
	m.custom_minimum_size = Vector2(px, px)
	m.set_script(load("res://scripts/mark_view.gd"))
	m.set("mark", kind)
	m.set("dim", dim)
	m.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return m


func _chip_btn(text: String) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(0, 40)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.mouse_filter = Control.MOUSE_FILTER_STOP
	b.focus_mode = Control.FOCUS_NONE
	b.disabled = false
	b.add_theme_font_size_override("font_size", 12)
	b.add_theme_color_override("font_color", Color(0.88, 0.96, 1.0))
	b.add_theme_color_override("font_hover_color", Color(1, 1, 1))
	b.add_theme_color_override("font_pressed_color", Color(0.55, 0.92, 1.0))
	b.add_theme_color_override("font_disabled_color", Color(0.5, 0.55, 0.6))
	b.add_theme_stylebox_override("normal", _bar_style(Color(0.07, 0.16, 0.24, 0.9)))
	b.add_theme_stylebox_override("hover", _bar_style(Color(0.12, 0.28, 0.38, 0.95)))
	b.add_theme_stylebox_override("pressed", _bar_style(Color(0.16, 0.42, 0.52, 0.98)))
	b.add_theme_stylebox_override("disabled", _bar_style(Color(0.08, 0.1, 0.14, 0.55)))
	return b


func _shoot_btn() -> Button:
	var b := Button.new()
	b.text = "사격 시작"
	b.custom_minimum_size = Vector2(0, 56)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.mouse_filter = Control.MOUSE_FILTER_STOP
	b.focus_mode = Control.FOCUS_NONE
	b.z_index = 24
	b.disabled = false
	b.add_theme_font_size_override("font_size", 18)
	b.add_theme_color_override("font_color", Color(0.88, 0.96, 1.0))
	b.add_theme_color_override("font_hover_color", Color(1, 1, 1))
	b.add_theme_color_override("font_pressed_color", Color(0.55, 0.92, 1.0))
	b.add_theme_color_override("font_disabled_color", Color(0.5, 0.55, 0.6))
	b.add_theme_stylebox_override("normal", _bar_style(Color(0.07, 0.16, 0.24, 0.9)))
	b.add_theme_stylebox_override("hover", _bar_style(Color(0.12, 0.28, 0.38, 0.95)))
	b.add_theme_stylebox_override("pressed", _bar_style(Color(0.16, 0.42, 0.52, 0.98)))
	b.add_theme_stylebox_override("disabled", _bar_style(Color(0.08, 0.1, 0.14, 0.55)))
	return b


func _bar_style(col: Color) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = col
	s.corner_radius_top_left = 16
	s.corner_radius_top_right = 16
	s.corner_radius_bottom_left = 16
	s.corner_radius_bottom_right = 16
	s.content_margin_left = 8
	s.content_margin_right = 8
	s.content_margin_top = 8
	s.content_margin_bottom = 8
	return s
