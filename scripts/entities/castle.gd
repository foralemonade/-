extends Node2D
class_name Castle
## 移动城堡 - 核心战斗单位

signal shield_changed(current: int, max_hp: int)
signal castle_destroyed()

@export var max_shield: int = 100
var current_shield: int = 100
var shield_regen: float = 0.0

@export var slot_count: int = 4
var creature_slots = []
var slot_positions = []
var current_creature_ids = []

var synergy_system = null
var enemy_container = null

func _ready():
	current_shield = max_shield
	slot_positions = [
		Vector2(-50, -80), Vector2(50, -80),
		Vector2(-50, -30), Vector2(50, -30),
	]
	for i in range(slot_count):
		var pos = Vector2.ZERO
		if i < slot_positions.size():
			pos = slot_positions[i]
		creature_slots.append({
			"creature": null,
			"creature_id": "",
			"position": pos,
		})
	var synergy_script = load("res://scripts/systems/faction_synergy.gd")
	synergy_system = synergy_script.new()
	synergy_system.name = "FactionSynergyCalculator"
	add_child(synergy_system)
	_draw_castle()

func _process(delta):
	if shield_regen > 0.0 and current_shield < max_shield:
		var new_shield = float(current_shield) + shield_regen * delta
		if new_shield > float(max_shield):
			new_shield = float(max_shield)
		current_shield = int(new_shield)
		shield_changed.emit(current_shield, max_shield)

func _draw_castle():
	var sprite = Sprite2D.new()
	var s = 160
	var img = Image.create(s, s, false, Image.FORMAT_RGBA8)
	img.fill_rect(Rect2i(10, 30, s - 20, s - 40), Color(0.35, 0.3, 0.5))
	img.fill_rect(Rect2i(20, 10, s - 40, 25), Color(0.45, 0.4, 0.6))
	var win_positions = [30, 70, 110]
	for wx in win_positions:
		img.fill_rect(Rect2i(wx, 50, 20, 20), Color(0.7, 0.7, 1.0, 0.6))
	img.fill_rect(Rect2i(65, 100, 30, 50), Color(0.25, 0.2, 0.4))
	img.fill_rect(Rect2i(10, 130, 30, 20), Color(0.3, 0.3, 0.3))
	img.fill_rect(Rect2i(120, 130, 30, 20), Color(0.3, 0.3, 0.3))
	var tex = ImageTexture.new()
	tex.set_image(img)
	sprite.texture = tex
	sprite.position = Vector2(float(-s) / 2.0, float(-s) / 2.0)
	add_child(sprite)

func place_creature(slot_index: int, creature_id: String) -> bool:
	if slot_index < 0 or slot_index >= creature_slots.size():
		return false
	var slot = creature_slots[slot_index]
	if slot["creature"] != null:
		remove_creature(slot_index)
	var data = GameData.get_creature_data(creature_id)
	if data.is_empty():
		return false
	var creature_scene = load("res://scenes/creature.tscn")
	if creature_scene == null:
		return false
	var c = creature_scene.instantiate()
	c.setup(data)
	c.position = slot["position"]
	c.set_enemy_container(enemy_container)
	add_child(c)
	slot["creature"] = c
	slot["creature_id"] = creature_id
	_refresh_creature_ids()
	_recalculate_synergies()
	EventBus.creature_placed.emit(slot_index, creature_id)
	return true

func remove_creature(slot_index: int) -> bool:
	if slot_index < 0 or slot_index >= creature_slots.size():
		return false
	var slot = creature_slots[slot_index]
	if slot["creature"] != null:
		slot["creature"].queue_free()
		slot["creature"] = null
		slot["creature_id"] = ""
		_refresh_creature_ids()
		_recalculate_synergies()
		EventBus.creature_removed.emit(slot_index)
		return true
	return false

func _refresh_creature_ids():
	current_creature_ids.clear()
	for slot in creature_slots:
		if slot["creature_id"] != "" and slot["creature_id"] != null:
			current_creature_ids.append(slot["creature_id"])

func _recalculate_synergies():
	var result = synergy_system.analyze_synergies(current_creature_ids)
	shield_regen = result.get("castle_regen", 0.0)
	for slot in creature_slots:
		if slot["creature"] != null:
			var c = slot["creature"]
			c.apply_synergy_effects(result)
	EventBus.synergy_updated.emit(result)

func take_damage(amount: int):
	var actual = amount
	if actual < 1:
		actual = 1
	current_shield = current_shield - actual
	if current_shield < 0:
		current_shield = 0
	shield_changed.emit(current_shield, max_shield)
	EventBus.castle_damaged.emit(current_shield, max_shield)
	if current_shield <= 0:
		castle_destroyed.emit()
		EventBus.castle_destroyed.emit()

func get_placed_creatures() -> Array:
	var r = []
	for slot in creature_slots:
		if slot["creature"] != null:
			r.append(slot["creature"])
	return r

func set_enemy_container(container: Node):
	enemy_container = container
