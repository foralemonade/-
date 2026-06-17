extends Node
class_name WaveManager
## 波次管理器

signal wave_started(wave_index: int, total_waves: int)
signal wave_completed(wave_index: int)
signal all_waves_completed()

var wave_configs = []
var current_wave: int = -1
var total_waves: int = 0
var enemies_remaining: int = 0
var spawn_queue = []
var spawn_timer: float = 0.0
var is_battle_active: bool = false

var enemy_spawner: Node2D = null
var enemy_path: Path2D = null
var enemy_container: Node = null

func _ready():
	enemy_container = Node.new()
	enemy_container.name = "Enemies"
	add_child(enemy_container)

func setup_waves(configs):
	wave_configs = configs
	current_wave = -1
	total_waves = configs.size()
	spawn_queue.clear()

func start_battle():
	if wave_configs.is_empty():
		return
	is_battle_active = true
	EventBus.battle_started.emit()
	_start_next_wave()

func _start_next_wave():
	current_wave += 1
	if current_wave >= wave_configs.size():
		_all_waves_done()
		return
	var config = wave_configs[current_wave]
	enemies_remaining = config.get("enemy_count", 3)
	wave_started.emit(current_wave + 1, total_waves)
	EventBus.wave_started.emit(current_wave + 1)
	spawn_queue.clear()
	var interval = config.get("spawn_interval", 1.5)
	for i in range(enemies_remaining):
		spawn_queue.append({"enemy_type": config.get("enemy_type", "basic"), "delay": float(i) * interval})
	spawn_timer = 0.0

func _process(delta):
	if not is_battle_active:
		return
	if spawn_queue.is_empty():
		return
	spawn_timer += delta
	var to_spawn = []
	for item in spawn_queue:
		if spawn_timer >= item["delay"]:
			to_spawn.append(item)
	for item in to_spawn:
		spawn_queue.erase(item)
		_spawn_enemy(item["enemy_type"])

func _spawn_enemy(enemy_type: String):
	if enemy_spawner == null:
		return
	var enemy_scene = load("res://scenes/enemy.tscn")
	if enemy_scene == null:
		return
	var e = enemy_scene.instantiate()
	e.enemy_type = enemy_type
	if enemy_path:
		e.path_follow = enemy_path
	e.position = enemy_spawner.position
	enemy_container.add_child(e)
	if e.has_method("_init_enemy"):
		e._init_enemy()
	e.died.connect(_on_enemy_died)
	e.reached_end.connect(_on_enemy_reached_end)
	EventBus.enemy_spawned.emit(e)

func _on_enemy_died(_enemy: Node2D):
	enemies_remaining -= 1
	if enemies_remaining <= 0 and spawn_queue.is_empty():
		_wave_cleared()

func _on_enemy_reached_end(_enemy: Node2D):
	enemies_remaining -= 1
	if enemies_remaining <= 0 and spawn_queue.is_empty():
		_wave_cleared()

func _wave_cleared():
	wave_completed.emit(current_wave + 1)
	EventBus.wave_cleared.emit(current_wave + 1)
	var timer = get_tree().create_timer(2.0)
	timer.timeout.connect(_on_wave_delay_finished)

func _on_wave_delay_finished():
	if is_battle_active:
		_start_next_wave()

func _all_waves_done():
	is_battle_active = false
	spawn_queue.clear()
	all_waves_completed.emit()
	EventBus.battle_won.emit()

func stop_battle():
	is_battle_active = false
	spawn_queue.clear()

func clear_all_enemies():
	for child in enemy_container.get_children():
		child.queue_free()
