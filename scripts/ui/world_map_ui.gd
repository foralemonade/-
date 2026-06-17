extends Control
## 大地图 UI - 六大陆节点选择

var world_map = null
var node_buttons = {}

func _ready():
	world_map = WorldMapManager.new()
	world_map.name = "WorldMapManager"
	add_child(world_map)
	_setup_ui()
	_connect_signals()

func _setup_ui():
	# 背景
	var bg = ColorRect.new()
	bg.size = Vector2(1280, 720)
	bg.color = Color(0.05, 0.04, 0.12)
	add_child(bg)

	# 标题
	var title = Label.new()
	title.text = "梦游症 · 六大陆"
	title.position = Vector2(0, 10)
	title.size = Vector2(1280, 40)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", Color(0.7, 0.6, 1.0))
	add_child(title)

	# 返回按钮
	var back = Button.new()
	back.position = Vector2(20, 10)
	back.size = Vector2(80, 35)
	back.text = "< 返回"
	back.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/main_menu.tscn"))
	add_child(back)

	# 大陆区域
	var continents = [
		{"name": "技术大陆", "x": 160, "y": 200, "w": 200, "h": 300, "col": Color(0.15, 0.2, 0.3)},
		{"name": "信仰大陆", "x": 420, "y": 100, "w": 200, "h": 340, "col": Color(0.25, 0.2, 0.1)},
		{"name": "自然大陆", "x": 720, "y": 200, "w": 200, "h": 310, "col": Color(0.1, 0.2, 0.1)},
		{"name": "商业大陆", "x": 940, "y": 280, "w": 200, "h": 260, "col": Color(0.25, 0.15, 0.08)},
		{"name": "记忆大陆", "x": 520, "y": 460, "w": 200, "h": 200, "col": Color(0.15, 0.1, 0.2)},
		{"name": "混战大陆", "x": 520, "y": 30, "w": 200, "h": 100, "col": Color(0.15, 0.08, 0.15)},
	]
	for cont in continents:
		var r = ColorRect.new()
		r.position = Vector2(cont["x"], cont["y"])
		r.size = Vector2(cont["w"], cont["h"])
		r.color = cont["col"]
		add_child(r)
		var lbl = Label.new()
		lbl.position = Vector2(cont["x"] + 5, cont["y"] + 5)
		lbl.text = cont["name"]
		lbl.add_theme_font_size_override("font_size", 12)
		lbl.add_theme_color_override("font_color", Color(0.6, 0.6, 0.7))
		add_child(lbl)

	_create_node_buttons()

func _create_node_buttons():
	var nodes = world_map.get_all_nodes()
	for nid in nodes:
		var nd = nodes[nid]
		var btn = Button.new()
		var sx = nd["x"] - 18
		var sy = nd["y"] - 18

		if nd.get("is_boss", false):
			btn.position = Vector2(sx - 6, sy - 6)
			btn.size = Vector2(48, 48)
			btn.text = "BOSS"
		else:
			btn.position = Vector2(sx, sy)
			btn.size = Vector2(36, 36)
			btn.text = nd["name"]

		btn.add_theme_font_size_override("font_size", 8)

		if world_map.is_node_completed(nid):
			btn.modulate = Color(0.3, 0.7, 0.3)
		elif world_map.is_node_unlocked(nid) or nid == "start":
			btn.modulate = Color(0.9, 0.9, 0.9)
		else:
			btn.modulate = Color(0.25, 0.25, 0.25)

		btn.pressed.connect(_on_node_pressed.bind(nid))
		add_child(btn)
		node_buttons[nid] = btn

func _on_node_pressed(node_id: String):
	if not world_map.is_node_unlocked(node_id) and node_id != "start":
		return
	GameData.world_progress["current_node"] = node_id
	var nd = world_map.get_map_node(node_id)
	EventBus.node_entered.emit(node_id)
	get_tree().change_scene_to_file("res://scenes/battle_scene.tscn")

func _connect_signals():
	EventBus.node_completed.connect(_on_node_completed)
	EventBus.node_unlocked.connect(_on_node_unlocked)
	EventBus.battle_won.connect(_on_battle_won_map)

func _on_battle_won_map():
	var node_id = GameData.world_progress["current_node"]
	if node_id != "" and not world_map.is_node_completed(node_id):
		world_map.complete_and_unlock(node_id)

func _on_node_completed(node_id: String):
	if node_buttons.has(node_id):
		node_buttons[node_id].modulate = Color(0.3, 0.7, 0.3)

func _on_node_unlocked(node_id: String):
	if node_buttons.has(node_id):
		node_buttons[node_id].modulate = Color(0.9, 0.9, 0.9)
