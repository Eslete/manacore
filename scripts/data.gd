class_name Data
extends RefCounted

## Vertical-slice tables only. Add rows here; do not grow Game.gd.

const TIER_CYAN := "cyan"


static func tier_order() -> Array[String]:
	return ["cyan", "violet", "amber", "red", "white"]


static func tiers() -> Dictionary:
	# PROVISIONAL: violet cost 80000. Amber's 100000 is now too close and must be retuned later.
	# PROVISIONAL: violet synthesis is a Core milestone (output/capacity), not a boss trophy.
	# PROVISIONAL: req_output 8 (~lv_prod 16 with produce_20); req_capacity 10000 (several 저장 or cap_50 + a few).
	return {
		"cyan": {
			"name": "시안",
			"from": "",
			"cost": 0.0,
			"unlock_after": "",
			"playable": true,
		},
		"violet": {
			"name": "바이올렛",
			"from": "cyan",
			"cost": 80000.0,
			"unlock_after": "",
			"req_output": 8.0,
			"req_capacity": 10000.0,
			"playable": true,
		},
		"amber": {
			"name": "앰버",
			"from": "violet",
			"cost": 100000.0,
			"unlock_after": "compression",
			"playable": false,
		},
		"red": {
			"name": "레드",
			"from": "amber",
			"cost": 500000.0,
			"unlock_after": "",
			"playable": false,
		},
		"white": {
			"name": "화이트",
			"from": "red",
			"cost": 2500000.0,
			"unlock_after": "",
			"playable": false,
		},
	}


static func region_order() -> Array[String]:
	return ["earth_orbit", "atmosphere", "satellite", "solar"]


static func regions() -> Dictionary:
	return {
		"earth_orbit": {
			"name": "저궤도",
			"label": "저궤도 · 침식 전선",
			"req_tier": "cyan",
			"visual": "sky",
			"playable": true,
		},
		"atmosphere": {
			"name": "대기권",
			"label": "대기권 · 전리층",
			"req_tier": "violet",
			"visual": "atmo",
			"playable": true,
		},
		"satellite": {
			"name": "위성권",
			"label": "위성권 · 계측 변형",
			"req_tier": "violet",
			"visual": "sat",
			"playable": true,
		},
		"solar": {
			"name": "태양권",
			"label": "태양권 · 미개방",
			"req_tier": "amber",
			"visual": "solar",
			"playable": false,
		},
	}


static func weapon_ids() -> Array[String]:
	return ["shooter", "beam", "lance", "prism", "collapse"]


static func weapons() -> Dictionary:
	return {
		"shooter": {
			"id": "shooter",
			"name": "사격기",
			"kind": "projectile",
			"req_tier": "cyan",
			"unlock_after": "",
			"upgrade": "shooter",
			"visual": "pulse",
			"slot": "active",
			"playable": true,
		},
		"beam": {
			"id": "beam",
			"name": "빔",
			"kind": "beam",
			"req_tier": "violet",
			"unlock_after": "",
			"upgrade": "beam",
			"visual": "beam",
			"playable": true,
		},
		"lance": {
			"id": "lance",
			"name": "Lance",
			"kind": "burst",
			"req_tier": "violet",
			"unlock_after": "resonator",
			"upgrade": "lance",
			"visual": "lance",
			"playable": false,
		},
		"prism": {
			"id": "prism",
			"name": "Prism",
			"kind": "spread",
			"req_tier": "violet",
			"unlock_after": "shell",
			"upgrade": "prism",
			"visual": "prism",
			"playable": false,
		},
		"collapse": {
			"id": "collapse",
			"name": "Collapse",
			"kind": "percent",
			"req_tier": "violet",
			"unlock_after": "ion_veil",
			"upgrade": "collapse",
			"frac": 0.35,
			"visual": "collapse",
			"playable": false,
		},
	}


static func enemies() -> Dictionary:
	return {
		"shard": {
			"id": "shard",
			"name": "파편 결정",
			"codename": "FRAGMENT CRYSTAL",
			"blurb": "약한 침식. 재생 없음.",
			"region": "지구권 저궤도",
			"form": "결정형",
			"trait": "자발적 구조 복원이 관측되지 않는다.",
			"note": "파단면이 고르다. 모체에서 떨어져 나온 조각으로 보인다.",
			"max_integrity": 90.0,
			"regen": 0.0,
			"defense": 0.0,
			"gimmick": "none",
			"visual": "shard",
			"region_id": "earth_orbit",
			"req_tier": "cyan",
			"playable": true,
			"gimmick_p": {},
		},
		"splinter": {
			"id": "splinter",
			"name": "미세 파편",
			"codename": "MICRO SPLINTER",
			"blurb": "조금 더 두꺼운 파편.",
			"region": "지구권 저궤도",
			"form": "파편 / 결정",
			"trait": "재생은 없다. 단면 밀도가 조금 높다.",
			"note": "첫 파편과 같은 계열. 맞히는 횟수가 늘어난다.",
			"max_integrity": 180.0,
			"regen": 0.0,
			"defense": 0.0,
			"gimmick": "none",
			"visual": "splinter",
			"region_id": "earth_orbit",
			"req_tier": "cyan",
			"playable": true,
			"gimmick_p": {},
		},
		# PROVISIONAL: regenerator shell HP / DR retuned for Shooter 1–2.
		"regenerator": {
			"id": "regenerator",
			"name": "삭마 다면체",
			"codename": "ABLATIVE POLYHEDRON",
			"blurb": "외피가 내부 안정도를 가린다.",
			"region": "지구권 저궤도",
			"form": "다면체",
			"trait": "외피 붕괴 전까지 내부 손상이 거의 기록되지 않는다.",
			"note": "외피 감쇠는 약 40%. 외피 소실 후 내부는 일반 침식체와 같다.",
			"max_integrity": 200.0,
			"regen": 0.0,
			"defense": 0.0,
			"gimmick": "shell",
			"visual": "polyhedron",
			"region_id": "earth_orbit",
			"req_tier": "cyan",
			"playable": true,
			"gimmick_p": {"shell": 120.0, "dr": 0.40},
		},
		"needle": {
			"id": "needle",
			"name": "침상 결정",
			"codename": "NEEDLE CRYSTAL",
			"blurb": "가늘고 길다. 맞히는 데 시간이 걸린다.",
			"region": "지구권 저궤도",
			"form": "침상 결정",
			"trait": "연속 사격이 단발보다 유효하다.",
			"note": "침상 구조. 단발로는 안정도가 잘 떨어지지 않는다.",
			"max_integrity": 360.0,
			"regen": 0.0,
			"defense": 0.0,
			"gimmick": "none",
			"visual": "needle",
			"region_id": "earth_orbit",
			"req_tier": "cyan",
			"playable": true,
			"gimmick_p": {},
		},
		"plate": {
			"id": "plate",
			"name": "차폐판",
			"codename": "ABLATIVE PLATE",
			"blurb": "두꺼운 외피가 내부를 가린다.",
			"region": "지구권 저궤도",
			"form": "차폐판",
			"trait": "외피 붕괴 전까지 내부 손상이 거의 기록되지 않는다.",
			"note": "외피 감쇠는 약 45%. 외피 소실 후 내부는 일반 침식체와 같다.",
			"max_integrity": 320.0,
			"regen": 0.0,
			"defense": 0.0,
			"gimmick": "shell",
			"visual": "plate",
			"region_id": "earth_orbit",
			"req_tier": "cyan",
			"playable": true,
			"gimmick_p": {"shell": 280.0, "dr": 0.45},
		},
		"cluster": {
			"id": "cluster",
			"name": "파편 무리",
			"codename": "SHARD CLUSTER",
			"blurb": "파편이 다섯으로 뭉쳐 있다.",
			"region": "지구권 저궤도",
			"form": "파편 무리",
			"trait": "무리를 이루지만 분리되지 않는다.",
			"note": "다섯 조각으로 보이지만 하나의 안정도로 계측된다.",
			"max_integrity": 560.0,
			"regen": 0.0,
			"defense": 0.0,
			"gimmick": "none",
			"visual": "cluster",
			"region_id": "earth_orbit",
			"req_tier": "cyan",
			"playable": true,
			"gimmick_p": {"n": 5},
		},
		"orbit_ring": {
			"id": "orbit_ring",
			"name": "궤도 고리",
			"codename": "ORBITAL RING",
			"blurb": "궤도 위에 고리가 감겨 있다.",
			"region": "지구권 저궤도",
			"form": "고리",
			"trait": "고리 구조. 재생은 없다.",
			"note": "저궤도에서 관측된 대형 고리. 격자에 앞서 나타난다.",
			"max_integrity": 780.0,
			"regen": 0.0,
			"defense": 0.0,
			"gimmick": "none",
			"visual": "ring",
			"region_id": "earth_orbit",
			"req_tier": "cyan",
			"playable": true,
			"gimmick_p": {},
		},
		# PROVISIONAL: lattice 3-stage shell / lattice / core retuned for Shooter 6–8.
		"lattice": {
			"id": "lattice",
			"name": "중첩 격자",
			"codename": "OVERLAPPING LATTICE",
			"blurb": "외피 → 격자 → 코어. 3단 구조.",
			"region": "지구권 외곽 전선",
			"form": "격자 / 중첩체",
			"trait": "외피 붕괴 후 내부 격자가 드러나고, 격자가 무너지면 코어가 노출된다.",
			"note": "3단 구조. 외피 감쇠 약 30%. 격자 면은 세 겹으로 계측되었다. 코어 노출 직전 일부 면이 관측 각도와 맞지 않았다.",
			"max_integrity": 900.0,
			"regen": 0.0,
			"defense": 0.0,
			"gimmick": "shell",
			"visual": "boss",
			"region_id": "earth_orbit",
			"req_tier": "cyan",
			"playable": true,
			"gimmick_p": {"shell": 480.0, "dr": 0.30, "lattice_n": 3, "lattice_hp": 220.0, "core": 900.0},
		},
		# PROVISIONAL: reconstructor HP / gap / heal_frac are first-pass, not final.
		"reconstructor": {
			"id": "reconstructor",
			"name": "재구성체",
			"codename": "RECONSTRUCTOR",
			"blurb": "피격이 끊기면 안정도가 크게 복원된다.",
			"region": "대기권 전리층",
			"form": "재구성체",
			"trait": "피격 공백이 약 1.2초를 넘으면 안정도가 급격히 복원된다.",
			"note": "연속 조사 없이는 계측이 되돌아간다. Discrete pulse보다 continuous discharge에 취약하다.",
			"max_integrity": 960.0,
			"regen": 0.0,
			"defense": 0.0,
			"gimmick": "gap_heal",
			"visual": "reconstruct",
			"region_id": "atmosphere",
			"req_tier": "violet",
			"playable": true,
			"gimmick_p": {"gap": 1.20, "heal_frac": 0.40},
		},
		# PROVISIONAL: resonator HP / regen / pulse heal are first-pass, not final. Later Violet rows below are also first-pass.
		"resonator": {
			"id": "resonator",
			"name": "공명핵",
			"codename": "RESONANT NODE",
			"blurb": "주기 복원 — 창(Lance)이 필요하다.",
			"region": "대기권 하층",
			"form": "공명체",
			"trait": "손상 후 일정 주기로 대규모 구조 복원이 발생한다.",
			"note": "복원 주기는 약 10초로 일정하다. 연속 조사보다 단발 고출력에 취약하다.",
			"max_integrity": 7200.0,
			"regen": 8.0,
			"defense": 0.0,
			"gimmick": "pulse_heal",
			"visual": "heal",
			"region_id": "atmosphere",
			"req_tier": "violet",
			"playable": false,
			"gimmick_p": {"period": 10.0, "heal": 1800.0},
		},
		"shell": {
			"id": "shell",
			"name": "삭마각",
			"codename": "ABLATIVE SHELL",
			"blurb": "외피가 피해를 흡수한다.",
			"region": "대기권 중층",
			"form": "각질 / 차폐층",
			"trait": "외피 붕괴 전까지 내부 구조가 관측되지 않는다.",
			"note": "외피 감쇠는 약 60%. 외피 소실 후 내부는 일반 침식체와 같다.",
			"max_integrity": 16000.0,
			"regen": 0.0,
			"defense": 0.0,
			"gimmick": "shell",
			"visual": "shell",
			"region_id": "atmosphere",
			"req_tier": "violet",
			"playable": false,
			"gimmick_p": {"shell": 12000.0, "dr": 0.6},
		},
		"ion_veil": {
			"id": "ion_veil",
			"name": "이온장막",
			"codename": "ION VEIL",
			"blurb": "재생과 주기 복원이 겹친다.",
			"region": "대기권 상층 전선",
			"form": "확산 장막",
			"trait": "지속 재생과 주기적 재정렬이 동시에 관측된다.",
			"note": "장막 밀도는 고도에 비례한다. 단발 관통이 유효하다.",
			"max_integrity": 38000.0,
			"regen": 72.0,
			"defense": 0.0,
			"gimmick": "pulse_heal",
			"visual": "heal_boss",
			"region_id": "atmosphere",
			"req_tier": "violet",
			"playable": false,
			"gimmick_p": {"period": 10.0, "heal": 14000.0},
		},
		"fragment": {
			"id": "fragment",
			"name": "분열표본",
			"codename": "SPLIT SAMPLE",
			"blurb": "임계 손상 시 세 조각으로 갈라진다.",
			"region": "정지궤도 표본대",
			"form": "결정 / 분열체",
			"trait": "안정도 45% 부근에서 구조가 세 갈래로 분리된다.",
			"note": "분리 직후 계측값이 세 배로 찍혔다. 장비 교정 오류로 처리한다.",
			"max_integrity": 24000.0,
			"regen": 0.0,
			"defense": 0.0,
			"gimmick": "fragment",
			"visual": "fragment",
			"region_id": "satellite",
			"req_tier": "violet",
			"playable": false,
			"gimmick_p": {"at": 0.45, "n": 3},
		},
		"recursion": {
			"id": "recursion",
			"name": "재귀상",
			"codename": "RECURSIVE IMAGE",
			"blurb": "축소 복제가 파동처럼 반복된다.",
			"region": "위성 음영대",
			"form": "상 / 중첩 복제",
			"trait": "본체와 유사한 축소체가 파동 단위로 출현한다.",
			"note": "두 번째 파동의 스케일이 기록과 맞지 않았다. 측정 변형으로 남긴다.",
			"max_integrity": 18000.0,
			"regen": 18.0,
			"defense": 0.0,
			"gimmick": "recursion",
			"visual": "recurse",
			"region_id": "satellite",
			"req_tier": "violet",
			"playable": false,
			"gimmick_p": {"n": 3, "scale": 0.35, "waves": 2},
		},
		"compression": {
			"id": "compression",
			"name": "압축핵",
			"codename": "COMPRESSION CORE",
			"blurb": "방어가 시간에 따라 두꺼워진다. 붕괴/창.",
			"region": "외곽 위성 결절",
			"form": "압축체",
			"trait": "관측 시간이 길수록 표면 밀도가 상승한다.",
			"note": "후반 계측은 신뢰 구간을 벗어난다. 조기 고출력 개입이 권고된다.",
			"max_integrity": 36000.0,
			"regen": 48.0,
			"defense": 0.0,
			"gimmick": "compression",
			"visual": "compress",
			"region_id": "satellite",
			"req_tier": "violet",
			"playable": false,
			"gimmick_p": {"def_per_sec": 0.08},
		},
	}


static func enemy_order() -> Array[String]:
	return [
		"shard",
		"splinter",
		"regenerator",
		"needle",
		"plate",
		"cluster",
		"orbit_ring",
		"lattice",
		"reconstructor",
		"resonator",
		"shell",
		"ion_veil",
		"fragment",
		"recursion",
		"compression",
	]


static func upgrades() -> Dictionary:
	# PROVISIONAL: shooter max and leftover weapon costs are first-pass, not final.
	# PROVISIONAL: cap base 48 / growth 1.18 so first 저장 is not 12 mana for +2000 tank. prod stays 18 / 1.22.
	# PROVISIONAL: tap_coupling / auto_dynamo / flywheel costs, caps, and branch tags are first-pass.
	return {
		"prod": {"name": "응축 장치", "action": "추가", "blurb": "생산 상승", "base": 18.0, "growth": 1.22, "visual": "ring", "domain": "generator"},
		"cap": {"name": "저장 장치", "action": "추가", "blurb": "용량 상승", "base": 48.0, "growth": 1.18, "visual": "core", "domain": "generator"},
		"tap_coupling": {"name": "수동 결합", "action": "추가", "blurb": "탭 배율", "base": 25.0, "growth": 1.25, "max": 8, "branch": "tap", "domain": "generator", "visual": "ring"},
		"auto_dynamo": {"name": "안정 다이나모", "action": "추가", "blurb": "자동 배율", "base": 25.0, "growth": 1.25, "max": 8, "branch": "auto", "domain": "generator", "visual": "core"},
		"flywheel": {"name": "플라이휠", "action": "추가", "blurb": "비가동 안정", "base": 40.0, "growth": 1.30, "max": 5, "branch": "auto", "domain": "generator", "visual": "core"},
		"shooter": {"name": "사격기", "blurb": "탄 피해", "base": 16.0, "growth": 1.2, "visual": "pulse", "domain": "weapon", "max": 8},
		"rapid": {"name": "연사", "blurb": "사격 시작 후 연속 발사", "base": 24.0, "growth": 1.0, "max": 1, "visual": "pulse", "domain": "weapon"},
		"beam": {"name": "빔", "blurb": "지속 피해", "base": 22.0, "growth": 1.22, "visual": "beam", "domain": "weapon"},
		"eff": {"name": "효율", "blurb": "빔 소비 감소", "base": 28.0, "growth": 1.2, "visual": "conduit", "domain": "weapon"},
		"lance": {"name": "Lance", "blurb": "단발 관통", "base": 32.0, "growth": 1.22, "visual": "lance", "domain": "weapon"},
		"prism": {"name": "Prism", "blurb": "확산 피해", "base": 36.0, "growth": 1.22, "visual": "prism", "domain": "weapon"},
		"collapse": {"name": "Collapse", "blurb": "비율 붕괴", "base": 44.0, "growth": 1.24, "visual": "collapse", "domain": "weapon"},
	}


static func upgrade_cost(id: String, level: int) -> float:
	var u: Dictionary = upgrades()[id]
	return float(u.get("base", 10.0)) * pow(float(u.get("growth", 1.2)), level)


static func passives() -> Dictionary:
	# PROVISIONAL: tap_echo 0.55 so deep Tap vs optimized Auto has identity (~1.83×). idle_coil / shot_lens still first-pass.
	return {
		"produce_20": {"name": "응축 링", "blurb": "생산 +20%", "kind": "prod_mult", "value": 0.20, "visual": "ring", "req_tier": "cyan", "unlock_after": "", "playable": true},
		"cap_50": {"name": "저장핵", "blurb": "최대 마력 +50%", "kind": "cap_mult", "value": 0.50, "visual": "core", "req_tier": "cyan", "unlock_after": "", "playable": true},
		"tap_echo": {"name": "공진 탭", "blurb": "탭 배율", "kind": "tap_mult", "value": 0.55, "visual": "ring", "req_tier": "cyan", "unlock_after": "", "playable": true},
		"idle_coil": {"name": "유휴 코일", "blurb": "자동 배율", "kind": "auto_mult", "value": 0.30, "visual": "core", "req_tier": "cyan", "unlock_after": "", "playable": true},
		"shot_lens": {"name": "사격 렌즈", "blurb": "사격 피해", "kind": "shooter_dmg", "value": 0.25, "visual": "pulse", "req_tier": "cyan", "unlock_after": "", "playable": true},
		"beam_eff": {"name": "빔 도관", "blurb": "빔 소비 -15%", "kind": "beam_cost", "value": 0.15, "visual": "conduit", "req_tier": "violet", "unlock_after": "", "playable": true},
		"anti_regen": {"name": "붕괴 가루", "blurb": "적 재생 -10%", "kind": "anti_regen", "value": 0.10, "visual": "dust", "req_tier": "cyan", "unlock_after": "", "playable": true},
		"kill_return": {"name": "회수 파편", "blurb": "처치 시 마력 8% 반환", "kind": "kill_return", "value": 0.08, "visual": "shard", "req_tier": "cyan", "unlock_after": "", "playable": true},
		"high_mana": {"name": "만충 증폭", "blurb": "마력 90% 이상일 때 피해 +25%", "kind": "high_mana_dmg", "value": 0.25, "visual": "flare", "req_tier": "violet", "unlock_after": "resonator", "playable": false},
		"after_burst": {"name": "잔류 가속", "blurb": "버스트 후 생산 +15%", "kind": "after_burst", "value": 0.15, "visual": "wake", "req_tier": "violet", "unlock_after": "shell", "playable": false},
	}


static func relic_drops() -> Dictionary:
	return {
		"shard": "produce_20",
		"splinter": "cap_50",
		"regenerator": "kill_return",
		"needle": "shot_lens",
		"plate": "tap_echo",
		"cluster": "idle_coil",
		"orbit_ring": "anti_regen",
		"lattice": "",
	}


static func passive_ids() -> Array[String]:
	return [
		"produce_20",
		"cap_50",
		"tap_echo",
		"idle_coil",
		"shot_lens",
		"beam_eff",
		"anti_regen",
		"kill_return",
		"high_mana",
		"after_burst",
	]


static func generator_upgrade_ids() -> Array[String]:
	return ["prod", "cap", "tap_coupling", "auto_dynamo", "flywheel"]


# PROVISIONAL: DESIGN light/deep tap vs Auto. time_eq 4.0 was ~20× idle at 5 taps/s.
static func tap_rules() -> Dictionary:
	return { "time_eq": 0.35, "cooldown": 0.20 }


# PROVISIONAL: delay 6 / ramp 18 / decay 3 kept. bonus_per_lv 0.10 so max Auto identity is clearer vs Tap.
static func flywheel_rules() -> Dictionary:
	return { "delay": 6.0, "ramp": 18.0, "decay": 3.0, "bonus_per_lv": 0.10 }


# PROVISIONAL: shooter cooldown / damage / cost keys are first-pass, not final.
static func shooter_rules() -> Dictionary:
	return {
		"cd": 0.95,
		"dmg_base": 9.0,
		"dmg_per_lv": 6.5,
		"cost_base": 12.0,
		"cost_per_lv": 4.0,
	}


# PROVISIONAL: discharge cost is first-pass, not final.
static func discharge_rules() -> Dictionary:
	return { "cost": 4800.0, "observe_id": "reconstructor" }


# PROVISIONAL: generator group titles / membership are first-pass, not final.
static func generator_groups() -> Array:
	return [
		{ "id": "shared", "title": "공유", "ids": ["prod", "cap"] },
		{ "id": "tap", "title": "탭", "ids": ["tap_coupling"] },
		{ "id": "auto", "title": "자동", "ids": ["auto_dynamo", "flywheel"] },
	]


static func weapon_upgrade_ids() -> Array[String]:
	var out: Array[String] = []
	var table: Dictionary = weapons()
	for id in weapon_ids():
		if bool(table[id].get("playable", true)):
			out.append(str(table[id].get("upgrade", id)))
			if id == "shooter":
				out.append("rapid")
	if table.has("beam") and bool(table["beam"].get("playable", true)):
		out.append("eff")
	return out


static func passive_ids_for_ui() -> Array[String]:
	var out: Array[String] = []
	var table: Dictionary = passives()
	for id in passive_ids():
		if bool(table[id].get("playable", true)):
			out.append(id)
	return out


static func space_ids() -> Array[String]:
	var out: Array[String] = []
	var table: Dictionary = enemies()
	for id in enemy_order():
		if not table.has(id):
			continue
		if bool(table[id].get("playable", true)):
			out.append(id)
	return out
