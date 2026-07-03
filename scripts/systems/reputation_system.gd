extends Node
## 好感度/声望系统 - 各派系独立数值追踪与奖励

class_name ReputationSystem

# 声望等级阈值
const RANK_THRESHOLDS = {
	0: "冷淡",
	100: "中立",
	300: "友善",
	600: "尊敬",
	1000: "崇拜",
}

# 各派系商店物品
var faction_shops: Dictionary = {}

func _ready():
	_init_shops()

func _init_shops():
	faction_shops = {
		GameData.Faction.TECH: {
			"creatures": ["steel_hound","tesla_core","war_mech"],
			"modules": ["reinforced_armor","energy_amplifier","scanner_drone"],
			"costs": {"steel_hound":300,"tesla_core":800,"war_mech":2000,"reinforced_armor":500,"energy_amplifier":1200,"scanner_drone":350},
		},
		GameData.Faction.FAITH: {
			"creatures": ["ritual_bell","phantom_priest","divine_guard"],
			"modules": ["prayer_altar","holy_totem","blessing_aura"],
			"costs": {"ritual_bell":300,"phantom_priest":800,"divine_guard":2000,"prayer_altar":500,"holy_totem":1200,"blessing_aura":1000},
		},
		GameData.Faction.NATURE: {
			"creatures": ["spore_flower","vine_guardian","elder_treant"],
			"modules": ["thorn_armor","fertile_soil","warehouse_module"],
			"costs": {"spore_flower":300,"vine_guardian":800,"elder_treant":2000,"thorn_armor":500,"fertile_soil":1200,"warehouse_module":400},
		},
		GameData.Faction.COMMERCE: {
			"creatures": ["mercenary_broker","stock_analyst","trade_prince"],
			"modules": ["trade_license","black_market"],
			"costs": {"mercenary_broker":300,"stock_analyst":800,"trade_prince":2000,"trade_license":500,"black_market":1200},
		},
		GameData.Faction.MEMORY: {
			"creatures": ["nostalgia_singer","historian","archivist"],
			"modules": ["memory_shard","time_dilator"],
			"costs": {"nostalgia_singer":300,"historian":800,"archivist":2000,"memory_shard":500,"time_dilator":1200},
		},
	}

func get_rank(faction: int) -> String:
	var rep = GameData.faction_reputation.get(faction, 0)
	var best = "冷淡"
	for threshold in RANK_THRESHOLDS:
		if rep >= threshold:
			best = RANK_THRESHOLDS[threshold]
	return best

func get_shop_items(faction: int) -> Dictionary:
	return faction_shops.get(faction, {})

func buy_item(faction: int, item_id: String) -> bool:
	var shop = faction_shops.get(faction, {})
	var costs = shop.get("costs", {})
	if not costs.has(item_id): return false
	var cost = costs[item_id]
	if not GameData.spend_resource("gold", cost): return false

	if item_id in shop.get("creatures", []):
		GameData.add_creature_duplicate(item_id)
		EventBus.creature_acquired.emit(item_id)
	elif item_id in shop.get("modules", []):
		# 允许同模块叠加购买(比如圣图腾买多个 = 多个槽位)
		GameData.player_inventory_modules.append(item_id)
		EventBus.module_acquired.emit(item_id)
	return true

func add_battle_reputation(node_data: Dictionary):
	var continent = node_data.get("continent", "")
	var faction_map = {
		"tech": GameData.Faction.TECH,
		"faith": GameData.Faction.FAITH,
		"nature": GameData.Faction.NATURE,
		"commerce": GameData.Faction.COMMERCE,
		"memory": GameData.Faction.MEMORY,
	}
	var amount = 30
	if node_data.get("is_boss", false): amount = 100
	if node_data.get("type", "") == "story": amount = 10
	if continent in faction_map:
		GameData.add_reputation(faction_map[continent], amount)
	elif continent == "neutral":
		for f in [GameData.Faction.TECH,GameData.Faction.FAITH,GameData.Faction.NATURE,GameData.Faction.COMMERCE,GameData.Faction.MEMORY]:
			GameData.add_reputation(f, amount / 2)
