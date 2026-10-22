## 🤖 GladiatorFSM — máquina de estados finitos do gladiador auto chess.
##
## Skill: godot-autochess-battle-logic
## Estados: IDLE → SEARCH_TARGET → MOVE_TO_TARGET → ATTACK → CAST_SPELL → DEAD
##
## Depende de BattleGrid (mesma skill) para navegação e ocupação,
## e usa duck typing para dano (aceita HealthComponent da
## godot-data-driven-architecture ou qualquer nó com take_damage()).
class_name GladiatorFSM
extends Node2D

signal state_changed(new_state: State)
signal died(gladiator: GladiatorFSM)

enum State { IDLE, SEARCH_TARGET, MOVE_TO_TARGET, ATTACK, CAST_SPELL, DEAD }

@export var stats: GladiatorData ## opcional: esquema .tres da data-driven-architecture
@export var team: int = 0
@export var grid: BattleGrid

@export_group("Combate (fallback fora de GladiatorData)")
@export var max_health: int = 100
@export var attack_damage: int = 12
@export var attack_speed: float = 1.0
@export var attack_range_cells: float = 1.5
@export var move_speed: float = 220.0
@export var spell_charge_per_hit: float = 0.25

var current_state: State = State.IDLE
var current_cell := Vector2i(-1, -1)
var target: Node2D = null
var mana := 0.0
var _attack_cooldown := 0.0
var _path: Array[Vector2i] = []
var _path_goal := Vector2i(-1, -1)


func _ready() -> void:
	add_to_group(&"gladiators")
	var hp := get_node_or_null("HealthComponent")
	if hp and hp.has_signal(&"died"):
		hp.died.connect(die)


# ---------- API de colocação e fases ----------

## Coloca o gladiador numa célula (drag-and-drop). Emite unit_deployed no EventBus.
func place_on_grid(cell: Vector2i) -> bool:
	if grid == null:
		return false
	cell = grid.clamp_to_grid(cell)
	if not grid.occupy_cell(cell, self):
		return false
	current_cell = cell
	position = grid.cell_to_position(cell)
	_set_state(State.IDLE)
	var bus := get_node_or_null("/root/EventBus")
	if bus:
		bus.unit_deployed.emit(self, cell)
	return true


## Ativado pelo MatchManager na fase COMBATE (ativação simultânea da IA).
func begin_combat() -> void:
	target = null
	_path.clear()
	_set_state(State.SEARCH_TARGET)


## Voltar ao banco após a RESOLUÇÃO / durante a PREPARAÇÃO.
func to_bench() -> void:
	target = null
	_path.clear()
	_set_state(State.IDLE)


# ---------- Ciclo FSM ----------

func _physics_process(delta: float) -> void:
	match current_state:
		State.IDLE:
			pass # fase de preparação: aguarda posicionamento
		State.SEARCH_TARGET:
			_state_search()
		State.MOVE_TO_TARGET:
			_state_move(delta)
		State.ATTACK:
			_state_attack(delta)
		State.CAST_SPELL:
			_state_cast_spell()
		State.DEAD:
			set_physics_process(false)


func _set_state(new_state: State) -> void:
	if current_state == new_state:
		return
	current_state = new_state
	state_changed.emit(new_state)


# ---------- SEARCH_TARGET ----------

func _state_search() -> void:
	_scan_target()
	if target == null:
		_set_state(State.IDLE)
	elif _distance_to_target() <= _attack_world_range():
		_set_state(State.ATTACK)
	else:
		_set_state(State.MOVE_TO_TARGET)


func _scan_target() -> void:
	var best: Node2D = null
	var best_dist := INF
	for node in get_tree().get_nodes_in_group(&"gladiators"):
		var foe := node as GladiatorFSM
		if foe == null or foe == self or foe.team == team:
			continue
		if foe.current_state == State.DEAD:
			continue
		var dist := global_position.distance_to(foe.global_position)
		if dist < best_dist:
			best_dist = dist
			best = foe
	target = best


# ---------- MOVE_TO_TARGET (rotas AStarGrid2D) ----------

func _state_move(delta: float) -> void:
	if target == null or target.get(&"current_state") == State.DEAD:
		_set_state(State.SEARCH_TARGET)
		return

	if _distance_to_target() <= _attack_world_range():
		_set_state(State.ATTACK)
		return

	var goal_cell := grid.clamp_to_grid(target.get(&"current_cell"))
	if goal_cell != _path_goal or _path.is_empty():
		_path = grid.get_path_cells(current_cell, goal_cell)
		_path_goal = goal_cell

	if _path.is_empty():
		# alvo bloqueado/ocupado: re-agenda a busca
		_set_state(State.SEARCH_TARGET)
		return

	var next_cell := _path[0]
	var next_pos := grid.cell_to_position(next_cell)
	position = position.move_toward(next_pos, _move_speed() * delta)

	if position.distance_to(next_pos) < 1.0:
		if grid.swap_occupancy(current_cell, next_cell, self):
			current_cell = next_cell
			_path.pop_front()
		else:
			_path.clear() # célula foi tomada entretanto: recalcula


# ---------- ATTACK ----------

func _state_attack(delta: float) -> void:
	if not _is_valid_target():
		_set_state(State.SEARCH_TARGET)
		return
	if _distance_to_target() > _attack_world_range() * 1.1:
		_set_state(State.MOVE_TO_TARGET)
		return

	_attack_cooldown -= delta
	if _attack_cooldown > 0.0:
		return

	_attack_cooldown = 1.0 / _attack_speed()
	_deal_damage(target, _attack_damage())
	mana = minf(mana + spell_charge_per_hit, 1.0)
	if mana >= 1.0:
		_set_state(State.CAST_SPELL)


# ---------- CAST_SPELL ----------

func _state_cast_spell() -> void:
	mana = 0.0
	var spell: PackedScene = _spell()
	if spell:
		if _is_valid_target():
			var fx := spell.instantiate()
			get_tree().current_scene.add_child(fx)
			fx.global_position = target.global_position
		var bus := get_node_or_null("/root/EventBus")
		if bus:
			bus.spell_cast.emit(self, spell)
	_set_state(State.ATTACK)


# ---------- Dano e morte (pipeline desacoplado) ----------

func _deal_damage(victim: Node, amount: int) -> void:
	if victim.has_method(&"take_damage"):
		victim.take_damage(amount, self)
	var bus := get_node_or_null("/root/EventBus")
	if bus:
		bus.gladiator_attacked.emit(self, victim, amount)


## Interface de receção de dano — chamada por atacantes via duck typing.
func take_damage(amount: int, _source: Node = null) -> void:
	if current_state == State.DEAD:
		return
	var hp := get_node_or_null("HealthComponent")
	if hp and hp.has_method(&"take_damage"):
		hp.take_damage(amount)
	else:
		die() # sem componente de vida: morre logo


func die() -> void:
	if current_state == State.DEAD:
		return
	_set_state(State.DEAD)
	target = null
	if grid and grid.occupant_of(current_cell) == self:
		grid.free_cell(current_cell)
	died.emit(self)
	var bus := get_node_or_null("/root/EventBus")
	if bus:
		bus.gladiator_died.emit(self, team)
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.6)
	tween.tween_callback(queue_free)


# ---------- Utilitários ----------

func _is_valid_target() -> bool:
	return target != null and is_instance_valid(target) and target.get(&"current_state") != State.DEAD


func _distance_to_target() -> float:
	return global_position.distance_to(target.global_position) if target else INF


func _attack_world_range() -> float:
	return attack_range_cells * float(grid.cell_size.x) if grid else attack_range_cells * 64.0


func _max_health_value() -> int:
	return stats.max_health if stats else max_health


func _attack_damage() -> int:
	return stats.attack_damage if stats else attack_damage


func _attack_speed() -> float:
	return stats.attack_speed if stats else attack_speed


func _move_speed() -> float:
	return stats.move_speed if stats else move_speed


func _spell() -> PackedScene:
	return stats.spell if stats and stats.spell else null
