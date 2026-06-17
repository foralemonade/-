extends Node2D
## 战斗场景主控制器

var castle: Castle = null
var wave_manager: WaveManager = null
var skill_system: SkillSystem = null
var battle_ui: CanvasLayer = null

func _ready():
	castle = $Castle
	wave_manager = $WaveManager

	# 技能系统
	skill_system = SkillSystem.new()
	skill_system.name = "SkillSystem"
	add_child(skill_system)

	# 战斗 UI
	var ui_script = load("res://scripts/ui/battle_ui.gd")
	battle_ui = ui_script.new()
	battle_ui.name = "BattleUI"
	add_child(battle_ui)

	# 设置引用
	wave_manager.enemy_spawner = $EnemySpawner
	wave_manager.enemy_path = $EnemyPath
	castle.set_enemy_container(wave_manager.enemy_container)

	if battle_ui.has_method("setup_references"):
		battle_ui.setup_references(castle, wave_manager, skill_system)

	castle.current_shield = castle.max_shield
	castle.castle_destroyed.connect(_on_castle_destroyed)
	EventBus.enemy_reached_end.connect(_on_enemy_reached_end)

func _draw():
	draw_rect(Rect2(0, 0, 1280, 720), Color(0.08, 0.06, 0.15))
	draw_line(Vector2(0, 500), Vector2(1280, 500), Color(0.2, 0.15, 0.3), 3.0)

func _on_enemy_reached_end(enemy: Node2D):
	if enemy is Enemy:
		castle.take_damage(enemy.damage_to_castle)

func _on_castle_destroyed():
	wave_manager.stop_battle()
	EventBus.battle_lost.emit()
