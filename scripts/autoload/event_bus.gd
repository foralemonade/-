extends Node
## 梦游症 - 全局事件总线 (Autoload)
## 解耦各系统间通信

# ── 战斗事件 ──
signal wave_started(wave_number: int)
signal wave_cleared(wave_number: int)
signal battle_won()
signal battle_lost()
signal battle_started()
signal enemy_killed(enemy_type: String, position: Vector2)
signal enemy_reached_end(enemy: Node2D)
signal enemy_spawned(enemy: Node2D)

# ── 城堡事件 ──
signal castle_damaged(current_hp: int, max_hp: int)
signal castle_destroyed()
signal creature_placed(slot_index: int, creature_id: String)
signal creature_removed(slot_index: int)
signal synergy_updated(result: Dictionary)

# ── 技能事件 ──
signal skill_used(skill_id: String)
signal energy_changed(current: float, max_energy: float)

# ── 资源事件 ──
signal resource_changed(resource: String, amount: int)
signal creature_acquired(creature_id: String)
signal module_acquired(module_id: String)

# ── 好感度事件 ──
signal reputation_changed(faction: int, value: int)

# ── 大地图事件 ──
signal node_unlocked(node_id: String)
signal node_completed(node_id: String)
signal node_entered(node_id: String)

# ── 挑战模式事件 ──
signal challenge_started()
signal challenge_ended(score: int)
signal challenge_card_selected(card_id: String)
