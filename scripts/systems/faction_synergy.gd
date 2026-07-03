extends Node
class_name FactionSynergy
## 梦游症 - 派系搭配效果计算引擎 v0.5
## 同派系协同 + 10 组跨派系反应(行为型)
## v0.5 变更:
##   - 9 条已有反应加行为副作用(交易代价/反伤/自伤/召唤/眩晕等)
##   - 新增 COMMERCE x FAITH "沉默交易"
##   - 反应触发时发 reaction_triggered 信号(EventBus)

const SYNERGY_THRESHOLDS = {
	2: {"attack_bonus": 0.15},
	3: {"attack_bonus": 0.25},
	4: {"attack_bonus": 0.40},
}

# 跨派系反应完整表(行为型 — v0.5 重新设计)
# 每条都至少有 1 个行为副作用,不止是数值加成
const CROSS_REACTIONS = {
	# TECH x NATURE / NATURE x TECH — 生化异变 (DOT + 自身中毒回血)
	"nature_tech":     {"name":"生化异变","desc":"攻击附带持续伤害,但生物自身每秒回 1% HP (变异共生)","dot_ratio":0.15,"dot_duration":3.0,"self_regen":0.01,"color":Color(0.55,0.85,0.55)},
	"tech_nature":     {"name":"生化异变","desc":"攻击附带持续伤害,生物自身每秒回 1% HP","dot_ratio":0.15,"dot_duration":3.0,"self_regen":0.01,"color":Color(0.55,0.85,0.55)},
	# FAITH x MEMORY / MEMORY x FAITH — 回响 (死亡复活战斗 + 复活期间无敌)
	"faith_memory":    {"name":"回响","desc":"生物死亡后以 50% HP 复活战斗 2 秒,期间无敌","revive_duration":2.0,"revive_hp_ratio":0.5,"color":Color(0.85,0.65,0.85)},
	"memory_faith":    {"name":"回响","desc":"生物死亡后以 50% HP 复活战斗 2 秒,期间无敌","revive_duration":2.0,"revive_hp_ratio":0.5,"color":Color(0.85,0.65,0.85)},
	# TECH x COMMERCE / COMMERCE x TECH — 军火交易 (攻速+但每次攻击自伤)
	"tech_commerce":   {"name":"军火交易","desc":"所有生物攻速 +20%,但每次攻击消耗 2 HP (弹药成本)","speed_bonus":0.20,"attack_self_cost":2.0,"color":Color(0.95,0.78,0.55)},
	"commerce_tech":   {"name":"军火交易","desc":"所有生物攻速 +20%,每次攻击消耗 2 HP","speed_bonus":0.20,"attack_self_cost":2.0,"color":Color(0.95,0.78,0.55)},
	# NATURE x FAITH / FAITH x NATURE — 神圣花园 (城堡回血 + 战外每 30 秒召唤 1 树苗)
	"nature_faith":    {"name":"神圣花园","desc":"城堡每秒恢复 1.5 护盾,每 30 秒召唤 1 树苗 8 秒","castle_regen":1.5,"periodic_summon":true,"summon_id":"sapling","summon_interval":30.0,"summon_duration":8.0,"color":Color(0.65,0.92,0.75)},
	"faith_nature":    {"name":"神圣花园","desc":"城堡每秒恢复 1.5 护盾,每 30 秒召唤 1 树苗","castle_regen":1.5,"periodic_summon":true,"summon_id":"sapling","summon_interval":30.0,"summon_duration":8.0,"color":Color(0.65,0.92,0.75)},
	# TECH x MEMORY / MEMORY x TECH — 数字幽灵 (攻击 10% 概率眩晕 + 死亡留幻象攻击 3 秒)
	"tech_memory":     {"name":"数字幽灵","desc":"攻击 10% 概率眩晕 0.5 秒,生物死亡后留幻象继续攻击 3 秒","stun_chance":0.10,"stun_duration":0.5,"phantom_after_death":3.0,"color":Color(0.65,0.55,0.95)},
	"memory_tech":     {"name":"数字幽灵","desc":"攻击 10% 概率眩晕 0.5 秒,死亡后留幻象 3 秒","stun_chance":0.10,"stun_duration":0.5,"phantom_after_death":3.0,"color":Color(0.65,0.55,0.95)},
	# COMMERCE x MEMORY / MEMORY x COMMERCE — 古董交易 (额外金币 + 30% 概率额外掉落基础治疗包)
	"commerce_memory": {"name":"古董交易","desc":"击杀敌人额外 5 金币,30% 概率掉落 1 基础治疗包","gold_per_kill":5,"drop_chance":0.30,"drop_item":"basic_heal_pack","color":Color(0.95,0.88,0.65)},
	"memory_commerce": {"name":"古董交易","desc":"击杀敌人额外 5 金币,30% 概率掉落 1 基础治疗包","gold_per_kill":5,"drop_chance":0.30,"drop_item":"basic_heal_pack","color":Color(0.95,0.88,0.65)},
	# NATURE x COMMERCE / COMMERCE x NATURE — 资源掠夺 (攻击+10% + 护盾-20 一次性,触发时全队回复 50HP)
	"nature_commerce": {"name":"资源掠夺","desc":"所有生物攻击 +10%,城堡护盾 -20,但触发时全队回复 50 HP (一次性收益)","trade_attack":0.10,"trade_shield_penalty":20,"burst_heal":50.0,"color":Color(0.75,0.95,0.55)},
	"commerce_nature": {"name":"资源掠夺","desc":"所有生物攻击 +10%,城堡护盾 -20,触发时全队回 50 HP","trade_attack":0.10,"trade_shield_penalty":20,"burst_heal":50.0,"color":Color(0.75,0.95,0.55)},
	# TECH x FAITH / FAITH x TECH — 圣装机兵 (技术+攻击,信仰+攻速 + 触发时全队 +1 护盾)
	"tech_faith":      {"name":"圣装机兵","desc":"技术派系 +15% 攻击,信仰派系 +15% 攻速,触发时全队 +1 护盾","tech_atk":0.15,"faith_spd":0.15,"team_shield_burst":1.0,"color":Color(0.95,0.85,0.95)},
	"faith_tech":      {"name":"圣装机兵","desc":"技术派系 +15% 攻击,信仰派系 +15% 攻速,触发时 +1 护盾","tech_atk":0.15,"faith_spd":0.15,"team_shield_burst":1.0,"color":Color(0.95,0.85,0.95)},
	# NATURE x MEMORY / MEMORY x NATURE — 远古记忆 (范围+15% + 攻击 5% 概率定身 0.8 秒)
	"nature_memory":   {"name":"远古记忆","desc":"全队攻击范围 +15%,攻击 5% 概率定身敌人 0.8 秒","range_bonus":0.15,"root_chance":0.05,"root_duration":0.8,"color":Color(0.85,0.95,0.65)},
	"memory_nature":   {"name":"远古记忆","desc":"全队攻击范围 +15%,攻击 5% 概率定身 0.8 秒","range_bonus":0.15,"root_chance":0.05,"root_duration":0.8,"color":Color(0.85,0.95,0.65)},
	# COMMERCE x FAITH / FAITH x COMMERCE — 沉默交易 (新增 v0.5)
	# 每 10 秒对随机敌人沉默 2 秒,期间城堡护盾 -10 (交易代价)
	"commerce_faith":  {"name":"沉默交易","desc":"每 10 秒沉默随机敌人 2 秒,城堡护盾 -10 (交易代价)","silence_interval":10.0,"silence_duration":2.0,"silence_shield_cost":10.0,"color":Color(0.85,0.55,0.65)},
	"faith_commerce":  {"name":"沉默交易","desc":"每 10 秒沉默随机敌人 2 秒,城堡护盾 -10","silence_interval":10.0,"silence_duration":2.0,"silence_shield_cost":10.0,"color":Color(0.85,0.55,0.65)},
}

var _faction_tag = {
	GameData.Faction.TECH: "tech",
	GameData.Faction.FAITH: "faith",
	GameData.Faction.NATURE: "nature",
	GameData.Faction.COMMERCE: "commerce",
	GameData.Faction.MEMORY: "memory",
}

func analyze_synergies(creature_ids: Array[String]) -> Dictionary:
	var result = {
		"faction_synergy": {},
		"cross_reactions": [],
		"global_attack_bonus": 0.0,
		"global_speed_bonus": 0.0,
		"global_range_bonus": 0.0,
		"dot_effects": [],
		"castle_regen": 0.0,
		"revive_enabled": false,
		"revive_duration": 0.0,
		"stun_chance": 0.0,
		"stun_duration": 0.0,
		"gold_per_kill": 0,
		"trade_attack_bonus": 0.0,
		"trade_shield_penalty": 0,
		"tech_attack_bonus": 0.0,
		"faith_speed_bonus": 0.0,
		"root_chance": 0.0,
		"root_duration": 0.0,
		"silence_enabled": false,
		"silence_interval": 0.0,
		"silence_duration": 0.0,
		"silence_shield_cost": 0.0,
		"attack_self_cost": 0.0,
		"self_regen": 0.0,
		"phantom_after_death": 0.0,
		"burst_heal": 0.0,
		"team_shield_burst": 0.0,
		"drop_chance": 0.0,
		"drop_item": "",
		"periodic_summon": false,
		"summon_interval": 0.0,
		"summon_id": "",
	}

	if creature_ids.is_empty():
		return result

	var faction_counts = {}
	var present_factions = []

	for id in creature_ids:
		var data = GameData.get_creature_data(id)
		if data.is_empty(): continue
		var f = data["faction"]
		faction_counts[f] = faction_counts.get(f, 0) + 1

	for f in faction_counts:
		present_factions.append(f)

	# 同派系协同
	for f in faction_counts:
		var cnt = faction_counts[f]
		if cnt >= 2:
			var lv = mini(cnt, 4)
			if SYNERGY_THRESHOLDS.has(lv):
				var bonus = SYNERGY_THRESHOLDS[lv].duplicate()
				result["faction_synergy"][f] = {"level":lv,"count":cnt,"bonus":bonus}
				result["global_attack_bonus"] = max(result["global_attack_bonus"], bonus.get("attack_bonus",0.0))

	# 跨派系反应 — 去重(同名反应只触发一次)
	var tags = []
	for f in present_factions:
		if _faction_tag.has(f): tags.append(_faction_tag[f])

	for i in range(tags.size()):
		for j in range(tags.size()):
			if i == j: continue
			var key = tags[i] + "_" + tags[j]
			if CROSS_REACTIONS.has(key):
				var r = CROSS_REACTIONS[key].duplicate()
				var already_added = false
				for existing in result["cross_reactions"]:
					if existing["name"] == r["name"]:
						already_added = true
						break
				if not already_added:
					result["cross_reactions"].append(r)
					_aggregate_reaction(r, result)

	# 反应触发信号(若至少有一条新反应)
	if not result["cross_reactions"].is_empty():
		EventBus.reaction_triggered.emit(result["cross_reactions"])

	return result

func _aggregate_reaction(r: Dictionary, result: Dictionary) -> void:
	if r.has("speed_bonus"): result["global_speed_bonus"] += r["speed_bonus"]
	if r.has("dot_ratio"): result["dot_effects"].append({"ratio":r["dot_ratio"],"duration":r["dot_duration"]})
	if r.has("castle_regen"): result["castle_regen"] += r["castle_regen"]
	if r.has("revive_duration"):
		result["revive_enabled"] = true
		result["revive_duration"] = max(result["revive_duration"], r["revive_duration"])
	if r.has("revive_hp_ratio"): pass
	if r.has("stun_chance"): result["stun_chance"] += r["stun_chance"]
	if r.has("stun_duration"): result["stun_duration"] = max(result["stun_duration"], r["stun_duration"])
	if r.has("gold_per_kill"): result["gold_per_kill"] += r["gold_per_kill"]
	if r.has("trade_attack"): result["trade_attack_bonus"] += r["trade_attack"]
	if r.has("trade_shield_penalty"): result["trade_shield_penalty"] += r["trade_shield_penalty"]
	if r.has("tech_atk"): result["tech_attack_bonus"] += r["tech_atk"]
	if r.has("faith_spd"): result["faith_speed_bonus"] += r["faith_spd"]
	if r.has("range_bonus"): result["global_range_bonus"] += r["range_bonus"]
	# v0.5 新增
	if r.has("silence_interval"):
		result["silence_enabled"] = true
		result["silence_interval"] = r["silence_interval"]
		result["silence_duration"] = r["silence_duration"]
		result["silence_shield_cost"] = r["silence_shield_cost"]
	if r.has("root_chance"): result["root_chance"] += r["root_chance"]
	if r.has("root_duration"): result["root_duration"] = max(result["root_duration"], r["root_duration"])
	if r.has("attack_self_cost"): result["attack_self_cost"] += r["attack_self_cost"]
	if r.has("self_regen"): result["self_regen"] += r["self_regen"]
	if r.has("phantom_after_death"): result["phantom_after_death"] = max(result["phantom_after_death"], r["phantom_after_death"])
	if r.has("burst_heal"): result["burst_heal"] = max(result["burst_heal"], r["burst_heal"])
	if r.has("team_shield_burst"): result["team_shield_burst"] += r["team_shield_burst"]
	if r.has("drop_chance"): result["drop_chance"] = max(result["drop_chance"], r["drop_chance"])
	if r.has("drop_item"): result["drop_item"] = r["drop_item"]
	if r.has("periodic_summon"):
		result["periodic_summon"] = true
		result["summon_interval"] = r["summon_interval"]
		result["summon_id"] = r["summon_id"]
