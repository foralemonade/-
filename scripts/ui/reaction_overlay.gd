extends CanvasLayer
## 反应视觉爆点 — 在 battle_scene 顶层
## 当 EventBus.reaction_triggered 触发时,显示大字 + 闪屏 + 屏幕震动

var flash_rect: ColorRect = null
var big_label: Label = null
var sub_label: Label = null
var particle_layer: Node2D = null

func _ready() -> void:
	layer = 100  # 最顶层
	# 屏幕闪白层
	flash_rect = ColorRect.new()
	flash_rect.color = Color(1, 1, 1, 0)
	flash_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	flash_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(flash_rect)

	# 大字标签
	big_label = Label.new()
	big_label.text = ""
	big_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	big_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	big_label.set_anchors_preset(Control.PRESET_CENTER)
	big_label.position = Vector2(-300, -100)
	big_label.size = Vector2(600, 80)
	big_label.add_theme_font_size_override("font_size", 56)
	big_label.modulate = Color(1, 1, 1, 0)
	big_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(big_label)

	# 副标题(描述)
	sub_label = Label.new()
	sub_label.text = ""
	sub_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	sub_label.set_anchors_preset(Control.PRESET_CENTER)
	sub_label.position = Vector2(-350, 0)
	sub_label.size = Vector2(700, 40)
	sub_label.add_theme_font_size_override("font_size", 18)
	sub_label.modulate = Color(1, 1, 1, 0)
	sub_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(sub_label)

	# 粒子层(简单的彩色环)
	particle_layer = Node2D.new()
	add_child(particle_layer)

	# 监听反应触发
	EventBus.reaction_triggered.connect(_on_reaction_triggered)
	EventBus.reaction_pop.connect(_on_reaction_pop)

func _on_reaction_triggered(reactions: Array) -> void:
	if reactions.is_empty():
		return
	# 屏幕闪白一次 + 显示第一条反应
	var r: Dictionary = reactions[0]
	var name: String = r.get("name", "化学反应")
	var desc: String = r.get("desc", "")
	var color: Color = r.get("color", Color(1, 1, 1, 0.6))
	_show_pop(name, desc, color)

func _on_reaction_pop(name: String, desc: String, color: Color) -> void:
	_show_pop(name, desc, color)

func _show_pop(name: String, desc: String, color: Color) -> void:
	# 闪屏
	flash_rect.color = Color(color.r, color.g, color.b, 0.55)
	var tw_flash: Tween = create_tween()
	tw_flash.tween_property(flash_rect, "color:a", 0.0, 0.5)

	# 大字淡入 + 缩放
	big_label.text = "✦  " + name + "  ✦"
	big_label.add_theme_color_override("font_color", color)
	big_label.modulate = Color(1, 1, 1, 1)
	big_label.scale = Vector2(0.6, 0.6)
	big_label.pivot_offset = Vector2(300, 40)
	var tw_label: Tween = create_tween()
	tw_label.tween_property(big_label, "scale", Vector2(1.0, 1.0), 0.3).set_trans(Tween.TRANS_BACK)
	tw_label.tween_interval(1.4)
	tw_label.tween_property(big_label, "modulate:a", 0.0, 0.6)

	# 副标题
	sub_label.text = desc
	sub_label.add_theme_color_override("font_color", Color(1, 1, 1, 0.85))
	sub_label.modulate = Color(1, 1, 1, 1)
	var tw_sub: Tween = create_tween()
	tw_sub.tween_interval(0.4)
	tw_sub.tween_property(sub_label, "modulate:a", 0.0, 1.5)

	# 屏幕震动(轻)
	_shake_screen()
	# 粒子
	_spawn_particles(color)

func _shake_screen() -> void:
	var parent: Node = get_parent()
	if parent == null:
		return
	var original: Vector2 = parent.position
	var tw: Tween = create_tween()
	for i in range(6):
		var offset: Vector2 = Vector2(randf_range(-6.0, 6.0), randf_range(-4.0, 4.0))
		tw.tween_property(parent, "position", original + offset, 0.04)
	tw.tween_property(parent, "position", original, 0.05)

func _spawn_particles(color: Color) -> void:
	# 6 个彩色环从中心向四周飞
	for i in range(6):
		var angle: float = (float(i) / 6.0) * TAU
		var dir: Vector2 = Vector2(cos(angle), sin(angle)) * 200.0
		var ring := ColorRect.new()
		ring.size = Vector2(14, 14)
		ring.position = Vector2(640 - 7, 360 - 7)
		ring.color = color
		ring.modulate = Color(color.r, color.g, color.b, 0.9)
		particle_layer.add_child(ring)
		var tw: Tween = create_tween()
		tw.tween_property(ring, "position", ring.position + dir, 0.8).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw.parallel().tween_property(ring, "modulate:a", 0.0, 0.8)
		tw.tween_callback(ring.queue_free)
