extends Control
## 无限挑战入口

func _ready():
	_setup_ui()

func _setup_ui():
	var bg = ColorRect.new()
	bg.size = Vector2(1280, 720)
	bg.color = Color(0.04, 0.03, 0.10)
	add_child(bg)

	var title = Label.new()
	title.text = "无限挑战"
	title.position = Vector2(0, 100)
	title.size = Vector2(1280, 60)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 48)
	title.add_theme_color_override("font_color", Color(1.0, 0.6, 0.2))
	add_child(title)

	var sub = Label.new()
	sub.text = "Roguelike 模式 | 每日/每周刷新"
	sub.position = Vector2(0, 160)
	sub.size = Vector2(1280, 30)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.add_theme_font_size_override("font_size", 16)
	sub.add_theme_color_override("font_color", Color(0.7, 0.7, 0.8))
	add_child(sub)

	var start_btn = Button.new()
	start_btn.text = "开始挑战"
	start_btn.position = Vector2(490, 250)
	start_btn.size = Vector2(300, 60)
	start_btn.add_theme_font_size_override("font_size", 22)
	start_btn.pressed.connect(func():
		get_tree().change_scene_to_file("res://scenes/battle_scene.tscn")
	)
	add_child(start_btn)

	var back = Button.new()
	back.text = "< 返回"
	back.position = Vector2(20, 20)
	back.size = Vector2(80, 35)
	back.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/main_menu.tscn"))
	add_child(back)
