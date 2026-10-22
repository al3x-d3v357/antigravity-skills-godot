# ♟️ Godot 4 Turn-Based Architecture Guide

## 1. State Machine de Turnos (FSM)

```gdscript
class_name CombatStateMachine
extends Node

enum State { ROUND_START, PLAYER_SELECTION, ACTION_RESOLVING, ENEMY_THINKING, ROUND_CLEANUP }

var current_state: State = State.ROUND_START

func change_state(new_state: State) -> void:
    _exit_state(current_state)
    current_state = new_state
    _enter_state(current_state)

func _enter_state(state: State) -> void:
    match state:
        State.ROUND_START:
            _reset_all_units_ap()
            change_state(State.PLAYER_SELECTION)
        State.PLAYER_SELECTION:
            pass
        State.ACTION_RESOLVING:
            pass
```

---

## 2. Command Pattern com Undo

```gdscript
class_name UnitActionCommand
extends RefCounted

var unit: Node2D
var start_pos: Vector2i
var target_pos: Vector2i
var cost_ap: int

func _init(p_unit: Node2D, p_start: Vector2i, p_target: Vector2i, p_cost: int) -> void:
    unit = p_unit
    start_pos = p_start
    target_pos = p_target
    cost_ap = p_cost

func execute() -> void:
    unit.consume_ap(cost_ap)
    unit.move_to_grid(target_pos)

func undo() -> void:
    unit.refund_ap(cost_ap)
    unit.move_to_grid(start_pos)
```

---

## 3. Fila de Iniciativa Dinâmica
Ordene os combatentes com base em um valor de Velocidade/Iniciativa:
```gdscript
var initiative_queue: Array[Combatant] = []

func rebuild_turn_order(combatants: Array[Combatant]) -> void:
    initiative_queue = combatants.duplicate()
    initiative_queue.sort_custom(func(a, b): return a.initiative_stat > b.initiative_stat)
```
