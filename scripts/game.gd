extends Node

const SAVE_PATH := "user://save.cfg"

signal changed
signal killed(id: String)
signal tapped(amount: float)
signal shot(ok: bool)
signal gap_healed(amount: float)

const TAP_SEC := 4.0 # unused; tap_gain uses Data.tap_rules().time_eq
const SHOOTER_CD := 0.95
const TELEMETRY_PATH := "user://telemetry.json"

# --- core ---
var mana := 80.0
var tier: String = "cyan"
var lv_prod := 0
var lv_cap := 0
var lv_tap_coupling := 0
var lv_auto_dynamo := 0
var lv_flywheel := 0
var flywheel_charge := 0.0
var idle_t := 0.0
var tap_cd := 0.0
var lv_shooter := 0
var lv_rapid := 0
var lv_beam := 0
var lv_eff := 0
var lv_lance := 0
var lv_prism := 0
var lv_collapse := 0
var tap_flash := 0.0
var shot_flash := 0.0

var equipped: Array[String] = ["produce_20"]
var owned: Array[String] = ["produce_20", "cap_50", "kill_return", "anti_regen"]
var archived: Array[String] = []
var sighted: Array[String] = []
var archive_relic: Dictionary = {}

# --- combat ---
var beam_on := false
var shooter_on := false
var shooter_cd := 0.0
var pulse_cd := 0.0
var enemy_id := "shard"
var integrity := 90.0
var alive := true
var erosion := 0.4
var front_cleared := false

var parts: Array[float] = []
var _part_cap: Array[float] = []
var shell_hp := 0.0
var fight_t := 0.0
var heal_acc := 0.0
var fragmented := false
var recursion_left := 0
var lance_cd := 0.0
var prism_cd := 0.0
var collapse_cd := 0.0
var _burst_t := 0.0
var _used_weapons: Array[String] = []

var _used_shooter := false
var _used_pulse := false
var _used_beam := false
var _resume_combat := false
var _save_acc := 0.0
var last_dps := 0.0
var last_net := 0.0

var undamaged_t := 0.0
var discharge_unlocked := false

var play_t := 0.0
var t_first_prod := -1.0
var t_tap_branch := -1.0
var t_auto_branch := -1.0
var mana_tap := 0.0
var mana_passive := 0.0
var tap_active_t := 0.0
var flywheel_high_t := 0.0
var spent_core := 0.0
var spent_shooter := 0.0
var clear_t: Dictionary = {}
var t_lattice := -1.0
var t_violet := -1.0
var t_beam := -1.0
var equipped_at: Dictionary = {}
var shooter_ok := 0
var shooter_starve := 0
var recon_fight_t := 0.0
var recon_heal_n := 0
var recon_heal_amt := 0.0


func _ready() -> void:
	load_game()
	_sync_front()
	changed.emit()


func _process(dt: float) -> void:
	var shooter_cooling := shooter_cd > 0.0
	shooter_cd = maxf(0.0, shooter_cd - dt)
	pulse_cd = shooter_cd
	lance_cd = maxf(0.0, lance_cd - dt)
	prism_cd = maxf(0.0, prism_cd - dt)
	collapse_cd = maxf(0.0, collapse_cd - dt)
	_burst_t = maxf(0.0, _burst_t - dt)
	tap_flash = maxf(0.0, tap_flash - dt * 3.2)
	shot_flash = maxf(0.0, shot_flash - dt * 3.2)

	if has_rapid() and shooter_on and combat_live() and not beam_on:
		if can_shooter():
			fire_shooter()
		elif weapon_unlocked("shooter") and shooter_cd <= 0.0 and mana < shooter_cost():
			if shooter_cooling:
				shooter_starve += 1

	tap_cd = maxf(0.0, tap_cd - dt)
	idle_t += dt
	var fw: Dictionary = Data.flywheel_rules()
	var delay := float(fw.get("delay", 6.0))
	var ramp := float(fw.get("ramp", 18.0))
	var decay := float(fw.get("decay", 3.0))
	if idle_t < delay:
		flywheel_charge = maxf(0.0, flywheel_charge - dt / maxf(decay, 0.001))
	else:
		flywheel_charge = minf(1.0, flywheel_charge + dt / maxf(ramp, 0.001))

	var prod := production()
	var drain := 0.0
	var dps := 0.0
	var spent_beam := 0.0

	mana = clampf(mana + prod * dt, 0.0, max_mana())

	play_t += dt
	mana_passive += prod * dt
	if idle_t < delay:
		tap_active_t += dt
	if flywheel_charge >= 0.8:
		flywheel_high_t += dt
	if combat_live() and enemy_id == "reconstructor":
		recon_fight_t += dt

	if beam_on and not weapon_unlocked("beam"):
		beam_on = false
	if beam_on:
		_used_beam = true
		_mark_weapon("빔")
		drain = beam_cost_per_sec()
		var need := drain * dt
		spent_beam = minf(mana, need)
		mana -= spent_beam
		if need > 0.0 and spent_beam + 0.000001 < need:
			beam_on = false
			dps = beam_dps() * (spent_beam / need)
		elif spent_beam > 0.0:
			dps = beam_dps()
		else:
			beam_on = false
			dps = 0.0
		if mana <= 0.0:
			beam_on = false

	last_dps = dps
	var regen := enemy_regen()
	var max_hp := float(current_enemy().get("max_integrity", 1.0))
	if alive and not front_cleared:
		_tick_gimmicks(dt)
		_tick_regen(dt)
		if dps > 0.0:
			apply_damage(dps * dt, false)
		var pressure := 0.5
		if regen > 0.0:
			pressure = clampf(0.5 + (regen - dps) / maxf(regen, 1.0) * 0.45, 0.08, 0.92)
		else:
			pressure = clampf(integrity / maxf(max_hp, 1.0), 0.08, 0.85)
		erosion = lerpf(erosion, pressure, clampf(dt * 2.2, 0.0, 1.0))
	else:
		erosion = lerpf(erosion, 0.08, clampf(dt * 3.0, 0.0, 1.0))

	last_net = production() - combat_spend_rate()
	_save_acc += dt
	if _save_acc >= 4.0:
		_save_acc = 0.0
		save_game()
	changed.emit()


func current_enemy() -> Dictionary:
	return Data.enemies()[enemy_id]


func combat_live() -> bool:
	return alive and not front_cleared


func is_archived(id: String) -> bool:
	return id in archived


func is_identified() -> bool:
	return front_cleared or not alive or is_archived(enemy_id)


func output() -> float:
	var base := 1.8 + lv_prod * 0.32
	return base * (1.0 + _passive("prod_mult"))


func tap_mult() -> float:
	return 1.0 + 0.12 * float(lv_tap_coupling) + _passive("tap_mult")


func auto_mult() -> float:
	return 1.0 + 0.10 * float(lv_auto_dynamo) + _passive("auto_mult")


func flywheel_factor() -> float:
	var rules: Dictionary = Data.flywheel_rules()
	var cap := float(rules.get("bonus_per_lv", 0.08)) * float(lv_flywheel)
	return 1.0 + cap * clampf(flywheel_charge, 0.0, 1.0)


func flywheel_charge_ratio() -> float:
	return clampf(flywheel_charge, 0.0, 1.0)


func flywheel_status_label() -> String:
	var ratio := flywheel_charge_ratio()
	if ratio >= 0.8:
		return "플라이휠 최대"
	if ratio > 0.05:
		return "플라이휠 충전"
	return ""


func production() -> float:
	var m := auto_mult() * flywheel_factor()
	if _burst_t > 0.0:
		m *= 1.0 + _passive("after_burst")
	return output() * m


func max_mana() -> float:
	var base := 420.0 + lv_cap * 2000.0
	return base * (1.0 + _passive("cap_mult"))


func tier_rank() -> int:
	var r := Data.tier_order().find(tier)
	if r < 0:
		return 0
	return r


func ascend_unlocked() -> bool:
	var next_id := next_tier_id()
	if next_id == "":
		return false
	var tiers: Dictionary = Data.tiers()
	if not tiers.has(next_id):
		return false
	var t: Dictionary = tiers[next_id]
	if not bool(t.get("playable", false)):
		return false
	var unlock_after := str(t.get("unlock_after", ""))
	if unlock_after != "" and not is_archived(unlock_after):
		return false
	var req_output := float(t.get("req_output", 0.0))
	var req_capacity := float(t.get("req_capacity", 0.0))
	if req_output > 0.0 and output() < req_output:
		return false
	if req_capacity > 0.0 and max_mana() < req_capacity:
		return false
	return true


func can_ascend() -> bool:
	if not ascend_unlocked():
		return false
	var t: Dictionary = Data.tiers()[next_tier_id()]
	return mana >= float(t.get("cost", 0.0))


func try_ascend() -> void:
	if not can_ascend():
		return
	var next_id := next_tier_id()
	var t: Dictionary = Data.tiers()[next_id]
	var cost := float(t.get("cost", 0.0))
	if not try_spend(cost):
		return
	tier = next_id
	if next_id == "violet":
		if t_violet < 0.0:
			t_violet = play_t
		if not equipped_at.has("violet"):
			equipped_at["violet"] = play_t
	_sync_owned_unlocks()
	_sync_front()
	save_game()
	changed.emit()


func tap_gain() -> float:
	var time_eq := float(Data.tap_rules().get("time_eq", 4.0))
	return output() * time_eq * tap_mult()


func tap_ready() -> bool:
	return tap_cd <= 0.0


func tap_core() -> float:
	if tap_cd > 0.0:
		return 0.0
	tap_cd = float(Data.tap_rules().get("cooldown", 0.20))
	idle_t = 0.0
	var room := max_mana() - mana
	if room <= 0.0:
		return 0.0
	var amount := minf(tap_gain(), room)
	if amount <= 0.0:
		return 0.0
	mana += amount
	mana = clampf(mana, 0.0, max_mana())
	mana_tap += amount
	tap_flash = 1.0
	tapped.emit(amount)
	changed.emit()
	return amount


func _row_unlocked(row: Dictionary) -> bool:
	if not bool(row.get("playable", true)):
		return false
	var req := str(row.get("req_tier", "cyan"))
	var req_rank := Data.tier_order().find(req)
	if req_rank < 0:
		return false
	if req_rank > tier_rank():
		return false
	var unlock_after := str(row.get("unlock_after", ""))
	if unlock_after != "" and not is_archived(unlock_after):
		return false
	return true


func weapon_unlocked(id: String) -> bool:
	if id == "beam":
		return discharge_unlocked
	var weapons: Dictionary = Data.weapons()
	if not weapons.has(id):
		return false
	return _row_unlocked(weapons[id])


func passive_unlocked(id: String) -> bool:
	if id == "beam_eff":
		return discharge_unlocked
	var passives: Dictionary = Data.passives()
	if not passives.has(id):
		return false
	return _row_unlocked(passives[id])


func discharge_cost() -> float:
	return float(Data.discharge_rules().get("cost", 4800.0))


func can_research_discharge() -> bool:
	if discharge_unlocked:
		return false
	if tier_rank() < Data.tier_order().find("violet"):
		return false
	var oid := str(Data.discharge_rules().get("observe_id", "reconstructor"))
	if oid not in sighted:
		return false
	return mana >= discharge_cost()


func try_research_discharge() -> bool:
	if not can_research_discharge():
		return false
	if not try_spend(discharge_cost()):
		return false
	discharge_unlocked = true
	_ensure_owned("beam_eff")
	if t_beam < 0.0:
		t_beam = play_t
	if not equipped_at.has("beam"):
		equipped_at["beam"] = play_t
	save_game()
	changed.emit()
	return true


func try_spend(amount: float) -> bool:
	if amount <= 0.0:
		return true
	if mana < amount:
		return false
	mana -= amount
	mana = clampf(mana, 0.0, max_mana())
	return true


func try_spend_frac(frac: float) -> float:
	if mana <= 0.0 or frac <= 0.0:
		return 0.0
	var spent := mana * frac
	mana -= spent
	return spent


func current_region_id() -> String:
	return str(current_enemy().get("region_id", "earth_orbit"))


func next_tier_id() -> String:
	var order: Array[String] = Data.tier_order()
	var idx := order.find(tier)
	if idx < 0 or idx + 1 >= order.size():
		return ""
	return order[idx + 1]


# --- combat ---
func pulse_damage() -> float:
	return shooter_damage()


func shooter_interval() -> float:
	return float(Data.shooter_rules().get("cd", 0.95))


func shooter_damage() -> float:
	var r: Dictionary = Data.shooter_rules()
	var base := float(r.get("dmg_base", 9.0)) + float(lv_shooter) * float(r.get("dmg_per_lv", 6.5))
	return base * (1.0 + _passive("shooter_dmg"))


func pulse_cost() -> float:
	return shooter_cost()


func shooter_cost() -> float:
	var r: Dictionary = Data.shooter_rules()
	return float(r.get("cost_base", 12.0)) + float(lv_shooter) * float(r.get("cost_per_lv", 4.0))


func combat_spend_rate() -> float:
	if beam_on:
		return beam_cost_per_sec()
	if shooter_on and combat_live() and shooter_cd > 0.0:
		var interval := shooter_interval()
		if interval <= 0.0:
			return 0.0
		return shooter_cost() / interval
	return 0.0


func beam_dps() -> float:
	return 40.0 + float(lv_beam) * 8.0


func beam_cost_per_sec() -> float:
	var cost := 128.0 * (1.0 - lv_eff * 0.07)
	cost *= 1.0 - _passive("beam_cost")
	return maxf(cost, 24.0)


func enemy_regen() -> float:
	var r := float(current_enemy().get("regen", 0.0))
	return r * (1.0 - _passive("anti_regen"))


func _passive(kind: String) -> float:
	var t := 0.0
	for id in equipped:
		var p: Dictionary = Data.passives()[id]
		if str(p.get("kind", "")) == kind:
			t += float(p.get("value", 0.0))
	return t


func can_pulse() -> bool:
	return can_shooter()


func has_rapid() -> bool:
	return lv_rapid > 0


func can_shooter() -> bool:
	return alive and not front_cleared and shooter_cd <= 0.0 and mana >= shooter_cost() and weapon_unlocked("shooter")


func shooter_vfx_active() -> bool:
	return shooter_cd > 0.0


func stability_ratio() -> float:
	if not combat_live():
		return 0.0
	if shell_ratio() > 0.0:
		return shell_ratio()
	var mx := float(current_enemy().get("max_integrity", 0.0))
	if mx <= 0.0:
		return 0.0
	return clampf(integrity / mx, 0.0, 1.0)


func stability_is_shell() -> bool:
	return combat_live() and shell_ratio() > 0.0


func combat_status_id() -> String:
	if not combat_live():
		return "cleared"
	if beam_on:
		return "beam_on"
	var cd := shooter_cd > 0.0
	if (has_rapid() and shooter_on and (can_shooter() or cd)) or (not has_rapid() and cd):
		return "firing"
	if (has_rapid() and shooter_on and mana < shooter_cost()) or (not has_rapid() and mana < shooter_cost()):
		return "empty"
	if weapon_unlocked("beam") and not shooter_on:
		return "beam_ready"
	return "idle"


func combat_status_label() -> String:
	match combat_status_id():
		"firing":
			return "사격 중"
		"empty":
			return "마력 부족"
		"beam_on":
			return "방전 중"
		"beam_ready":
			return "연속 방전"
		_:
			return "대기"


func fire_pulse() -> void:
	fire_shooter()


func fire_shooter() -> void:
	if not can_shooter():
		shot_flash = 0.45
		shot.emit(false)
		return
	var cost := shooter_cost()
	if not try_spend(cost):
		shot_flash = 0.45
		shot.emit(false)
		return
	_used_shooter = true
	_used_pulse = true
	_mark_weapon("사격기")
	shooter_cd = shooter_interval()
	pulse_cd = shooter_cd
	apply_damage(shooter_damage(), false)
	shot_flash = 1.0
	shooter_ok += 1
	spent_shooter += cost
	shot.emit(true)
	changed.emit()


func set_beam(on: bool) -> void:
	if not weapon_unlocked("beam"):
		beam_on = false
		return
	if on:
		if alive and not front_cleared and mana > 0.0:
			beam_on = true
			_used_beam = true
			_mark_weapon("빔")
	else:
		beam_on = false
	changed.emit()


func toggle_beam() -> void:
	set_beam(not beam_on)


func set_shooter_on(on: bool) -> void:
	if on and has_rapid() and combat_live():
		shooter_on = true
		if can_shooter():
			fire_shooter()
	else:
		shooter_on = false
	changed.emit()


func toggle_shooter() -> void:
	if not combat_live():
		shooter_on = false
		changed.emit()
		return
	set_shooter_on(not shooter_on)


func lance_cost() -> float:
	return max_mana() * 0.20


func lance_damage() -> float:
	return 3200.0 + float(lv_lance) * 500.0


func prism_cost() -> float:
	return max_mana() * 0.10


func prism_damage() -> float:
	return 380.0 + float(lv_prism) * 90.0


func collapse_frac() -> float:
	var weapons: Dictionary = Data.weapons()
	if not weapons.has("collapse"):
		return 0.35
	var w: Dictionary = weapons["collapse"]
	return float(w.get("frac", 0.35))


func collapse_scale() -> float:
	return 2.4 + float(lv_collapse) * 0.15


func can_lance() -> bool:
	return (
		weapon_unlocked("lance")
		and alive
		and not front_cleared
		and lance_cd <= 0.0
		and mana >= lance_cost()
	)


func fire_lance() -> void:
	if not can_lance():
		return
	if not try_spend(lance_cost()):
		return
	lance_cd = 2.4
	_burst_t = 4.0
	_mark_weapon("창")
	apply_damage(lance_damage(), false)
	changed.emit()


func can_prism() -> bool:
	return (
		weapon_unlocked("prism")
		and alive
		and not front_cleared
		and prism_cd <= 0.0
		and mana >= prism_cost()
	)


func fire_prism() -> void:
	if not can_prism():
		return
	if not try_spend(prism_cost()):
		return
	prism_cd = 1.6
	_mark_weapon("프리즘")
	apply_damage(prism_damage(), true)
	changed.emit()


func can_collapse() -> bool:
	return (
		weapon_unlocked("collapse")
		and alive
		and not front_cleared
		and collapse_cd <= 0.0
		and mana > 0.0
	)


func fire_collapse() -> void:
	if not can_collapse():
		return
	var spent := try_spend_frac(collapse_frac())
	if spent <= 0.0:
		return
	collapse_cd = 2.2
	_mark_weapon("붕괴")
	apply_damage(spent * collapse_scale(), true)
	changed.emit()


func gimmick_label() -> String:
	if int(_gimmick_p().get("lattice_n", 0)) > 0:
		match boss_stage():
			0:
				return "외피"
			1:
				return "격자"
			_:
				return "코어"
	var g := _gimmick()
	match g:
		"gap_heal":
			return "공백 복원"
		"pulse_heal":
			if float(current_enemy().get("regen", 0.0)) > 0.0:
				return "재생 · 주기 복원"
			return "주기 복원"
		"shell":
			return "외피"
		"fragment":
			return "분열"
		"recursion":
			return "재귀"
		"compression":
			return "압축"
		"regen":
			if float(current_enemy().get("regen", 0.0)) > 0.0:
				return "재생"
			return ""
	return ""


func boss_stage() -> int:
	if shell_ratio() > 0.0:
		return 0
	if part_count() > 1:
		return 1
	return 2


func gap_ratio() -> float:
	if _gimmick() != "gap_heal":
		return 0.0
	var gap := float(_gimmick_p().get("gap", 0.80))
	return clampf(undamaged_t / maxf(gap, 0.001), 0.0, 1.0)


func part_count() -> int:
	var n := 0
	for p in parts:
		if p > 0.0:
			n += 1
	return n


func shell_ratio() -> float:
	var mx := float(_gimmick_p().get("shell", 0.0))
	if mx <= 0.0:
		return 0.0
	return clampf(shell_hp / mx, 0.0, 1.0)


func compression() -> float:
	return clampf(fight_t / 40.0, 0.0, 1.0)


func apply_damage(amount: float, hit_all: bool) -> void:
	if not alive or front_cleared:
		return
	if amount <= 0.0:
		return
	var shell_before := shell_hp
	var parts_before: Array[float] = []
	for p in parts:
		parts_before.append(p)
	var cap := max_mana()
	if cap > 0.0 and mana / cap >= 0.9:
		amount *= 1.0 + _passive("high_mana_dmg")
	var defense := float(current_enemy().get("defense", 0.0))
	if _gimmick() == "compression":
		defense += fight_t * float(_gimmick_p().get("def_per_sec", 0.0))
	amount /= 1.0 + defense
	if _gimmick() == "shell" and shell_hp > 0.0:
		var dr := float(_gimmick_p().get("dr", 0.0))
		var vs_shell := amount * (1.0 - dr)
		if vs_shell >= shell_hp:
			amount = vs_shell - shell_hp
			shell_hp = 0.0
		else:
			shell_hp -= vs_shell
			amount = 0.0
	if amount > 0.0 and not parts.is_empty():
		if hit_all:
			for i in parts.size():
				if parts[i] > 0.0:
					parts[i] = maxf(0.0, parts[i] - amount)
		else:
			for i in parts.size():
				if parts[i] > 0.0:
					parts[i] = maxf(0.0, parts[i] - amount)
					break
	var hit := shell_hp < shell_before
	if not hit:
		for i in parts.size():
			if i < parts_before.size() and parts[i] < parts_before[i]:
				hit = true
				break
	if hit:
		undamaged_t = 0.0
	_sync_integrity()
	_try_fragment()
	if _all_parts_dead():
		_resolve_death()


func _gimmick() -> String:
	return str(current_enemy().get("gimmick", "none"))


func _gimmick_p() -> Dictionary:
	var raw = current_enemy().get("gimmick_p", {})
	if raw is Dictionary:
		return raw
	return {}


func _mark_weapon(wname: String) -> void:
	if wname not in _used_weapons:
		_used_weapons.append(wname)


func _sync_integrity() -> void:
	var s := 0.0
	for i in parts.size():
		parts[i] = maxf(0.0, parts[i])
		s += parts[i]
	integrity = s


func _first_living_index() -> int:
	for i in parts.size():
		if parts[i] > 0.0:
			return i
	return -1


func _all_parts_dead() -> bool:
	if parts.is_empty():
		return true
	for p in parts:
		if p > 0.0:
			return false
	return true


func _try_fragment() -> void:
	if fragmented:
		return
	if _gimmick() != "fragment":
		return
	if _all_parts_dead():
		return
	var max_hp := float(current_enemy().get("max_integrity", 1.0))
	var at := float(_gimmick_p().get("at", 0.45))
	if integrity > max_hp * at:
		return
	var n := int(_gimmick_p().get("n", 2))
	if n < 2:
		n = 2
	var share := integrity / float(n)
	parts.clear()
	_part_cap.clear()
	for _i in n:
		parts.append(share)
		_part_cap.append(share)
	fragmented = true
	_sync_integrity()


func _resolve_death() -> void:
	if _gimmick() == "recursion" and recursion_left > 0:
		_respawn_recursion()
		return
	_on_kill()


func _respawn_recursion() -> void:
	recursion_left -= 1
	var gp := _gimmick_p()
	var n := int(gp.get("n", 1))
	if n < 1:
		n = 1
	var scale := float(gp.get("scale", 1.0))
	var max_hp := float(current_enemy().get("max_integrity", 1.0))
	var hp := max_hp * scale
	parts.clear()
	_part_cap.clear()
	for _i in n:
		parts.append(hp)
		_part_cap.append(hp)
	alive = true
	_sync_integrity()


func _tick_gimmicks(dt: float) -> void:
	if not alive or front_cleared:
		return
	fight_t += dt
	var g := _gimmick()
	var gp := _gimmick_p()
	if g == "gap_heal":
		undamaged_t += dt
		var gap := float(gp.get("gap", 0.80))
		if undamaged_t >= gap:
			var max_hp := float(current_enemy().get("max_integrity", 1.0))
			var heal := float(gp.get("heal_frac", 0.0)) * max_hp
			_add_heal(heal)
			undamaged_t = 0.0
			gap_healed.emit(heal)
			if t_beam < 0.0:
				recon_heal_n += 1
				recon_heal_amt += heal
		return
	if g != "pulse_heal":
		return
	var period := float(gp.get("period", 10.0))
	if period <= 0.0:
		return
	heal_acc += dt
	if heal_acc >= period:
		heal_acc -= period
		_add_heal(float(gp.get("heal", 0.0)))


func _tick_regen(dt: float) -> void:
	if not alive or front_cleared:
		return
	var regen := enemy_regen()
	if regen <= 0.0:
		return
	_add_heal(regen * dt)


func _add_heal(amount: float) -> void:
	if amount <= 0.0 or parts.is_empty():
		return
	var idx := _first_living_index()
	if idx < 0:
		return
	var healed := parts[idx] + amount
	if idx < _part_cap.size():
		healed = minf(healed, _part_cap[idx])
	parts[idx] = healed
	_sync_integrity()


func try_upgrade(id: String) -> void:
	if id == "pulse":
		id = "shooter"
	var upgrades: Dictionary = Data.upgrades()
	if not upgrades.has(id):
		return
	var row: Dictionary = upgrades[id]
	var mx := int(row.get("max", 0))
	if mx > 0 and _lv(id) >= mx:
		return
	var weapon_id := _weapon_id_for_upgrade(id)
	if not weapon_id.is_empty() and not weapon_unlocked(weapon_id):
		return
	var cost := Data.upgrade_cost(id, _lv(id))
	if not try_spend(cost):
		return
	var gen_ids: Array[String] = Data.generator_upgrade_ids()
	if id in gen_ids:
		spent_core += cost
	if id == "shooter" or id == "pulse" or id == "rapid":
		spent_shooter += cost
	if id == "prod" and t_first_prod < 0.0:
		t_first_prod = play_t
	if id == "tap_coupling" and t_tap_branch < 0.0:
		t_tap_branch = play_t
	if (id == "auto_dynamo" or id == "flywheel") and t_auto_branch < 0.0:
		t_auto_branch = play_t
	match id:
		"prod":
			lv_prod += 1
		"cap":
			lv_cap += 1
		"tap_coupling":
			lv_tap_coupling += 1
		"auto_dynamo":
			lv_auto_dynamo += 1
		"flywheel":
			lv_flywheel += 1
		"shooter":
			lv_shooter += 1
		"rapid":
			lv_rapid += 1
		"beam":
			lv_beam += 1
		"eff":
			lv_eff += 1
		"lance":
			lv_lance += 1
		"prism":
			lv_prism += 1
		"collapse":
			lv_collapse += 1
	save_game()
	changed.emit()


func _lv(id: String) -> int:
	match id:
		"prod":
			return lv_prod
		"cap":
			return lv_cap
		"tap_coupling":
			return lv_tap_coupling
		"auto_dynamo":
			return lv_auto_dynamo
		"flywheel":
			return lv_flywheel
		"shooter", "pulse":
			return lv_shooter
		"rapid":
			return lv_rapid
		"beam":
			return lv_beam
		"eff":
			return lv_eff
		"lance":
			return lv_lance
		"prism":
			return lv_prism
		"collapse":
			return lv_collapse
	return 0


func _weapon_id_for_upgrade(id: String) -> String:
	match id:
		"shooter", "pulse", "rapid", "beam", "lance", "prism", "collapse":
			if id == "pulse" or id == "rapid":
				return "shooter"
			return id
		"eff":
			return "beam"
	var upgrades: Dictionary = Data.upgrades()
	if upgrades.has(id):
		return str(upgrades[id].get("weapon", ""))
	return ""


func level_of(id: String) -> int:
	return _lv(id)


func toggle_passive(id: String) -> void:
	if id in equipped:
		equipped.erase(id)
	else:
		if equipped.size() >= 4:
			equipped.pop_front()
		equipped.append(id)
	save_game()
	changed.emit()


func _spawn(id: String) -> void:
	enemy_id = id
	front_cleared = false
	var e: Dictionary = Data.enemies()[id]
	var max_hp := float(e.get("max_integrity", 1.0))
	parts.clear()
	_part_cap.clear()
	var gp: Dictionary = {}
	var raw = e.get("gimmick_p", {})
	if raw is Dictionary:
		gp = raw
	shell_hp = float(gp.get("shell", 0.0))
	var n := int(gp.get("lattice_n", 0))
	if n > 0:
		var lhp := float(gp.get("lattice_hp", 40.0))
		for _i in n:
			parts.append(lhp)
			_part_cap.append(lhp)
		var core := float(gp.get("core", max_hp))
		parts.append(core)
		_part_cap.append(core)
		_sync_integrity()
	else:
		parts.append(max_hp)
		_part_cap.append(max_hp)
		integrity = max_hp
	fight_t = 0.0
	heal_acc = 0.0
	undamaged_t = 0.0
	fragmented = false
	recursion_left = 0
	if str(e.get("gimmick", "none")) == "recursion":
		recursion_left = int(gp.get("waves", 0))
	alive = true
	beam_on = false
	_used_shooter = false
	_used_pulse = false
	_used_beam = false
	_used_weapons.clear()
	if id not in sighted:
		sighted.append(id)
	if id == "reconstructor" and not equipped_at.has("reconstructor"):
		equipped_at["reconstructor"] = play_t


func _on_kill() -> void:
	if not alive:
		return
	alive = false
	integrity = 0.0
	parts.clear()
	_part_cap.clear()
	shell_hp = 0.0
	beam_on = false
	var ret: float = float(current_enemy().get("max_integrity", 0.0)) * _passive("kill_return")
	mana = minf(max_mana(), mana + ret)
	clear_t[enemy_id] = play_t
	if enemy_id == "lattice":
		if t_lattice < 0.0:
			t_lattice = play_t
		if not equipped_at.has("lattice"):
			equipped_at["lattice"] = play_t
	_record_archive(enemy_id)
	killed.emit(enemy_id)
	get_tree().create_timer(1.1).timeout.connect(_advance_front, CONNECT_ONE_SHOT)


func _record_archive(id: String) -> void:
	if id not in archived:
		archived.append(id)
	if _used_weapons.is_empty():
		archive_relic[id] = "기록 없음"
	else:
		archive_relic[id] = " · ".join(_used_weapons)
	_sync_owned_unlocks()


func _advance_front() -> void:
	_apply_front_gate()
	save_game()
	changed.emit()


func _sync_front() -> void:
	_apply_front_gate()


func _apply_front_gate() -> void:
	var order: Array[String] = Data.enemy_order()
	var next_any := ""
	var next_playable := ""
	var last_archived := ""
	for id in order:
		if id in archived:
			last_archived = id
			continue
		if next_any == "":
			next_any = id
		if next_playable == "" and _enemy_playable_at_tier(id):
			next_playable = id
	if next_playable != "":
		if _resume_combat and enemy_id == next_playable and alive:
			_resume_combat = false
			if enemy_id not in sighted:
				sighted.append(enemy_id)
			return
		_resume_combat = false
		_spawn(next_playable)
		return
	_resume_combat = false
	front_cleared = true
	alive = false
	integrity = 0.0
	parts.clear()
	_part_cap.clear()
	shell_hp = 0.0
	beam_on = false
	shooter_on = false
	if next_any != "":
		if last_archived != "":
			enemy_id = last_archived
		return
	if order.size() > 0:
		enemy_id = order[order.size() - 1]


func _enemy_playable_at_tier(id: String) -> bool:
	var enemies: Dictionary = Data.enemies()
	if not enemies.has(id):
		return false
	var e: Dictionary = enemies[id]
	var req := str(e.get("req_tier", "cyan"))
	var req_rank := Data.tier_order().find(req)
	if req_rank < 0:
		return false
	if not bool(e.get("playable", true)):
		return false
	return req_rank <= tier_rank()


func save_game() -> void:
	var c := ConfigFile.new()
	c.set_value("core", "mana", mana)
	c.set_value("core", "tier", tier)
	c.set_value("core", "lv_prod", lv_prod)
	c.set_value("core", "lv_cap", lv_cap)
	c.set_value("core", "lv_tap_coupling", lv_tap_coupling)
	c.set_value("core", "lv_auto_dynamo", lv_auto_dynamo)
	c.set_value("core", "lv_flywheel", lv_flywheel)
	c.set_value("core", "flywheel_charge", flywheel_charge)
	c.set_value("core", "idle_t", idle_t)
	c.set_value("core", "lv_shooter", lv_shooter)
	c.set_value("core", "lv_pulse", lv_shooter)
	c.set_value("core", "lv_rapid", lv_rapid)
	c.set_value("core", "lv_beam", lv_beam)
	c.set_value("core", "lv_eff", lv_eff)
	c.set_value("core", "lv_lance", lv_lance)
	c.set_value("core", "lv_prism", lv_prism)
	c.set_value("core", "lv_collapse", lv_collapse)
	c.set_value("core", "enemy_id", enemy_id)
	c.set_value("core", "equipped", equipped)
	c.set_value("core", "owned", owned)
	c.set_value("core", "archived", archived)
	c.set_value("core", "sighted", sighted)
	c.set_value("core", "archive_relic", archive_relic)
	c.set_value("core", "discharge_unlocked", discharge_unlocked)
	c.set_value("telemetry", "play_t", play_t)
	c.set_value("telemetry", "t_first_prod", t_first_prod)
	c.set_value("telemetry", "t_tap_branch", t_tap_branch)
	c.set_value("telemetry", "t_auto_branch", t_auto_branch)
	c.set_value("telemetry", "mana_tap", mana_tap)
	c.set_value("telemetry", "mana_passive", mana_passive)
	c.set_value("telemetry", "tap_active_t", tap_active_t)
	c.set_value("telemetry", "flywheel_high_t", flywheel_high_t)
	c.set_value("telemetry", "spent_core", spent_core)
	c.set_value("telemetry", "spent_shooter", spent_shooter)
	c.set_value("telemetry", "clear_t", clear_t)
	c.set_value("telemetry", "t_lattice", t_lattice)
	c.set_value("telemetry", "t_violet", t_violet)
	c.set_value("telemetry", "t_beam", t_beam)
	c.set_value("telemetry", "equipped_at", equipped_at)
	c.set_value("telemetry", "shooter_ok", shooter_ok)
	c.set_value("telemetry", "shooter_starve", shooter_starve)
	c.set_value("telemetry", "recon_fight_t", recon_fight_t)
	c.set_value("telemetry", "recon_heal_n", recon_heal_n)
	c.set_value("telemetry", "recon_heal_amt", recon_heal_amt)
	c.set_value("combat", "alive", alive)
	c.set_value("combat", "front_cleared", front_cleared)
	c.set_value("combat", "integrity", integrity)
	c.set_value("combat", "shell_hp", shell_hp)
	c.set_value("combat", "parts", Array(parts))
	c.set_value("combat", "part_cap", Array(_part_cap))
	c.set_value("combat", "undamaged_t", undamaged_t)
	c.set_value("combat", "fight_t", fight_t)
	c.set_value("combat", "heal_acc", heal_acc)
	c.set_value("combat", "fragmented", fragmented)
	c.set_value("combat", "recursion_left", recursion_left)
	c.set_value("combat", "used_weapons", Array(_used_weapons))
	c.save(SAVE_PATH)
	_write_telemetry()


func reset_game() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(SAVE_PATH)
	if FileAccess.file_exists(TELEMETRY_PATH):
		DirAccess.remove_absolute(TELEMETRY_PATH)
	_restore_fresh_state()
	_sync_front()
	changed.emit()


func _restore_fresh_state() -> void:
	mana = 80.0
	tier = "cyan"
	lv_prod = 0
	lv_cap = 0
	lv_tap_coupling = 0
	lv_auto_dynamo = 0
	lv_flywheel = 0
	flywheel_charge = 0.0
	idle_t = 0.0
	tap_cd = 0.0
	lv_shooter = 0
	lv_rapid = 0
	lv_beam = 0
	lv_eff = 0
	lv_lance = 0
	lv_prism = 0
	lv_collapse = 0
	tap_flash = 0.0
	shot_flash = 0.0
	equipped.clear()
	equipped.append("produce_20")
	owned.clear()
	owned.append("produce_20")
	owned.append("cap_50")
	owned.append("kill_return")
	owned.append("anti_regen")
	discharge_unlocked = false
	undamaged_t = 0.0
	_clear_telemetry()
	_sync_owned_unlocks()
	archived.clear()
	sighted.clear()
	archive_relic.clear()
	beam_on = false
	shooter_on = false
	shooter_cd = 0.0
	pulse_cd = 0.0
	enemy_id = "shard"
	integrity = 90.0
	alive = true
	erosion = 0.4
	front_cleared = false
	parts.clear()
	_part_cap.clear()
	shell_hp = 0.0
	fight_t = 0.0
	heal_acc = 0.0
	fragmented = false
	recursion_left = 0
	lance_cd = 0.0
	prism_cd = 0.0
	collapse_cd = 0.0
	_burst_t = 0.0
	_used_weapons.clear()
	_used_shooter = false
	_used_pulse = false
	_used_beam = false
	_resume_combat = false
	_save_acc = 0.0
	last_dps = 0.0
	last_net = 0.0


func load_game() -> void:
	var c := ConfigFile.new()
	if c.load(SAVE_PATH) != OK:
		_restore_fresh_state()
		return
	mana = float(c.get_value("core", "mana", mana))
	tier = str(c.get_value("core", "tier", "cyan"))
	lv_prod = int(c.get_value("core", "lv_prod", 0))
	lv_cap = int(c.get_value("core", "lv_cap", 0))
	lv_tap_coupling = int(c.get_value("core", "lv_tap_coupling", 0))
	lv_auto_dynamo = int(c.get_value("core", "lv_auto_dynamo", 0))
	lv_flywheel = int(c.get_value("core", "lv_flywheel", 0))
	flywheel_charge = clampf(float(c.get_value("core", "flywheel_charge", 0.0)), 0.0, 1.0)
	idle_t = maxf(0.0, float(c.get_value("core", "idle_t", 0.0)))
	tap_cd = 0.0
	lv_shooter = int(c.get_value("core", "lv_shooter", c.get_value("core", "lv_pulse", 0)))
	lv_rapid = int(c.get_value("core", "lv_rapid", 0))
	lv_beam = int(c.get_value("core", "lv_beam", 0))
	lv_eff = int(c.get_value("core", "lv_eff", 0))
	lv_lance = int(c.get_value("core", "lv_lance", 0))
	lv_prism = int(c.get_value("core", "lv_prism", 0))
	lv_collapse = int(c.get_value("core", "lv_collapse", 0))
	enemy_id = str(c.get_value("core", "enemy_id", "shard"))
	var eq = c.get_value("core", "equipped", equipped)
	equipped.clear()
	for x in eq:
		equipped.append(str(x))
	if c.has_section_key("core", "owned"):
		_load_id_list(c, "owned", owned)
	_load_id_list(c, "archived", archived)
	_load_id_list(c, "sighted", sighted)
	archive_relic = c.get_value("core", "archive_relic", {})
	discharge_unlocked = bool(c.get_value("core", "discharge_unlocked", false))
	play_t = float(c.get_value("telemetry", "play_t", 0.0))
	t_first_prod = float(c.get_value("telemetry", "t_first_prod", -1.0))
	t_tap_branch = float(c.get_value("telemetry", "t_tap_branch", -1.0))
	t_auto_branch = float(c.get_value("telemetry", "t_auto_branch", -1.0))
	mana_tap = float(c.get_value("telemetry", "mana_tap", 0.0))
	mana_passive = float(c.get_value("telemetry", "mana_passive", 0.0))
	tap_active_t = float(c.get_value("telemetry", "tap_active_t", 0.0))
	flywheel_high_t = float(c.get_value("telemetry", "flywheel_high_t", 0.0))
	spent_core = float(c.get_value("telemetry", "spent_core", 0.0))
	spent_shooter = float(c.get_value("telemetry", "spent_shooter", 0.0))
	clear_t = c.get_value("telemetry", "clear_t", {})
	if clear_t == null or not (clear_t is Dictionary):
		clear_t = {}
	t_lattice = float(c.get_value("telemetry", "t_lattice", -1.0))
	t_violet = float(c.get_value("telemetry", "t_violet", -1.0))
	t_beam = float(c.get_value("telemetry", "t_beam", -1.0))
	equipped_at = c.get_value("telemetry", "equipped_at", {})
	if equipped_at == null or not (equipped_at is Dictionary):
		equipped_at = {}
	shooter_ok = int(c.get_value("telemetry", "shooter_ok", 0))
	shooter_starve = int(c.get_value("telemetry", "shooter_starve", 0))
	recon_fight_t = float(c.get_value("telemetry", "recon_fight_t", 0.0))
	recon_heal_n = int(c.get_value("telemetry", "recon_heal_n", 0))
	recon_heal_amt = float(c.get_value("telemetry", "recon_heal_amt", 0.0))
	var old_kills = c.get_value("core", "kills", {})
	if archived.is_empty() and old_kills is Dictionary:
		for k in old_kills:
			if int(old_kills[k]) > 0 and str(k) not in archived:
				archived.append(str(k))
	mana = clampf(mana, 0.0, max_mana())
	beam_on = false
	shooter_on = false
	_resume_combat = false
	if c.has_section("combat"):
		alive = bool(c.get_value("combat", "alive", alive))
		front_cleared = bool(c.get_value("combat", "front_cleared", front_cleared))
		integrity = float(c.get_value("combat", "integrity", integrity))
		shell_hp = float(c.get_value("combat", "shell_hp", shell_hp))
		_copy_float_array(c.get_value("combat", "parts", []), parts)
		_copy_float_array(c.get_value("combat", "part_cap", []), _part_cap)
		undamaged_t = maxf(0.0, float(c.get_value("combat", "undamaged_t", 0.0)))
		fight_t = maxf(0.0, float(c.get_value("combat", "fight_t", 0.0)))
		heal_acc = maxf(0.0, float(c.get_value("combat", "heal_acc", 0.0)))
		fragmented = bool(c.get_value("combat", "fragmented", false))
		recursion_left = int(c.get_value("combat", "recursion_left", 0))
		_load_id_list(c, "used_weapons", _used_weapons, "combat")
		if not parts.is_empty():
			_sync_integrity()
		_resume_combat = alive and not front_cleared
	_sync_owned_unlocks()


func _ensure_owned(id: String) -> void:
	if id not in owned:
		owned.append(id)


func _sync_owned_unlocks() -> void:
	var table: Dictionary = Data.passives()
	if table.has("anti_regen") and bool(table["anti_regen"].get("playable", false)):
		_ensure_owned("anti_regen")
	for id in ["tap_echo", "idle_coil", "shot_lens"]:
		if table.has(id) and bool(table[id].get("playable", false)):
			_ensure_owned(id)
	for id in ["beam_eff", "high_mana", "after_burst"]:
		if passive_unlocked(id):
			_ensure_owned(id)


func _load_id_list(c: ConfigFile, key: String, into: Array[String], section: String = "core") -> void:
	into.clear()
	var raw = c.get_value(section, key, [])
	if raw == null:
		return
	for x in raw:
		into.append(str(x))


func _copy_float_array(raw, into: Array[float]) -> void:
	into.clear()
	if raw == null:
		return
	if raw is Array or raw is PackedFloat32Array or raw is PackedFloat64Array:
		for x in raw:
			into.append(float(x))


func _telemetry_snapshot() -> Dictionary:
	return {
		"play_t": play_t,
		"t_first_prod": t_first_prod,
		"t_tap_branch": t_tap_branch,
		"t_auto_branch": t_auto_branch,
		"mana_tap": mana_tap,
		"mana_passive": mana_passive,
		"tap_active_t": tap_active_t,
		"flywheel_high_t": flywheel_high_t,
		"spent_core": spent_core,
		"spent_shooter": spent_shooter,
		"clear_t": clear_t,
		"t_lattice": t_lattice,
		"t_violet": t_violet,
		"t_beam": t_beam,
		"equipped_at": equipped_at,
		"shooter_ok": shooter_ok,
		"shooter_starve": shooter_starve,
		"recon_fight_t": recon_fight_t,
		"recon_heal_n": recon_heal_n,
		"recon_heal_amt": recon_heal_amt,
	}


func _write_telemetry() -> void:
	var f := FileAccess.open(TELEMETRY_PATH, FileAccess.WRITE)
	if f == null:
		return
	f.store_string(JSON.stringify(_telemetry_snapshot()))


func _clear_telemetry() -> void:
	play_t = 0.0
	t_first_prod = -1.0
	t_tap_branch = -1.0
	t_auto_branch = -1.0
	mana_tap = 0.0
	mana_passive = 0.0
	tap_active_t = 0.0
	flywheel_high_t = 0.0
	spent_core = 0.0
	spent_shooter = 0.0
	clear_t = {}
	t_lattice = -1.0
	t_violet = -1.0
	t_beam = -1.0
	equipped_at = {}
	shooter_ok = 0
	shooter_starve = 0
	recon_fight_t = 0.0
	recon_heal_n = 0
	recon_heal_amt = 0.0
