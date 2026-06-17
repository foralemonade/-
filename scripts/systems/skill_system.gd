extends Node
## 主角技能系统 - 支援技能的释放、冷却、效果执行

class_name SkillSystem

var max_energy: float = 100.0
var current_energy: float = 50.0
var energy_regen: float = 2.0

var skill_database: Dictionary = {}
var cooldowns: Dictionary = {}

func _ready():
	_init_skill_database()

func _init_skill_database():
	skill_database = {
		"energy_burst": {
			"id":"energy_burst","name":"能量爆发","desc":"对场上所有敌人造成 50 伤害","cost":30,"cooldown":15.0,
			"type":"damage","value":50,
		},
		"shield_overload": {
			"id":"shield_overload","name":"护盾过载","desc":"立即恢复城堡 30 护盾","cost":25,"cooldown":12.0,
			"type":"heal","value":30,
		},
		"time_freeze": {
			"id":"time_freeze","name":"时间凝滞","desc":"所有敌人减速 80%，持续 3 秒","cost":40,"cooldown":20.0,
			"type":"slow","value":0.20,"duration":3.0,
		},
		"reinforcement": {
			"id":"reinforcement","name":"紧急增援","desc":"召唤一只临时生物战斗 10 秒","cost":35,"cooldown":18.0,
			"type":"summon","duration":10.0,
		},
		"airstrike": {
			"id":"airstrike","name":"空袭","desc":"对血量最低的 3 个敌人造成 80 伤害","cost":45,"cooldown":25.0,
			"type":"snipe","value":80,"targets":3,
		},
	}
	for skill_id in skill_database:
		cooldowns[skill_id] = 0.0

func _process(delta):
	if current_energy < max_energy:
		current_energy = minf(max_energy, current_energy + energy_regen * delta)
	for skill_id in cooldowns:
		if cooldowns[skill_id] > 0:
			cooldowns[skill_id] -= delta

func use_skill(skill_id: String, enemy_container: Node, castle: Castle) -> bool:
	if not skill_database.has(skill_id): return false
	if cooldowns[skill_id] > 0: return false
	var skill = skill_database[skill_id]
	if current_energy < skill["cost"]: return false

	current_energy -= skill["cost"]
	cooldowns[skill_id] = skill["cooldown"]
	EventBus.skill_used.emit(skill_id)
	EventBus.energy_changed.emit(current_energy, max_energy)

	match skill["type"]:
		"damage":
			_damage_all(enemy_container, skill["value"])
		"heal":
			if castle:
				castle.current_shield = minf(castle.max_shield, castle.current_shield + skill["value"])
				castle.shield_changed.emit(castle.current_shield, castle.max_shield)
		"slow":
			_slow_all(enemy_container, skill["value"], skill["duration"])
		"summon":
			_summon_reinforcement(castle, skill["duration"])
		"snipe":
			_snipe_targets(enemy_container, skill["value"], skill["targets"])
	return true

func _damage_all(container: Node, damage: float):
	if container == null: return
	for e in container.get_children():
		if e is Enemy and e.is_alive:
			e.take_damage(damage)

func _slow_all(container: Node, factor: float, duration: float):
	if container == null: return
	for e in container.get_children():
		if e is Enemy and e.is_alive:
			e.apply_slow(factor, duration)

func _snipe_targets(container: Node, damage: float, count: int):
	if container == null: return
	var enemies: Array[Enemy] = []
	for e in container.get_children():
		if e is Enemy and e.is_alive: enemies.append(e)
	enemies.sort_custom(func(a,b): return a.current_health < b.current_health)
	for i in range(min(count, enemies.size())):
		enemies[i].take_damage(damage)

func _summon_reinforcement(castle: Castle, duration: float):
	if castle == null: return
	var ids = ["mech_sniper","spirit_wisp","thorn_beast","scrap_gambler","echo_walker"]
	var pick = ids[randi() % ids.size()]
	var data = GameData.get_creature_data(pick)
	if data.is_empty(): return
	var creature_scene = load("res://scenes/creature.tscn")
	if creature_scene == null: return
	var c = creature_scene.instantiate()
	c.setup(data)
	c.position = Vector2(randi()%60-30, -40)
	c.set_enemy_container(castle.enemy_container)
	castle.add_child(c)
	await get_tree().create_timer(duration).timeout
	if is_instance_valid(c): c.queue_free()

func get_cooldown(skill_id: String) -> float:
	return max(0, cooldowns.get(skill_id, 0.0))

func get_cooldown_max(skill_id: String) -> float:
	if skill_database.has(skill_id):
		return skill_database[skill_id]["cooldown"]
	return 0.0
