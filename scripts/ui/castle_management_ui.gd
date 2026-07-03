extends Control
## 城堡管理 UI — 队伍管理 + 战外治疗 + 复活仪式
## 阶段1补完: 战外治疗UI + 复活UI 都在这里

var creature_rows: Array[Dictionary] = []  # 缓存当前展示的生物行节点
var creature_list: VBoxContainer = null
var gold_label: Label = null
var item_label: Label = null
var core_label: Label = null
var message_label: Label = null

func _ready() -> void:
	_setup_ui()
	_connect_signals()
	_refresh()

func _setup_ui() -> void:
	# 背景
	var bg := ColorRect.new()
	bg.size = Vector2(1280, 720)
	bg.color = Color(0.16, 0.13, 0.24)
	add_child(bg)

	# 标题
	var title := Label.new()
	title.text = "城堡 · 队伍管理"
	title.position = Vector2(0, 12)
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
	back.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/world_map.tscn"))
	add_child(back)

	# ── 顶部状态栏 ──
	var status := HBoxContainer.new()
	status.position = Vector2(110, 60)
	status.add_theme_constant_override("separation", 30)
	add_child(status)

	# 金币
	var gold_lbl := Label.new()
	gold_lbl.text = "金币: " + str(GameData.resources.get("gold", 0))
	gold_lbl.add_theme_font_size_override("font_size", 16)
	gold_lbl.add_theme_color_override("font_color", Color(1.0, 0.88, 0.55))
	status.add_child(gold_lbl)
	gold_label = gold_lbl

	# 治疗包数量
	var item_lbl := Label.new()
	item_lbl.text = "基础包: %d  高级包: %d  灵魂碎片: %d" % [
		GameData.healing_items.get("basic_heal_pack", 0),
		GameData.healing_items.get("advanced_heal_pack", 0),
		GameData.healing_items.get("soul_fragment", 0),
	]
	item_lbl.add_theme_font_size_override("font_size", 14)
	item_lbl.add_theme_color_override("font_color", Color(0.75, 0.85, 0.95))
	status.add_child(item_lbl)
	item_label = item_lbl

	# 城堡核心
	var core_lbl := Label.new()
	core_lbl.text = "城堡核心: %d/%d" % [
		GameData.castle_modules.get("core_hp", 0),
		GameData.castle_modules.get("core_hp_max", 200),
	]
	core_lbl.add_theme_font_size_override("font_size", 14)
	core_lbl.add_theme_color_override("font_color", Color(0.95, 0.65, 0.75))
	status.add_child(core_lbl)
	core_label = core_lbl

	# ── 说明 ──
	var hint := Label.new()
	hint.text = "轻伤(≥50%) 自动恢复 / 重伤(25-50%) 50金治愈 / 濒死(<25%) 100金+1高级包 / 死亡 500金+3灵魂碎片"
	hint.position = Vector2(0, 95)
	hint.size = Vector2(1280, 22)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 12)
	hint.add_theme_color_override("font_color", Color(0.70, 0.65, 0.85))
	add_child(hint)

	# ── 滚动生物列表 ──
	var scroll := ScrollContainer.new()
	scroll.position = Vector2(40, 130)
	scroll.size = Vector2(1200, 540)
	add_child(scroll)

	var list := VBoxContainer.new()
	list.name = "CreatureList"
	list.add_theme_constant_override("separation", 6)
	scroll.add_child(list)
	creature_list = list

	# ── 消息 ──
	var msg := Label.new()
	msg.position = Vector2(40, 680)
	msg.size = Vector2(1200, 24)
	msg.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	msg.add_theme_font_size_override("font_size", 14)
	msg.add_theme_color_override("font_color", Color(0.95, 0.85, 0.55))
	add_child(msg)
	message_label = msg

func _connect_signals() -> void:
	EventBus.resource_changed.connect(_on_resource_changed)
	EventBus.creature_healed.connect(_on_creature_changed)
	EventBus.creature_resurrected.connect(_on_creature_changed)
	EventBus.creature_died_in_battle.connect(_on_creature_changed)
	EventBus.creature_injured.connect(_on_creature_changed)

func _refresh() -> void:
	if creature_list == null:
		return
	for child in creature_list.get_children():
		child.queue_free()
	creature_rows.clear()
	for cid: String in GameData.player_creatures:
		var row: HBoxContainer = _build_creature_row(cid)
		creature_list.add_child(row)
		creature_rows.append({"cid": cid, "row": row})
	_update_status_labels()

func _build_creature_row(cid: String) -> HBoxContainer:
	var data: Dictionary = GameData.get_creature_data(cid)
	var hp: float = GameData.get_creature_hp(cid)
	var max_hp: float = GameData.get_creature_max_hp(cid)
	var stage: int = GameData.get_creature_injury_stage(cid)
	var is_dead: bool = GameData.is_creature_dead(cid)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)

	# 派系色块
	var swatch := ColorRect.new()
	swatch.custom_minimum_size = Vector2(14, 48)
	swatch.color = GameData.get_faction_color(data.get("faction", 0))
	row.add_child(swatch)

	# 名字 + 派系
	var name_lbl := Label.new()
	name_lbl.text = data.get("name", cid)
	name_lbl.custom_minimum_size = Vector2(140, 0)
	name_lbl.add_theme_font_size_override("font_size", 15)
	name_lbl.add_theme_color_override("font_color", Color(0.95, 0.92, 0.98))
	row.add_child(name_lbl)

	var fac_lbl := Label.new()
	fac_lbl.text = GameData.get_faction_name(data.get("faction", 0))
	fac_lbl.custom_minimum_size = Vector2(110, 0)
	fac_lbl.add_theme_font_size_override("font_size", 12)
	fac_lbl.add_theme_color_override("font_color", Color(0.75, 0.70, 0.85))
	row.add_child(fac_lbl)

	# 定位
	var pos_lbl := Label.new()
	pos_lbl.text = GameData.get_position_name(data.get("position_type", 0))
	pos_lbl.custom_minimum_size = Vector2(60, 0)
	pos_lbl.add_theme_font_size_override("font_size", 12)
	pos_lbl.add_theme_color_override("font_color", Color(0.75, 0.70, 0.85))
	row.add_child(pos_lbl)

	# HP 文字
	var hp_lbl := Label.new()
	hp_lbl.custom_minimum_size = Vector2(140, 0)
	hp_lbl.add_theme_font_size_override("font_size", 14)
	hp_lbl.add_theme_color_override("font_color", Color.WHITE)
	if is_dead:
		hp_lbl.text = "HP: 已阵亡"
		hp_lbl.add_theme_color_override("font_color", Color(0.65, 0.55, 0.60))
	else:
		hp_lbl.text = "HP: %d / %d" % [int(hp), int(max_hp)]
	row.add_child(hp_lbl)

	# HP 进度条
	var bar := ProgressBar.new()
	bar.custom_minimum_size = Vector2(200, 16)
	bar.max_value = max_hp if max_hp > 0.0 else 1.0
	bar.value = hp
	bar.show_percentage = false
	if is_dead:
		bar.modulate = Color(0.4, 0.4, 0.4)
	elif stage == GameData.InjuryStage.DYING:
		bar.modulate = Color(0.95, 0.45, 0.45)
	elif stage == GameData.InjuryStage.SEVERE:
		bar.modulate = Color(0.95, 0.70, 0.50)
	elif stage == GameData.InjuryStage.LIGHT:
		bar.modulate = Color(0.95, 0.88, 0.65)
	else:
		bar.modulate = Color(0.65, 0.95, 0.78)
	row.add_child(bar)

	# 状态标签
	var stage_lbl := Label.new()
	stage_lbl.custom_minimum_size = Vector2(80, 0)
	stage_lbl.add_theme_font_size_override("font_size", 13)
	var stage_name: String = ["健康", "轻伤", "重伤", "濒死", "已亡"][stage] if stage >= 0 and stage < 5 else "?"
	stage_lbl.text = "[" + stage_name + "]"
	match stage:
		GameData.InjuryStage.HEALTHY: stage_lbl.add_theme_color_override("font_color", Color(0.65, 0.95, 0.78))
		GameData.InjuryStage.LIGHT: stage_lbl.add_theme_color_override("font_color", Color(0.95, 0.88, 0.65))
		GameData.InjuryStage.SEVERE: stage_lbl.add_theme_color_override("font_color", Color(0.95, 0.70, 0.50))
		GameData.InjuryStage.DYING: stage_lbl.add_theme_color_override("font_color", Color(0.95, 0.45, 0.45))
		GameData.InjuryStage.DEAD: stage_lbl.add_theme_color_override("font_color", Color(0.55, 0.50, 0.55))
	row.add_child(stage_lbl)

	# 操作按钮
	var action_box := HBoxContainer.new()
	action_box.add_theme_constant_override("separation", 6)
	row.add_child(action_box)

	if is_dead:
		# 24h 免费复活选项 + 立即付费复活
		if GameData.can_free_resurrect(cid):
			var free_btn := Button.new()
			free_btn.text = "24h 免费复活(立即)"
			free_btn.custom_minimum_size = Vector2(170, 32)
			free_btn.add_theme_font_size_override("font_size", 12)
			free_btn.modulate = Color(0.55, 0.95, 0.75)
			free_btn.pressed.connect(_on_free_resurrect_pressed.bind(cid))
			action_box.add_child(free_btn)
		else:
			# 显示倒计时
			var remaining: int = GameData.free_resurrect_remaining(cid)
			if remaining > 0:
				var hours: int = remaining / 3600
				var minutes: int = (remaining % 3600) / 60
				var countdown_lbl := Label.new()
				countdown_lbl.text = "免费复活倒计时: %dh%dm" % [hours, minutes]
				countdown_lbl.custom_minimum_size = Vector2(170, 32)
				countdown_lbl.add_theme_font_size_override("font_size", 11)
				countdown_lbl.add_theme_color_override("font_color", Color(0.75, 0.85, 0.95))
				countdown_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
				action_box.add_child(countdown_lbl)
		# 立即付费复活
		var resurrect_btn := Button.new()
		resurrect_btn.text = "立即复活 (500G+3灵魂)"
		resurrect_btn.custom_minimum_size = Vector2(180, 32)
		resurrect_btn.add_theme_font_size_override("font_size", 12)
		resurrect_btn.pressed.connect(_on_resurrect_pressed.bind(cid))
		action_box.add_child(resurrect_btn)
	else:
		# 治疗按钮 (轻伤/重伤/濒死)
		var heal_btn := Button.new()
		heal_btn.custom_minimum_size = Vector2(140, 32)
		heal_btn.add_theme_font_size_override("font_size", 12)
		match stage:
			GameData.InjuryStage.LIGHT:
				heal_btn.text = "免费恢复"
				heal_btn.disabled = true  # 战外自动恢复
			GameData.InjuryStage.SEVERE:
				heal_btn.text = "基础治疗 (50G)"
				heal_btn.pressed.connect(_on_basic_heal_pressed.bind(cid))
			GameData.InjuryStage.DYING:
				heal_btn.text = "高级治疗 (100G+1包)"
				heal_btn.pressed.connect(_on_advanced_heal_pressed.bind(cid))
			_:
				heal_btn.text = "无需治疗"
				heal_btn.disabled = true
		action_box.add_child(heal_btn)

	# 详情(技能描述)
	var skill_lbl := Label.new()
	skill_lbl.custom_minimum_size = Vector2(280, 0)
	skill_lbl.text = "技能: " + data.get("skill_name", "") + " - " + data.get("skill_desc", "")
	skill_lbl.add_theme_font_size_override("font_size", 11)
	skill_lbl.add_theme_color_override("font_color", Color(0.65, 0.62, 0.78))
	skill_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	row.add_child(skill_lbl)

	return row

func _update_status_labels() -> void:
	if gold_label:
		gold_label.text = "金币: " + str(GameData.resources.get("gold", 0))
	if item_label:
		item_label.text = "基础包: %d  高级包: %d  灵魂碎片: %d" % [
			GameData.healing_items.get("basic_heal_pack", 0),
			GameData.healing_items.get("advanced_heal_pack", 0),
			GameData.healing_items.get("soul_fragment", 0),
		]
	if core_label:
		core_label.text = "城堡核心: %d/%d" % [
			GameData.castle_modules.get("core_hp", 0),
			GameData.castle_modules.get("core_hp_max", 200),
		]

func _show_message(text: String) -> void:
	if message_label == null:
		return
	message_label.text = text
	var tw: Tween = create_tween()
	tw.tween_interval(2.5)
	tw.tween_property(message_label, "modulate:a", 0.0, 0.5)
	tw.tween_callback(func():
		message_label.modulate.a = 1.0
		message_label.text = "")

func _on_basic_heal_pressed(cid: String) -> void:
	# 战外治疗: 重伤 50 金币
	if GameData.spend_resource("gold", 50):
		var data: Dictionary = GameData.get_creature_data(cid)
		var max_hp: float = data.get("max_hp", 100.0)
		GameData.creature_heal(cid, max_hp)
		EventBus.creature_healed.emit(cid)
		_show_message("%s 已治疗至满血" % data.get("name", cid))
		SaveManager.save_game()
		_refresh()
	else:
		_show_message("金币不足！")

func _on_advanced_heal_pressed(cid: String) -> void:
	# 战外治疗: 濒死 100 金币 + 1 高级治疗包
	if GameData.healing_items.get("advanced_heal_pack", 0) < 1:
		_show_message("需要 1 个高级治疗包！")
		return
	if GameData.resources.get("gold", 0) < 100:
		_show_message("金币不足！")
		return
	GameData.spend_resource("gold", 100)
	GameData.healing_items["advanced_heal_pack"] -= 1
	var data: Dictionary = GameData.get_creature_data(cid)
	var max_hp: float = data.get("max_hp", 100.0)
	GameData.creature_heal(cid, max_hp)
	EventBus.creature_healed.emit(cid)
	_show_message("%s 紧急救治成功" % data.get("name", cid))
	SaveManager.save_game()
	_refresh()

func _on_resurrect_pressed(cid: String) -> void:
	# 询问 24h 免费复活 还是 立即付费
	if not GameData.world_progress["free_resurrect_available"].has(cid):
		# 第一次: 同时提供两个选项
		GameData.enable_free_resurrect(cid)
		if GameData.resurrect_creature(cid):
			var data: Dictionary = GameData.get_creature_data(cid)
			_show_message("%s 已立即复活！" % data.get("name", cid))
			SaveManager.save_game()
			_refresh()
		else:
			_show_message("复活失败：需要 500 金币 + 3 灵魂碎片")
	else:
		# 已登记,只能付费
		if GameData.resurrect_creature(cid):
			var data: Dictionary = GameData.get_creature_data(cid)
			_show_message("%s 已复活！" % data.get("name", cid))
			SaveManager.save_game()
			_refresh()
		else:
			_show_message("复活失败：需要 500 金币 + 3 灵魂碎片")

func _on_free_resurrect_pressed(cid: String) -> void:
	if GameData.perform_free_resurrect(cid):
		var data: Dictionary = GameData.get_creature_data(cid)
		_show_message("%s 24h 免费复活成功！" % data.get("name", cid))
		SaveManager.save_game()
		_refresh()
	else:
		_show_message("免费复活尚未到时间")

func _on_resource_changed(_t: String, _a: int) -> void:
	_update_status_labels()

func _on_creature_changed(_cid: String = "") -> void:
	_refresh()
