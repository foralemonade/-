extends Control
## 生物图鉴 UI — 阶段2-3 任务
## 展示 21 只生物(已获取高亮,未获取灰显)
## 派系筛选 + 反应发现子页面

var current_faction_filter: int = -1  # -1 = 全部
var current_tab: String = "creatures"  # "creatures" | "reactions"
var creature_buttons: Array[Dictionary] = []
var detail_panel: Panel = null
var detail_name_lbl: Label = null
var detail_fac_lbl: Label = null
var detail_stats_lbl: Label = null
var detail_skill_lbl: Label = null
var detail_desc_lbl: Label = null

func _ready() -> void:
	_setup_ui()
	_connect_signals()
	_refresh_creature_list()

func _setup_ui() -> void:
	# 背景
	var bg := ColorRect.new()
	bg.size = Vector2(1280, 720)
	bg.color = Color(0.13, 0.10, 0.22)
	add_child(bg)

	# 标题
	var title := Label.new()
	title.text = "梦游症 · 生物图鉴"
	title.position = Vector2(0, 10)
	title.size = Vector2(1280, 40)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", Color(0.85, 0.75, 1.0))
	add_child(title)

	# 返回按钮
	var back := Button.new()
	back.position = Vector2(20, 14)
	back.size = Vector2(80, 34)
	back.text = "< 返回"
	back.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/main_menu.tscn"))
	add_child(back)

	# 标签页切换
	var tab_creatures := Button.new()
	tab_creatures.name = "TabCreatures"
	tab_creatures.position = Vector2(120, 60)
	tab_creatures.size = Vector2(140, 32)
	tab_creatures.text = "生物图鉴"
	tab_creatures.pressed.connect(_on_tab_pressed.bind("creatures"))
	add_child(tab_creatures)

	var tab_reactions := Button.new()
	tab_reactions.name = "TabReactions"
	tab_reactions.position = Vector2(270, 60)
	tab_reactions.size = Vector2(140, 32)
	tab_reactions.text = "反应发现"
	tab_reactions.pressed.connect(_on_tab_pressed.bind("reactions"))
	add_child(tab_reactions)

	# 派系筛选按钮
	var faction_filters: Array = [
		{"f": -1, "name": "全部", "col": Color(0.85, 0.75, 1.0)},
		{"f": GameData.Faction.TECH,     "name": "技术", "col": Color(0.55, 0.80, 0.95)},
		{"f": GameData.Faction.FAITH,    "name": "信仰", "col": Color(0.95, 0.78, 0.82)},
		{"f": GameData.Faction.NATURE,   "name": "自然", "col": Color(0.68, 0.92, 0.82)},
		{"f": GameData.Faction.COMMERCE, "name": "商业", "col": Color(0.95, 0.82, 0.72)},
		{"f": GameData.Faction.MEMORY,   "name": "记忆", "col": Color(0.78, 0.65, 0.95)},
	]
	for i in range(faction_filters.size()):
		var ff: Dictionary = faction_filters[i]
		var btn := Button.new()
		btn.position = Vector2(430 + i * 130, 60)
		btn.size = Vector2(120, 32)
		btn.text = ff["name"]
		btn.modulate = ff["col"]
		btn.pressed.connect(_on_faction_filter.bind(ff["f"]))
		add_child(btn)

	# 收藏进度标签
	var progress_lbl := Label.new()
	progress_lbl.name = "ProgressLabel"
	progress_lbl.position = Vector2(0, 100)
	progress_lbl.size = Vector2(1280, 22)
	progress_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	progress_lbl.add_theme_font_size_override("font_size", 13)
	progress_lbl.add_theme_color_override("font_color", Color(0.95, 0.88, 0.55))
	add_child(progress_lbl)

	# 左:生物列表滚动
	var list_scroll := ScrollContainer.new()
	list_scroll.position = Vector2(30, 135)
	list_scroll.size = Vector2(540, 555)
	add_child(list_scroll)

	var list_box := VBoxContainer.new()
	list_box.name = "CreatureList"
	list_box.add_theme_constant_override("separation", 4)
	list_scroll.add_child(list_box)

	# 右:详情面板
	detail_panel = Panel.new()
	detail_panel.position = Vector2(590, 135)
	detail_panel.size = Vector2(660, 555)
	add_child(detail_panel)

	var panel_bg := ColorRect.new()
	panel_bg.size = Vector2(660, 555)
	panel_bg.color = Color(0.16, 0.13, 0.24, 0.7)
	panel_bg.position = Vector2(0, 0)
	detail_panel.add_child(panel_bg)

	detail_name_lbl = Label.new()
	detail_name_lbl.name = "DetailName"
	detail_name_lbl.position = Vector2(20, 20)
	detail_name_lbl.size = Vector2(620, 36)
	detail_name_lbl.add_theme_font_size_override("font_size", 24)
	detail_name_lbl.add_theme_color_override("font_color", Color(0.95, 0.92, 0.98))
	detail_panel.add_child(detail_name_lbl)

	detail_fac_lbl = Label.new()
	detail_fac_lbl.name = "DetailFaction"
	detail_fac_lbl.position = Vector2(20, 60)
	detail_fac_lbl.size = Vector2(620, 24)
	detail_fac_lbl.add_theme_font_size_override("font_size", 15)
	detail_panel.add_child(detail_fac_lbl)

	detail_stats_lbl = Label.new()
	detail_stats_lbl.name = "DetailStats"
	detail_stats_lbl.position = Vector2(20, 95)
	detail_stats_lbl.size = Vector2(620, 200)
	detail_stats_lbl.add_theme_font_size_override("font_size", 13)
	detail_stats_lbl.add_theme_color_override("font_color", Color(0.85, 0.85, 0.92))
	detail_stats_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detail_panel.add_child(detail_stats_lbl)

	detail_skill_lbl = Label.new()
	detail_skill_lbl.name = "DetailSkill"
	detail_skill_lbl.position = Vector2(20, 305)
	detail_skill_lbl.size = Vector2(620, 110)
	detail_skill_lbl.add_theme_font_size_override("font_size", 14)
	detail_skill_lbl.add_theme_color_override("font_color", Color(1.0, 0.88, 0.65))
	detail_skill_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detail_panel.add_child(detail_skill_lbl)

	detail_desc_lbl = Label.new()
	detail_desc_lbl.name = "DetailDesc"
	detail_desc_lbl.position = Vector2(20, 425)
	detail_desc_lbl.size = Vector2(620, 110)
	detail_desc_lbl.add_theme_font_size_override("font_size", 12)
	detail_desc_lbl.add_theme_color_override("font_color", Color(0.75, 0.70, 0.85))
	detail_desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detail_panel.add_child(detail_desc_lbl)

func _connect_signals() -> void:
	EventBus.creature_acquired.connect(_on_creature_acquired)

func _refresh_creature_list() -> void:
	if current_tab != "creatures":
		_refresh_reaction_list()
		return
	var list: VBoxContainer = get_node_or_null("CreatureList")
	if list == null:
		return
	for child in list.get_children():
		child.queue_free()
	creature_buttons.clear()
	var db: Dictionary = GameData.creature_database
	for cid: String in db:
		var data: Dictionary = db[cid]
		var faction: int = data.get("faction", 0)
		if current_faction_filter != -1 and faction != current_faction_filter:
			continue
		var row := _create_creature_row(cid, data)
		list.add_child(row)
		creature_buttons.append({"cid": cid, "row": row})
	_update_progress_label()

func _create_creature_row(cid: String, data: Dictionary) -> PanelContainer:
	var owned: bool = GameData.has_creature(cid)
	var count: int = GameData.get_creature_count(cid)
	var hp: float = GameData.get_creature_hp(cid)
	var max_hp: float = GameData.get_creature_max_hp(cid)
	var stage: int = GameData.get_creature_injury_stage(cid)
	var is_dead: bool = GameData.is_creature_dead(cid)

	var row := PanelContainer.new()
	row.custom_minimum_size = Vector2(510, 60)
	var bg := ColorRect.new()
	bg.size = Vector2(510, 60)
	bg.color = Color(0.20, 0.16, 0.30, 0.6)
	row.add_child(bg)

	var btn := Button.new()
	btn.custom_minimum_size = Vector2(510, 60)
	btn.flat = true
	btn.position = Vector2(0, 0)

	# 派系色条
	var swatch := ColorRect.new()
	swatch.position = Vector2(8, 8)
	swatch.size = Vector2(8, 44)
	swatch.color = GameData.get_faction_color(data.get("faction", 0))
	btn.add_child(swatch)

	# 名字
	var name_lbl := Label.new()
	name_lbl.position = Vector2(24, 8)
	name_lbl.size = Vector2(220, 24)
	name_lbl.add_theme_font_size_override("font_size", 15)
	if not owned:
		name_lbl.text = "???"
		name_lbl.add_theme_color_override("font_color", Color(0.50, 0.45, 0.55))
	else:
		name_lbl.text = data.get("name", cid)
		name_lbl.add_theme_color_override("font_color", Color(0.95, 0.92, 0.98))
	btn.add_child(name_lbl)

	# 派系 + 定位
	var fac_lbl := Label.new()
	fac_lbl.position = Vector2(24, 34)
	fac_lbl.size = Vector2(220, 20)
	fac_lbl.add_theme_font_size_override("font_size", 11)
	if owned:
		fac_lbl.text = "%s · %s" % [GameData.get_faction_name(data.get("faction", 0)), GameData.get_role_name(data.get("role", 0))]
		fac_lbl.add_theme_color_override("font_color", Color(0.75, 0.70, 0.85))
	else:
		fac_lbl.text = "未获取"
		fac_lbl.add_theme_color_override("font_color", Color(0.50, 0.45, 0.55))
	btn.add_child(fac_lbl)

	# 拥有数量
	if owned and count > 1:
		var count_lbl := Label.new()
		count_lbl.position = Vector2(250, 12)
		count_lbl.size = Vector2(50, 36)
		count_lbl.text = "×%d" % count
		count_lbl.add_theme_font_size_override("font_size", 18)
		count_lbl.add_theme_color_override("font_color", Color(1.0, 0.88, 0.55))
		btn.add_child(count_lbl)

	# HP 显示
	if owned:
		var hp_lbl := Label.new()
		hp_lbl.position = Vector2(310, 12)
		hp_lbl.size = Vector2(190, 18)
		hp_lbl.add_theme_font_size_override("font_size", 12)
		if is_dead:
			hp_lbl.text = "已阵亡"
			hp_lbl.add_theme_color_override("font_color", Color(0.55, 0.50, 0.55))
		else:
			hp_lbl.text = "HP: %d/%d" % [int(hp), int(max_hp)]
			var ratio: float = hp / max_hp if max_hp > 0.0 else 0.0
			if ratio < 0.25:
				hp_lbl.add_theme_color_override("font_color", Color(0.95, 0.45, 0.45))
			elif ratio < 0.5:
				hp_lbl.add_theme_color_override("font_color", Color(0.95, 0.70, 0.50))
			else:
				hp_lbl.add_theme_color_override("font_color", Color(0.75, 0.85, 0.95))
		btn.add_child(hp_lbl)

		var stage_lbl := Label.new()
		stage_lbl.position = Vector2(310, 32)
		stage_lbl.size = Vector2(190, 18)
		stage_lbl.add_theme_font_size_override("font_size", 11)
		var stage_name: String = ["健康", "轻伤", "重伤", "濒死", "已亡"][stage] if stage >= 0 and stage < 5 else "?"
		stage_lbl.text = "状态: " + stage_name
		stage_lbl.add_theme_color_override("font_color", Color(0.65, 0.65, 0.75))
		btn.add_child(stage_lbl)

	# 获取途径
	var source_lbl := Label.new()
	source_lbl.position = Vector2(0, 0)
	source_lbl.size = Vector2(0, 0)
	# 把"获取关卡"放在行底右侧
	if owned:
		var src := _get_creature_source(cid)
		if src != "":
			var src_lbl := Label.new()
			src_lbl.position = Vector2(310, 50)
			src_lbl.size = Vector2(190, 14)
			src_lbl.text = "来源: " + src
			src_lbl.add_theme_font_size_override("font_size", 10)
			src_lbl.add_theme_color_override("font_color", Color(0.55, 0.50, 0.65))
			btn.add_child(src_lbl)

	btn.pressed.connect(_on_creature_selected.bind(cid, owned, data))
	row.add_child(btn)
	return row

func _get_creature_source(cid: String) -> String:
	# 倒查 reward_table 哪个节点奖励该生物
	for node_id: String in RewardTable.FIRST_CLEAR_REWARDS:
		var reward: Dictionary = RewardTable.FIRST_CLEAR_REWARDS[node_id]
		if reward.get("creature", "") == cid:
			var nd: Dictionary = WorldMap.get_map_node(node_id)
			return nd.get("name", node_id)
	return "商店购买"

func _update_progress_label() -> void:
	var lbl: Label = get_node_or_null("ProgressLabel")
	if lbl == null:
		return
	var owned_kinds: int = 0
	var total: int = GameData.creature_database.size()
	for cid: String in GameData.creature_database:
		if GameData.has_creature(cid):
			owned_kinds += 1
	lbl.text = "收集进度: %d / %d (种类)   总拥有: %d 只" % [owned_kinds, total, GameData.player_creatures.size()]

func _on_creature_selected(cid: String, owned: bool, data: Dictionary) -> void:
	if not owned:
		detail_name_lbl.text = "??? (未获取)"
		detail_fac_lbl.text = "解锁方法: " + _get_creature_source(cid)
		detail_stats_lbl.text = ""
		detail_skill_lbl.text = "通关对应关卡或从商店购买后可查看详情"
		detail_desc_lbl.text = ""
		return
	detail_name_lbl.text = data.get("name", cid) + ("  ×%d" % GameData.get_creature_count(cid) if GameData.get_creature_count(cid) > 1 else "")
	detail_fac_lbl.text = "%s · %s · %s" % [
		GameData.get_faction_name(data.get("faction", 0)),
		GameData.get_role_name(data.get("role", 0)),
		GameData.get_position_name(data.get("position_type", 0)),
	]
	detail_stats_lbl.text = "HP: %d\n攻击: %d\n攻速: %.1f/秒\n范围: %d\n稀有度: %d ★\n派系: %s\n来源: %s" % [
		int(data.get("max_hp", 0)),
		int(data.get("attack", 0)),
		float(data.get("attack_speed", 0)),
		int(data.get("range", 0)),
		int(data.get("rarity", 0)) + 1,
		GameData.get_faction_name(data.get("faction", 0)),
		_get_creature_source(cid),
	]
	detail_skill_lbl.text = "【%s】 %s" % [data.get("skill_name", ""), data.get("skill_desc", "")]
	detail_desc_lbl.text = ""

func _on_creature_acquired(_cid: String) -> void:
	_refresh_creature_list()

func _on_faction_filter(faction: int) -> void:
	current_faction_filter = faction
	_refresh_creature_list()

func _on_tab_pressed(tab: String) -> void:
	current_tab = tab
	_refresh_creature_list()
	# 重置详情面板
	detail_name_lbl.text = "选择一个生物查看详情"
	detail_fac_lbl.text = ""
	detail_stats_lbl.text = ""
	detail_skill_lbl.text = ""
	detail_desc_lbl.text = ""
	# 显示/隐藏筛选按钮(反应页不需要)
	for child in get_children():
		if child is Button and child.text in ["技术", "信仰", "自然", "商业", "记忆", "全部"] and tab == "reactions":
			child.visible = false
		elif child is Button and child.text in ["技术", "信仰", "自然", "商业", "记忆", "全部"]:
			child.visible = true

func _refresh_reaction_list() -> void:
	var list: VBoxContainer = get_node_or_null("CreatureList")
	if list == null:
		return
	for child in list.get_children():
		child.queue_free()
	creature_buttons.clear()
	# 展示所有跨派系反应
	var seen_names: Array[String] = []
	for key: String in FactionSynergy.CROSS_REACTIONS:
		var r: Dictionary = FactionSynergy.CROSS_REACTIONS[key]
		var name: String = r.get("name", key)
		if name in seen_names:
			continue
		seen_names.append(name)
		var row := _create_reaction_row(name, r, key)
		list.add_child(row)
	# 进度
	var lbl: Label = get_node_or_null("ProgressLabel")
	if lbl:
		lbl.text = "已知反应: %d / 10" % seen_names.size()

func _create_reaction_row(name: String, r: Dictionary, key: String) -> PanelContainer:
	var row := PanelContainer.new()
	row.custom_minimum_size = Vector2(510, 70)
	var bg := ColorRect.new()
	bg.size = Vector2(510, 70)
	bg.color = Color(0.20, 0.16, 0.30, 0.6)
	row.add_child(bg)

	var btn := Button.new()
	btn.custom_minimum_size = Vector2(510, 70)
	btn.flat = true
	btn.position = Vector2(0, 0)

	var name_lbl := Label.new()
	name_lbl.position = Vector2(20, 10)
	name_lbl.size = Vector2(470, 28)
	name_lbl.text = "✦ " + name
	name_lbl.add_theme_font_size_override("font_size", 17)
	name_lbl.add_theme_color_override("font_color", Color(1.0, 0.88, 0.65))
	btn.add_child(name_lbl)

	var desc_lbl := Label.new()
	desc_lbl.position = Vector2(20, 42)
	desc_lbl.size = Vector2(470, 22)
	desc_lbl.text = r.get("desc", "")
	desc_lbl.add_theme_font_size_override("font_size", 12)
	desc_lbl.add_theme_color_override("font_color", Color(0.75, 0.70, 0.85))
	btn.add_child(desc_lbl)

	row.add_child(btn)
	return row
