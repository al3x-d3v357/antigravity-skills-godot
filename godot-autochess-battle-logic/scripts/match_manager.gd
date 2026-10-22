## 🎮 MatchManager — ciclo de jogo por fases da arena auto chess.
##
## Skill: godot-autochess-battle-logic
## PREPARAÇÃO (drag-and-drop livre, IA desativada)
##   → COMBATE (UI travada, IA simultânea, monitorização das equipas)
##   → RESOLUÇÃO (vencedor, dano ao líder, retorno ao banco, nova preparação)
class_name MatchManager
extends Node

signal phase_changed(new_phase: int)
signal combat_started
signal combat_ended(winner_team: int)
signal leader_damaged(team: int, remaining_health: int)
signal match_ended(winner_team: int)

enum MatchPhase { PREPARATION, COMBAT, RESOLUTION }

@export var grid: BattleGrid
@export var leader_max_health: int = 10
@export var resolution_delay := 2.0

var phase: MatchPhase = MatchPhase.PREPARATION
var leader_health := {0: 10, 1: 10}


func _ready() -> void:
	add_to_group(&"match_manager")
	leader_health = {0: leader_max_health, 1: leader_max_health}


func _set_phase(new_phase: MatchPhase) -> void:
	if phase == new_phase:
		return
	phase = new_phase
	phase_changed.emit(new_phase)
	var bus := get_node_or_null("/root/EventBus")
	if bus:
		bus.phase_changed.emit(new_phase)


# ---------- Transição PREPARAÇÃO -> COMBATE ----------

## Chamado pela UI quando o jogador confirma a equipa (travamento de interface).
func begin_combat() -> void:
	if phase != MatchPhase.PREPARATION:
		return
	_set_phase(MatchPhase.COMBAT)
	for unit in _all_units():
		unit.begin_combat()
	var bus := get_node_or_null("/root/EventBus")
	if bus:
		bus.combat_started.emit()


# ---------- Monitorização durante o COMBATE ----------

func _physics_process(_delta: float) -> void:
	if phase != MatchPhase.COMBAT:
		return
	var alive := {
		0: false,
		1: false,
	}
	for unit in _all_units():
		if is_instance_valid(unit) and unit.get(&"current_state") != GladiatorFSM.State.DEAD:
			alive[unit.team] = true
	# Uma equipa morrida termina a ronda
	if not alive[0] or not alive[1]:
		var winner := 0 if alive[0] else (1 if alive[1] else -1)
		_end_combat(winner)


# ---------- RESOLUÇÃO ----------

func _end_combat(winner_team: int) -> void:
	_set_phase(MatchPhase.RESOLUTION)
	var losing_team := 1 if winner_team == 0 else 0
	if winner_team == -1:
		losing_team = -1 # empate impróprio (duplo wipe em simultâneo)

	var bus := get_node_or_null("/root/EventBus")
	if bus:
		bus.combat_ended.emit(winner_team)

	# Determinação do vencedor: dano ao líder da equipa derrotada
	if winner_team != -1:
		leader_health[losing_team] = maxi(leader_health[losing_team] - 1, 0)
		leader_damaged.emit(losing_team, leader_health[losing_team])
		if bus:
			bus.leader_damaged.emit(losing_team, leader_health[losing_team])

		# Fim de jogo: líder sem vidas
		if leader_health[losing_team] <= 0:
			var victory := winner_team
			match_ended.emit(victory)
			if bus:
				bus.match_ended.emit(victory)
			_set_phase_victory()
			return

	# Reposicionamento: regresso ao banco e nova preparação
	await get_tree().create_timer(resolution_delay).timeout
	if not is_inside_tree():
		return
	for unit in _all_units():
		if is_instance_valid(unit):
			unit.to_bench()
	if bus:
		bus.units_repositioned.emit()
	_set_phase(MatchPhase.PREPARATION)


func _set_phase_victory() -> void:
	# Congela o loop em RESOLUÇÃO: é a UI que decide recomeçar/voltar ao menu.
	set_physics_process(false)


# ---------- Reset (recomeço de partida) ----------

func reset_match() -> void:
	leader_health = {0: leader_max_health, 1: leader_max_health}
	set_physics_process(true)
	_set_phase(MatchPhase.PREPARATION)


# ---------- Utilitários ----------

func _all_units() -> Array:
	return get_tree().get_nodes_in_group(&"gladiators")
