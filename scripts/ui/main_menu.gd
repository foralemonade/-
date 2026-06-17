extends Control
## 梦游症 - 主菜单

func _ready():
	_setup_ui()

func _setup_ui():
	var bg = ColorRect.new()
	bg.size = Vector2(1280, 720)
	bg.color = Color(0.05, 0.04, 0.12)
	add_child(bg)

	for i in range(40):
		var dot = ColorRect.new()
		dot.position = Vector2(randi() % 1280, randi() % 720)
		dot.size = Vector2(2, 2)
		dot.color = Color(0.5, 0.5, 0.8, randf() * 0.4 + 0.2)
		add_child(dot)

	var title = Label.new()
	title.text = "梦 游 症"
	title.position = Vector2(0, 120)
	title.size = Vector2(1280, 80)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 64)
	title.add_theme_color_override("font_color", Color(0.7, 0.6, 1.0))
	add_child(title)

	var sub = Label.new()
	sub.text = "Somnambulism"
	sub.position = Vector2(0, 200)
	sub.size = Vector2(1280, 40)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.add_theme_font_size_override("font_size", 20)
	sub.add_theme_color_override("font_color", Color(0.5, 0.5, 0.7))
	add_child(sub)

	_create_button("世界地图", 280, "res://scenes/world_map.tscn")
	_create_button("原型战斗", 360, "res://scenes/battle_scene.tscn")
	_create_button("无限挑战", 440, "res://scenes/challenge_scene.tscn")

	var ver = Label.new()
	ver.text = "v0.2 | Godot | 五大派系 x 六大陆 x 20只生物"
	ver.position = Vector2(0, 680)
	ver.size = Vector2(1280, 20)
	ver.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ver.add_theme_font_size_override("font_size", 12)
	ver.add_theme_color_override("font_color", Color(0.4, 0.4, 0.5))
	add_child(ver)

func _create_button(txt: String, y_pos: float, scene_path: String):
	var btn = Button.new()
	btn.text = txt
	btn.position = Vector2(490, y_pos)
	btn.size = Vector2(300, 60)
	btn.add_theme_font_size_override("font_size", 22)
	btn.pressed.connect(func():
		get_tree().change_scene_to_file(scene_path)
	)
	add_child(btn)
